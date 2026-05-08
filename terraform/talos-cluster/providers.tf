provider "proxmox" {
  endpoint  = var.endpoint
  api_token = var.api_token
  insecure  = true
  ssh {
    agent       = true
    username    = "root"
    private_key = file(var.ssh_private_key_path)
  }
}