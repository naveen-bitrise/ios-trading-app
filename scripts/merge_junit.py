#!/usr/bin/env python3
"""Merge the JUnit XML produced by each test shard into a single report.

Shard files are located through the `SHARD_JUNIT_<index>` environment
variables that each parallel workflow shares as a Pipeline intermediate file.

Usage: merge_junit.py <output.xml>
"""

import os
import sys
import xml.etree.ElementTree as ET


def shard_files():
    """Returns the shard JUnit paths in shard-index order."""
    entries = []
    for key, value in os.environ.items():
        if not key.startswith("SHARD_JUNIT_"):
            continue
        suffix = key[len("SHARD_JUNIT_"):]
        if not value:
            continue
        if not os.path.isfile(value):
            print(f"warning: {key} points at a missing file: {value}", file=sys.stderr)
            continue
        try:
            order = int(suffix)
        except ValueError:
            order = 1 << 30
        entries.append((order, key, value))

    return [(key, path) for _, key, path in sorted(entries)]


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2

    output_path = sys.argv[1]
    files = shard_files()
    if not files:
        print("error: no SHARD_JUNIT_* files found to merge", file=sys.stderr)
        return 1

    merged = ET.Element("testsuites", {"name": "UnitTests"})
    total_tests = 0
    total_failures = 0
    total_skipped = 0
    total_time = 0.0

    for key, path in files:
        root = ET.parse(path).getroot()
        suites = [root] if root.tag == "testsuite" else root.findall("testsuite")
        for suite in suites:
            merged.append(suite)
            total_tests += int(suite.get("tests", 0))
            total_failures += int(suite.get("failures", 0))
            total_skipped += int(suite.get("skipped", 0))
            total_time += float(suite.get("time", 0) or 0)
        print(f"merged {len(suites)} suite(s) from {key} ({path})")

    merged.set("tests", str(total_tests))
    merged.set("failures", str(total_failures))
    merged.set("skipped", str(total_skipped))
    merged.set("time", f"{total_time:.3f}")

    tree = ET.ElementTree(merged)
    ET.indent(tree, space="  ")
    tree.write(output_path, encoding="utf-8", xml_declaration=True)

    print(
        f"Merged {len(files)} shard report(s) into {output_path}: "
        f"{total_tests} tests, {total_failures} failures, {total_skipped} skipped"
    )
    return 1 if total_failures else 0


if __name__ == "__main__":
    sys.exit(main())
