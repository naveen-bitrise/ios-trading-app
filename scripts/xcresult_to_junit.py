#!/usr/bin/env python3
"""Convert an .xcresult bundle into a JUnit XML file.

Used by each test shard so the shard results can be merged into a single
JUnit report at the end of the pipeline.

Usage: xcresult_to_junit.py <path/to/Test.xcresult> <output.xml> [suite-prefix]
"""

import json
import subprocess
import sys
import xml.etree.ElementTree as ET


def load_test_results(xcresult_path):
    result = subprocess.run(
        [
            "xcrun", "xcresulttool", "get", "test-results", "tests",
            "--path", xcresult_path,
            "--format", "json", "--compact",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


def duration_seconds(raw):
    """xcresulttool reports durations like "0.012s" or "1m 3s"."""
    if not raw:
        return 0.0
    text = str(raw).strip()
    total = 0.0
    for part in text.split():
        part = part.strip()
        try:
            if part.endswith("ms"):
                total += float(part[:-2]) / 1000
            elif part.endswith("m"):
                total += float(part[:-1]) * 60
            elif part.endswith("s"):
                total += float(part[:-1])
            else:
                total += float(part)
        except ValueError:
            continue
    return total


def collect_cases(nodes, suite=None, cases=None):
    if cases is None:
        cases = []
    for node in nodes:
        kind = node.get("nodeType")
        name = node.get("name", "")

        if kind == "Test Suite":
            suite = name
        elif kind == "Test Case":
            failures = [
                child.get("name", "")
                for child in node.get("children", [])
                if child.get("nodeType") == "Failure Message"
            ]
            cases.append({
                "suite": suite or "Tests",
                "name": name,
                "result": node.get("result", ""),
                "duration": duration_seconds(node.get("duration")),
                "failures": failures,
            })

        collect_cases(node.get("children", []), suite, cases)
    return cases


def build_junit(cases, prefix):
    by_suite = {}
    for case in cases:
        by_suite.setdefault(case["suite"], []).append(case)

    root = ET.Element("testsuites")
    total_tests = 0
    total_failures = 0
    total_skipped = 0
    total_time = 0.0

    for suite_name in sorted(by_suite):
        suite_cases = by_suite[suite_name]
        suite_time = sum(case["duration"] for case in suite_cases)
        suite_failures = sum(1 for case in suite_cases if case["result"] == "Failed")
        suite_skipped = sum(1 for case in suite_cases if case["result"] == "Skipped")

        suite_element = ET.SubElement(root, "testsuite", {
            "name": f"{prefix}{suite_name}" if prefix else suite_name,
            "tests": str(len(suite_cases)),
            "failures": str(suite_failures),
            "skipped": str(suite_skipped),
            "time": f"{suite_time:.3f}",
        })

        for case in suite_cases:
            case_element = ET.SubElement(suite_element, "testcase", {
                "classname": f"{prefix}{case['suite']}" if prefix else case["suite"],
                "name": case["name"],
                "time": f"{case['duration']:.3f}",
            })
            if case["result"] == "Failed":
                message = case["failures"][0] if case["failures"] else "Test failed"
                failure = ET.SubElement(case_element, "failure", {
                    "message": message,
                    "type": "XCTAssertionFailure",
                })
                failure.text = "\n".join(case["failures"])
            elif case["result"] == "Skipped":
                ET.SubElement(case_element, "skipped")

        total_tests += len(suite_cases)
        total_failures += suite_failures
        total_skipped += suite_skipped
        total_time += suite_time

    root.set("tests", str(total_tests))
    root.set("failures", str(total_failures))
    root.set("skipped", str(total_skipped))
    root.set("time", f"{total_time:.3f}")
    return root, total_tests


def main():
    if len(sys.argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2

    xcresult_path, output_path = sys.argv[1], sys.argv[2]
    prefix = sys.argv[3] if len(sys.argv) > 3 else ""

    cases = collect_cases(load_test_results(xcresult_path).get("testNodes", []))
    root, total = build_junit(cases, prefix)

    tree = ET.ElementTree(root)
    ET.indent(tree, space="  ")
    tree.write(output_path, encoding="utf-8", xml_declaration=True)

    print(f"Wrote {total} test cases to {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
