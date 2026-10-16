# Ansible role: zabbix-server

Разворачивает Zabbix Server + PostgreSQL + Web UI в Docker Compose.

## Что делает

1. Создаёт `/opt/zabbix/` с подпапками.
2. Копирует `docker-compose.yml` из шаблона.
3. Копирует `.env` (пароль БД из Ansible Vault).
4. Запускает `docker compose up -d`.
5. Открывает порты `10051` (Server) и `8080` (Web) в UFW.
6. Ждёт готовности Web UI (HTTP 200).

## Что разворачивается

| Сервис | Порт (на хосте) | Назначение |
|---|---|---|
| `postgres` | — (только внутри Docker) | БД Zabbix |
| `zabbix-server` | 10051 | Приём метрик от агентов |
| `zabbix-web` | 8080 | Веб-интерфейс |

## Переменные

| Переменная | По умолчанию | Описание |
|---|---|---|
| `zabbix_stack_dir` | `/opt/zabbix` | Папка для стека |
| `zabbix_version` | `7.0` | Версия Zabbix (LTS) |
| `zabbix_postgres_image` | `postgres:16-alpine` | Образ БД |
| `zabbix_server_port` | `10051` | Порт Zabbix Server |
| `zabbix_web_port` | `8080` | Порт Web UI |
| `zabbix_php_timezone` | `Europe/Moscow` | Timezone для Frontend |

## Секреты

Пароль БД (`vault_zabbix_db_password`) — из `group_vars/vault.yml`, зашифрован Ansible Vault.

## Использование

```yaml
# playbooks/site.yml
- hosts: mon
  become: true
  roles:
    - zabbix-server
```

## Требования

- Роль `docker` (Docker Engine + Compose v2)
- Роль `common` (UFW + базовые пакеты)
- Ansible Vault настроен (`vault_password_file` в ansible.cfg)

## После установки

Веб-интерфейс: `http://172.16.0.200:8080`

- Логин по умолчанию: `Admin`
- Пароль по умолчанию: `zabbix`

**ВАЖНО:** сменить пароль `Admin` сразу после первого входа.

## Handlers

- `restart zabbix stack` — пересоздаёт контейнеры при изменении конфига.