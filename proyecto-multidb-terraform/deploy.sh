#!/bin/bash

# Cargar variables de entorno
set -a
source .env
set +a

#!/bin/bash
# 1. Borrar todo rastro anterior
docker-compose down -v
docker volume prune -f

# 2. Levantar los servicios sin los scripts primero para crear el volumen db_scripts
docker-compose up -d --build

# 3. Copiar tus scripts locales al volumen de Docker
docker cp init-scripts/01-mysql.sql db_mysql_users:/docker-entrypoint-initdb.d/
docker cp init-scripts/02-postgres.sql db_postgres_inventory:/docker-entrypoint-initdb.d/

# 4. Reiniciar los contenedores para que ejecuten los scripts copiados
docker-compose restart db_mysql_users db_postgres_inventory

echo "--- Despliegue completado ---"
docker ps

