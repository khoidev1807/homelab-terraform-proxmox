output "ssh_public_key" {
  value     = tls_private_key.omada_controller_ssh_key.private_key_openssh
  sensitive = true
}

