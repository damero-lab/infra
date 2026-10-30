# =============================================================================
# ВНИМАНИЕ! Этот файл сгенерирован автоматически Terraform.
# Не редактируйте его вручную, изменения будут перезаписаны.
# =============================================================================

all:
  children:
    # Группа для базовой настройки (common + docker + zabbix-agent)
    astra:
      hosts:
%{ for name, vm in vms ~}
        ${name}:
          ansible_host: ${replace(vm.ip_address, "/24", "")}
%{ endfor ~}

    # Группа для развертывания Zabbix Server (переименована в monitoring)
    monitoring:
      hosts:
        mon:
          ansible_host: ${replace(vms["mon"].ip_address, "/24", "")}
    
    # Группа для развертывания Prometheus (сбор метрик с node_exporter)
    prometheus_server:
      hosts:
        prom:
          ansible_host: ${replace(vms["prom"].ip_address, "/24", "")}      

    # Виртуальный хост для работы с Zabbix API
    zabbix_api:
      hosts:
        zabbix_server:
          ansible_host: ${replace(vms["mon"].ip_address, "/24", "")}
          ansible_connection: local