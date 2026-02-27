terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {
  # Este bloque le dice a Terraform que se conecte al Docker Desktop 
  # o servicio de Docker que tienes corriendo en tu máquina.
}

# 1. Red de microservicios
resource "docker_network" "app_network" {
  name = "app_network_internal"
}

# 2. Contenedor MySQL (Perfiles de Usuario)
resource "docker_container" "mysql_db" {
  name  = "db_mysql_users"
  image = "mysql:8.0"
  networks_advanced { name = docker_network.app_network.name }
  env = [
    "MYSQL_ROOT_PASSWORD=${var.db_password}",
    "MYSQL_DATABASE=${var.db_name}",
    "MYSQL_USER=${var.db_user}",
    "MYSQL_PASSWORD=${var.db_password}"
  ]
}

# 3. Contenedor PostgreSQL (Inventario)
resource "docker_container" "postgres_db" {
  name  = "db_postgres_inventory"
  image = "postgres:15-alpine"
  networks_advanced { name = docker_network.app_network.name }
  env = [
    "POSTGRES_USER=${var.pg_user}",
    "POSTGRES_PASSWORD=${var.pg_password}",
    "POSTGRES_DB=${var.pg_db_name}"
  ]
}

# 4. El Microservicio Dual
resource "docker_container" "python_service" {
  name  = "api_gateway_service"
  # Usamos la imagen que construimos localmente
  image = "user-service:latest"
  networks_advanced { name = docker_network.app_network.name }

  ports {
    internal = 8001
    external = 8001
  }

  env = [
    "MYSQL_URL=mysql+pymysql://${var.db_user}:${var.db_password}@db_mysql_users:3306/${var.db_name}",
    "POSTGRES_URL=postgresql://${var.pg_user}:${var.pg_password}@db_postgres_inventory:5432/${var.pg_db_name}"
  ]

  # CRUCIAL: Terraform esperará a que las BDs se creen primero
  depends_on = [
    docker_container.mysql_db,
    docker_container.postgres_db
  ]
}
