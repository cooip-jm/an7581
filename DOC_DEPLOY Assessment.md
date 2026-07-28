# AN7581 真实设备部署评估

> 基于原厂固件分析和 LXC 测试结果的部署方案评估
> 最后更新: 2026-07-28

---

## 1. 当前状态

### LXC 测试环境
- ✅ glibc OpenWrt 23.05 运行正常
- ✅ Vendor 二进制 (ponmgr, omciMgr) 在 glibc 2.37 上运行正常
- ✅ 5 个 LuCI GPON 页面全部 200 OK
- ✅ 模拟数据读取正常
- ❌ 无法验证真实硬件功能 (PON 光模块、OMCI 协议、内核模块)

### 关键差异: LXC vs 真实设备

| 方面 | LXC 测试环境 | 真实设备 |
|------|-------------|----------|
| 内核 | 6.18.39 (OpenWrt) | 5.4.55 (vendor) |
| 内核模块 | 无 vendor .ko | 60+ vendor .ko |
| rootfs 格式 | tar.gz 解压 | SquashFS on NAND |
| /etc 机制 | 直接读写 | bind mount from UBIFS |
| 启动流程 | OpenWrt procd | vendor BusyBox init → appmgr |
| PON 驱动 | 无 | mtk_txpd, en7572, xpon_10g 等 |
| 网络驱动 | virtio | eth, eth_ephy, qdma, hw_nat 等 |

---

## 2. 方案评估

### 方案 A: 修改 vendor rootfs (推荐)

**思路:** 在原厂 SquashFS rootfs 上添加我们的 LuCI overlay，而不是替换整个 rootfs。

**步骤:**
1. 解包 mtd3.bin (SquashFS) — 已完成 (analysis/rootfs_mtd3/)
2. 在解包后的目录中添加我们的文件:
   - `/www/luci-static/resources/view/gpon/*.js` — LuCI 视图
   - `/usr/share/luci/menu.d/luci-app-gpon.json` — 菜单
   - `/usr/share/rpcd/acl.d/luci-app-gpon.json` — ACL
   - `/etc/config/pon` — UCI 配置
   - `/etc/config/pon_auth` — UCI 认证配置
   - `/usr/libexec/pon_helpers.sh` — Shell helpers
   - `/usr/libexec/pon_apply_uci.sh` — UCI→daemon 桥接
3. 重新打包为 SquashFS
4. 写入 mtd3 (或 mtd5 bank2)

**优点:**
- 保留原厂启动流程 (rcS → appmgr → ponmgr/omciMgr)
- 保留所有内核模块
- 保留 /etc overlay 机制
- 风险最低

**问题:**
- SquashFS 是只读的，需要重新打包
- 重新打包后大小可能超过 29MB 分区限制
- 需要安装 mksquashfs 工具
- 原厂 rootfs 已经 129MB (解压后)，压缩回 SquashFS 后大小未知

**风险:**
- 🟡 中等 — 如果 SquashFS 大小超过分区，设备无法启动
- 🟢 低 — 如果大小合适，不影响原厂功能

### 方案 B: 运行时覆盖 (无需重打包)

**思路:** 利用设备的 /etc overlay 机制，在启动后动态添加我们的文件。

**步骤:**
1. 将我们的文件放入 /configs/etc/ (UBIFS 持久化)
2. 修改 /usr/etc/init.d/rcS 或添加启动脚本
3. 在 rcS 末尾启动 LuCI 和 rpcd

**优点:**
- 无需重打包 SquashFS
- 可以随时修改和回滚
- 利用原厂 overlay 机制

**问题:**
- 需要先有某种方式将文件写入 /configs (SSH? USB? Web 升级?)
- 需要安装 LuCI 和依赖 (opkg)
- 需要修改 rcS 启动流程
- 原厂 rootfs 中没有 opkg，需要先安装

**风险:**
- 🟡 中等 — 修改 rcS 可能导致启动失败
- 🟢 低 — /configs 是持久化的，可以恢复

### 方案 C: 双系统 (保留原厂 + 添加 OpenWrt)

**思路:** 利用双 bank 机制，bank1 保留原厂，bank2 部署我们的系统。

**步骤:**
1. bank1 (mtd2/mtd3) 保持原厂不动
2. 修改 bank2 (mtd4/mtd5) 的 rootfs
3. 通过 mtd8 (flag) 切换到 bank2 启动

**优点:**
- 完全不破坏原厂系统
- 可以随时切回 bank1
- 最安全的方案

