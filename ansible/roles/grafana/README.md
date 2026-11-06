# Ansible role: grafana

Разворачивает Grafana в Docker Compose. Визуализирует метрики, которые собирает
Prometheus (`node_exporter` `:9100`). Устанавливается на VM `prom` (`172.16.0.201`) —
на тот же хост, где уже работает Prometheus.

## Что делает

1. Создаёт `/opt/grafana/`, `volumes/data/`, `provisioning/{datasources,dashboards}` и `dashboards/`.
2. Выставляет владельца data-папки `472:472` (пользователь контейнера Grafana) — **не рекурсивно** (см. раздел ниже).
3. Копирует provisioning: datasource Prometheus и провайдер дашбордов.
4. Копирует дашборды (`files/dashboards/*.json`).
5. Копирует `docker-compose.yml` из шаблона.
6. Запускает `docker compose up -d`.
7. Открывает порт `3000` в UFW.
8. Ждёт готовности (`GET /api/health` → HTTP 200).

## Что разворачивается

| Сервис | Порт (на хосте) | Назначение |
|---|---|---|
| `grafana` | 3000 | Веб-UI и дашборды |

## Переменные

| Переменная | По умолчанию | Описание |
|---|---|---|
| `grafana_stack_dir` | `/opt/grafana` | Папка для стека |
| `grafana_version` | `13.3.0` | Версия Grafana (пиннутый тег) |
| `grafana_port` | `3000` | Порт веб-UI |
| `grafana_admin_user` | `admin` | Логин администратора |
| `grafana_prometheus_port` | `9090` | Порт Prometheus |
| `grafana_prometheus_url` | `http://<ansible_host>:9090` | Адрес datasource |
| `grafana_uid` / `grafana_gid` | `472` | Пользователь контейнера |

## Секреты (Ansible Vault)

Пароль администратора НЕ хранится в роли. Он лежит в
`ansible/inventories/homelab/group_vars/all/vault.yml` под именем
`vault_grafana_admin_password` и подставляется в `docker-compose.yml.j2`.

Добавить/изменить секрет (на `mgmt`, где установлен Ansible):

```bash
cd /home/roman/infra/ansible
ansible-vault edit inventories/homelab/group_vars/all/vault.yml --vault-password-file ~/.vault_pass
# добавить строку:
#   vault_grafana_admin_password: "СЛОЖНЫЙ_ПАРОЛЬ"
```

## Provisioning as code (важно)

Datasource и дашборды описаны в коде и монтируются в контейнер:

- `templates/provisioning/datasources/prometheus.yml.j2` → datasource Prometheus (uid `prometheus`);
- `templates/provisioning/dashboards/provider.yml.j2` → провайдер, читает `/var/lib/grafana/dashboards`;
- `files/dashboards/*.json` → сами дашборды.

Почему так: настройки, сделанные руками в UI, живут только в томе и теряются или
расходятся при пересоздании контейнера (**config drift**). Provisioning перезаписывает
их при каждом старте → «код = реальность». `allowUiUpdates: false` запрещает
сохранять правки из UI.

Добавить новый дашборд = положить `.json` в `files/dashboards/` и прогнать плейбук.

## ⚠️ Адрес Prometheus: не localhost

Из контейнера Grafana `localhost:9090` указывает на **сам контейнер**, а не на хост.
Поэтому `grafana_prometheus_url` собирается из IP хоста (`ansible_host`), а не из `localhost`.
Иначе datasource будет в статусе ошибки.

## ⚠️ Владелец data-папки: без `recurse` (безопасность + идемпотентность)

Владелец `472:472` выставляется **только на верхнюю папку** `volumes/data` —
задача `ansible.builtin.file` **без** `recurse: true`.

Почему так:

- Grafana сама создаёт файлы внутри и ставит им строгие права:
  `grafana.db` = `0640`, подпапки (`csv/`, `pdf/`, `png/`) = `0700`.
- Рекурсивный `mode: "0755"` (в связке с `recurse: true`) **расшарил бы БД на
  чтение всем** (`0640 → 0755`) — это дыра в безопасности.
- Плюс каждый прогон менял бы права → задача вечно отдавала бы `changed`, то есть
  роль была бы **не идемпотентной**.

Без `recurse` повторный прогон даёт `changed=0` — проверено на `mgmt`.

## UFW

Роль открывает порт `3000` для всех — осознанное решение для homelab (доступ к UI
с рабочей машины). В проде — сузить до конкретных источников.

## Требования

- Роль `docker` (Docker Engine + Compose v2)
- Роль `common` (UFW + базовые пакеты)
- Роль `prometheus` на этом же хосте (иначе datasource некуда подключать)
- Секрет `vault_grafana_admin_password` в Ansible Vault

## Использование

В `playbooks/site.yml` роль включена отдельным play (Блок 5):

```yaml
- name: Развернуть Grafana на prometheus VM
  hosts: prometheus_server
  become: true
  gather_facts: true

  roles:
    - grafana
```

## После установки

Веб-интерфейс: `http://172.16.0.201:3000`

1. Войти под `admin` и паролем из Vault.
2. **Connections → Data sources** — Prometheus должен быть в статусе OK (green).
3. **Dashboards** — дашборд `Homelab Overview` уже загружен (provisioning).

## ⚠️ Ротация пароля администратора

`GF_SECURITY_ADMIN_PASSWORD` применяется **только при первом создании** пользователя,
то есть когда БД в `./volumes/data` ещё пустая. После первого старта пароль хранится
в БД, и простое изменение секрета в Vault + пересоздание контейнера пароль **не сменит**.

Как сменить пароль после первого запуска:

```bash
cd /opt/grafana
docker compose exec grafana grafana cli admin reset-admin-password 'НОВЫЙ_ПАРОЛЬ'
```

После смены — обновить значение в Ansible Vault, чтобы код и реальность совпадали.

## Handlers

- `restart grafana stack` — пересоздаёт контейнер при изменении конфигов.
