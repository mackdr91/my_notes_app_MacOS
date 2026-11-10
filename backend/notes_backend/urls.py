"""
Author: Domonick Mack
Date: 2026-11-09
Description: Root URL Configuration for notes_backend including API and installer download portal routes.
"""
from django.contrib import admin
from django.urls import include, path

from api.views import DownloadArtifactView, DownloadPortalView

urlpatterns = [
    path('', DownloadPortalView.as_view(), name='root-download-portal'),
    path('download/', DownloadPortalView.as_view(), name='download-portal'),
    path('download/<str:filename>', DownloadArtifactView.as_view(), name='download-artifact'),
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
]
