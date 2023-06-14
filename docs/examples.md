# Examples

## ECR build and push workflow on commit to `main` referring to helm charts contained in `infrastructure` repo on `cloudkite-io` organisation

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
    uses: cloudkite-io/github-workflows/.github/workflows/ecr-build-template.yml@v1
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
    uses:cloudkite-io/github-workflows/.github/workflows/deploy-template.yml@develop
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
