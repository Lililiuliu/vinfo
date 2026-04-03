import asyncio
from vinfo.constants import HealthStatus
from vinfo.core.base import BaseEnvironmentProvider
from vinfo.core.models import DockerInfo, EnvironmentInfo
from vinfo.core.registry import register
from vinfo.core.runner import CommandRunner


@register
class DockerProvider(BaseEnvironmentProvider):
    name = "docker"
    display_name = "Docker"
    icon = "\U0001f30a"
    priority = 40

    def __init__(self, runner: CommandRunner):
        self._runner = runner

    async def detect(self) -> bool:
        return self._runner.which("docker") is not None

    async def collect(self) -> DockerInfo:
        docker_bin = self._runner.which("docker") or ""
        docker_ver = await self._runner.run(f"{docker_bin} --version 2>&1")
        version = docker_ver.stdout.replace("Docker version ", "").split(",")[0].strip() if docker_ver.success else "Unknown"

        info = DockerInfo(
            name=self.name,
            display_name=f"Docker {version}",
            status=HealthStatus.UNKNOWN,
            version=version,
            path=docker_bin,
        )

        daemon_check = await self._runner.run(
            f"{docker_bin} info --format '{{{{.ServerVersion}}}}' 2>&1", timeout=5
        )
        if daemon_check.success:
            info.daemon_running = True
            info.status = HealthStatus.HEALTHY
        else:
            info.daemon_running = False
            info.status = HealthStatus.WARNING
            info.errors.append("Docker daemon is not running")

        if info.daemon_running:
            containers_res, images_res, volumes_res = await asyncio.gather(
                self._runner.run(f"{docker_bin} ps -a --format '{{{{.ID}}}}\\t{{{{.Names}}}}\\t{{{{.Image}}}}\\t{{{{.Status}}}}' 2>&1"),
                self._runner.run(f"{docker_bin} images --format '{{{{.ID}}}}\\t{{{{.Repository}}}}\\t{{{{.Tag}}}}\\t{{{{.Size}}}}' 2>&1"),
                self._runner.run(f"{docker_bin} volume ls --format '{{{{.Name}}}}\\t{{{{.Driver}}}}' 2>&1"),
            )

            if containers_res.success:
                info.containers = []
                for line in containers_res.stdout.splitlines():
                    parts = line.split("\t")
                    if len(parts) >= 4:
                        info.containers.append({
                            "id": parts[0],
                            "name": parts[1],
                            "image": parts[2],
                            "status": parts[3],
                        })

            if images_res.success:
                info.images = []
                for line in images_res.stdout.splitlines():
                    parts = line.split("\t")
                    if len(parts) >= 4:
                        info.images.append({
                            "id": parts[0],
                            "repository": parts[1],
                            "tag": parts[2],
                            "size": parts[3],
                        })

            if volumes_res.success:
                info.volumes = []
                for line in volumes_res.stdout.splitlines():
                    parts = line.split("\t")
                    if len(parts) >= 2:
                        info.volumes.append({"name": parts[0], "driver": parts[1]})

        compose_res, context_res = await asyncio.gather(
            self._runner.run(f"{docker_bin} compose version 2>&1"),
            self._runner.run(f"{docker_bin} context show 2>&1"),
        )
        if compose_res.success:
            first_line = compose_res.stdout.splitlines()[0] if compose_res.stdout else ""
            info.compose_version = first_line.strip() or None
        if context_res.success:
            info.context_name = context_res.stdout.strip()

        return info

    async def health_check(self) -> tuple[HealthStatus, list[str]]:
        if not self._runner.which("docker"):
            return HealthStatus.NOT_FOUND, ["Docker is not installed"]
        return HealthStatus.HEALTHY, []

    def get_quick_actions(self) -> list[dict]:
        return [
            {"id": "prune_images", "label": "Prune dangling images", "description": "Remove unused dangling images", "dangerous": True},
            {"id": "prune_volumes", "label": "Prune unused volumes", "description": "Remove unused volumes", "dangerous": True},
            {"id": "list_containers", "label": "List all containers", "description": "Show all containers (running + stopped)", "dangerous": False},
        ]
