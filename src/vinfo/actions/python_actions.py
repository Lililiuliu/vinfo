import json
import asyncio
from vinfo.actions.base import ActionResult, BaseAction
from vinfo.core.models import PythonInfo


class ListVirtualEnvsAction(BaseAction):
    name = "list_venvs"
    description = "List all detected virtual environments"

    async def execute(self, runner, info: PythonInfo) -> ActionResult:
        if not info.virtualenvs:
            return ActionResult(success=True, message="No virtual environments found.", output="")

        lines = [f"{v['name']} ({v['python_version']}) at {v['path']}" for v in info.virtualenvs]
        return ActionResult(success=True, message="", output="\n".join(lines))


class ListPipPackagesAction(BaseAction):
    name = "list_pip"
    description = "List installed pip packages"

    async def execute(self, runner, info: PythonInfo) -> ActionResult:
        python_bin = info.path or "python3"
        result = await runner.run(f"{python_bin} -m pip list --format=json", timeout=30)
        if not result.success:
            return ActionResult(success=False, message=f"pip list failed: {result.stderr}", output=result.stderr)

        try:
            packages = json.loads(result.stdout)
            lines = [f"{p['name']} {p['version']}" for p in packages[:20]]
            total = len(packages)
            output = "\n".join(lines)
            if total > 20:
                output += f"\n... and {total - 20} more packages"
            return ActionResult(success=True, message=f"{total} packages installed", output=output)
        except json.JSONDecodeError:
            return ActionResult(success=False, message="Failed to parse pip list output", output=result.stdout)


class CheckPipOutdatedAction(BaseAction):
    name = "pip_outdated"
    description = "Check for outdated pip packages"

    async def execute(self, runner, info: PythonInfo) -> ActionResult:
        python_bin = info.path or "python3"
        result = await runner.run(f"{python_bin} -m pip list --outdated --format=json", timeout=30)
        if not result.success:
            return ActionResult(success=False, message=f"pip list --outdated failed: {result.stderr}", output=result.stderr)

        try:
            packages = json.loads(result.stdout)
            if not packages:
                return ActionResult(success=True, message="All packages are up to date", output="")
            lines = [f"{p['name']} {p['version']} -> {p['latest_version']}" for p in packages]
            return ActionResult(success=True, message=f"{len(packages)} packages have updates", output="\n".join(lines))
        except json.JSONDecodeError:
            return ActionResult(success=False, message="Failed to parse output", output=result.stdout)


class ShowSitePackagesAction(BaseAction):
    name = "site_packages"
    description = "Show site-packages directory"

    async def execute(self, runner, info: PythonInfo) -> ActionResult:
        python_bin = info.path or "python3"
        result = await runner.run(f"{python_bin} -c 'import site; print(site.getsitepackages()[0])'", timeout=5)
        if result.success:
            return ActionResult(success=True, message="", output=result.stdout)
        return ActionResult(success=False, message="Could not determine site-packages", output="")


def get_python_actions(info: PythonInfo) -> list[BaseAction]:
    return [
        ListVirtualEnvsAction(),
        ListPipPackagesAction(),
        CheckPipOutdatedAction(),
        ShowSitePackagesAction(),
    ]
