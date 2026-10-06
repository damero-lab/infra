# Terraform module: vm

Универсальный модуль для создания VM в Proxmox путём клонирования шаблона.
Поддерживает Astra Linux и Ubuntu.

## Что делает модуль

1. Клонирует указанный шаблон (полный клон — диск независим от шаблона).
2. Настраивает CPU, RAM, сетевой интерфейс, qemu-guest-agent.
3. Через cloud-init: задаёт статический IP, hostname, пользователя и SSH-ключ.
4. Запускает VM.

## Использование

```hcl
module "app_01" {
  source = "../../modules/vm"

  vm_name        = "app-01"
  target_node    = "proxmox"
  template_id    = 101
  ip_address     = "172.16.0.211/24"
  ssh_public_key = var.ssh_public_key
  tags           = ["app", "astra"]
}