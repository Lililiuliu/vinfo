from typing import Sequence

from textual.widgets import Static


class InfoTable(Static):
    def __init__(self, rows: Sequence[tuple[str, str]], **kwargs):
        super().__init__(**kwargs)
        self._rows = list(rows)

    def compose(self):
        for key, value in self._rows:
            yield Static(f"[bold][blue]{key}:[/]  {value}", classes="info-row")

    def update_rows(self, rows: Sequence[tuple[str, str]]):
        self._rows = list(rows)
        self.refresh()
