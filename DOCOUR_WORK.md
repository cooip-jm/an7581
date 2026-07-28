# AN7581 PON LuCI — 已完成工作

> 本文档记录所有已验证可用的功能和组件
> 最后更新: 2026-07-28

---

## 1. LXC 测试环境

### 基本信息
- **容器**: `an7581_test` on 192.168.0.86 (Armbian bookworm, aarch64)
- **IP**: 192.168.0.87
- **网关**: 192.168.0.19, **DNS**: 192.168.0.11
- **root 密码**: admin
- **OpenWrt**: 23.05-SNAPSHOT r24129+1-3f67d4ef03 (glibc 2.37)
- **rootfs 来源**: `https://www.audioscience.com/internet/openwrt/builds/latest/targets/armsr/armv8-glibc/openwrt-armsr-armv8-generic-rootfs.tar.gz`
- **备份**: `an7581_glibc_rootfs_20260728.tar.gz` (41MB) 在项目根目录

### distfeeds.conf
```
src/gz openwrt_core https://www.audioscience.com/internet/openwrt/builds/latest/targets/armsr/armv8-glibc/packages
src/gz openwrt_base https://www.audioscience.com/internet/openwrt/builds/latest/packages/aarch64_generic/base
src/gz openwrt_luci https://www.audioscience.com/internet/openwrt/builds/latest/packages/aarch64_generic/luci
src/gz openwrt_packages https://www.audioscience.com/internet/openwrt/builds/latest/packages/aarch64_generic/packages
src/gz openwrt_routing https://www.audioscience.com/internet/openwrt/builds/latest/packages/aarch64_generic/routing
src/gz openwrt_telephony https://www.audioscience.com/internet/openwrt/builds/latest/packages/aarch64_generic/telephony
```

### 已安装的 ipk 包
- **核心**: bash, curl, dropbear, nano, fwtool, usbutils, luci 等
- **LuCI**: luci, luci-app-attendedsysupgrade, luci-app-firewall, luci-app-package-manager, luci-base, luci-compat, luci-i18n-base-zh-cn, luci-light, luci-mod-admin-full, luci-mod-network, luci-mod-status, luci-mod-system, luci-ssl, luci-theme-bootstrap
- **Ruby**: ruby, ruby-bigdecimal, ruby-date, ruby-digest, ruby-enc, ruby-pstore, ruby-psych, ruby-stringio, ruby-yaml

### LuCI 框架
- ucode-based LuCI (OpenWrt 23.05+)
- CGI handler: `#!/usr/bin/env ucode`
- 菜单: JSON in `/usr/share/luci/menu.d/`
- 视图: JS in `/www/luci-static/resources/view/`
- ACL: `/usr/share/rpcd/acl.d/`

---

## 2. Vendor 二进制部署

### 部署位置
```
/opt/vendor/bin/     # 5 个二进制
/opt/vendor/lib/     # 282 个 .so 文件 (196 个唯一库)
```

### 二进制清单

| 二进制 | 大小 | 用途 | 验证状态 |
|--------|------|------|----------|
| `ponmgr` | 139KB | GPON PON 状态机、串号注册 | ✅ `ponmgr gpon get status` 正常 |
| `omciMgr` | 4.7MB | OMCI 协议管理 | ✅ 启动正常 (daemon) |
| `hcfgtool` | 10KB | 硬件配置查询 | ✅ 正常 |
| `ritool` | 28KB | NVRAM 读写 | ✅ 正常 |
| `ledtool` | 10KB | LED 控制 | ✅ 已部署 |

### 关键依赖库

| 库 | 大小 | 用途 |
|----|------|------|
| `libxpon.so` | 183KB | PON 核心库 |
| `libubus.so` / `libubox.so` | 43KB/96KB | OpenWrt IPC |
| `libbosa.so` | 63KB | BOSA 光模块 |
| `libGponRSSI.so` | 39KB | GPON RSSI |
| `libcrypto.so` / `libssl.so` | 3.5MB/811KB | 加密 |
| `libcfg.so` | 547KB | 配置管理 |

### 关键发现
- Vendor 二进制是 glibc 2.32 编译，但**前向兼容** glibc 2.37
- **不能**将 vendor 的 glibc 2.32 基础库 (ld-2.32.so, libc-2.32.so 等) 放入 /opt/vendor/lib，会与系统 glibc 冲突导致 Segfault
- 通过 `LD_LIBRARY_PATH=/opt/vendor/lib` 加载 vendor 特有的 .so 文件

---

## 3. LuCI GPON 覆盖层

### 5 个页面 (全部 200 OK)

| 页面 | 文件 | 功能 |
|------|------|------|
| PON Status | `status.js` | 链接状态、FEC、光模块参数、服务状态 |
| Optical Module | `optical.js` | TX/RX 功率、温度、偏置电流、电压、计数器 |
| OMCI Status | `omci.js` | OMCI 状态、设备 ID、序列号 |
| PON Configuration | `config.js` | FEC、调试、OMCI 设置 (UCI) |
| OLT Authentication | `auth.js` | SN、SLID、LOID 配置 |

