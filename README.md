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
     [wordpress_servers]
     localhost ansible_connection=local
     ```
   - Для удаленного развертывания:
     ```
     [wordpress_servers]
     target_server ansible_host=<IP-адрес> ansible_user=<пользователь> ansible_ssh_private_key_file=~/.ssh/id_rsa
     ```

3. Настроить переменные в `vars/main.yml`:
   - Пароли MySQL
   - Пользователи WordPress
   - Настройки мониторинга

### 3. Запуск развертывания

Запустите основной плейбук:
```bash
ansible-playbook playbook.yml -i inventory -K
```
Флаг `-K` запрашивает sudo пароль (требуется только при первом запуске)

Плейбук автоматически:
- Установит Docker и Docker Compose
- Создаст необходимые директории
- Настроит права доступа
- Создаст конфигурационные файлы
- Запустит все сервисы в правильном порядке

### 4. Проверка развертывания

После завершения плейбука проверьте статус контейнеров:
```bash
docker ps
```

Все контейнеры должны быть в статусе "Up". Если какие-то контейнеры не запустились, проверьте логи:
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
- **cAdvisor**: http://<host>:8081 (обратите внимание на изменение порта)

## Подробная инструкция по развертыванию

### 1. Подготовка системы
```bash
# Установка Docker и Docker Compose
sudo apt-get update
sudo apt-get install docker.io docker-compose

# Создание директорий для данных
sudo mkdir -p /var/lib/mysql/node{1,2,3}
sudo mkdir -p /var/lib/wordpress
sudo chown -R 1001:1001 /var/lib/mysql
sudo chown -R 1001:1001 /var/lib/wordpress
```

### 2. Настройка переменных окружения
Создайте файл `.env` в директории проекта:
```bash
# MySQL настройки
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_REPLICATION_USER=repl_user
MYSQL_REPLICATION_PASSWORD=repl_password

# WordPress настройки
WORDPRESS_DATABASE_USER=wordpress
WORDPRESS_DATABASE_PASSWORD=wordpress_password
WORDPRESS_DATABASE_NAME=wordpress
```

### 3. Порядок запуска
```bash
# Запуск MySQL кластера
docker-compose up -d node1 node2 node3

# Ожидание инициализации MySQL (30-60 секунд)
sleep 60

# Запуск WordPress
docker-compose up -d wordpress

# Запуск компонентов мониторинга
docker-compose up -d prometheus grafana mysqld_exporter
```

### 4. Проверка работоспособности
```bash
# Проверка статуса контейнеров
docker ps

# Проверка логов MySQL
docker logs wordpress-node1-1
docker logs wordpress-node2-1
docker logs wordpress-node3-1

# Проверка логов WordPress
docker logs wordpress-wordpress-1
```

### 5. Устранение неполадок
Если контейнеры завершаются с ошибкой:
1. Проверьте логи контейнера: `docker logs <container_name>`
2. Убедитесь, что все переменные окружения установлены
3. Проверьте права доступа к директориям данных
4. Проверьте, что все порты свободны

## Настройка Grafana
1. Войдите в Grafana с учетными данными
2. Добавьте источник данных Prometheus (URL: http://prometheus:9090)
3. Импортируйте готовые дашборды для Docker (ID: 893, 1860, 10619)