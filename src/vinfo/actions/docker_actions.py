import re
from vinfo.actions.base import ActionResult, BaseAction
from vinfo.core.models import DockerInfo


class ListContainersAction(BaseAction):
    name = "list_containers"
    description = "List all containers (running and stopped)"

    async def execute(self, runner, info: DockerInfo) -> ActionResult:
        result = await runner.run("docker ps -a --format '{{.ID}}\\t{{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.Ports}}'", timeout=10)
        if not result.success:
            return ActionResult(success=False, message=f"docker ps failed: {result.stderr}", output=result.stderr)

        if not result.stdout:
            return ActionResult(success=True, message="No containers", output="")

        lines = ["ID           Name                 Image                 Status                Ports"]
        for line in result.stdout.splitlines():
            parts = line.split("\t")
            if len(parts) >= 4:
                lines.append(f"{parts[0][:12]:13} {parts[1][:20]:21} {parts[2][:20]:21} {parts[3][:20]:21} {parts[4] if len(parts) > 4 else ''}")
        return ActionResult(success=True, message=f"{len(result.stdout.splitlines())} containers", output="\n".join(lines))


class ListImagesAction(BaseAction):
    name = "list_images"
    description = "List all Docker images"

    async def execute(self, runner, info: DockerInfo) -> ActionResult:
        result = await runner.run("docker images --format '{{.Repository}}\\t{{.Tag}}\\t{{.Size}}\\t{{.ID}}'", timeout=10)
        if not result.success:
            return ActionResult(success=False, message=f"docker images failed: {result.stderr}", output=result.stderr)

        if not result.stdout:
            return ActionResult(success=True, message="No images", output="")

        lines = ["Repository             Tag       Size      ID"]
        for line in result.stdout.splitlines():
            parts = line.split("\t")
            if len(parts) >= 4:
                lines.append(f"{parts[0][:22]:23} {parts[1][:10]:11} {parts[2][:10]:11} {parts[3]}")
        return ActionResult(success=True, message=f"{len(result.stdout.splitlines())} images", output="\n".join(lines))


class DockerDiskUsageAction(BaseAction):
    name = "disk_usage"
    description = "Show Docker disk usage breakdown"

    async def execute(self, runner, info: DockerInfo) -> ActionResult:
        result = await runner.run("docker system df", timeout=10)
        if not result.success:
            return ActionResult(success=False, message=f"docker system df failed: {result.stderr}", output=result.stderr)
        return ActionResult(success=True, message="", output=result.stdout)


class PruneImagesAction(BaseAction):
    name = "prune_images"
    description = "Remove all dangling images"
    dangerous = True

    async def execute(self, runner, info: DockerInfo) -> ActionResult:
        result = await runner.run("docker image prune -f", timeout=30)
        if not result.success:
            return ActionResult(success=False, message=f"docker image prune failed: {result.stderr}", output=result.stderr)
        return ActionResult(success=True, message="Dangling images pruned", output=result.stdout)


class PruneVolumesAction(BaseAction):
    name = "prune_volumes"
    description = "Remove all unused volumes"
    dangerous = True

    async def execute(self, runner, info: DockerInfo) -> ActionResult:
        result = await runner.run("docker volume prune -f", timeout=30)
        if not result.success:
            return ActionResult(success=False, message=f"docker volume prune failed: {result.stderr}", output=result.stderr)
        return ActionResult(success=True, message="Unused volumes pruned", output=result.stdout)


class PruneAllAction(BaseAction):
    name = "prune_all"
    description = "Remove all unused containers, networks, and dangling images"
    dangerous = True

    async def execute(self, runner, info: DockerInfo) -> ActionResult:
        result = await runner.run("docker system prune -af", timeout=60)
        if not result.success:
            return ActionResult(success=False, message=f"docker system prune failed: {result.stderr}", output=result.stderr)
        return ActionResult(success=True, message="System prune complete", output=result.stdout)


def get_docker_actions(info: DockerInfo) -> list[BaseAction]:
    return [
        ListContainersAction(),
        ListImagesAction(),
        DockerDiskUsageAction(),
        PruneImagesAction(),
        PruneVolumesAction(),
        PruneAllAction(),
    ]
