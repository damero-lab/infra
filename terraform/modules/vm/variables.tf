# =============================================================================
# Модуль: vm
# Универсальный модуль для клонирования VM из шаблона в Proxmox.
# Поддерживает Astra Linux и Ubuntu (различие — через параметр os_type).
# =============================================================================

variable "vm_name" {
  description = "Имя VM (будет и hostname, и name в Proxmox)"
  type        = string
}

variable "vm_id" {
  description = "VM ID в Proxmox. Если не указан — Proxmox сам назначит"
  type        = number
  default     = null
}

variable "target_node" {
  description = "Имя ноды Proxmox, где создаётся VM"
  type        = string
  default     = "proxmox"
}

variable "template_id" {
  description = "VM ID шаблона для клонирования (101 = astra-template)"
  type        = number
}

variable "ip_address" {
  description = "IP-адрес VM в CIDR-формате (например, 172.16.0.211/24)"
  type        = string
}

variable "gateway" {
  description = "IP-адрес шлюза (роутера)"
  type        = string
  default     = "172.16.0.1"
}

variable "cores" {
  description = "Количество ядер CPU"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Объём RAM в мегабайтах"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = <<-EOT
    Размер диска в гигабайтах (GiB). По умолчанию null — диск наследуется от
    шаблона. Задавайте явно ТОЛЬКО для УВЕЛИЧЕНИЯ (Proxmox не умеет уменьшать).
  EOT
  type        = number
  default     = null
}

variable "disk_storage" {
  description = "Хранилище (datastore), где размещается диск VM"
  type        = string
  default     = "local-lvm"
}

variable "disk_interface" {
  description = "Интерфейс диска в Proxmox (должен совпадать с шаблоном): sata0, scsi0, virtio0…"
  type        = string
  default     = "sata0"
}

variable "disk_discard" {
  description = "Проброс discard/trim на хранилище: on | ignore (в шаблоне astra — on)"
  type        = string
  default     = "on"
}

variable "disk_ssd" {
  description = "Эмуляция SSD для диска (в шаблоне astra — включена)"
  type        = bool
  default     = true
}

variable "disk_iothread" {
  description = "Отдельный I/O-поток для диска (в шаблоне astra — включён)"
  type        = bool
  default     = true
}

variable "network_bridge" {
  description = "Мост для сетевого интерфейса"
  type        = string
  default     = "vmbr0"
}

variable "ssh_public_key" {
  description = "Публичный SSH-ключ для доступа под пользователем ansible"
  type        = string
}

variable "ansible_user" {
  description = "Имя пользователя, который настраивает cloud-init"
  type        = string
  default     = "roman"
}

variable "tags" {
  description = "Теги VM (для удобства в Proxmox UI)"
  type        = list(string)
  default     = []
}