# Homelab Infrastructure as Code (IaC)

Автоматизированное развертывание тестового стенда с мониторингом Zabbix на базе Proxmox VE. Проект полностью автоматизирует создание виртуальных машин, их настройку и развертывание мониторинга с возможностью запуска из любой точки мира одной кнопкой.

## 🏗 Архитектура

- **Гипервизор:** Proxmox VE (`172.16.0.199`)
- **Управляющая машина:** `mgmt` (Debian, `172.16.0.248`) — здесь настроен Self-hosted GitHub Runner для запуска CI/CD.
- **Целевые VM (Astra Linux 1.8):**
  - `mon` (`172.16.0.200`) — Zabbix Server (Docker: Server, Web, PostgreSQL), Zabbix Agent.
  - `app-01` (`172.16.0.211`) — тестовая VM, Zabbix Agent.

### Схема развертывания и CI/CD

```text
[Инженер] 
    │ (Запускает Run workflow в GitHub)
    ▼
[GitHub Actions (CI/CD)] 
    │ 
    ▼
[mgmt (Self-hosted Runner)] ───(Terraform)───► [Proxmox VE]
    │                                              │
    │                                              ├─► [VM mon (Zabbix Server)]
    │                                              └─► [VM app-01 (Agent)]
    │
    └──(Ansible)───► [Настройка и мониторинг VM]
       
🛠 Технологический стек

Terraform: Создание VM (модуль vm), настройка cloud-init, автоматическая генерация Ansible inventory.

Ansible: Настройка ОС (hardening, UFW), установка Docker, развертывание Zabbix, регистрация хостов через API.

Docker Compose: Запуск Zabbix Server, Web и PostgreSQL.

GitHub Actions: CI/CD пайплайн с ручным запуском (кнопка "Run workflow") и self-hosted runner'ом на базе mgmt.

📱 Управление с телефона (Zero-Touch Deploy)

В проекте настроен GitHub Actions. Вы можете развернуть или обновить всю инфраструктуру прямо с мобильного телефона:

Откройте репозиторий на GitHub.

Перейдите в раздел Actions.

Выберите Deploy Homelab Infrastructure.

Нажмите Run workflow.

Скриншот успешного запуска из мобильного приложения:
![Mobile Deploy Screenshot](docs/images/mobile-deploy.jpg)

🚀 Как развернуть с нуля (вручную)
Настройте доступ к Proxmox API.

Заполните terraform.tfvars (токены, SSH-ключ).

Создайте VM (Terraform автоматически сгенерирует hosts.yml для Ansible):

bash
cd terraform/environments/homelab
terraform init
terraform apply
Запустите настройку Ansible (с машины mgmt):

bash
cd ansible
ansible-playbook playbooks/site.yml

✅ Как проверить
Зайдите в Zabbix Web UI: http://172.16.0.200:8080 (Admin / пароль из Ansible Vault).

Перейдите в Data collection -> Hosts. Вы должны увидеть Zabbix server и app-01.

Проверьте Monitoring -> Latest data — с агентов должны поступать данные (CPU, RAM и т.д.).
