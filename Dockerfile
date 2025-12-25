# =============================================================================
# V Rising Dedicated Server - ARM64 Dockerfile
# =============================================================================
# Optimized for Oracle Ampere / ARM64 with BepInEx support
# Based on tsx-cloud/vrising-ntsync with custom improvements
#
# Features:
# - Ubuntu 25.04 (NTSync kernel support)
# - Box64 (x86_64 emulation for ARM64)
# - Box86 (x86 emulation for SteamCMD)
# - Wine Staging 10.x with NTSync + WoW64
# - SteamCMD (32-bit via Box86)
# - BepInEx with ARM64 patches
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
    && rm -rf /var/lib/apt/lists/*

# Clone and build Box64 for ARM64
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

# Enable armhf architecture for 32-bit libraries
RUN dpkg --add-architecture armhf && \
    apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    ca-certificates \
    gcc-arm-linux-gnueabihf \
    libc6:armhf \
    && rm -rf /var/lib/apt/lists/*

# Clone and build Box86 for ARM64 host
WORKDIR /build
RUN git clone --depth 1 https://github.com/ptitSeb/box86.git && \
    cd box86 && \
    mkdir build && cd build && \
    cmake .. \
    -DARM_DYNAREC=ON \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DRPI4ARM64=1 && \
    make -j$(nproc) && \
    make DESTDIR=/box86-install install

# -----------------------------------------------------------------------------
# Stage 3: Runtime Image
# -----------------------------------------------------------------------------
FROM ubuntu:25.04 AS runtime

LABEL maintainer="VRising ARM64 Project"
LABEL description="V Rising Dedicated Server with BepInEx for ARM64"
LABEL version="1.0.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64
ENV WINEDEBUG=-all

# Server configuration defaults
ENV TZ=UTC
ENV SERVERNAME="V Rising Server"
ENV ENABLE_PLUGINS=false
ENV STEAM_APP_ID=1829350

# Wine/Box64 performance tuning
ENV WINE_LARGE_ADDRESS_AWARE=1
ENV BOX64_DYNAREC=1
ENV BOX64_DYNAREC_FASTROUND=1
ENV BOX64_DYNAREC_FASTNAN=1
ENV BOX64_DYNAREC_SAFEFLAGS=0
ENV BOX64_DYNAREC_BIGBLOCK=2
ENV BOX64_DYNAREC_STRONGMEM=0
ENV BOX64_DYNAREC_BLEEDING_EDGE=1
ENV BOX64_MALLOC_HACK=1

# Paths
ENV SERVER_PATH=/mnt/vrising/server
ENV DATA_PATH=/mnt/vrising/persistentdata
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
    # X11/Display (for Wine)
    xvfb \
    x11-utils \
    # Wine dependencies
    cabextract \
    winbind \
    # 32-bit libraries for Box86/SteamCMD
    libc6:armhf \
    libstdc++6:armhf \
    # Timezone
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Copy Box64 from builder
# -----------------------------------------------------------------------------
COPY --from=box64-builder /box64-install/usr/local/bin/box64 /usr/local/bin/box64
COPY --from=box64-builder /box64-install/usr/local/lib /usr/local/lib
RUN ldconfig

# -----------------------------------------------------------------------------
# Copy Box86 from builder
# -----------------------------------------------------------------------------
COPY --from=box86-builder /box86-install/usr/local/bin/box86 /usr/local/bin/box86

# Register Box64 and Box86 as binfmt interpreters
RUN mkdir -p /etc/binfmt.d && \
    echo ':box64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/local/bin/box64:' > /etc/binfmt.d/box64.conf && \
    echo ':box86:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/local/bin/box86:' > /etc/binfmt.d/box86.conf

# -----------------------------------------------------------------------------
# Install Wine (Staging with NTSync)
# -----------------------------------------------------------------------------
# Note: Check https://github.com/Kron4ek/Wine-Builds/releases for latest version
# Format: wine-{VERSION}-staging-tkg-{OPTIONS}-amd64.tar.xz
ENV WINE_VERSION=10.15
ENV WINE_BRANCH=staging-tkg-ntsync-amd64-wow64

RUN mkdir -p ${WINE_PATH} && \
    cd /tmp && \
    # Download Wine from Kron4ek builds
    # Try the exact URL, if it fails, build won't proceed
    wget -q "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-${WINE_BRANCH}.tar.xz" -O wine.tar.xz || \
    wget -q "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-staging-tkg-amd64-wow64.tar.xz" -O wine.tar.xz && \
    tar -xf wine.tar.xz -C ${WINE_PATH} --strip-components=1 && \
    rm wine.tar.xz && \
    # Create symlinks
    ln -sf ${WINE_PATH}/bin/wine64 /usr/local/bin/wine64 && \
    ln -sf ${WINE_PATH}/bin/wine /usr/local/bin/wine && \
    ln -sf ${WINE_PATH}/bin/wineserver /usr/local/bin/wineserver && \
    ln -sf ${WINE_PATH}/bin/wineboot /usr/local/bin/wineboot

# -----------------------------------------------------------------------------
# Install SteamCMD
# -----------------------------------------------------------------------------
RUN mkdir -p ${STEAMCMD_PATH} && \
    cd ${STEAMCMD_PATH} && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - && \
    chmod +x steamcmd.sh

# -----------------------------------------------------------------------------
# Create directory structure
# -----------------------------------------------------------------------------
RUN mkdir -p \
    ${SERVER_PATH} \
    ${DATA_PATH}/Settings \
    ${DATA_PATH}/Saves \
    /opt/bepinex \
    /opt/scripts

# -----------------------------------------------------------------------------
# Copy scripts
# -----------------------------------------------------------------------------
COPY scripts/ /opt/scripts/
RUN chmod +x /opt/scripts/*.sh

# -----------------------------------------------------------------------------
# Copy BepInEx (pre-patched for ARM64)
# -----------------------------------------------------------------------------
COPY bepinex/ /opt/bepinex/

# -----------------------------------------------------------------------------
# Copy config templates
# -----------------------------------------------------------------------------
COPY config/ /opt/config/

# -----------------------------------------------------------------------------
# Copy entrypoint
# -----------------------------------------------------------------------------
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# -----------------------------------------------------------------------------
# Volumes
# -----------------------------------------------------------------------------
VOLUME ["${SERVER_PATH}", "${DATA_PATH}"]

# -----------------------------------------------------------------------------
# Ports
# -----------------------------------------------------------------------------
# Game Port (UDP)
EXPOSE 9876/udp
# Query Port (UDP)
EXPOSE 9877/udp
# RCON Port (TCP)
EXPOSE 25575/tcp
# API/Metrics Port (TCP)
EXPOSE 9090/tcp

# -----------------------------------------------------------------------------
# Health Check
# -----------------------------------------------------------------------------
HEALTHCHECK --interval=60s --timeout=10s --start-period=300s --retries=3 \
    CMD pgrep -f VRisingServer || exit 1

# -----------------------------------------------------------------------------
# Entrypoint
# -----------------------------------------------------------------------------
WORKDIR ${SERVER_PATH}
ENTRYPOINT ["/entrypoint.sh"]
