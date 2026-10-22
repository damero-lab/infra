terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.50.0"
    }
    
    # Плагин для сохранения файла:
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }
}