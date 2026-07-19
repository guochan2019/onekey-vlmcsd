#!/bin/bash
cd /tmp
# ============================================================
# onekey-vlmcsd — vlmcsd (KMS Emulator) 一键安装/升级/卸载脚本
# 适用环境: Debian LXC (amd64)
# 上游: https://github.com/Wind4/vlmcsd
# ============================================================
set -e

trap 'echo -e "\033[0;31m[ERROR] 脚本执行失败，请检查:\033[0m
  - 网络连接（能否访问 github.com）
  - 是否以 root 运行" >&2' ERR

# ---------- 配置 ----------
INSTALL_DIR="/opt/vlmcsd"
BIN="/usr/local/bin/vlmcsd"

# ---------- 彩色输出 ----------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------- 检测 root ----------
if [ "$(id -u)" -ne 0 ]; then
  err "请以 root 用户运行 (当前非 root)"
fi

# ---------- 检测架构 ----------
detect_arch() {
  case "$(uname -m)" in
    x86_64)  echo "x64" ;;
    aarch64) echo "arm64" ;;
    i386|i686) echo "x86" ;;
    *)       echo "" ;;
  esac
}

# ---------- 安装 ----------
do_install() {
  info "=== 开始安装 vlmcsd ==="

  # 1. 安装依赖
  info "=== 1/4 安装系统依赖 ==="
  apt-get update -qq 2>/dev/null
  apt-get install -y -qq wget curl 2>/dev/null
  info "  ✓ 依赖已安装"

  # 2. 下载并解包
  info "=== 2/4 下载 vlmcsd ==="
  ARCH=$(detect_arch)
  [ -z "$ARCH" ] && err "不支持的架构: $(uname -m)"
  
  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"
  info "  → 下载 binaries.tar.gz ..."
  wget -q "https://github.com/Wind4/vlmcsd/releases/download/svn1113/binaries.tar.gz" -O binaries.tar.gz
  info "  → 解包 ..."
  tar -xzf binaries.tar.gz
  
  # 查找对应架构的 vlmcsd 和 vlmcs
  VLMCSD=$(find binaries -name "vlmcsd-${ARCH}-glibc" -type f | head -1)
  VLMCS=$(find binaries -name "vlmcs-${ARCH}-glibc" ! -name "*multi*" -type f | head -1)
  
  if [ -z "$VLMCSD" ]; then
    err "未找到 ${ARCH} 架构的 vlmcsd 二进制文件"
  fi

  # 3. 安装到系统
  info "=== 3/4 安装二进制 ==="
  # 备份旧的二进制
  if [ -f "$BIN" ]; then
    cp "$BIN" "${BIN}.bak.$(date +%Y%m%d_%H%M%S)"
    info "  ✓ 旧二进制已备份"
  fi
  
  cp "$VLMCSD" "$BIN"
  chmod +x "$BIN"
  info "  ✓ vlmcsd 已安装到 ${BIN}"
  
  if [ -n "$VLMCS" ]; then
    cp "$VLMCS" "/usr/local/bin/vlmcs"
    chmod +x "/usr/local/bin/vlmcs"
    info "  ✓ vlmcs 客户端已安装到 /usr/local/bin/vlmcs"
  fi

  mkdir -p /var/log/vlmcsd

  # 4. 创建 systemd 服务
  info "=== 4/4 创建 systemd 服务 ==="
  cat > /etc/systemd/system/vlmcsd.service << 'SERVICEEOF'
[Unit]
Description=vlmcsd - KMS Emulator Server
Documentation=https://github.com/Wind4/vlmcsd
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/vlmcsd -D -l /var/log/vlmcsd/vlmcsd.log
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

StandardOutput=append:/var/log/vlmcsd/vlmcsd.log
StandardError=append:/var/log/vlmcsd/vlmcsd.log

[Install]
WantedBy=multi-user.target
SERVICEEOF
  systemctl daemon-reload
  systemctl enable vlmcsd
  systemctl restart vlmcsd
  sleep 1
  
  if systemctl is-active vlmcsd &>/dev/null; then
    info "  ✓ vlmcsd 已成功启动！"
  else
    warn "  ⚠ vlmcsd 启动失败，检查日志: journalctl -u vlmcsd -n 50 --no-pager"
    systemctl status vlmcsd --no-pager
    exit 1
  fi

  # 清理
  rm -rf "$TMP_DIR"

  info ""
  info "========== 安装完成 =========="
  info " vlmcsd 版本: svn1113 (2020-03-28)"
  info " 监听端口:    TCP 1688"
  info " 日志文件:    /var/log/vlmcsd/vlmcsd.log"
  info ""
  info " Windows / Office 激活方法:"
  info "  以管理员身份运行:"
  info "    slmgr /skms 192.168.50.22:1688"
  info "    slmgr /ato"
  info "    slmgr /dli"
  info "=================================="
}

# ---------- 卸载 ----------
do_uninstall() {
  info "=== 卸载 vlmcsd ==="
  
  # 停止并禁用服务
  if systemctl is-active vlmcsd &>/dev/null; then
    systemctl stop vlmcsd
    systemctl disable vlmcsd
    info "  ✓ 服务已停止并禁用"
  fi
  
  # 删除 service 文件
  rm -f /etc/systemd/system/vlmcsd.service
  systemctl daemon-reload
  info "  ✓ service 文件已删除"
  
  # 删除二进制
  rm -f /usr/local/bin/vlmcsd /usr/local/bin/vlmcs
  info "  ✓ 二进制文件已删除"
  
  # 删除日志
  rm -rf /var/log/vlmcsd
  info "  ✓ 日志已删除"

  # 删除安装目录
  rm -rf "$INSTALL_DIR"

  info ""
  info "========== 卸载完成 =========="
}

# =================== 主菜单 ===================
echo ""
echo "========================================"
echo "  vlmcsd 一键安装/卸载脚本"
echo "  https://github.com/Wind4/vlmcsd"
echo "========================================"
echo ""

ARCH=$(detect_arch)
[ -z "$ARCH" ] && err "不支持的架构: $(uname -m) (仅支持 x86_64 / aarch64)"

INSTALLED=false
if [ -f "$BIN" ]; then
  INSTALLED=true
  VER=$("$BIN" -V 2>/dev/null || echo "")
  if [ -n "$VER" ]; then
    info "检测到 vlmcsd (${VER}) 已安装"
  else
    info "检测到 vlmcsd 已安装"
  fi
else
  info "vlmcsd 未安装"
fi

echo ""
echo "请选择操作："
echo "  1. 安装 / 升级 vlmcsd"
echo "  2. 卸载 vlmcsd"
echo "  0. 退出"
echo ""
read -p "请输入选项 (0-2): " ACTION </dev/tty
echo ""

case "$ACTION" in
  2)
    do_uninstall
    ;;
  0)
    info "已退出"
    exit 0
    ;;
  1|"")
    do_install
    ;;
  *)
    err "无效选项: ${ACTION}"
    ;;
esac
