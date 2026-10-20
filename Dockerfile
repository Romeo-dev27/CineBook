# Multi-stage production Dockerfile pour CineBook Backend (FastAPI + SQLite)
FROM python:3.12-slim AS builder

WORKDIR /app

# Installation des dépendances de compilation si nécessaire
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt requirements.txt
RUN pip install --no-cache-dir --user -r requirements.txt

# Étape finale
FROM python:3.12-slim

WORKDIR /app

# Copie des packages python installés depuis le builder
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Copie du code source et des données matricielles nécessaires au seed
COPY backend/ /app/backend/
COPY data_pipeline/data/feature_matrix.json /app/data_pipeline/data/feature_matrix.json
COPY data_pipeline/data/color_features.json /app/data_pipeline/data/color_features.json
COPY data_pipeline/data/enriched_tags.json /app/data_pipeline/data/enriched_tags.json

# Initialisation et peuplement immédiat de la base SQLite
RUN python -m backend.seed_db

# Utilisateur non-root pour la sécurité
RUN addgroup --system cinebook && adduser --system --group cinebook \
    && chown -R cinebook:cinebook /app
USER cinebook

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD python -c "import os, urllib.request; urllib.request.urlopen('http://localhost:' + os.environ.get('PORT', '8000') + '/health')" || exit 1

CMD ["sh", "-c", "uvicorn backend.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 2"]
