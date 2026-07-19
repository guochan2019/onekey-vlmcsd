# onekey-vlmcsd

一键在 Debian LXC 上部署 [vlmcsd](https://github.com/Wind4/vlmcsd) — KMS 激活服务端。

## 快速开始

> ⚠️ 需要 root 权限。

```bash
# 方式一：一键直达（推荐）
bash <(wget -qO- https://raw.githubusercontent.com/guochan2019/onekey-vlmcsd/main/onekey-vlmcsd.sh)

# 方式二：wget
wget -qO- https://raw.githubusercontent.com/guochan2019/onekey-vlmcsd/main/onekey-vlmcsd.sh | bash
```

## 使用方式

运行脚本后显示菜单：

```
========================================
  vlmcsd 一键安装/卸载脚本
  https://github.com/Wind4/vlmcsd
========================================

[INFO] vlmcsd 未安装

请选择操作：
  1. 安装 / 升级 vlmcsd
  2. 卸载 vlmcsd
  0. 退出
```

| 选项 | 功能 |
|------|------|
| **1** | 安装 vlmcsd（从 upstream release 下载） |
| **2** | 卸载：停止服务、删除二进制/日志 |
| **0** | 退出 |

## 安装流程

| 步骤 | 说明 |
|------|------|
| 1/4 | 安装系统依赖（wget、curl） |
| 2/4 | 从 Wind4/vlmcsd release 下载并解包二进制 |
| 3/4 | 安装 vlmcsd + vlmcs 到 /opt/vlmcsd/ |
| 4/4 | 创建 systemd 服务并启动 |

## 使用说明

安装后 vlmcsd 在 **TCP 1688** 端口监听。

### Windows 激活

```cmd
slmgr /skms 192.168.50.22:1688
slmgr /ato
slmgr /dli
```

### Office 激活

```cmd
cd "C:\Program Files\Microsoft Office\Office16"
cscript ospp.vbs /sethst:192.168.50.22
cscript ospp.vbs /act
```

## 目录结构

```
/opt/vlmcsd/
├── vlmcsd                      # vlmcsd 守护进程（KMS 服务端）
└── vlmcs                       # vlmcs 命令行客户端

/usr/local/bin/vlmcs -> /opt/vlmcsd/vlmcs   # 软链接，方便命令行调用
/var/log/vlmcsd/vlmcsd.log      # 运行日志
```

## 服务管理

```bash
systemctl status vlmcsd       # 查看状态
systemctl restart vlmcsd      # 重启
systemctl stop vlmcsd         # 停止
journalctl -u vlmcsd -f       # 实时日志
```

### 升级 / 卸载

再次运行脚本选择对应选项即可：

```bash
bash onekey-vlmcsd.sh
# 选 1 → 升级；选 2 → 卸载
```

## 架构支持

x86_64 / aarch64

## 上游

[vlmcsd](https://github.com/Wind4/vlmcsd) — KMS Emulator in C，已归档但功能稳定。

## 许可证

本项目基于 [GPL-3.0](LICENSE) 协议。vlmcsd 本身同样遵循 GPL-3.0。
