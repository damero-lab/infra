# =============================================================================
# Окружение: homelab
# Объявление переменных для подключения к Proxmox и настройки VM.
#
# РЕАЛЬНЫЕ ЗНАЧЕНИЯ (токены, ключи) задаются в terraform.tfvars,
# который находится ВНЕ репозитория (в .gitignore).
# =============================================================================

# -----------------------------------------------------------------------------
# Подключение к Proxmox API
# -----------------------------------------------------------------------------

variable "proxmox_api_url" {
  description = "URL API Proxmox (например, https://172.16.0.199:8006/api2/json)"
  type        = string
  default     = "https://172.16.0.199:8006/api2/json"
}

variable "proxmox_token_id" {
  description = "ID API-токена Proxmox (например, terraform@pve!terraform-token)"
  type        = string
  sensitive   = true
}

variable "proxmox_token_secret" {
  description = "Секретная часть API-токена Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Игнорировать ошибки SSL (для самоподписанных сертификатов)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Сетевые настройки
# -----------------------------------------------------------------------------

variable "network_gateway" {
  description = "IP-адрес шлюза (роутера) для всех VM в homelab"
  type        = string
  default     = "172.16.0.1"
}

# -----------------------------------------------------------------------------
# SSH-ключ для доступа к VM
# -----------------------------------------------------------------------------

variable "ssh_public_key" {
  description = "Публичный SSH-ключ, который будет добавлен в authorized_keys на всех VM"
  type        = string
}