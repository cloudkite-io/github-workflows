# github-workflows
This repository contains a collection of reusable github actions workflows to be used by Cloudkite's clients

* `build-and-push-image-to-acr.yml` - Build and push docker image to Azure Container Registry
* `build-docker-push-to-acr.yml` - Build and push docker image to Elastic Container Registry
* `commit-to-helm-chart-cronjobs.yml` - Commit and push new image tag for a cronjob (standard-app.cronjobs.$CRONJOB_NAME.tag)
* `commit-to-helm-chart.yml` - Commit and push new global image tag for the whole chart (standard-app.tag)

## Google Cloud container delivery

### `gar-build-template.yml`

Builds a caller's Docker context, pushes only the caller commit SHA to Google
Artifact Registry, and returns the immutable image URI and `sha256` digest. The
workflow builds before Google authentication so the generated
`gha-creds-*.json` file cannot enter the Docker build context. Callers should
run their language-specific tests in a preceding job and pin this reusable
workflow to an exact commit SHA.

If that commit-SHA tag already exists, a rerun reuses its digest rather than
overwriting it. Configure GAR with immutable Docker tags to enforce this
promotion contract at the registry boundary.

Required inputs are `GCP_PROJECT`, `GAR_REPO_DOMAIN`, `GAR_REPO_PATH`,
`SERVICE_ACCOUNT`, and `WORKLOAD_IDENTITY_PROVIDER`. Optional inputs configure
runner labels, Dockerfile, context, platform, and non-secret build arguments.
`PROJECT_ENV` remains accepted only for caller compatibility; mutable
environment tags are no longer published.

### `cloud-run-deploy-template.yml`

Deploys an existing GAR image to a Cloud Run service. It accepts exactly one
immutable digest or 40-character commit-SHA tag, resolves the final digest,
optionally runs a Cloud Run migration job, deploys the same digest to the
service, and verifies readiness. It never builds or pushes an image.

The called job enters `GITHUB_ENVIRONMENT_NAME` before resolving these GitHub
environment variables:

- `GCP_APPLICATION_PROJECT`
- `CLOUD_RUN_REGION`
- `CLOUD_RUN_SERVICE`
- `CLOUD_RUN_MIGRATION_JOB` (optional)
- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_DEPLOYER_SERVICE_ACCOUNT`

Explicit workflow inputs can override those values. Set `ROLLBACK: true` with
an exact `IMAGE_DIGEST` to skip migration and update only the service. Use
GitHub environment protection rules for production approval.

Run `./tests/validate-gcp-delivery-workflows.sh` after changing either workflow.
