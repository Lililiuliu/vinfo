from enum import Enum


class HealthStatus(str, Enum):
    HEALTHY = "healthy"
    WARNING = "warning"
    ERROR = "error"
    NOT_FOUND = "not_found"
    UNKNOWN = "unknown"


STATUS_ICONS: dict[HealthStatus, str] = {
    HealthStatus.HEALTHY: "[green]OK[/]",
    HealthStatus.WARNING: "[yellow]!![/]",
    HealthStatus.ERROR: "[red]XX[/]",
    HealthStatus.NOT_FOUND: "[gray]--[/]",
    HealthStatus.UNKNOWN: "[magenta]??[/]",
}

# Plain-text labels for CLI
STATUS_LABELS: dict[HealthStatus, str] = {
    HealthStatus.HEALTHY: "OK",
    HealthStatus.WARNING: "!!",
    HealthStatus.ERROR: "XX",
    HealthStatus.NOT_FOUND: "--",
    HealthStatus.UNKNOWN: "??",
}

STATUS_CSS_CLASS: dict[HealthStatus, str] = {
    HealthStatus.HEALTHY: "status-ok",
    HealthStatus.WARNING: "status-warn",
    HealthStatus.ERROR: "status-error",
    HealthStatus.NOT_FOUND: "status-missing",
    HealthStatus.UNKNOWN: "status-unknown",
}
