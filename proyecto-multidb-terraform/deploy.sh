#!/bin/bash

# Cargar variables de entorno
set -a
source .env
set +a

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

# 5. Post deploy

# --- Cargar variables de entorno ---
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
else
    echo "¡Error! No se encuentra el archivo .env"
    exit 1
fi

# --- Configuración basada en .env ---
MYSQL_CONTAINER="db_mysql_users"
POSTGRES_CONTAINER="db_postgres_inventory"

# Variables asumidas en el .env:
# MYSQL_ROOT_PASSWORD
# MYSQL_USER
# MYSQL_PASSWORD
# MYSQL_DATABASE
# POSTGRES_USER (admin_pg)
# POSTGRES_PASSWORD
# POSTGRES_DB (inventory_db)
# POSTGRES_APP_USER
# POSTGRES_APP_PASSWORD

echo "=== Iniciando configuración post-despliegue usando .env ==="

# --- Configurar MySQL ---
echo "Configurando MySQL..."
# Esperar un poco a que MySQL inicie por completo
sleep 5
docker exec -i $MYSQL_CONTAINER mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
echo "MySQL configurado."

# --- Configurar PostgreSQL ---
echo "Configurando PostgreSQL..."
# Esperar un poco a que Postgres inicie por completo
sleep 5

# Ejecutar como superusuario (usualmente postgres o el definido en POSTGRES_USER)
docker exec -i $POSTGRES_CONTAINER psql -U ${POSTGRES_USER} -d postgres <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${POSTGRES_APP_USER}') THEN
        CREATE ROLE ${POSTGRES_APP_USER} LOGIN PASSWORD '${POSTGRES_APP_PASSWORD}';
    ELSE
        ALTER ROLE ${POSTGRES_APP_USER} WITH PASSWORD '${POSTGRES_APP_PASSWORD}';
    END IF;
END
\$\$;
EOF

# Aplicar permisos en la base de datos específica
docker exec -i $POSTGRES_CONTAINER psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} <<EOF
GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_APP_USER};
GRANT USAGE, CREATE ON SCHEMA public TO ${POSTGRES_APP_USER};
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${POSTGRES_APP_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${POSTGRES_APP_USER};
EOF
echo "PostgreSQL configurado."

echo "=== Configuración finalizada exitosamente ==="

