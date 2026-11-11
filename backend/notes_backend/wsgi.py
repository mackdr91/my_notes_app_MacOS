"""
Author: Domonick Mack
Date: 2026-11-10
Description: WSGI config for notes_backend project.
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'notes_backend.settings')

application = get_wsgi_application()
