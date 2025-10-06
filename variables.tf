variable "do_token" {
  description = "DigitalOcean API token (sensitive)"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Region for the DOKS cluster and VPC"
  type        = string
  default     = "nyc3"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "portafolio-cluster"
}

variable "kubernetes_version" {
  description = "Explicit Kubernetes version slug. If empty, use latest available"
  type        = string
  default     = ""
}

variable "auto_upgrade" {
  description = "Enable automatic patch upgrades during maintenance window"
  type        = bool
  default     = true
}

variable "surge_upgrade" {
  description = "Enable surge upgrades to minimize downtime"
  type        = bool
  default     = true
}

variable "maintenance_policy_day" {
  description = "Maintenance window day (e.g., sunday)"
  type        = string
  default     = "sunday"
}

variable "maintenance_policy_start_time" {
  description = "Maintenance window start time in UTC (HH:MM)"
  type        = string
  default     = "03:00"
}

variable "tags" {
  description = "Tags to apply (used on node pools)"
  type        = list(string)
  default     = ["portafolio"]
}

variable "vpc_name" {
  description = "Name for the dedicated VPC"
  type        = string
  default     = "portafolio-vpc"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "node_pool_name" {
  description = "Default node pool name"
  type        = string
  default     = "portafolio-pool"
}

variable "node_pool_size" {
  description = "Droplet size slug for worker nodes"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "node_pool_min_nodes" {
  description = "Minimum nodes for autoscaling"
  type        = number
  default     = 1
}

variable "node_pool_max_nodes" {
  description = "Maximum nodes for autoscaling"
  type        = number
  default     = 2
}

variable "authorized_sources" {
  description = "List of CIDR addresses allowed to access the cluster API (control plane firewall)"
  type        = list(string)
  default     = []
}

variable "enable_registry_integration" {
  description = "Enable DigitalOcean Container Registry integration on the cluster"
  type        = bool
  default     = true
}

variable "registry_name" {
  description = "Container registry name to create/use when integration is enabled"
  type        = string
  default     = "portafolio-registry"
}

variable "registry_tier" {
  description = "Container registry tier (basic, professional)"
  type        = string
  default     = "basic"
}
