# Terraform AWS Infrastructure

This folder models real AWS resources for a multi-environment platform deployment.

## Environments

- `environments/dev`
- `environments/staging`
- `environments/prod`

Each environment composes reusable modules:

- `network`: VPC, public/private subnets, NAT, routing
- `cdn`: S3 website bucket, content bucket, CloudFront distribution
- `database`: RDS PostgreSQL and ElastiCache Redis
- `ecs-api`: ECS Fargate service, ALB, ECR, IAM, CloudWatch logs

## Bootstrap backend

Create these once manually or through a separate bootstrap stack:

```bash
aws s3 mb s3://YOUR_TF_STATE_BUCKET
aws dynamodb create-table \
  --table-name YOUR_TF_LOCK_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Then initialize:

```bash
cd infra/terraform/environments/dev
terraform init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="dynamodb_table=$TF_LOCK_TABLE" \
  -backend-config="key=rv-platform-demo/dev.tfstate" \
  -backend-config="region=us-east-1"
terraform plan
```
