terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "~> 2.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11.1"
    }
  }


  backend "s3" {
    bucket         = "xbrain-terraform-state"
    key            = "us-dev/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "opensearch" {
  url         = var.enable_geekbrain ? module.geekbrain_ai_engine[0].opensearch_collection_endpoint : "https://localhost:9200"
  healthcheck = false
}
