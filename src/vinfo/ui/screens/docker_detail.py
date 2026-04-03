from textual.app import ComposeResult
from textual.containers import Container, VerticalScroll
from textual.widgets import DataTable, Static, TabbedContent, Tab

from vinfo.core.models import DockerInfo
from vinfo.ui.screens.detail import DetailScreen
from vinfo.actions.docker_actions import get_docker_actions


class DockerDetailScreen(DetailScreen):
    def compose(self) -> ComposeResult:
        yield from super().compose()
        yield TabbedContent(id="detail-tabs")

    def on_mount(self) -> None:
        info: DockerInfo = self._info
        tabs = self.query_one("#detail-tabs", TabbedContent)

        tabs.clear_panes()
        tabs.add_pane(Tab("Overview", self._build_overview(info)))
        tabs.add_pane(Tab("Containers", self._build_containers(info)))
        tabs.add_pane(Tab("Images", self._build_images(info)))
        tabs.add_pane(Tab("Actions", self._build_actions(info)))

    def _build_overview(self, info: DockerInfo) -> Container:
        rows = [
            ("Version", info.version or "Unknown"),
            ("Daemon", "Running" if info.daemon_running else "Stopped"),
            ("Context", info.context_name or "default"),
        ]
        if info.compose_version:
            rows.append(("Docker Compose", info.compose_version))

        container = Container()
        for key, value in rows:
            container.mount(Static(f"[bold][blue]{key}:[/]  {value}"))
        return container

    def _build_containers(self, info: DockerInfo) -> Container:
        container = VerticalScroll()
        if not info.containers:
            container.mount(Static("No containers found."))
            return container

        table = DataTable()
        table.add_columns("Name", "Image", "Status")
        for c in info.containers:
            table.add_row(c.get("name", ""), c.get("image", ""), c.get("status", ""))
        container.mount(table)
        return container

    def _build_images(self, info: DockerInfo) -> Container:
        container = VerticalScroll()
        if not info.images:
            container.mount(Static("No images found."))
            return container

        table = DataTable()
        table.add_columns("Repository", "Tag", "Size", "ID")
        for img in info.images:
            table.add_row(
                img.get("repository", ""),
                img.get("tag", ""),
                img.get("size", ""),
                img.get("id", ""),
            )
        container.mount(table)
        return container

    def _build_actions(self, info: DockerInfo) -> Container:
        container = VerticalScroll()
        container.mount(Static("[b]Actions:[/]"))

        actions = get_docker_actions(info)
        for i, action in enumerate(actions, 1):
            danger_prefix = "[yellow]![/] " if action.dangerous else ""
            container.mount(Static(f"{i}. {danger_prefix}{action.description}"))
            container.mount(Static(f"   Command: [dim]{action.name}[/]", classes="action-cmd"))

        container.mount(Static("\n[dim]Actions execute on selection. Output shown below.[/]"))
        container.mount(Static("", id="action-output"))
        return container
