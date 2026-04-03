import os

from textual.app import App, ComposeResult
from textual.containers import Container
from textual.message import Message
from textual.widgets import Static

import vinfo.providers  # noqa: F401 - triggers @register decorators
from vinfo.config import ensure_config_file, load_config
from vinfo.core.detector import detect_platform
from vinfo.core.runner import CommandRunner
from vinfo.core.models import PythonInfo, NodeInfo, DockerInfo, GitInfo
from vinfo.ui.screens.dashboard import DashboardScreen
from vinfo.ui.screens.python_detail import PythonDetailScreen
from vinfo.ui.screens.node_detail import NodeDetailScreen
from vinfo.ui.screens.docker_detail import DockerDetailScreen
from vinfo.ui.screens.git_detail import GitDetailScreen


def _css_path() -> str:
    return os.path.join(os.path.dirname(__file__), "ui", "theme.css")


class VinfoApp(App):
    TITLE = "vinfo -- Development Environment Inspector"
    SUB_TITLE = "Press ? for help | q to quit | Enter for details"
    CSS_PATH = _css_path()

    BINDINGS = [
        ("q", "quit", "Quit"),
        ("d", "go_dashboard", "Dashboard"),
        ("?", "toggle_help", "Help"),
        ("r", "refresh", "Refresh"),
    ]

    def __init__(self):
        super().__init__()
        self._platform = detect_platform()
        self._config_dir = ensure_config_file(self._platform.config_dir)
        self._config = load_config(self._config_dir)
        self._runner = CommandRunner()
        self._help_visible = False

    @property
    def runner(self) -> CommandRunner:
        return self._runner

    @property
    def config(self):
        return self._config

    @property
    def platform(self):
        return self._platform

    def compose(self) -> ComposeResult:
        yield DashboardScreen()
        yield Container(
            Static(self._help_text(), id="help-panel"),
            id="help-overlay",
        )

    def _help_text(self) -> str:
        return """[bold]Keyboard Shortcuts[/bold]

[cyan]q[/cyan]  Quit
[cyan]d[/cyan]  Go to Dashboard
[cyan]?[/cyan]  Toggle this help
[cyan]r[/cyan]  Refresh data

[bold]Dashboard[/bold]
[cyan]Up/Down[/cyan]  Navigate environments
[cyan]Enter[/cyan]  Open environment details
[cyan]Esc[/cyan]   Go back / Close panel

[bold]Details[/bold]
[cyan]Tab[/cyan]  Switch tabs
[cyan]1-9[/cyan]  Execute action
"""

    def toggle_help(self) -> None:
        overlay = self.query_one("#help-overlay")
        self._help_visible = not self._help_visible
        overlay.display = self._help_visible

    def on_dashboard_environment_selected(self, event) -> None:
        info = event.info
        if isinstance(info, PythonInfo):
            self.push_screen(PythonDetailScreen(info))
        elif isinstance(info, NodeInfo):
            self.push_screen(NodeDetailScreen(info))
        elif isinstance(info, DockerInfo):
            self.push_screen(DockerDetailScreen(info))
        elif isinstance(info, GitInfo):
            self.push_screen(GitDetailScreen(info))

    def action_go_dashboard(self):
        self.pop_screen()

    def action_refresh(self):
        self.post_message(RefreshRequest())


class RefreshRequest(Message):
    pass
