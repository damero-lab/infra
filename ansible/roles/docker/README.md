# Ansible role: docker

Устанавливает Docker Engine и Docker Compose v2 (plugin) из официального
репозитория `download.docker.com`.

## Что делает

1. Устанавливает зависимости (`ca-certificates`, `curl`, `gnupg`).
2. Скачивает GPG-ключ Docker в `/etc/apt/keyrings/docker.asc`.
3. Добавляет apt-репозиторий Docker.
4. Устанавливает пакеты: `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`.
5. Настраивает `/etc/docker/daemon.json` (log-driver: journald, live-restore).
6. Включает и запускает сервис `docker`.
7. Добавляет указанных пользователей в группу `docker`.

## Переменные

| Переменная | По умолчанию | Описание |
|---|---|---|
| `docker_apt_release` | `bookworm` | Версия Debian-репозитория (Astra = Debian 12) |
| `docker_apt_release_channel` | `stable` | Канал (stable, test, nightly) |
| `docker_packages` | 5 пакетов Docker | Список устанавливаемых пакетов |
| `docker_daemon_config` | log-driver: journald, live-restore: true | Настройки `/etc/docker/daemon.json` |
| `docker_users` | `[roman]` | Пользователи для группы `docker` |

## Использование

В плейбуке:

```yaml
- name: Установить Docker на все VM
  hosts: astra
  become: true
  roles:
    - docker