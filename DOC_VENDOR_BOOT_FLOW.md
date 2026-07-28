# Nokia XG-040G-MD (AN7581) 原机固件启动流程

> 基于 `analysis/rootfs_mtd3/` 提取的 rootfs 和 `back_an_7581_40md/` 的 mtd 分区备份分析
> 最后更新: 2026-07-28

---

## 1. 分区布局

| MTD | 大小 | 用途 | 文件系统 |
|-----|------|------|----------|
| mtd0 | 512K | U-Boot bootloader | raw |
| mtd1 | 256K | romfile (U-Boot env 备份) | raw |
| mtd2 | 3.7M | Kernel A (bank1) | FIT image |
| mtd3 | 29M | Rootfs A (bank1) | **SquashFS** (LZMA, magic `hsqs`) |
| mtd4 | 4.5M | Kernel B (bank2) | FIT image |
| mtd5 | 36M | Rootfs B (bank2) | SquashFS |
| mtd6 | 256K | BOSA 校准数据 | raw |
| mtd7 | 256K | (保留) | raw |
| mtd8 | 256K | flag (bank 切换标记) | raw |
| mtd9 | 256K | flagback | raw |
| mtd10 | 10M | configs (UBI) | **UBIFS** → `/configs` |
| mtd11 | 129M | data (UBI) | **UBIFS** → `/data` |
| mtd12 | 4M | oopsfs (内核崩溃日志) | raw |
| mtd13 | 10M | logs (UBI) | **UBIFS** → `/logs` |
| mtd14 | 41M | nsb_master | raw |
| mtd15 | 41M | nsb_slave | raw |
| mtd16 | 236M | all_flash | raw |

**双 bank 机制**: mtd2/mtd3 为 bank1 (active)，mtd4/mtd5 为 bank2。通过 mtd8 (flag) 切换。

---

## 2. 启动流程总览

```
U-Boot (mtd0)
  │
  ├─ 读取 mtd8 (flag) 判断当前 active bank
  ├─ 加载 kernel from mtd2 (bank1) 或 mtd4 (bank2)
  │
  ▼
Linux 5.4.55 内核启动
  │
  ├─ 挂载 rootfs SquashFS from mtd3 或 mtd5
  ├─ BusyBox init 读取 /usr/etc/inittab
  │
  ▼
inittab → ::sysinit:/usr/etc/init.d/rcS
  │
  ▼
rcS 执行完整启动序列 (见下文)
  │
  ▼
/sbin/appmgr & (应用管理器)
  │
  ├─ 读取 /configs/config.cfg
  ├─ 启动 ponmgr, omciMgr, cfgmgr, evtmgr, msgmgr 等
  └─ 监控心跳，异常时 reboot
```

---

## 3. rcS 启动序列 (完整)

### 阶段 1: 基础环境 (lines 2-18)

```
1. source /userfs/profile.cfg     # 加载 TCSUPPORT_* 特性标志
2. mount -t tmpfs none /dev       # 挂载 /dev
3. /usr/script/makedev.sh         # 创建所有静态设备节点
4. mount -t tmpfs /dev/ram1 /tmp  # 挂载 128MB tmpfs 到 /tmp
5. mount -a                       # 挂载 fstab (proc, devpts, sysfs 等)
```

### 阶段 2: 早期内核模块 (lines 21-28)

```
6.  insmod nand_drv.ko            # NAND 驱动
7.  insmod ri.ko                  # Runtime Information (板卡信息)
8.  insmod hcfg.ko                # Hardware Configuration
9.  mknod /dev/ri_drv c 60 0
10. mknod /dev/hcfg c 218 0
11. insmod board_dev.ko           # Board Device
12. mknod /dev/board_dev c 219 0
```

### 阶段 3: UBI/UBIFS 挂载 (line 30)

```
13. /usr/script/mountfs.sh
    ├─ ubiattach /dev/ubi_ctrl -m 13 -d 2  # logs 分区
    ├─ mount -t ubifs /dev/ubi2_0 /logs
    ├─ ubiattach /dev/ubi_ctrl -m 10 -d 1  # configs 分区
    ├─ mount -t ubifs /dev/ubi1_0 /configs
    ├─ ubiattach /dev/ubi_ctrl -m 11 -d 3  # data 分区
    └─ mount -t ubifs /dev/ubi3_0 /data
```

### 阶段 4: /etc Overlay 设置 (lines 32-38)

```
14. mkdir -p /configs/ct
15. mount --bind /configs/ct/ /usr/local/ct/
16. source /usr/etc/scripts/buildcheck.sh    # 关键! /etc overlay
17. backup_restore.sh restore
18. backup_restore.sh backup
```

**buildcheck.sh 核心逻辑:**
```
mount --bind /configs/etc /etc     # /etc 指向持久化存储
diff /usr/etc/buildinfo /etc/buildinfo
if 不同: cp -rpf /usr/etc/* /configs/etc   # 固件升级时重新复制
```

