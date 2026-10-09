# Bootstrap: шаблон Astra Linux SE 1.8 для Proxmox

Документ описывает **полный процесс создания шаблона** Astra Linux SE 1.8,
готового для клонирования через Terraform.

Цель: создать `astra-template` (VM ID 101), из которого Terraform будет клонировать
рабочие VM с автоматической настройкой сети, hostname и SSH-доступа через cloud-init.

---

## Требования

- Proxmox VE 8.x или 9.x
- ISO-образ `alse-1.8.6.iso` в Proxmox storage
- Доступ к Shell Proxmox (для конвертации template)
- Доступ к Proxmox UI (для создания VM и настроек)
- SSH-ключ `~/.ssh/id_ed25519_infra` на mgmt (для доступа к клонам)

---

## Шаг 1. Создание VM в Proxmox

**Create VM** в Proxmox UI со следующими параметрами:

| Параметр | Значение |
|---|---|
| **Name** | `astra-template` |
| **VM ID** | `101` |
| **Start at boot** | No |
| **ISO** | `local:iso/alse-1.8.6.iso` |
| **BIOS** | **Default (SeaBIOS)** — НЕ OVMF |
| **Qemu Agent** | ✅ Enabled |
| **Disk Bus** | **SATA**, storage `local-lvm`, size 32 GiB |
| **Disk options** | Discard ✅, SSD emulation ✅, IO thread ✅ |
| **CPU** | 2 cores, type `x86-64-v2-AES` |
| **Memory** | 2048 MiB |
| **Network** | VirtIO, bridge `vmbr0` |

**Почему SATA, а не SCSI:**
Astra SE 1.8 с `virtio-scsi-single` не может корректно записать GRUB при установке.
SATA — надёжный вариант. Минус: диски SATA не поддерживают snapshots в Proxmox,
но для шаблона это не критично.

**Почему SeaBIOS, а не OVMF:**
Установщик Astra делает GPT-разметку с BIOS boot partition, а не EFI.
При OVMF GRUB не находится. Использовать SeaBIOS.

---

## Шаг 2. Установка Astra Linux

Запустить VM → `Start` → `Console` → дождаться Live-режима.

Запустить **Графический инсталлятор**, пройти шаги:

| Шаг | Значение |
|---|---|
| Язык | Русский |
| Продукт | **Astra Linux для Сервера** |
| Уровень защищённости | **Базовый** |
| Лицензия | Принять |
| Регион | Europe/Moscow, Русский, Alt+Shift |
| Разметка | Использовать EXT4, весь диск `/dev/sda` |
| Ядро | `linux-6.1-generic` |
| Компоненты | Консольные утилиты ✅, **Средства удалённого подключения SSH** ✅, Средства работы в сети Интернет ✅, ufw ✅, Стандартное восстановление ✅. Остальное — снять. |
| Параметры безопасности | **Запрос пароля для команды sudo — СНЯТЬ** ⬅ критично для Ansible |
| Пользователь | `roman`, сложный пароль (12+ символов) |
| Имя ПК | `astra-template` |
| Пароль загрузчика | Оставить как есть |

**Дождаться сообщения «Установка успешно завершена»** — не прерывать раньше.

---

## Шаг 3. Post-install: базовые пакеты

Подключиться к VM по SSH или через Console. Проверить, что мы на `mgmt`:
`ssh roman@<IP>`

**qemu-guest-agent** (для Proxmox — чтение IP, корректный shutdown):
```bash
sudo apt update
sudo apt install -y qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```

**cloud-init** (для автоматизации клонов):
```bash
sudo apt install -y cloud-init cloud-utils
```

**Проверка:**
```bash
systemctl status qemu-guest-agent --no-pager | head -3
which cloud-init && cloud-init --version
```

---

## Шаг 4. Настройка sudo без пароля

Ansible не может вводить пароль интерактивно. Пользователь `roman` должен выполнять `sudo` без пароля.

```bash
echo "roman ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/90-roman-nopasswd
sudo chmod 0440 /etc/sudoers.d/90-roman-nopasswd
```

**Проверка синтаксиса:**
```bash
sudo visudo -c
```

**Проверка работы:**
```bash
sudo whoami
# Ожидаемо: root (без запроса пароля)
```

