#!/usr/bin/env python3
# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

import json
import sys


CLUSTER_RESOURCE = (
    "module.rosa_cluster_hcp.rhcs_cluster_rosa_hcp.rosa_hcp_cluster"
)
EXPECTED_VALUES = {
    "null_uses_one_machine_pool_type": "m5.xlarge",
    "null_uses_same_type_from_multiple_machine_pools": "m5.xlarge",
    "explicit_type_wins_over_machine_pool_type": "m7i.xlarge",
    "null_with_empty_machine_pools_stays_null": None,
    "explicit_type_with_empty_machine_pools": "m5.xlarge",
    "null_with_explicitly_null_machine_pools": None,
}


def read_events(path):
    with open(path, encoding="utf-8") as stream:
        for line_number, line in enumerate(stream, start=1):
            try:
                yield json.loads(line)
            except json.JSONDecodeError as error:
                raise AssertionError(
                    f"{path}:{line_number} is not valid Terraform JSON output: {error}"
                ) from error


def assert_cluster_resource_values(path):
    actual_values = {}
    for event in read_events(path):
        run_name = event.get("@testrun")
        if event.get("type") != "test_plan" or run_name not in EXPECTED_VALUES:
            continue

        resources = event.get("test_plan", {}).get("resource_changes", [])
        matches = [item for item in resources if item.get("address") == CLUSTER_RESOURCE]
        if len(matches) != 1:
            raise AssertionError(
                f"{run_name} contained {len(matches)} changes for {CLUSTER_RESOURCE}; expected 1"
            )
        actual_values[run_name] = matches[0]["change"]["after"][
            "compute_machine_type"
        ]

    if actual_values != EXPECTED_VALUES:
        raise AssertionError(
            f"cluster compute_machine_type values differ: {actual_values!r}"
        )


def assert_null_for_each_diagnostic(path):
    diagnostics = [
        event["diagnostic"]
        for event in read_events(path)
        if event.get("type") == "diagnostic"
        and event.get("diagnostic", {}).get("severity") == "error"
    ]
    if len(diagnostics) != 1:
        raise AssertionError(
            f"expected one error diagnostic from the untargeted null plan, got {len(diagnostics)}"
        )

    diagnostic = diagnostics[0]
    snippet = diagnostic.get("snippet", {})
    values = snippet.get("values", [])
    if (
        diagnostic.get("summary") != "Invalid for_each argument"
        or diagnostic.get("range", {}).get("filename") != "../../main.tf"
        or snippet.get("context") != 'module "rhcs_hcp_machine_pool"'
        or snippet.get("code") != "  for_each = var.machine_pools"
        or values
        != [{"traversal": "var.machine_pools", "statement": "is null"}]
    ):
        raise AssertionError(f"unexpected null-plan diagnostic: {diagnostic!r}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(f"usage: {sys.argv[0]} PLAN_JSONL FAILURE_JSONL")
    assert_cluster_resource_values(sys.argv[1])
    assert_null_for_each_diagnostic(sys.argv[2])
