# MegaDog - RSR Compliant Justfile
# Ethical merge game with Mandelbrot dogtags

set shell := ["bash", "-uc"]
set dotenv-load := true

# Default recipe - show help
default:
    @just --list --unsorted

# ============================================================================
# DEVELOPMENT ENVIRONMENT
# ============================================================================

# Enter Nix development shell
[group('dev')]
dev:
    nix develop

# Update all flake inputs
[group('dev')]
update:
    nix flake update

# Format all Nix files
[group('dev')]
fmt:
    nixpkgs-fmt ./**/*.nix

# Validate all configurations
[group('dev')]
validate: validate-nickel validate-cue validate-dhall
    @echo "All configurations valid"

# ============================================================================
# CONFIGURATION VALIDATION
# ============================================================================

# Validate Nickel configurations
[group('config')]
validate-nickel:
    @echo "Validating Nickel configs..."
    @for f in config/*.ncl; do nickel typecheck "$$f" && echo "  ✓ $$f"; done

# Validate CUE schemas
[group('config')]
validate-cue:
    @echo "Validating CUE schemas..."
    @cd config && cue vet ./...

# Validate Dhall configurations
[group('config')]
validate-dhall:
    @echo "Validating Dhall configs..."
    @for f in config/*.dhall; do dhall --file "$$f" > /dev/null && echo "  ✓ $$f"; done

# Export Dhall to JSON
[group('config')]
dhall-export file:
    dhall-to-json --file config/{{file}}.dhall > config/generated/{{file}}.json

# ============================================================================
# BUILD
# ============================================================================

# Build Pony server
[group('build')]
build-server:
    @echo "Building Pony server..."
    cd server && ponyc -o ../build/bin -b megadog-server

# Build Kotlin renderer (Android)
[group('build')]
build-android:
    @echo "Building Android app..."
    cd android && ./gradlew assembleDebug

# Build all components
[group('build')]
build-all: build-server build-android
    @echo "All components built"

# Clean build artifacts
[group('build')]
clean:
    rm -rf build/
    cd android && ./gradlew clean 2>/dev/null || true

# ============================================================================
# CONTAINERS (Podman, never Docker)
# ============================================================================

# Build server container with Wolfi base
[group('container')]
container-build:
    @echo "Building container with Podman (Wolfi base)..."
    podman build -t megadog-server:latest -f containers/server.containerfile .

# Run server container
[group('container')]
container-run:
    podman run --rm -p 8080:8080 megadog-server:latest

# Push to registry
[group('container')]
container-push registry:
    podman push megadog-server:latest {{registry}}/megadog-server:latest

# Scan container for vulnerabilities
[group('container')]
container-scan:
    @echo "Scanning container..."
    podman run --rm -v /var/run/podman/podman.sock:/var/run/podman/podman.sock \
        cgr.dev/chainguard/grype megadog-server:latest

# ============================================================================
# SMART CONTRACTS (Vyper)
# ============================================================================

# Compile Vyper contracts
[group('contracts')]
contracts-compile:
    @echo "Compiling Vyper contracts..."
    @mkdir -p build/contracts
    vyper contracts/MegaDog.vy -o build/contracts/MegaDog.json -f abi
    vyper contracts/MegaDog.vy -o build/contracts/MegaDog.bin -f bytecode

# Deploy to testnet
[group('contracts')]
contracts-deploy network="mumbai":
    @echo "Deploying to {{network}}..."
    ./scripts/deploy.sh {{network}}

# Verify contract on explorer
[group('contracts')]
contracts-verify network="mumbai" address="":
    @echo "Verifying contract {{address}} on {{network}}..."
    ./scripts/verify.sh {{network}} {{address}}

# ============================================================================
# TESTING
# ============================================================================

# Run Pony tests
[group('test')]
test-server:
    cd server && ponyc -o ../build/test --debug && ../build/test/server

# Run contract tests
[group('test')]
test-contracts:
    @echo "Running contract tests..."
    cd contracts && python -m pytest tests/ -v

# Run all tests
[group('test')]
test-all: test-server test-contracts
    @echo "All tests passed"

# ============================================================================
# DOCUMENTATION
# ============================================================================

# Build documentation
[group('docs')]
docs-build:
    mdbook build docs/

# Serve documentation locally
[group('docs')]
docs-serve:
    mdbook serve docs/ --open

# Generate architecture diagrams
[group('docs')]
docs-diagrams:
    @echo "Generating diagrams..."
    plantuml docs/diagrams/*.puml

# ============================================================================
# LINTING & QUALITY
# ============================================================================

# Lint all code
[group('quality')]
lint: lint-nix lint-nickel lint-pony
    @echo "All linting passed"

# Lint Nix files
[group('quality')]
lint-nix:
    nixpkgs-fmt --check ./**/*.nix

# Lint Nickel configs
[group('quality')]
lint-nickel:
    @for f in config/*.ncl; do nickel typecheck "$$f"; done

# Lint Pony code
[group('quality')]
lint-pony:
    @echo "Pony linting (format check)..."
    # pony-fmt when available

# Run pre-commit hooks
[group('quality')]
pre-commit:
    pre-commit run --all-files

# ============================================================================
# GIT OPERATIONS
# ============================================================================

# Set up git hooks
[group('git')]
git-setup:
    pre-commit install
    git config core.hooksPath .githooks

# RVC - Robot Vacuum Cleaner (automated tidying)
[group('git')]
rvc:
    @echo "Running Robot Vacuum Cleaner..."
    @just fmt
    @just validate
    @just lint
    @echo "Repository tidied"

# ============================================================================
# RELEASE
# ============================================================================

# Create release
[group('release')]
release version:
    @echo "Creating release {{version}}..."
    git tag -a v{{version}} -m "Release {{version}}"
    @just build-all
    @just container-build

# ============================================================================
# UTILITIES
# ============================================================================

# Show project status
[group('util')]
status:
    @echo "=== MegaDog Project Status ==="
    @echo "Git branch: $(git branch --show-current)"
    @echo "Uncommitted: $(git status --porcelain | wc -l) files"
    @echo "Nix: $(nix --version)"
    @echo "Podman: $(podman --version)"

# Generate Mandelbrot preview
[group('util')]
mandelbrot-preview seed="0x1234567890abcdef":
    @echo "Generating Mandelbrot preview for seed {{seed}}..."
    cd tools && kotlin MandelbrotPreview.kt {{seed}}