---

## Шаг 5. Добавление SSH-ключа для Ansible

С mgmt (где есть ключ `~/.ssh/id_ed25519_infra`):

```bash
ssh-copy-id -i ~/.ssh/id_ed25519_infra.pub roman@<IP>
```

**Проверка:**
```bash
ssh -i ~/.ssh/id_ed25519_infra roman@<IP>
# Ожидаемо: пустит без пароля
```

---

## Шаг 6. Правка cloud.cfg — включение модуля network

Открыть конфиг:
```bash
sudo nano /etc/cloud/cloud.cfg
```

Найти блок `cloud_init_modules:`. Между `- mounts` и `- set_hostname` **добавить**:
```
 - network
```

**Должно получиться:**
```yaml
cloud_init_modules:
 - seed_random
 - bootcmd
 - write-files
 - growpart
 - resizefs
 - disk_setup
 - mounts
 - network          ← добавлено
 - set_hostname
 - update_hostname
 ...
```

Сохранить: `Ctrl+O`, Enter, `Ctrl+X`.

**Примечание:** в Astra SE этого модуля нет в cloud-init (файл `cc_network.py`
отсутствует). Добавление строки не даёт ошибки, но и не делает работу. Оставлена
для совместимости со стандартным cloud-init. Реально за работу сети отвечает
`cloud-init-network.service`.

---

## Шаг 7. 🔴 КРИТИЧНО: переключение рендерера на systemd-networkd

**Это главный фикс.** Astra SE использует `systemd-networkd` для управления сетью,
а cloud-init по умолчанию пишет конфиг в `ifupdown` (`/etc/network/interfaces.d/`),
который в Astra не работает и падает с ошибками.

**Решение:** указать cloud-init использовать рендерер `networkd`.

### 7.1. Отключить сломанный ifupdown

```bash
sudo systemctl disable --now networking.service
sudo systemctl mask networking.service
```

`mask` полностью блокирует сервис — он не запустится даже как зависимость.

### 7.2. Создать файл с рендерером

```bash
sudo nano /etc/cloud/cloud.cfg.d/99-network-renderer.cfg
```

Содержимое:
```yaml
system_info:
  network:
    renderers: [networkd]
```

Сохранить: `Ctrl+O`, Enter, `Ctrl+X`.

**Проверка:**
```bash
cat /etc/cloud/cloud.cfg.d/99-network-renderer.cfg
```

### 7.3. Как это работает

- Cloud-init при клонировании получает `network-config` от Proxmox.
- С новым рендерером он генерирует файл `/etc/systemd/network/10-cloud-init-eth0.network`.
- Файл лексически **раньше** `20-ethernet.network` (там `DHCP=yes`), поэтому имеет приоритет.
- Networkd применяет статический IP из Terraform.

---

## Шаг 8. Очистка системы перед шаблонированием

Удалить уникальные идентификаторы, чтобы каждый клон был уникальным.

### 8.1. Сбросить cloud-init

```bash
sudo cloud-init clean --logs
```

### 8.2. Очистить идентификаторы, SSH-ключи, логи, историю

```bash
sudo truncate -s 0 /etc/machine-id && \
sudo rm -f /var/lib/dbus/machine-id && \
sudo ln -sf /etc/machine-id /var/lib/dbus/machine-id && \
sudo rm -f /etc/ssh/ssh_host_* && \
sudo truncate -s 0 /var/log/auth.log 2>/dev/null ; \
sudo truncate -s 0 /var/log/syslog 2>/dev/null ; \
cat /dev/null > ~/.bash_history && history -c && \
sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null ; \
echo "=== DONE ==="
```

**Что делает:**
- `machine-id` — обнуляется (система сгенерирует новый при первом boot клона).
- `/var/lib/dbus/machine-id` — симлинк на machine-id.
- SSH host keys — удаляются (сгенерируются заново при boot, у каждой VM уникальные).
- Логи и история bash — очищаются.

**Примечание:** после этой очистки **SSH-сервер в шаблоне не работает** —
нет host keys. Это нормально. При старте клона systemd сгенерирует новые
(через `ssh-keygen -A` в стартовых скриптах или через cloud-init).

