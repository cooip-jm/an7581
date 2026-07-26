#!/bin/bash
# Local build script using Docker
# Builds OpenWrt firmware for AN7581 and creates rootfs for LXC testing
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="/workspace"
CONTAINER="an7581-build"
IMAGE="ubuntu:22.04"

echo "=== AN7581 Local Build Script ==="

# Check if Docker is available
if ! command -v docker &>/dev/null; then
    echo "Docker not found. Install Docker first."
    exit 1
fi

# Build Docker image if needed
if ! docker inspect "$IMAGE" &>/dev/null 2>&1; then
    echo "Pulling $IMAGE..."
    docker pull "$IMAGE"
fi

# Create container if not exists
if ! docker inspect "$CONTAINER" &>/dev/null 2>&1; then
    echo "Creating build container..."
    docker run -d --name "$CONTAINER" \
        -v "$SCRIPT_DIR:$WORKSPACE" \
        -w "$WORKSPACE" \
        "$IMAGE" \
        sleep infinity
fi

# Install build deps inside container
echo "Installing build dependencies..."
docker exec "$CONTAINER" bash -c '
    apt-get update && apt-get install -y \
    ack antlr3 asciidoc autoconf automake autopoint binutils \
    bison build-essential bzip2 ccache cmake cpio curl \
    device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib \
    g++-multilib git gnutls-dev gperf haveged help2man intltool \
    lib32gcc-s1 libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev \
    libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev \
    libncursesw5-dev libpython3-dev libreadline-dev libssl-dev \
    libtool libz-dev lrzsz mkisofs msmtp nano ninja-build p7zip \
    p7zip-full patch pkgconf python3 python3-pip \
    python3-ply python3-pyelftools python3-setuptools qemu-utils \
    rsync scons squashfs-tools subversion swig texinfo \
    uglifyjs unzip upx-ucl vim wget xmlto xxd zlib1g-dev 2>/dev/null
' 2>/dev/null || true

# Clone OpenWrt if not present
docker exec "$CONTAINER" bash -c "
    if [ ! -d '$WORKSPACE/openwrt' ]; then
        echo 'Cloning OpenWrt...'
        git clone --depth 1 https://git.openwrt.org/openwrt/openwrt.git '$WORKSPACE/openwrt'
    fi
"

# Configure and build
docker exec "$CONTAINER" bash -c "
    cd '$WORKSPACE/openwrt'

    # Update feeds
    ./scripts/feeds update -a
    ./scripts/feeds install -a

    # Configure
    cat > .config <<'CONFIG'
CONFIG_TARGET_airoha=y
CONFIG_TARGET_airoha_an7581=y
CONFIG_TARGET_airoha_an7581_DEVICE_nokia_xg-040g-md=y
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-lib-ipkg=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_uhttpd=y
CONFIG_PACKAGE_lua=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_uci=y
CONFIG_PACKAGE_jshn=y
CONFIG_PACKAGE_jsonfilter=y
CONFIG
    make defconfig

    # Download sources
    make download -j\$(nproc)

    # Build
    make -j\$(nproc) || make -j1 V=s
"

# Extract and package
docker exec "$CONTAINER" bash -c "
    cd '$WORKSPACE'
    mkdir -p output/release

    # Find firmware
    FIRMWARE_DIR=\$(find openwrt/bin/targets -type d | head -1)
    if [ -d \"\$FIRMWARE_DIR\" ]; then
        cp \"\$FIRMWARE_DIR\"/*.bin \"\$FIRMWARE_DIR\"/*.img.gz 2>/dev/null output/release/ || true
    fi

    # Create rootfs tarball from build
    if [ -d openwrt/staging_dir/target-aarch64_cortex-a53_musl/rootfs ]; then
        tar czf output/release/rootfs.tar.gz -C openwrt/staging_dir/target-aarch64_cortex-a53_musl/rootfs .
    fi

    # Add overlay
    tar czf output/release/luci-overlay.tar.gz -C luci-overlay .
    cp output/install_overlay.sh output/release/

    echo '=== Build Complete ==='
    ls -lh output/release/
"

echo "=== Done ==="
echo "Artifacts in: $SCRIPT_DIR/output/release/"