**问题:**
- 需要修改 bank2 的 rootfs (同方案 A 的 SquashFS 问题)
- 需要理解 mtd8 flag 的切换机制
- 需要能够写入 mtd4/mtd5/mtd8

**风险:**
- 🟢 低 — 原厂系统完全保留
- 🟡 中等 — bank2 修改仍有 SquashFS 大小问题

---

## 3. 关键技术问题

### 3.1 SquashFS 大小

原厂 rootfs:
- mtd3.bin: 29MB (SquashFS 压缩)
- 解压后: 129MB

我们的添加:
- LuCI JS 视图: ~10KB
- Shell 脚本: ~10KB
- UCI 配置: ~1KB
- LuCI 依赖 (luci, luci-base, rpcd 等): 需要评估

**问题:** 原厂 rootfs 已经 29MB，我们的添加是否会超出分区大小?

### 3.2 OpenWrt 组件依赖

LuCI 需要以下组件:
- `rpcd` — RPC 守护进程 (处理 file.read/file.exec)
- `uhttpd` — HTTP 服务器 (服务 LuCI)
- `luci-base` — LuCI 核心库
- `luci-compat` — 兼容层
- `libubox`, `libubus` — OpenWrt IPC

这些在原厂 rootfs 中**不存在**。需要:
1. 交叉编译这些组件 for aarch64 glibc
2. 或者从 OpenWrt packages 中提取
3. 或者使用静态编译版本

### 3.3 启动流程集成

原厂启动流程:
```
rcS → appmgr → ( ponmgr, omciMgr, cfgmgr, ... )
```

我们需要在其中插入:
```
rcS → appmgr → ( ponmgr, omciMgr, cfgmgr, ... )
                ↓
              rpcd → uhttpd → LuCI
```

**方案:** 在 rcS 末尾或 appmgr 启动后添加:
```sh
# 启动 OpenWrt 服务
/etc/init.d/rpcd start
/etc/init.d/uhttpd start
```

### 3.4 /etc 写入

原厂 /etc 是 bind mount from /configs/etc (UBIFS):
```
mount --bind /configs/etc /etc
```

如果我们把 LuCI 文件放在 /configs/etc/，它们会出现在 /etc/ 中。
但 /usr/share/luci/ 等路径不在 /etc 下，需要放在 SquashFS 中或通过其他方式添加。

---

## 4. 建议的下一步

### 优先级 1: 评估 SquashFS 大小
```bash
# 在设备上测试
mksquashfs analysis/rootfs_mtd3/ /tmp/test_rootfs.bin -comp lzma -b 128k
ls -lh /tmp/test_rootfs.bin
# 如果 < 29MB，方案 A 可行
```

### 优先级 2: 交叉编译 OpenWrt 组件
需要为 aarch64 glibc 交叉编译:
- rpcd
- uhttpd
- luci-base
- luci-compat
- 相关依赖

### 优先级 3: 集成测试
1. 在 LXC 中验证完整启动流程
2. 模拟原厂 rcS → appmgr 流程
3. 测试 LuCI 在原厂环境中的行为

### 优先级 4: 写入设备
1. 备份所有 mtd 分区
2. 测试写入 mtd3 (或 mtd5)
3. 验证启动

---

## 5. 风险总结

| 风险 | 等级 | 缓解措施 |
|------|------|----------|
| SquashFS 超出分区大小 | 🟡 中 | 先测试压缩后大小 |
| LuCI 依赖缺失 | 🟡 中 | 交叉编译或提取 OpenWrt 包 |
| 启动流程被破坏 | 🟡 中 | 保留原厂 rcS，只在末尾添加 |
| 无法恢复原厂 | 🟢 低 | 保留 mtd3 备份，双 bank 机制 |
| 内核模块不兼容 | 🟢 低 | 不修改内核模块，只添加用户态 |
| /etc overlay 冲突 | 🟢 低 | 使用 /configs/etc/ 持久化 |

---

## 6. 结论

**当前 LXC 测试环境与真实设备是两个不同的系统。** LXC 验证了:
- Vendor 二进制在 glibc 2.37 上运行正常
- LuCI 视图代码逻辑正确
- UCI 配置结构合理

**但以下内容需要在真实设备上验证:**
- 内核模块加载 (PON, Ethernet, NAT)
- ponmgr/omciMgr 与真实硬件的交互
- OMCI 协议与 OLT 的通信
- 光模块参数读取
- 启动流程集成

**建议:** 先完成 SquashFS 大小评估和 OpenWrt 组件交叉编译，再进行设备写入。
