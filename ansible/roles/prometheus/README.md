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

## Таргеты для сбора

Список таргетов **не хардкодится** — генерируется из инвентаря Ansible:

```jinja
{% for host in groups['astra'] %}
- '{{ hostvars[host].ansible_host }}:{{ prometheus_node_exporter_port }}'
{% endfor %}
```

Значит, новая VM в группе `astra` → автоматически появляется в мониторинге
после прогона плейбука. Отдельно править `prometheus.yml` не нужно.

## UFW

Роль открывает порт `9090` (веб UI и API Prometheus) для всех.

Это осознанное решение для homelab: порт нужен для доступа к UI с рабочей
машины. В проде — сузить до конкретных источников.

## Self-scrape и docker-подсети (важно)

Prometheus в контейнере скрейпит `node_exporter` **на всех хостах** группы
`astra`, включая **свой собственный**.

Возникает неочевидный эффект:

- **Чужой хост** (`mon`, `app-01`) → пакет покидает `prom`, Docker делает
  MASQUERADE → source подменяется на IP хоста (`172.16.0.201`).
  Правило `allow from 172.16.0.201` на том хосте срабатывает. Всё хорошо.
- **Свой хост** (`prom → prom`) → пакет не покидает машину, MASQUERADE
  не срабатывает → source остаётся **docker-IP** контейнера (`172.18.0.2`).
  Правило `172.16.0.201` его не пускает → drop → таймаут 10s.

Поэтому роль `node_exporter` в `node_exporter_allowed_sources` разрешает
не только IP Prometheus, но и **docker-подсети** (`172.17/18/19.0.0/16`).
Тот же паттерн — в роли `zabbix-agent` (порт `10050`).

Без этого целевой таргет Prometheus на самом `prom` будет `DOWN`
с ошибкой `context deadline exceeded`.

## Требования

- Роль `docker` (Docker Engine + Compose v2)
- Роль `common` (UFW + базовые пакеты)
- Роль `node_exporter` на целевых хостах (иначе таргеты будут `DOWN`)
- В `node_exporter_allowed_sources` должны быть docker-подсети
  (для self-scrape — см. раздел выше)

## Использование

```yaml
# playbooks/site.yml
- hosts: prometheus_server
  become: true
  roles:
    - prometheus
```

## После установки

Веб-интерфейс: `http://172.16.0.201:9090`

Раздел **Status → Targets** — проверить, что все таргеты `UP`.
Ожидаемо: N таргетов `node_exporter` (по числу хостов в `astra`)
+ 1 self-scrape (`localhost:9090`).

## Handlers

- `restart prometheus stack` — пересоздаёт контейнер при изменении конфигов.