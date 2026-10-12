# Ansible role: common

Базовая настройка Linux-хоста (Astra Linux, Ubuntu, Debian).
Устанавливает пакеты, настраивает время, SSH, firewall.

## Что делает

1. Обновляет кэш apt.
2. Устанавливает часовой пояс (`timezone`).
3. Устанавливает и запускает NTP (`chrony`).
4. Устанавливает базовые пакеты из `base_packages`.
5. Настраивает SSH (отключает вход по паролю, запрещает root).
6. Настраивает UFW (firewall) — если включён.

## Переменные

Значения по умолчанию — в `defaults/main.yml`.
Реальные значения для homelab — в `ansible/inventories/homelab/group_vars/all.yml`.

| Переменная | По умолчанию | Описание |
|---|---|---|
| `timezone` | `UTC` | Часовой пояс |
| `ntp_package` | `chrony` | Пакет для синхронизации времени |
| `ntp_service` | `chrony` | Имя systemd-сервиса NTP |
| `base_packages` | `[curl, git, vim]` | Список базовых пакетов |
| `ssh_permit_root_login` | `"prohibit-password"` | Разрешение root по SSH |
| `ssh_password_authentication` | `"no"` | Вход по паролю (no = только ключи) |
| `ufw_enabled` | `false` | Включать ли firewall |
| `ufw_default_policy` | `deny` | Политика по умолчанию |
| `ufw_allowed_ports` | `[22/tcp]` | Список разрешённых портов |

## Использование

В плейбуке:

```yaml
- name: Применить роль common на все VM
  hosts: all
  become: true
  roles:
    - common
