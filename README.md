# IFMO_DistributedComputing_for_DevOps
Distributed Computing course for DevOps 2025

## Описание
Проект для автоматизированного развертывания WordPress с использованием Docker и системы мониторинга на базе Prometheus, Grafana и cAdvisor.

## Системные требования
- Ubuntu 24.04
- Ansible >= 6.0
- Docker на целевых серверах
- Минимум 2 ГБ оперативной памяти
- Минимум 5 ГБ свободного места на диске

## Подготовка к запуску

### 1. Установка зависимостей

Перед запуском плейбука необходимо установить требуемые коллекции Ansible:

```bash
ansible-galaxy collection install -r requirements.yml
```

### 2. Настройка окружения

1. Клонировать репозиторий:
   ```bash
   git clone https://github.com/DSugakov/IFMO_DistributedComputing_for_DevOps.git
   cd IFMO_DistributedComputing_for_DevOps
   ```

2. Настроить inventory файл:
   - Для локального развертывания (на том же сервере):
     ```
     [app_servers]
     localhost ansible_connection=local
     ```
   - Для удаленного развертывания:
     ```
     [app_servers]
     target_server ansible_host=<IP-адрес> ansible_user=<пользователь> ansible_ssh_private_key_file=~/.ssh/id_rsa
     ```

3. Настроить переменные в `vars/main.yml`:
   - Пароли MySQL
   - Пользователи WordPress
   - Настройки мониторинга

## Варианты запуска

### Вариант 1: Полное развертывание (рекомендуется)

Запустите основной плейбук для полной настройки системы:
```bash
ansible-playbook playbook.yml -i inventory -K
```

Этот плейбук выполнит:
- Установку Docker и Docker Compose
- Настройку пользователей и прав доступа
- Развертывание WordPress с MySQL кластером
- Настройку системы мониторинга

### Вариант 2: Поэтапное развертывание

#### Шаг 1: Развертывание приложения
```bash
ansible-playbook deploy_app.yml -i inventory -K
```

#### Шаг 2: Развертывание мониторинга
```bash
ansible-playbook deploy_monitoring.yml -i inventory -K
```

### Вариант 3: Обновление конфигурации

Для обновления только мониторинга без пересоздания приложения:
```bash
ansible-playbook deploy_monitoring.yml -i inventory -K
```

**Примечание:** Флаг `-K` запрашивает sudo пароль и требуется только при первом запуске или при изменении системных настроек.

## Проверка развертывания

После завершения плейбука проверьте статус контейнеров:
```bash
docker ps
```

Все контейнеры должны быть в статусе "Up":
```
CONTAINER ID   IMAGE                          STATUS
xxxxxxxxx      bitnami/wordpress:6            Up X hours
xxxxxxxxx      bitnami/mysql:8.0              Up X hours  
xxxxxxxxx      prom/mysqld-exporter:v0.14.0   Up X hours
xxxxxxxxx      grafana/grafana:latest         Up X hours
xxxxxxxxx      prom/prometheus:latest         Up X hours
```

Если какие-то контейнеры не запустились, проверьте логи:
```bash
docker logs <container_name>
```

## Доступ к сервисам

После успешного деплоя, сервисы будут доступны по следующим адресам:

- **WordPress**: http://<host>:8080
- **Grafana**: http://<host>:3000 
  - Логин: `monadmin` (или значение `monitoring_grafana_user` из vars/main.yml)
  - Пароль: `monpassword` (или значение `monitoring_grafana_password` из vars/main.yml)
- **Prometheus**: http://<host>:9090
- **MySQL Exporter**: http://<host>:9104

## Настройка мониторинга

### Grafana

После развертывания мониторинга источник данных Prometheus и дашборд MySQL настраиваются автоматически:

- ✅ Источник данных **Prometheus** (URL: http://prometheus:9090)
- ✅ Дашборд **MySQL Basic (mysqld_exporter)** для мониторинга базы данных
- ✅ Автоматическое обнаружение метрик MySQL

**Доступные метрики:**
- MySQL Threads Connected - количество активных подключений
- MySQL Queries/sec - количество запросов в секунду
- MySQL Connection Errors - ошибки подключений
- MySQL Slow Queries - медленные запросы

### Prometheus

Prometheus автоматически собирает метрики с:
- MySQL Exporter (порт 9104) - метрики базы данных
- cAdvisor (порт 8080) - метрики контейнеров
- Node Exporter (если настроен) - метрики системы

## Устранение неполадок

### Проблемы с контейнерами
```bash
# Перезапуск всех сервисов
cd /home/wordpress/wordpress
docker compose down
docker compose up -d

# Проверка логов конкретного сервиса
docker logs wordpress-grafana-1
docker logs wordpress-prometheus-1
docker logs wordpress-mysqld_exporter-1
```

### Проблемы с Grafana
```bash
# Проверка provisioning файлов
docker exec -it wordpress-grafana-1 ls -la /etc/grafana/provisioning/
docker exec -it wordpress-grafana-1 cat /etc/grafana/provisioning/dashboards/mysql-dashboard.yml

# Проверка дашбордов
docker exec -it wordpress-grafana-1 ls -la /var/lib/grafana/dashboards/
```

### Проблемы с правами доступа
```bash
# Исправление прав на файлы Grafana
sudo chown -R 472:472 /opt/wp_app/grafana/
sudo chmod -R 755 /opt/wp_app/grafana/
```

### Переустановка мониторинга
```bash
# Полная переустановка мониторинга
docker compose down
ansible-playbook deploy_monitoring.yml -i inventory -K
```

## Архитектура системы

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   WordPress     │    │   MySQL Cluster  │    │   Monitoring    │
│   (Port 8080)   │◄──►│   (Ports 3306-   │    │                 │
│                 │    │    3308)         │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │ MySQL Exporter   │    │   Prometheus    │
                       │  (Port 9104)     │───►│   (Port 9090)   │
                       └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │    Grafana      │
                                               │   (Port 3000)   │
                                               └─────────────────┘
```

## Дополнительные возможности

### Масштабирование
Для добавления новых узлов MySQL отредактируйте `vars/main.yml` и добавьте новые узлы в секцию `cluster_nodes`.

### Бэкапы
Настройте регулярные бэкапы MySQL:
```bash
# Пример команды бэкапа
docker exec wordpress-node1-1 mysqldump -u root -p<password> --all-databases > backup.sql
```

### Мониторинг дополнительных метрик
Добавьте дополнительные exporters в `docker-compose.yml` для мониторинга системных метрик.