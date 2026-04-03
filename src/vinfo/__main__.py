import asyncio
import typer
from rich.console import Console
from rich.text import Text
from rich.table import Table

import vinfo.providers  # noqa: F401
import vinfo
from vinfo.constants import STATUS_LABELS
from vinfo.core.registry import get_all_providers
from vinfo.core.runner import CommandRunner
from vinfo.core.models import PythonInfo, NodeInfo, DockerInfo, GitInfo
from vinfo.providers.git_provider import GH_AUTH_LOGGED_IN

app = typer.Typer(add_completion=False)
console = Console()




async def get_all_infos() -> dict:
    runner = CommandRunner()
    providers = get_all_providers()
    results = {}

    async def collect(p_cls):
        p = p_cls(runner)
        detected = await p.detect()
        if detected:
            info = await p.collect()
            status, msgs = await p.health_check()
            if status.value != "unknown":
                info.status = status
            info.errors = msgs
            return p.name, info
        return p.name, None

    gathered = await asyncio.gather(*[collect(p) for p in providers], return_exceptions=True)
    for item in gathered:
        if isinstance(item, Exception):
            continue
        name, info = item
        results[name] = info
    return results


@app.command()
def dashboard():
    """显示所有环境概览"""
    infos = asyncio.run(get_all_infos())

    table = Table(title="[b]开发环境状态[/b]", show_header=True, header_style="bold cyan")
    table.add_column("Status", style="bold", width=8)
    table.add_column("Environment", style="bold blue", width=15)
    table.add_column("Version", style="green", width=20)
    table.add_column("Details", style="dim")

    for name, info in infos.items():
        if info is None:
            continue
        status = STATUS_LABELS.get(info.status, "??")
        details = _quick_details(info)
        table.add_row(status, info.display_name, info.version or "N/A", details)

    logo = (
        "__     _____        __       \n"
        "\\ \\   / /_ _|_ __  / _| ___  \n"
        " \\ \\ / / | || '_ \\| |_ / _ \\ \n"
        "  \\ V /  | || | | |  _| (_) |\n"
        "   \\_/  |___|_| |_|_|  \\___/ \n"
    )
    console.print(Text(logo, style="cyan bold", justify="left"))
    console.print(f"[dim]v{vinfo.__version__}[/dim]")
    console.print()
    console.print(table)
    console.print("\n[dim]查看详情: vinfo python | vinfo node | vinfo docker | vinfo git[/dim]")


def _quick_details(info):
    if isinstance(info, PythonInfo):
        if info.pyenv_installed:
            vm = f"Pyenv"
            if info.virtualenvs:
                return f"{vm}, {len(info.virtualenvs)} 个虚拟环境, pip {info.pip_version or '?'}"
            return f"{vm}, pip {info.pip_version or '?'}"
        return f"系统自带, pip {info.pip_version or '?'}"
    elif isinstance(info, NodeInfo):
        parts = []
        if info.nvm_installed:
            parts.append("nvm")
        elif info.fnm_installed:
            parts.append("fnm")
        elif info.volta_installed:
            parts.append("volta")
        if info.npm_version:
            parts.append(f"npm {info.npm_version}")
        return ", ".join(parts) or "system"
    elif isinstance(info, DockerInfo):
        if info.daemon_running:
            return "正常运行中"
        return "[yellow]未运行[/yellow]"
    elif isinstance(info, GitInfo):
        if info.gh_installed and info.gh_auth_status == GH_AUTH_LOGGED_IN:
            return f"GitHub CLI 已登录 ({info.gh_user or ''})"
        return "GitHub CLI 未登录"
    return ""


