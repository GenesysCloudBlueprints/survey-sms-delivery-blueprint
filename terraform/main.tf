terraform {
  required_providers {
    genesyscloud = {
      source  = "mypurecloud/genesyscloud"
      version = "1.51.0"
    }
  }
}

provider "genesyscloud" {
  sdk_debug = true
}

module "media_retention_policies" {
    source = "./modules/media-retention-policies"
    client_id = var.client_id
    client_secret = var.client_secret
}