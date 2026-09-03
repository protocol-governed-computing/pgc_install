"""`pgc` — report what is installed and whether this environment can build.

Installing the toolchain is one of two steps. The compiler resolves the
governance surface from PGC_PLATFORM_ROOT rather than from a bundled copy —
fail-hard, cwd-independent, zero inference — so the declarations come from a
repository the operator points at, not from a wheel. A registry inside a wheel
would be a second governance surface competing with the repository's.

This command reports both halves so the gap is visible before a build fails.
"""
from __future__ import annotations

import importlib.metadata as md
import os
import sys
from pathlib import Path

FAMILY = [
    ("pgc-compiler", "declarations → compiled projections"),
    ("pgc-assembler", "projections → sealed snapshot"),
    ("pgc-runtime", "snapshot → governed execution"),
    ("pgc-inspector", "snapshot → read-only inspection"),
    ("pgc-transformation", "change request → protocol artifacts"),
    ("pgc-governance", "governance surface implementations"),
    ("pgc-workloads", "conformance workload implementations"),
]

STANDARD = "https://doi.org/10.5281/zenodo.22150616"


def _installed() -> list[tuple[str, str, str]]:
    rows = []
    for dist, role in FAMILY:
        try:
            rows.append((dist, md.version(dist), role))
        except md.PackageNotFoundError:
            rows.append((dist, "-", role))
    return rows


def _environment() -> list[tuple[str, str, bool]]:
    """The anchors the toolchain reads. Absent is not an error here — it is a fact."""
    checks = []
    root = os.environ.get("PGC_PLATFORM_ROOT")
    if not root:
        checks.append(("PGC_PLATFORM_ROOT", "not set", False))
    else:
        p = Path(root).expanduser()
        ok = (p / "registry").is_dir()
        checks.append(("PGC_PLATFORM_ROOT", f"{p}{'' if ok else '  (no registry/ here)'}", ok))
    for name in ("PGC_BUILD_ROOT", "PGC_DOMAIN_ROOTS"):
        v = os.environ.get(name)
        checks.append((name, v or "not set (optional)", True))
    return checks


def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    if argv and argv[0] not in ("status", "-h", "--help"):
        print(f"pgc: unknown command {argv[0]!r}", file=sys.stderr)
        return 2
    if argv and argv[0] in ("-h", "--help"):
        print(__doc__.strip())
        return 0

    print("Protocol-Governed Computing\n")
    print("  toolchain")
    missing = 0
    for dist, ver, role in _installed():
        if ver == "-":
            missing += 1
        print(f"    {dist:<20} {ver:<8} {role}")

    print("\n  environment")
    ready = True
    for name, value, ok in _environment():
        if not ok:
            ready = False
        print(f"    {name:<20} {value}")

    print()
    if missing:
        print(f"  {missing} package(s) not installed — `pip install pgc` installs the family.")
    if not ready:
        print("  PGC_PLATFORM_ROOT must point at a governance repository (the directory")
        print("  containing registry/). The declarations are not shipped in any wheel:")
        print("  the compiler resolves them from this anchor, so one governance surface")
        print("  governs a build rather than a wheel's stale copy competing with a repo.")
        print("\n    git clone https://github.com/protocol-governed-computing/software_governance")
        print("    export PGC_PLATFORM_ROOT=$PWD/software_governance")
    if not missing and ready:
        print("  Ready: toolchain installed and a governance surface is anchored.")
    print(f"\n  standard: {STANDARD}")
    return 0 if (ready and not missing) else 1


if __name__ == "__main__":
    raise SystemExit(main())
