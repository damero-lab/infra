# Ansible role: prometheus

Разворачивает Prometheus в Docker Compose. Собирает системные метрики
с `node_exporter` (`:9100`) со всех хостов группы `astra`.

## Что делает

1. Создаёт `/opt/prometheus/` и `/opt/prometheus/volumes/data/`.
2. Выставляет владельца data-папки `65534:65534` (пользователь контейнера).
3. Копирует `prometheus.yml` из шаблона (таргеты — динамически из инвентаря).
4. Копирует `docker-compose.yml` из шаблона.
5. Запускает `docker compose up -d`.
6. Открывает порт `9090` в UFW.
7. Ждёт готовности (`GET /-/ready` → HTTP 200).

## Что разворачивается

| Сервис | Порт (на хосте) | Назначение |
|---|---|---|
| `prometheus` | 9090 | Сбор и хранение метрик, веб UI |

## Переменные

| Переменная | По умолчанию | Описание |
|---|---|---|
| `prometheus_stack_dir` | `/opt/prometheus` | Папка для стека |
| `prometheus_version` | `v3.1.0` | Версия Prometheus |
| `prometheus_port` | `9090` | Порт веб UI и API |
| `prometheus_scrape_interval` | `15s` | Интервал сбора метрик |
| `prometheus_retention` | `15d` | Срок хранения метрик |
| `prometheus_node_exporter_port` | `9100` | Порт node_exporter на целевых хостах |

## Taргеты для сбора

Список таргетов **не хардкодится** — генерируется из инвентаря Ansible:

```jinja
{% for host in groups['astra'] %}
  - '{{ hostvars[host].ansible_host }}:{{ prometheus_node_exporter_port }}'
{% endfor %}
```

Значит, новая VM в группе `astra` → автоматически появляется в мониторинге
после прогона плейбука. Отдельно править `prometheus.yml` не нужно.

## Использование

```yaml
# playbooks/site.yml
- hosts: prometheus_server
  become: true
  roles:
    - prometheus
```

## Требования

- Роль `docker` (Docker Engine + Compose v2)
- Роль `common` (UFW + базовые пакеты)
- Роль `node_exporter` на целевых хостах (иначе таргеты будут `DOWN`)

## После установки

Веб-интерфейс: `http://172.16.0.201:9090`

- Раздел **Status → Targets** — проверить, что все таргеты `UP`.

## Handlers

- `restart prometheus stack` — пересоздаёт контейнер при изменении конфигов.