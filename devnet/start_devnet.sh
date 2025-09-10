#!/bin/bash
set -e

echo "Starting devnet environment..."

# Start mock L1 provider in background
echo "Starting mock L1 provider on port 8545..."
python3 /app/devnet/mock_l1_provider.py 8545 &
L1_PID=$!

# Wait for L1 provider to start
sleep 3

# Cleanup function
cleanup() {
    echo "Shutting down devnet..."
    kill $L1_PID 2>/dev/null || true
    exit 0
}

# Set trap for cleanup
trap cleanup INT TERM

echo "Starting apollo_node..."
echo "Config: /app/devnet/preset_config.json"
echo "L1 Provider: http://localhost:8545"

# Start apollo_node
exec ./target/release/apollo_node --config_file /app/devnet/preset_config.json