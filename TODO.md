# AN7581 PON LuCI - 待解决问题

> **重要**: 修改前先读 STATUS.md 和 DOCOUR_WORK.md 了解已有功能。
> **部署评估**: 见 DOC_DEPLOY Assessment.md (最后阶段才考虑)
> **最后更新**: 2026-07-28

---

## 优先级说明
- **P0 (阻塞)**: 不修就无法在 LXC 中继续测试
- **P1 (核心)**: 影响 LXC 中的基本功能验证
- **P2 (重要)**: 影响用户体验
- **P3 (优化)**: 锦上添花
- **最终阶段**: 真实设备部署 (所有 LXC 验证通过后才考虑)

---

## P0: 配置保存后不生效

**现象**: config.js 和 auth.js 保存 UCI 配置后，ponmgr/omciMgr 不会读取新值。

**原因**: `pon_apply_uci.sh` 只在 `ecnt_xpon` boot() 中被调用。LuCI 表单保存只做 `uci commit`，没有触发 apply 脚本。

**解决方案**: 在 config.js 和 auth.js 的 form.Map 中添加 `save` 回调，通过 `file.exec` 调用 `pon_apply_uci.sh`。但 `file.exec` 在 rpcd 中被屏蔽。

**备选方案**:
1. 创建一个 ubus 服务来执行 apply
2. 通过 `/cgi-bin/` CGI 脚本执行
3. 在 init.d 中添加 hotplug 监听 UCI 变更
4. 直接在 JS 中调用 pon_helpers.sh 中的各个 pon_set_* 函数 (需要 file.exec)

---

## P1: 认证流程未完整实现

**当前状态**: auth.js 可以保存 SN/SLID/LOID 到 UCI，但没有反馈机制告诉用户认证是否成功。

**完整认证流程** (需要实现):
```
用户在 auth.js 设置 SN + 密码
    ↓ UCI commit
pon_apply_uci.sh 读取 UCI
    ↓ 调用 ponmgr CLI
ponmgr gpon set sn / ont_password
    ↓ 写入内核驱动
ponmgr gpon get status → 显示注册状态
    ↓ OLT 验证
omci_state 从 O1→O2→O4→O5 (成功) 或停留在 O2 (失败)
    ↓
status.js 显示链路状态
```

**需要实现的反馈**:
1. 保存配置后自动调用 pon_apply_uci.sh
2. 显示当前 ponmgr 守护进程状态
3. 认证失败时显示失败原因 (OMCI 状态 O2/O3)
4. 状态页面显示当前认证信息 (SN 是否已设置)

---

## P1: 模拟数据格式需匹配真实设备

**当前**: 模拟数据是简单文本 (如 `55.3`, `-21.3`, `O5`)

**真实设备格式** (需要确认):
- 光模块数据可能是原始整数 (如 55300 表示 55.3°C)
- omci_state 可能是完整状态字符串
- 需要分析 ponmgr 输出格式来确认

**需要做的**:
1. 在 LXC 中运行 `ponmgr gpon get info` 获取输出格式
2. 检查 pon_helpers.sh 中的转换函数是否正确
3. 更新模拟数据以匹配真实格式
4. 更新 pon_helpers.sh 中的转换函数

---

## P2: OMCI 状态页面字体太小

**文件**: `omci.js`

**问题**: OMCI 状态使用 `label` class (小标签样式)

**修正**: 改为普通文本，与其他页面保持一致。

---

## P2: LED 状态未显示

**需求**: PON LED 应该反映连接状态。

**实现方案**:
1. 读取 `/sys/class/leds/` 获取当前 LED 状态
2. 或通过 ponmgr CLI 获取 LED 状态
3. 在 status.js 显示 LED 指示器

**需要确认**: 真实设备的 LED 控制接口是什么？

---

## P2: 跨页面数据重复

**问题**:
- status.js 和 optical.js 都显示 TX/RX power, temperature
- status.js 和 omci.js 都显示 OMCI state

