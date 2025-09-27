output "droplet_ip" {
  description = "Public IPv4 of the droplet"
  value       = digitalocean_droplet.portafolio.ipv4_address
}
