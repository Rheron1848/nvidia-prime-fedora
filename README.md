# nvidia-prime-fedora

在 Fedora 43 上为 NVIDIA 390.xx（Fermi 架构）+ muxless Optimus 笔记本实现 Reverse PRIME，
复现 Ubuntu/Mint `prime-select nvidia` 的效果。

**测试机型**：ThinkPad T530（Intel HD 4000 + NVIDIA NVS 5400M）

## 前提条件

- nvidia 390.157 DKMS 内核模块已安装（`dkms status` 显示 installed）
- `nvidia-drm.modeset=1` 已通过 `/etc/modprobe.d/nvidia-drm.conf` 设置
- `xorg-x11-server-Xorg` 已通过 `dnf reinstall` 修复（libglx.so 为 GLVND 版）
- SDDM 为显示管理器，KDE Plasma X11 会话

## 目录结构

```
config/
├── dkms.conf                          # DKMS 构建配置
├── modprobe.d/
│   ├── blacklist-nouveau.conf         # 禁用 nouveau
│   └── nvidia-drm.conf               # nvidia-drm modeset=1
├── dracut.conf.d/
│   └── 10-nvidia.conf                # nvidia 模块强制进 initramfs
├── X11/xorg.conf.d/
│   └── 10-optimus-prime.conf         # Reverse PRIME Xorg 配置（核心）
└── sddm/scripts/
    ├── Xsetup                         # SDDM X 启动钩子
    └── Xstop                          # SDDM X 停止钩子

scripts/
├── prime-offload                      # Reverse PRIME xrandr 配置脚本
└── prime-select                       # GPU 模式切换命令
```

## 安装方法

```bash
sudo bash install.sh
```

或手动逐步：

```bash
# 1. Xorg 配置
sudo cp config/X11/xorg.conf.d/10-optimus-prime.conf /etc/X11/xorg.conf.d/

# 2. prime-offload 脚本
sudo cp scripts/prime-offload /usr/local/bin/
sudo chmod +x /usr/local/bin/prime-offload

# 3. prime-select 命令
sudo cp scripts/prime-select /usr/local/bin/
sudo chmod +x /usr/local/bin/prime-select

# 4. SDDM Xsetup 钩子
sudo cp config/sddm/scripts/Xsetup /usr/share/sddm/scripts/Xsetup

# 5. 重新登录 X11 会话
```

## 切换命令

```bash
sudo prime-select nvidia   # 切换到独显模式（重新登录生效）
sudo prime-select intel    # 切换到核显模式（重新登录生效）
prime-select status        # 查看当前模式
```

## 验证

```bash
# 查看 provider（NVIDIA-0 应有 Source Output 能力）
xrandr --listproviders

# 查看当前渲染器（nvidia 模式下应为 NVS 5400M）
glxinfo | grep "OpenGL renderer"

# 查看配置日志
cat /var/log/prime-offload.log
```

## 回滚

```bash
sudo prime-select intel
# 重新登录即可恢复到 Intel 核显模式
```

## 背景

- `nvidia-prime` 源码：https://github.com/canonical/nvidia-prime
- NVIDIA 390.157 RandR 1.4 文档：https://download.nvidia.com/XFree86/Linux-x86_64/390.157/README/randr14.html
- ArchWiki PRIME：https://wiki.archlinux.org/title/PRIME

## 已知问题

- Vulkan + VSync 在 Reverse PRIME 下可能导致系统冻结（390.xx 已知 bug）
- glamor 与 NVIDIA GLX 可能冲突，若遇问题在 xorg.conf 的 Intel Device section 加 `Option "AccelMethod" "none"`
