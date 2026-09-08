terraform {
  required_version = ">= 1.9"

  backend "s3" {
    bucket       = "service-watch-tfstate-182715287298"
    key          = "service-watch/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
