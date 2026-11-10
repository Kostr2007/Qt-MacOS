#!/usr/bin/env python3
"""Check the source snapshot's local Markdown links and publication boundaries."""
import re
import subprocess
from pathlib import Path
from urllib.parse import unquote


def main():
    root = Path(__file__).resolve().parent.parent
    result = subprocess.run(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
                            cwd=root, capture_output=True, check=True)
    paths = sorted(set(result.stdout.decode().split("\0")) - {""})
    errors = []
    ignored_roots = {"references", "reference-materials", "research", "recordings", "captures",
                     "artifacts", "local", "qt-sdk", ".qt-sdk", ".cache"}
    for relative in paths:
        path = root / relative
        if path.parts[len(root.parts)] in ignored_roots or relative.startswith(("build/", "build-example/")):
            errors.append(f"Local artifact is tracked: {relative}")
        if not path.is_file():
            errors.append(f"Missing source: {relative}")
            continue
        if path.stat().st_size > 20 * 1024 * 1024:
            errors.append(f"Oversized repository file (>20 MiB): {relative}")
        if path.suffix != ".md":
            continue
        source = re.sub(r"```.*?```", "", path.read_text(), flags=re.S)
        for target in re.findall(r"!?\[[^\]]*\]\(([^)]+)\)", source):
            target = target.split(' "')[0].strip("<>")
            if ":" in target or target.startswith("#"):
                continue
            target = unquote(target.split("#")[0])
            if target and not (path.parent / target).exists():
                errors.append(f"Broken link: {relative} -> {target}")
    if errors:
        raise SystemExit("\n".join(errors))
    print(f"Release boundaries and Markdown links passed ({len(paths)} files).")


if __name__ == "__main__":
    main()
