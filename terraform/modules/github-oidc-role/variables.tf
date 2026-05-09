variable "repo" {
  description = "Full GitHub repo name, e.g. 'user-benjamin/tavern'"
  type        = string
}

variable "environment" {
  description = "GHA environment name to scope the trust policy to. Takes precedence over branch if set."
  type        = string
  default     = null
}

variable "branch" {
  description = "Branch to scope the trust policy to. Used when environment is not set."
  type        = string
  default     = "main"
}

variable "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider (from aws-bootstrap outputs)"
  type        = string
}

variable "policy_arns" {
  description = "IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "role_name" {
  description = "Override the generated role name. Defaults to github-{repo-slug}-{environment|branch}."
  type        = string
  default     = null
}
