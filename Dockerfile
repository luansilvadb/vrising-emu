# =============================================================================
# V Rising Dedicated Server - ARM64 Production Dockerfile
# =============================================================================
# Battle-tested configuration based on tsx-cloud/vrising-ntsync
# Optimized for Oracle Ampere / ARM64 with BepInEx support
#
# Build time: ~20-40 minutes (first build)
# Image size: ~3-4GB
#
# CROSS-REFERENCE VERIFIED with:
# - https://github.com/tsx-cloud/vrising-ntsync
# - https://github.com/Kron4ek/Wine-Builds/releases
# =============================================================================

# Build argument for Wine version (can be overridden)
ARG WINE_VERSION=11.0-rc3

# -----------------------------------------------------------------------------
# Stage 1: Build Box64 (x86_64 emulation for ARM64)
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
    -DNO_LIB_INSTALL=1 \
    -DNO_CONF_INSTALL=1 && \
    make -j$(nproc) && \
    make DESTDIR=/box64-install install

# -----------------------------------------------------------------------------
# Stage 2: Build Box86 (x86 emulation for 32-bit SteamCMD)
# Using native ARM build with cross-compile toolchain
# -----------------------------------------------------------------------------
FROM arm64v8/debian:bookworm-slim AS box86-builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies and cross-compile toolchain
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
    -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc \
    -DNO_LIB_INSTALL=1 \
    -DNO_CONF_INSTALL=1 && \
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

# Box64 - STABILITY settings (tsx-cloud verified)
# Change these for performance at your own risk
ENV BOX64_DYNAREC=1
ENV BOX64_DYNAREC_STRONGMEM=1
ENV BOX64_DYNAREC_BIGBLOCK=0
ENV BOX64_DYNAREC_SAFEFLAGS=1
ENV BOX64_NOBANNER=1
ENV BOX64_LOG=0

# Box86 settings
ENV BOX86_NOBANNER=1
ENV BOX86_LOG=0
ENV BOX86_DYNAREC=1

# Paths
ENV SERVER_PATH=/mnt/vrising/server
ENV DATA_PATH=/mnt/vrising/persistentdata
ENV LOG_PATH=/mnt/vrising/persistentdata/logs
ENV STEAMCMD_PATH=/opt/steamcmd
ENV WINE_PATH=/opt/wine

# Wine version from build arg
ARG WINE_VERSION
ENV WINE_VERSION=${WINE_VERSION}

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
    kmod \
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
# Note: Box64 installs libs to /usr/lib/box64* which doesn't respect DESTDIR
# We only need the binary for emulation
# -----------------------------------------------------------------------------
COPY --from=box64-builder /box64-install/usr/local/bin/box64 /usr/local/bin/box64

# -----------------------------------------------------------------------------
# Copy Box86 from builder  
# -----------------------------------------------------------------------------
COPY --from=box86-builder /box86-install/usr/local/bin/box86 /usr/local/bin/box86

# Update library cache
RUN ldconfig

# Verify emulators work
RUN echo "Verifying Box64..." && box64 --version 2>&1 | head -1 && \
    echo "Verifying Box86..." && box86 --version 2>&1 | head -1

# -----------------------------------------------------------------------------
# Register Box64/Box86 with binfmt_misc for automatic x86/x86_64 emulation
# This allows scripts like steamcmd.sh to work transparently
# -----------------------------------------------------------------------------
RUN mkdir -p /etc/binfmt.d && \
    # Box64 for x86_64 ELF binaries
    echo ':box64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfe\xff\xff\xff:/usr/local/bin/box64:CF' > /etc/binfmt.d/box64.conf && \
    # Box86 for x86 (32-bit) ELF binaries
    echo ':box86:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfe\xff\xff\xff:/usr/local/bin/box86:CF' > /etc/binfmt.d/box86.conf && \
    echo "binfmt_misc config files created"

