#!/bin/bash
set -a
source .env
set +a

NETWORK_NAME="app_network_internal"
INIT_SCRIPTS_PATH="/home/humic/bucket-archivos/proyecto-multidb/init-scripts"
SCRIPTS_TEMP_PATH="/tmp/processed-scripts"

# Crear directorio temporal para scripts procesados
mkdir -p $SCRIPTS_TEMP_PATH

# 1. Crear Red
docker network create $NETWORK_NAME || true

# --- PROCESAR SCRIPTS SQL CON SED ---
# Procesar MySQL
sed -e "s/\${MYSQL_USER}/$MYSQL_USER/g" \
    -e "s/\${MYSQL_PASSWORD}/$MYSQL_PASSWORD/g" \
    $INIT_SCRIPTS_PATH/01-mysql.sql > $SCRIPTS_TEMP_PATH/01-mysql.sql

# Procesar Postgres
sed -e "s/\${POSTGRES_APP_USER}/$POSTGRES_APP_USER/g" \
    -e "s/\${POSTGRES_APP_PASSWORD}/$POSTGRES_APP_PASSWORD/g" \
    $INIT_SCRIPTS_PATH/02-postgres.sql > $SCRIPTS_TEMP_PATH/02-postgres.sql

# 2. Levantar MySQL (Montando script procesado)
docker run -d \
  --name db_mysql_users \
  --network $NETWORK_NAME \
  -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
  -v $SCRIPTS_TEMP_PATH/01-mysql.sql:/docker-entrypoint-initdb.d/01-mysql.sql \
  mysql:8.0 --default-authentication-plugin=mysql_native_password

# 3. Levantar Postgres (Montando script procesado)
docker run -d \
  --name db_postgres_inventory \
  --network $NETWORK_NAME \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e POSTGRES_DB=$POSTGRES_DB \
  -v $SCRIPTS_TEMP_PATH/02-postgres.sql:/docker-entrypoint-initdb.d/02-postgres.sql \
  postgres:15-alpine

# Esperar a que las BDs inicien
echo "Esperando a que las bases de datos inicialicen..."
sleep 20

# 4. Levantar la API
docker build -t user-service:latest ./user-service
docker run -d \
  --name api_gateway_service \
  --network $NETWORK_NAME \
  -p 8001:8001 \
  -e MYSQL_URL="mysql+pymysql://$MYSQL_USER:$MYSQL_PASSWORD@db_mysql_users:3306/$MYSQL_DATABASE" \
  -e POSTGRES_URL="postgresql://$POSTGRES_APP_USER:$POSTGRES_APP_PASSWORD@db_postgres_inventory:5432/$POSTGRES_DB" \
  user-service:latest

echo "--- Despliegue completado ---"
docker ps

#curl http://localhost:8001/health
