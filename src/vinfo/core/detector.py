import os
import platform
import sys
from dataclasses import dataclass
from enum import Enum


class OSFamily(str, Enum):
    MACOS = "macos"
    LINUX = "linux"
    WINDOWS = "windows"
    OTHER = "other"


@dataclass
class PlatformInfo:
    os_family: OSFamily
    os_name: str
    os_version: str
    architecture: str
    shell: str
    home_dir: str
    config_dir: str


def detect_platform() -> PlatformInfo:
    system = platform.system().lower()
    if system == "darwin":
        family = OSFamily.MACOS
    elif system == "linux":
        family = OSFamily.LINUX
    elif system == "windows":
        family = OSFamily.WINDOWS
    else:
        family = OSFamily.OTHER

    if family in (OSFamily.MACOS, OSFamily.LINUX):
        config_dir = os.path.join(
            os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")), "vinfo"
        )
    else:
        config_dir = os.path.join(os.environ.get("APPDATA", ""), "vinfo")

    return PlatformInfo(
        os_family=family,
        os_name=platform.system(),
        os_version=platform.release(),
        architecture=platform.machine(),
        shell=os.environ.get("SHELL", "/bin/sh"),
        home_dir=os.path.expanduser("~"),
        config_dir=config_dir,
    )
