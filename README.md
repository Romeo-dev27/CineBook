# 🎬 CineBook - AI Cinematic Vibe & Recommendation Engine

> Plateforme de recommandation de films intelligente basée sur l'atmosphère, l'esthétique visuelle, les palettes de couleurs et le rythme, plutôt que sur de simples notes numériques.

---

## 🏗️ Architecture du Projet (Monorepo)

```text
CineBook/
├── backend/        # API REST Python 3 & FastAPI + Base de données SQLite / SQLAlchemy
├── frontend/       # Application Flutter / Dart (Interface web & mobile en mode sombre)
├── data_pipeline/  # Scripts d'extraction de données (TMDb) et traitement d'image (OpenCV)
└── docs/
    └── images/     # Captures d'écran pour la documentation
```

---

## 🛠️ Stack Technique

| Couche              | Technologies & Outils                                                |
| ------------------- | -------------------------------------------------------------------- |
| **Frontend**        | Flutter / Dart (Responsive Web & Mobile, Material Design dark theme) |
| **Backend**         | Python 3.12, FastAPI, SQLAlchemy, Pydantic                           |
| **Base de Données** | SQLite                                                               |
| **Moteur & Data**   | TMDb API, OpenCV, Algorithme de Similarité Cosinus                   |

---

## 📸 Aperçu de l'Application

### 1. Page d'Accueil (`Home`)

![Accueil](./docs/images/Home.png)

### 2. Recherche et Sélection de Films (`Movie Search`)

![Recherche de films](./docs/images/MovieSearch.png)

### 3. Gestion de la Liste de Souhaits (`WishList`)

![Wishlist](./docs/images/WishList.png)

---

## 🚀 Démarrage Rapide

### 1. Lancer le Backend (FastAPI)

```bash
cd backend
python -m venv .venv
# Activer l'environnement virtuel (.venv\Scripts\activate sous Windows)
pip install -r requirements.txt
uvicorn main:app --reload
```

### 2. Lancer le Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## ✨ Fonctionnalités Clés (V2)

- **Sélection multiple (Multi-seed Vibe Builder) :** Combine plusieurs films pour moyenner et mixer leurs ambiances esthétiques.
- **Extraction de palettes visuelles :** Analyse des couleurs dominantes pour identifier des œuvres aux harmonies similaires.
- **Documentation API interactive :** Accessible en local via Swagger UI (`/docs`).
