# =============================================================================
# Окружение: homelab
# Настройка провайдера Proxmox.
#
# ВАЖНО: значения токенов передаются через переменные и хранятся ВНЕ
# репозитория (в terraform.tfvars, который в .gitignore).
# =============================================================================

provider "proxmox" {
  # URL API Proxmox (обычно https://IP:8006/api2/json)
  endpoint = var.proxmox_api_url

  # Аутентификация по API-токену: формат "<token_id>=<token_secret>"
  api_token = "${var.proxmox_token_id}=${var.proxmox_token_secret}"

  # Игнорировать ошибки SSL (самоподписанный сертификат Proxmox)
  insecure = var.proxmox_insecure
}