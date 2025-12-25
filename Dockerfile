# =============================================================================
# V Rising Dedicated Server - ARM64 Production Dockerfile
# =============================================================================
# Battle-tested configuration based on tsx-cloud/vrising-ntsync
# Optimized for Oracle Ampere / ARM64 with BepInEx support
#
# Build time: ~20-40 minutes (first build)
# Image size: ~3-4GB
#
# Features:
# - Ubuntu 25.04 (NTSync kernel support)
# - Box64 (x86_64 emulation for ARM64)
# - Box86 (x86 emulation for SteamCMD)
# - Wine Staging with NTSync + WoW64
# - SteamCMD (32-bit via Box86)
# - BepInEx with ARM64 patches (pre-configured)
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build Box64
# -----------------------------------------------------------------------------
FROM ubuntu:25.04 AS box64-builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    ca-certificates \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --depth 1 https://github.com/ptitSeb/box64.git && \
    cd box64 && \
    mkdir build && cd build && \
    cmake .. \
    -DARM_DYNAREC=ON \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBAD_SIGNAL=ON \
    -DBOX64_MINIMAL=0 && \
    make -j$(nproc) && \
    make DESTDIR=/box64-install install

# -----------------------------------------------------------------------------
# Stage 2: Build Box86 (for 32-bit SteamCMD)
# -----------------------------------------------------------------------------
FROM arm64v8/debian:bookworm-slim AS box86-builder

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture armhf && \
    apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    ca-certificates \
    python3 \
    gcc-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --depth 1 https://github.com/ptitSeb/box86.git && \
    cd box86 && \
    mkdir build && cd build && \
    cmake .. \
    -DARM_DYNAREC=ON \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DRPI4ARM64=1 \
    -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc && \
    make -j$(nproc) && \
    make DESTDIR=/box86-install install

# -----------------------------------------------------------------------------
# Stage 3: Runtime Image
# -----------------------------------------------------------------------------
FROM ubuntu:25.04 AS runtime

LABEL maintainer="VRising ARM64 Project"
LABEL description="V Rising Dedicated Server with BepInEx for ARM64"
LABEL version="2.0.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
ENV DISPLAY=:0

# Wine configuration
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64
ENV WINEDEBUG=-all

# Server defaults
ENV TZ=UTC
ENV SERVERNAME="V Rising Server"
ENV ENABLE_PLUGINS=false
ENV LOGDAYS=30
ENV UPDATE_SERVER=true

# Steam App ID for V Rising Dedicated Server
ENV STEAM_APP_ID=1829350

# Box64 performance tuning (production optimized)
ENV BOX64_DYNAREC=1
ENV BOX64_DYNAREC_FASTROUND=1
ENV BOX64_DYNAREC_FASTNAN=1
ENV BOX64_DYNAREC_SAFEFLAGS=0
ENV BOX64_DYNAREC_BIGBLOCK=2
ENV BOX64_DYNAREC_STRONGMEM=0
ENV BOX64_DYNAREC_BLEEDING_EDGE=1
ENV BOX64_MALLOC_HACK=1
ENV BOX64_NOBANNER=1
ENV BOX64_LOG=0

# Box86 performance tuning
ENV BOX86_NOBANNER=1
ENV BOX86_LOG=0
ENV BOX86_DYNAREC=1

# Paths
ENV SERVER_PATH=/mnt/vrising/server
ENV DATA_PATH=/mnt/vrising/persistentdata
ENV LOG_PATH=/mnt/vrising/persistentdata/logs
ENV STEAMCMD_PATH=/opt/steamcmd
ENV WINE_PATH=/opt/wine

# -----------------------------------------------------------------------------
# Install base dependencies
# -----------------------------------------------------------------------------
RUN dpkg --add-architecture armhf && \
    apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    ca-certificates \
    curl \
    wget \
    gnupg2 \
    xz-utils \
    tar \
    unzip \
    procps \
    nano \
    lsof \
    # X11/Display (for Wine)
    xvfb \
    x11-utils \
    # Wine dependencies
    cabextract \
    winbind \
    # Winetricks
    winetricks \
    # 32-bit libraries for Box86/SteamCMD
    libc6:armhf \
    libstdc++6:armhf \
    # Timezone
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# -----------------------------------------------------------------------------
# Copy Box64 from builder
# -----------------------------------------------------------------------------
COPY --from=box64-builder /box64-install/usr/local/bin/box64 /usr/local/bin/box64
COPY --from=box64-builder /box64-install/usr/local/lib /usr/local/lib

# -----------------------------------------------------------------------------
# Copy Box86 from builder  
# -----------------------------------------------------------------------------
COPY --from=box86-builder /box86-install/usr/local/bin/box86 /usr/local/bin/box86

