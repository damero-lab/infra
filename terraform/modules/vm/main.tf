# =============================================================================
# Модуль: vm
# Создаёт VM в Proxmox путём клонирования шаблона.
# Настраивает сеть, cloud-init и qemu-guest-agent.
# =============================================================================

# -----------------------------------------------------------------------------
# Клонирование VM из шаблона
# -----------------------------------------------------------------------------
resource "proxmox_virtual_environment_vm" "this" {
  name      = var.vm_name
  node_name = var.target_node
  vm_id     = var.vm_id

  # Клонирование из шаблона
  clone {
    vm_id = var.template_id
    full  = true  # Полный клон (не linked) — независимый диск
  }

  # Отключаем создание диска — он будет унаследован от шаблона
  # (Proxmox сам разберётся с клонированием)

  # CPU
  cpu {
    cores = var.cores
    type  = "x86-64-v2-AES"
  }

  # Память
  memory {
    dedicated = var.memory
  }

  # Сетевой интерфейс
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # qemu-guest-agent — для чтения IP и корректного shutdown
  agent {
    enabled = true
  }

  # Cloud-init: настройка при первом запуске
  initialization {
    # IP-конфигурация
    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    # Пользователь и SSH-ключ
    user_account {
      username = var.ansible_user
      keys     = [var.ssh_public_key]
    }
  }

  # Включаем VM после создания
  started = true

  # Теги для удобства
  tags = var.tags
}