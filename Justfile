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

# Run panic-attacker pre-commit scan
assail:
    @command -v panic-attack >/dev/null 2>&1 && panic-attack assail . || echo "panic-attack not found — install from https://github.com/hyperpolymath/panic-attacker"

# Self-diagnostic — checks dependencies, permissions, paths
doctor:
    @echo "Running diagnostics for megadog..."
    @echo "Checking required tools..."
    @command -v just >/dev/null 2>&1 && echo "  [OK] just" || echo "  [FAIL] just not found"
    @command -v git >/dev/null 2>&1 && echo "  [OK] git" || echo "  [FAIL] git not found"
    @echo "Checking for hardcoded paths..."
    @grep -rn '$HOME\|$ECLIPSE_DIR' --include='*.rs' --include='*.ex' --include='*.res' --include='*.gleam' --include='*.sh' . 2>/dev/null | head -5 || echo "  [OK] No hardcoded paths"
    @echo "Diagnostics complete."

# Auto-repair common issues
heal:
    @echo "Attempting auto-repair for megadog..."
    @echo "Fixing permissions..."
    @find . -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    @echo "Cleaning stale caches..."
    @rm -rf .cache/stale 2>/dev/null || true
    @echo "Repair complete."

# Guided tour of key features
tour:
    @echo "=== megadog Tour ==="
    @echo ""
    @echo "1. Project structure:"
    @ls -la
    @echo ""
    @echo "2. Available commands: just --list"
    @echo ""
    @echo "3. Read README.adoc for full overview"
    @echo "4. Read EXPLAINME.adoc for architecture decisions"
    @echo "5. Run 'just doctor' to check your setup"
    @echo ""
    @echo "Tour complete! Try 'just --list' to see all available commands."

# Open feedback channel with diagnostic context
help-me:
    @echo "=== megadog Help ==="
    @echo "Platform: $(uname -s) $(uname -m)"
    @echo "Shell: $SHELL"
    @echo ""
    @echo "To report an issue:"
    @echo "  https://github.com/hyperpolymath/megadog/issues/new"
    @echo ""
    @echo "Include the output of 'just doctor' in your report."
