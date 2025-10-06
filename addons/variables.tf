variable "kubeconfig_file" {
  description = "Path to kubeconfig file for the target cluster"
  type        = string
}

variable "enable_ingress" {
  description = "Enable installation of ingress-nginx"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Enable installation of cert-manager"
  type        = bool
  default     = true
}

variable "enable_external_dns" {
  description = "Enable installation of external-dns"
  type        = bool
  default     = true
}

variable "enable_metrics_server" {
  description = "Enable installation of metrics-server"
  type        = bool
  default     = true
}

variable "domain_base" {
  description = "Base domain managed in DigitalOcean DNS (e.g., alexdevvv.com)"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt ACME registration"
  type        = string
}

variable "letsencrypt_environment" {
  description = "Let's Encrypt environment: production or staging"
  type        = string
  default     = "production"
}

variable "do_token" {
  description = "DigitalOcean API token for external-dns (requires DNS write)"
  type        = string
  sensitive   = true
}
