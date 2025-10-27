terraform {
  required_providers {
    nginxproxymanager = {
      source  = "Sander0542/nginxproxymanager"
      version = "1.2.2"
    }
  }
}

# Environment variable-based authentication - 
# NGINXPROXYMANAGER_PASSWORD
# NGINXPROXYMANAGER_URL
# NGINXPROXYMANAGER_USERNAME
provider "nginxproxymanager" {}
