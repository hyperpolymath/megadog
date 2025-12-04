# MegaDog

**Ethical merge game with Mandelbrot dogtags - no scams, just math.**

[![RSR Compliant](https://img.shields.io/badge/RSR-Compliant-gold)](./MANIFESTO.md)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue.svg)](./LICENSE)

## What is MegaDog?

MegaDog is an ethical remake of predatory mobile "merge dog" games. Instead of fake money promises and psychological manipulation, we offer:

- **Real Ownership**: Your dogs are NFTs you actually own
- **Beautiful Math**: Unique Mandelbrot fractals as dogtags
- **Transparent Economics**: All code open source, all odds public
- **Memory-Safe Stack**: Pony + Vyper + Kotlin (no exploits)

## Quick Start

```bash
# Enter development environment
nix develop

# See available commands
just

# Build everything
just build-all

# Run server
just container-run
```

## Architecture

```
┌─────────────────────────────────────┐
│        Android Client (Kotlin)       │
│  • Merge UI • Mandelbrot Renderer   │
└─────────────┬───────────────────────┘
              │ WebSocket
              ▼
┌─────────────────────────────────────┐
│        Pony Game Server             │
│  • State Management • Anti-Cheat    │
│  • Batch Aggregation                │
└─────────────┬───────────────────────┘
              │ Batched Diffs
              ▼
┌─────────────────────────────────────┐
│        Polygon Blockchain           │
│  • Vyper Contracts                  │
│  • Logarithmic Storage              │
│  • NFT Ownership                    │
└─────────────────────────────────────┘
```

## The Innovation: Logarithmic Storage

Traditional games store values directly:
```
treats = 1,000,000,000  (uint256: 32 bytes)
```

MegaDog stores logarithmically:
```
log_treats = ln(1,000,000,000) × 10^6 = 20,723,266  (int128: 16 bytes)
```

**Result**: 50% storage reduction, ~30% gas savings at scale.

## Mandelbrot Dogtags

Each dog generates a unique 3D Mandelbulb fractal based on:
- Dog level (complexity)
- Merge history (seed)
- Birth timestamp (entropy)

These fractals are:
- Deterministic (reproducible by anyone)
- Beautiful (actual mathematical art)
- Exportable (4K wallpapers, NFT metadata)

## RSR Compliance

This project follows the Rhodium Standard Repository specification:

- ✅ **Nix flakes** for hermetic builds
- ✅ **Nickel** for type-safe configuration
- ✅ **Justfile** for comprehensive CLI
- ✅ **Podman** with Wolfi base images
- ✅ **GitLab** for source control
- ✅ **Memory-safe languages** throughout

## Project Structure

```
megadog/
├── android/           # Kotlin Android app
│   └── app/src/main/kotlin/com/megadog/
│       ├── renderer/  # Mandelbrot GPU renderer
│       └── game/      # Game logic & client
├── server/            # Pony game server
│   └── src/           # Actor-based architecture
├── contracts/         # Vyper smart contracts
├── config/            # Nickel configurations
├── containers/        # Podman containerfiles
├── scripts/           # Deployment scripts
└── docs/              # Documentation
```

## Commands

```bash
# Development
just dev              # Enter Nix shell
just validate         # Validate all configs
just fmt              # Format code

# Build
just build-server     # Build Pony server
just build-android    # Build Android app
just build-all        # Build everything

# Containers
just container-build  # Build with Podman
just container-run    # Run locally
just container-scan   # Security scan

# Contracts
just contracts-compile  # Compile Vyper
just contracts-deploy   # Deploy to testnet

# Testing
just test-all         # Run all tests
```

## Philosophy

Read [MANIFESTO.md](./MANIFESTO.md) for why we built this.

Read [ARCHITECTURE.md](./ARCHITECTURE.md) for how it works.

Read [CONTRIBUTING.md](./CONTRIBUTING.md) to help out.

## License

AGPL-3.0 - Because games should be games, not slot machines.

---

*The dogs deserve better. So do the players.*
