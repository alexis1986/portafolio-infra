terraform {
  required_version = ">= 1.3.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket = "alexdevvv-portafolio-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1" # DigitalOcean Spaces usa este valor por convención

    endpoints = {
      s3 = "https://nyc3.digitaloceanspaces.com"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

provider "digitalocean" {
  token = var.do_token
}

