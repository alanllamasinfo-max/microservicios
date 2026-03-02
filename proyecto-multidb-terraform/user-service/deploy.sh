#!/bin/bash

# Cargar variables de entorno
set -a
source .env
set +a

# Configuración
NETWORK_NAME="app_network_internal"
IMAGE_NAME="user-service:latest"
IMAGE_DIR="./user-service"

# Variables (equivalentes a secretos.tfvars y variables.tf)
DB_PASSWORD="123"
PG_PASSWORD="456"
DB_NAME="users_db"
DB_USER="user_admin"
PG_USER="admin_pg"
PG_DB_NAME="inventory_db"

echo "--- Iniciando despliegue de Docker puro ---"

# 1. Crear la red
if [ ! "$(docker network ls | grep $NETWORK_NAME)" ]; then
  echo "Creando red: $NETWORK_NAME"
  docker network create $NETWORK_NAME
else
  echo "La red $NETWORK_NAME ya existe."
fi

# 2. Levantar MySQL
echo "Levantando contenedor MySQL..."
docker run -d \
  --name db_mysql_users \
  --network $NETWORK_NAME \
  -e MYSQL_ROOT_PASSWORD=$DB_PASSWORD \
  -e MYSQL_DATABASE=$DB_NAME \
  -e MYSQL_USER=$DB_USER \
  -e MYSQL_PASSWORD=$DB_PASSWORD \
  mysql:8.0 --default-authentication-plugin=mysql_native_password

# 3. Levantar PostgreSQL
echo "Levantando contenedor PostgreSQL..."
docker run -d \
  --name db_postgres_inventory \
  --network $NETWORK_NAME \
  -e POSTGRES_USER=$PG_USER \
  -e POSTGRES_PASSWORD=$PG_PASSWORD \
  -e POSTGRES_DB=$PG_DB_NAME \
  postgres:15-alpine

# 4. Construir la imagen de la API
echo "Construyendo imagen de la API..."
docker build -t $IMAGE_NAME $IMAGE_DIR

# 5. Esperar a que las BDs inicien
echo "Esperando 20 segundos a que las bases de datos inicien..."
sleep 20

# 6. Levantar el servicio Python
echo "Levantando contenedor Python API..."
docker run -d \
  --name api_gateway_service \
  --network $NETWORK_NAME \
  -p 8001:8001 \
  -e MYSQL_URL="mysql+pymysql://$DB_USER:$DB_PASSWORD@db_mysql_users:3306/$DB_NAME" \
  -e POSTGRES_URL="postgresql://$PG_USER:$PG_PASSWORD@db_postgres_inventory:5432/$PG_DB_NAME" \
  $IMAGE_NAME

echo "--- Despliegue completado ---"
docker ps