### UCI 配置

**`/etc/config/pon`:**
```
config global
    option enabled '1'
    option pon_mode 'auto'
    option fec_rx '1'
    option fec_tx '1'
    option aes '1'
    option event_debug '0'
    option init_report '1'
    option proc_path '/root/tc3162'
```

**`/etc/config/pon_auth`:**
```
config sn
    option vendor_id ''
    option vssd ''

config slid
    option enabled '1'
    option password_disabled '0'
    option value ''
    option mode 'ascii'

config loid
    option enabled '0'
    option value ''
    option password ''
```

### Shell 脚本

| 脚本 | 行数 | 功能 |
|------|------|------|
| `pon_helpers.sh` | 298 | 封装 ponmgr CLI、光模块数据转换、VLAN 控制 |
| `pon_apply_uci.sh` | 85 | UCI → daemon 桥接 |
| `ecnt_xpon` | 205 | PON init: 创建 /dev 节点、加载模块、启动 ponmgr/omciMgr |

### rpc.declare 模式 (JS views 必须使用)

```js
var callRead = rpc.declare({
    object: 'file', method: 'read',
    params: ['path'],          // 必须!
    expect: { '': {} }         // 必须! 用 {'':{}} 不是 {data:''}
});
callRead(path);                // 位置参数，不是对象
```

### 模拟数据 (/root/tc3162/)

| 文件 | 值 |
|------|-----|
| omci_state | O5 |
| omci_eqid | ALCLF00A1234 |
| omci_sn | 0123456789ABCDEF |
| pon_txpower | -19.5 |
| pon_rxpower | -21.3 |
| pon_temp | 55.3 |
| pon_bias | 65 |
| pon_voltage | 3.31 |
| pon_txbytes | 1234567890 |
| pon_rxbytes | 9876543210 |
| pon_txpkts | 543210 |
| pon_rxpkts | 1234567 |

---

## 4. Git 提交历史 (40md 分支)

```
e4f9f1c fix: remove form.Dummy from auth.js (not available in ucode LuCI)
a51d50a fix: use expect:{'':{}} instead of expect:{data:''} in rpc.declare
d43e166 fix: pass positional arg to callRead, not object
2f99401 fix: add params:['path'] to rpc.declare for file.read
65307e4 fix: add uci read permission and file paths to GPON ACL
49e2ce5 fix: use file.read + UCI proc_path for LuCI data access
6afff08 feat: add Chinese translations and fix CI release permissions
3ce7010 Add PON WAN network config, VLAN support, fix build workflow
731feeb Add SN auth, password disable, fix optical/omci trim errors
459f85f Fix LuCI views: use view.extend instead of baseclass.extend
cbb290b Fix LuCI JS views for ucode LuCI 25.x
4d49322 Rewrite LuCI for ucode-based LuCI 25.x (tested on LXC)
```

---

## 5. 文件结构

```
an7581/
├── luci-overlay/                    # LuCI 覆盖层 (部署到 rootfs)
│   ├── etc/
│   │   ├── config/pon               # UCI PON 配置
│   │   ├── config/pon_auth          # UCI 认证配置
│   │   └── init.d/ecnt_xpon         # PON init 脚本
│   ├── usr/
│   │   ├── libexec/pon_helpers.sh   # Shell helpers
│   │   ├── libexec/pon_apply_uci.sh # UCI→daemon 桥接
│   │   └── share/
│   │       ├── luci/menu.d/luci-app-gpon.json  # 菜单
│   │       └── rpcd/acl.d/luci-app-gpon.json   # ACL
│   └── www/luci-static/resources/view/gpon/
│       ├── status.js                # PON 状态
│       ├── optical.js               # 光模块
│       ├── omci.js                  # OMCI 状态
│       ├── config.js                # PON 配置
│       └── auth.js                  # OLT 认证
├── analysis/rootfs_mtd3/            # 原厂 rootfs 提取
│   ├── sbin/ponmgr, omciMgr, ...   # vendor 二进制
│   ├── lib/modules/*.ko            # 60 个内核模块
│   ├── usr/etc/init.d/rcS          # 原厂启动脚本
│   └── usr/script/                 # 原厂脚本
├── back_an_7581_40md/               # 原厂 mtd 分区备份
│   ├── mtd0.bin - mtd16.bin        # 17 个分区
│   └── ...
├── base-files/                      # iopsys 基础文件 (仅参考)
├── fake_pon/                        # LXC 测试 LD_PRELOAD shim
├── an7581_glibc_rootfs_20260728.tar.gz  # rootfs 备份
├── STATUS.md                        # 当前状态记录
├── TODO.md                          # 待修复问题
└── archive/                         # 归档文件 (不可用)
```
