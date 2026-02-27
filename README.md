--Ejercicio de microservicios

1. Estructura de Directorios
Ejecuta estos comandos en tu terminal para crear el esqueleto del proyecto:

# Crear carpeta raiz
mkdir proyecto-multidb-terraform && cd proyecto-multidb-terraform

# Crear carpeta para el código del microservicio
mkdir user-service

# Crear carpeta para la infraestructura (Terraform)
mkdir terraform

/proyecto-multidb-terraform
 /user-service
   main.py
   requirements.txt
   Dockerfile
 /terraform
   main.tf
   variables.tf
   secretos.tfvars

2. Archivos de Configuración (Contenido rápido)
En /user-service/requirements.txt

En /terraform/variables.tf:
(Definimos qué variables necesitamos sin poner los valores reales aún).

En /terraform/secretos.tfvars:
Importante: Este archivo es el que contiene tus contraseñas reales.

3. Instrucciones de Ejecución (Paso a Paso)
Sigue este orden exacto para evitar errores de "imagen no encontrada" o "conexión rechazada":

----------------------------------------------------

Fase 1: El Empaquetado (Dockerfile)
Para que Terraform pueda gestionar nuestro microservicio, primero necesitamos convertir nuestro código Python en una Imagen de Docker. Crea un archivo llamado Dockerfile en la carpeta user-service/.

Dockerfile

Fase 2: La Infraestructura Robusta (main.tf)
Aquí es donde ocurre la magia de la orquestación. Vamos a definir que el servicio de Python depende de que las bases de datos estén listas.

main.tf

----------------------------------------------------

Fase 3: Lógica Multi-Base de Datos (main.py)
Ahora configuramos FastAPI para que hable con ambos mundos. Usaremos variables de entorno para las conexiones, lo que hace que nuestro código sea "agnóstico" a la infraestructura.

main.py

Pasos finales para ejecutar:

Paso 1: Construir la imagen de Docker
Terraform necesita que la imagen exista antes de intentar levantar el contenedor.

Bash
cd user-service
docker build -t user-service:latest .
cd ..

Paso 2: Inicializar y Desplegar con Terraform
Ahora vamos a la carpeta de infraestructura para dar las órdenes.

Bash
cd terraform
terraform init
terraform apply -var-file="secretos.tfvars"
Terraform te pedirá confirmación escribiendo yes.

Construye la imagen: docker build -t user-service:latest ./user-service

Prepara secretos: Crea tu archivo secretos.tfvars con las contraseñas.

Despliega: terraform apply -var-file="secretos.tfvars"

----------------------------------------------------

4. Script de Verificación (Smoke Test)
Una vez que Terraform termine, puedes verificar que todo el "engranaje" funciona con este comando de terminal:

Bash
# Verificar salud del servicio y conexiones a las 2 DBs
curl http://localhost:8001/health
Resultado esperado:

JSON
{
  "service": "running",
  "mysql": "connected",
  "postgres": "connected"
}

----------------------------------------------------

5. Mantenimiento y Cierre
Si haces cambios en el código Python: Debes repetir el docker build y luego hacer un terraform apply (Terraform detectará que la imagen cambió y reiniciará el contenedor).

Para borrar todo el entorno:
terraform destroy -var-file="secretos.tfvars"