# Update library cache
RUN ldconfig

# -----------------------------------------------------------------------------
# Install Wine (Staging with NTSync support)
# Latest stable version from Kron4ek builds
# -----------------------------------------------------------------------------
ARG WINE_VERSION=10.15

RUN mkdir -p ${WINE_PATH} && \
    cd /tmp && \
    # Try multiple Wine build variants in order of preference
    (wget -q "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-staging-tkg-ntsync-amd64-wow64.tar.xz" -O wine.tar.xz || \
    wget -q "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-staging-tkg-amd64-wow64.tar.xz" -O wine.tar.xz || \
    wget -q "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-staging-amd64.tar.xz" -O wine.tar.xz) && \
    tar -xf wine.tar.xz -C ${WINE_PATH} --strip-components=1 && \
    rm -f wine.tar.xz && \
    # Create symlinks for Wine binaries
    ln -sf ${WINE_PATH}/bin/wine64 /usr/local/bin/wine64 && \
    ln -sf ${WINE_PATH}/bin/wine /usr/local/bin/wine && \
    ln -sf ${WINE_PATH}/bin/wineserver /usr/local/bin/wineserver && \
    ln -sf ${WINE_PATH}/bin/wineboot /usr/local/bin/wineboot && \
    ln -sf ${WINE_PATH}/bin/winecfg /usr/local/bin/winecfg

# -----------------------------------------------------------------------------
# Install SteamCMD
# -----------------------------------------------------------------------------
RUN mkdir -p ${STEAMCMD_PATH} && \
    cd ${STEAMCMD_PATH} && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - && \
    chmod +x steamcmd.sh && \
    # Create wrapper script for SteamCMD
    echo '#!/bin/bash' > /usr/local/bin/steamcmd.sh && \
    echo 'cd ${STEAMCMD_PATH} && ./steamcmd.sh "$@"' >> /usr/local/bin/steamcmd.sh && \
    chmod +x /usr/local/bin/steamcmd.sh

# -----------------------------------------------------------------------------
# Create directory structure
# -----------------------------------------------------------------------------
RUN mkdir -p \
    ${SERVER_PATH} \
    ${DATA_PATH}/Settings \
    ${DATA_PATH}/Saves \
    ${LOG_PATH} \
    /opt/defaults/server \
    /opt/scripts

# -----------------------------------------------------------------------------
# Copy BepInEx defaults and scripts
# -----------------------------------------------------------------------------
COPY bepinex/ /opt/defaults/server/
COPY scripts/ /opt/scripts/
COPY config/ /opt/defaults/config/

# Make scripts executable
RUN chmod +x /opt/scripts/*.sh 2>/dev/null || true

# -----------------------------------------------------------------------------
# Copy and configure entrypoint
# -----------------------------------------------------------------------------
COPY entrypoint.sh /start.sh
RUN chmod +x /start.sh

# Create emulators config
RUN echo '# Box64/Box86 runtime configuration' > /emulators.rc && \
    echo 'export BOX64_DYNAREC=1' >> /emulators.rc && \
    echo 'export BOX64_DYNAREC_BIGBLOCK=2' >> /emulators.rc && \
    echo 'export BOX64_DYNAREC_FASTROUND=1' >> /emulators.rc && \
    echo 'export BOX64_DYNAREC_FASTNAN=1' >> /emulators.rc && \
    echo 'export BOX64_DYNAREC_SAFEFLAGS=0' >> /emulators.rc && \
    echo 'export BOX64_DYNAREC_BLEEDING_EDGE=1' >> /emulators.rc && \
    echo 'export BOX64_MALLOC_HACK=1' >> /emulators.rc

# -----------------------------------------------------------------------------
# Volumes
# -----------------------------------------------------------------------------
VOLUME ["${SERVER_PATH}", "${DATA_PATH}"]

# -----------------------------------------------------------------------------
# Ports
# Game Port (UDP) - Required
EXPOSE 9876/udp
# Query Port (UDP) - For server browser
EXPOSE 9877/udp
# RCON Port (TCP) - Optional, for remote administration
EXPOSE 25575/tcp
# API/Metrics Port (TCP) - Optional, for monitoring
EXPOSE 9090/tcp

# -----------------------------------------------------------------------------
# Health Check
# Start period is long because first boot downloads ~8GB of game files
# -----------------------------------------------------------------------------
HEALTHCHECK --interval=60s --timeout=10s --start-period=600s --retries=3 \
    CMD pgrep -f VRisingServer.exe || exit 1

# -----------------------------------------------------------------------------
# Entrypoint
# -----------------------------------------------------------------------------
WORKDIR ${SERVER_PATH}
ENTRYPOINT []
CMD ["/start.sh"]
