output "ssh_public_key" {
  value = tls_private_key.ubuntu_resolute_ssh_key.private_key_openssh
  sensitive = true
}

output "vm_ipv4_address" {
  value = proxmox_virtual_environment_vm.omada_controller.ipv4_addresses[1][0]
}