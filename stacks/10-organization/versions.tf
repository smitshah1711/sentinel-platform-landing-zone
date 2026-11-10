terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Partial config: run `terraform init -backend-config=../backend.hcl`
  backend "s3" {
    key = "platform-landing-zone/10-organization.tfstate"
  }
}

provider "aws" {
  region = var.home_region

  default_tags {
    tags = {
      project    = "sentinel"
      stack      = "10-organization"
      managed-by = "terraform"
      repo       = "platform-landing-zone"
    }
  }
}
