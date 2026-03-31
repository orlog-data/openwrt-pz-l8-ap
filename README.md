# OpenWrt Firmware for CMCC PZ-L8

自动构建 CMCC PZ-L8 (IPQ5018) 设备的 OpenWrt 固件。

## 设备信息

- **SoC**: Qualcomm IPQ5018 (双核 Cortex-A53)
- **RAM**: 256MB
- **Flash**: 128MB NAND
- **WiFi**:
  - 2.4GHz: IPQ5000 (SoC 内置)
  - 5GHz: QCN6102
- **网口**: 4x GbE (1x WAN + 3x LAN)

## 固件版本

### AP 模式
- 所有端口桥接 (lan1, lan2, lan3, wan)
- DHCP 客户端，fallback 192.168.10.1
- 802.11s mesh 支持 + usteer
- 无防火墙，无 DHCP 服务器
- 适用场景: 作为 AP/MESH 节点使用

### Router 模式
- 完整路由功能
- WAN: wan 口 (DHCP 或 PPPoE)
- LAN: lan1, lan2, lan3 桥接
- 防火墙、NAT、IPv6 支持
- PHY-to-PHY 2Gbps 硬件加速
- 适用场景: 作为主路由使用

## 补丁来源

- **PR #21495**: PZ-L8 设备支持 + ath11k-smallbuffers (256MB RAM 优化)
- **PR #21496**: PHY-to-PHY 2Gbps 硬件加速 (仅 Router 模式)

## ZRAM 压缩

- 支持: lzo, lzo-rle, zstd
- 默认: lzo-rle (低 CPU 占用)
- 切换算法:
  ```bash
  echo zstd > /sys/block/zram0/comp_algorithm
  ```

## 安装方法

1. 下载对应模式的固件
2. 通过原厂固件 Web 界面刷入 `factory.bin`
3. 或在 OpenWrt 中使用 `sysupgrade` 升级

## 文件说明

| 文件 | 说明 |
|------|------|
| `openwrt-pz-l8-factory-ap.bin` | AP 模式，从原厂固件刷入 |
| `openwrt-pz-l8-sysupgrade-ap.bin` | AP 模式，OpenWrt 系统内升级 |
| `openwrt-pz-l8-factory-router.bin` | Router 模式，从原厂固件刷入 |
| `openwrt-pz-l8-sysupgrade-router.bin` | Router 模式，OpenWrt 系统内升级 |

## 构建

使用 GitHub Actions 自动构建：

1. 进入 Actions 页面
2. 选择 "Build OpenWrt for CMCC PZ-L8"
3. 点击 "Run workflow"
4. 填写 release_tag (可选，留空则不创建 Release)

## 致谢

- [OpenWrt](https://github.com/openwrt/openwrt)
- PR #21495 和 #21496 的贡献者