@app.command()
def python():
    """Python 环境详情"""
    runner = CommandRunner()

    async def collect():
        from vinfo.providers.python_provider import PythonProvider
        p = PythonProvider(runner)
        if not await p.detect():
            console.print("[red]Python 未安装[/red]")
            return
        info = await p.collect()
        status, msgs = await p.health_check()
        if status.value != "unknown":
            info.status = status
        info.errors = msgs
        return info

    info = asyncio.run(collect())
    if not info:
        return

    from rich.panel import Panel
    from rich.text import Text

    # 从路径中提取实际版本名
    path_version = ""
    if info.path:
        import re
        m = re.search(r'/versions/([^/]+)/bin/python', info.path)
        if m:
            path_version = m.group(1)

    title = f"Python {path_version or info.version}"
    if info.pyenv_installed:
        subtitle = f"由 Pyenv 管理"
    elif "brew" in (info.path or ""):
        subtitle = "由 Homebrew 安装"
    else:
        subtitle = "系统自带"

    console.print(Panel(Text.from_markup(f"{title}  pip: [dim]{info.pip_version or '?'}[/dim]"), title=subtitle, border_style="blue"))

    # 已安装的虚拟环境
    if info.pyenv_versions:
        installed = [v for v in info.pyenv_versions if v != "system"]
        current_path = info.path or ""
        lines = []
        for v in installed:
            marker = "  ← 当前使用" if current_path.endswith(f"versions/{v}/bin/python") or current_path.endswith(f"versions/{v}/bin/python3") else ""
            lines.append(f"  {v}{marker}")
        console.print(f"\n[bold]已安装的 Python 版本:[/bold]")
        console.print("\n".join(lines) if lines else "  无额外版本")

    # 虚拟环境
    if info.virtualenvs:
        console.print(f"\n[bold]虚拟环境 ({len(info.virtualenvs)} 个):[/bold]")
        console.print("[dim]虚拟环境是独立的 Python 运行环境，互不影响[/dim]")
        venv_table = Table(show_header=True)
        venv_table.add_column("名称", style="cyan")
        venv_table.add_column("版本", style="green")
        for v in info.virtualenvs:
            venv_table.add_row(v["name"], v.get("python_version", ""))
        console.print(venv_table)

    # pip 包
    pip_res = asyncio.run(runner.run(f"{info.path or 'python3'} -m pip list --format=json", timeout=15))
    if pip_res.success:
        try:
            import json
            packages = json.loads(pip_res.stdout)
            total = len(packages)
            console.print(f"\n[bold]已安装的 pip 包 ({total} 个):[/bold]")
            if total > 0:
                pkg_table = Table(show_header=True)
                pkg_table.add_column("包名", style="cyan")
                pkg_table.add_column("版本", style="green")
                for pkg in packages:
                    pkg_table.add_row(pkg.get("name", ""), pkg.get("version", ""))
                console.print(pkg_table)
        except Exception:
            pass

    # 建议
    if info.pyenv_versions and len(info.pyenv_versions) > 3:
        console.print()
        console.print("[yellow]提示:[/yellow] 发现多个 Python 版本，当前使用 [green]{}[/green]。可通过 [cyan]pyenv local 版本号[/cyan] 切换。".format(path_version or info.version))

    if info.errors:
        for e in info.errors:
            console.print(f"[yellow]警告:[/yellow] {e}")


@app.command()
def node():
    """Node.js 环境详情"""
    runner = CommandRunner()

    async def collect():
        from vinfo.providers.node_provider import NodeProvider
        p = NodeProvider(runner)
        if not await p.detect():
            console.print("[red]Node.js 未安装[/red]")
            return
        return await p.collect()

    info = asyncio.run(collect())
    if not info:
        return

    from rich.panel import Panel

    subtitle = None
    if info.nvm_installed:
        subtitle = f"由 NVM 管理 (当前: {info.nvm_current or info.version})"
    elif info.fnm_installed:
        subtitle = "由 FNM 管理"
    elif info.volta_installed:
        subtitle = "由 Volta 管理"
    else:
        subtitle = "系统安装"

    console.print(Panel(f"[green]v{info.version}[/green]  npm: v{info.npm_version or '?'}", title=subtitle, border_style="green"))

    if info.nvm_versions:
        installed = [v for v in info.nvm_versions if v.strip()]
        console.print(f"\n[bold]NVM 已安装版本 ({len(installed)} 个):[/bold]")
        current = info.nvm_current or ""
        for v in installed[:10]:
            marker = "  ← 当前使用" if v == current else ""
            console.print(f"  {v}{marker}")
        if len(installed) > 10:
            console.print(f"  ... 还有 {len(installed) - 10} 个版本")