# -----------------------------------------------------------------------------
# Install Wine (Staging TKG with WoW64)
# Using Kron4ek builds - cross-reference verified 2025-12-25
# Available: wine-11.0-rc3-staging-tkg-amd64-wow64.tar.xz
# -----------------------------------------------------------------------------
RUN mkdir -p ${WINE_PATH} && \
    cd /tmp && \
    echo "Downloading Wine ${WINE_VERSION}..." && \
    # Try different Wine builds in order of preference
    (wget "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-staging-tkg-amd64-wow64.tar.xz" -O wine.tar.xz || \
    wget "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-staging-amd64-wow64.tar.xz" -O wine.tar.xz || \
    wget "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-amd64-wow64.tar.xz" -O wine.tar.xz || \
    wget "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-amd64.tar.xz" -O wine.tar.xz) && \
    # Verify download succeeded
    ls -la wine.tar.xz && \
    test -s wine.tar.xz || (echo "ERROR: Wine download failed!" && exit 1) && \
    # Show archive structure for debugging
    echo "=== Wine archive structure (first 30 files) ===" && \
    tar -tf wine.tar.xz | head -30 && \
    echo "==============================" && \
    # Extract Wine
    echo "Extracting Wine to ${WINE_PATH}..." && \
    tar -xf wine.tar.xz -C ${WINE_PATH} --strip-components=1 && \
    rm -f wine.tar.xz && \
    # Show what was extracted
    echo "=== Contents of ${WINE_PATH} ===" && \
    ls -la ${WINE_PATH}/ && \
    echo "=== Looking for wine binaries ===" && \
    find ${WINE_PATH} -name "wine*" -type f 2>/dev/null | head -10 && \
    # Find wine binary - SEARCH ONLY IN BIN to avoid .so library files!
    WINE_BIN_PATH=$(find ${WINE_PATH}/bin -name "wine64" -o -name "wine" 2>/dev/null | grep -v "\.so" | head -1) && \
    echo "Found wine binary at: $WINE_BIN_PATH" && \
    test -n "$WINE_BIN_PATH" || (echo "ERROR: No wine binary found!" && exit 1) && \
    # Determine Wine directory structure
    WINE_BIN_DIR=$(dirname "$WINE_BIN_PATH") && \
    echo "Wine bin directory: $WINE_BIN_DIR" && \
    # Find Wine library directories dynamically
    WINE_LIB_UNIX=$(find ${WINE_PATH} -type d -path "*/lib*/wine/x86_64-unix" 2>/dev/null | head -1) && \
    WINE_LIB_BASE=$(dirname "$WINE_LIB_UNIX" 2>/dev/null) && \
    if [ -z "$WINE_LIB_UNIX" ]; then \
    echo "WARN: Could not find x86_64-unix lib directory, using defaults" && \
    WINE_LIB_UNIX="${WINE_PATH}/lib/wine/x86_64-unix" && \
    WINE_LIB_BASE="${WINE_PATH}/lib/wine"; \
    fi && \
    echo "Wine lib directories:" && \
    echo "  Unix libs: $WINE_LIB_UNIX" && \
    echo "  Base libs: $WINE_LIB_BASE" && \
    # Create Wine wrapper scripts with dynamic paths
    echo '#!/bin/bash' > /usr/local/bin/wine64 && \
    echo "export BOX64_LD_LIBRARY_PATH=\"$WINE_LIB_UNIX:$WINE_LIB_BASE:\$BOX64_LD_LIBRARY_PATH\"" >> /usr/local/bin/wine64 && \
    echo "exec box64 $WINE_BIN_PATH \"\$@\"" >> /usr/local/bin/wine64 && \
    chmod +x /usr/local/bin/wine64 && \
    echo '#!/bin/bash' > /usr/local/bin/wine && \
    echo "export BOX64_LD_LIBRARY_PATH=\"$WINE_LIB_UNIX:$WINE_LIB_BASE:\$BOX64_LD_LIBRARY_PATH\"" >> /usr/local/bin/wine && \
    echo "exec box64 $WINE_BIN_PATH \"\$@\"" >> /usr/local/bin/wine && \
    chmod +x /usr/local/bin/wine && \
    echo '#!/bin/bash' > /usr/local/bin/wineserver && \
    echo "export BOX64_LD_LIBRARY_PATH=\"$WINE_LIB_UNIX:$WINE_LIB_BASE:\$BOX64_LD_LIBRARY_PATH\"" >> /usr/local/bin/wineserver && \
    echo "exec box64 $WINE_BIN_DIR/wineserver \"\$@\"" >> /usr/local/bin/wineserver && \
    chmod +x /usr/local/bin/wineserver && \
    echo '#!/bin/bash' > /usr/local/bin/wineboot && \
    echo "export BOX64_LD_LIBRARY_PATH=\"$WINE_LIB_UNIX:$WINE_LIB_BASE:\$BOX64_LD_LIBRARY_PATH\"" >> /usr/local/bin/wineboot && \
    echo "exec box64 $WINE_BIN_DIR/wineboot \"\$@\"" >> /usr/local/bin/wineboot && \
    chmod +x /usr/local/bin/wineboot && \
    echo '#!/bin/bash' > /usr/local/bin/winecfg && \
    echo "export BOX64_LD_LIBRARY_PATH=\"$WINE_LIB_UNIX:$WINE_LIB_BASE:\$BOX64_LD_LIBRARY_PATH\"" >> /usr/local/bin/winecfg && \
    echo "exec box64 $WINE_BIN_DIR/winecfg \"\$@\"" >> /usr/local/bin/winecfg && \
    chmod +x /usr/local/bin/winecfg && \
    echo "Wine ${WINE_VERSION} installed and wrappers created successfully"

