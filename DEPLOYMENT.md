# 🚀 Guide de Déploiement en Production — CineBook

Ce guide détaille la mise en ligne complète du projet CineBook :
- **Backend API (FastAPI + SQLite)** sur **Render**
- **Frontend Client (Flutter Web)** sur **Vercel**

---

## 🏗️ 1. Architecture de Déploiement

```
                   ┌──────────────────────────────────────────────┐
                   │               UTILISATEUR                    │
                   └──────────────────────┬───────────────────────┘
                                          │
                   ┌──────────────────────┴───────────────────────┐
                   │                                              │
                   ▼ (HTTPS)                                      ▼ (HTTPS / API)
┌──────────────────────────────────────┐       ┌──────────────────────────────────────┐
│        VERCEL (Edge CDN)             │       │         RENDER (Web Service)         │
│  • Frontend Flutter Web              │──────▶│  • FastAPI Python 3.12 Backend       │
│  • build/web (HTML5 / CanvasKit)     │       │  • Moteur Cosinus Pondéré (NumPy)    │
│  • Single Page App (SPA Rewrites)    │       │  • Base SQLite locale (142 films)    │
│  • Routing & Caching mondial         │       │  • Auth JWT (compatible Supabase)    │
└──────────────────────────────────────┘       └──────────────────────────────────────┘
```

---

## 🐍 2. Déploiement du Backend sur Render

Render permet d'héberger gratuitement notre API FastAPI avec redémarrage automatique et certificat SSL HTTPS inclus.

### Option A : Déploiement automatique via `render.yaml` (Recommandé)
1. Pousse ton code sur ton dépôt GitHub (`git push origin master`).
2. Rends-toi sur [dashboard.render.com](https://dashboard.render.com).
3. Clique sur **"New +"** puis sélectionne **"Blueprint"**.
4. Connecte ton dépôt GitHub `CineBook` : Render détectera automatiquement le fichier [`render.yaml`](./render.yaml).
5. Clique sur **"Apply"** : Render installe les dépendances, peuple la base de données SQLite via `seed_db.py`, et démarre Uvicorn !

### Option B : Déploiement manuel via Web Service
1. Sur Render, clique sur **"New +"** -> **"Web Service"**.
2. Choisis ton dépôt GitHub `CineBook`.
3. Configure les champs suivants :
   - **Name** : `cinebook-api`
   - **Language / Runtime** : `Python 3`
   - **Region** : `Frankfurt (EU Central)`
   - **Branch** : `master`
   - **Build Command** : `./build.sh` (ou `pip install -r backend/requirements.txt && python -m backend.seed_db`)
   - **Start Command** : `./start.sh` (ou `uvicorn backend.main:app --host 0.0.0.0 --port $PORT --workers 2`)
4. Dans **Environment Variables**, ajoute :
   - `PYTHON_VERSION` = `3.12.8`
   - `PYTHONPATH` = `.`
   - `JWT_SECRET` = `(génère une clé secrète aléatoire de 32 caractères)`
5. Clique sur **"Create Web Service"**.
6. Une fois le déploiement terminé, teste ton API en ouvrant :
   - `https://cinebook-api.onrender.com/health` (doit renvoyer `{"status": "healthy", "indexed_movies": 142}`)
   - `https://cinebook-api.onrender.com/docs` (Swagger UI complet en direct)

---

## 🌐 3. Déploiement du Frontend Flutter Web sur Vercel

Vercel offre une vitesse de chargement optimale grâce à son réseau mondial Edge.

### Étape 1 : Récupérer l'URL de ton Backend Render
Note l'URL de ton API déployée sur Render (par exemple : `https://cinebook-api.onrender.com/api`).

### Étape 2 : Déploiement sur Vercel
1. Rends-toi sur [vercel.com](https://vercel.com) et connecte-toi avec ton compte GitHub.
2. Clique sur **"Add New..."** -> **"Project"**.
3. Importe le dépôt `CineBook`.
4. Dans les paramètres de configuration du projet (**Project Settings**) :
   - **Framework Preset** : Sélectionne **Other**.
   - **Root Directory** : Clique sur Edit et sélectionne le dossier `frontend` (ou laisse vide si tu utilises le `vercel.json` racine).
   - **Build Command** : `bash ./build.sh` (ou laisse vide, le `package.json` s'en charge).
   - **Output Directory** : `build/web`.
5. Dans la section **Environment Variables**, ajoute :
   - `API_URL` = `https://cinebook-api.onrender.com/api` (remplace avec ton URL Render exacte).
6. Clique sur **"Deploy"**.

---

## ⚡ 4. Alternative Express pour Soutenance (Déploiement en 30 secondes via CLI Vercel)

Si tu souhaites compiler Flutter Web localement sur ta machine et déployer le résultat instantanément sur Vercel :

```powershell
# 1. Compiler Flutter Web avec l'URL de ton API Render
cd C:\Projets_ESST\CineBook\frontend
flutter build web --release --no-tree-shake-icons --dart-define=API_URL="https://cinebook-api.onrender.com/api"

# 2. Déployer directement le dossier build/web sur Vercel
cd build\web
npx vercel --prod
```

En moins de 30 secondes, ton application Web est en ligne et accessible publiquement avec un lien `.vercel.app` sécurisé !

---

## ✅ 5. Checklist de Validation Finale

- [x] Backend testé avec 31 tests unitaires et d'intégration (`pytest` à 100%).
- [x] Base SQLite initialisée avec 142 films et 5 vecteurs normalisés.
- [x] Frontend analysé sans aucune erreur (`dart analyze`).
- [x] Authentification par JWT et gestion de Watchlists isolées par utilisateur.
- [x] Fichiers de déploiement Render créés (`render.yaml`, `Dockerfile`, `build.sh`, `start.sh`).
- [x] Fichiers de déploiement Vercel créés (`frontend/vercel.json`, `frontend/build.sh`, `frontend/package.json`).
