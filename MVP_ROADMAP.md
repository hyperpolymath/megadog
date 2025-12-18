# MegaDog MVP Roadmap

> The route to launching an ethical dog-merging blockchain game

## Current State Assessment

### ✅ Complete
- **Smart Contracts** (`contracts/MegaDog.vy`)
  - Logarithmic storage (30% gas savings)
  - Core mint/merge/prestige mechanics
  - Batch diff updates
  - Transparency functions

- **Pony Game Server** (`server/src/`)
  - Actor-based architecture (10 files)
  - Dog state management
  - Batch aggregation
  - Anti-cheat engine
  - WebSocket server
  - Blockchain client
  - Metrics collection
  - Connection management

- **Android App Foundation** (`android/`)
  - Build configuration
  - Basic dog/game models
  - Mandelbrot renderer (GPU)

- **Infrastructure**
  - Podman containerization
  - GitLab CI/CD pipeline
  - Guix/Nix package management

- **Security & CI/CD** (updated 2025-12-17)
  - SHA-pinned GitHub Actions (all 11 workflows)
  - SPDX-License-Identifier headers on all workflow files
  - OSSF Scorecard integration
  - CodeQL security analysis
  - TruffleHog secrets scanning
  - HTTPS-only policy enforcement
  - No weak crypto (MD5/SHA1) policy

### 🔄 In Progress (from STATE.scm)
- Bridge contracts (multi-chain)
- Tournament system
- Guild features
- GraphQL API

---

## Route to MVP Release

### Phase 1: Core Loop (Week 1-2)
**Goal: Playable dog merging on testnet**

```
┌─────────────────────────────────────────────────┐
│  1.1 Deploy Contracts to Mumbai Testnet         │
├─────────────────────────────────────────────────┤
│  • Configure deploy.dhall with Mumbai RPC       │
│  • Run: ./scripts/deploy.sh mumbai              │
│  • Verify on PolygonScan                        │
│  • Test mint_starter_dog() manually             │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│  1.2 Connect Pony Server to Contracts           │
├─────────────────────────────────────────────────┤
│  • Update config.pony with contract addresses   │
│  • Test blockchain_client.pony connection       │
│  • Verify batch submission works                │
│  • Run: make run (server)                       │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│  1.3 Android App WebSocket Connection           │
├─────────────────────────────────────────────────┤
│  • Implement GameClient.kt WebSocket            │
│  • Connect to Pony server                       │
│  • Test mint/merge flow                         │
│  • Verify fractal rendering                     │
└─────────────────────────────────────────────────┘
```

### Phase 2: Polish & Testing (Week 3)
**Goal: Stable, tested MVP**

| Task | Priority | Effort |
|------|----------|--------|
| Integration tests (Pony ↔ Vyper) | HIGH | 2 days |
| Load test (1000 concurrent) | HIGH | 1 day |
| UI polish (Android) | MEDIUM | 2 days |
| Anti-cheat tuning | MEDIUM | 1 day |
| Fractal export (wallpaper) | LOW | 1 day |

### Phase 3: Testnet Launch (Week 4)
**Goal: Public testnet beta**

- [ ] Deploy to Mumbai (Polygon testnet)
- [ ] Create testnet faucet integration
- [ ] Set up monitoring (Grafana/Prometheus)
- [ ] Write user documentation
- [ ] Announce beta on relevant channels
- [ ] Gather feedback

### Phase 4: Mainnet Launch (Week 5-6)
**Goal: Production release**

- [ ] Security audit (smart contracts)
- [ ] Performance optimization
- [ ] Deploy to Polygon mainnet
- [ ] F-Droid / APK distribution
- [ ] Community building

---

## Technical Checklist

### Before Testnet Deploy

```bash
# 1. Environment setup
export DEPLOYER_PRIVATE_KEY="0x..."
export SERVER_ADDRESS="0x..."
export POLYGONSCAN_API_KEY="..."

# 2. Contract deployment
cd /home/user/megadog
./scripts/deploy.sh mumbai

# 3. Server configuration
cd server
# Edit config.pony with contract addresses
make release

# 4. Infrastructure
podman-compose up -d postgres redis

# 5. Start server
./build/megadog-server

# 6. Android build
cd ../android
./gradlew assembleDebug
```

### Before Mainnet Deploy

- [ ] All tests passing (`make test`)
- [ ] Gas usage verified (< 4000 per dog action)
- [ ] Anti-cheat threshold tuned (> 90% accuracy)
- [ ] Batch size optimized (100 diffs default)
- [ ] Contract verified on PolygonScan
- [x] No hardcoded secrets in code (TruffleHog CI)
- [x] HTTPS only for all endpoints (CI enforced)
- [ ] Rate limiting configured
- [ ] Monitoring dashboards ready
- [x] SHA-pinned GitHub Actions (supply chain security)
- [x] SPDX license headers (compliance)

---

## Key Metrics (MVP Success Criteria)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Gas per dog action | < 4,000 | Contract analytics |
| Server throughput | > 1,000 ops/sec | Prometheus |
| Concurrent connections | > 5,000 | Connection manager |
| Fractal render FPS | > 30 | Android profiler |
| Anti-cheat accuracy | > 90% | ML validation |
| Testnet users (beta) | > 100 | User count |

---

## Risk Mitigation

### Technical Risks

| Risk | Mitigation |
|------|------------|
| Gas spikes on Polygon | Batch sizing + EIP-1559 management |
| Server overload | Actor isolation + rate limiting |
| Anti-cheat bypass | ML model + manual review |
| Fractal rendering slow | GPU shaders + LOD |

### Operational Risks

| Risk | Mitigation |
|------|------------|
| Contract exploit | Slither audit + time-locked upgrades |
| Data loss | PostgreSQL backups + blockchain state |
| DDoS attack | Rate limiting + CDN |

---

## Quick Start Commands

```bash
# Clone and setup
git clone https://gitlab.com/megadog/megadog
cd megadog

# Build everything
just build-all  # or manually:

# Server
cd server && make release

# Contracts
cd ../contracts && vyper MegaDog.vy

# Android
cd ../android && ./gradlew assembleDebug

# Deploy to testnet
./scripts/deploy.sh mumbai

# Start infrastructure
podman-compose up -d

# Run server
./server/build/megadog-server
```

---

## Timeline Summary

```
Week 1: Contract deployment + server integration
Week 2: Android connection + core loop testing
Week 3: Polish + testing + bug fixes
Week 4: Testnet beta launch
Week 5: Feedback incorporation
Week 6: Mainnet launch
```

**MVP Target: 6 weeks from now**

---

## Post-MVP Features (Backlog)

1. **Multi-chain Bridge** - Transfer dogs across chains
2. **Tournaments** - Competitive events with prizes
3. **Guilds** - Cooperative gameplay
4. **Advanced Fractals** - More fractal types, animations
5. **Social Features** - Friends, chat, sharing
6. **DAO Governance** - Community-driven parameters

---

## Contact & Resources

- **Repository**: https://gitlab.com/megadog/megadog
- **Documentation**: See `docs/` directory
- **STATE.scm**: Complete technical state
- **ECOSYSTEM.scm**: Tech stack overview
