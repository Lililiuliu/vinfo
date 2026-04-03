import json
from vinfo.actions.base import ActionResult, BaseAction
from vinfo.core.models import NodeInfo


class ListGlobalPackagesAction(BaseAction):
    name = "list_global"
    description = "List globally installed npm packages"

    async def execute(self, runner, info: NodeInfo) -> ActionResult:
        result = await runner.run("npm list -g --depth=0 --json", timeout=30)
        if not result.success:
            return ActionResult(success=False, message=f"npm list -g failed: {result.stderr}", output=result.stderr)

        try:
            data = json.loads(result.stdout)
            dependencies = data.get("dependencies", {})
            lines = [f"{name} {pkg['version']}" for name, pkg in list(dependencies.items())[:20]]
            total = len(dependencies)
            output = "\n".join(lines)
            if total > 20:
                output += f"\n... and {total - 20} more"
            return ActionResult(success=True, message=f"{total} global packages", output=output)
        except json.JSONDecodeError:
            return ActionResult(success=False, message="Failed to parse npm output", output=result.stdout)


class NpmOutdatedAction(BaseAction):
    name = "npm_outdated"
    description = "Check for outdated global packages"

    async def execute(self, runner, info: NodeInfo) -> ActionResult:
        result = await runner.run("npm outdated -g --json 2>&1 || true", timeout=30)
        try:
            data = json.loads(result.stdout)
            if not data:
                return ActionResult(success=True, message="All global packages are up to date", output="")
            lines = [f"{name}: current={pkg['current']} latest={pkg['latest']}" for name, pkg in data.items()]
            return ActionResult(success=True, message=f"{len(data)} packages have updates", output="\n".join(lines))
        except json.JSONDecodeError:
            return ActionResult(success=True, message="", output=result.stdout)


class ShowNodePathAction(BaseAction):
    name = "node_path"
    description = "Show Node.js binary path"

    async def execute(self, runner, info: NodeInfo) -> ActionResult:
        node_path = info.path or runner.which("node") or "not found"
        return ActionResult(success=True, message="", output=node_path)


class ShowNpmPrefixAction(BaseAction):
    name = "npm_prefix"
    description = "Show global npm modules directory"

    async def execute(self, runner, info: NodeInfo) -> ActionResult:
        result = await runner.run("npm prefix -g", timeout=5)
        if result.success:
            return ActionResult(success=True, message="", output=result.stdout)
        return ActionResult(success=False, message="Could not determine npm prefix", output="")


def get_node_actions(info: NodeInfo) -> list[BaseAction]:
    return [
        ListGlobalPackagesAction(),
        NpmOutdatedAction(),
        ShowNodePathAction(),
        ShowNpmPrefixAction(),
    ]