### 阶段 5: 环境变量和日志 (lines 40-56)

```
19. export LD_LIBRARY_PATH=/lib:/usr/lib/:/lib64
20. insmod klog.ko
21. hcfgtool get Wifi.Num → boot_wlan.sh    # WiFi 模块加载
```

### 阶段 6: LED/按钮/基础驱动 (lines 58-61)

```
22. insmod module_sel.ko
23. insmod tcledctrl.ko          # LED 控制
24. insmod tccicmd.ko            # TCC 命令接口
25. insmod sif.ko                # Serial Interface
```

### 阶段 7: PON/BOSA/SDK 模块 (lines 64-66)

```
26. /usr/script/boot_pon_driver.sh   # insmod mtk_txpd.ko (GPIO 参数)
27. /usr/script/boot_bosa.sh         # insmod en7572.ko + bosa_en7572.ko
28. /usr/script/sdk_moudles.sh       # 见下文
```

### 阶段 8: SoC/GPIO/网络钩子 (lines 67-72)

```
29. insmod soc.ko
30. insmod gpio_mgr.ko
31. insmod nethook.ko
32. insmod netlinkmsg.ko
33. insmod i2c_drv.ko
34. insmod mt_whnat_7916d.ko
```

### 阶段 9: 网络调优 (lines 74-77)

```
echo 16384  > /proc/net/skbmgr_4k_limit
echo 30000  > /proc/net/skbmgr_limit
echo 42000  > /proc/net/skbmgr_driver_max_skb
```

### 阶段 10: 运营商/工厂模式/密码 (lines 79-87)

```
35. ritool get OperatorID
36. isFactoryMode → config_passwd.sh
```

### 阶段 11: GPIO/LED/LAN PHY (lines 90-113)

```
37. insmod gpio-led.ko
38. insmod button_driver.ko
39. boot_lan_phy_an8811.sh       # mdio_arht.ko, air_en8811h.ko, 8811_bbu_api.ko
40. sysdrvs_modules.sh           # vlanctl.ko, phy_driver.ko, kuser_monitor.ko, kigmp.ko
41. boot_wlan_hal.sh             # wlan_hal.ko (条件)
42. rebootcheck.sh
```

### 阶段 12: 网络/Web (lines 120-126)

```
43. ifconfig lo 127.0.0.1
44. 提取 WAN_MAC, LAN_MAC → /etc/mac.conf
45. lan.sh                       # 创建 br0 桥接, 设置 IP (默认 192.168.1.1)
46. /webs/thttpd -dd /webs/ &    # 启动 HTTP 服务器
47. create_bootlog.sh
```

### 阶段 13: OpenJDK/USB/Voice (lines 128-133)

```
48. mountopenjdk.sh              # 挂载 OpenJDK SquashFS 镜像
49. boot_usb.sh                  # USB 存储模块
50. boot_dsp_voice.sh            # VoIP/DSP 模块 (条件)
```

### 阶段 14: 看门狗/Core Dump (lines 134-140)

```
51. config_core_dump.sh
52. tcwdog -t 1 /dev/watchdog &  # 硬件看门狗
```

### 阶段 15: 应用管理器 (lines 142-154)

```
53. /sbin/reboot_monitor &
54. config_tr069.sh
55. config_crond.sh
56. /sbin/appmgr &               # ★ 核心: 启动所有应用服务
57. boot_traffic_services.sh     # asb_parentctl.ko, asb_tm.ko
58. insmod secureupgrade.ko (条件)
```

### 阶段 16: Hotplug/完成 (lines 157-160)

```
59. echo /sbin/mdev > /proc/sys/kernel/hotplug
60. image_done                   # 通知 U-Boot 启动完成
```

### 阶段 17: 后台任务 (lines 162-201)

```
61. run_scripts "S" "start" &    # 运行 /etc/rc.d/S* 脚本
62. inotify_monitor /configs/    # 监控配置变更
63. 禁用 GPHY EEE
64. [postapp.sh]                 # 用户自定义启动后脚本
65. insmod nsb_dying_gasp.ko     # 断电保护
```

---

## 4. sdk_moudles.sh 模块加载顺序

```
1.  fe_core.ko          # Fast Ethernet 核心
2.  ifc.ko              # Interface Classifier
3.  qdma_lan.ko         # QDMA LAN
4.  dataspeed_limit.ko  # 限速
5.  eth.ko              # Ethernet 驱动 (4 端口)
6.  eth_ephy.ko         # 内部 PHY
7.  hsgmii_lan.ko       # HSGMII 10G LAN
8.  phy_10g.ko          # 10G PHY
9.  qdma_wan.ko         # QDMA WAN
10. xpon_10g.ko         # 10G XPON
11. ponvlan.ko          # PON VLAN
12. xpon_int.ko         # XPON Internal
13. hw_nat.ko           # Hardware NAT
14. bandwidth.ko        # 带宽管理
15. vxlan_hw_offload.ko # VXLAN 卸载
16. thermal.ko          # 温控
17. CpuPower.ko         # CPU 功耗管理
18. lro_wan.ko          # LRO WAN
19. lro_lan.ko          # LRO LAN
20. l2tp_offload.ko     # L2TP 卸载
```

