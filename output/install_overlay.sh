#!/bin/sh
# Install LuCI overlay onto AN7581 vendor rootfs
# Run this on the device after extracting the overlay
# WARNING: This replaces vendor web interface with LuCI

set -e

OVERLAY_DIR="/tmp/luci-overlay"
ROOT="/"

echo "=== AN7581 LuCI Overlay Installer ==="

# Check if running on AN7581
if ! grep -q "airoha" /proc/cpuinfo 2>/dev/null; then
    echo "WARNING: Not running on Airoha platform!"
    echo "Continue anyway? [y/N]"
    read answer
    [ "$answer" = "y" ] || exit 1
fi

# Stop vendor web server
echo "Stopping vendor thttpd..."
killall thttpd 2>/dev/null || true

# Backup vendor web
if [ -d /webs ] && [ ! -d /vendor_webs_bak ]; then
    echo "Backing up vendor web to /vendor_webs_bak..."
    mv /webs /vendor_webs_bak
fi

# Apply overlay files
echo "Applying overlay files..."
cd "${OVERLAY_DIR}"

# Create directories
find . -type d | while read d; do
    mkdir -p "${ROOT}${d#./}"
done

# Copy files
find . -type f | while read f; do
    target="${ROOT}${f#./}"
    echo "  ${f#./}"
    cp -f "${f}" "${target}"
done

# Make scripts executable
chmod 755 /usr/libexec/pon_helpers.sh 2>/dev/null || true
chmod 755 /usr/libexec/pon_apply_uci.sh 2>/dev/null || true
chmod 755 /etc/init.d/ecnt_xpon 2>/dev/null || true
chmod 755 /etc/init.d/xpon 2>/dev/null || true
chmod 755 /etc/init.d/vendor_web 2>/dev/null || true
chmod 755 /etc/uci-defaults/60-xpon-generate 2>/dev/null || true
chmod 755 /etc/hotplug.d/iface/20-pon 2>/dev/null || true

# Generate xpon.ani config from MAC if not present
if [ -f /etc/uci-defaults/60-xpon-generate ] && [ ! -s /etc/config/xpon ]; then
    /etc/uci-defaults/60-xpon-generate
fi

# Enable uhttpd
if [ -f /etc/init.d/uhttpd ]; then
    /etc/init.d/uhttpd enable 2>/dev/null || true
fi

echo ""
echo "=== Overlay installed ==="
echo "Next steps:"
echo "  1. Reboot the device"
echo "  2. Access LuCI at http://192.168.1.1"
echo "  3. Navigate to Network > PON Management"
echo "  4. Configure serial number if not auto-generated"
echo ""
echo "To revert to vendor web:"
echo "  killall uhttpd 2>/dev/null"
echo "  /vendor_webs_bak/thttpd -dd /vendor_webs_bak/ &"
