variable "proxmox_api_url" {
  description = "URL для доступа к Proxmox API"
  type        = string
  default     = "https://172.16.0.199:8006/api2/json"
}

variable "proxmox_user" {
  description = "Имя пользователя (с областью)"
  type        = string
  default     = "terraform@pve"
}

variable "proxmox_token_id" {
  description = "ID токена (например, terraform@pve!terraform-token)"
  type        = string
  sensitive   = true
}

variable "proxmox_token_secret" {
  description = "Секрет токена"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Игнорировать ошибки SSL"
  type        = bool
  default     = true
}

variable "proxmox_timeout" {
  description = "Таймаут для API-запросов"
  type        = number
  default     = 120
}
