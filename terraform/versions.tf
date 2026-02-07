terraform {
  required_version = ">=1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.0.0"
    }
  }
  backend "s3" {
    bucket       = "project-bedrock-terraform-state-1528"
    use_lockfile = true
    key          = "starttech-infra/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true

  }
}

provider "aws" {
  region = "us-east-1"



}