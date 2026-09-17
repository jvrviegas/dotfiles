#!/usr/bin/env python3
"""Normalize cross-machine paths in coding-agent sessions and Git metadata."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
import tempfile
from collections import defaultdict
from pathlib import Path

PRUNED_DIRS = {
    ".next",
    ".parcel-cache",
    ".stversions",
    ".turbo",
    ".venv",
    "node_modules",
    "venv",
}


def parse_mappings(values: list[str]) -> list[tuple[str, str]]:
    mappings: list[tuple[str, str]] = []
    for value in values:
        if "=" not in value:
            raise ValueError(f"invalid mapping {value!r}; expected OLD=NEW")
        old, new = value.split("=", 1)
        if not old or not new:
            raise ValueError(f"invalid mapping {value!r}; paths cannot be empty")
        mappings.append((old.rstrip("/"), new.rstrip("/")))
    return sorted(mappings, key=lambda item: len(item[0]), reverse=True)


def rewrite_path(value: str, mappings: list[tuple[str, str]]) -> str:
    for old, new in mappings:
        if value == old or value.startswith(old + "/"):
            return new + value[len(old) :]
    return value


def rewrite_json(value: object, mappings: list[tuple[str, str]]) -> object:
    if isinstance(value, dict):
        return {key: rewrite_json(item, mappings) for key, item in value.items()}
    if isinstance(value, list):
        return [rewrite_json(item, mappings) for item in value]
    if isinstance(value, str):
        return rewrite_path(value, mappings)
    return value


def encoded_prefix(path: str, kind: str) -> str:
    if kind == "pi":
        safe = re.sub(r"[/\\:]", "-", path.lstrip("/\\"))
        return f"--{safe}"
    return re.sub(r"[^A-Za-z0-9]", "-", path)


def normalize_bucket(name: str, kind: str, mappings: list[tuple[str, str]]) -> str:
    for old, new in mappings:
        old_prefix = encoded_prefix(old, kind)
        if name == old_prefix or name.startswith(old_prefix + "-"):
            return encoded_prefix(new, kind) + name[len(old_prefix) :]
    return name


def choose_candidates(
    source: Path, kind: str, mappings: list[tuple[str, str]]
) -> tuple[dict[Path, Path], int]:
    grouped: dict[Path, list[Path]] = defaultdict(list)
    if not source.exists():
        return {}, 0

    for bucket in sorted(source.iterdir()):
        if not bucket.is_dir() or bucket.name == ".stversions":
            continue
        target_bucket = normalize_bucket(bucket.name, kind, mappings)
        for path in bucket.rglob("*"):
            if path.is_file() and not path.is_symlink():
                grouped[Path(target_bucket) / path.relative_to(bucket)].append(path)

    selected: dict[Path, Path] = {}
    collisions = 0
    for relative, candidates in grouped.items():
        if len(candidates) > 1:
            collisions += len(candidates) - 1
        # Session logs are append-oriented, so prefer the largest copy. Use
        # mtime only as a deterministic tie-breaker for equally sized files.
        selected[relative] = max(
            candidates, key=lambda path: (path.stat().st_size, path.stat().st_mtime_ns)
        )
    return selected, collisions


def normalized_file(path: Path, output: Path, mappings: list[tuple[str, str]]) -> int:
    rewritten = 0
    if path.suffix == ".jsonl":
        with path.open("r", encoding="utf-8", errors="surrogateescape") as source_file, output.open(
            "w", encoding="utf-8", errors="surrogateescape"
        ) as target_file:
            for line in source_file:
                try:
                    value = json.loads(line)
                except json.JSONDecodeError:
                    target_file.write(line)
                    continue
                normalized = rewrite_json(value, mappings)
                if normalized != value:
                    rewritten += 1
                target_file.write(json.dumps(normalized, ensure_ascii=False, separators=(",", ":")))
                target_file.write("\n")
    elif path.suffix == ".json":
        try:
            with path.open("r", encoding="utf-8", errors="surrogateescape") as source_file:
                value = json.load(source_file)
        except (json.JSONDecodeError, UnicodeDecodeError):
            shutil.copyfile(path, output)
        else:
            normalized = rewrite_json(value, mappings)
            if normalized != value:
                rewritten += 1
            with output.open("w", encoding="utf-8", errors="surrogateescape") as target_file:
                json.dump(normalized, target_file, ensure_ascii=False, separators=(",", ":"))
                target_file.write("\n")
    else:
        shutil.copyfile(path, output)
    shutil.copystat(path, output, follow_symlinks=False)
    return rewritten


def same_file(left: Path, right: Path) -> bool:
    if not right.exists() or left.stat().st_size != right.stat().st_size:
        return False
    with left.open("rb") as left_file, right.open("rb") as right_file:
        while True:
            left_chunk = left_file.read(1024 * 1024)
            right_chunk = right_file.read(1024 * 1024)
            if left_chunk != right_chunk:
                return False
            if not left_chunk:
                return True


def import_sessions(
    source: Path,
    destination: Path,
    backup: Path | None,
    kind: str,
    mappings: list[tuple[str, str]],
) -> None:
    selected, collisions = choose_candidates(source, kind, mappings)
    copied = unchanged = backed_up = rewritten = 0

    for relative, source_file in sorted(selected.items()):
        destination_file = destination / relative
        destination_file.parent.mkdir(parents=True, exist_ok=True)
        fd, temporary_name = tempfile.mkstemp(prefix=".work-sync-", dir=destination_file.parent)
        os.close(fd)
        temporary = Path(temporary_name)
        try:
            rewritten += normalized_file(source_file, temporary, mappings)
            if same_file(temporary, destination_file):
                unchanged += 1
                temporary.unlink()
                continue
            if destination_file.exists() and backup is not None:
                backup_file = backup / relative
                backup_file.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(destination_file, backup_file)
                backed_up += 1
            os.replace(temporary, destination_file)
            copied += 1
        finally:
            temporary.unlink(missing_ok=True)

    print(
        f"{kind}: selected={len(selected)} copied={copied} unchanged={unchanged} "
        f"source-collisions={collisions} backups={backed_up} rewritten-lines={rewritten}"
    )


def is_git_structural_file(relative: Path) -> bool:
    parts = relative.parts
    if relative.name == ".git":
        return True
    for index, part in enumerate(parts):
        if part != ".git":
            continue
        tail = parts[index + 1 :]
        if tail in {("config",), ("config.worktree",), ("objects", "info", "alternates")}:
            return True
        if len(tail) >= 3 and tail[0] == "worktrees" and tail[-1] == "gitdir":
            return True
        if len(tail) >= 2 and tail[0] == "modules" and tail[-1] in {
            "config",
            "config.worktree",
        }:
            return True
    return False


def normalize_git_paths(root: Path, mappings: list[tuple[str, str]]) -> None:
    changed = 0
    occurrences = 0
    old_values = [(old.encode(), new.encode()) for old, new in mappings]

    for current, directories, files in os.walk(root):
        directories[:] = [name for name in directories if name not in PRUNED_DIRS]
        current_path = Path(current)
        for name in files:
            path = current_path / name
            relative = path.relative_to(root)
            if not is_git_structural_file(relative) or path.is_symlink():
                continue
            try:
                data = path.read_bytes()
            except OSError:
                continue
            normalized = data
            count = 0
            for old, new in old_values:
                count += normalized.count(old)
                normalized = normalized.replace(old, new)
            if normalized == data:
                continue
            if b"\0" in normalized:
                print(f"git: skipped binary structural file {relative}", file=sys.stderr)
                continue
            with path.open("r+b") as target:
                target.write(normalized)
                target.truncate()
            changed += 1
            occurrences += count

    print(f"git: normalized-files={changed} path-occurrences={occurrences}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    sessions = subparsers.add_parser("sessions")
    sessions.add_argument("--source", type=Path, required=True)
    sessions.add_argument("--destination", type=Path, required=True)
    sessions.add_argument("--backup", type=Path)
    sessions.add_argument("--kind", choices=("pi", "claude"), required=True)
    sessions.add_argument("--map", action="append", default=[], dest="mappings")

    git_paths = subparsers.add_parser("git-paths")
    git_paths.add_argument("--root", type=Path, required=True)
    git_paths.add_argument("--map", action="append", default=[], dest="mappings")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        mappings = parse_mappings(args.mappings)
    except ValueError as error:
        print(f"work-sync normalize: {error}", file=sys.stderr)
        return 2

    if args.command == "sessions":
        import_sessions(
            args.source, args.destination, args.backup, args.kind, mappings
        )
    else:
        normalize_git_paths(args.root, mappings)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
