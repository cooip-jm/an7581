# AN7581 PON LuCI - 当前状态

> **重要**: 此文档记录所有已验证可用的功能。修改代码前必须阅读此文档，避免破坏已有成果。
> **文档索引**:
> - `DOC_VENDOR_BOOT_FLOW.md` — 原厂固件完整启动流程
> - `DOCOUR_WORK.md` — 我们已完成的工作
> - `DOC_DEPLOY Assessment.md` — 真实设备部署评估 (最终阶段)
> - `TODO.md` — 待修复问题
> - `archive/README.md` — 归档文件说明 (不可用)
> **最后更新**: 2026-07-28

---

## 1. 项目架构

### 目标设备
- Nokia XG-040G-MD, Airoha AN7581 SoC
- 内核 5.4.55 (vendor modules: `vermagic=5.4.55 SMP mod_unload aarch64`)
- Vendor 用户态: glibc 2.32 (ponmgr, omciMgr 等)
- 最终目标: 在保留 vendor PON 功能的基础上添加 LuCI 管理界面

### LXC 测试环境 (192.168.0.86)
- 容器 `an7581_test`, IP `192.168.0.87`
- **OpenWrt 23.05-SNAPSHOT (glibc 2.37)** — 来自 audioscience.com glibc 构建
- Rootfs: `https://www.audioscience.com/internet/openwrt/builds/latest/targets/armsr/armv8-glibc/openwrt-armsr-armv8-generic-rootfs.tar.gz`
- LXC 配置: 单 veth 接口 `eth0`，静态 IP
- root 密码: admin
- **备份**: `an7581_glibc_rootfs_20260728.tar.gz` (41MB) 在项目根目录

### distfeeds.conf (已验证可用)
```
src/gz openwrt_core https://www.audioscience.com/internet/openwrt/builds/latest/targets/armsr/armv8-glibc/packages
src/gz openwrt_base https://www.audioscience.com/internet/openwrt/builds/latest/packages/aarch64_generic/base
src/gz openwrt_luci https://www.audioscience.com/internet/openwrt/builds/latest/packages/aarch64_generic/luci
src/gz openwrt_packages https://www.audioscience.com/internet/openwrt/builds/latest/packages/aarch64_generic/packages
src/gz openwrt_routing https://www.audioscience.com/internet/openwrt/builds/latest/packages/aarch64_generic/routing
src/gz openwrt_telephony https://www.audioscience.com/internet/openwrt/builds/latest/packages/aarch64_generic/telephony
```

---

## 2. 已验证可用的功能

### 2.1 Vendor 二进制 (glibc 2.37 系统上运行 glibc 2.32 编译的二进制)
| 二进制 | 大小 | 验证状态 |
|--------|------|----------|
| ponmgr | 139KB | ✅ `ponmgr gpon get status` 正常 |
| omciMgr | 4.7MB | ✅ 启动正常 (daemon) |
| hcfgtool | 10KB | ✅ `hcfgtool` 正常 |
| ritool | 28KB | ✅ `ritool` 正常 |
| ledtool | 10KB | ✅ 已部署 |

**关键**: vendor 的 glibc 2.32 库 (ld-2.32.so, libc-2.32.so 等) 不要放到 /opt/vendor/lib，否则与系统 glibc 2.37 冲突导致 Segfault。

### 2.2 rpc.declare 模式 (JS views 必须使用)
```js
var callRead = rpc.declare({
    object: 'file', method: 'read',
    params: ['path'],          // 必须! 没有则 ubus 发送空 {}
    expect: { '': {} }         // 必须! 用 {'':{}} 不是 {data:''}
});
callRead(path);                // 位置参数，不是对象
```

### 2.3 UCI 配置结构
**`/etc/config/pon`**:
- `global`: enabled, pon_mode(auto), fec_rx(1), fec_tx(1), aes(1), event_debug(0), init_report(1), proc_path(/root/tc3162)
- `device`: name(pon), ifname(pon), type(auto), vid(0) — 当前未使用
- `omci`: enabled(1), auto_start(1), pm_flag(0)
- `pon_vlan`: enabled(0), mode(transparent), vid(), priority(0)

**`/etc/config/pon_auth`**:
- `sn`: vendor_id(), vssd()
- `slid`: enabled(1), password_disabled(0), value(), mode(ascii)
- `loid`: enabled(0), value(), password()
- `password`: value() — 当前未应用

### 2.4 Shell 脚本
| 脚本 | 功能 |
|------|------|
| `pon_helpers.sh` (298行) | 封装 ponmgr CLI、光模块数据转换、VLAN 控制、`pon_get_full_status()` |
| `pon_apply_uci.sh` (85行) | UCI → daemon 桥接，boot 时由 ecnt_xpon 调用 |
| `ecnt_xpon` (205行) | PON init 脚本: 创建 /dev/ 节点、加载内核模块、启动 ponmgr/omciMgr |

### 2.5 模拟数据 (/root/tc3162/)
```
omci_state=O5  omci_eqid=ALCLF00A1234  omci_sn=0123456789ABCDEF
pon_txpower=-19.5  pon_rxpower=-21.3  pon_temp=55.3
pon_bias=65  pon_voltage=3.31
pon_txbytes=1234567890  pon_rxbytes=9876543210
pon_txpkts=543210  pon_rxpkts=1234567
```

### 2.6 LuCI 页面 (5 个, 全部 200 OK)
| 页面 | 文件 | 验证 |
|------|------|------|
| PON Status | status.js | ✅ 加载正常 |
| Optical Module | optical.js | ✅ 加载正常 |
| OMCI Status | omci.js | ✅ 加载正常 |
| PON Configuration | config.js | ✅ 加载正常 |
| OLT Authentication | auth.js | ✅ 加载正常 |

---

## 3. 供应商数据来源

### vendor 文件位置
- **固件备份**: `back_an_7581_40md/` — mtd0-mtd16.bin (原厂分区备份)
- **已提取 rootfs**: `analysis/rootfs_mtd3/` — sbin/, lib/, etc/
- **关键 PON 二进制**: `analysis/rootfs_mtd3/sbin/ponmgr`, `omciMgr`
- **Vendor glibc 2.32 库**: `analysis/rootfs_mtd3/lib/` (ld-2.32.so, libc-2.32.so 等 — 仅参考，不要部署到容器)

### 内核驱动接口 (来自源码分析)
- `/proc/xgpon/*` — debug, counter, errcnt, errsts, keyinfo, fastmode
- `/dev/pon` (major 190) — MCI ioctl 主接口
- GPON 10G 状态机: O1→O2_3→O4→O5 (正常), O7 (紧急停止)
- ponmgr CLI: `gpon set/get sn/passwd/fec/dbg_level/event_ctrl`

---

## 4. 已删除/不使用

- **CI workflow** (`/.github/workflows/build.yml`) — 已删除
- **GitHub Releases** (build-8 到 build-13) — 已全部删除
- **generic musl rootfs** — 不再使用
- **iopsys OpenWrt 构建系统** — 不能从零构建，已归档到 `archive/`

---

## 5. Git 提交历史 (40md 分支)
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
