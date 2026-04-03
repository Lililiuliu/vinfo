import os
import tomllib
from dataclasses import dataclass, field


@dataclass
class GeneralConfig:
    refresh_interval: int = 0
    startup_screen: str = "dashboard"
    theme: str = "dark"


@dataclass
class DashboardConfig:
    show_providers: list[str] = field(default_factory=list)
    sort_by: str = "priority"


@dataclass
class PythonConfig:
    python_path: str = ""
    scan_home_venvs: bool = True


@dataclass
class NodeConfig:
    node_path: str = ""


@dataclass
class DockerConfig:
    docker_host: str = ""
    disk_warning_threshold: int = 80


@dataclass
class GitConfig:
    warn_no_identity: bool = True


@dataclass
class AppConfig:
    general: GeneralConfig = field(default_factory=GeneralConfig)
    dashboard: DashboardConfig = field(default_factory=DashboardConfig)
    python: PythonConfig = field(default_factory=PythonConfig)
    node: NodeConfig = field(default_factory=NodeConfig)
    docker: DockerConfig = field(default_factory=DockerConfig)
    git: GitConfig = field(default_factory=GitConfig)


DEFAULT_CONFIG = AppConfig()


def _default_config_toml() -> str:
    return """[general]
refresh_interval = 0
startup_screen = "dashboard"
theme = "dark"

[dashboard]
show_providers = []
sort_by = "priority"

[python]
python_path = ""
scan_home_venvs = true

[node]
node_path = ""

[docker]
docker_host = ""
disk_warning_threshold = 80

[git]
warn_no_identity = true
"""


def load_config(config_dir: str) -> AppConfig:
    config_path = os.path.join(config_dir, "config.toml")
    if not os.path.exists(config_path):
        return DEFAULT_CONFIG

    with open(config_path, "rb") as f:
        data = tomllib.load(f)

    cfg = AppConfig()
    if "general" in data:
        g = data["general"]
        cfg.general.refresh_interval = g.get("refresh_interval", 0)
        cfg.general.startup_screen = g.get("startup_screen", "dashboard")
        cfg.general.theme = g.get("theme", "dark")

    if "dashboard" in data:
        d = data["dashboard"]
        cfg.dashboard.show_providers = d.get("show_providers", [])
        cfg.dashboard.sort_by = d.get("sort_by", "priority")

    if "python" in data:
        p = data["python"]
        cfg.python.python_path = p.get("python_path", "")
        cfg.python.scan_home_venvs = p.get("scan_home_venvs", True)

    if "node" in data:
        n = data["node"]
        cfg.node.node_path = n.get("node_path", "")

    if "docker" in data:
        d = data["docker"]
        cfg.docker.docker_host = d.get("docker_host", "")
        cfg.docker.disk_warning_threshold = d.get("disk_warning_threshold", 80)

    if "git" in data:
        g = data["git"]
        cfg.git.warn_no_identity = g.get("warn_no_identity", True)

    return cfg


def ensure_config_file(config_dir: str) -> str:
    os.makedirs(config_dir, exist_ok=True)
    config_path = os.path.join(config_dir, "config.toml")
    if not os.path.exists(config_path):
        with open(config_path, "w") as f:
            f.write(_default_config_toml())
    return config_path


def save_config(config_dir: str, cfg: AppConfig) -> None:
    ensure_config_file(config_dir)
    config_path = os.path.join(config_dir, "config.toml")

    lines = ["[general]\n"]
    lines.append(f'refresh_interval = {cfg.general.refresh_interval}\n')
    lines.append(f'startup_screen = "{cfg.general.startup_screen}"\n')
    lines.append(f'theme = "{cfg.general.theme}"\n\n')

    lines.append("[dashboard]\n")
    lines.append(f'show_providers = {cfg.dashboard.show_providers}\n')
    lines.append(f'sort_by = "{cfg.dashboard.sort_by}"\n\n')

    lines.append("[python]\n")
    lines.append(f'python_path = "{cfg.python.python_path}"\n')
    lines.append(f"scan_home_venvs = {str(cfg.python.scan_home_venvs).lower()}\n\n")

    lines.append("[node]\n")
    lines.append(f'node_path = "{cfg.node.node_path}"\n\n')

    lines.append("[docker]\n")
    lines.append(f'docker_host = "{cfg.docker.docker_host}"\n')
    lines.append(f"disk_warning_threshold = {cfg.docker.disk_warning_threshold}\n\n")

    lines.append("[git]\n")
    lines.append(f"warn_no_identity = {str(cfg.git.warn_no_identity).lower()}\n")

    with open(config_path, "w") as f:
        f.writelines(lines)
