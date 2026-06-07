resource "proxmox_download_file" "talos_vm_image" {
  node_name    = "proxmox"
  content_type = "iso"
  datastore_id = "local"
  file_name    = "talos-amd64-secureboot.iso"
  url          = "https://factory.talos.dev/image/861a91152157e97c900df9ca48fe4a26f19f19795e081386751bb7994c16800f/v1.13.0/nocloud-amd64-secureboot.iso"

}

resource "proxmox_virtual_environment_vm" "talos_control_plane" {
  name = "talos-control-plane"

  node_name = "proxmox"
  vm_id     = 101
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
    datastore_id = "local-lvm"
    file_id      = proxmox_download_file.talos_vm_image.id
    interface    = "scsi0"
    file_format  = "raw"
    discard      = "on"
    size         = 30
    cache        = "writethrough"
  }


  scsi_hardware = "virtio-scsi-pci"

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.11.11/24"
        gateway = "192.168.11.1"
      }
    }
  }

  cpu {
    cores = 2
    type = "host"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  memory {
    dedicated = 8192
    
  }

}


resource "proxmox_virtual_environment_vm" "talos_worker" {
  count = 3

  name      = "talos-worker-${count.index + 1}"
  node_name = "proxmox"
  vm_id     = 102 + count.index  
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
    datastore_id = "local-lvm"
    file_id      = proxmox_download_file.talos_vm_image.id
    interface    = "scsi0"
    file_format  = "raw"
    discard      = "on"
    size         = 30
    cache        = "writethrough"
  }


   disk {
    datastore_id = "data-pool"
    interface    = "scsi1"
    file_format  = "raw"
    discard      = "on"
    size         = 300
    cache        = "writethrough"
  }

  scsi_hardware = "virtio-scsi-pci"

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.11.${12 + count.index}/24"  
        gateway = "192.168.11.1"
      }
    }
  }

  cpu {
    cores = 4
    type  = "host"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  memory {
    dedicated = 8192
   
  }
}