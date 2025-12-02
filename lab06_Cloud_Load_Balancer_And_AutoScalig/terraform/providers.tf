terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    # Настройте свой S3 bucket для state файла
  }
}

provider "aws" {
  region = var.aws_region
}