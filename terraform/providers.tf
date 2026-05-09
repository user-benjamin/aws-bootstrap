provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project    = "aws-bootstrap"
      managed-by = "terraform"
    }
  }
}
