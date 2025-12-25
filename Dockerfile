# Base image: Ubuntu 24.04 (Noble) for ARM64
FROM ubuntu:24.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Host Dependencies (ARM64)
# We need python3/curl/etc for the build process and FEX dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    jq \
    gnupg \
    software-properties-common \
    sudo \
    tar \
    xz-utils \
    unzip \
    libgl1-mesa-dri \
    libglx-mesa0 \
    libvulkan1 \
    mesa-vulkan-drivers \
    xvfb \
    cabextract \
    libx11-6 \
    libxcomposite1 \
    libxcursor1 \
    libxi6 \
    libxtst6 \
    libxrandr2 \
    libfreetype6 \
    libfontconfig1 \
    libdbus-1-3 \
    && rm -rf /var/lib/apt/lists/*

# 2. Install FEX-Emu (Host)
RUN add-apt-repository -y ppa:fex-emu/fex && \
    apt-get update && \
    apt-get install -y fex-emu-armv8.2 && \
    rm -rf /var/lib/apt/lists/*

# 3. Setup FEX User and RootFS
# We create a generic user 'fex' but we might run as root in container context for simplicity with Easypanel permissions,
# however FEX prefers a user. We'll set up the rootfs for the root user or a dedicated user.
# Let's stick to root for Docker simplicity unless specified.
# FEX RootFS path: /root/.fex-emu/RootFS/Ubuntu_22.04

WORKDIR /root

# Download and Extract FEX RootFS (Ubuntu 22.04 x86-64)
# We parse the official index to find the URL for Ubuntu 22.04
RUN echo "Fetching FEX RootFS..." && \
    ROOTFS_INFO=$(curl -s https://rootfs.fex-emu.gg/RootFS_links.json) && \
    ROOTFS_URL=$(echo "$ROOTFS_INFO" | jq -r '.v1 | to_entries[] | select(.value.DistroMatch == "ubuntu" and .value.DistroVersion == "22.04") | .value.URL' | head -n 1) && \
    curl -L -o rootfs.img "$ROOTFS_URL" && \
    mkdir -p /root/.fex-emu/RootFS/Ubuntu_22.04 && \
    if echo "$ROOTFS_URL" | grep -q ".ero$"; then \
    echo "Extracting EroFS..." && \
    fsck.erofs --extract=/root/.fex-emu/RootFS/Ubuntu_22.04 rootfs.img; \
    else \
    echo "Extracting SquashFS..." && \
    unsquashfs -f -d /root/.fex-emu/RootFS/Ubuntu_22.04 rootfs.img; \
    fi && \
    rm rootfs.img && \
    mkdir -p /root/.fex-emu && \
    echo '{"Config":{"RootFS":"Ubuntu_22.04"}}' > /root/.fex-emu/Config.json

# 4. Install Wine (x86-64) - Kron4ek Builds (Staging)
# We place this in a standard location. FEX will execute the binaries inside.
# Note: FEX will use the libraries from the RootFS to satisfy Wine's dependencies.
ENV WINE_VERSION="9.4"
# Using a static link or a known release. Let's use a recent 9.x staging.
# URL format example: https://github.com/Kron4ek/Wine-Builds/releases/download/9.4/wine-9.4-staging-amd64.tar.xz

RUN echo "Installing Wine (x86-64)..." && \
    WINE_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/9.4/wine-9.4-staging-amd64.tar.xz" && \
    curl -L -o wine.tar.xz "$WINE_URL" && \
    tar -xf wine.tar.xz -C /opt && \
    mv /opt/wine-9.4-staging-amd64 /opt/wine && \
    rm wine.tar.xz

# Add Wine to PATH (This path works when running standard shell IF FEX intercepts it, 
# but usually we invoke via FEXInterpreter for absolute clarity or rely on binfmt_misc)
ENV PATH="/opt/wine/bin:$PATH"

# 5. Setup SteamCMD (Linux x86)
# run via FEX
RUN mkdir -p /steamcmd && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C /steamcmd

# 6. Environment Variables
ENV STEAMCMD_DIR="/steamcmd"
ENV SERVER_DIR="/data/server"
ENV WINEPREFIX="/data/wineprefix"
ENV WINEARCH="win64"
ENV DISPLAY=":0" 
# Configure FEX to allow some optimizations (optional)
# ENV FEX_APP_DATA_LOCATION="/root/.fex-emu"

# 7. Add Scripts
COPY scripts/start.sh /start.sh
COPY scripts/update_server.sh /update_server.sh
RUN chmod +x /start.sh /update_server.sh

# 8. Expose Ports (V Rising Default: 9876, 9877 UDP)
EXPOSE 9876/udp 9877/udp 9876/tcp 9877/tcp

# 9. Volume for persistence
VOLUME ["/data"]

# Entrypoint
ENTRYPOINT ["/start.sh"]
