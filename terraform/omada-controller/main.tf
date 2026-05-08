# Generate an SSH key pair (only needs to be created once)
resource "tls_private_key" "omada_controller_ssh_key" {
  algorithm = "ED25519"
}


resource "proxmox_download_file" "ubuntu_noble_cloud_image" {
  node_name    = "node1"
  content_type = "iso"
  datastore_id = "local"
  file_name    = "noble-server-cloudimg-amd64.img"
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}



resource "proxmox_virtual_environment_vm" "omada_controller" {
  name = "omada-controller"

  node_name = "node1"
  vm_id     = 100
  machine   = "q35"
  bios      = "ovmf"

  agent {
    enabled = true
  }

  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }
  

  disk {
    datastore_id = "datadrive"
    file_id      = proxmox_download_file.ubuntu_noble_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.11.10/24"
        gateway = "192.168.11.1"
      }
    }
    user_data_file_id    = proxmox_virtual_environment_file.user_data_cloud_config.id
  }

  cpu {
    cores = 2
    type = "host"
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  memory {
    dedicated = 3072
    floating  = 3072
  }

}

resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "node1"

  source_raw {
    data      = <<EOF
#cloud-config
users:
  - default
  - name: ubuntu
    groups:
      - sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - ${trimspace(tls_private_key.omada_controller_ssh_key.public_key_openssh)}
    sudo: ALL=(ALL) NOPASSWD:ALL
package_update: true
packages:
  - qemu-guest-agent
  - net-tools
  - curl
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - echo "done" > /tmp/vendor-cloud-init-done
EOF
    file_name = "cloud-config.yaml"
  }
}


