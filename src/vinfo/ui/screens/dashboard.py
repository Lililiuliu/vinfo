import asyncio

from textual.app import ComposeResult
from textual.message import Message
from textual.screen import Screen
from textual.widgets import DataTable, Header, Footer, Static

from vinfo.constants import HealthStatus, STATUS_LABELS
from vinfo.core.models import EnvironmentInfo, PythonInfo, NodeInfo, DockerInfo, GitInfo
from vinfo.core.registry import get_all_providers
from vinfo.core.runner import CommandRunner
from vinfo.providers.git_provider import GH_AUTH_LOGGED_IN


class DashboardScreen(Screen):
    pass

    class EnvironmentSelected(Message):
        def __init__(self, info: EnvironmentInfo) -> None:
            super().__init__()
            self.info = info

    def __init__(self):
        super().__init__()
        self._infos: list[EnvironmentInfo] = []

    def compose(self) -> ComposeResult:
        yield Header(id="header")
        yield Static("Collecting environment data...", id="loading-text")
        yield DataTable(id="env-table")
        yield Footer(id="footer")

    def on_mount(self) -> None:
        table = self.query_one("#env-table", DataTable)
        table.add_columns(
            "Status",
            "Environment",
            "Version",
            "Details",
        )
        self.call_later(self._refresh_sync)

    def _refresh_sync(self) -> None:
        asyncio.create_task(self._do_refresh())

    async def _do_refresh(self) -> None:
        loading_text = self.query_one("#loading-text", Static)
        table = self.query_one("#env-table", DataTable)

        loading_text.update("Collecting environment data...")

        providers = get_all_providers()
        runner = CommandRunner()

        tasks = [self._collect_provider(p, runner) for p in providers]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        infos: list[EnvironmentInfo] = [r for r in results if not isinstance(r, Exception)]
        self._populate_table(infos)
        loading_text.update("")

    async def _collect_provider(self, provider_cls, runner):
        provider = provider_cls(runner)
        detected = await provider.detect()
        if not detected:
            info = EnvironmentInfo(
                name=provider.name,
                display_name=provider.display_name,
                status=HealthStatus.NOT_FOUND,
                version=None,
            )
            return info

        info = await provider.collect()
        status, msgs = await provider.health_check()
        if status != HealthStatus.UNKNOWN:
            info.status = status
        info.errors = msgs
        return info

    def _populate_table(self, infos: list[EnvironmentInfo]) -> None:
        table = self.query_one("#env-table", DataTable)
        table.clear()
        self._infos.clear()

        for info in infos:
            status_label = STATUS_LABELS.get(info.status, "??")

            details = self._get_quick_details(info)
            table.add_row(
                status_label,
                info.display_name,
                info.version or "N/A",
                details,
            )
            self._infos.append(info)

    def _get_quick_details(self, info: EnvironmentInfo) -> str:
        if isinstance(info, PythonInfo):
            parts = []
            if info.pyenv_installed:
                parts.append("pyenv")
            if info.virtualenvs:
                parts.append(f"{len(info.virtualenvs)} venvs")
            return ", ".join(parts) or "system"
        elif isinstance(info, NodeInfo):
            parts = []
            if info.nvm_installed:
                parts.append("nvm")
            elif info.fnm_installed:
                parts.append("fnm")
            elif info.volta_installed:
                parts.append("volta")
            if info.npm_version:
                parts.append(f"npm {info.npm_version}")
            return ", ".join(parts) or "system"
        elif isinstance(info, DockerInfo):
            parts = []
            if info.daemon_running:
                parts.append("running")
            if info.containers:
                parts.append(f"{len(info.containers)} containers")
            if info.images:
                parts.append(f"{len(info.images)} images")
            return ", ".join(parts) or "stopped"
        elif isinstance(info, GitInfo):
            parts = []
            if info.gh_installed:
                parts.append("gh")
                if info.gh_auth_status == GH_AUTH_LOGGED_IN:
                    parts.append("authed")
            if info.current_repo:
                parts.append(f"repo: {info.current_repo.split('/')[-1]}")
            return ", ".join(parts) or "no repo"
        return ""

    def on_data_table_row_selected(self, event: DataTable.RowSelected) -> None:
        info = self._infos[event.cursor_row] if event.cursor_row < len(self._infos) else None
        if info and not isinstance(info, Exception):
            self.post_message(self.EnvironmentSelected(info))

    def on_refresh_request(self) -> None:
        self.run_worker(self._do_refresh())
