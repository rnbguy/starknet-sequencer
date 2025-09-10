#!/bin/bash
set -e

# Apollo Node Bootstrap Script
# This script helps bootstrap an apollo_node with a dummy L1 provider for development/testing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_IMAGE_NAME="apollo-node-bootstrap"
CONTAINER_NAME="apollo-node-devnet"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS] COMMAND"
    echo ""
    echo "Commands:"
    echo "  build      Build the apollo_node Docker image"
    echo "  run        Run apollo_node in devnet mode with dummy L1 provider"
    echo "  run-dev    Run apollo_node directly with cargo run (for development)"
    echo "  stop       Stop the running apollo_node container"
    echo "  clean      Remove the apollo_node container and image"
    echo "  logs       Show logs from the running container"
    echo ""
    echo "Options:"
    echo "  -p, --port PORT     Port to expose for RPC (default: 8080)"
    echo "  -v, --volume PATH   Additional volume to mount for config/data"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build                    # Build the Docker image"
    echo "  $0 run                      # Run with default settings"
    echo "  $0 run -p 9090              # Run with RPC on port 9090"
    echo "  $0 run -v ./data:/data      # Run with data volume mounted"
}

# Parse command line arguments
RPC_PORT=8080
ADDITIONAL_VOLUMES=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            RPC_PORT="$2"
            shift 2
            ;;
        -v|--volume)
            ADDITIONAL_VOLUMES="$ADDITIONAL_VOLUMES -v $2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        build|run|run-dev|stop|clean|logs)
            COMMAND="$1"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check if command is provided
if [[ -z "${COMMAND:-}" ]]; then
    print_error "No command provided"
    usage
    exit 1
fi

# Function to build the Docker image
build_image() {
    print_info "Building apollo_node Docker image..."
    cd "$PROJECT_ROOT"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    docker build -f devnet/Dockerfile.apollo-bootstrap -t "$DOCKER_IMAGE_NAME" .
    print_info "Docker image '$DOCKER_IMAGE_NAME' built successfully"
}

# Function to run apollo_node directly with cargo run
run_dev() {
    print_info "Running apollo_node in development mode with cargo run..."
    
    cd "$PROJECT_ROOT"
    
    if [[ ! -f "devnet/preset_config.json" ]]; then
        print_error "devnet/preset_config.json not found"
        exit 1
    fi
    
    print_info "Starting apollo_node with devnet/preset_config.json..."
    print_info "This will run: cargo run --locked --bin apollo_node -- --config_file devnet/preset_config.json"
    
    # Run apollo_node with cargo run as specified in requirements
    cargo run --locked --bin apollo_node -- --config_file devnet/preset_config.json
}

# Function to run the container
run_container() {
    print_info "Starting apollo_node in devnet mode..."
    
    # Stop existing container if running
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        print_warning "Container '$CONTAINER_NAME' is already running. Stopping it first..."
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1
    fi
    
    # Remove existing container if exists
    if docker ps -a -q -f name="$CONTAINER_NAME" | grep -q .; then
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1
    fi
    
    # Create data directory if it doesn't exist
    mkdir -p "$SCRIPT_DIR/data"
    
    print_info "Running apollo_node on port $RPC_PORT..."
    print_info "Data directory: $SCRIPT_DIR/data"
    print_info "Config file: preset_config.json (with dummy L1 provider)"
    
    # Run the container
    docker run -d \
        --name "$CONTAINER_NAME" \
        -p "$RPC_PORT:8080" \
        -p "$((RPC_PORT + 1)):8081" \
        -p "$((RPC_PORT + 2)):8082" \
        -v "$SCRIPT_DIR/data:/data" \
        -v "$SCRIPT_DIR/preset_config.json:/app/preset_config.json" \
        $ADDITIONAL_VOLUMES \
        "$DOCKER_IMAGE_NAME"
    
    print_info "Apollo node started successfully!"
    print_info "RPC endpoint: http://localhost:$RPC_PORT"
    print_info "Monitoring: http://localhost:$((RPC_PORT + 1))"
    print_info "Additional port: http://localhost:$((RPC_PORT + 2))"
    print_info ""
    print_info "To see logs: $0 logs"
    print_info "To stop: $0 stop"
}

# Function to stop the container
stop_container() {
    print_info "Stopping apollo_node container..."
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        docker stop "$CONTAINER_NAME"
        print_info "Container stopped successfully"
    else
        print_warning "Container '$CONTAINER_NAME' is not running"
    fi
}

# Function to clean up
clean_up() {
    print_info "Cleaning up apollo_node container and image..."
    
    # Stop and remove container
    if docker ps -a -q -f name="$CONTAINER_NAME" | grep -q .; then
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
        docker rm "$CONTAINER_NAME"
        print_info "Container removed"
    fi
    
    # Remove image
    if docker images -q "$DOCKER_IMAGE_NAME" | grep -q .; then
        docker rmi "$DOCKER_IMAGE_NAME"
        print_info "Image removed"
    fi
    
    print_info "Cleanup completed"
}

# Function to show logs
show_logs() {
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        print_info "Showing logs for apollo_node container..."
        docker logs -f "$CONTAINER_NAME"
    else
        print_error "Container '$CONTAINER_NAME' is not running"
        exit 1
    fi
}

# Execute the command
case $COMMAND in
    build)
        build_image
        ;;
    run)
        # Build image if it doesn't exist
        if ! docker images -q "$DOCKER_IMAGE_NAME" | grep -q .; then
            print_info "Image not found. Building first..."
            build_image
        fi
        run_container
        ;;
    run-dev)
        run_dev
        ;;
    stop)
        stop_container
        ;;
    clean)
        clean_up
        ;;
    logs)
        show_logs
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac