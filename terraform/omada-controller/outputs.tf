output "ssh_public_key" {
  value     = tls_private_key.ubuntu_resolute_ssh_key.private_key_openssh
  sensitive = true
}

