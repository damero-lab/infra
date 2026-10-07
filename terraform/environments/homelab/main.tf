# =============================================================================
# Окружение: homelab
# Создание VM по реестру vms.auto.tfvars.
#
# Файл описывает ЛОГИКУ (как обойти реестр и вызвать модуль),
# но НЕ содержит конкретных VM. Список VM — в vms.auto.tfvars.
# =============================================================================

# -----------------------------------------------------------------------------
# Определение реестра VM как переменной Terraform
# -----------------------------------------------------------------------------
# Значения реестра задаются в vms.auto.tfvars (см. отдельный файл).
# Структура: map(object(...)) — словарь, где ключ = имя VM.
# -----------------------------------------------------------------------------

variable "vms" {
  description = "Реестр виртуальных машин. Ключ = имя VM, значение = параметры."
  type = map(object({
    template_id = number
    ip_address  = string
    cores       = optional(number, 2)
    memory      = optional(number, 2048)
    disk_size   = optional(number, 20)
    tags        = optional(list(string), [])
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Создание VM через модуль
# -----------------------------------------------------------------------------
# for_each = var.vms — «для каждой VM из реестра»
# each.key        — имя VM (ключ в map): app-01, mon, db-01...
# each.value.X    — параметры этой VM: ip_address, cores, memory...
# -----------------------------------------------------------------------------

module "vms" {
  source   = "../../modules/vm"
  for_each = var.vms

  # Имя VM = ключ из реестра
  vm_name = each.key

  # ID шаблона — из реестра
  template_id = each.value.template_id

  # Сеть
  ip_address = each.value.ip_address
  gateway    = var.network_gateway

  # Ресурсы — из реестра (со значениями по умолчанию из type)
  cores     = each.value.cores
  memory    = each.value.memory
  disk_size = each.value.disk_size

  # Теги — из реестра
  tags = each.value.tags

  # Данные из переменных окружения
  ssh_public_key = var.ssh_public_key
  ansible_user   = "roman"
}