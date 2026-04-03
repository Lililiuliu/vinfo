from dataclasses import dataclass, field
from typing import Optional

from vinfo.constants import HealthStatus


@dataclass
class EnvironmentInfo:
    name: str
    display_name: str
    status: HealthStatus
    version: Optional[str] = None
    path: Optional[str] = None
    details: dict = field(default_factory=dict)
    errors: list[str] = field(default_factory=list)
    actions_available: list[str] = field(default_factory=list)


@dataclass
class PythonInfo(EnvironmentInfo):
    pyenv_installed: bool = False
    pyenv_versions: list[str] = field(default_factory=list)
    pyenv_current: Optional[str] = None
    virtualenvs: list[dict] = field(default_factory=list)
    pip_packages: list[dict] = field(default_factory=list)
    pip_version: Optional[str] = None
    site_packages_path: Optional[str] = None
    interpreter: Optional[str] = None
    platform: Optional[str] = None


@dataclass
class NodeInfo(EnvironmentInfo):
    nvm_installed: bool = False
    fnm_installed: bool = False
    volta_installed: bool = False
    nvm_versions: list[str] = field(default_factory=list)
    nvm_current: Optional[str] = None
    npm_version: Optional[str] = None
    global_packages: list[dict] = field(default_factory=list)


@dataclass
class DockerInfo(EnvironmentInfo):
    daemon_running: bool = False
    containers: list[dict] = field(default_factory=list)
    images: list[dict] = field(default_factory=list)
    volumes: list[dict] = field(default_factory=list)
    disk_usage: Optional[dict] = None
    compose_version: Optional[str] = None
    context_name: Optional[str] = None


@dataclass
class GitInfo(EnvironmentInfo):
    user_name: Optional[str] = None
    user_email: Optional[str] = None
    signing_key: Optional[str] = None
    default_branch: Optional[str] = None
    gh_installed: bool = False
    gh_version: Optional[str] = None
    gh_auth_status: Optional[str] = None
    gh_user: Optional[str] = None
    current_repo: Optional[str] = None
    current_branch: Optional[str] = None
    remotes: list[dict] = field(default_factory=list)
