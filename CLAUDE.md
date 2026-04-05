# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

vinfo is a development environment monitoring tool available in two versions:
- **Python CLI** (`src/vinfo/`): Terminal TUI application using Textual
- **Swift macOS app** (`VinfoBar/`): Menu bar application using SwiftUI

Both versions share the same architecture: Provider-based environment detection for Python, Node.js, Docker, and Git.

## Build Commands

### Python CLI
```bash
pip install .                    # Install
vinfo                            # Run
vinfo python|node|docker|git     # View specific environment
```

### Swift macOS App
```bash
cd VinfoBar
swift build                      # Debug build
swift build -c release           # Release build
./build_app.sh                   # Package as .app
open build/VinfoBar.app          # Run
```

## Architecture

### Provider Pattern (shared between both versions)

Each environment (Python/Node/Docker/Git) has a Provider implementing:

```
detect()      → Check if tool is installed
collect()     → Gather environment info
healthCheck() → Return status + warnings
```

Providers are registered and sorted by `priority` (lower = shown first).

### Python Version

- `core/runner.py`: `CommandRunner` executes shell commands with async/timeout
- `core/registry.py`: `@register` decorator auto-registers providers
- `core/base.py`: `BaseEnvironmentProvider` abstract class
- `providers/`: PythonProvider, NodeProvider, DockerProvider, GitProvider
- `actions/`: Quick actions per environment (e.g., list pip packages)
- `ui/screens/`: Textual TUI screens (Dashboard + Detail views)

### Swift Version

- `Core/CommandRunner.swift`: `Process` + `Pipe` for shell commands (actor-based)
- `Providers/`: Same pattern as Python, with static properties for metadata
- `Services/EnvironmentService.swift`: Orchestrates parallel provider execution with `TaskGroup`
- `Views/PopoverView.swift`: Main menu bar popover UI

## Adding a New Provider

1. Create provider class implementing `BaseEnvironmentProvider` (Python) or `EnvironmentProvider` (Swift)
2. Add `@register` decorator (Python) or register in `ProviderRegistry.init()` (Swift)
3. Define `name`, `display_name`/`displayName`, `priority`
4. Implement `detect()`, `collect()`, `health_check()`/`healthCheck()`
5. Create corresponding Info model in `core/models.py` or `Models/`

## Git Workflow

- Push directly to the target branch unless explicitly asked to create a PR
- Never discard uncommitted changes without explicit confirmation