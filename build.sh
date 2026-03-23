#!/bin/bash
# Local build script for OpenWrt CMCC PZ-L8 (AP Mode)
# Usage: ./build.sh [--clean]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
OPENWRT_DIR="openwrt"
PR_NUMBER="21495"
TARGET="qualcommax"
SUBTARGET="ipq50xx"
DEVICE="cmcc_pz-l8"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking build dependencies..."
    
    local missing=()
    local deps=(
        "build-essential" "clang" "flex" "bison" "g++" "gawk"
        "gcc-multilib" "g++-multilib" "gettext" "git" "libncurses-dev"
        "libssl-dev" "python3-distutils" "rsync" "swig" "unzip"
        "zlib1g-dev" "file" "wget" "curl" "jq" "device-tree-compiler"
    )
    
    for dep in "${deps[@]}"; do
        if ! dpkg -l "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_warn "Missing dependencies: ${missing[*]}"
        log_info "Installing missing dependencies..."
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi
    
    log_info "All dependencies satisfied."
}

clone_openwrt() {
    if [ -d "$OPENWRT_DIR" ]; then
        if [ "$1" == "--clean" ]; then
            log_info "Clean build requested, removing existing directory..."
            rm -rf "$OPENWRT_DIR"
        else
            log_info "OpenWrt directory already exists, updating..."
            cd "$OPENWRT_DIR"
            git fetch origin
            git reset --hard origin/main
            cd ..
            return
        fi
    fi
    
    log_info "Cloning OpenWrt repository..."
    git clone --depth 1 --single-branch --branch main \
        https://github.com/openwrt/openwrt.git "$OPENWRT_DIR"
}

apply_pr_patches() {
    log_info "Fetching and applying PR #$PR_NUMBER patches..."
    
    cd "$OPENWRT_DIR"
    
    # Fetch the PR
    git fetch origin "pull/$PR_NUMBER/head:pr-$PR_NUMBER"
    
    # Configure git
    git config user.email "builder@local"
    git config user.name "Local Builder"
    
    # Try to merge
    if git merge "pr-$PR_NUMBER" --no-edit; then
        log_info "PR #$PR_NUMBER merged successfully."
    else
        log_warn "Merge failed, trying cherry-pick..."
        
        # Get commits from PR
        COMMITS=$(git rev-list --reverse main..pr-$PR_NUMBER 2>/dev/null || true)
        
        if [ -n "$COMMITS" ]; then
            for commit in $COMMITS; do
                log_info "Cherry-picking: $(git log -1 --oneline $commit)"
                if ! git cherry-pick --strategy=recursive -X theirs $commit --no-commit; then
                    log_warn "Skipping problematic commit: $commit"
                    git cherry-pick --abort || true
                fi
            done
            git commit -m "Applied PR #$PR_NUMBER patches" --allow-empty || true
        fi
    fi
    
    cd ..
}

update_feeds() {
    log_info "Updating feeds..."
    cd "$OPENWRT_DIR"
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    cd ..
}

