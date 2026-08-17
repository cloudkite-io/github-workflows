#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build="$root/.github/workflows/gar-build-template.yml"
deploy="$root/.github/workflows/cloud-run-deploy-template.yml"

fail() { printf '%s\n' "$*" >&2; exit 1; }
require_pattern() { grep -Eq -- "$2" "$1" || fail "missing required pattern in $1: $2"; }
forbid_pattern() { ! grep -Eq -- "$2" "$1" || fail "forbidden pattern in $1: $2"; }
require_before() {
  local first_line second_line
  first_line="$(grep -nEm1 -- "$2" "$1" | cut -d: -f1)"
  second_line="$(grep -nEm1 -- "$3" "$1" | cut -d: -f1)"
  [[ -n "$first_line" && -n "$second_line" && "$first_line" -lt "$second_line" ]] ||
    fail "required ordering missing in $1: $2 before $3"
}

[[ -f "$build" ]] || fail "missing GAR build workflow: $build"
[[ -f "$deploy" ]] || fail "missing Cloud Run deploy workflow: $deploy"

require_pattern "$build" '^[[:space:]]*workflow_call:'
require_pattern "$build" '^[[:space:]]*image_uri:'
require_pattern "$build" '^[[:space:]]*image_digest:'
require_pattern "$build" 'actions/checkout@[0-9a-f]{40}'
require_pattern "$build" 'google-github-actions/auth@[0-9a-f]{40}'
require_pattern "$build" 'google-github-actions/setup-gcloud@[0-9a-f]{40}'
require_pattern "$build" 'docker[[:space:]]+build'
require_pattern "$build" '--platform[[:space:]]+"\$PLATFORM"'
require_pattern "$build" 'docker[[:space:]]+push[[:space:]]+"\$IMAGE_TAG_URI"'
require_pattern "$build" 'gcloud[[:space:]]+artifacts[[:space:]]+docker[[:space:]]+images[[:space:]]+describe'
require_pattern "$build" 'EXISTING_DIGEST'
require_pattern "$build" '\^\[0-9a-f\]\{40\}\$'
require_pattern "$build" 'BUILD_ARGS_JSON'
require_before "$build" 'docker[[:space:]]+build' 'google-github-actions/auth@[0-9a-f]{40}'
require_before "$build" 'EXISTING_DIGEST=.*gcloud[[:space:]]+artifacts[[:space:]]+docker[[:space:]]+images[[:space:]]+describe' 'docker[[:space:]]+push[[:space:]]+"\$IMAGE_TAG_URI"'
forbid_pattern "$build" 'actions/checkout@(v[0-9]|main|master)'
forbid_pattern "$build" 'google-github-actions/(auth|setup-gcloud)@(v[0-9]|main|master)'
forbid_pattern "$build" 'docker[[:space:]]+push.*(PROJECT_ENV|github\.ref_name|latest)'

require_pattern "$deploy" '^[[:space:]]*workflow_call:'
require_pattern "$deploy" 'environment:'
require_pattern "$deploy" 'name:[[:space:]]*\$\{\{[[:space:]]*inputs\.GITHUB_ENVIRONMENT_NAME[[:space:]]*\}\}'
forbid_pattern "$deploy" 'inputs\.ENVIRONMENT_NAME'
require_pattern "$deploy" 'vars\.GCP_APPLICATION_PROJECT'
require_pattern "$deploy" 'vars\.CLOUD_RUN_REGION'
require_pattern "$deploy" 'vars\.CLOUD_RUN_SERVICE'
require_pattern "$deploy" 'vars\.CLOUD_RUN_MIGRATION_JOB'
require_pattern "$deploy" 'vars\.GCP_WORKLOAD_IDENTITY_PROVIDER'
require_pattern "$deploy" 'vars\.GCP_DEPLOYER_SERVICE_ACCOUNT'
require_pattern "$deploy" 'google-github-actions/auth@[0-9a-f]{40}'
require_pattern "$deploy" 'google-github-actions/setup-gcloud@[0-9a-f]{40}'
require_pattern "$deploy" '\^sha256:\[0-9a-f\]\{64\}\$'
require_pattern "$deploy" '\^\[0-9a-f\]\{40\}\$'
require_pattern "$deploy" 'gcloud[[:space:]]+artifacts[[:space:]]+docker[[:space:]]+images[[:space:]]+describe'
require_pattern "$deploy" 'gcloud[[:space:]]+run[[:space:]]+jobs[[:space:]]+update'
require_pattern "$deploy" 'gcloud[[:space:]]+run[[:space:]]+jobs[[:space:]]+execute'
require_pattern "$deploy" 'gcloud[[:space:]]+run[[:space:]]+services[[:space:]]+update'
require_pattern "$deploy" 'gcloud[[:space:]]+run[[:space:]]+revisions[[:space:]]+describe'
require_pattern "$deploy" 'READY_IMAGE_URI.*==.*IMAGE_URI'
require_pattern "$deploy" 'MIGRATION_JOB_NAME'
require_pattern "$deploy" 'ROLLBACK'
require_pattern "$deploy" 'inputs\.ROLLBACK[[:space:]]*==[[:space:]]*false.*migration_job_name'
require_pattern "$deploy" 'latestReadyRevisionName'
require_pattern "$deploy" 'status\.conditions'
require_before "$deploy" 'gcloud[[:space:]]+run[[:space:]]+jobs[[:space:]]+execute' 'gcloud[[:space:]]+run[[:space:]]+services[[:space:]]+update'
forbid_pattern "$deploy" 'docker[[:space:]]+(build|push)'
forbid_pattern "$deploy" 'actions/checkout@'
forbid_pattern "$deploy" 'google-github-actions/(auth|setup-gcloud)@(v[0-9]|main|master)'

printf 'GCP delivery workflow contract checks passed\n'
