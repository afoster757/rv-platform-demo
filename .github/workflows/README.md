# GitHub Actions workflow layout

This repo uses one deploy workflow per application, and each workflow supports all environments.

## Files

- `api-deploy.yml` — builds, tests, publishes, plans, and deploys the API for `dev`, `staging`, or `prod`.
- `web-deploy.yml` — builds the static web app, deploys to S3, and invalidates CloudFront for `dev`, `staging`, or `prod`.
- `infra-plan.yml` — runs Terraform plan only, useful for PR review across environments.

## Branch-to-environment mapping

- `develop` → `dev`
- `staging` → `staging`
- `main` → `prod`

Each deploy workflow also supports manual `workflow_dispatch` so you can select the target environment from the GitHub UI.

## Required GitHub environment setup

Create these GitHub environments:

- `dev`
- `staging`
- `prod`

Add this secret to each environment:

- `AWS_ROLE_TO_ASSUME` — IAM role ARN that GitHub Actions can assume through OIDC.

Recommended: require approval on the `prod` environment.
