terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  # Recommended for CI/CD — uncomment and create the bucket + table once.
  # backend "s3" {
  #   bucket         = "juice-shop-tfstate-562517367791"
  #   key            = "juice-shop-cluster/terraform.tfstate"
  #   region         = "us-east-2"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "juice-shop"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
