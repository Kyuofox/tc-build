terraform {
  required_providers {
    external = {
      source = "hashicorp/external"
    }
    null = {
      source = "hashicorp/null"
    }
    packet = {
      source = "terraform-providers/packet"
    }
  }
  required_version = ">= 0.13"
}
