# =============================================================================
# Модуль: vm
# Возвращает информацию о созданной VM для использования в других модулях
# и для генерации инвентаря Ansible.
# =============================================================================

output "vm_id" {
  description = "ID виртуальной машины в Proxmox"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "vm_name" {
  description = "Имя VM (совпадает с hostname)"
  value       = proxmox_virtual_environment_vm.this.name
}

output "ip_address" {
  description = "IP-адрес VM без маски (например, 172.16.0.211)"
  # Убираем маску /24 из строки вида "172.16.0.211/24"
  value       = split("/", var.ip_address)[0]
}

output "hostname" {
  description = "Hostname VM (alias для удобства в Ansible inventory)"
  value       = var.vm_name
}