#!/usr/bin/env bash
# MegaDog Contract Deployment Script
# RSR Compliant: Bash with proper error handling
set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONTRACTS_DIR="$PROJECT_ROOT/contracts"
BUILD_DIR="$PROJECT_ROOT/build/contracts"

# Network configurations
declare -A NETWORKS=(
    ["localhost"]="http://localhost:8545"
    ["mumbai"]="https://rpc-amoy.polygon.technology"
    ["polygon"]="https://polygon-rpc.com"
)

declare -A CHAIN_IDS=(
    ["localhost"]="31337"
    ["mumbai"]="80002"
    ["polygon"]="137"
)

# =============================================================================
# Functions
# =============================================================================

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_success() {
    echo "[SUCCESS] $1"
}

check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v vyper &> /dev/null; then
        log_error "Vyper not found. Install with: pip install vyper"
        exit 1
    fi

    if ! command -v cast &> /dev/null; then
        log_info "Foundry cast not found. Using fallback deployment method."
    fi

    log_success "Dependencies OK"
}

compile_contracts() {
    log_info "Compiling Vyper contracts..."

    mkdir -p "$BUILD_DIR"

    for contract in "$CONTRACTS_DIR"/*.vy; do
        name=$(basename "$contract" .vy)
        log_info "  Compiling $name..."

        # Compile to ABI
        vyper "$contract" -f abi > "$BUILD_DIR/${name}.abi.json"

        # Compile to bytecode
        vyper "$contract" -f bytecode > "$BUILD_DIR/${name}.bin"

        # Compile to combined JSON
        vyper "$contract" -f combined_json > "$BUILD_DIR/${name}.json"

        log_success "  $name compiled"
    done

    log_success "All contracts compiled"
}

deploy_contract() {
    local network="$1"
    local server_address="${2:-0x0000000000000000000000000000000000000000}"

    if [[ ! -v "NETWORKS[$network]" ]]; then
        log_error "Unknown network: $network"
        log_info "Available networks: ${!NETWORKS[*]}"
        exit 1
    fi

    local rpc_url="${NETWORKS[$network]}"
    local chain_id="${CHAIN_IDS[$network]}"

    log_info "Deploying to $network..."
    log_info "  RPC: $rpc_url"
    log_info "  Chain ID: $chain_id"
    log_info "  Server Address: $server_address"

    if command -v cast &> /dev/null && [[ -n "${PRIVATE_KEY:-}" ]]; then
        # Deploy with Foundry cast
        local bytecode
        bytecode=$(cat "$BUILD_DIR/MegaDog.bin")

        # Encode constructor args (server_address)
        local encoded_args
        encoded_args=$(cast abi-encode "constructor(address)" "$server_address")

        # Deploy
        local result
        result=$(cast send \
            --rpc-url "$rpc_url" \
            --private-key "$PRIVATE_KEY" \
            --create "${bytecode}${encoded_args:2}" \
            --json)

        local contract_address
        contract_address=$(echo "$result" | jq -r '.contractAddress')

        log_success "Contract deployed at: $contract_address"
        echo "$contract_address" > "$BUILD_DIR/deployed_address_$network.txt"
    else
        log_info "No PRIVATE_KEY set or cast not available"
        log_info "To deploy manually, use the bytecode at: $BUILD_DIR/MegaDog.bin"
        log_info "Constructor argument: $server_address"
    fi
}

verify_contract() {
    local network="$1"
    local address="$2"

    log_info "Contract verification not yet implemented for $network"
    log_info "Manual verification required at block explorer"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        compile)
            check_dependencies
            compile_contracts
            ;;
        deploy)
            local network="${1:-localhost}"
            local server="${2:-0x0000000000000000000000000000000000000000}"
            check_dependencies
            compile_contracts
            deploy_contract "$network" "$server"
            ;;
        verify)
            local network="${1:-}"
            local address="${2:-}"
            if [[ -z "$network" || -z "$address" ]]; then
                log_error "Usage: $0 verify <network> <address>"
                exit 1
            fi
            verify_contract "$network" "$address"
            ;;
        help|--help|-h)
            echo "MegaDog Contract Deployment"
            echo ""
            echo "Usage: $0 <command> [args]"
            echo ""
            echo "Commands:"
            echo "  compile           Compile all Vyper contracts"
            echo "  deploy <network>  Deploy to specified network"
            echo "  verify <net> <addr>  Verify contract on explorer"
            echo ""
            echo "Networks: ${!NETWORKS[*]}"
            echo ""
            echo "Environment:"
            echo "  PRIVATE_KEY       Deployer private key (required for deploy)"
            ;;
        *)
            log_error "Unknown command: $command"
            echo "Run '$0 help' for usage"
            exit 1
            ;;
    esac
}

main "$@"
