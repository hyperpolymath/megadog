# MegaDog Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     ANDROID CLIENT                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Kotlin    │  │  OpenGL ES  │  │     Mandelbrot         │  │
│  │   Game UI   │  │   Shaders   │  │     Renderer           │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
│         │                │                      │                │
│         └────────────────┴──────────────────────┘                │
│                          │                                       │
└──────────────────────────┼───────────────────────────────────────┘
                           │ WebSocket
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PONY SERVER                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │    Dog      │  │   Batch     │  │      Anti-Cheat        │  │
│  │   Manager   │  │ Aggregator  │  │       Engine           │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
│         │                │                      │                │
│         └────────────────┴──────────────────────┘                │
│                          │                                       │
└──────────────────────────┼───────────────────────────────────────┘
                           │ Batched Diffs
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   POLYGON BLOCKCHAIN                             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Vyper Contracts                          ││
│  │  • Logarithmic dog state storage                            ││
│  │  • Merkle root batch commits                                ││
│  │  • NFT ownership registry                                   ││
│  │  • Transparent economics                                    ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### Android Client (Kotlin)

**Responsibilities:**
- Game UI and touch handling
- GPU-accelerated Mandelbrot rendering
- Local state caching
- WebSocket communication with server

**Key Classes:**
- `MandelbrotRenderer`: OpenGL ES raymarching for 3D fractals
- `DogManager`: Local dog state management
- `GameClient`: WebSocket connection handler
- `WallpaperExporter`: High-res fractal export

### Pony Server

**Actor Model Architecture:**

```
Main
 │
 ├── WebSocketServer ─────────────┐
 │                                │
 ├── DogStateManager              │
 │    └── DogActor (per user)     │
 │                                │
 ├── BatchAggregator ─────────────┼──→ Blockchain
 │                                │
 └── AntiCheatEngine              │
      └── UserSession (per conn)──┘
```

**Why Pony:**
- Actor isolation prevents data races
- Reference capabilities enforce memory safety
- No GC pauses (critical for game servers)
- Type-safe concurrency

### Vyper Smart Contracts

**Storage Optimisation:**

```
Traditional uint256:  32 bytes per value
Logarithmic int128:   16 bytes per value (50% reduction)
Batch commits:        ~80 gas per dog vs ~5000 gas individual
```

**Contract Functions:**
- `mint_starter_dog()`: Create initial dog for new players
- `merge_dogs()`: Combine two same-level dogs
- `apply_dog_diff_batch()`: Batched state updates from server
- `prestige_reset()`: Milkshake blender reset mechanic
- `verify_dog_rarity()`: Public rarity verification

### Mandelbrot Dogtags

**Generation Algorithm:**

1. Dog parameters (level, merge history, timestamp) → seed
2. Seed → Mandelbulb parameters (iterations, rotation, bailout)
3. Parameters → GPU raymarching → 3D fractal
4. Fractal → PNG export + IPFS hash

**Shader Pipeline:**

```glsl
// Signed Distance Function for Mandelbulb
float mandelbulbSDF(vec3 pos, float power) {
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;

    for (int i = 0; i < MAX_ITERATIONS; i++) {
        r = length(z);
        if (r > BAILOUT) break;

        // Convert to spherical
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);
        dr = pow(r, power - 1.0) * power * dr + 1.0;

        // Scale and rotate
        float zr = pow(r, power);
        theta *= power;
        phi *= power;

        // Back to Cartesian
        z = zr * vec3(
            sin(theta) * cos(phi),
            sin(phi) * sin(theta),
            cos(theta)
        ) + pos;
    }
    return 0.5 * log(r) * r / dr;
}
```

## Data Flow

### Merge Operation

```
1. User taps "Merge" on two dogs
   │
2. Android sends merge request via WebSocket
   │
3. Pony server validates:
   │  • User owns both dogs
   │  • Dogs are same level
   │  • Anti-cheat passes
   │
4. Server creates merged dog:
   │  • New level = old level + 1
   │  • New seed = hash(seed1, seed2, block)
   │  • Log treats combined
   │
5. Server queues diff for batch commit
   │
6. When batch full (100 diffs) or timeout:
   │
7. Server submits Merkle root to blockchain
   │
8. Client receives confirmation, renders new fractal
```

### Batch Aggregation

```
Individual actions → DogStateManager
                          │
                          ▼
                   BatchAggregator
                          │
              ┌───────────┴───────────┐
              │   Collect 100 diffs   │
              │   OR 60s timeout      │
              └───────────┬───────────┘
                          │
                          ▼
               Compute Merkle root
                          │
                          ▼
            Submit single transaction
                          │
                          ▼
               ~80 gas per dog action
```

## Security Model

### Threat Mitigation

| Threat | Mitigation |
|--------|------------|
| Bot farming | Rate limiting + pattern detection |
| State manipulation | Server-side validation + blockchain proof |
| Replay attacks | Nonce tracking + signature verification |
| Data theft | No PII stored, public blockchain |

### Trust Boundaries

```
Trusted:      Pony server (validates all actions)
Trustless:    Blockchain (anyone can verify)
Untrusted:    Android client (never trust client state)
```

## Configuration

All configuration via Nickel for type safety:

- `config/project.ncl`: Project metadata, RSR compliance
- `config/game.ncl`: Economy, fractals, anti-cheat
- `config/ci.ncl`: GitLab CI pipeline

Exported to JSON/Dhall for runtime consumption.

## Deployment

```bash
# Development
nix develop
just build-all

# Container (Podman + Wolfi)
just container-build
just container-run

# Blockchain
just contracts-deploy testnet
just contracts-verify testnet $ADDRESS
```