**方案**: 
- status.js: 概览页面，显示关键状态 + 链接跳转
- optical.js: 详细光模块参数 + 计数器
- omci.js: OMCI 协议状态 + 设备信息

---

## P3: 自动刷新

**问题**: status.js 和 optical.js 显示实时数据，但页面加载后不会自动更新。

**方案**: 使用 LuCI 的 `request.poll()` 或 `L.poll()` 实现定时刷新。

---

## P3: UCI 配置项未完全应用

| UCI Key | 当前状态 | 需要 |
|---------|----------|------|
| pon.global.fec_rx | ✅ 已应用 | - |
| pon.global.fec_tx | ❌ 未应用 | 需要 ponmgr set tx_fec_cfg |
| pon.global.aes | ❌ 未应用 | 需要确认接口 |
| pon.global.enabled | ❌ 未强制 | 需要 procd service wrapper |
| pon.omci.enabled | ❌ 未应用 | 需要 start/stop omciMgr |
| pon.omci.auto_start | ❌ 未应用 | 需要开机行为控制 |
| pon_auth.password | ❌ 未应用 | 需要确认 ponmgr 接口 |
| pon.device | ❌ 未使用 | 需要确认用途 |

---

## 最终阶段: 真实设备部署

> ⚠️ 以下内容仅在所有 LXC 验证通过后才考虑

**前提条件**:
1. 所有 P0-P2 问题在 LXC 中解决
2. LuCI 5 个页面功能完整验证
3. 配置保存→应用→反馈流程验证通过
4. 模拟数据格式与真实设备匹配确认

**部署方案**: 见 `DOC_DEPLOY Assessment.md`
- 方案 A (推荐): 修改 vendor rootfs，添加 LuCI overlay
- 方案 B: 运行时覆盖 (利用 /configs/etc overlay)
- 方案 C: 双系统 (bank1 原厂, bank2 我们的)

**需要解决的技术问题**:
1. SquashFS 重新打包大小评估
2. OpenWrt 组件交叉编译 (rpcd, uhttpd, luci-base)
3. 启动流程集成 (rcS → appmgr → LuCI)
4. 写入设备方法 (U-Boot 命令? Web 升级?)

---

## 测试清单

每次修改后，必须在 LXC 容器中验证:

```bash
# 1. 重启容器
ssh root@192.168.0.86 "lxc-restart -n an7581_test"

# 2. 检查网络
ssh root@192.168.0.86 "lxc-attach -n an7581_test -- ip addr show eth0"

# 3. 检查 LuCI 页面
# 访问 http://192.168.0.87/cgi-bin/luci

# 4. 检查 UCI 配置
ssh root@192.168.0.86 "lxc-attach -n an7581_test -- uci show pon"
ssh root@192.168.0.86 "lxc-attach -n an7581_test -- uci show pon_auth"

# 5. 检查模拟数据
ssh root@192.168.0.86 "lxc-attach -n an7581_test -- ls -la /root/tc3162/"
```

---

## 架构决策记录

### 为什么不用 CI workflow?
- generic OpenWrt rootfs (musl) 无法运行 vendor 二进制文件 (glibc)
- CI 只生成 overlay 文件，不编译完整 firmware
- 等核心问题解决后再考虑 CI

### 为什么模拟数据在 /root/tc3162/?
- /proc 是内核虚拟文件系统，无法 bind mount 到 LXC
- UCI proc_path 配置允许在 LXC 中使用 /root/tc3162/ 作为替代
- 真实设备使用 /proc/tc3162/ (内核驱动直接暴露)

### 为什么 file.exec 不可用?
- rpcd 有严格的 ACL 控制
- 即使授权了 file.exec，rpcd 也返回 "Not found"
- 只能通过 file.read 读取文件，不能执行命令

### 为什么不能从零构建 iopsys OpenWrt 固件?
- 缺少完整的 SDK 和构建环境
- vendor 内核模块需要特定工具链编译
- 已验证不可行，不再尝试
