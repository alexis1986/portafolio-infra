variable "do_token" {
  description = "DigitalOcean API token (sensitive)"
  type        = string
  sensitive   = true
}

variable "ssh_key_id" {
  description = "ID (o fingerprint) of the SSH public key uploaded to DigitalOcean"
  type        = string
}

variable "region" {
  description = "Droplet region"
  type        = string
  default     = "nyc3"
}

variable "droplet_size" {
  description = "Droplet size slug"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "droplet_image" {
  description = "Image slug for Droplet"
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "droplet_name" {
  type    = string
  default = "portafolio-droplet"
}
