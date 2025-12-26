#!/usr/bin/env bash
#
# port-forward.sh - Automate kubectl port-forwarding for AI Todo services
#
# Usage:
#   ./deployment/port-forward.sh            # Start all port-forwards in background
#   ./deployment/port-forward.sh stop       # Stop all port-forwards
#   ./deployment/port-forward.sh status     # Check port-forward status
#
# This script forwards:
#   - Backend service: localhost:8000 -> ai-todo-backend-service:8000
#   - Frontend service: localhost:3000 -> ai-todo-frontend-service:3000
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service configurations
BACKEND_SERVICE="ai-todo-backend-service"
BACKEND_PORT="8000"
FRONTEND_SERVICE="ai-todo-frontend-service"
FRONTEND_PORT="3000"

# Log directory for port-forward processes
LOG_DIR="/tmp/ai-todo-port-forward"
mkdir -p "$LOG_DIR"

# Function: Print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Function: Check if port is already in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function: Check if kubectl is available and cluster is accessible
check_prerequisites() {
    if ! command -v kubectl &> /dev/null; then
        print_color "$RED" "ERROR: kubectl not found. Please install kubectl first."
        exit 1
    fi

    if ! kubectl cluster-info &> /dev/null; then
        print_color "$RED" "ERROR: Cannot connect to Kubernetes cluster."
        print_color "$YELLOW" "Hint: Run 'minikube start' or check your kubectl context."
        exit 1
    fi
}

# Function: Check if service exists
check_service() {
    local service=$1
    if ! kubectl get svc "$service" &> /dev/null; then
        print_color "$RED" "ERROR: Service '$service' not found in cluster."
        print_color "$YELLOW" "Hint: Run './deployment/deploy.sh' to deploy services first."
        return 1
    fi
    return 0
}

# Function: Start port-forward for a service
start_port_forward() {
    local service=$1
    local port=$2
    local log_file="$LOG_DIR/${service}.log"

    print_color "$BLUE" "Starting port-forward for $service on localhost:$port..."

    # Check if port is already in use
    if check_port "$port"; then
        print_color "$YELLOW" "⚠ Port $port is already in use. Checking if it's our port-forward..."

        # Check if it's our port-forward process
        if pgrep -f "kubectl port-forward.*$service.*$port:$port" > /dev/null; then
            print_color "$GREEN" "✓ Port-forward for $service is already running on port $port"
            return 0
        else
            print_color "$RED" "ERROR: Port $port is in use by another process."
            print_color "$YELLOW" "Hint: Stop the other process or use a different port."
            return 1
        fi
    fi

    # Start port-forward in background
    kubectl port-forward "svc/$service" "$port:$port" > "$log_file" 2>&1 &
    local pid=$!

    # Wait a moment for port-forward to initialize
    sleep 2

    # Check if port-forward is still running
    if ps -p $pid > /dev/null 2>&1; then
        print_color "$GREEN" "✓ Port-forward started for $service (PID: $pid)"
        print_color "$GREEN" "  Access at: http://localhost:$port"
        echo "$pid" > "$LOG_DIR/${service}.pid"
        return 0
    else
        print_color "$RED" "ERROR: Port-forward failed to start for $service"
        print_color "$YELLOW" "Check logs: cat $log_file"
        return 1
    fi
}

