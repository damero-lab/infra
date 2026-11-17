# Ansible role: zabbix-server

Разворачивает Zabbix Server + PostgreSQL + Web UI в Docker Compose.

## Что делает

1. Создаёт `/opt/zabbix/` с подпапками.
2. Копирует `docker-compose.yml` из шаблона.
3. Копирует `.env` (пароль БД из Ansible Vault).
4. Применяет отложенные handlers **до** запуска стека (`meta: flush_handlers`).
5. Запускает `docker compose up -d`.
6. Открывает порты `10051` (Server) и `8080` (Web) в UFW.
7. Ждёт готовности: порт Server `10051` (значит, БД инициализирована), затем Web UI (HTTP 200).

## ⚠️ Инициализация БД (важно)

При **первом** запуске `zabbix-server` создаёт схему в PostgreSQL (десятки секунд — минуты).
Если в этот момент пересоздать контейнеры, инициализация прервётся и останется полу-созданная
схема (таблица `role` есть, записи `dbversion` нет) — сервер навсегда зациклится:

```
ERROR:  relation "role" already exists
```

→ контейнер в статусе `Restarting`, Zabbix не работает.

Поэтому handler применяется **до** `docker compose up`, а после старта стек никто не трогает;
дополнительно роль ждёт порт `10051` — он открывается только после успешного init БД.

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
| `zabbix_version` | `7.0.32` | Версия Zabbix 7.0 LTS (пиннутый тег образов) |
| `zabbix_postgres_image` | `postgres:16.16-alpine` | Образ БД (пиннутый патч-тег) |
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

Веб-интерфейс: `http://172.16.0.200:8080`, логин — `Admin`.

На **свежей** БД пароль Admin изначально дефолтный (`zabbix`). Роль **`zabbix-api`**
(следующий play) приводит его к значению из Vault (`vault_zabbix_admin_password`) через
bootstrap — вручную менять пароль в UI не нужно, и он переживает `destroy`.

## Handlers

- `restart zabbix stack` — пересоздаёт контейнеры при изменении конфига.
  Применяется **до** `docker compose up` (см. «Инициализация БД»): после старта стек
  не перезапускается, иначе можно сломать инициализацию схемы.