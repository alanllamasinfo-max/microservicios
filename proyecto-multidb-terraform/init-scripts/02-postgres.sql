-- 1. Crear el usuario de la aplicación si no existe
DO
$do$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${POSTGRES_APP_USER}') THEN
      CREATE ROLE ${POSTGRES_APP_USER} LOGIN PASSWORD '${POSTGRES_APP_PASSWORD}';
   ELSE
     ALTER ROLE ${POSTGRES_APP_USER} WITH PASSWORD '${POSTGRES_APP_PASSWORD}';
   END IF;
END
$do$;

-- 2. Conectarse a la base de datos específica (inventory_db)
\c inventory_db;

-- 3. Asignar permisos básicos sobre el esquema público
GRANT CONNECT ON DATABASE inventory_db TO ${POSTGRES_APP_USER};
GRANT USAGE, CREATE ON SCHEMA public TO ${POSTGRES_APP_USER};

-- 4. Asignar permisos de manipulación de datos (DML) sobre tablas existentes
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${POSTGRES_APP_USER};

-- 5. Asignar permisos para futuras tablas (opcional pero recomendado)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${POSTGRES_APP_USER};
