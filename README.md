# ⚡ Hysteria2-LuoPo 管理面板

<div align="center">

专为恶劣网络环境打造的极简 Hysteria2 自动化运维脚本。<br>
告别繁琐的 YAML 缩进，告别玄学的连通性问题，实现真正的**“一键导入，秒开 4K”**。

[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Hysteria2](https://img.shields.io/badge/Core-Hysteria%20v2-blueviolet?style=flat-square)](https://v2.hysteria.network/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

</div>

---

## 📖 项目简介

Hysteria2 是一款基于修改版 QUIC 协议的代理工具，以其**暴力发包**和**无视晚高峰丢包**的特性，被誉为拯救“垃圾线路”的最强杀器。

本项目 (`hysteria2-luopo`) 旨在为 Hysteria2 提供一个极简、直观、高内聚的 Linux 终端管理面板。无论你是想用真实的域名 CA 证书，还是想直接 IP 裸连（自签证书），只需敲击几次键盘，脚本就能为你全自动配置好一切，并输出标准化的分享链接。

## ✨ 核心特性

- **🚀 极简部署**：一键拉取核心面板，自动安装最新版 Hysteria2 内核。
- **🛡️ 双模式证书**：
  - **CA 模式**：全自动 ACME 申请真实域名证书，伪装更彻底。
  - **自签模式**：无需域名，自动生成高强度自签名证书，直接 IP 暴力连通。
- **📦 标准化订阅**：告别客户端配置错误，脚本直接输出标准的 `hysteria2://` 分享链接。
- **📶 速率可调**：支持在配置阶段自定义 `up_mbps/down_mbps`，并同步输出到客户端配置片段。
- **📱 移动端友好**：原生输出完美的 `Sing-box` (Android/iOS) Outbound JSON 配置片段，复制即用。
- **🧩 模板直出**：支持输出完整 `Sing-box` 分流模板（含 DNS/路由规则），开箱即改即用。
- **⚙️ 全局掌控**：支持一键启动/停止/重启服务、实时查看运行日志、完全卸载。
- **📚 内置速查**：面板内置服务器常用指令与关键路径速查菜单，排障更快。
- **🩺 一键诊断**：支持快速检测服务状态、端口监听、证书文件、配置完整性和公网 IP 一致性。
- **📝 诊断导出**：诊断结果可自动导出到 `/tmp/hy2-diagnose-时间戳.log`，便于远程排障与反馈问题。
- **📄 报告回看**：支持直接查看最近一次诊断报告，快速复盘问题。
- **💾 备份恢复**：支持手动创建配置备份并一键恢复最近备份，降低误配置风险。

## 🛠️ 安装指南

支持主流的 Linux 发行版 (Debian / Ubuntu / CentOS)。请使用 `root` 用户登录您的 VPS，然后执行以下命令：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/hysteria2-luopo/main/install.sh)
```

> **注意**：安装成功后，随时在终端输入 `hy2` 即可唤出管理面板。

## 🖥️ 面板预览

```text
=====================================================
        Hysteria2-LuoPo 管理面板 V1.1
=====================================================
  [状态] Core: v2.2.4 | 服务: ● 运行中
=====================================================
  ◈ 节点与核心管理
    (1) 🚀 一键安装/更新 Hysteria2 内核
    (2) ⚙️ 配置 Hysteria2 节点 (CA / 自签)
    (3) 📦 查看客户端配置与分享链接

  ◈ 服务控制
    (4) ▶️ 启动 / ⏹️ 停止 / 🔄 重启 服务
    (5) 📜 查看实时运行日志
    (6) 🗑️ 完全卸载
    (7) ❓ 查看常用指令速查
    (8) 🧩 查看 Sing-box 完整模板
    (9) 🩺 一键环境诊断
    (10) 📄 查看最近诊断报告
    (11) 💾 配置备份与恢复
    (0) 退出面板
=====================================================
➡️ 请选择操作 [0-11]: 
```

## 📱 客户端连接必读

1. **Windows / PC 端**：推荐使用 **[v2rayN](https://github.com/2dust/v2rayN)** 或 **[NekoBoxForPc](https://github.com/MatsuriDayo/nekoray)**。在面板中输入 `3` 获取链接后，直接从剪贴板导入。
2. **Android / iOS 端**：推荐使用 **[Sing-box](https://github.com/SagerNet/sing-box)**。复制面板生成的 JSON 片段，替换掉你配置文件中的 `outbounds` 代理节点即可。
3. **⚠️ 自签证书注意**：如果您在配置时选择了“(2) 自签证书”，请确保在客户端的节点设置中，将 **“允许不安全 (insecure / 跳过证书验证)”** 选项设置为 `true`，否则将无法连接！

## 🤝 贡献与支持

如果你觉得这个项目拯救了你的网络，欢迎点击右上角的 **⭐ Star** 支持一下！
如果你发现了 Bug 或有更好的优化建议，欢迎提交 Issues 或 Pull Requests。

## 🧪 开发自检

如果你在本地修改了 `hy2.sh` 或 `install.sh`，建议先跑一次脚本质量检查：

```bash
chmod +x scripts/verify.sh
./scripts/verify.sh
```

该脚本会执行：

- `bash -n` 语法检查
- `shellcheck` 静态检查
- 菜单与 README 预览一致性检查（防止文档漂移）

## ✅ VPS 冒烟测试（5 分钟）

以下步骤用于在一台全新 Linux VPS 上快速验证 `v1.1.0` 可用性。

### 1) 一键安装面板

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/hysteria2-luopo/main/install.sh)
```

通过标准：

- 终端提示“面板安装完成”
- 可直接进入 `hy2` 菜单界面

### 2) 安装/更新 Hysteria2 内核（菜单 1）

在面板中输入：

```text
1
```

通过标准：

- 提示内核部署/更新完成
- 菜单状态行出现 Core 版本号（如 `v2.x.x`）

### 3) 生成节点配置（菜单 2）

在面板中输入：

```text
2
```

建议测试参数：

- 端口：`443`
- 密码：直接回车使用默认随机值
- 伪装网址：`https://bing.com`
- 证书模式：先选 `2`（自签）做快速验证
- SNI：`bing.com`

通过标准：

- 提示“节点配置并启动成功”
- 无回滚错误提示

### 4) 检查分享链接与 JSON（菜单 3）

在面板中输入：

```text
3
```

通过标准：

- 成功显示 `hysteria2://` 链接
- 成功显示 Sing-box JSON 片段
- 链接中的参数完整（`sni`、`insecure`）

### 5) 验证服务控制与日志（菜单 4、5）

先输入：

```text
4
```

依次测试：

- 启动服务
- 停止服务
- 重启服务
- 查看状态

再输入：

```text
5
```

通过标准：

- 服务控制子菜单各动作有明确成功/失败反馈
- 日志可正常跟随输出（`journalctl -f`）

### 6) 最后验收命令（可选）

```bash
systemctl is-active hysteria-server.service
systemctl status hysteria-server.service --no-pager -l
```

通过标准：

- `is-active` 输出 `active`
- `status` 无连续报错或崩溃重启

## 📜 开源协议

本项目基于 [MIT License](LICENSE) 协议开源。

