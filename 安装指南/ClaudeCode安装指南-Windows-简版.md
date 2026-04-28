# Claude Code 安装指南 — Windows（简版）

> **作者**: @Mzs | **日期**: 2026/4/28 | **版本**: v1.0.0
>
> GitHub: [github.com/Mzs-code/ai-wiki](https://github.com/Mzs-code/ai-wiki)

---

## 目录

- [Claude Code 安装指南 — Windows（简版）](#claude-code-安装指南--windows简版)
  - [目录](#目录)
  - [一、安装 CC-Switch](#一安装-cc-switch)
  - [二、安装 Git](#二安装-git)
  - [三、安装 Claude Code](#三安装-claude-code)
  - [四、验证安装](#四验证安装)
  - [五、验证连通性](#五验证连通性)

---

## 一、安装 CC-Switch

CC-Switch 是 Claude Code 的配置管理工具, 提供 Skills 管理、会话管理、API Key 管理等功能.

1. 浏览器访问 https://github.com/farion1231/cc-switch
2. 点击右侧 **Releases**, 滑动到页面最下方的 **Assets**
3. 下载 Windows 版安装包: `CC-Switch-v.xx.xx-Windows.exe`
4. 双击运行安装包, 按提示完成安装
5. 私信公司管理员获取 **API Key**
6. 打开 CC-Switch, 点击右上角 **添加按钮** → 选择 **PackyCode** → 填入 Key → 点击 **添加**

---

## 二、安装 Git

1. 浏览器访问 https://git-scm.com/downloads/win
2. 点击下载 **Standalone Installer** 对应你系统的版本（通常选择 **64-bit**）
3. 双击安装, 安装过程中保持**默认选项**即可（确保勾选了 "Add to PATH"）
4. 安装完成后, 在 PowerShell 中执行 `git --version`, 能输出版本号则代表安装成功

---

## 三、安装 Claude Code

打开 PowerShell（按 `Win + S` 搜索 "PowerShell"），执行:

```powershell
winget install Anthropic.ClaudeCode
```

> WinGet 使用本地源, **无需科学上网**, 国内网络也稳定.
>
> 后续更新版本可执行: `winget upgrade Anthropic.ClaudeCode`

---

## 四、验证安装

安装完成后, **关闭并重新打开** PowerShell, 执行:

```powershell
claude --version
```

正确输出类似 `2.x.xx` 的版本号, 则代表安装成功.

---

## 五、验证连通性

1. 启动 Claude Code:

```powershell
claude
```

2. 首次启动会提示登录, 按照屏幕指引在浏览器中完成认证

3. 登录完成后, 发送 `ping`, 如果收到 `pong`, 则代表配置成功, 可以开始使用了
