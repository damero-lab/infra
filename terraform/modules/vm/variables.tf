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
  description = "Размер диска в гигабайтах"
  type        = number
  default     = 20
}

variable "disk_storage" {
  description = "Хранилище, где размещается диск VM"
  type        = string
  default     = "local-lvm"
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