#!/bin/bash
# install.sh - 一键安装 Reverse PRIME 配置
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "请用 sudo 运行：sudo bash install.sh"
    exit 1
fi

echo "[1/4] 安装 Xorg 配置..."
cp "$SCRIPT_DIR/config/X11/xorg.conf.d/10-optimus-prime.conf" \
   /etc/X11/xorg.conf.d/10-optimus-prime.conf

echo "[2/4] 安装 prime-offload 脚本..."
cp "$SCRIPT_DIR/scripts/prime-offload" /usr/local/bin/prime-offload
chmod +x /usr/local/bin/prime-offload

echo "[3/4] 安装 prime-select 命令..."
cp "$SCRIPT_DIR/scripts/prime-select" /usr/local/bin/prime-select
chmod +x /usr/local/bin/prime-select

echo "[4/4] 配置 SDDM Xsetup 钩子..."
cp /usr/share/sddm/scripts/Xsetup /usr/share/sddm/scripts/Xsetup.bak
cp "$SCRIPT_DIR/config/sddm/scripts/Xsetup" /usr/share/sddm/scripts/Xsetup

echo ""
echo "✓ 安装完成。请重新登录 X11 会话以生效。"
echo "  验证：xrandr --listproviders"
echo "  日志：cat /var/log/prime-offload.log"
echo "  回滚：sudo prime-select intel"