# Function: Stop all port-forwards
stop_port_forwards() {
    print_color "$BLUE" "Stopping all AI Todo port-forwards..."

    local stopped=0

    # Stop using PID files
    for pid_file in "$LOG_DIR"/*.pid; do
        if [[ -f "$pid_file" ]]; then
            local pid=$(cat "$pid_file")
            local service=$(basename "$pid_file" .pid)

            if ps -p "$pid" > /dev/null 2>&1; then
                kill "$pid" 2>/dev/null || true
                print_color "$GREEN" "✓ Stopped port-forward for $service (PID: $pid)"
                stopped=$((stopped + 1))
            fi
            rm -f "$pid_file"
        fi
    done

    # Also stop any kubectl port-forward processes for our services
    pkill -f "kubectl port-forward.*(ai-todo-backend-service|ai-todo-frontend-service)" 2>/dev/null || true

    if [[ $stopped -eq 0 ]]; then
        print_color "$YELLOW" "No active port-forwards found."
    else
        print_color "$GREEN" "✓ Stopped $stopped port-forward(s)"
    fi
}

# Function: Show port-forward status
show_status() {
    print_color "$BLUE" "Port-forward status for AI Todo services:"
    echo ""

    local backend_running=false
    local frontend_running=false

    # Check backend
    if pgrep -f "kubectl port-forward.*$BACKEND_SERVICE.*$BACKEND_PORT:$BACKEND_PORT" > /dev/null; then
        print_color "$GREEN" "✓ Backend ($BACKEND_SERVICE): Running on localhost:$BACKEND_PORT"
        backend_running=true
    else
        print_color "$YELLOW" "✗ Backend ($BACKEND_SERVICE): Not running"
    fi

    # Check frontend
    if pgrep -f "kubectl port-forward.*$FRONTEND_SERVICE.*$FRONTEND_PORT:$FRONTEND_PORT" > /dev/null; then
        print_color "$GREEN" "✓ Frontend ($FRONTEND_SERVICE): Running on localhost:$FRONTEND_PORT"
        frontend_running=true
    else
        print_color "$YELLOW" "✗ Frontend ($FRONTEND_SERVICE): Not running"
    fi

    echo ""
    if $backend_running && $frontend_running; then
        print_color "$GREEN" "Status: All services forwarded"
        echo ""
        print_color "$BLUE" "Access URLs:"
        echo "  Frontend: http://localhost:$FRONTEND_PORT"
        echo "  Backend:  http://localhost:$BACKEND_PORT"
    elif $backend_running || $frontend_running; then
        print_color "$YELLOW" "Status: Partial - some services forwarded"
    else
        print_color "$YELLOW" "Status: No port-forwards active"
        print_color "$BLUE" "Run './deployment/port-forward.sh' to start"
    fi
}

# Function: Start all port-forwards
start_all() {
    print_color "$BLUE" "=== AI Todo Port-Forward Setup ==="
    echo ""

    check_prerequisites

    # Check if services exist
    local services_ok=true
    if ! check_service "$BACKEND_SERVICE"; then
        services_ok=false
    fi
    if ! check_service "$FRONTEND_SERVICE"; then
        services_ok=false
    fi

    if [[ "$services_ok" != "true" ]]; then
        print_color "$RED" "ERROR: Required services not found in cluster."
        exit 1
    fi

    echo ""

    # Start port-forwards
    local success=true
    if ! start_port_forward "$BACKEND_SERVICE" "$BACKEND_PORT"; then
        success=false
    fi
    if ! start_port_forward "$FRONTEND_SERVICE" "$FRONTEND_PORT"; then
        success=false
    fi

    echo ""
    if [[ "$success" == "true" ]]; then
        print_color "$GREEN" "=== Port-forwards started successfully ==="
        echo ""
        print_color "$BLUE" "Access URLs:"
        echo "  Frontend: http://localhost:$FRONTEND_PORT"
        echo "  Backend:  http://localhost:$BACKEND_PORT"
        echo ""
        print_color "$YELLOW" "To stop port-forwards:"
        echo "  ./deployment/port-forward.sh stop"
        echo "  OR: pkill -f 'kubectl port-forward'"
        echo ""
        print_color "$BLUE" "Logs available at: $LOG_DIR/"
    else
        print_color "$RED" "=== Port-forward setup completed with errors ==="
        print_color "$YELLOW" "Check logs in: $LOG_DIR/"
        exit 1
    fi
}

# Main execution
main() {
    local command="${1:-start}"

    case "$command" in
        start)
            start_all
            ;;
        stop)
            stop_port_forwards
            ;;
        status)
            show_status
            ;;
        --help|-h|help)
            echo "Usage: $0 [start|stop|status]"
            echo ""
            echo "Commands:"
            echo "  start   - Start port-forwards for all services (default)"
            echo "  stop    - Stop all port-forwards"
            echo "  status  - Show current port-forward status"
            echo ""
            echo "Examples:"
            echo "  $0              # Start port-forwards"
            echo "  $0 start        # Start port-forwards"
            echo "  $0 stop         # Stop port-forwards"
            echo "  $0 status       # Check status"
            ;;
        *)
            print_color "$RED" "ERROR: Unknown command '$command'"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"
