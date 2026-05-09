# aws-bootstrap

One-time account setup that every other project depends on. Run this first, run it once, leave it alone.

## What it creates

| Resource | Purpose |
|---|---|
| GitHub OIDC provider | Lets GitHub Actions assume IAM roles — no static credentials anywhere |
| S3 bucket (versioned, encrypted) | Remote Terraform state for all projects |
| DynamoDB table | Terraform state locking |

The `modules/github-oidc-role` module is the shared primitive every project uses to create its own IAM role.

## Prerequisites

- AWS CLI configured (`aws configure` or environment variables)
- Terraform >= 1.6
- An AWS account you own

## Running it

```bash
cd terraform

cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — set your bucket name, region, github org

terraform init      # local backend — intentional, see note below
terraform plan
terraform apply
```

Take note of the outputs — you'll need them in every other project:

```
oidc_provider_arn    = "arn:aws:iam::123456789:oidc-provider/token.actions.githubusercontent.com"
state_bucket_name    = "yourname-tfstate"
state_dynamodb_table = "terraform-locks"
```

> **Bootstrap state stays local.** This repo uses a local backend deliberately.
> The state file it manages is tiny and rarely changes. Storing it in S3 would
> be circular (it creates the bucket). Commit `terraform.tfstate` to a private
> repo or keep it somewhere safe — losing it means manually importing resources.

## Using the module in a project

### 1. Configure remote state

In your project's `terraform/versions.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "yourname-tfstate"
    key            = "your-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
```

### 2. Create a deploy role

```hcl
module "gha_role" {
  source = "git::https://github.com/benjaminglover/aws-bootstrap//terraform/modules/github-oidc-role?ref=main"

  repo              = "benjaminglover/your-project"
  environment       = "production"          # scopes trust to this GHA environment
  oidc_provider_arn = "arn:aws:iam::..."    # from bootstrap outputs
  policy_arns       = [aws_iam_policy.deploy.arn]
}
```

Role name will be `github-benjaminglover-your-project-production`.

### 3. Use it in your workflow

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ vars.AWS_ROLE_ARN }}
      aws-region: us-east-1
```

Put the role ARN in a GitHub Actions environment variable — not hardcoded in the YAML.

## Trust policy options

| Scenario | Module input |
|---|---|
| Specific GHA environment (recommended for prod) | `environment = "production"` |
| Specific branch | `branch = "main"` (default) |
| Any workflow in the repo | Don't do this for production roles |

## Structure

```
terraform/
├── versions.tf          # provider versions
├── providers.tf         # AWS provider + default tags
├── variables.tf         # inputs
├── oidc-provider.tf     # GitHub OIDC provider
├── state.tf             # S3 bucket + DynamoDB
├── outputs.tf           # ARNs and names for downstream projects
└── modules/
    └── github-oidc-role/
        ├── main.tf      # trust policy + role + policy attachments
        ├── variables.tf
        └── outputs.tf
```
