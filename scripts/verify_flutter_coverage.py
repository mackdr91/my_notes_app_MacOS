#!/usr/bin/env python3
"""
Author: Domonick Mack
Date: 2026-11-10
Description: Parses Flutter lcov.info coverage output and enforces the minimum line coverage threshold.
"""

from __future__ import annotations

import argparse
import pathlib
import sys


def parse_lcov(lcov_path: pathlib.Path) -> tuple[int, int, list[tuple[str, int, int]]]:
    """Parse an LCOV report and return (total_hit, total_found, per_file_stats)."""
    if not lcov_path.exists():
        raise FileNotFoundError(f"LCOV coverage file not found at {lcov_path}")

    total_lf = 0
    total_lh = 0
    per_file: list[tuple[str, int, int]] = []

    content = lcov_path.read_text(encoding="utf-8")
    for block in content.split("end_of_record"):
        sf = ""
        lf = 0
        lh = 0
        for line in block.strip().splitlines():
            if line.startswith("SF:"):
                sf = line[3:].strip()
            elif line.startswith("LF:"):
                lf = int(line[3:].strip())
            elif line.startswith("LH:"):
                lh = int(line[3:].strip())
        if sf and lf > 0:
            total_lf += lf
            total_lh += lh
            per_file.append((sf, lh, lf))

    return total_lh, total_lf, per_file


def main() -> int:
    """CLI entrypoint for verifying Flutter LCOV line coverage."""
    parser = argparse.ArgumentParser(
        description="Verify Flutter LCOV line coverage meets minimum threshold."
    )
    parser.add_argument(
        "--lcov",
        default="mac_notes_app/coverage/lcov.info",
        help="Path to lcov.info file (default: mac_notes_app/coverage/lcov.info)",
    )
    parser.add_argument(
        "--min-coverage",
        type=float,
        default=80.0,
        help="Minimum required coverage percentage (default: 80.0)",
    )
    args = parser.parse_args()

    lcov_path = pathlib.Path(args.lcov).resolve()
    try:
        total_lh, total_lf, per_file = parse_lcov(lcov_path)
    except Exception as exc:
        print(f"Coverage verification error: {exc}", file=sys.stderr)
        return 1

    if total_lf == 0:
        print("Coverage verification error: 0 instrumentable lines found.", file=sys.stderr)
        return 1

    overall_pct = (total_lh / total_lf) * 100.0
    print("Flutter Line Coverage Summary:")
    print("-" * 78)
    for sf, lh, lf in per_file:
        pct = (lh / lf) * 100.0
        print(f"  {sf:56s} {lh:4d}/{lf:4d} ({pct:5.1f}%)")
    print("-" * 78)
    print(
        f"Total Flutter Coverage: {total_lh}/{total_lf} lines ({overall_pct:.2f}%) "
        f"[Threshold: {args.min_coverage:.1f}%]"
    )

    if overall_pct < args.min_coverage:
        print(
            f"FAILED: Flutter coverage {overall_pct:.2f}% is below minimum "
            f"threshold {args.min_coverage:.1f}%.",
            file=sys.stderr,
        )
        return 1

    print("PASSED: Flutter coverage meets threshold.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