@app.command()
def docker():
    """Docker 环境详情"""
    runner = CommandRunner()

    async def collect():
        from vinfo.providers.docker_provider import DockerProvider
        p = DockerProvider(runner)
        if not await p.detect():
            console.print("[red]Docker 未安装[/red]")
            return
        return await p.collect()

    info = asyncio.run(collect())
    if not info:
        return

    daemon_status = "[green]✓ 运行中[/green]" if info.daemon_running else "[yellow]✘ 未运行[/yellow]"
    from rich.panel import Panel
    overview = (
        f"[bold]版本:[/bold] {info.version or 'N/A'}\n"
        f"[bold]状态:[/bold] {daemon_status}"
    )
    console.print(Panel(overview, title="Docker", border_style="green" if info.daemon_running else "yellow"))

    if not info.daemon_running:
        console.print("\n[yellow]提示:[/yellow] Docker 未运行。启动 Docker Desktop 后重试。")
        return

    if info.containers:
        console.print(f"\n[bold]容器 ({len(info.containers)} 个):[/bold]")
        ct = Table(show_header=True)
        ct.add_column("名称", style="cyan")
        ct.add_column("镜像", style="green")
        ct.add_column("状态", style="white")
        for c in info.containers:
            ct.add_row(c.get("name", ""), c.get("image", ""), c.get("status", ""))
        console.print(ct)

    if info.images:
        console.print(f"\n[bold]镜像 ({len(info.images)} 个):[/bold]")
        it = Table(show_header=True)
        it.add_column("仓库", style="cyan")
        it.add_column("标签", style="green")
        it.add_column("大小", style="white")
        for img in info.images:
            it.add_row(img.get("repository", ""), img.get("tag", ""), img.get("size", ""))
        console.print(it)


@app.command()
def git():
    """Git / GitHub CLI 详情"""
    runner = CommandRunner()

    async def collect():
        from vinfo.providers.git_provider import GitProvider
        p = GitProvider(runner)
        if not await p.detect():
            console.print("[red]Git 未安装[/red]")
            return
        return await p.collect()

    info = asyncio.run(collect())
    if not info:
        return

    from rich.panel import Panel

    # 用户身份
    identity_ok = bool(info.user_name and info.user_email)
    identity_panel = (
        f"[green]用户名:[/green] {info.user_name}\n"
        f"[green]邮箱:[/green] {info.user_email}"
        if identity_ok else
        "[yellow]未配置用户名和邮箱[/yellow]\n"
        "[dim]提交代码前需要先配置: git config --global user.name \"你的名字\"[/dim]"
    )
    console.print(Panel(identity_panel, title="Git 身份信息", border_style="blue" if identity_ok else "yellow"))

    # GitHub CLI
    if info.gh_installed:
        gh_ok = info.gh_auth_status == GH_AUTH_LOGGED_IN
        gh_panel = (
            f"[green]已登录:[/green] {info.gh_user or ''}\n"
            f"[dim]版本:[/dim] {info.gh_version or 'N/A'}"
        ) if gh_ok else (
            "[yellow]未登录 GitHub[/yellow]\n"
            "[dim]运行: gh auth login[/dim]"
        )
        console.print(Panel(gh_panel, title="GitHub CLI", border_style="green" if gh_ok else "yellow"))

    # 当前仓库
    if info.current_repo:
        repo_name = info.current_repo.split("/")[-1]
        console.print(f"\n[bold]当前仓库:[/bold] [cyan]{repo_name}[/cyan]")
        console.print(f"[dim]路径:[/dim] {info.current_repo}")
        console.print(f"[dim]分支:[/dim] {info.current_branch or 'N/A'}")
        if info.remotes:
            for r in info.remotes:
                console.print(f"[dim]远程:[/dim] {r['name']} → {r['url']}")


def main():
    import sys
    if len(sys.argv) == 1:
        dashboard()
    else:
        app()
