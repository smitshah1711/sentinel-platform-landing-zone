terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    key = "platform-landing-zone/30-identity-center.tfstate"
  }
}

# Identity Center must already be enabled (organization instance) in this region.
provider "aws" {
  region = var.home_region

  default_tags {
    tags = {
      project    = "sentinel"
      stack      = "30-identity-center"
      managed-by = "terraform"
      repo       = "platform-landing-zone"
    }
  }
}
