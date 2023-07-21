# Examples

## ECR build and push workflow referring to helm charts contained in `infrastructure` repo on `cloudkite-io` organisation

### On commit to `main`

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
    uses: cloudkite-io/github-workflows/aws/ecr-build-template.yml@v1
    with:
      AWS_ACCOUNT_ID: '123456789012' # The AWS account hosting the ECR repo
      AWS_REGION: 'us-east-1' # The region hosting the ECR repo
      ECR_REPO_NAME: 'backend-api'
      AWS_ROLE_NAME: 'GithubECRPush' # The role to assume in the AWS account hosting the ECR repo
  deploy:
    permissions:
      id-token: write # This is required for requesting the JWT
      contents: read # This is required for actions/checkout
    needs: [build]
    uses: cloudkite-io/github-workflows/aws/deploy-template.yml@develop
    with:
      AWS_ACCOUNT_ID: '123456789012' # The AWS account hosting the ECR repo
      AWS_REGION: 'us-east-1' # The region hosting the ECR repo
      ECR_REPO_NAME: 'backend-api'
      INFRASTRUCTURE_REPO: 'git@github.com:cloudkite-io/infrastructure.git'
      APP_REPO_NAME: ${{ github.event.repository.name }}
      ARGO_APP_NAME: 'backend-api' # The Argo CD application name in the infrastructure repo
      ARGO_APP_BRANCH: 'main' # The Argo CD target branch for the application name in the infrastructure repo
      ENVIRONMENT: 'dev' # The Argo CD application environment in the infrastructure repo
    secrets:
      DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }} # SSH key with readwrite permissions to the infrastructure repo
```

### On any semver tag e.g `v1.2.3`

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
    uses: cloudkite-io/github-workflows/aws/deploy-template.yml@develop
    with:
      AWS_ACCOUNT_ID: '123456789012'  # The AWS account hosting the ECR repo
      AWS_REGION: 'us-east-1' # The region hosting the ECR repo
      ECR_REPO_NAME: 'backend-api'
      INFRASTRUCTURE_REPO: 'git@github.com:cloudkite-io/infrastructure.git'
      APP_REPO_NAME: ${{ github.event.repository.name }}
      ARGO_APP_NAME: 'backend-api' # The Argo CD application name in the infrastructure repo
      ARGO_APP_BRANCH: 'main' # The Argo CD target branch for the application name in the infrastructure repo
      ENVIRONMENT: 'prod' # The Argo CD application environment in the infrastructure repo
      AWS_ROLE_NAME: 'GithubECRPush' # The role to assume in the AWS account hosting the ECR repo
    secrets:
      DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }} # SSH key with readwrite permissions to the infrastructure repo
```
