"""Serializers with explicit validation for Notes and Folders."""
from typing import Any, Dict, List, Optional
from rest_framework import serializers


class ChecklistItemSerializer(serializers.Serializer):
    """Serializer for individual note checklist items."""

    id = serializers.CharField(max_length=128)
    text = serializers.CharField(max_length=1024, allow_blank=True)
    isCompleted = serializers.BooleanField(default=False)


class NoteTableSerializer(serializers.Serializer):
    """Serializer for embedded table structures inside notes."""

    id = serializers.CharField(max_length=128)
    rowCount = serializers.IntegerField(min_value=1, max_value=100)
    colCount = serializers.IntegerField(min_value=1, max_value=20)
    cells = serializers.ListField(
        child=serializers.ListField(child=serializers.CharField(allow_blank=True))
    )

    def validate_cells(self, value: List[List[str]]) -> List[List[str]]:
        if not isinstance(value, list):
            raise serializers.ValidationError("Table cells must be a two-dimensional matrix.")
        return value


class NoteAttachmentSerializer(serializers.Serializer):
    """Serializer for attached media and documents."""

    id = serializers.CharField(max_length=128)
    name = serializers.CharField(max_length=512)
    fileType = serializers.CharField(max_length=64)
    localPath = serializers.CharField(max_length=1024, allow_blank=True)
    fileSize = serializers.IntegerField(min_value=0)


class NoteSerializer(serializers.Serializer):
    """Serializer for Apple Note documents with explicit validations."""

    id = serializers.CharField(max_length=128)
    folderId = serializers.CharField(max_length=128)
    title = serializers.CharField(max_length=512, allow_blank=True, default='')
    body = serializers.CharField(allow_blank=True, default='')
    richTextJson = serializers.CharField(allow_blank=True, allow_null=True, required=False, default=None)
    tags = serializers.ListField(child=serializers.CharField(max_length=64), required=False, default=list)
    isPinned = serializers.BooleanField(default=False)
    isLocked = serializers.BooleanField(default=False)
    passwordHash = serializers.CharField(max_length=256, required=False, allow_null=True, default=None)
    checklists = ChecklistItemSerializer(many=True, required=False, default=list)
    tables = NoteTableSerializer(many=True, required=False, default=list)
    attachments = NoteAttachmentSerializer(many=True, required=False, default=list)
    createdAt = serializers.DateTimeField()
    updatedAt = serializers.DateTimeField()

    def validate_title(self, value: str) -> str:
        """Sanitizes and validates note title."""
        return value.strip()

    def validate_folderId(self, value: str) -> str:
        """Ensures folderId is non-empty."""
        if not value or not value.strip():
            raise serializers.ValidationError("folderId cannot be empty.")
        return value.strip()

    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """Cross-field validation for note payload."""
        if attrs.get('isLocked') and not attrs.get('passwordHash'):
            # Allow lock flag with system authentication password
            pass
        return attrs


class FolderSerializer(serializers.Serializer):
    """Serializer for Folder documents."""

    id = serializers.CharField(max_length=128)
    name = serializers.CharField(max_length=256)
    account = serializers.CharField(max_length=64, default='iCloud')
    parentId = serializers.CharField(max_length=128, required=False, allow_null=True, default=None)
    isSystem = serializers.BooleanField(default=False)
    iconType = serializers.CharField(max_length=64, default='folder')
    createdAt = serializers.DateTimeField()
    updatedAt = serializers.DateTimeField()

    def validate_name(self, value: str) -> str:
        """Validates folder name is non-empty."""
        cleaned = value.strip()
        if not cleaned:
            raise serializers.ValidationError("Folder name cannot be blank.")
        return cleaned


class BatchSyncSerializer(serializers.Serializer):
    """Serializer for batch offline-first synchronization requests."""

    notes = NoteSerializer(many=True, required=False, default=list)
    folders = FolderSerializer(many=True, required=False, default=list)
    lastSyncTimestamp = serializers.DateTimeField(required=False, allow_null=True, default=None)
