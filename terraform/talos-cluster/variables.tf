variable "endpoint" {
  sensitive   = true
  type        = string
  description = "Proxmox API endpoint URL, e.g., https://proxmox.example.com:8006"
}

variable "api_token" {
  sensitive   = true
  type        = string
  description = "proxmox api token"
}

variable "ssh_private_key_path" {
  sensitive   = true
  type        = string
  description = "Path to SSH private key for Proxmox access"
}



