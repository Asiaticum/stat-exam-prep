#!/usr/bin/env python3
"""OS-aware wrapper for skill helper scripts."""

from __future__ import annotations

import platform
import subprocess
import sys
from pathlib import Path


SCRIPT_MAP = {
    "convert_to_jpg": {
        "unix": "convert_to_jpg.sh",
        "windows": "convert_to_jpg.ps1",
    },
    "extract_figures": {
        "unix": "extract_figures.sh",
        "windows": "extract_figures.ps1",
    },
}


def build_command(script_path: Path, args: list[str]) -> list[str]:
    system = platform.system()
    if system == "Windows":
        return [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(script_path),
            *args,
        ]
    if system in {"Darwin", "Linux"}:
        return ["bash", str(script_path), *args]
    raise SystemExit(f"Unsupported operating system: {system}")


def main() -> int:
    if len(sys.argv) < 2:
        available = ", ".join(sorted(SCRIPT_MAP))
        print(
            f"Usage: {Path(sys.argv[0]).name} <tool> [args...]\n"
            f"Available tools: {available}",
            file=sys.stderr,
        )
        return 1

    tool = sys.argv[1]
    tool_args = sys.argv[2:]
    script_names = SCRIPT_MAP.get(tool)
    if script_names is None:
        available = ", ".join(sorted(SCRIPT_MAP))
        print(f"Unknown tool: {tool}. Available tools: {available}", file=sys.stderr)
        return 1

    system = platform.system()
    script_name = script_names["windows"] if system == "Windows" else script_names["unix"]
    script_path = Path(__file__).resolve().with_name(script_name)
    command = build_command(script_path, tool_args)

    result = subprocess.run(command, check=False)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
