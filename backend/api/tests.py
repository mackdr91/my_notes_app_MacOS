"""
Author: Domonick Mack
Date: 2026-11-09
Description: Comprehensive unit and integration tests for the Notes, Folders, Two-Way Sync, and Download Portal API.
"""
from datetime import datetime, timedelta, timezone
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from api.mongodb import MongoDBManager


class NotesAPITests(APITestCase):
    """Test suite for Notes endpoints, two-way batch sync, and download portal."""

    def setUp(self) -> None:
        MongoDBManager.reset()
        self.now_dt = datetime.now(timezone.utc)
        self.now_iso = self.now_dt.isoformat()
        self.sample_note_payload = {
            'id': 'test_note_101',
            'folderId': 'notes',
            'title': 'Test Meeting Note',
            'body': 'Discussing system architecture with the engineering team.',
            'tags': ['work', 'architecture'],
            'isPinned': True,
            'isLocked': False,
            'passwordHash': None,
            'checklists': [
                {'id': 'c1', 'text': 'Draft API spec', 'isCompleted': True},
                {'id': 'c2', 'text': 'Verify MongoDB sync', 'isCompleted': False},
            ],
            'tables': [
                {
                    'id': 't1',
                    'rowCount': 2,
                    'colCount': 2,
                    'cells': [['Header A', 'Header B'], ['Value 1', 'Value 2']],
                }
            ],
            'attachments': [],
            'createdAt': self.now_iso,
            'updatedAt': self.now_iso,
        }

    def test_health_check(self) -> None:
        """Health check returns 200 OK."""
        url = reverse('health-check')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'healthy')

    def test_create_and_retrieve_note(self) -> None:
        """Creating a note persists it and allows retrieval."""
        url = reverse('note-list')
        response = self.client.post(url, self.sample_note_payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], 'Test Meeting Note')
        self.assertTrue(response.data['isPinned'])

        # Retrieve note
        detail_url = reverse('note-detail', kwargs={'pk': 'test_note_101'})
        detail_response = self.client.get(detail_url)
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        self.assertEqual(detail_response.data['id'], 'test_note_101')

    def test_update_note(self) -> None:
        """Updating note content returns 200 OK."""
        url = reverse('note-list')
        self.client.post(url, self.sample_note_payload, format='json')

        updated_payload = dict(self.sample_note_payload)
        updated_payload['title'] = 'Updated Architecture Meeting'
        detail_url = reverse('note-detail', kwargs={'pk': 'test_note_101'})
        response = self.client.put(detail_url, updated_payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], 'Updated Architecture Meeting')

    def test_delete_note(self) -> None:
        """Deleting note returns 204 NO CONTENT."""
        url = reverse('note-list')
        self.client.post(url, self.sample_note_payload, format='json')

        detail_url = reverse('note-detail', kwargs={'pk': 'test_note_101'})
        response = self.client.delete(detail_url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)

        get_response = self.client.get(detail_url)
        self.assertEqual(get_response.status_code, status.HTTP_404_NOT_FOUND)

    def test_folder_crud(self) -> None:
        """Folder CRUD operations succeed."""
        folder_payload = {
            'id': 'folder_custom_1',
            'name': 'Personal Projects',
            'account': 'iCloud',
            'parentId': None,
            'isSystem': False,
            'iconType': 'folder',
            'createdAt': self.now_iso,
            'updatedAt': self.now_iso,
        }
        url = reverse('folder-list')
        create_res = self.client.post(url, folder_payload, format='json')
        self.assertEqual(create_res.status_code, status.HTTP_201_CREATED)

        detail_url = reverse('folder-detail', kwargs={'pk': 'folder_custom_1'})
        get_res = self.client.get(detail_url)
        self.assertEqual(get_res.status_code, status.HTTP_200_OK)
        self.assertEqual(get_res.data['name'], 'Personal Projects')

    def test_batch_sync_and_last_write_wins(self) -> None:
        """Batch sync reconciles offline notes/folders and returns merged state with Last-Write-Wins."""
        sync_payload = {
            'notes': [self.sample_note_payload],
            'folders': [
                {
                    'id': 'f_sync_1',
                    'name': 'Synced Folder',
                    'account': 'iCloud',
                    'parentId': None,
                    'isSystem': False,
                    'iconType': 'folder',
                    'createdAt': self.now_iso,
                    'updatedAt': self.now_iso,
                }
            ],
            'lastSyncTimestamp': self.now_iso,
        }
        url = reverse('batch-sync')
        response = self.client.post(url, sync_payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['syncedNotes'], 1)
        self.assertEqual(response.data['syncedFolders'], 1)
        self.assertEqual(len(response.data['notes']), 1)
        self.assertEqual(len(response.data['folders']), 1)

        # Older edit from a stale device should NOT overwrite newer server state
        stale_note = dict(self.sample_note_payload)
        stale_note['title'] = 'Stale Title From Offline Device'
        stale_note['updatedAt'] = (self.now_dt - timedelta(minutes=10)).isoformat()

        res_stale = self.client.post(url, {'notes': [stale_note], 'folders': []}, format='json')
        self.assertEqual(res_stale.status_code, status.HTTP_200_OK)
        self.assertEqual(res_stale.data['notes'][0]['title'], 'Test Meeting Note')

    def test_download_portal_renders(self) -> None:
        """Download portal HTML page renders 200 OK."""
        url = reverse('download-portal')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn(b'Notes for macOS &amp; iPadOS', response.content)
