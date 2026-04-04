#!/usr/bin/env python3
"""Delegate skill helper execution to the shared workbook-builder wrapper."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def main() -> int:
    shared_wrapper = (
        Path(__file__).resolve().parents[2]
        / "stats-workbook-builder"
        / "scripts"
        / "run_tool.py"
    )
    result = subprocess.run([sys.executable, str(shared_wrapper), *sys.argv[1:]], check=False)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
