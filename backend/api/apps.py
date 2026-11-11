"""
Author: Domonick Mack
Date: 2026-11-10
Description: Django AppConfig registration for the Notes API application.
"""

from django.apps import AppConfig


class ApiConfig(AppConfig):
    default_auto_field: str = 'django.db.models.BigAutoField'
    name: str = 'api'
    verbose_name: str = 'Notes & Folders API'
