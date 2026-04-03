import asyncio
import os
from vinfo.constants import HealthStatus
from vinfo.core.base import BaseEnvironmentProvider
from vinfo.core.models import EnvironmentInfo, NodeInfo
from vinfo.core.registry import register
from vinfo.core.runner import CommandRunner


@register
class NodeProvider(BaseEnvironmentProvider):
    name = "node"
    display_name = "Node.js"
    icon = "\U0001f4bb"
    priority = 20

    def __init__(self, runner: CommandRunner):
        self._runner = runner

    async def detect(self) -> bool:
        return self._runner.which("node") is not None

    async def collect(self) -> NodeInfo:
        node_bin = self._runner.which("node") or ""
        npm_bin = self._runner.which("npm")

        node_ver, fnm_check, volta_check = await asyncio.gather(
            self._runner.run(f"{node_bin} --version 2>&1"),
            asyncio.to_thread(self._runner.which, "fnm"),
            asyncio.to_thread(self._runner.which, "volta"),
        )

        version = node_ver.stdout.strip().lstrip("v") if node_ver.success else "Unknown"
        npm_ver = None
        if npm_bin:
            npm_res = await self._runner.run(f"{npm_bin} --version 2>&1")
            npm_ver = npm_res.stdout if npm_res.success else None

        info = NodeInfo(
            name=self.name,
            display_name=f"Node.js {version}",
            status=HealthStatus.HEALTHY,
            version=version,
            path=node_bin,
            npm_version=npm_ver,
        )

        nvm_dir = os.environ.get("NVM_DIR", os.path.expanduser("~/.nvm"))
        if os.path.isdir(nvm_dir):
            info.nvm_installed = True
            # 直接从目录读取已安装版本，比 nvm list 更可靠
            nvm_list_res = await asyncio.gather(
                asyncio.to_thread(_list_nvm_versions, nvm_dir),
                self._runner.run(f'. "{nvm_dir}/nvm.sh" 2>/dev/null && nvm current 2>&1 || true'),
            )
            info.nvm_versions = nvm_list_res[0]
            info.nvm_current = nvm_list_res[1].stdout.strip() if nvm_list_res[1].success else None

        if fnm_check:
            info.fnm_installed = True
        if volta_check:
            info.volta_installed = True

        return info

    async def health_check(self) -> tuple[HealthStatus, list[str]]:
        return HealthStatus.HEALTHY, []

    def get_quick_actions(self) -> list[dict]:
        return [
            {"id": "list_global_pkgs", "label": "List global packages", "description": "Show globally installed npm packages", "dangerous": False},
            {"id": "npm_version_check", "label": "Check npm version", "description": "Compare local vs latest npm version", "dangerous": False},
        ]


def _list_nvm_versions(nvm_dir: str) -> list[str]:
    """List installed Node versions from nvm directory."""
    versions = []
    node_dir = os.path.join(nvm_dir, "versions", "node")
    if os.path.isdir(node_dir):
        for name in sorted(os.listdir(node_dir)):
            vpath = os.path.join(node_dir, name)
            if os.path.isdir(vpath) and os.path.exists(os.path.join(vpath, "bin", "node")):
                versions.append(name)
    return versions
