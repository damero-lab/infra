resource "proxmox_virtual_environment_vm" "astra_vm" {
  name        = "astra-test-01"
  description = "Развёрнута Terraform из шаблона"
  tags        = ["terraform", "test"]
  node_name   = "proxmox"
  clone {
    vm_id = 101
    full  = true
  }
  operating_system {
    type = "l26"
  }
  cpu {
    cores   = 2
    sockets = 1
  }
  memory {
    dedicated = 2048
  }
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
  agent {
    enabled = true
  }
  scsi_hardware = "virtio-scsi-pci"
  started       = true
}
output "vm_ip" {
  value = proxmox_virtual_environment_vm.astra_vm.ipv4_addresses[0][0]
}