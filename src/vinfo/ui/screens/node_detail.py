from textual.app import ComposeResult
from textual.containers import Container, VerticalScroll
from textual.widgets import Static, TabbedContent, Tab

from vinfo.core.models import NodeInfo
from vinfo.ui.screens.detail import DetailScreen
from vinfo.actions.node_actions import get_node_actions


class NodeDetailScreen(DetailScreen):
    def compose(self) -> ComposeResult:
        yield from super().compose()
        yield TabbedContent(id="detail-tabs")

    def on_mount(self) -> None:
        info: NodeInfo = self._info
        tabs = self.query_one("#detail-tabs", TabbedContent)

        tabs.clear_panes()
        tabs.add_pane(Tab("Overview", self._build_overview(info)))
        tabs.add_pane(Tab("Actions", self._build_actions(info)))

    def _build_overview(self, info: NodeInfo) -> Container:
        rows = [
            ("Version", info.version or "Unknown"),
            ("Path", info.path or "N/A"),
            ("npm Version", info.npm_version or "N/A"),
        ]
        version_managers = []
        if info.nvm_installed:
            version_managers.append(f"nvm (current: {info.nvm_current})")
        if info.fnm_installed:
            version_managers.append("fnm")
        if info.volta_installed:
            version_managers.append("volta")
        if version_managers:
            rows.append(("Version Managers", ", ".join(version_managers)))

        container = Container()
        for key, value in rows:
            container.mount(Static(f"[bold][blue]{key}:[/]  {value}"))
        return container

    def _build_actions(self, info: NodeInfo) -> Container:
        container = VerticalScroll()
        container.mount(Static("[b]Actions:[/]"))

        actions = get_node_actions(info)
        for i, action in enumerate(actions, 1):
            danger_prefix = "[yellow]![/] " if action.dangerous else ""
            container.mount(Static(f"{i}. {danger_prefix}{action.description}"))
            container.mount(Static(f"   Command: [dim]{action.name}[/]", classes="action-cmd"))

        container.mount(Static("\n[dim]Actions execute on selection. Output shown below.[/]"))
        container.mount(Static("", id="action-output"))
        return container
