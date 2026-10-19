"""
database.py — Configuration de la base de données SQLite avec SQLAlchemy 2.0

Gère la connexion à la base SQLite locale, l'activation des clés étrangères (PRAGMA foreign_keys=ON),
la fabrique de sessions (SessionLocal) et la classe de base déclarative (Base).
"""

import os
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine, event
from sqlalchemy.orm import declarative_base, sessionmaker

# Charge les variables d'environnement depuis le .env à la racine
ROOT_DIR = Path(__file__).resolve().parent.parent
load_dotenv(ROOT_DIR / ".env")

DATABASE_URL = os.getenv("DATABASE_URL", f"sqlite:///{ROOT_DIR / 'cinebook.db'}")

# Création du moteur SQLite
# check_same_thread=False permet à FastAPI d'utiliser la session sur différents threads
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
    echo=False
)

# ⚠️ Bonnes pratiques SQLite : activer obligatoirement la vérification des clés étrangères
# Par défaut, SQLite désactive les clés étrangères pour des raisons de compatibilité historique.
@event.listens_for(engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    if DATABASE_URL.startswith("sqlite"):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """Générateur de session pour l'injection de dépendances FastAPI (Jalon 3)."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
