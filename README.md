# OpenWrt Firmware for CMCC PZ-L8 (AP Mode)

Custom OpenWrt firmware for CMCC PZ-L8 router, optimized for Access Point (AP) mode with mesh networking support.

## Features

- **AP Mode Only** - All Ethernet ports (lan1, lan2, lan3, wan) bridged together
- **WiFi Support** - Dual-band: 2.4GHz (IPQ5000) + 5GHz (QCN6102)
- **Mesh Networking** - 802.11s mesh support with usteer for roaming
- **IPv6 Support** - Automatic IPv6 address assignment via SLAAC
- **Low Memory Optimization** - ath11k-smallbuffers driver for 256MB RAM devices
- **LuCI Web Interface** - Minimal web interface with package manager

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

The firmware file is named: `openwrt-qualcommax-ipq50xx-cmcc_pz-l8-squashfs-sysupgrade.bin`

## Installation

### Prerequisites

- Device must already be running OpenWrt (this firmware or another OpenWrt-based firmware)
- Access to LuCI web interface or SSH

### Via LuCI Web Interface

1. Navigate to **System** → **Backup / Flash Firmware**
2. Under "Flash new firmware image", click **Choose File**
3. Select the `sysupgrade.bin` file
4. Click **Upload** and confirm the flash
5. Wait for the device to reboot (approximately 2-3 minutes)

### Via SSH

```bash
# Transfer firmware to device
scp openwrt-qualcommax-ipq50xx-cmcc_pz-l8-squashfs-sysupgrade.bin root@[device-ip]:/tmp/

# Flash firmware
ssh root@[device-ip]
sysupgrade -n /tmp/openwrt-qualcommax-ipq50xx-cmcc_pz-l8-squashfs-sysupgrade.bin
```

The `-n` flag will not preserve configuration files. Omit it to keep your current settings.

> **Note**: This firmware only provides sysupgrade images. Factory installation from stock firmware requires UART access and is not covered in this guide.

## Network Configuration

### Default Settings

- All Ethernet ports bridged as `br-lan`
- IPv4: DHCP client (automatic IP from main router)
- IPv4 Fallback: 192.168.10.1 (if DHCP fails)
- IPv6: Automatic via SLAAC

### Access the Device

- **LuCI Web Interface**: http://[device-ip] or http://192.168.10.1
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
apk update
apk add luci-i18n-base-zh-cn
apk add luci-i18n-package-manager-zh-cn
apk add luci-i18n-usteer-zh-cn
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
2. Try fallback IP: 192.168.10.1 (connect directly with static IP in 192.168.10.x range)
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

This project is licensed under the same terms as OpenWrt. OpenWrt is composed of many components that are licensed under various open source licenses, including GPL-2.0, GPL-2.0+, LGPL-2.1, MIT, ISC, and BSD licenses. See individual packages for specific license information.

For more information about OpenWrt licensing, see: https://openwrt.org/docs/guide-developer/license
