import os
from fastapi import FastAPI
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# 1. Leemos las URLs inyectadas por Terraform
MYSQL_URL = os.getenv("MYSQL_URL")
POSTGRES_URL = os.getenv("POSTGRES_URL")

# 2. Creamos los dos motores de búsqueda
engine_mysql = create_engine(MYSQL_URL)
engine_pg = create_engine(POSTGRES_URL)

SessionMySQL = sessionmaker(bind=engine_mysql)
SessionPG = sessionmaker(bind=engine_pg)

app = FastAPI()

@app.get("/health")
def health_check():
    # Validación de salud dual
    status = {"service": "running"}
    try:
        engine_mysql.connect()
        status["mysql"] = "connected"
    except:
        status["mysql"] = "error"
    
    try:
        engine_pg.connect()
        status["postgres"] = "connected"
    except:
        status["postgres"] = "error"
    
    return status

@app.post("/sync-data")
def sync_example(user_id: int, item_name: str):
    # Aquí podrías guardar el usuario en MySQL y
    # reservar su primer ítem en el inventario de Postgres
    return {"message": "Datos sincronizados en ambas BDs"}