data "digitalocean_kubernetes_versions" "this" {}

locals {
  cluster_version = var.kubernetes_version != "" ? var.kubernetes_version : data.digitalocean_kubernetes_versions.this.latest_version
}

resource "digitalocean_vpc" "vpc" {
  name     = var.vpc_name
  region   = var.region
  ip_range = var.vpc_cidr
}

resource "digitalocean_container_registry" "registry" {
  count                   = var.enable_registry_integration ? 1 : 0
  name                    = var.registry_name
  subscription_tier_slug  = var.registry_tier
}

resource "digitalocean_kubernetes_cluster" "cluster" {
  name    = var.cluster_name
  region  = var.region
  version = local.cluster_version

  vpc_uuid          = digitalocean_vpc.vpc.id
  auto_upgrade      = var.auto_upgrade
  surge_upgrade     = var.surge_upgrade
  registry_integration = var.enable_registry_integration

  maintenance_policy {
    day        = var.maintenance_policy_day
    start_time = var.maintenance_policy_start_time
  }

  control_plane_firewall {
    enabled           = length(var.authorized_sources) > 0
    allowed_addresses = var.authorized_sources
  }

  node_pool {
    name       = var.node_pool_name
    size       = var.node_pool_size
    auto_scale = true
    min_nodes  = var.node_pool_min_nodes
    max_nodes  = var.node_pool_max_nodes
    tags       = var.tags
  }

  depends_on = [
    digitalocean_vpc.vpc,
    digitalocean_container_registry.registry
  ]
}