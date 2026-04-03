import asyncio
import os
from vinfo.constants import HealthStatus
from vinfo.core.base import BaseEnvironmentProvider
from vinfo.core.models import EnvironmentInfo, PythonInfo
from vinfo.core.registry import register
from vinfo.core.runner import CommandRunner


@register
class PythonProvider(BaseEnvironmentProvider):
    name = "python"
    display_name = "Python"
    icon = "\U0001f40d"
    priority = 10

    def __init__(self, runner: CommandRunner):
        self._runner = runner

    async def detect(self) -> bool:
        return self._runner.which("python3") is not None or self._runner.which("python") is not None

    async def collect(self) -> PythonInfo:
        python_bin = self._runner.which("python3") or self._runner.which("python") or ""

        # Run version, platform, site-packages, pip version in parallel
        ver_task = self._runner.run(f"{python_bin} --version 2>&1")
        plat_task = self._runner.run(f"{python_bin} -c 'import platform; print(platform.platform())'")
        site_task = self._runner.run(
            f"{python_bin} -c 'import site; print(site.getsitepackages()[0] if site.getsitepackages() else site.getusersitepackages())'"
        )
        pip_task = self._runner.run(f"{python_bin} -m pip --version 2>&1")
        ver_res, plat_res, site_res, pip_res = await asyncio.gather(ver_task, plat_task, site_task, pip_task)

        version = ver_res.stdout.replace("Python ", "").strip() if ver_res.success else "Unknown"

        # Parse pip version: "pip 25.1 from /path/to/pip (python 3.12)"
        pip_version = None
        if pip_res.success:
            first_word = pip_res.stdout.split()[1] if pip_res.stdout.split() else None
            pip_version = first_word

        info = PythonInfo(
            name=self.name,
            display_name=f"Python {version}",
            status=HealthStatus.HEALTHY,
            version=version,
            path=python_bin,
            interpreter="CPython",
            platform=plat_res.stdout if plat_res.success else None,
            site_packages_path=site_res.stdout if site_res.success else None,
            pip_version=pip_version,
        )

        pyenv_bin = self._runner.which("pyenv")
        if pyenv_bin:
            info.pyenv_installed = True
            ver_task = self._runner.run("pyenv versions --bare")
            curr_task = self._runner.run("pyenv global 2>/dev/null || true")
            ver_res, curr_res = await asyncio.gather(ver_task, curr_task)
            if ver_res.success:
                info.pyenv_versions = ver_res.stdout.splitlines()
            info.pyenv_current = curr_res.stdout.strip() if curr_res.success else None

        venv_dirs = await self._find_virtualenvs()
        info.virtualenvs = venv_dirs

        return info

    async def _find_virtualenvs(self) -> list[dict]:
        venvs = []
        home = os.path.expanduser("~")
        search_paths = [
            os.path.join(home, "virtualenvs"),
            os.path.join(home, ".local", "share", "virtualenvs"),
        ]

        # Discover venvs first
        candidates = []
        for base in search_paths:
            if os.path.isdir(base):
                for name in os.listdir(base):
                    vpath = os.path.join(base, name)
                    if os.path.isdir(vpath) and os.path.exists(os.path.join(vpath, "bin", "python")):
                        candidates.append((name, vpath))

        cwd_venv = os.path.join(os.getcwd(), ".venv")
        if os.path.exists(os.path.join(cwd_venv, "bin", "python")):
            candidates.append((".venv (cwd)", cwd_venv))

        # Query all venv Python versions in parallel
        if candidates:
            async def get_ver(name: str, vpath: str) -> dict:
                res = await self._runner.run(f"{vpath}/bin/python --version 2>&1")
                py_ver = res.stdout.replace("Python ", "").strip() if res.success else "unknown"
                return {"name": name, "path": vpath, "python_version": py_ver}

            results = await asyncio.gather(*[get_ver(n, p) for n, p in candidates])
            venvs = list(results)

        return venvs

    async def health_check(self) -> tuple[HealthStatus, list[str]]:
        messages = []
        status = HealthStatus.HEALTHY

        if self._runner.which("pip") is None and self._runner.which("pip3") is None:
            status = HealthStatus.WARNING
            messages.append("pip not found in PATH")

        return status, messages

    def get_quick_actions(self) -> list[dict]:
        return [
            {"id": "list_venvs", "label": "List VirtualEnvs", "description": "Show all detected virtual environments", "dangerous": False},
            {"id": "pip_packages", "label": "List pip packages", "description": "Show top installed pip packages", "dangerous": False},
        ]
