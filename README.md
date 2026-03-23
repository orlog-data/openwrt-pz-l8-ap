# OpenWrt for CMCC PZ-L8 (AP Mode)

通过 GitHub Actions 自动构建的 OpenWrt 固件，专为 CMCC PZ-L8（IPQ5018）设备优化，仅用于 AP 模式。

## 设备规格

| 组件 | 规格 |
|------|------|
| SoC | Qualcomm IPQ5000 (IPQ5018) |
| RAM | 256MB DDR3L (集成) |
| Flash | 128MB SPI-NAND |
| WLAN 2.4GHz | IPQ5000 (SoC) 2T2R |
| WLAN 5GHz | QCN6102 2T2R |
| Ethernet | 4x 1GbE (QCA8337 switch) |

## 固件特点

- **AP 模式优化**: 移除了 DNS、DHCP、防火墙、PPPoE 等路由组件
- **Mesh 支持**: 802.11s mesh + usteer 漫游
- **内存优化**: ath11k-smallbuffers 驱动 + zram-swap
- **精简 LuCI**: 仅保留必要界面

## 包含的补丁

自动应用 [PR #21495](https://github.com/openwrt/openwrt/pull/21495)，包含：
- `kmod-ath11k-smallbuffers`: 低内存优化驱动
- `ath11k-firmware-ipq5018-qcn6122`: WiFi 固件
- `ipq-wifi-cmcc_pz-l8`: 设备校准数据

## 使用方法

### 手动构建

1. 进入 **Actions** 页面
2. 选择 **Build OpenWrt for CMCC PZ-L8 (AP Mode)**
3. 点击 **Run workflow**
4. 等待构建完成（约 2-3 小时）
5. 下载固件

### 发布版本

创建 tag 会自动构建并发布：
```bash
git tag v1.0.0
git push origin v1.0.0
```

## 包列表

### WiFi & Mesh
```
kmod-ath11k-ahb
kmod-ath11k-smallbuffers
ath11k-firmware-ipq5018-qcn6122
ipq-wifi-cmcc_pz-l8
wpad-mesh-mbedtls
usteer
luci-app-usteer
```

### LuCI
```
luci-base
luci-mod-admin-full
luci-theme-bootstrap
luci-i18n-base-zh-cn
luci-i18n-package-manager-zh-cn
luci-i18n-usteer-zh-cn
uhttpd
uhttpd-mod-ubus
```

### 核心
```
apk-mbedtls base-files ca-bundle dropbear fstools
kmod-gpio-button-hotplug kmod-leds-gpio kmod-qca-nss-dp
logd mtd netifd procd-ujail uboot-envtools uci
urandom-seed urngd zram-swap iw iwinfo
```

## AP 模式配置

刷入固件后，配置网络为 AP 模式：

```bash
# /etc/config/network
config interface 'lan'
    option type 'bridge'
    option ifname 'eth0'
    option proto 'dhcp'
```

Mesh 配置：
```bash
# /etc/config/wireless
config wifi-iface 'mesh'
    option device 'radio1'
    option mode 'mesh'
    option mesh_id 'my-mesh'
    option encryption 'sae'
    option key 'your-password'
```

## 已知问题

1. 256MB 内存对 ath11k 较紧张，建议启用 swap
2. 高负载下 WiFi 可能不稳定

## 致谢

- [OpenWrt 项目](https://openwrt.org/)
- [PR #21495 作者](https://github.com/openwrt/openwrt/pull/21495)
