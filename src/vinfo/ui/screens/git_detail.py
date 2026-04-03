from textual.app import ComposeResult
from textual.containers import Container, VerticalScroll
from textual.widgets import DataTable, Static, TabbedContent, Tab

from vinfo.core.models import GitInfo
from vinfo.ui.screens.detail import DetailScreen
from vinfo.actions.git_actions import get_git_actions


class GitDetailScreen(DetailScreen):
    def compose(self) -> ComposeResult:
        yield from super().compose()
        yield TabbedContent(id="detail-tabs")

    def on_mount(self) -> None:
        info: GitInfo = self._info
        tabs = self.query_one("#detail-tabs", TabbedContent)

        tabs.clear_panes()
        tabs.add_pane(Tab("Identity", self._build_identity(info)))
        tabs.add_pane(Tab("Repository", self._build_repo(info)))
        tabs.add_pane(Tab("Actions", self._build_actions(info)))

    def _build_identity(self, info: GitInfo) -> Container:
        rows = [
            ("Version", info.version or "Unknown"),
            ("Path", info.path or "N/A"),
            ("User Name", info.user_name or "[yellow]Not configured[/]"),
            ("User Email", info.user_email or "[yellow]Not configured[/]"),
            ("Signing Key", info.signing_key or "None"),
            ("Default Branch", info.default_branch or "main"),
            ("GitHub CLI", "Installed" if info.gh_installed else "Not installed"),
        ]
        if info.gh_version:
            rows.append(("gh Version", info.gh_version))
        if info.gh_auth_status:
            rows.append(("gh Auth", info.gh_auth_status))
        if info.gh_user:
            rows.append(("gh User", info.gh_user))

        container = Container()
        for key, value in rows:
            container.mount(Static(f"[bold][blue]{key}:[/]  {value}"))
        return container

    def _build_repo(self, info: GitInfo) -> Container:
        container = VerticalScroll()
        if not info.current_repo:
            container.mount(Static("Not inside a git repository."))
            return container

        container.mount(Static(f"[bold]Repository:[/] {info.current_repo}"))
        container.mount(Static(f"[bold]Branch:[/] {info.current_branch or 'unknown'}"))

        if info.remotes:
            table = DataTable()
            table.add_columns("Remote", "URL")
            for remote in info.remotes:
                table.add_row(remote.get("name", ""), remote.get("url", ""))
            container.mount(table)
        return container

    def _build_actions(self, info: GitInfo) -> Container:
        container = VerticalScroll()
        container.mount(Static("[b]Actions:[/]"))

        actions = get_git_actions(info)
        for i, action in enumerate(actions, 1):
            danger_prefix = "[yellow]![/] " if action.dangerous else ""
            container.mount(Static(f"{i}. {danger_prefix}{action.description}"))
            container.mount(Static(f"   Command: [dim]{action.name}[/]", classes="action-cmd"))

        container.mount(Static("\n[dim]Actions execute on selection. Output shown below.[/]"))
        container.mount(Static("", id="action-output"))
        return container
