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
| LEDs/Keys | 2x LEDs, 2x Keys |

## 固件特点

### AP 模式优化
- **无路由功能**: 移除了 NAT、路由相关组件
- **无 DNS 服务**: 移除了 dnsmasq 等DNS 服务
- **无 DHCP 服务**: 移除了 DHCP 服务器
- **无防火墙**: 移除了 firewall3/4

### Mesh 支持
- **802.11s Mesh**: 使用 wpad-mesh-mbedtls 支持 mesh 网络
- **usteer**: 无线漫游引导，优化客户端切换

### 内存优化
- **ath11k-smallbuffers**: 来自 PR #21495，针对低内存设备优化
- **zram-swap**: 启用压缩交换空间
- **精简 LuCI**: 仅保留必要的 LuCI 组件

## 包含的补丁

### PR #21495
此固件包含了 [PR #21495](https://github.com/openwrt/openwrt/pull/21495) 的补丁，主要包括：

- `kmod-ath11k-smallbuffers`: 针对 256MB 内存的优化驱动
- `ath11k-firmware-ipq5018-qcn6122`: IPQ5018/QCN6122 固件
- `ipq-wifi-cmcc_pz-l8`: CMCC PZ-L8 特定的 WiFi 校准数据

## 包列表

### 核心系统包
```
apk-mbedtls
base-files
ca-bundle
dropbear
fstools
kmod-gpio-button-hotplug
kmod-leds-gpio
kmod-qca-nss-dp
libc
libgcc
libustream-mbedtls
logd
mtd
netifd
procd-ujail
uboot-envtools
uci
uclient-fetch
urandom-seed
urngd
zram-swap
```

### WiFi 和 Mesh
```
kmod-ath11k-ahb
kmod-ath11k-smallbuffers
ath11k-firmware-ipq5018-qcn6122
ipq-wifi-cmcc_pz-l8
wpad-mesh-mbedtls
iw
iwinfo
usteer
```

### LuCI 界面
```
luci-base
luci-mod-admin-full
luci-theme-bootstrap
luci-i18n-base-zh-cn
luci-i18n-package-manager-zh-cn
luci-i18n-usteer-zh-cn
luci-app-usteer
uhttpd
uhttpd-mod-ubus
```

## 如何使用

### 方法一：Fork 后自动构建

1. Fork 本仓库
2. 进入 Actions 页面
3. 选择 "Build OpenWrt for CMCC PZ-L8 (AP Mode)"
4. 点击 "Run workflow"
5. 等待构建完成（约 2-3 小时）
6. 下载生成的固件

### 方法二：本地构建

```bash
# 克隆仓库
git clone https://github.com/YOUR_USERNAME/openwrt-pz-l8.git
cd openwrt-pz-l8

# 克隆 OpenWrt
git clone https://github.com/openwrt/openwrt.git
cd openwrt

# 获取 PR #21495
git fetch origin pull/21495/head:pr-21495
git merge pr-21495

# 配置和构建
make menuconfig
# 选择 Target: qualcommax/ipq50xx
# 选择 Device: cmcc_pz-l8

make download -j$(nproc)
make -j$(nproc) V=s
```

## 刷写说明

### 从原厂固件刷写

1. 拆机找到 TTL 调试接口
2. 连接串口（波特率 115200）
3. 在 U-Boot 启动时按任意键中断
4. 设置 TFTP 服务器，上传固件
5. 执行刷写命令

### 从其他 OpenWrt 刷写

```bash
# 使用 LuCI 刷写
系统 -> 备份/升级 -> 刷写新固件

# 或使用命令行
sysupgrade -n openwrt-*.bin
```

## AP 模式配置

### 基本网络配置

AP 模式下，所有网口桥接在一起，通过上游路由器获取 IP：

```bash
# /etc/config/network
config interface 'lan'
    option type 'bridge'
    option ifname 'eth0'
    option proto 'dhcp'
```

### Mesh 配置

配置 802.11s mesh 网络：

```bash
# /etc/config/wireless
config wifi-iface 'mesh'
    option device 'radio0'
    option ifname 'mesh0'
    option network 'lan'
    option mode 'mesh'
    option mesh_id 'my-mesh'
    option encryption 'sae'
    option key 'your-password'
```

### usteer 配置

启用无线漫游引导：

```bash
# /etc/config/usteer
config usteer
    option network 'lan'
    option enabled '1'
```

## 已知问题

1. **内存限制**: 256MB 内存对于 ath11k 驱动较为紧张，建议使用 swap
2. **WiFi 性能**: 在高负载下可能不稳定，建议控制连接设备数量
3. **DSA 问题**: 当前 DSA 配置可能存在端口问题，请关注上游更新

## 技术支持

- [OpenWrt 论坛](https://forum.openwrt.org/)
- [恩山无线论坛](https://www.right.com.cn/forum/)
- [GitHub Issues](https://github.com/YOUR_USERNAME/openwrt-pz-l8/issues)

## 致谢

- [OpenWrt 项目](https://openwrt.org/)
- [PR #21495 作者](https://github.com/openwrt/openwrt/pull/21495)
- 所有测试和反馈的用户

## 许可证

OpenWrt 及其包根据各自的许可证发布。本仓库的构建脚本使用 MIT 许可证。
