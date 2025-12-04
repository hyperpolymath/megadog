# Contributing to MegaDog

## RSR Compliance Required

All contributions must follow the Rhodium Standard Repository specification.

### Before You Start

1. **Read the Manifesto** - Understand why we're building this
2. **Set up Nix** - `nix develop` for reproducible environment
3. **Run validations** - `just validate` must pass

### Code Standards

#### Languages (Memory-Safe Only)

| Component | Language | Rationale |
|-----------|----------|-----------|
| Server | Pony | Actor model, no GC pauses |
| Contracts | Vyper | Auditable, Pythonic |
| Android | Kotlin | Type-safe, JVM |
| Config | Nickel/Dhall | Type-safe configuration |
| Scripts | Bash | Where unavoidable |

**Not Allowed:**
- Python (except Vyper toolchain)
- JavaScript/TypeScript
- Go
- Anything with null pointer exceptions

#### Container Requirements

- **Podman only** (never Docker)
- **Wolfi base images** (Chainguard)
- **Non-root user** in containers
- **Multi-stage builds** for minimal images

#### Configuration

- **Nickel** for complex configs with validation
- **Dhall** for simpler typed configs
- **CUE** for schema validation
- **Never** raw JSON/YAML without schema

### Workflow

1. **Fork on GitLab** (not GitHub)
2. **Create feature branch**: `git checkout -b feature/amazing-thing`
3. **Make changes**
4. **Run RVC**: `just rvc` (Robot Vacuum Cleaner)
5. **Commit with conventional format**: `feat(server): add dog merging`
6. **Push and create MR**

### Commit Messages

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code restructure
- `test`: Tests
- `chore`: Maintenance

### Testing

```bash
# Server tests
just test-server

# Contract tests
just test-contracts

# All tests
just test-all
```

### Documentation

- Update `ARCHITECTURE.md` for structural changes
- Add inline comments for complex algorithms
- Keep `MANIFESTO.md` sacred (philosophy, not implementation)

### Security

- Never commit secrets
- Report vulnerabilities privately
- All crypto operations reviewed by maintainers

### Questions?

Open an issue on GitLab. We don't bite (the dogs might).
