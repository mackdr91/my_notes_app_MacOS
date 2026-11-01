"""RESTful API Views for Apple Notes backend with explicit typing and HTTP status codes."""
from typing import Any, Dict, List, Optional
from datetime import datetime, timezone
from rest_framework import status, viewsets
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from api.mongodb import get_folders_collection, get_notes_collection
from api.serializers import BatchSyncSerializer, FolderSerializer, NoteSerializer


class NoteViewSet(viewsets.ViewSet):
    """ViewSet managing Note CRUD operations against MongoDB."""

    def list(self, request: Request) -> Response:
        """Retrieves notes with optional folder, tag, and query filtering."""
        collection = get_notes_collection()
        query: Dict[str, Any] = {}

        folder_id: Optional[str] = request.query_params.get('folder_id')
        if folder_id:
            query['folderId'] = folder_id

        tag: Optional[str] = request.query_params.get('tag')
        if tag:
            query['tags'] = tag

        raw_notes: List[Dict[str, Any]] = collection.find(query)

        # In-memory search filtering if query param present
        search_term: Optional[str] = request.query_params.get('search')
        if search_term:
            term_lower = search_term.lower()
            raw_notes = [
                n for n in raw_notes
                if term_lower in n.get('title', '').lower()
                or term_lower in n.get('body', '').lower()
            ]

        serializer = NoteSerializer(raw_notes, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def retrieve(self, request: Request, pk: Optional[str] = None) -> Response:
        """Retrieves a single note by ID."""
        if not pk:
            return Response({'error': 'Note ID required.'}, status=status.HTTP_400_BAD_REQUEST)

        collection = get_notes_collection()
        doc = collection.find_one({'id': pk})
        if not doc:
            return Response({'error': f"Note with ID '{pk}' not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = NoteSerializer(doc)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def create(self, request: Request) -> Response:
        """Validates and persists a new note in MongoDB."""
        serializer = NoteSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data: Dict[str, Any] = serializer.validated_data
        # Ensure string format for JSON response
        doc: Dict[str, Any] = {
            **validated_data,
            'createdAt': validated_data['createdAt'].isoformat(),
            'updatedAt': validated_data['updatedAt'].isoformat(),
        }

        collection = get_notes_collection()
        collection.insert_one(doc)

        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def update(self, request: Request, pk: Optional[str] = None) -> Response:
        """Updates an existing note document."""
        if not pk:
            return Response({'error': 'Note ID required.'}, status=status.HTTP_400_BAD_REQUEST)

        collection = get_notes_collection()
        existing = collection.find_one({'id': pk})
        if not existing:
            return Response({'error': f"Note with ID '{pk}' not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = NoteSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data: Dict[str, Any] = serializer.validated_data
        update_doc: Dict[str, Any] = {
            **validated_data,
            'createdAt': validated_data['createdAt'].isoformat(),
            'updatedAt': validated_data['updatedAt'].isoformat(),
        }

        collection.update_one({'id': pk}, {'$set': update_doc})
        return Response(serializer.data, status=status.HTTP_200_OK)

    def destroy(self, request: Request, pk: Optional[str] = None) -> Response:
        """Permanently removes a note."""
        if not pk:
            return Response({'error': 'Note ID required.'}, status=status.HTTP_400_BAD_REQUEST)

        collection = get_notes_collection()
        existing = collection.find_one({'id': pk})
        if not existing:
            return Response({'error': f"Note with ID '{pk}' not found."}, status=status.HTTP_404_NOT_FOUND)

        collection.delete_many({'id': pk})
        return Response(status=status.HTTP_204_NO_CONTENT)


class FolderViewSet(viewsets.ViewSet):
    """ViewSet managing Folder CRUD operations against MongoDB."""

    def list(self, request: Request) -> Response:
        """Retrieves all folders."""
        collection = get_folders_collection()
        raw_folders = collection.find({})
        serializer = FolderSerializer(raw_folders, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def retrieve(self, request: Request, pk: Optional[str] = None) -> Response:
        """Retrieves a single folder by ID."""
        if not pk:
            return Response({'error': 'Folder ID required.'}, status=status.HTTP_400_BAD_REQUEST)

        collection = get_folders_collection()
        doc = collection.find_one({'id': pk})
        if not doc:
            return Response({'error': f"Folder with ID '{pk}' not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = FolderSerializer(doc)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def create(self, request: Request) -> Response:
        """Creates a new folder."""
        serializer = FolderSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data: Dict[str, Any] = serializer.validated_data
        doc: Dict[str, Any] = {
            **validated_data,
            'createdAt': validated_data['createdAt'].isoformat(),
            'updatedAt': validated_data['updatedAt'].isoformat(),
        }

        collection = get_folders_collection()
        collection.insert_one(doc)

        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def update(self, request: Request, pk: Optional[str] = None) -> Response:
        """Updates folder metadata."""
        if not pk:
            return Response({'error': 'Folder ID required.'}, status=status.HTTP_400_BAD_REQUEST)

        collection = get_folders_collection()
        existing = collection.find_one({'id': pk})
        if not existing:
            return Response({'error': f"Folder with ID '{pk}' not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = FolderSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data: Dict[str, Any] = serializer.validated_data
        update_doc: Dict[str, Any] = {
            **validated_data,
            'createdAt': validated_data['createdAt'].isoformat(),
            'updatedAt': validated_data['updatedAt'].isoformat(),
        }

        collection.update_one({'id': pk}, {'$set': update_doc})
        return Response(serializer.data, status=status.HTTP_200_OK)

    def destroy(self, request: Request, pk: Optional[str] = None) -> Response:
        """Deletes a user-created folder."""
        if not pk:
            return Response({'error': 'Folder ID required.'}, status=status.HTTP_400_BAD_REQUEST)

        collection = get_folders_collection()
        existing = collection.find_one({'id': pk})
        if not existing:
            return Response({'error': f"Folder with ID '{pk}' not found."}, status=status.HTTP_404_NOT_FOUND)

        if existing.get('isSystem', False):
            return Response(
                {'error': 'System default folders cannot be deleted.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        collection.delete_many({'id': pk})
        return Response(status=status.HTTP_204_NO_CONTENT)


class BatchSyncView(APIView):
    """Batch reconciliation endpoint for offline-first Flutter synchronization."""

    def post(self, request: Request) -> Response:
        serializer = BatchSyncSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        notes_data: List[Dict[str, Any]] = serializer.validated_data.get('notes', [])
        folders_data: List[Dict[str, Any]] = serializer.validated_data.get('folders', [])

        notes_col = get_notes_collection()
        folders_col = get_folders_collection()

        synced_notes_count = 0
        for note in notes_data:
            doc = {
                **note,
                'createdAt': note['createdAt'].isoformat(),
                'updatedAt': note['updatedAt'].isoformat(),
            }
            existing = notes_col.find_one({'id': note['id']})
            if existing:
                notes_col.update_one({'id': note['id']}, {'$set': doc})
            else:
                notes_col.insert_one(doc)
            synced_notes_count += 1

        synced_folders_count = 0
        for folder in folders_data:
            f_doc = {
                **folder,
                'createdAt': folder['createdAt'].isoformat(),
                'updatedAt': folder['updatedAt'].isoformat(),
            }
            existing_f = folders_col.find_one({'id': folder['id']})
            if existing_f:
                folders_col.update_one({'id': folder['id']}, {'$set': f_doc})
            else:
                folders_col.insert_one(f_doc)
            synced_folders_count += 1

        return Response(
            {
                'status': 'success',
                'syncedNotes': synced_notes_count,
                'syncedFolders': synced_folders_count,
                'serverTimestamp': datetime.now(timezone.utc).isoformat(),
            },
            status=status.HTTP_200_OK,
        )


class HealthCheckView(APIView):
    """System health check endpoint."""

    def get(self, request: Request) -> Response:
        return Response(
            {
                'service': 'mac-apple-notes-backend',
                'status': 'healthy',
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'version': '1.0.0',
            },
            status=status.HTTP_200_OK,
        )
