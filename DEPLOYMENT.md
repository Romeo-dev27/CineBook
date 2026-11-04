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
   - **Build Command** : `bash ./build.sh` (ou `pip install -r backend/requirements.txt && python -m backend.seed_db`)
   - **Start Command** : `bash ./start.sh` (ou `uvicorn backend.main:app --host 0.0.0.0 --port $PORT --workers 2`)
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

> ⚠️ **L'image de build Vercel n'embarque pas le SDK Flutter.** Le Build Command ne doit
> donc ** jamais** être `flutter build web --release` : c'est `frontend/build.sh` qui
> installe le SDK (1.6 Go) puis compile. `vercel build` retournerait
> `flutter: command not found` (code 127).

### Étape 1 : Récupérer l'URL de ton Backend Render
Note l'URL exacte de ton API (par exemple `https://cinebook-api.onrender.com/api`).

### Étape 2 : Variables d'environnement côté Render
Dans **Render → Service → Environment** :

| Variable | Valeur | Rôle |
|---|---|---|
| `JWT_SECRET` | 32+ caractères aléatoires | Sans elle, une clé éphémère est générée : **toutes les sessions sautent à chaque redémarrage** |
| `TMDB_API_KEY` | ta clé (rotivée) | Plateformes de streaming ; sinon repli sur le cache JSON local |
| `CORS_ALLOW_ORIGINS` | `https://ton-projet.vercel.app` | Autorise l'app web à appeler l'API |

### Étape 3 : Créer le projet Vercel
1. [vercel.com](https://vercel.com) → **Add New... → Project** → importe `CineBook`.
2. **Settings → Build & Development Settings** (le dashboard **écrase** `vercel.json`) :
   - **Framework Preset** : `Other`
   - **Root Directory** : `frontend`
   - **Install Command** : `:`
   - **Build Command** : `bash ./build.sh`
   - **Output Directory** : `build/web`
3. **Settings → Environment Variables** :
   - `API_URL` = `https://<ton-service-render>/api` — **obligatoire**, le build échoue sans lui
     (il évite ainsi de livrer une app pointant sur `127.0.0.1`).
4. **Deploy**. Premier build ~10 min (téléchargement du SDK), sous la limite de 45 min.

### Note sur le cache
`build.sh` compile avec `--pwa-strategy=none` : le service worker Flutter ne retient pas
l'ancienne version, ce qui évite un déploiement invisible après un `flutter build`.


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
- [ ] `TMDB_API_KEY` rotée sur TMDb puis définie comme variable d'environnement Render (l'ancienne clé a été publiée dans l'historique Git).
- [ ] `JWT_SECRET` et `CORS_ALLOW_ORIGINS` définis sur Render.
- [ ] Persistance des comptes : migrer SQLite (filesystem éphémère Render) vers Postgres managé.
