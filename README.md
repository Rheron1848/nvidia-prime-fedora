# nvidia-prime-fedora

> ⚠️ **This project was completed with AI assistance (Claude by Anthropic).**
>
> ⚠️ **本项目由 AI 辅助完成（Claude，by Anthropic）。**

---

Reverse PRIME GPU switching for NVIDIA 390.xx (Fermi) + muxless Optimus laptops on Fedora 43,
replicating the behavior of `prime-select nvidia` from Ubuntu/Mint.

在 Fedora 43 上为 NVIDIA 390.xx（Fermi 架构）+ muxless Optimus 笔记本实现 Reverse PRIME GPU 切换，
复现 Ubuntu/Mint `prime-select nvidia` 的效果。

**Tested on / 测试机型**：ThinkPad T530（Intel HD 4000 + NVIDIA NVS 5400M）

---

## Prerequisites / 前提条件

- NVIDIA 390.157 DKMS kernel module installed → see [nvidia-390xx-dkms-fedora](https://github.com/Rheron1848/nvidia-390xx-dkms-fedora)
- NVIDIA 390.157 DKMS 内核模块已安装 → 参见 [nvidia-390xx-dkms-fedora](https://github.com/Rheron1848/nvidia-390xx-dkms-fedora)
- `nvidia-drm.modeset=1` set via `/etc/modprobe.d/nvidia-drm.conf`
- `xorg-x11-server-Xorg` reinstalled via `dnf reinstall` to restore GLVND `libglx.so`
- SDDM display manager + KDE Plasma X11 session

---

## How It Works / 工作原理

```
NVIDIA GPU renders frame
  → copied over PCIe to Intel VRAM      (Reverse PRIME)
    → Intel driver scans out to display

NVIDIA GPU 渲染画面
  → 通过 PCIe 复制到 Intel 显存          (Reverse PRIME)
    → Intel 驱动将帧扫出到物理屏幕
```

SDDM runs `/usr/share/sddm/scripts/Xsetup` as root before the login screen appears,
which calls `prime-offload` to wire up the xrandr providers.

SDDM 在登录界面出现前以 root 身份执行 `/usr/share/sddm/scripts/Xsetup`，
调用 `prime-offload` 建立 xrandr provider 路由。

---

## File Structure / 目录结构

```
config/
├── dkms.conf                          # DKMS build config / DKMS 构建配置
├── modprobe.d/
│   ├── blacklist-nouveau.conf         # Disable nouveau / 禁用 nouveau
│   └── nvidia-drm.conf               # nvidia-drm modeset=1
├── dracut.conf.d/
│   └── 10-nvidia.conf                # Force nvidia modules into initramfs
├── X11/xorg.conf.d/
│   └── 10-optimus-prime.conf         # Reverse PRIME Xorg config (core)
└── sddm/scripts/
    ├── Xsetup                         # SDDM pre-login hook
    └── Xstop                          # SDDM post-session hook

scripts/
├── prime-offload                      # xrandr Reverse PRIME routing script
└── prime-select                       # GPU mode switch command
```

---

## Installation / 安装

```bash
git clone https://github.com/Rheron1848/nvidia-prime-fedora.git
cd nvidia-prime-fedora
sudo bash install.sh
```

Or manually / 或手动逐步：

```bash
# 1. Xorg config / Xorg 配置
sudo cp config/X11/xorg.conf.d/10-optimus-prime.conf /etc/X11/xorg.conf.d/

# 2. prime-offload script / prime-offload 脚本
sudo cp scripts/prime-offload /usr/local/bin/
sudo chmod +x /usr/local/bin/prime-offload

# 3. prime-select command / prime-select 命令
sudo cp scripts/prime-select /usr/local/bin/
sudo chmod +x /usr/local/bin/prime-select

# 4. SDDM Xsetup hook / SDDM Xsetup 钩子
sudo cp config/sddm/scripts/Xsetup /usr/share/sddm/scripts/Xsetup

# 5. Re-login to X11 session / 重新登录 X11 会话
```

---

## Usage / 使用

```bash
sudo prime-select nvidia   # Switch to NVIDIA mode (re-login required)
                           # 切换到独显模式（重新登录生效）

sudo prime-select intel    # Switch to Intel mode (re-login required)
                           # 切换到核显模式（重新登录生效）

prime-select status        # Show current mode / 查看当前模式
```

---

## Verification / 验证

```bash
# Provider list - NVIDIA-0 should show Source Output capability
# Provider 列表 - NVIDIA-0 应有 Source Output 能力
xrandr --listproviders

# Renderer - should show NVS 5400M in nvidia mode
# 渲染器 - nvidia 模式下应为 NVS 5400M
glxinfo | grep "OpenGL renderer"

# offload log / 配置日志
cat /var/log/prime-offload.log
```

---

## Rollback / 回滚

```bash
sudo prime-select intel
# Re-login to restore Intel-only mode
# 重新登录即可恢复到 Intel 核显模式
```

---

## Known Issues / 已知问题

- **Vulkan + VSync deadlock**: Known bug in 390.xx with Reverse PRIME; disable VSync in Vulkan apps as a workaround.
- **Vulkan + VSync 死锁**：390.xx + Reverse PRIME 已知 bug，建议关闭 Vulkan 应用的 VSync。
- **glamor conflict**: If display issues occur, add `Option "AccelMethod" "none"` to the Intel Device section in `10-optimus-prime.conf`.
- **glamor 冲突**：若出现显示问题，在 xorg.conf 的 Intel Device section 加 `Option "AccelMethod" "none"`。

---

## References / 参考资料

- [canonical/nvidia-prime](https://github.com/canonical/nvidia-prime) — Original implementation for Ubuntu/Mint
- [NVIDIA 390.157 RandR 1.4 README](https://download.nvidia.com/XFree86/Linux-x86_64/390.157/README/randr14.html)
- [ArchWiki: PRIME](https://wiki.archlinux.org/title/PRIME)
- [nvidia-390xx-dkms-fedora](https://github.com/Rheron1848/nvidia-390xx-dkms-fedora) — Driver installation (companion repo)
