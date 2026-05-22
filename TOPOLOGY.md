<!-- SPDX-License-Identifier: MPL-2.0 -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# MegaDog — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              ANDROID PLAYER             │
                        │        (Kotlin UI / Mandelbrot HUD)     │
                        └───────────────────┬─────────────────────┘
                                            │ WebSocket
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           PONY GAME SERVER              │
                        │    (Actor-based state, Anti-cheat)      │
                        └──────────┬───────────────────┬──────────┘
                                   │                   │
                                   ▼                   ▼
                        ┌───────────────────────┐  ┌────────────────────────────────┐
                        │ RENDERING ENGINE      │  │ LOGARITHMIC STORAGE            │
                        │ - GPU Mandelbrot      │  │ - ln(val) x 10^6               │
                        │ - Determ. Dogtags     │  │ - 50% Storage Reduction        │
                        └──────────┬────────────┘  └──────────┬─────────────────────┘
                                   │                          │
                                   └────────────┬─────────────┘
                                                ▼
                        ┌─────────────────────────────────────────┐
                        │           POLYGON BLOCKCHAIN            │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │ Vyper     │  │  NFT Ownership    │  │
                        │  │ Contracts │  │  (On-chain state) │  │
                        │  └───────────┘  └───────────────────┘  │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile Automation  .machine_readable/  │
                        │  Nix / Wolfi          0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CLIENT & RENDERER
  Android Client (Kotlin)           ██████████ 100%    Merge UI stable
  Mandelbrot GPU Renderer           ██████████ 100%    Deterministic tag generation
  WebSocket Integration             ████████░░  80%    Latency optimization active

GAME SERVER (PONY)
  Actor State Management            ██████████ 100%    Anti-cheat stable
  Batch Aggregation                 ████████░░  80%    Polygon bridge refining
  Logarithmic Storage Logic         ██████████ 100%    Gas savings verified

BLOCKCHAIN (VYPER)
  Polygon Contracts                 ██████████ 100%    Audit grade Vyper active
  NFT Metadata / Dogtags            ██████████ 100%    On-chain proof verified
  Contract Deployment               ████████░░  80%    Testnet validation active

REPO INFRASTRUCTURE
  Justfile Automation               ██████████ 100%    Standard build/run tasks
  .machine_readable/                ██████████ 100%    STATE tracking active
  Nix Development Env               ██████████ 100%    Hermetic builds verified

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            █████████░  ~90%   MVP stable and ethical
```

## Key Dependencies

```
Mandelbrot Seed ───► Pony Server ──────► Vyper Contract ──────► Polygon
     │                 │                   │                    │
     ▼                 ▼                   ▼                    ▼
 Android UI ◄──────► WebSocket ◄───────► NFT Ownership ◄─────── User
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
