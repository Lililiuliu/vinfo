from textual.app import ComposeResult
from textual.containers import Container, VerticalScroll
from textual.widgets import Static, DataTable, TabbedContent, Tab, Button

from vinfo.core.models import PythonInfo
from vinfo.ui.screens.detail import DetailScreen
from vinfo.actions.python_actions import get_python_actions


class PythonDetailScreen(DetailScreen):
    def compose(self) -> ComposeResult:
        yield from super().compose()
        yield TabbedContent(id="detail-tabs")

    def on_mount(self) -> None:
        info: PythonInfo = self._info
        tabs = self.query_one("#detail-tabs", TabbedContent)

        tabs.clear_panes()
        tabs.add_pane(Tab("Overview", self._build_overview(info)))
        tabs.add_pane(Tab("Virtual Environments", self._build_venvs(info)))
        tabs.add_pane(Tab("Actions", self._build_actions(info)))

    def _build_overview(self, info: PythonInfo) -> Container:
        rows = [
            ("Version", info.version or "Unknown"),
            ("Interpreter", info.interpreter or "CPython"),
            ("Path", info.path or "N/A"),
            ("Platform", info.platform or "N/A"),
            ("Site-packages", info.site_packages_path or "N/A"),
            ("Pyenv", "Yes" if info.pyenv_installed else "No"),
        ]
        if info.pyenv_current:
            rows.append(("Pyenv Global", info.pyenv_current))
        if info.pyenv_versions:
            rows.append(("Pyenv Versions", f"{len(info.pyenv_versions)} installed"))

        container = Container()
        for key, value in rows:
            container.mount(Static(f"[bold][blue]{key}:[/]  {value}"))
        return container

    def _build_venvs(self, info: PythonInfo) -> Container:
        container = VerticalScroll()
        if not info.virtualenvs:
            container.mount(Static("No virtual environments found."))
            return container

        table = DataTable()
        table.add_columns("Name", "Python Version", "Path")
        for venv in info.virtualenvs:
            table.add_row(
                venv.get("name", ""),
                venv.get("python_version", ""),
                venv.get("path", ""),
            )
        container.mount(table)
        return container

    def _build_actions(self, info: PythonInfo) -> Container:
        container = VerticalScroll()
        container.mount(Static("[b]Actions:[/]"))

        actions = get_python_actions(info)
        for i, action in enumerate(actions, 1):
            danger_prefix = "[yellow]![/] " if action.dangerous else ""
            container.mount(Static(f"{i}. {danger_prefix}{action.description}"))
            container.mount(Static(f"   Command: [dim]{action.name}[/]", classes="action-cmd"))

        container.mount(Static("\n[dim]Actions execute on selection. Output shown below.[/]"))
        container.mount(Static("", id="action-output"))
        return container

    async def run_action(self, action_name: str) -> str:
        from vinfo.app import VinfoApp
        from vinfo.actions.python_actions import get_python_actions

        app = self.app
        runner = app.runner
        actions = get_python_actions(self._info)
        for action in actions:
            if action.name == action_name:
                result = await action.execute(runner, self._info)
                return result.output or result.message
        return "Action not found"
