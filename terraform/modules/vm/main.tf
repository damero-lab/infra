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

  # Диск: переопределяем ТОЛЬКО если disk_size задан явно (opt-in).
  # Если disk_size = null — блока нет, диск наследуется от шаблона (как раньше).
  #
  # ⚠️ Почему dynamic, а не статичный disk:
  #   При клоне провайдер применяет ДЕФОЛТЫ СХЕМЫ к любым неуказанным атрибутам
  #   диска (size=8, discard=ignore, ssd=false, iothread=false), перезаписывая
  #   настройки шаблона. Поэтому, задавая size, мы обязаны продублировать
  #   остальные атрибуты шаблона (discard/ssd/iothread), иначе получим регресс.
  #   А если бы мы всегда включали блок с size=20 — Terraform пытался бы
  #   СЖАТЬ диск с 32 GiB (Proxmox умеет только увеличивать).
  dynamic "disk" {
    for_each = var.disk_size == null ? [] : [1]
    content {
      interface    = var.disk_interface
      datastore_id = var.disk_storage
      size         = var.disk_size
      discard      = var.disk_discard
      ssd          = var.disk_ssd
      iothread     = var.disk_iothread
    }
  }

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