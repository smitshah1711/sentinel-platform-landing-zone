terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    key = "platform-landing-zone/20-logging.tfstate"
  }
}

locals {
  default_tags = {
    project    = "sentinel"
    stack      = "20-logging"
    managed-by = "terraform"
    repo       = "platform-landing-zone"
  }
}

# Management account: owns the organization trail.
provider "aws" {
  region = var.home_region

  default_tags {
    tags = local.default_tags
  }
}

# Log archive account: owns the bucket and the KMS key.
provider "aws" {
  alias  = "log_archive"
  region = var.home_region

  assume_role {
    role_arn     = "arn:aws:iam::${local.log_archive_id}:role/OrganizationAccountAccessRole"
    session_name = "terraform-20-logging"
  }

  default_tags {
    tags = merge(local.default_tags, { environment = "security" })
  }
}
