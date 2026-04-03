from textual.widget import Widget
from textual.widgets import Static

from vinfo.constants import HealthStatus, STATUS_CSS_CLASS


class StatusBadge(Widget):
    def __init__(self, status: HealthStatus, label: str = "", **kwargs):
        super().__init__(**kwargs)
        self._status = status
        self._label = label or self._default_label(status)

    def _default_label(self, status: HealthStatus) -> str:
        labels = {
            HealthStatus.HEALTHY: "OK",
            HealthStatus.WARNING: "!!",
            HealthStatus.ERROR: "XX",
            HealthStatus.NOT_FOUND: "--",
            HealthStatus.UNKNOWN: "??",
        }
        return labels.get(status, "??")

    def compose(self):
        css_class = STATUS_CSS_CLASS.get(self._status, "status-unknown")
        yield Static(f"[{self._label}]", classes=f"status-badge {css_class}")
