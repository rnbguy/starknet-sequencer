# Apollo Node Devnet Bootstrap

This directory provides a complete devnet environment for running `apollo_node` with a mock L1 provider for development and testing purposes.

## Overview

The devnet setup includes:
- **Mock L1 Provider**: A simple Python HTTP server that responds to Ethereum JSON-RPC calls
- **Apollo Node**: Configured to run in devnet mode with all necessary components enabled
- **Docker Support**: Complete containerized environment for easy deployment
- **CI Integration**: Automated testing that validates block production

## Files

- `Dockerfile.apollo-bootstrap` - Docker image based on rust:1-slim that builds apollo_node
- `preset_config.json` - Complete devnet configuration enabling consensus, batcher, mempool, etc.
- `bootstrap-apollo.sh` - Main management script with build, run, stop commands
- `mock_l1_provider.py` - Simple L1 provider that responds to basic Ethereum JSON-RPC calls
- `start_devnet.sh` - Docker startup script that runs both L1 provider and apollo_node
- `test-bootstrap.sh` - Validation script for testing the setup

## Quick Start

### Using Docker (Recommended)

1. **Build and run:**
   ```bash
   cd devnet
   ./bootstrap-apollo.sh build
   ./bootstrap-apollo.sh run
   ```

### Using Cargo (Development)

1. **Run directly with cargo:**
   ```bash
   cd devnet
   ./bootstrap-apollo.sh run-dev
   ```

This will:
- Start a mock L1 provider on port 8545
- Start apollo_node with the devnet configuration
- Begin block production automatically

## Features

### Mock L1 Provider
The mock L1 provider (`mock_l1_provider.py`) responds to common Ethereum JSON-RPC methods:
- `eth_chainId` - Returns mainnet chain ID
- `eth_blockNumber` - Returns incrementing block numbers
- `eth_getBlockByNumber` - Returns mock block data
- `eth_call` - Returns empty results for contract calls
- `eth_getLogs` - Returns empty log arrays

### Complete Devnet Configuration
The `preset_config.json` enables all necessary components:
- **Consensus Manager**: Enabled for block production
- **Batcher**: Processes transactions into batches
- **Mempool**: Manages pending transactions
- **Gateway**: Handles external requests
- **HTTP Server**: Provides RPC endpoints (port 8080)
- **Monitoring**: Provides metrics endpoints (port 8081)

### Block Production
The devnet is configured to automatically start producing blocks with:
- Consensus enabled with single validator
- Fast block times for development
- L1 DA mode disabled for standalone operation
   ./bootstrap-apollo.sh run
   ```

3. **Check the logs:**
   ```bash
   ./bootstrap-apollo.sh logs
   ```

4. **Stop the node:**
   ```bash
   ./bootstrap-apollo.sh stop
   ```

## Usage

```bash
./bootstrap-apollo.sh [OPTIONS] COMMAND
```

### Commands

- `build` - Build the apollo_node Docker image
- `run` - Run apollo_node in devnet mode with dummy L1 provider
- `stop` - Stop the running apollo_node container
- `clean` - Remove the apollo_node container and image
- `logs` - Show logs from the running container

### Options

- `-p, --port PORT` - Port to expose for RPC (default: 8080)
- `-v, --volume PATH` - Additional volume to mount for config/data
- `-h, --help` - Show help message

## Examples

```bash
# Build and run with default settings
cd devnet
./bootstrap-apollo.sh build
./bootstrap-apollo.sh run

# Run with custom RPC port
./bootstrap-apollo.sh run -p 9090

# Run with additional data volume
./bootstrap-apollo.sh run -v ./my-data:/data

# Run with custom config file
./bootstrap-apollo.sh run -v ./my-config.json:/app/preset_config.json
```

## Configuration

The `preset_config.json` file contains a minimal devnet configuration with:

- **Dummy L1 Provider**: Points to `http://localhost:8545` (you can run a local Anvil instance)
- **Local Components**: All components run in local execution mode
- **Dummy Contract**: Uses `0x0000000000000000000000000000000000000000` as the Starknet contract address
- **Test Keys**: Uses test secret keys for networking components

### Customizing Configuration

You can modify `preset_config.json` or mount your own configuration:

```bash
# Create your custom config
cp preset_config.json my_config.json
# Edit my_config.json as needed

# Run with custom config
./bootstrap-apollo.sh run -v ./my_config.json:/app/preset_config.json
```

## Running with a Real L1 Provider

To connect to a real L1 provider (like Anvil), update the configuration:

1. Start Anvil:
   ```bash
   anvil --host 0.0.0.0 --port 8545
   ```

2. Update `preset_config.json`:
   ```json
   {
     "base_layer_config.node_url": "http://host.docker.internal:8545",
     ...
   }
   ```

3. Run the node:
   ```bash
   ./bootstrap-apollo.sh run
   ```

## Ports

By default, the following ports are exposed:

- `8080` - RPC endpoint
- `8081` - Monitoring endpoint  
- `8082` - Additional service endpoint

## Data Persistence

The script creates a `./data` directory that is mounted to `/data` in the container for persistent storage.

## Incremental Builds

For development with incremental builds, you can mount your source directory:

```bash
./bootstrap-apollo.sh run -v ./target:/app/target
```

This allows you to:
1. Build outside the container
2. Reuse build artifacts
3. Speed up subsequent builds

## Troubleshooting

### Container won't start
- Check logs: `./bootstrap-apollo.sh logs`
- Verify configuration: Ensure `preset_config.json` is valid JSON

### Port conflicts
- Use a different port: `./bootstrap-apollo.sh run -p 9090`
- Check what's using the port: `lsof -i :8080`

### Build failures
- Ensure Docker is installed and running
- Check disk space for Docker builds
- Try cleaning up: `./bootstrap-apollo.sh clean`

## Architecture

The bootstrap setup creates a minimal apollo_node environment suitable for:
- Local development
- Integration testing
- Learning and experimentation
- CI/CD pipelines

It's not intended for production use but provides a quick way to get apollo_node running with minimal external dependencies.