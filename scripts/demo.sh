#!/usr/bin/env bash
# Local fallback: runs the same checks as the pipeline, no cloud creds needed.
# Usage: ./scripts/demo.sh
set -uo pipefail
cd "$(dirname "$0")/.."

bold() { printf "\n\033[1m%s\033[0m\n" "$1"; }

bold "== OPA / Conftest: org policy =="
conftest test --parser hcl2 --policy policy/ terraform/
c1=$?

bold "== Checkov: baseline checks =="
checkov -d terraform/ --framework terraform --quiet --compact --skip-download \
  --check CKV_AWS_24,CKV_AWS_25,CKV_AWS_260,CKV_AWS_277
c2=$?

if [[ $c1 -eq 0 && $c2 -eq 0 ]]; then
  bold "✅ PIPELINE SAYS YES: safe to merge"
else
  bold "❌ PIPELINE SAYS NO: fix before merge"
  exit 1
fi
