import os
from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker, declarative_base

# 1. Leemos las URLs inyectadas
MYSQL_URL = os.getenv("MYSQL_URL")
POSTGRES_URL = os.getenv("POSTGRES_URL")

# 2. Creamos los motores
engine_mysql = create_engine(MYSQL_URL)
engine_pg = create_engine(POSTGRES_URL)

SessionMySQL = sessionmaker(bind=engine_mysql)
SessionPG = sessionmaker(bind=engine_pg)

# Base para los modelos
Base = declarative_base()

# --- Definición de Modelos ---
class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    name = Column(String(100))

class Inventory(Base):
    __tablename__ = 'inventory'
    id = Column(Integer, primary_key=True)
    item_name = Column(String(100))
    user_id = Column(Integer) # Referencia lógica a MySQL

# Crear tablas si no existen
Base.metadata.create_all(engine_mysql)
Base.metadata.create_all(engine_pg)

app = FastAPI()

@app.get("/health")
def health_check():
    status = {"service": "running"}
    try:
        engine_mysql.connect().close()
        status["mysql"] = "connected"
    except Exception as e:
        status["mysql"] = f"error: {str(e)}"

    try:
        engine_pg.connect().close()
        status["postgres"] = "connected"
    except Exception as e:
        status["postgres"] = f"error: {str(e)}"

    return status

# --- Endpoint de Sincronización ---
@app.post("/sync-data")
def sync_example(user_id: int, user_name: str, item_name: str):
    session_ms = SessionMySQL()
    session_pg = SessionPG()

    try:
        # 1. Guardar en MySQL
        new_user = User(id=user_id, name=user_name)
        session_ms.add(new_user)
        session_ms.commit()

        # 2. Guardar en Postgres
        new_item = Inventory(item_name=item_name, user_id=user_id)
        session_pg.add(new_item)
        session_pg.commit()

        return {
            "message": "Datos sincronizados exitosamente",
            "user": user_name,
            "item": item_name
        }

    except Exception as e:
        print(f"Error detallado: {str(e)}")
        session_ms.rollback()
        session_pg.rollback()
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        session_ms.close()
        session_pg.close()
