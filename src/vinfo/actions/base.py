from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass
class ActionResult:
    success: bool
    message: str
    output: str = ""


class BaseAction(ABC):
    name: str = ""
    description: str = ""
    dangerous: bool = False

    @abstractmethod
    async def execute(self, runner, info) -> ActionResult:
        ...

    @property
    def label(self) -> str:
        return self.name
