# github-workflows
This repository contains a collection of reusable github actions workflows to be used by Cloudkite's clients

* `build-and-push-image-to-acr.yml` - Build and push docker image to Azure Container Registry
* `build-docker-push-to-acr.yml` - Build and push docker image to Elastic Container Registry
* `commit-to-helm-chart-cronjobs.yml` - Commit and push new image tag for a cronjob (standard-app.cronjobs.$CRONJOB_NAME.tag)
* `commit-to-helm-chart.yml` - Commit and push new global image tag for the whole chart (standard-app.tag)