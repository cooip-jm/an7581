# 归档文件说明

这些文件/目录已从项目根目录移除，**不要使用**。

## 原因
iopsys OpenWrt 构建系统（SDK、内核源码、image 构建脚本等）已被证明**不能从零构建**。本项目采用的方案是：**vendor 二进制 + glibc OpenWrt rootfs + LuCI overlay**。

## 归档内容
- `openwrt/`, `5.4.55/`, `linux-5.4.225-base/` — 内核/SDK 源码
- `econet-kernel/`, `en7523/`, `lantiq/`, `iopsys_kernel/` — 其他平台内核
- `image/`, `Makefile`, `config`, `Config.in` — 构建系统
- `modules/`, `kernel/` — 内核模块（非 vendor PON 模块）
- `an7581/`, `an7583/` — 其他设备配置
- `build*.sh` — 旧构建脚本
- `GPL_*.tar.gz`, `airoha_sdk.tar.gz` — SDK 源码包
- `WXK001-*.bin` — 原厂固件（备份在 back_an_7581_40md/）
- `dts/`, `output/`, `rootfs-build/`, `sdk_extracted/` — 旧构建产物
- `other/`, `usbhost/`, `gpl_extracted/` — 杂项

## 正确的项目路径
- `luci-overlay/` — LuCI 覆盖层（在开发中）
- `analysis/rootfs_mtd3/` — vendor rootfs 提取（ponmgr, omciMgr, libs）
- `back_an_7581_40md/` — 原厂固件 mtd 分区备份
- `base-files/` — iopsys 基础文件（仅参考 ecnt_xpon 启动逻辑）
- `fake_pon/` — LXC 测试用 LD_PRELOAD shim
- `an7581_glibc_rootfs_20260728.tar.gz` — LXC 测试用 rootfs 备份

## 文档
- `DOC_VENDOR_BOOT_FLOW.md` — 原厂固件完整启动流程
- `DOCOUR_WORK.md` — 我们已完成的工作
- `DOC_DEPLOY Assessment.md` — 真实设备部署评估
- `STATUS.md` — 当前状态记录
- `TODO.md` — 待修复问题
