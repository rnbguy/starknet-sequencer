#!/bin/bash

# Simple test script to validate the apollo_node bootstrap setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Apollo Node Bootstrap Setup Test ==="
echo

# Test 1: Check if all required files exist
echo "Test 1: Checking required files..."
required_files=(
    "Dockerfile.apollo-bootstrap"
    "preset_config.json"
    "bootstrap-apollo.sh"
    "BOOTSTRAP_README.md"
)

for file in "${required_files[@]}"; do
    if [[ -f "$SCRIPT_DIR/$file" ]]; then
        echo "✓ $file exists"
    else
        echo "✗ $file is missing"
        exit 1
    fi
done

# Test 2: Validate JSON configuration
echo
echo "Test 2: Validating preset_config.json..."
if python3 -m json.tool "$SCRIPT_DIR/preset_config.json" > /dev/null 2>&1; then
    echo "✓ preset_config.json is valid JSON"
else
    echo "✗ preset_config.json is invalid JSON"
    exit 1
fi

# Test 3: Check if bootstrap script is executable
echo
echo "Test 3: Checking bootstrap script permissions..."
if [[ -x "$SCRIPT_DIR/bootstrap-apollo.sh" ]]; then
    echo "✓ bootstrap-apollo.sh is executable"
else
    echo "✗ bootstrap-apollo.sh is not executable"
    exit 1
fi

# Test 4: Test bootstrap script help
echo
echo "Test 4: Testing bootstrap script help..."
if "$SCRIPT_DIR/bootstrap-apollo.sh" --help > /dev/null 2>&1; then
    echo "✓ bootstrap-apollo.sh help works"
else
    echo "✗ bootstrap-apollo.sh help failed"
    exit 1
fi

# Test 5: Check Dockerfile syntax
echo
echo "Test 5: Basic Dockerfile validation..."
if grep -q "FROM rust:1-slim" "$SCRIPT_DIR/Dockerfile.apollo-bootstrap"; then
    echo "✓ Dockerfile uses correct base image (rust:1-slim)"
else
    echo "✗ Dockerfile doesn't use rust:1-slim base image"
    exit 1
fi

if grep -q "cargo build --locked --bin apollo_node" "$SCRIPT_DIR/Dockerfile.apollo-bootstrap"; then
    echo "✓ Dockerfile builds apollo_node with --locked"
else
    echo "✗ Dockerfile doesn't build apollo_node with --locked"
    exit 1
fi

# Test 6: Check config has dummy L1 provider
echo
echo "Test 6: Checking dummy L1 provider configuration..."
if grep -q '"base_layer_config.node_url": "http://localhost:8545"' "$SCRIPT_DIR/preset_config.json"; then
    echo "✓ Configuration has dummy L1 provider (localhost:8545)"
else
    echo "✗ Configuration missing dummy L1 provider"
    exit 1
fi

# Test 7: Check if essential config fields are present
echo
echo "Test 7: Checking essential configuration fields..."
essential_fields=(
    "base_layer_config"
    "components.http_server.execution_mode"
    "components.monitoring_endpoint.execution_mode"
)

for field in "${essential_fields[@]}"; do
    if grep -q "\"$field" "$SCRIPT_DIR/preset_config.json"; then
        echo "✓ $field is configured"
    else
        echo "✗ $field is missing from configuration"
        exit 1
    fi
done

echo
echo "=== All tests passed! ==="
echo
echo "The Apollo Node bootstrap setup is ready to use."
echo "Next steps:"
echo "  1. Build: ./bootstrap-apollo.sh build"
echo "  2. Run:   ./bootstrap-apollo.sh run"
echo "  3. Or for development: ./bootstrap-apollo.sh run-dev"