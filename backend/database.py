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

# Charge les variables d'environnement depuis le .env à la racine ou dans backend
ROOT_DIR = Path(__file__).resolve().parent.parent
load_dotenv(ROOT_DIR / ".env")
load_dotenv(Path(__file__).resolve().parent / ".env")

_env_db_url = os.getenv("DATABASE_URL")
if not _env_db_url or _env_db_url == "sqlite:///./cinebook.db":
    # Assure un chemin absolu vers cinebook.db pour éviter la création d'une DB vide
    # selon le répertoire d'exécution (root vs backend)
    db_path = ROOT_DIR / "cinebook.db"
    if not db_path.exists() and (Path(__file__).resolve().parent / "cinebook.db").exists():
        db_path = Path(__file__).resolve().parent / "cinebook.db"
    DATABASE_URL = f"sqlite:///{db_path}"
elif _env_db_url.startswith("sqlite:///./"):
    rel_path = _env_db_url.replace("sqlite:///./", "")
    db_path = ROOT_DIR / rel_path
    if not db_path.exists() and (Path(__file__).resolve().parent / rel_path).exists():
        db_path = Path(__file__).resolve().parent / rel_path
    DATABASE_URL = f"sqlite:///{db_path}"
else:
    DATABASE_URL = _env_db_url

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