之后配置: `ifconfig eth up`, `ifconfig pon up`, `ifconfig omci up`, hw_nat 配置, br0 桥接, QDMA 限速。

---

## 5. /etc Overlay 机制

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   只读 Rootfs    │     │   持久化存储     │     │   运行时视图     │
│   (SquashFS)    │     │   (UBIFS)       │     │                 │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ /usr/etc/*      │     │ /configs/etc/*  │     │ /etc/*          │
│ (出厂默认)       │ ──→ │ (用户+升级)      │ ──→ │ (= /configs/etc)│
│ 不可变           │     │ 持久化           │     │ bind mount      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**首次启动/固件升级:**
1. `mount --bind /configs/etc /etc`
2. buildinfo 不匹配 → `cp -rpf /usr/etc/* /configs/etc`
3. /etc 内容更新为新固件默认值

**正常启动:**
1. `mount --bind /configs/etc /etc`
2. buildinfo 匹配 → 不复制，用户修改保留

**注意:** `/configs` 是 UBIFS (MTD10)，断电安全。`/usr/etc` 在 SquashFS 中，只读。

---

## 6. 应用管理器 (appmgr)

- 二进制: `/sbin/appmgr` (ELF 64-bit ARM aarch64)
- 配置: `/configs/config.cfg` (运行时生成，不在 rootfs 中)
- 功能:
  1. 读取 config.cfg，启动所有服务 (ponmgr, omciMgr, cfgmgr, evtmgr, msgmgr 等)
  2. 监控心跳 (csMsg IPC)
  3. msgmgr 超时未启动 → `reboot -m appmgr_msgmgr_boot_error`
  4. 绑定 CPU 0+1

**config.cfg 格式:** 未捕获。该文件在 `/configs` UBIFS 分区上运行时生成。

---

## 7. PON 启动细节

### boot_pon_driver.sh
```
读取 hcfgtool 获取 GPIO 引脚:
  Pon.TxDisable.Pin, Pon.TxPowerEnable.Pin
  Pon.TxDisable.Active, Pon.TxPowerEnable.Active
insmod mtk_txpd.ko (PON 发射功率控制)
```

### boot_bosa.sh
```
insmod en7572.ko                    # BOSA 基础驱动
bosa_load.sh → bosa_load.en7572.sh
  insmod bosa_en7572.ko
  mknod /dev/bosa (动态 major)
```

### sdk_moudles.sh (PON 部分)
```
insmod phy_10g.ko                   # 10G PHY
insmod xpon_10g.ko                  # XPON 10G
insmod ponvlan.ko                   # PON VLAN
insmod xpon_int.ko                  # XPON Internal
ifconfig pon up
ifconfig omci up
```

---

## 8. 关键文件路径

| 路径 | 用途 |
|------|------|
| `/usr/etc/inittab` | BusyBox init 配置 |
| `/usr/etc/init.d/rcS` | 主启动脚本 (201 行) |
| `/usr/etc/scripts/buildcheck.sh` | /etc overlay 逻辑 |
| `/usr/etc/fstab` | 文件系统挂载表 |
| `/usr/script/mountfs.sh` | UBI/UBIFS 挂载 |
| `/usr/script/makedev.sh` | 设备节点创建 |
| `/usr/script/boot_pon_driver.sh` | PON 驱动加载 |
| `/usr/script/boot_bosa.sh` | BOSA 驱动加载 |
| `/usr/script/sdk_moudles.sh` | SDK 网络模块 |
| `/usr/script/lan.sh` | LAN 桥接配置 |
| `/sbin/appmgr` | 应用管理器 |
| `/userfs/profile.cfg` | 芯片/特性标志 |

---

## 9. 工具

| 工具 | 用途 |
|------|------|
| `ritool` | 读写 NVRAM (BoardID, OperatorID, MAC 等) |
| `hcfgtool` | 硬件配置查询 (WiFi 数量, BOSA 芯片, GPIO) |
| `cfgcli` | 配置 CLI (数据模型接口) |
| `bob.mtk` | MTK BOSA 初始化 |
| `image_done` | 通知 U-Boot 启动完成 |
| `hw_nat` | Hardware NAT 配置 |
| `ethphxcmd` | Ethernet PHY 寄存器命令 |
| `tcwdog` | 硬件看门狗守护进程 |
