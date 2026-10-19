# Ansible role: zabbix-agent

Устанавливает **Zabbix Agent 2** нативно на Linux-хосты (Astra Linux / Debian).

## Что делает

1. Скачивает GPG-ключ Zabbix в `/etc/apt/keyrings/zabbix.asc`.
2. Добавляет apt-репозиторий Zabbix.
3. Устанавливает `zabbix-agent2`.
4. Разворачивает конфиг `/etc/zabbix/zabbix_agent2.conf` (Server, Hostname, Port).
5. Запускает сервис `zabbix-agent2`.
6. Открывает порт 10050 в UFW **только для IP Zabbix Server**.

## Переменные

| Переменная | По умолчанию | Описание |
|---|---|---|
| `zabbix_agent_version` | `7.0` | Версия Zabbix (совпадает с Server) |
| `zabbix_agent_server` | `172.16.0.200` | IP Zabbix Server |
| `zabbix_agent_port` | `10050` | Порт агента |
| `zabbix_agent_server_port` | `10051` | Порт сервера (active checks) |
| `zabbix_agent_hostname` | `{{ inventory_hostname }}` | Имя хоста в Zabbix |

## Использование

Применяется на **все хосты** (группа `astra`):

```yaml
- hosts: astra
  become: true
  roles:
    - common
    - docker
    - zabbix-agent
```

## Проверка

После применения:
```bash
systemctl status zabbix-agent2
```

В Zabbix UI: `Data collection → Hosts` — хост должен быть Available (зелёный `ZBX`).

## Handlers

- `restart zabbix-agent` — перезапуск при изменении конфига.