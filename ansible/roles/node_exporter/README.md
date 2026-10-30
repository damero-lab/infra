# Роль: node_exporter

Роль входит в **стек мониторинга Prometheus/Grafana**.

## Что делает

Устанавливает [node_exporter](https://github.com/prometheus/node_exporter)
нативно бинарником из официального GitHub-релиза. Агент отдаёт метрики хоста
(CPU, RAM, диск, сеть) по HTTP на порту `9100`.

**Модель работы — pull:** не агент шлёт данные, а Prometheus сам приходит
и забирает метрики с порта `9100`.

## На какие хосты ставится

На **все** VM из группы `astra` (`mon`, `app-01`, `prom`).

## Переменные

| Переменная | По умолчанию | Описание |
|---|---|---|
| `node_exporter_version` | `1.8.2` | Версия релиза |
| `node_exporter_arch` | `amd64` | Архитектура |
| `node_exporter_port` | `9100` | Порт HTTP-метрик |
| `node_exporter_allowed_sources` | `["172.16.0.201"]` | Кому разрешён доступ (UFW) |

## Безопасность

Порт `9100` открывается в UFW **только** для VM `prom` (`172.16.0.201`),
где работает Prometheus. Остальным доступ закрыт.

## Проверка

```bash
# На хосте локально
curl -s http://localhost:9100/metrics | head

# С mgmt (для prom)
curl -s http://172.16.0.201:9100/metrics | head
```