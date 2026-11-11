"""
Author: Domonick Mack
Date: 2026-11-10
Description: RESTful API Views for Lusid backend with two-way batch sync and installer download portal.
"""

from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from django.conf import settings
from django.http import FileResponse, Http404, HttpRequest, HttpResponse
from rest_framework import status, viewsets
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from api.mongodb import get_folders_collection, get_notes_collection
from api.serializers import BatchSyncSerializer, FolderSerializer, NoteSerializer


def _parse_iso_datetime(value: Any) -> datetime | None:
    """Safely parses an ISO-8601 string or datetime into a timezone-aware UTC datetime."""
    if isinstance(value, datetime):
        if value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc)
    if isinstance(value, str) and value:
        try:
            normalized = value.replace('Z', '+00:00')
            parsed = datetime.fromisoformat(normalized)
            if parsed.tzinfo is None:
                return parsed.replace(tzinfo=timezone.utc)
            return parsed.astimezone(timezone.utc)
        except ValueError:
            return None
    return None


class NoteViewSet(viewsets.ViewSet):
    """ViewSet managing Note CRUD operations against MongoDB."""

    def list(self, request: Request) -> Response:
        """Retrieves notes with optional folder, tag, and query filtering."""
        collection = get_notes_collection()
        query: dict[str, Any] = {}

        folder_id: str | None = request.query_params.get('folder_id')
        if folder_id:
            query['folderId'] = folder_id

        tag: str | None = request.query_params.get('tag')
        if tag:
            query['tags'] = tag

        raw_notes: list[dict[str, Any]] = list(collection.find(query))

        # In-memory search filtering if query param present
        search_term: str | None = request.query_params.get('search')
        if search_term:
            term_lower = search_term.lower()
            raw_notes = [
                n
                for n in raw_notes
                if term_lower in n.get('title', '').lower()
                or term_lower in n.get('body', '').lower()
            ]

        serializer = NoteSerializer(raw_notes, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def retrieve(self, request: Request, pk: str | None = None) -> Response:
        """Retrieves a single note by ID."""
        if not pk:
            return Response({'error': 'Note ID required.'}, status=status.HTTP_400_BAD_REQUEST)

        collection = get_notes_collection()
        doc = collection.find_one({'id': pk})
        if not doc:
            return Response(
                {'error': f"Note with ID '{pk}' not found."}, status=status.HTTP_404_NOT_FOUND
            )

        serializer = NoteSerializer(doc)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def create(self, request: Request) -> Response:
        """Validates and persists a new note in MongoDB."""
        serializer = NoteSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data: dict[str, Any] = serializer.validated_data
        doc: dict[str, Any] = {
            **validated_data,
            'createdAt': validated_data['createdAt'].isoformat(),
            'updatedAt': validated_data['updatedAt'].isoformat(),
        }

        collection = get_notes_collection()
        collection.insert_one(doc)

        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def update(self, request: Request, pk: str | None = None) -> Response:
        """Updates an existing note document."""
        if not pk:
            return Response({'error': 'Note ID required.'}, status=status.HTTP_400_BAD_REQUEST)

        collection = get_notes_collection()
        existing = collection.find_one({'id': pk})
        if not existing:
            return Response(
                {'error': f"Note with ID '{pk}' not found."}, status=status.HTTP_404_NOT_FOUND
            )

        serializer = NoteSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data: dict[str, Any] = serializer.validated_data
        update_doc: dict[str, Any] = {
            **validated_data,
            'createdAt': validated_data['createdAt'].isoformat(),
            'updatedAt': validated_data['updatedAt'].isoformat(),
        }

        collection.update_one({'id': pk}, {'$set': update_doc})
        return Response(serializer.data, status=status.HTTP_200_OK)

    def destroy(self, request: Request, pk: str | None = None) -> Response:
        """Permanently removes a note."""
        if not pk:
            return Response({'error': 'Note ID required.'}, status=status.HTTP_400_BAD_REQUEST)

        collection = get_notes_collection()
        existing = collection.find_one({'id': pk})
        if not existing:
            return Response(
                {'error': f"Note with ID '{pk}' not found."}, status=status.HTTP_404_NOT_FOUND
            )

        collection.delete_many({'id': pk})
        return Response(status=status.HTTP_204_NO_CONTENT)


class FolderViewSet(viewsets.ViewSet):
    """ViewSet managing Folder CRUD operations against MongoDB."""

    def list(self, request: Request) -> Response:
        """Retrieves all folders."""
        collection = get_folders_collection()
        raw_folders = list(collection.find({}))
        serializer = FolderSerializer(raw_folders, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def retrieve(self, request: Request, pk: str | None = None) -> Response:
        """Retrieves a single folder by ID."""
        if not pk:
            return Response({'error': 'Folder ID required.'}, status=status.HTTP_400_BAD_REQUEST)

        collection = get_folders_collection()
        doc = collection.find_one({'id': pk})
        if not doc:
            return Response(
                {'error': f"Folder with ID '{pk}' not found."}, status=status.HTTP_404_NOT_FOUND
            )

        serializer = FolderSerializer(doc)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def create(self, request: Request) -> Response:
        """Creates a new folder."""
        serializer = FolderSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data: dict[str, Any] = serializer.validated_data
        doc: dict[str, Any] = {
            **validated_data,
            'createdAt': validated_data['createdAt'].isoformat(),
            'updatedAt': validated_data['updatedAt'].isoformat(),
        }

        collection = get_folders_collection()
        collection.insert_one(doc)

        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def update(self, request: Request, pk: str | None = None) -> Response:
        """Updates folder metadata."""
        if not pk:
            return Response({'error': 'Folder ID required.'}, status=status.HTTP_400_BAD_REQUEST)

        collection = get_folders_collection()
        existing = collection.find_one({'id': pk})
        if not existing:
            return Response(
                {'error': f"Folder with ID '{pk}' not found."}, status=status.HTTP_404_NOT_FOUND
            )

        serializer = FolderSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data: dict[str, Any] = serializer.validated_data
        update_doc: dict[str, Any] = {
            **validated_data,
            'createdAt': validated_data['createdAt'].isoformat(),
            'updatedAt': validated_data['updatedAt'].isoformat(),
        }

        collection.update_one({'id': pk}, {'$set': update_doc})
        return Response(serializer.data, status=status.HTTP_200_OK)

    def destroy(self, request: Request, pk: str | None = None) -> Response:
        """Deletes a user-created folder."""
        if not pk:
            return Response({'error': 'Folder ID required.'}, status=status.HTTP_400_BAD_REQUEST)

        collection = get_folders_collection()
        existing = collection.find_one({'id': pk})
        if not existing:
            return Response(
                {'error': f"Folder with ID '{pk}' not found."}, status=status.HTTP_404_NOT_FOUND
            )

        if existing.get('isSystem', False):
            return Response(
                {'error': 'System default folders cannot be deleted.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        collection.delete_many({'id': pk})
        return Response(status=status.HTTP_204_NO_CONTENT)


class BatchSyncView(APIView):
    """Two-way batch reconciliation endpoint for offline-first Mac & iPad synchronization."""

    def post(self, request: Request) -> Response:
        serializer = BatchSyncSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        notes_data: list[dict[str, Any]] = serializer.validated_data.get('notes', [])
        folders_data: list[dict[str, Any]] = serializer.validated_data.get('folders', [])

        notes_col = get_notes_collection()
        folders_col = get_folders_collection()

        synced_notes_count = 0
        for note in notes_data:
            incoming_updated = _parse_iso_datetime(note.get('updatedAt'))
            doc = {
                **note,
                'createdAt': note['createdAt'].isoformat(),
                'updatedAt': note['updatedAt'].isoformat(),
            }
            existing = notes_col.find_one({'id': note['id']})
            if existing:
                existing_updated = _parse_iso_datetime(existing.get('updatedAt'))
                if (
                    incoming_updated is None
                    or existing_updated is None
                    or incoming_updated >= existing_updated
                ):
                    notes_col.update_one({'id': note['id']}, {'$set': doc})
            else:
                notes_col.insert_one(doc)
            synced_notes_count += 1

        synced_folders_count = 0
        for folder in folders_data:
            incoming_f_updated = _parse_iso_datetime(folder.get('updatedAt'))
            f_doc = {
                **folder,
                'createdAt': folder['createdAt'].isoformat(),
                'updatedAt': folder['updatedAt'].isoformat(),
            }
            existing_f = folders_col.find_one({'id': folder['id']})
            if existing_f:
                existing_f_updated = _parse_iso_datetime(existing_f.get('updatedAt'))
                if (
                    incoming_f_updated is None
                    or existing_f_updated is None
                    or incoming_f_updated >= existing_f_updated
                ):
                    folders_col.update_one({'id': folder['id']}, {'$set': f_doc})
            else:
                folders_col.insert_one(f_doc)
            synced_folders_count += 1

        # Return full merged state so Mac and iPad stay in sync
        merged_notes = NoteSerializer(list(notes_col.find({})), many=True).data
        merged_folders = FolderSerializer(list(folders_col.find({})), many=True).data

        return Response(
            {
                'status': 'success',
                'syncedNotes': synced_notes_count,
                'syncedFolders': synced_folders_count,
                'notes': merged_notes,
                'folders': merged_folders,
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


def _get_releases_dir() -> Path:
    """Resolves the directory containing built Mac (.dmg/.zip) and iPad (.ipa) installers."""
    env_dir = os.getenv('RELEASES_DIR')
    if env_dir:
        return Path(env_dir).resolve()
    return (Path(settings.BASE_DIR).parent / 'releases').resolve()


class DownloadPortalView(APIView):
    """Serves a responsive Apple-styled HTML download portal for Mac and iPad installers."""

    def get(self, request: Request) -> HttpResponse:
        releases_dir = _get_releases_dir()
        files: list[dict[str, Any]] = []
        if releases_dir.exists() and releases_dir.is_dir():
            for entry in sorted(releases_dir.iterdir()):
                if entry.is_file() and not entry.name.startswith('.'):
                    size_mb = round(entry.stat().st_size / (1024 * 1024), 2)
                    ext = entry.suffix.lower()
                    platform_label = (
                        'macOS Installer'
                        if ext in ('.dmg', '.zip')
                        else ('iPadOS / iOS Package' if ext == '.ipa' else 'Release Artifact')
                    )
                    files.append(
                        {
                            'name': entry.name,
                            'size_mb': size_mb,
                            'platform': platform_label,
                        }
                    )

        cards_html = ''
        if files:
            for item in files:
                cards_html += f"""
                <div class="card">
                    <div>
                        <span class="badge">{item['platform']}</span>
                        <h3>{item['name']}</h3>
                        <p class="meta">{item['size_mb']} MB</p>
                    </div>
                    <a class="btn" href="/download/{item['name']}">Download</a>
                </div>
                """
        else:
            cards_html = """
            <div class="empty">
                <p>No installer packages found in <code>releases/</code> yet. Run the build script to generate <code>.dmg</code> and <code>.ipa</code> packages.</p>
            </div>
            """

        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Lusid — Mac &amp; iPad Downloads</title>
    <style>
        :root {{
            --gold: #ECA825;
            --bg: #141416;
            --card: #1E1E22;
            --text: #F5F5F7;
            --muted: #98989D;
            --border: #2C2C30;
        }}
        * {{ box-sizing: border-box; font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif; }}
        body {{ margin: 0; background: var(--bg); color: var(--text); padding: 40px 20px; }}
        .container {{ max-width: 760px; margin: 0 auto; }}
        .header {{ display: flex; align-items: center; gap: 16px; margin-bottom: 28px; }}
        .icon {{ width: 56px; height: 56px; border-radius: 14px; background: linear-gradient(180deg, #F5C242 0%, #ECA825 100%); display: flex; align-items: center; justify-content: center; font-size: 28px; font-weight: bold; color: #1C1C1E; }}
        h1 {{ margin: 0; font-size: 26px; font-weight: 700; }}
        p.sub {{ margin: 4px 0 0; color: var(--muted); font-size: 14px; }}
        .card {{ background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 18px 20px; display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }}
        .badge {{ display: inline-block; font-size: 11px; font-weight: 600; text-transform: uppercase; color: var(--gold); letter-spacing: 0.5px; margin-bottom: 4px; }}
        h3 {{ margin: 0; font-size: 16px; }}
        .meta {{ margin: 4px 0 0; color: var(--muted); font-size: 13px; }}
        .btn {{ background: var(--gold); color: #141416; text-decoration: none; font-weight: 600; font-size: 14px; padding: 10px 18px; border-radius: 8px; }}
        .guide {{ margin-top: 32px; background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 20px; font-size: 14px; line-height: 1.6; color: var(--muted); }}
        .guide h4 {{ color: var(--text); margin-top: 0; }}
        code {{ background: #2C2C30; color: var(--gold); padding: 2px 6px; border-radius: 4px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="icon">📝</div>
            <div>
                <h1>Lusid for macOS &amp; iPadOS</h1>
                <p class="sub">Direct Download &amp; Local Sync Server Portal</p>
            </div>
        </div>
        {cards_html}
        <div class="guide">
            <h4>Installation Guide</h4>
            <ul>
                <li><strong>macOS (.dmg / .zip):</strong> Open the downloaded <code>.dmg</code> and drag <strong>Lusid.app</strong> to your <code>/Applications</code> folder. If macOS Gatekeeper prompts on first launch, right-click the app and select <strong>Open</strong> (or run <code>xattr -cr /Applications/Lusid.app</code>).</li>
                <li><strong>iPadOS (.ipa):</strong> Install onto your iPad using <strong>AltStore</strong>, <strong>Sideloadly</strong>, or <strong>Xcode &rarr; Window &rarr; Devices and Simulators</strong> using your free Apple ID.</li>
                <li><strong>Cross-Device Sync:</strong> Open the Sync Settings icon in the top toolbar and set the Server URL to <code>http://{request.get_host()}/api</code>.</li>
            </ul>
        </div>
    </div>
</body>
</html>"""
        return HttpResponse(html, content_type='text/html')


class DownloadArtifactView(APIView):
    """Streams an installer file (.dmg, .zip, .ipa) from the releases directory."""

    def get(self, request: HttpRequest, filename: str) -> FileResponse:
        releases_dir = _get_releases_dir()
        safe_name = os.path.basename(filename)
        target_path = (releases_dir / safe_name).resolve()

        if not str(target_path).startswith(str(releases_dir)) or not target_path.is_file():
            raise Http404(f"Artifact '{safe_name}' not found.")

        return FileResponse(
            open(target_path, 'rb'),
            as_attachment=True,
            filename=safe_name,
        )
