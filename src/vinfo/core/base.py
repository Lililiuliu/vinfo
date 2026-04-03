from abc import ABC, abstractmethod

from vinfo.constants import HealthStatus
from vinfo.core.models import EnvironmentInfo


class BaseEnvironmentProvider(ABC):
    name: str = ""
    display_name: str = ""
    icon: str = "?"

    @abstractmethod
    async def detect(self) -> bool: ...

    @abstractmethod
    async def collect(self) -> EnvironmentInfo: ...

    @abstractmethod
    async def health_check(self) -> tuple[HealthStatus, list[str]]: ...

    @abstractmethod
    def get_quick_actions(self) -> list[dict]: ...

    @property
    def priority(self) -> int:
        return 100
