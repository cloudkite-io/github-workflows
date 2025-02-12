# GAR Examples

## GAR build and push workflow referring to helm charts contained in `infrastructure` repo on `cloudkite-io` organisation

### Prerequisite - You have to set up [Workload Identity Federation](https://github.com/marketplace/actions/authenticate-to-google-cloud#setup) before using the `gar-build-template.yml` workflow.

### On commit to `main`
This builds an image with the commit SHA tag, pushes it to the repository, and updates the Helm values file in the infrastructure repository (typically the dev file) to incorporate the new image tag.

```yml
name: Deploy

on:
  push:
    branches:
      - 'main'

jobs:
  build:
    permissions:
      id-token: write # This is required for requesting the JWT
      contents: read # This is required for actions/checkout
    uses: cloudkite-io/github-workflows/.github/workflows/gar-build-template.yml
    with:
      PROJECT_ENV: 'dev'
      GCP_PROJECT: 'project-id'
      GAR_REPO_DOMAIN: 'us-central1-docker.pkg.dev' 
      GAR_REPO_PATH: 'project-name/repo-name/app-name' # The GAR repo path where the image will be stored
      SERVICE_ACCOUNT: 'github-actions@project-name.iam.gserviceaccount.com' # The service account used to authenticate to GAR
      WORKLOAD_IDENTITY_PROVIDER: 'projects/123456789/locations/global/workloadIdentityPools/my-pool/providers/my-provider' #The full identifier of the Workload Identity Provider, including the project number, pool name, and provider name.
  deploy:
    permissions:
      id-token: write # This is required for requesting the JWT
      contents: read # This is required for actions/checkout
    needs: [build]
    uses: cloudkite-io/github-workflows/.github/workflows/gar-deploy-template.yml
    with:
      INFRASTRUCTURE_REPO: 'cloudkite-io/infrastructure.git'
      ARGO_APP_NAME: 'backend-api' # The Argo CD application name in the infrastructure repo
      ENVIRONMENT: 'dev' # The Argo CD application environment in the infrastructure repo
    secrets:
      INFRA_SSH_PRIVATE_KEY: ${{ secrets.INFRASTRUCTURE_SSH_PRIVATE_KEY }} # SSH key with readwrite permissions to the infrastructure repo
```

### On any semver tag e.g `v1.2.3`
This fetches an image with the commit SHA of the Tag, re-tags it using the GitHub tag, and then updates the Helm values file in the infrastructure repository (typically the prod file) to utilize the newly assigned image tag.
```yml
name: Deploy

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  deploy:
    permissions:
      id-token: write # This is required for requesting the JWT
      contents: read # This is required for actions/checkout
    if: startsWith(github.ref, 'refs/tags/')
    uses: cloudkite-io/github-workflows/.github/workflows/gar-deploy-template.yml
    with:
      GAR_REPO_DOMAIN: 'us-central1-docker.pkg.dev' 
      GAR_REPO_PATH: 'project-name/repo-name/app-name' # The GAR repo path where the image will be stored
      SERVICE_ACCOUNT: 'github-actions@project-name.iam.gserviceaccount.com' # The service account used to authenticate to GAR
      WORKLOAD_IDENTITY_PROVIDER: 'projects/123456789/locations/global/workloadIdentityPools/my-pool/providers/my-provider' #The full identifier of the Workload Identity Provider, including the project number, pool name, and provider name.
      INFRASTRUCTURE_REPO: 'cloudkite-io/infrastructure.git'
      ARGO_APP_NAME: 'backend-api' # The Argo CD application name in the infrastructure repo
      ENVIRONMENT: 'dev' # The Argo CD application environment in the infrastructure repo
    secrets:
      INFRA_SSH_PRIVATE_KEY: ${{ secrets.INFRASTRUCTURE_SSH_PRIVATE_KEY }} # SSH key with readwrite permissions to the infrastructure repo
```