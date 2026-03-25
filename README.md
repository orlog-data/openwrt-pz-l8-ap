# OpenWrt Firmware for CMCC PZ-L8 (AP Mode)

Custom OpenWrt firmware for CMCC PZ-L8 router, optimized for Access Point (AP) mode with mesh networking support.

## Features

- **AP Mode Only** - All Ethernet ports (lan1, lan2, lan3, wan) bridged together
- **WiFi Support** - Dual-band: 2.4GHz (IPQ5000) + 5GHz (QCN6102)
- **Mesh Networking** - 802.11s mesh support with usteer for roaming
- **IPv6 Support** - Automatic IPv6 address assignment via SLAAC
- **Low Memory Optimization** - ath11k-smallbuffers driver for 256MB RAM devices
- **LuCI Web Interface** - Minimal web interface for configuration

## Hardware Specifications

| Component | Specification |
|-----------|---------------|
| SoC | Qualcomm IPQ5000 (Dual-core Cortex-A53) |
| RAM | 256MB |
| Flash | 128MB NAND |
| WiFi 2.4GHz | IPQ5000 (SoC built-in) |
| WiFi 5GHz | QCN6102 |
| Ethernet | 4x Gigabit (lan1, lan2, lan3, wan) |

## Download

Download the latest firmware from [Releases](https://github.com/orlog-data/openwrt-pz-l8-ap/releases) or [Actions artifacts](https://github.com/orlog-data/openwrt-pz-l8-ap/actions).

## Installation

### Prerequisites

- Access to the device's UART console (required for initial installation)
- TFTP server for firmware transfer

### Steps

1. Connect to UART console (115200 baud, 8N1)
2. Interrupt boot and enter U-Boot
3. Set up TFTP server with firmware image
4. Flash firmware via U-Boot commands

```bash
# Example U-Boot commands (adjust IP addresses as needed)
tftpboot 0x44000000 openwrt-qualcommax-ipq50xx-cmcc_pz-l8-squashfs-nand-factory.bin
nand write 0x44000000 0x280000 0x1a80000
reset
```

## Network Configuration

### Default Settings

- All Ethernet ports bridged as `br-lan`
- IPv4: DHCP client (automatic IP from main router)
- IPv4 Fallback: 192.168.1.1 (if DHCP fails)
- IPv6: Automatic via SLAAC

### Access the Device

- **LuCI Web Interface**: http://[device-ip] or http://192.168.1.1
- **SSH**: `ssh root@[device-ip]`

## WiFi Configuration

The firmware includes WiFi board data files (BDF) extracted from official CMCC firmware 501.11. WiFi should work out of the box after installation.

### Mesh Setup

For mesh networking, configure 802.11s interface in LuCI or via UCI:

```bash
# Example mesh configuration
uci set wireless.mesh0='wifi-iface'
uci set wireless.mesh0.device='radio0'
uci set wireless.mesh0.mode='mesh'
uci set wireless.mesh0.mesh_id='my-mesh'
uci set wireless.mesh0.encryption='sae'
uci set wireless.mesh0.key='your-password'
uci commit wireless
```

## Installing Language Packs

The firmware comes with English as the default language. To install Chinese language support:

### Via LuCI Web Interface

1. Navigate to **System** → **Software**
2. Click **Update lists**
3. Search for and install:
   - `luci-i18n-base-zh-cn`
   - `luci-i18n-package-manager-zh-cn`
   - `luci-i18n-usteer-zh-cn`
4. Navigate to **System** → **Language** and select Chinese

### Via SSH

```bash
opkg update
opkg install luci-i18n-base-zh-cn
opkg install luci-i18n-package-manager-zh-cn
opkg install luci-i18n-usteer-zh-cn
```

## Building from Source

This firmware is built using GitHub Actions. The workflow:

1. Checks out OpenWrt main branch
2. Applies PR #21495 (PZ-L8 device support + ath11k-smallbuffers)
3. Downloads WiFi board data files
4. Configures for AP mode
5. Builds firmware image

### Local Build

```bash
# Clone repository
git clone https://github.com/orlog-data/openwrt-pz-l8-ap.git
cd openwrt-pz-l8-ap

# Download and apply to OpenWrt
git clone https://github.com/openwrt/openwrt.git
cd openwrt
git fetch origin pull/21495/head:pr-21495
git merge pr-21495

# Copy workflow config files and build
# ... see .github/workflows/build.yml for details
```

## Technical Details

### WiFi Board Data Files

- **Source**: [firmware_qca-wireless PR #106](https://github.com/openwrt/firmware_qca-wireless/pull/106)
- **Extracted from**: Official CMCC PZ-L8 firmware 501.11
- **Installed to**:
  - `/lib/firmware/ath11k/IPQ5018/hw1.0/board-2.bin`
  - `/lib/firmware/ath11k/QCN6122/hw1.0/board-2.bin`

### Patches Applied

- [PR #21495](https://github.com/openwrt/openwrt/pull/21495) - Device support for CMCC PZ-L8 with ath11k-smallbuffers

### IPv6 Configuration

```bash
# /etc/sysctl.d/99-ipv6-ap.conf
net.ipv6.conf.br-lan.accept_ra = 2
net.ipv6.conf.br-lan.forwarding = 0
```

This allows the AP to receive IPv6 Router Advertisements and obtain global IPv6 addresses via SLAAC.

## Troubleshooting

### WiFi Not Working

1. Check if BDF files are present:
   ```bash
   ls -la /lib/firmware/ath11k/IPQ5018/hw1.0/
   ls -la /lib/firmware/ath11k/QCN6122/hw1.0/
   ```

2. Check kernel logs:
   ```bash
   dmesg | grep -i ath11k
   ```

### Cannot Access Device

1. Check if device obtained IP via DHCP
2. Try fallback IP: 192.168.1.1 (connect directly with static IP in 192.168.1.x range)
3. Check if device has IPv6 address: `ip -6 addr show br-lan`

### Memory Issues

If device runs out of memory:
- Reduce log level: `uci set system.@system[0].log_level='4'`
- Disable unnecessary services
- Use swap: the firmware includes zram-swap

## Credits

- OpenWrt Project - https://openwrt.org
- PR #21495 contributors - Device support
- BDF files from firmware_qca-wireless PR #106 by sqliuchang

## License

OpenWrt is licensed under various licenses. See individual packages for details.

The configuration and build scripts in this repository are provided as-is without warranty.
