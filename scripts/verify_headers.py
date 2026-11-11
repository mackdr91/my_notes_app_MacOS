#!/usr/bin/env python3
"""
Author: Domonick Mack
Date: 2026-11-10
Description: CI verification script enforcing file headers (Author/Date/Description) and zero placeholder TODOs.
"""

from __future__ import annotations

import pathlib
import re
import sys
from typing import List, Tuple

REQUIRED_AUTHOR = "Author: Domonick Mack"
DATE_PATTERN = re.compile(r"Date:\s*\d{4}-\d{2}-\d{2}")
DESCRIPTION_PATTERN = re.compile(r"Description:\s*\S+")
TODO_PATTERN = re.compile(r"(//|#)\s*TODO\b", re.IGNORECASE)


def collect_target_files(repo_root: pathlib.Path) -> List[pathlib.Path]:
    """Collect all first-party source, test, script, and infrastructure files."""
    targets: List[pathlib.Path] = []

    # Flutter Dart files (lib & test)
    targets.extend(sorted((repo_root / "mac_notes_app" / "lib").rglob("*.dart")))
    targets.extend(sorted((repo_root / "mac_notes_app" / "test").rglob("*.dart")))

    # Shell scripts
    if (repo_root / "mac_notes_app" / "scripts").exists():
        targets.extend(sorted((repo_root / "mac_notes_app" / "scripts").rglob("*.sh")))
    if (repo_root / "scripts").exists():
        targets.extend(sorted((repo_root / "scripts").rglob("*.sh")))
        targets.extend(sorted((repo_root / "scripts").rglob("*.py")))

    # Backend Python files (excluding virtualenv and cache directories)
    excluded_parts = {"venv", ".venv", "__pycache__", "migrations", ".git"}
    for py_file in sorted((repo_root / "backend").rglob("*.py")):
        if not excluded_parts.intersection(py_file.parts):
            targets.append(py_file)

    # Docker & Compose files
    for infra_rel in [
        "docker-compose.yml",
        "backend/Dockerfile",
        "mac_notes_app/analysis_options.yaml",
        ".hadolint.yaml",
        ".gitleaks.toml",
        ".github/dependabot.yml",
    ]:
        candidate = repo_root / infra_rel
        if candidate.exists():
            targets.append(candidate)

    # GitHub workflow files
    workflows_dir = repo_root / ".github" / "workflows"
    if workflows_dir.exists():
        targets.extend(sorted(workflows_dir.rglob("*.yml")))
        targets.extend(sorted(workflows_dir.rglob("*.yaml")))

    # Deduplicate while preserving deterministic order
    seen: set[pathlib.Path] = set()
    unique_targets: List[pathlib.Path] = []
    for path in targets:
        resolved = path.resolve()
        if resolved not in seen:
            seen.add(resolved)
            unique_targets.append(path)

    return unique_targets


def validate_file(file_path: pathlib.Path, repo_root: pathlib.Path) -> List[str]:
    """Validate that a file contains the mandatory header and no placeholder TODO comments."""
    errors: List[str] = []
    rel_path = file_path.relative_to(repo_root)

    try:
        content = file_path.read_text(encoding="utf-8")
    except OSError as exc:
        return [f"{rel_path}: Failed to read file ({exc})"]

    lines = content.splitlines()
    header_window = "\n".join(lines[:12])

    if REQUIRED_AUTHOR not in header_window:
        errors.append(f"{rel_path}: Missing '{REQUIRED_AUTHOR}' in top 12 lines.")
    if not DATE_PATTERN.search(header_window):
        errors.append(f"{rel_path}: Missing 'Date: YYYY-MM-DD' in top 12 lines.")
    if not DESCRIPTION_PATTERN.search(header_window):
        errors.append(f"{rel_path}: Missing 'Description: <summary>' in top 12 lines.")

    # Skip checking this script's own regex definition line for TODO matches
    if file_path.name != "verify_headers.py":
        for line_num, line in enumerate(lines, start=1):
            if TODO_PATTERN.search(line):
                errors.append(
                    f"{rel_path}:{line_num}: Placeholder TODO comment found: {line.strip()}"
                )

    return errors


def main() -> int:
    """Entrypoint for CI header and code completeness verification."""
    repo_root = pathlib.Path(__file__).resolve().parent.parent
    target_files = collect_target_files(repo_root)

    all_errors: List[Tuple[pathlib.Path, List[str]]] = []
    for target in target_files:
        file_errors = validate_file(target, repo_root)
        if file_errors:
            all_errors.append((target, file_errors))

    if all_errors:
        print("Header & Completeness Verification FAILED:", file=sys.stderr)
        for _, errs in all_errors:
            for err in errs:
                print(f"  - {err}", file=sys.stderr)
        return 1

    print(
        f"Verified {len(target_files)} files: All headers ('{REQUIRED_AUTHOR}') "
        "and completeness checks passed."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
