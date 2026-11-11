"""
Author: Domonick Mack
Date: 2026-11-10
Description: Comprehensive unit and integration tests for Notes, Folders, Two-Way Sync, Auth, MongoDB, and Download Portal.
"""

from __future__ import annotations

import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest.mock import MagicMock, patch

from django.test import RequestFactory
from django.urls import reverse
from rest_framework import exceptions, status
from rest_framework.test import APITestCase

from api.authentication import FirebaseAuthentication
from api.mongodb import InMemoryCollection, MongoDBManager
from api.views import FolderViewSet, NoteViewSet, _parse_iso_datetime


class NotesAPITests(APITestCase):
    """Test suite for Notes endpoints, Folders, two-way batch sync, auth, and download portal."""

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

    def test_create_list_filter_and_retrieve_note(self) -> None:
        """Creating a note persists it and supports folder, tag, and search filtering."""
        url = reverse('note-list')
        response = self.client.post(url, self.sample_note_payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], 'Test Meeting Note')
        self.assertTrue(response.data['isPinned'])

        # Filter by folder_id, tag, and search term
        list_res = self.client.get(
            url, {'folder_id': 'notes', 'tag': 'work', 'search': 'architecture'}
        )
        self.assertEqual(list_res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(list_res.data), 1)

        # Search term with no match returns empty list
        empty_res = self.client.get(url, {'search': 'nonexistent_keyword_xyz'})
        self.assertEqual(empty_res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(empty_res.data), 0)

        # Retrieve note
        detail_url = reverse('note-detail', kwargs={'pk': 'test_note_101'})
        detail_response = self.client.get(detail_url)
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        self.assertEqual(detail_response.data['id'], 'test_note_101')

        # Retrieve non-existent note returns 404
        missing_url = reverse('note-detail', kwargs={'pk': 'does_not_exist'})
        self.assertEqual(self.client.get(missing_url).status_code, status.HTTP_404_NOT_FOUND)

    def test_note_validation_and_edge_cases(self) -> None:
        """Invalid note payloads and missing IDs return appropriate 400/404 responses."""
        url = reverse('note-list')
        bad_payload = dict(self.sample_note_payload, folderId='')
        res = self.client.post(url, bad_payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

        # Update non-existent note returns 404
        missing_url = reverse('note-detail', kwargs={'pk': 'missing_id'})
        self.assertEqual(
            self.client.put(missing_url, self.sample_note_payload, format='json').status_code,
            status.HTTP_404_NOT_FOUND,
        )

        # Create then send invalid update
        self.client.post(url, self.sample_note_payload, format='json')
        detail_url = reverse('note-detail', kwargs={'pk': 'test_note_101'})
        bad_update = self.client.put(detail_url, bad_payload, format='json')
        self.assertEqual(bad_update.status_code, status.HTTP_400_BAD_REQUEST)

        # Delete non-existent note returns 404
        self.assertEqual(self.client.delete(missing_url).status_code, status.HTTP_404_NOT_FOUND)

        # Direct ViewSet calls without pk return 400
        viewset = NoteViewSet()
        req = RequestFactory().get('/api/notes/')
        self.assertEqual(viewset.retrieve(req, pk=None).status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(viewset.update(req, pk=None).status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(viewset.destroy(req, pk=None).status_code, status.HTTP_400_BAD_REQUEST)

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

    def test_folder_crud_and_system_folder_protection(self) -> None:
        """Folder CRUD operations succeed and system folders cannot be deleted."""
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

        # List folders
        list_res = self.client.get(url)
        self.assertEqual(list_res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(list_res.data), 1)

        # Invalid folder creation (blank name)
        bad_folder = dict(folder_payload, name='   ')
        self.assertEqual(
            self.client.post(url, bad_folder, format='json').status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        # Retrieve & update folder
        detail_url = reverse('folder-detail', kwargs={'pk': 'folder_custom_1'})
        get_res = self.client.get(detail_url)
        self.assertEqual(get_res.status_code, status.HTTP_200_OK)
        self.assertEqual(get_res.data['name'], 'Personal Projects')

        updated_folder = dict(folder_payload, name='Renamed Projects')
        put_res = self.client.put(detail_url, updated_folder, format='json')
        self.assertEqual(put_res.status_code, status.HTTP_200_OK)
        self.assertEqual(put_res.data['name'], 'Renamed Projects')

        # Invalid update returns 400
        self.assertEqual(
            self.client.put(detail_url, bad_folder, format='json').status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        # Delete custom folder
        del_res = self.client.delete(detail_url)
        self.assertEqual(del_res.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(self.client.get(detail_url).status_code, status.HTTP_404_NOT_FOUND)
        self.assertEqual(
            self.client.put(detail_url, updated_folder, format='json').status_code,
            status.HTTP_404_NOT_FOUND,
        )
        self.assertEqual(self.client.delete(detail_url).status_code, status.HTTP_404_NOT_FOUND)

        # System folder cannot be deleted
        sys_folder = dict(folder_payload, id='sys_notes', name='Notes', isSystem=True)
        self.client.post(url, sys_folder, format='json')
        sys_url = reverse('folder-detail', kwargs={'pk': 'sys_notes'})
        sys_del = self.client.delete(sys_url)
        self.assertEqual(sys_del.status_code, status.HTTP_400_BAD_REQUEST)

        # Direct FolderViewSet calls without pk return 400
        f_viewset = FolderViewSet()
        req = RequestFactory().get('/api/folders/')
        self.assertEqual(f_viewset.retrieve(req, pk=None).status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(f_viewset.update(req, pk=None).status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(f_viewset.destroy(req, pk=None).status_code, status.HTTP_400_BAD_REQUEST)

    def test_batch_sync_and_last_write_wins(self) -> None:
        """Batch sync reconciles offline notes/folders and returns merged state with Last-Write-Wins."""
        folder_item = {
            'id': 'f_sync_1',
            'name': 'Synced Folder',
            'account': 'iCloud',
            'parentId': None,
            'isSystem': False,
            'iconType': 'folder',
            'createdAt': self.now_iso,
            'updatedAt': self.now_iso,
        }
        sync_payload = {
            'notes': [self.sample_note_payload],
            'folders': [folder_item],
            'lastSyncTimestamp': self.now_iso,
        }
        url = reverse('batch-sync')
        response = self.client.post(url, sync_payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['syncedNotes'], 1)
        self.assertEqual(response.data['syncedFolders'], 1)

        # Older edit from a stale device should NOT overwrite newer server state
        stale_note = dict(self.sample_note_payload, title='Stale Title')
        stale_note['updatedAt'] = (self.now_dt - timedelta(minutes=10)).isoformat()
        stale_folder = dict(folder_item, name='Stale Folder Name')
        stale_folder['updatedAt'] = (self.now_dt - timedelta(minutes=10)).isoformat()

        res_stale = self.client.post(
            url, {'notes': [stale_note], 'folders': [stale_folder]}, format='json'
        )
        self.assertEqual(res_stale.status_code, status.HTTP_200_OK)
        self.assertEqual(res_stale.data['notes'][0]['title'], 'Test Meeting Note')
        self.assertEqual(res_stale.data['folders'][0]['name'], 'Synced Folder')

        # Newer edit SHOULD overwrite server state
        newer_note = dict(self.sample_note_payload, title='Newer Synced Title')
        newer_note['updatedAt'] = (self.now_dt + timedelta(minutes=5)).isoformat()
        newer_folder = dict(folder_item, name='Newer Synced Folder')
        newer_folder['updatedAt'] = (self.now_dt + timedelta(minutes=5)).isoformat()

        res_newer = self.client.post(
            url, {'notes': [newer_note], 'folders': [newer_folder]}, format='json'
        )
        self.assertEqual(res_newer.status_code, status.HTTP_200_OK)
        self.assertEqual(res_newer.data['notes'][0]['title'], 'Newer Synced Title')
        self.assertEqual(res_newer.data['folders'][0]['name'], 'Newer Synced Folder')

        # Invalid sync payload returns 400
        bad_sync = self.client.post(url, {'notes': [{'invalid': True}]}, format='json')
        self.assertEqual(bad_sync.status_code, status.HTTP_400_BAD_REQUEST)

    def test_parse_iso_datetime_helper(self) -> None:
        """_parse_iso_datetime handles naive/aware datetimes, ISO strings, and invalid values."""
        naive_dt = datetime(2026, 11, 10, 12, 0, 0)
        self.assertEqual(_parse_iso_datetime(naive_dt).tzinfo, timezone.utc)

        aware_dt = datetime(2026, 11, 10, 12, 0, 0, tzinfo=timezone.utc)
        self.assertEqual(_parse_iso_datetime(aware_dt), aware_dt)

        self.assertIsNotNone(_parse_iso_datetime('2026-11-10T12:00:00Z'))
        self.assertIsNotNone(_parse_iso_datetime('2026-11-10T12:00:00'))
        self.assertIsNone(_parse_iso_datetime('not-a-timestamp'))
        self.assertIsNone(_parse_iso_datetime(None))

    def test_download_portal_and_artifact_streaming(self) -> None:
        """Download portal renders artifacts or empty state, and streams files safely."""
        portal_url = reverse('download-portal')

        with tempfile.TemporaryDirectory() as tmp_dir:
            with patch.dict('os.environ', {'RELEASES_DIR': tmp_dir}):
                # Empty releases directory renders empty state
                empty_res = self.client.get(portal_url)
                self.assertEqual(empty_res.status_code, status.HTTP_200_OK)
                self.assertIn(b'No installer packages found', empty_res.content)

                # Populate sample artifacts
                dmg_file = Path(tmp_dir) / 'Notes-macOS-v1.0.0.dmg'
                ipa_file = Path(tmp_dir) / 'Notes-iPadOS-v1.0.0.ipa'
                sums_file = Path(tmp_dir) / 'SHA256SUMS.txt'
                dmg_file.write_bytes(b'DMG_BINARY_CONTENT')
                ipa_file.write_bytes(b'IPA_BINARY_CONTENT')
                sums_file.write_text('abc123  Notes-macOS-v1.0.0.dmg\n', encoding='utf-8')

                populated_res = self.client.get(portal_url)
                self.assertEqual(populated_res.status_code, status.HTTP_200_OK)
                self.assertIn(b'Notes-macOS-v1.0.0.dmg', populated_res.content)
                self.assertIn(b'Notes-iPadOS-v1.0.0.ipa', populated_res.content)

                # Stream existing artifact
                dl_url = reverse('download-artifact', kwargs={'filename': 'Notes-macOS-v1.0.0.dmg'})
                dl_res = self.client.get(dl_url)
                self.assertEqual(dl_res.status_code, status.HTTP_200_OK)
                dl_res.close()

                # Missing artifact returns 404
                missing_dl = reverse('download-artifact', kwargs={'filename': 'missing.dmg'})
                self.assertEqual(self.client.get(missing_dl).status_code, status.HTTP_404_NOT_FOUND)

    def test_firebase_authentication_flows(self) -> None:
        """FirebaseAuthentication handles missing headers, dev fallback, and Firebase verification."""
        auth = FirebaseAuthentication()
        factory = RequestFactory()

        # No Authorization header -> returns None
        req_none = factory.get('/api/notes/')
        self.assertIsNone(auth.authenticate(req_none))

        # Non-Bearer header -> returns None
        req_basic = factory.get('/api/notes/', HTTP_AUTHORIZATION='Basic abc123')
        self.assertIsNone(auth.authenticate(req_basic))

        # Local dev fallback when no Firebase app is initialized
        req_bearer = factory.get('/api/notes/', HTTP_AUTHORIZATION='Bearer devtoken123456')
        user, _ = auth.authenticate(req_bearer)
        self.assertTrue(user.username.startswith('dev_user_'))

        # Mocked Firebase app active: valid token and invalid token
        with (
            patch('api.authentication.FIREBASE_AVAILABLE', True),
            patch('api.authentication.firebase_admin', create=True) as mock_admin,
            patch('api.authentication.firebase_auth', create=True) as mock_fb_auth,
        ):
            mock_admin._apps = {'default': MagicMock()}
            mock_fb_auth.verify_id_token.return_value = {'uid': 'firebase_uid_99'}

            fb_user, _ = auth.authenticate(req_bearer)
            self.assertEqual(fb_user.username, 'firebase_uid_99')

            mock_fb_auth.verify_id_token.side_effect = ValueError('Expired token')
            with self.assertRaises(exceptions.AuthenticationFailed):
                auth.authenticate(req_bearer)

    def test_in_memory_collection_and_mongodb_manager_safety(self) -> None:
        """InMemoryCollection supports full CRUD and MongoDBManager protects non-test DBs."""
        col = InMemoryCollection('test_items')
        col.insert_one({'id': 'item_1', 'name': 'Alpha', 'group': 'A'})
        col.insert_one({'id': 'item_2', 'name': 'Beta', 'group': 'A'})
        self.assertEqual(col.count_documents({'group': 'A'}), 2)
        self.assertIsNotNone(col.find_one({'id': 'item_1'}))
        self.assertIsNone(col.find_one({'id': 'missing'}))

        # Update existing and non-existing
        res_up = col.update_one({'id': 'item_1'}, {'$set': {'name': 'Alpha Updated'}})
        self.assertEqual(res_up.modified_count, 1)
        res_up_miss = col.update_one({'id': 'missing'}, {'$set': {'name': 'None'}})
        self.assertEqual(res_up_miss.matched_count, 0)

        # Delete one and delete many
        self.assertEqual(col.delete_one({'id': 'missing'}).deleted_count, 0)
        self.assertEqual(col.delete_one({'id': 'item_1'}).deleted_count, 1)
        self.assertEqual(col.delete_many({'group': 'A'}).deleted_count, 1)
        col.clear()
        self.assertEqual(col.count_documents(), 0)

        # Verify MongoDBManager refuses to reset a non-test database
        fake_db = MagicMock()
        fake_db.name = 'production_db'
        with patch.object(MongoDBManager, '_db', fake_db):
            with self.assertRaises(RuntimeError):
                MongoDBManager.reset()