configure_build() {
    log_info "Configuring build..."
    
    cd "$OPENWRT_DIR"
    
    # Create configuration
    cat > .config << 'EOF'
# Target configuration
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq50xx=y
CONFIG_TARGET_qualcommax_ipq50xx_DEVICE_cmcc_pz-l8=y

# Build options
CONFIG_DEVEL=y
CONFIG_CCACHE=y
CONFIG_USE_CCACHE=y
CONFIG_EXTERNAL_TOOLCHAIN=n

# Image options
CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_ROOTFS_JFFS2=n
CONFIG_TARGET_ROOTFS_EXT4FS=n
CONFIG_TARGET_ROOTFS_TARGZ=n
CONFIG_TARGET_ROOTFS_CPIOGZ=n
CONFIG_TARGET_IMAGES_GZIP=y

# Kernel options
CONFIG_KERNEL_CRASHLOG=y
CONFIG_KERNEL_SWAP=y
CONFIG_KERNEL_DEBUG_FS=y
CONFIG_KERNEL_PERF_EVENTS=y

# Package build options
CONFIG_ALL_KMODS=y
CONFIG_ALL_NONSHARED=y

# Busybox minimal
CONFIG_BUSYBOX_CUSTOM=y
CONFIG_BUSYBOX_CONFIG_FEATURE_SH_IS_ASH=y

# Disable unwanted components
CONFIG_PACKAGE_dnsmasq=n
CONFIG_PACKAGE_dnsmasq-full=n
CONFIG_PACKAGE_odhcpd=n
CONFIG_PACKAGE_firewall=n
CONFIG_PACKAGE_firewall3=n
CONFIG_PACKAGE_firewall4=n
CONFIG_PACKAGE_ppp=n
CONFIG_PACKAGE_ppp-mod-pppoe=n
CONFIG_PACKAGE_luci-app-firewall=n

# Use mbedtls
CONFIG_PACKAGE_libustream-mbedtls=y
CONFIG_PACKAGE_libustream-openssl=n

# WPAD mesh
CONFIG_PACKAGE_wpad-mesh-mbedtls=y
CONFIG_PACKAGE_wpad-basic=n
CONFIG_PACKAGE_wpad-mini=n

# ath11k
CONFIG_PACKAGE_kmod-ath11k-ahb=y
CONFIG_PACKAGE_kmod-ath11k-smallbuffers=y
CONFIG_PACKAGE_ath11k-firmware-ipq5018-qcn6122=y
CONFIG_PACKAGE_ipq-wifi-cmcc_pz-l8=y

# LuCI minimal
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-package-manager-zh-cn=y
CONFIG_PACKAGE_luci-i18n-usteer-zh-cn=y
CONFIG_PACKAGE_luci-app-usteer=y
CONFIG_PACKAGE_uhttpd=y
CONFIG_PACKAGE_uhttpd-mod-ubus=y

# Disable full LuCI
CONFIG_PACKAGE_luci=n
CONFIG_PACKAGE_luci-ssl=n

# Mesh and usteer
CONFIG_PACKAGE_usteer=y

# Essential packages
CONFIG_PACKAGE_apk-mbedtls=y
CONFIG_PACKAGE_base-files=y
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_fstools=y
CONFIG_PACKAGE_kmod-gpio-button-hotplug=y
CONFIG_PACKAGE_kmod-leds-gpio=y
CONFIG_PACKAGE_kmod-qca-nss-dp=y
CONFIG_PACKAGE_libc=y
CONFIG_PACKAGE_libgcc=y
CONFIG_PACKAGE_logd=y
CONFIG_PACKAGE_mtd=y
CONFIG_PACKAGE_netifd=y
CONFIG_PACKAGE_procd-ujail=y
CONFIG_PACKAGE_uboot-envtools=y
CONFIG_PACKAGE_uci=y
CONFIG_PACKAGE_uclient-fetch=y
CONFIG_PACKAGE_urandom-seed=y
CONFIG_PACKAGE_urngd=y
CONFIG_PACKAGE_zram-swap=y
CONFIG_PACKAGE_iw=y
CONFIG_PACKAGE_iwinfo=y
EOF

    # Expand configuration
    make defconfig
    
    log_info "Configuration complete."
    log_info "Target: $TARGET/$SUBTARGET"
    log_info "Device: $DEVICE"
    
    cd ..
}

build_firmware() {
    log_info "Building firmware (this may take several hours)..."
    
    cd "$OPENWRT_DIR"
    
    # Download sources
    log_info "Downloading sources..."
    make download -j$(nproc) || make download -j1 V=s
    
    # Build
    log_info "Starting build..."
    make -j$(nproc) V=s || {
        log_warn "Build failed, trying single-threaded..."
        make -j1 V=s
    }
    
    cd ..
}

show_results() {
    log_info "Build complete!"
    
    echo ""
    echo "=== Generated Images ==="
    ls -la "$OPENWRT_DIR/bin/targets/$TARGET/$SUBTARGET/" 2>/dev/null || true
    
    echo ""
    echo "Firmware files are located in:"
    echo "$OPENWRT_DIR/bin/targets/$TARGET/$SUBTARGET/"
}

# Main
main() {
    log_info "Starting OpenWrt build for CMCC PZ-L8 (AP Mode)"
    
    check_dependencies
    clone_openwrt "$1"
    apply_pr_patches
    update_feeds
    configure_build
    build_firmware
    show_results
    
    log_info "Done!"
}

main "$@"
