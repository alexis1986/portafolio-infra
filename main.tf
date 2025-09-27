resource "digitalocean_droplet" "portafolio" {
  name   = var.droplet_name
  region = var.region
  size   = var.droplet_size
  image  = var.droplet_image

  ssh_keys = [var.ssh_key_id]

  tags = ["portafolio"]

  user_data = file("${path.module}/cloud-init.sh")
}