#!/usr/bin/env bash
# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly test_file="tests/root_compute_machine_type.tftest.hcl"
readonly expected_failure_dir="tests/expected-failures"

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

plan_output="${work_dir}/plans.jsonl"
failure_output="${work_dir}/expected-failure.jsonl"

terraform test -filter="${test_file}" -json -verbose >"${plan_output}"

terraform init -backend=false -input=false -test-directory="${expected_failure_dir}" >/dev/null

if terraform test -test-directory="${expected_failure_dir}" -json >"${failure_output}"; then
  echo "Expected an untargeted real-root plan with null machine_pools to fail." >&2
  exit 1
fi

python3 tests/root_compute_machine_type_test.py "${plan_output}" "${failure_output}"

echo "Root compute machine type plans and explicit-null diagnostic verified."