# -----------------------------------------------------------------------------
# Install SteamCMD
# -----------------------------------------------------------------------------
RUN mkdir -p ${STEAMCMD_PATH} && \
    cd ${STEAMCMD_PATH} && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - && \
    chmod +x steamcmd.sh

# Create robust SteamCMD wrapper script
# This runs linux32/steamcmd directly via Box86 (binary is included in tar.gz)
RUN echo '#!/bin/bash' > /usr/local/bin/steamcmd.sh && \
    echo '# SteamCMD wrapper for ARM64 with Box86 emulation' >> /usr/local/bin/steamcmd.sh && \
    echo '' >> /usr/local/bin/steamcmd.sh && \
    echo '# Box86 configuration for stability' >> /usr/local/bin/steamcmd.sh && \
    echo 'export BOX86_NOBANNER=1' >> /usr/local/bin/steamcmd.sh && \
    echo 'export BOX86_LOG=0' >> /usr/local/bin/steamcmd.sh && \
    echo 'export BOX86_DYNAREC_STRONGMEM=1' >> /usr/local/bin/steamcmd.sh && \
    echo 'export BOX86_LD_LIBRARY_PATH="/opt/steamcmd/linux32"' >> /usr/local/bin/steamcmd.sh && \
    echo '' >> /usr/local/bin/steamcmd.sh && \
    echo 'cd /opt/steamcmd' >> /usr/local/bin/steamcmd.sh && \
    echo '' >> /usr/local/bin/steamcmd.sh && \
    echo '# Run linux32/steamcmd directly with Box86 (no exec to handle self-updates)' >> /usr/local/bin/steamcmd.sh && \
    echo 'box86 /opt/steamcmd/linux32/steamcmd +@sSteamCmdForcePlatformBitness 32 "$@"' >> /usr/local/bin/steamcmd.sh && \
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
# Create emulators.rc (tsx-cloud compatible - STABILITY settings)
# -----------------------------------------------------------------------------
RUN echo '### BOX64 - STABILITY settings (tsx-cloud verified)' > /emulators.rc && \
    echo '### For performance tuning, modify BepInEx/addition_stuff/box64.rc' >> /emulators.rc && \
    echo '' >> /emulators.rc && \
    echo '# These settings prioritize STABILITY over performance:' >> /emulators.rc && \
    echo 'export BOX64_DYNAREC_STRONGMEM=1' >> /emulators.rc && \
    echo 'export BOX64_DYNAREC_BIGBLOCK=0' >> /emulators.rc && \
    echo '' >> /emulators.rc && \
    echo '### FEX-EMU (if used instead of Box64)' >> /emulators.rc && \
    echo '# export FEX_PARANOIDTSO=true' >> /emulators.rc && \
    chmod +x /emulators.rc

# Create load script for emulators
RUN echo '#!/bin/bash' > /load_emulators_env.sh && \
    echo 'if [ -f /emulators.rc ]; then' >> /load_emulators_env.sh && \
    echo '    source /emulators.rc' >> /load_emulators_env.sh && \
    echo 'fi' >> /load_emulators_env.sh && \
    chmod +x /load_emulators_env.sh

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
