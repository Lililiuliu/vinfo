from typing import Type

from vinfo.core.base import BaseEnvironmentProvider

_providers: dict[str, Type[BaseEnvironmentProvider]] = {}


def register(
    provider_class: Type[BaseEnvironmentProvider],
) -> Type[BaseEnvironmentProvider]:
    _providers[provider_class.name] = provider_class
    return provider_class


def get_all_providers() -> list[Type[BaseEnvironmentProvider]]:
    return sorted(_providers.values(), key=lambda p: p.priority)


def get_provider(name: str) -> Type[BaseEnvironmentProvider]:
    return _providers[name]


def get_registered_names() -> list[str]:
    return list(_providers.keys())
