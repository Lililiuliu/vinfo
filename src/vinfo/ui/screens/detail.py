from textual.screen import Screen
from textual.widgets import Header, Footer, Static


class DetailScreen(Screen):
    def __init__(self, info, **kwargs):
        super().__init__(**kwargs)
        self._info = info

    @property
    def info(self):
        return self._info
