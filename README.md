# Lusid for macOS & iPadOS

**Lusid** is a sleek, distraction-free notes application inspired by native **Apple Notes**, built with **Flutter (macOS, iPadOS/iOS, and Web PWA)** and **Provider** state management following a strict feature-first architecture, backed by a containerized **Django REST Framework + MongoDB** two-way sync server and installer download portal.

## Key Features

- **macOS & iPadOS Adaptive Interface**:
  - **macOS Desktop**: Unified titlebar with traffic light buttons, sidebar collapse button, view mode switchers (List & Gallery), compose button, checklist toggle, rich formatting palette, table editor, code block editor, media attachments, search, and theme mode switcher.
  - **iPadOS Multitasking**: Automatically adapts across **Wide Landscape (3-column)**, **Portrait / Split View (2-column + frosted slide-over sidebar drawer)**, and **Slide Over / Compact (1-column drill-down with `< Notes` back button)** with `SafeArea` insets and touch-friendly targets.
- **Rich Note Editor**:
  - Live interactive Markdown conversion, auto-title first line, interactive circular checkboxes, rich typography (Title, Heading, Subheading, Body, Monospaced), multi-line syntax-highlighted code blocks with language selector & copy button, inline multi-column tables with hover row/column insertion/deletion handles, file attachments, and password locking.
- **Cross-Device Two-Way Sync & Offline-First Persistence**:
  - Instant zero-latency local persistence on both Mac and iPad, plus two-way Last-Write-Wins batch synchronization with the Dockerized **Django REST Framework + MongoDB** backend.

---

## Building & Packaging Installers (`.dmg`, `.zip`, `.ipa`, Web PWA)

Run the automated packaging script to generate all release artifacts inside `releases/`:

```bash
./mac_notes_app/scripts/build_and_package.sh
```

This produces:
- `releases/Lusid-macOS-v1.0.0.dmg` — Drag-and-drop macOS Disk Image installer (`Lusid.app` -> `/Applications`).
- `releases/Lusid-macOS-v1.0.0.zip` — Zipped macOS `.app` bundle.
- `releases/Lusid-iPadOS-v1.0.0.ipa` — iPadOS / iOS application archive for **AltStore**, **Sideloadly**, or **Xcode Direct Install**.
- `releases/Lusid-Web-PWA-v1.0.0.zip` — Standalone Web PWA bundle for Safari **Add to Home Screen** on iPad.

---

## Installing on Your Mac & iPad

### 1. Install on macOS
1. Open `releases/Lusid-macOS-v1.0.0.dmg` (or download from GitHub Releases / the local `/download/` portal).
2. Drag **Lusid.app** into the **Applications** folder.
3. If macOS Gatekeeper prompts on first launch (since it uses free ad-hoc signing), right-click **Lusid.app** and choose **Open**, or run:
   ```bash
   xattr -cr /Applications/Lusid.app
   ```

### 2. Install on iPad
- **Option A — AltStore or Sideloadly (`.ipa`)**:
  Download `Lusid-iPadOS-v1.0.0.ipa` from GitHub Releases or `http://<your-mac-ip>:8000/download/` and install via **AltStore** or **Sideloadly** using your free Apple ID.
- **Option B — Direct USB / Wi-Fi Install via Xcode**:
  Connect your iPad to your Mac, open `mac_notes_app/ios/Runner.xcworkspace` in Xcode, select your personal Team under **Signing & Capabilities**, and press **Run** (`Cmd+R`) or run:
  ```bash
  cd mac_notes_app && flutter run --release -d <your-ipad-device-id>
  ```

---

## Running the Containerized Sync & Download Server (Docker Compose)

To sync notes between your Mac and iPad (and serve the `/download/` installer portal over your local network or cloud host):

```bash
docker compose up --build -d
```

- **Download Portal**: Open `http://localhost:8000/download/` (or `http://<your-mac-lan-ip>:8000/download/` on your iPad).
- **API Health Check**: `http://localhost:8000/api/health/`
- **Configure in App**: Click the **Cloud Sync** icon in the Lusid toolbar, enter `http://<your-mac-lan-ip>:8000/api`, and click **Sync Now**.

---

## CI/CD Pipeline Architecture (GitHub Actions)

This repository includes a 5-stage automated CI/CD pipeline under `.github/workflows/`:

1. **Stage 1 — Code Quality & Static Analysis (`.github/workflows/ci-quality.yml`)**:
   - Enforces file headers (`Author / Date / Description`) and zero placeholder `TODO` comments via `scripts/verify_headers.py`.
   - Runs `dart format --set-exit-if-changed` and `flutter analyze --fatal-infos --fatal-warnings` on `mac_notes_app`.
   - Runs **Ruff** (`ruff check .` & `ruff format --check .`) and `python manage.py check` on `backend`.
   - Lints shell scripts with **ShellCheck**, `backend/Dockerfile` with **Hadolint** (`.hadolint.yaml`), and `docker-compose.yml` schema.
2. **Stage 2 — Automated Testing & Coverage (`.github/workflows/ci-tests.yml`)**:
   - Runs `flutter test --coverage` and enforces an **80% minimum coverage gate** via `scripts/verify_flutter_coverage.py`.
   - Spins up a live `mongo:7.0` service container and runs Django API & two-way sync tests with an **80% minimum coverage gate** (`coverage report --fail-under=80`).
   - Executes an end-to-end **Docker Compose Smoke Test** (`scripts/smoke_test_compose.sh`) against `/api/health/`, `/api/sync/`, `/api/notes/`, `/api/folders/`, and `/download/`.
3. **Stage 3 — Security & Dependency Auditing (`.github/workflows/ci-security.yml` & `.github/dependabot.yml`)**:
   - Runs **Gitleaks** secret scanning (`.gitleaks.toml`), **`pip-audit`** on Python dependencies, **Google OSV-Scanner** & `dart pub outdated` on Flutter dependencies, and **Aqua Security Trivy** on the built backend container image (on every push/PR and weekly Mondays at `08:00 UTC`).
4. **Stage 4 — Multi-Platform Artifact Packaging (`.github/workflows/cd-package.yml`)**:
   - Builds macOS `.dmg` & `.zip` (with ad-hoc signing by default or Apple Developer ID notarization via Secrets), iPadOS `.ipa`, Web PWA `.zip`, and `SHA256SUMS.txt` on `macos-latest`.
5. **Stage 5 — Release & Deployment Automation (`.github/workflows/cd-release.yml`)**:
   - Publishes multi-arch (`linux/amd64`, `linux/arm64`) backend images to **GitHub Container Registry** (`ghcr.io/mackdr91/my_notes_app_macos-backend`).
   - Deploys the live Web PWA to **GitHub Pages**.
   - Creates automated **GitHub Releases** on `v*.*.*` tags with all installer packages and `SHA256SUMS.txt` attached.