⚠️ **Важно:** при следующей загрузке этой VM (пока ещё шаблона) **сразу
выполнить** `sudo ssh-keygen -A && sudo systemctl start ssh`, если нужно
снова зайти по SSH.

---

## Шаг 9. Конвертация в template

### 9.1. Остановить VM

**В Proxmox UI:** VM 101 → `Shutdown` (или `Stop` если не выключается).

### 9.2. Снять read-only с диска (для установки флага)

В Shell Proxmox:
```bash
lvchange -prw pve/base-101-disk-0
```

**Проверка:**
```bash
lvs | grep 101
# Ожидаемо: Vwi---tz-k (writable)
```

### 9.3. Установить флаг template

```bash
qm set 101 --template 1
```

**Проверка:**
```bash
qm config 101 | grep template
# Ожидаемо: template: 1
```

### 9.4. Вернуть read-only

```bash
lvchange -pr pve/base-101-disk-0
```

**Проверка:**
```bash
lvs | grep 101
# Ожидаемо: Vri---tz-k (read-only)
```

Обновить Proxmox UI (F5) — иконка 101 станет серой с пометкой template.

---

## Шаг 10. Проверка

Создать тестовый клон через Terraform:
```bash
cd ~/infra/terraform/environments/homelab
terraform apply
```

Дождаться создания VM. Проверить в Proxmox UI, что новый клон (например, VM 102)
имеет:
- **IP:** статический из Terraform (например, `172.16.0.211`)
- **Hostname:** заданный (например, `app-01`)

Проверить SSH:
```bash
ssh -i ~/.ssh/id_ed25519_infra roman@172.16.0.211
```

Внутри:
```bash
hostname            # → app-01
ip -4 addr show     # → 172.16.0.211/24 static
sudo cloud-init status --long
```

---

## Известные проблемы

### Проблема: SSH не подключается, "Connection refused"
**Причина:** host keys удалены при очистке, sshd не может стартовать.
**Решение:** `sudo ssh-keygen -A && sudo systemctl start ssh`.

### Проблема: SSH "REMOTE HOST IDENTIFICATION HAS CHANGED"
**Причина:** у клона новый host key (уникальный для каждой VM).
**Решение:** `ssh-keygen -R <IP>` — удалить старую запись из known_hosts.

### Проблема: сеть не применяется, IP по DHCP
**Причина:** cloud-init пишет в ifupdown, а Astra использует systemd-networkd.
**Решение:** Шаг 7 этого документа.

### Проблема: cloud-init `degraded done` и warning про `user deprecated`
**Причина:** провайдер bpg/proxmox передаёт `user:` в старом формате.
**Влияние:** не критично, SSH-ключ и hostname применяются.
**Решение:** отложено (можно задать свой user-data в Terraform).

### Проблема: snapshots не работают ("guest configuration does not support snapshots")
**Причина:** диск подключён как SATA, а не SCSI.
**Решение:** сделать backup вместо snapshot. Или перевести диск на SCSI и проверить,
что GRUB загружается (рискованно).

---

## Структура файлов шаблона (важное)

| Файл | Назначение |
|---|---|
| `/etc/cloud/cloud.cfg` | Основной конфиг cloud-init |
| `/etc/cloud/cloud.cfg.d/99-network-renderer.cfg` | Наш override: рендерер networkd |
| `/etc/sudoers.d/90-roman-nopasswd` | Sudo без пароля для roman |
| `/etc/ssh/authorized_keys` (у roman) | Наш SSH-ключ (id_ed25519_infra.pub) |
| `/etc/systemd/system/networking.service` | Симлинк на /dev/null (замаскирован) |

---

## Что НЕ делать

- **Не пушить в git** файлы `terraform.tfvars`, `*.pem`, `id_*`.
- **Не удалять** содержимое `~/.ssh/authorized_keys` перед очисткой —
  иначе клоны не пустят по SSH.
- **Не выключать** cloud-init полностью — только менять рендерер.
- **Не использовать virtio-scsi-single** с этим шаблоном.
- **Не использовать OVMF/UEFI** — только SeaBIOS.
- **Не создавать snapshot** для шаблона в UI (не даст — это read-only).
---

_Документ создан: октябрь 2026._
_Версия Astra Linux: 1.8.6 SE_