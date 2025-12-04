# MegaDog Server Container
# RSR Compliant: Podman + Chainguard Wolfi base
# Ultra-minimal, supply-chain-secure, APK-based

# =============================================================================
# BUILD STAGE - Compile Pony server
# =============================================================================
FROM docker.io/ponylang/ponyc:latest AS builder

WORKDIR /build

# Copy server source
COPY server/ ./server/
COPY config/ ./config/

# Build the Pony server
RUN cd server && ponyc -o /build/output -b megadog-server

# =============================================================================
# RUNTIME STAGE - Wolfi base (minimal, secure)
# =============================================================================
FROM cgr.dev/chainguard/wolfi-base:latest

# Labels for container metadata
LABEL org.opencontainers.image.title="MegaDog Server"
LABEL org.opencontainers.image.description="Ethical merge game server - Pony + Mandelbrot dogtags"
LABEL org.opencontainers.image.source="https://gitlab.com/megadog/megadog"
LABEL org.opencontainers.image.licenses="AGPL-3.0"
LABEL rsr.compliant="true"
LABEL rsr.container.runtime="podman"

# Install minimal runtime dependencies
RUN apk add --no-cache \
    libstdc++ \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Create non-root user (security best practice)
RUN adduser -D -u 1000 megadog
USER megadog

WORKDIR /app

# Copy compiled binary from builder
COPY --from=builder --chown=megadog:megadog /build/output/megadog-server /app/megadog-server

# Copy configuration
COPY --chown=megadog:megadog config/ /app/config/

# Expose server port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the server
ENTRYPOINT ["/app/megadog-server"]
CMD ["--config", "/app/config"]
