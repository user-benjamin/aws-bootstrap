locals {
  repo_slug   = replace(var.repo, "/", "-")
  scope_label = var.environment != null ? var.environment : var.branch
  role_name   = coalesce(var.role_name, "github-${local.repo_slug}-${local.scope_label}")
  subject     = var.environment != null ? "repo:${var.repo}:environment:${var.environment}" : "repo:${var.repo}:ref:refs/heads/${var.branch}"
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.subject]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = {
    github-repo = var.repo
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
