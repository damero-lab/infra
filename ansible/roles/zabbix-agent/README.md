# Ansible role: zabbix-agent

Устанавливает **Zabbix Agent 2** нативно на Linux-хосты (Astra Linux / Debian).

## Что делает

1. Устанавливает зависимости (`ca-certificates`, `curl`, `gnupg`, `wget`).
2. Скачивает официальный `.deb` пакет `zabbix-release` (он автоматически ставит GPG-ключ и apt-репозиторий).
3. Устанавливает пакет `zabbix-agent2`.
4. Разворачивает конфиг `/etc/zabbix/zabbix_agent2.conf` (Server, Hostname, Port).
5. Запускает и включает сервис `zabbix-agent2`.
6. Открывает порт 10050 в UFW **только для IP Zabbix Server**.

## Переменные

| Переменная | По умолчанию | Описание |
|---|---|---|
| `zabbix_agent_version` | `7.0` | Версия Zabbix (совпадает с Server) |
| `zabbix_agent_package` | `zabbix-agent2` | Пакет (Agent 2) |
| `zabbix_agent_server` | `172.16.0.200` | IP Zabbix Server |
| `zabbix_agent_port` | `10050` | Порт агента |
| `zabbix_agent_server_port` | `10051` | Порт сервера (для active checks) |
| `zabbix_agent_hostname` | `{{ inventory_hostname }}` | Имя хоста в Zabbix |

## Использование

Применяется **на все хосты** (группа `astra`):

```yaml
# playbooks/site.yml
- name: Базовая настройка всех VM
  hosts: astra
  become: true
  roles:
    - common
    - docker
    - zabbix-agent
```

## Требования

- Zabbix Server развёрнут (`roles/zabbix-server`).
- Роль `common` (для UFW).
- Доступ в интернет для скачивания `.deb` и пакетов из `repo.zabbix.com`.

## Как проверить

После применения — на хосте:

```bash
systemctl status zabbix-agent2
```

В Zabbix UI (`http://172.16.0.200:8080`):

- **Data collection → Hosts** — хост с тем же именем должен быть `Available` (зелёный `ZBX`).
- **Monitoring → Latest data** — появляются метрики CPU/RAM/диск.

## Handlers

- `restart zabbix-agent` — перезапуск агента при изменении конфига.