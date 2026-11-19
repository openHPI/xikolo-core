#!/usr/bin/env python3
"""Inventory reachable local SCSS selectors and find missing literal class usage."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


IMPORT_RE = re.compile(r"@(import|use|forward)\s+([^;]+);")
QUOTED_RE = re.compile(r"[\"']([^\"']+)[\"']")
CLASS_RE = re.compile(r"\.([A-Za-z_-][A-Za-z0-9_-]*)")
SEARCH_EXTENSIONS = {
    ".erb",
    ".haml",
    ".html",
    ".js",
    ".jsx",
    ".rb",
    ".slim",
    ".ts",
    ".tsx",
}
IGNORED_DIRS = {
    ".git",
    ".bundle",
    "app/assets/builds",
    "app/assets/stylesheets",
    "coverage",
    "log",
    "node_modules",
    "public/assets",
    "tmp",
    "vendor",
}


@dataclass(frozen=True)
class Selector:
    source: Path
    line: int
    text: str
    dynamic: bool

    @property
    def classes(self) -> tuple[str, ...]:
        without_interpolation = re.sub(r"#\{.*?\}", "", self.text)
        return tuple(dict.fromkeys(CLASS_RE.findall(without_interpolation)))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Resolve local Sass imports and flag selectors whose class tokens have no "
            "literal use. Candidates always require manual Rails/runtime verification."
        )
    )
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument(
        "--stylesheet-root",
        type=Path,
        default=Path("app/assets/stylesheets"),
    )
    parser.add_argument(
        "--entrypoint",
        type=Path,
        action="append",
        help="Sass entrypoint, repeatable (default: app/assets/stylesheets/main.scss)",
    )
    parser.add_argument(
        "--search-root",
        type=Path,
        action="append",
        help="Template/code root, repeatable (default: app, engines)",
    )
    parser.add_argument(
        "--only",
        choices=("all", "candidates", "seen", "dynamic"),
        default="candidates",
    )
    parser.add_argument("--format", choices=("tsv", "json"), default="tsv")
    return parser.parse_args()


def absolute(repo: Path, path: Path) -> Path:
    return path.resolve() if path.is_absolute() else (repo / path).resolve()


def rel(path: Path, repo: Path) -> str:
    try:
        return str(path.relative_to(repo))
    except ValueError:
        return str(path)


def strip_comments(text: str) -> str:
    output: list[str] = []
    index = 0
    quote: str | None = None
    escaped = False
    while index < len(text):
        char = text[index]
        if escaped:
            output.append(char)
            escaped = False
            index += 1
            continue
        if char == "\\" and quote:
            output.append(char)
            escaped = True
            index += 1
            continue
        if quote:
            output.append(char)
            if char == quote:
                quote = None
            index += 1
            continue
        if char in "\"'":
            output.append(char)
            quote = char
            index += 1
            continue
        if text.startswith("/*", index):
            end = text.find("*/", index + 2)
            end = len(text) if end == -1 else end + 2
            output.extend("\n" if item == "\n" else " " for item in text[index:end])
            index = end
            continue
        if text.startswith("//", index):
            end = text.find("\n", index + 2)
            end = len(text) if end == -1 else end
            output.extend(" " for _ in text[index:end])
            index = end
            continue
        output.append(char)
        index += 1
    return "".join(output)


def import_targets(path: Path) -> list[str]:
    text = strip_comments(path.read_text(encoding="utf-8", errors="replace"))
    targets: list[str] = []
    for match in IMPORT_RE.finditer(text):
        targets.extend(QUOTED_RE.findall(match.group(2)))
    return targets


def resolve_local_import(target: str, current: Path, root: Path) -> Path | None:
    if target.startswith(("http:", "https:", "url(")) or target.endswith(".css"):
        return None

    raw = Path(target)
    bases = [current.parent / raw, root / raw]
    candidates: list[Path] = []
    for base in bases:
        suffixes = [base] if base.suffix else [base.with_suffix(".scss"), base / "index.scss"]
        for candidate in suffixes:
            candidates.append(candidate)
            candidates.append(candidate.with_name("_" + candidate.name))

    root_resolved = root.resolve()
    for candidate in candidates:
        candidate = candidate.resolve()
        try:
            candidate.relative_to(root_resolved)
        except ValueError:
            continue
        if candidate.is_file():
            return candidate
    return None


def reachable_files(entrypoints: Iterable[Path], root: Path) -> tuple[set[Path], dict[Path, list[Path]]]:
    reachable: set[Path] = set()
    graph: dict[Path, list[Path]] = defaultdict(list)
    pending = list(entrypoints)
    while pending:
        path = pending.pop()
        if path in reachable:
            continue
        if not path.is_file():
            raise FileNotFoundError(f"Sass entrypoint not found: {path}")
        reachable.add(path)
        for target in import_targets(path):
            imported = resolve_local_import(target, path, root)
            if imported:
                graph[path].append(imported)
                pending.append(imported)
    return reachable, graph


def split_selectors(header: str) -> list[str]:
    parts: list[str] = []
    start = 0
    depth = 0
    quote: str | None = None
    escaped = False
    for index, char in enumerate(header):
        if escaped:
            escaped = False
            continue
        if char == "\\":
            escaped = True
            continue
        if quote:
            if char == quote:
                quote = None
            continue
        if char in "\"'":
            quote = char
        elif char in "([":
            depth += 1
        elif char in ")]":
            depth = max(0, depth - 1)
        elif char == "," and depth == 0:
            parts.append(header[start:index].strip())
            start = index + 1
    parts.append(header[start:].strip())
    return [part for part in parts if part]


def expand_selectors(header: str, parents: tuple[str, ...]) -> tuple[str, ...]:
    children = split_selectors(header)
    if not parents:
        return tuple(children)
    expanded: list[str] = []
    for parent in parents:
        for child in children:
            expanded.append(child.replace("&", parent) if "&" in child else f"{parent} {child}")
    return tuple(expanded)


def selectors_in_file(path: Path) -> list[Selector]:
    text = strip_comments(path.read_text(encoding="utf-8", errors="replace"))
    selectors: list[Selector] = []
    stack: list[tuple[str, ...]] = []
    statement_start = 0
    line = 1
    index = 0
    quote: str | None = None
    escaped = False

    while index < len(text):
        char = text[index]
        if char == "\n":
            line += 1
        if escaped:
            escaped = False
            index += 1
            continue
        if char == "\\":
            escaped = True
            index += 1
            continue
        if quote:
            if char == quote:
                quote = None
            index += 1
            continue
        if char in "\"'":
            quote = char
            index += 1
            continue
        if char == "#" and index + 1 < len(text) and text[index + 1] == "{":
            interpolation_end = text.find("}", index + 2)
            if interpolation_end == -1:
                break
            line += text[index:interpolation_end].count("\n")
            index = interpolation_end + 1
            continue
        if char == "{":
            header = text[statement_start:index].strip()
            parents = stack[-1] if stack else ()
            if not header or header.startswith("@") or header.startswith("$"):
                current = parents
            else:
                current = expand_selectors(header, parents)
                for selector_text in current:
                    if CLASS_RE.search(selector_text):
                        selectors.append(
                            Selector(path, line, " ".join(selector_text.split()), "#{" in selector_text)
                        )
            stack.append(current)
            statement_start = index + 1
        elif char == "}":
            if stack:
                stack.pop()
            statement_start = index + 1
        elif char == ";":
            statement_start = index + 1
        index += 1

    return list(dict.fromkeys(selectors))


def ignored(path: Path, repo: Path, stylesheet_root: Path) -> bool:
    try:
        relative = path.relative_to(repo)
    except ValueError:
        return False
    posix = relative.as_posix()
    if path.is_relative_to(stylesheet_root):
        return True
    return any(posix == item or posix.startswith(item + "/") for item in IGNORED_DIRS)


def search_files(roots: Iterable[Path], repo: Path, stylesheet_root: Path) -> list[Path]:
    files: set[Path] = set()
    for root in roots:
        if not root.exists():
            continue
        candidates = [root] if root.is_file() else root.rglob("*")
        for path in candidates:
            if path.is_file() and path.suffix.lower() in SEARCH_EXTENSIONS:
                if not ignored(path, repo, stylesheet_root):
                    files.add(path)
    return sorted(files)


def class_hits(classes: set[str], files: Iterable[Path], repo: Path) -> dict[str, list[str]]:
    hits: dict[str, list[str]] = defaultdict(list)
    if not classes:
        return hits
    alternatives = "|".join(re.escape(name) for name in sorted(classes, key=len, reverse=True))
    pattern = re.compile(rf"(?<![A-Za-z0-9_-])({alternatives})(?![A-Za-z0-9_-])")
    for path in files:
        for line_number, line in enumerate(
            path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1
        ):
            for match in pattern.finditer(line):
                name = match.group(1)
                if len(hits[name]) < 5:
                    hits[name].append(f"{rel(path, repo)}:{line_number}")
    return hits


def main() -> int:
    args = parse_args()
    repo = args.repo.resolve()
    stylesheet_root = absolute(repo, args.stylesheet_root)
    entrypoint_args = args.entrypoint or [Path("app/assets/stylesheets/main.scss")]
    entrypoints = [absolute(repo, path) for path in entrypoint_args]
    search_root_args = args.search_root or [Path("app"), Path("engines")]
    roots = [absolute(repo, path) for path in search_root_args]

    try:
        reachable, graph = reachable_files(entrypoints, stylesheet_root)
    except (FileNotFoundError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    selectors = [selector for path in sorted(reachable) for selector in selectors_in_file(path)]
    classes = {name for selector in selectors for name in selector.classes}
    searched_files = search_files(roots, repo, stylesheet_root)
    hits = class_hits(classes, searched_files, repo)

    rows = []
    for selector in selectors:
        missing = [name for name in selector.classes if not hits[name]]
        status = "dynamic" if selector.dynamic else ("candidate" if missing else "seen")
        if args.only == "candidates" and status != "candidate":
            continue
        if args.only == "seen" and status != "seen":
            continue
        if args.only == "dynamic" and status != "dynamic":
            continue
        rows.append(
            {
                "status": status,
                "source": rel(selector.source, repo),
                "line": selector.line,
                "selector": selector.text,
                "classes": list(selector.classes),
                "missing": missing,
                "sample_hits": {name: hits[name] for name in selector.classes if hits[name]},
            }
        )

    all_scss = {path.resolve() for path in stylesheet_root.rglob("*.scss")}
    unreachable = sorted(rel(path, repo) for path in all_scss - reachable)
    summary = {
        "entrypoints": [rel(path, repo) for path in entrypoints],
        "reachable_scss_files": len(reachable),
        "import_edges": sum(len(imports) for imports in graph.values()),
        "unreachable_local_scss": unreachable,
        "selectors_scanned": len(selectors),
        "unique_classes": len(classes),
        "usage_files_scanned": len(searched_files),
        "rows_returned": len(rows),
        "warning": "candidate means missing literal evidence; manually verify Rails and runtime generation",
    }

    if args.format == "json":
        json.dump({"summary": summary, "results": rows}, sys.stdout, indent=2)
        print()
    else:
        print("status\tsource:line\tselector\tmissing\tsample_hits")
        for row in rows:
            samples = ",".join(
                f"{name}={'|'.join(locations)}" for name, locations in row["sample_hits"].items()
            )
            print(
                "\t".join(
                    (
                        row["status"],
                        f"{row['source']}:{row['line']}",
                        row["selector"],
                        ",".join(row["missing"]),
                        samples,
                    )
                )
            )
        print(json.dumps(summary, indent=2), file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
