from vinfo.core.registry import register
from vinfo.providers.docker_provider import DockerProvider
from vinfo.providers.git_provider import GitProvider
from vinfo.providers.node_provider import NodeProvider
from vinfo.providers.python_provider import PythonProvider

__all__ = [
    "PythonProvider",
    "NodeProvider",
    "DockerProvider",
    "GitProvider",
]
