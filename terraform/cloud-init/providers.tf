provider "proxmox" {
  endpoint  = "https://proxmox.109lcpalhcm.crabdance.com:8006"
  api_token = "terraform@pve!provider=2dd5a379-ec96-452e-9e44-0339094f21a2"
  insecure  = true
  ssh {
    agent       = true
    username    = "root"
    private_key = file("~/.ssh/proxmox_terraform")
  }
}