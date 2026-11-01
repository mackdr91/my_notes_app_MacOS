# Apple Notes macOS Desktop Replica

A pixel-accurate, feature-complete replica of the native macOS **Apple Notes** desktop application built with **Flutter (macOS desktop)** and **Provider** state management following a strict feature-first architecture, backed by a **Django REST Framework + MongoDB** sync backend and **Firebase** authentication and media storage.

## Key Features

- **macOS Window Integration**: Unified titlebar with traffic light buttons, sidebar collapse button, view mode switchers, compose button, checklist toggle, rich formatting palette, table editor, media attachments, and search.
- **Three-Column Navigation**:
  1. **Sidebar**: Quick Notes, Accounts (iCloud / On My Mac), folder tree with live note count badges, expandable subfolders, tag selector (#tags), and bottom "+ New Folder" action.
  2. **Notes List**: Chronological groupings ("Pinned", "Today", "Previous 7 Days", "Previous 30 Days", monthly/yearly), note preview cards with title, timestamp, body excerpt, and amber pin icon.
  3. **Rich Note Editor**: Auto-title first line, interactive circular checkboxes, rich typography (Title, Heading, Subheading, Body, Monospaced), bold/italic/underline/strikethrough, formatted lists (bullet, numbered, dash), inline multi-column tables, attachments, and password locking.
- **Visual Design**: Native SF Pro typography, authentic Apple Notes amber/gold accent palette (`#ECA825`), light and dark mode support, and frosted macOS materials.
- **Architecture**:
  - **Flutter Desktop Frontend**: Feature-first structure (`features/<feature_name>/{models, services, providers, presentation}`) with Provider.
  - **Local Persistence & Sync**: Instant zero-latency offline-first local cache.
  - **Django REST Framework Backend**: PEP 8 compliant backend connected to MongoDB.
  - **Firebase**: Authentication and storage for media attachments.

## Project Structure

```
my_notes_app_MacOS/
├── mac_notes_app/                    # Flutter macOS Desktop App
│   ├── macos/                        # macOS native runner configuration
│   └── lib/
│       ├── main.dart
│       ├── core/                     # Constants, themes, widgets, utils
│       └── features/
│           ├── folders/              # Folders & Accounts feature
│           ├── notes/                # Notes list & Rich Editor feature
│           ├── tags/                 # Tags feature
│           └── auth_sync/            # Sync & Auth feature
└── backend/                          # Django REST Framework Backend
    ├── manage.py
    ├── notes_backend/                # Core settings & URLs
    └── api/                          # Django REST API connected to MongoDB
```

## Running the App

### macOS Flutter App
```bash
cd mac_notes_app
flutter pub get
flutter run -d macos
```

### Django Backend
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py runserver 8000
```
