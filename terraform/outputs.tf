output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider — pass this to the github-oidc-role module in each project"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "state_bucket_name" {
  description = "S3 bucket name for Terraform remote state"
  value       = aws_s3_bucket.tfstate.bucket
}

output "state_dynamodb_table" {
  description = "DynamoDB table name for Terraform state locking"
  value       = aws_dynamodb_table.tfstate_lock.name
}
