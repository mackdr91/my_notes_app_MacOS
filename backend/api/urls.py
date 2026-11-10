"""
Author: Domonick Mack
Date: 2026-11-09
Description: API URL Routing for Notes, Folders, Batch Sync, and Health Check endpoints.
"""
from django.urls import include, path
from rest_framework.routers import DefaultRouter

from api.views import BatchSyncView, FolderViewSet, HealthCheckView, NoteViewSet

router = DefaultRouter()
router.register(r'notes', NoteViewSet, basename='note')
router.register(r'folders', FolderViewSet, basename='folder')

urlpatterns = [
    path('', include(router.urls)),
    path('sync/', BatchSyncView.as_view(), name='batch-sync'),
    path('health/', HealthCheckView.as_view(), name='health-check'),
]
