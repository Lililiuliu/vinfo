# vinfo - 开发环境一站式查询工具

在终端里一键查看 Python、Node.js、Docker、Git 等开发环境状态。

## 功能预览

```
$ vinfo

__     _____        __
\ \   / /_ _|_ __  / _| ___
 \ \ / / | || '_ \| |_ / _ \
  \ V /  | || | | |  _| (_) |
   \_/  |___|_| |_|_|  \___/


                         开发环境状态
┏━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Status   ┃ Environment     ┃ Version              ┃ Details                  ┃
┡━━━━━━━━━━╇━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━┫━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ OK       │ Python 3.12.12  │ 3.12.12              │ Pyenv, pip 25.0.1        │
│ OK       │ Node.js 24.13.1 │ 24.13.1              │ nvm, npm 11.8.0          │
│ OK       │ Git 2.50.1      │ 2.50.1 (Apple        │ GitHub CLI 已登录        │
│          │ (Apple Git-155) │ Git-155)             │ (Lililiuliu)             │
└──────────┴─────────────────┴───────────────────────┴──────────────────────────┘

查看详情: vinfo python | vinfo node | vinfo docker | vinfo git
```

## 安装

```bash
pip install .
```

或使用 uv（推荐）：

```bash
uv pip install .
```

## 使用方法

### 概览所有环境
```bash
vinfo
```

### 查看单个环境详情
```bash
vinfo python   # Python 环境（版本、pyenv、虚拟环境、pip 包）
vinfo node     # Node.js 环境（版本、nvm、npm）
vinfo docker   # Docker 环境（容器、镜像、卷）
vinfo git      # Git / GitHub CLI 配置
```

## 支持的环境

| 环境 | 检测内容 |
|------|---------|
| **Python** | 版本、路径、pip 版本、pyenv 版本、虚拟环境 |
| **Node.js** | 版本、nvm/fnm/volta、npm 版本 |
| **Docker** | 守护进程状态、容器、镜像、卷 |
| **Git** | 用户配置、GitHub CLI 登录状态、当前仓库 |

## 系统要求

- Python 3.11+
- macOS / Linux

## 许可证

MIT
