#!/bin/bash

# Создаем директорию для мониторинга
mkdir -p "${MONITORING_DIR}"
chmod 755 "${MONITORING_DIR}"
chown "${APP_USER}:${APP_USER}" "${MONITORING_DIR}"

# Копируем и настраиваем файлы
cp monitoring-docker-compose.yml.j2 "${MONITORING_DIR}/docker-compose.yml"
cp prometheus.yml.j2 "${MONITORING_DIR}/prometheus.yml"

# Устанавливаем права
chmod 644 "${MONITORING_DIR}/docker-compose.yml"
chmod 644 "${MONITORING_DIR}/prometheus.yml"
chown "${APP_USER}:${APP_USER}" "${MONITORING_DIR}/docker-compose.yml"
chown "${APP_USER}:${APP_USER}" "${MONITORING_DIR}/prometheus.yml"

# Запускаем стек мониторинга
cd "${MONITORING_DIR}"
docker compose up -d
