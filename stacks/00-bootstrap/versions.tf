terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Bootstrap keeps local state on purpose: it creates the bucket every other stack uses.
  # Keep terraform.tfstate from this folder somewhere safe (e.g. a password manager attachment).
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project    = "sentinel"
      stack      = "00-bootstrap"
      managed-by = "terraform"
      repo       = "platform-landing-zone"
    }
  }
}
