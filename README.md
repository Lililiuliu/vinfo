# vinfo - 开发环境一站式查询工具

在终端或菜单栏一键查看 Python、Node.js、Docker、Git 等开发环境状态。

## 两种使用方式

| 版本 | 平台 | 说明 |
|------|------|------|
| **CLI 版** | macOS / Linux | 终端 TUI 界面，跨平台 |
| **macOS 版** | macOS 14+ | 菜单栏常驻应用 |

---

## macOS 菜单栏版 (VinfoBar)

菜单栏图标实时显示开发环境状态，点击展开详情。

### 安装

```bash
cd VinfoBar
swift build -c release && ./build_app.sh
open build/VinfoBar.app
```

### 功能

- 菜单栏图标，点击展开 Popover
- 自动检测 Python / Node.js / Docker / Git 环境
- 支持自动刷新 (1/2/5/15/30 分钟)
- 设置窗口控制显示哪些环境
- 点击环境查看详情

### 截图

```
┌─────────────────────────────────────┐
│ Development Environment      [刷新] │
├─────────────────────────────────────┤
│ ✓ Python 3.12.0                     │
│   pyenv, 3 venvs                    │
│                                     │
│ ✓ Node.js 20.0.0                    │
│   nvm, npm 10.0.0                   │
│                                     │
│ ✓ Docker 24.0.5                     │
│   running, 2 containers             │
│                                     │
│ ✓ Git 2.50.0                        │
│   gh: logged in                     │
├─────────────────────────────────────┤
│ [Settings]          Updated: 5s ago │
└─────────────────────────────────────┘
```

---

## CLI 版 (终端 TUI)

在终端中以交互式界面查看开发环境。

### 安装

```bash
pip install .

# 或使用 uv（推荐）
uv pip install .
```

### 使用方法

```bash
vinfo              # 概览所有环境
vinfo python       # Python 详情
vinfo node         # Node.js 详情
vinfo docker       # Docker 详情
vinfo git          # Git 详情
```

### 功能预览

```
$ vinfo

__     _____        __
\ \   / /_ _|_ __  / _| ___
 \ \ / / | || '_ \| |_ / _ \
  \ V /  | || | | |  _| (_) |
   \_/  |___|_| |_|_|  \___/

v0.1.0

                         开发环境状态
┏━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Status   ┃ Environment     ┃ Version              ┃ Details                  ┃
┡━━━━━━━━━━╇━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ OK       │ Python 3.12.12  │ 3.12.12              │ Pyenv, pip 25.0.1        │
│ OK       │ Node.js 24.13.1 │ 24.13.1              │ nvm, npm 11.8.0          │
│ OK       │ Git 2.50.1      │ 2.50.1               │ GitHub CLI logged in     │
└──────────┴─────────────────┴───────────────────────┴──────────────────────────┘
```

---

## 支持的环境

| 环境 | 检测内容 |
|------|---------|
| **Python** | 版本、路径、pip 版本、pyenv 版本、虚拟环境 |
| **Node.js** | 版本、nvm/fnm/volta、npm 版本 |
| **Docker** | 守护进程状态、容器、镜像、卷 |
| **Git** | 用户配置、GitHub CLI 登录状态、当前仓库 |

## 系统要求

| 版本 | 要求 |
|------|------|
| CLI 版 | Python 3.11+, macOS / Linux |
| macOS 版 | macOS 14+ (Sonoma) |

## 项目结构

```
vinfo/
├── src/vinfo/          # Python CLI 版本
│   ├── core/           # 核心逻辑
│   ├── providers/      # 环境检测器
│   ├── actions/        # 快捷操作
│   └── ui/             # TUI 界面
│
└── VinfoBar/           # macOS 菜单栏版本
    ├── Sources/VinfoBar/
    │   ├── App/        # 应用入口
    │   ├── Core/       # 命令执行
    │   ├── Models/     # 数据模型
    │   ├── Providers/  # 环境检测器
    │   ├── Services/   # 服务层
    │   └── Views/      # SwiftUI 界面
    └── build_app.sh    # 打包脚本
```

## 许可证

MIT