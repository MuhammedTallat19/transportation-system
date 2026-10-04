"""
Django 4.2 template Context copying fails on Python 3.14+ (admin change lists break).

Upstream fix uses instance __new__ instead of copy(super()). Apply before any
template rendering. Long-term: use Python 3.12 or Django 5.2+.
"""
from __future__ import annotations

import sys
from copy import copy


def apply() -> None:
    if sys.version_info < (3, 14):
        return

    import django.template.context as context_module

    def _base_context_copy(self):
        duplicate = self.__class__.__new__(self.__class__)
        if self.__dict__:
            duplicate.__dict__.update(self.__dict__)
        duplicate.dicts = self.dicts[:]
        return duplicate

    def _context_copy(self):
        duplicate = context_module.BaseContext.__copy__(self)
        duplicate.render_context = copy(self.render_context)
        return duplicate

    context_module.BaseContext.__copy__ = _base_context_copy
    context_module.Context.__copy__ = _context_copy


apply()
