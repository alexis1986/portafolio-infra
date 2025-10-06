output "cluster_id" {
  description = "DOKS Cluster ID"
  value       = digitalocean_kubernetes_cluster.cluster.id
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = digitalocean_kubernetes_cluster.cluster.endpoint
}

output "kubeconfig" {
  description = "Raw kubeconfig for the created cluster"
  value       = digitalocean_kubernetes_cluster.cluster.kube_config[0].raw_config
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID where the cluster is located"
  value       = digitalocean_vpc.vpc.id
}

output "registry_name" {
  description = "Container registry name (if created)"
  value       = try(digitalocean_container_registry.registry[0].name, null)
}
