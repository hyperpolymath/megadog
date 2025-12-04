# MegaDog Android Builder Container
# RSR Compliant: Podman + Wolfi-based build environment
# For CI/CD pipeline Android builds

FROM cgr.dev/chainguard/wolfi-base:latest AS android-sdk

# Install build dependencies
RUN apk add --no-cache \
    openjdk-17 \
    wget \
    unzip \
    git \
    bash

# Set up Android SDK
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    cd ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip && \
    unzip -q tools.zip && \
    rm tools.zip && \
    mv cmdline-tools latest

# Accept licenses and install SDK components
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# =============================================================================
# BUILD STAGE
# =============================================================================
FROM android-sdk AS builder

WORKDIR /build

# Copy Android project
COPY android/ ./android/
COPY config/ ./config/

# Build APK
RUN cd android && ./gradlew assembleRelease --no-daemon

# =============================================================================
# OUTPUT STAGE - Extract artifacts
# =============================================================================
FROM cgr.dev/chainguard/wolfi-base:latest AS artifacts

WORKDIR /output

COPY --from=builder /build/android/app/build/outputs/apk/release/*.apk ./

# Final container just holds the APK
CMD ["ls", "-la", "/output"]
