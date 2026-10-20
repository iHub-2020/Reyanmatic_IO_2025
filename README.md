# Reyanmatic 路由器固件

预编译固件，下载见 **[Releases](../../releases)**。

## 镜像文件说明

### x86 / 64 位（软路由 / 虚拟机）

| 文件 | 用途 |
|---|---|
| `*-combined-efi.img` | 物理机 / 通用虚拟机（UEFI）。写入磁盘：`dd` / balenaEtcher / physdiskwrite |
| `*.qcow2` | Proxmox VE / KVM / QEMU 直接导入 |
| `*.vmdk` | VMware ESXi / Workstation |
| `*.vdi` | VirtualBox |

### NanoPi R2S

| 文件 | 用途 |
|---|---|
| `*-sysupgrade.img.gz` | 写入 TF 卡（balenaEtcher / `dd`），或已运行系统里 `sysupgrade` 升级 |

## 首次启动

- 管理地址：`http://192.168.8.198`（2026-10-20 之后编译的 OpenWrt 固件）
- 更早的固件（含 LEDE 版）管理地址为 `http://192.168.1.198`。
- 用户名 `root`，密码见交付说明。

## 免责声明

固件按"现状"提供，不附带任何担保；刷机有风险，请自行备份原固件与数据。
