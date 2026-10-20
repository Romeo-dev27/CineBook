#!/usr/bin/env bash
# build.sh — Compilation automatisée de Flutter Web pour Vercel / CI
set -e

FLUTTER_VERSION="3.38.5"
FLUTTER_CHANNEL="stable"

echo "🎬 CineBook Frontend — Démarrage du build Flutter Web..."

# Installation du SDK Flutter sous Linux si absent de l'environnement de build
if ! command -v flutter &> /dev/null; then
  echo "📦 Téléchargement et installation du SDK Flutter ($FLUTTER_VERSION)..."
  mkdir -p "$HOME/flutter_sdk"
  cd "$HOME/flutter_sdk"
  curl -s -L "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" | tar -xJ
  export PATH="$HOME/flutter_sdk/flutter/bin:$PATH"
  cd -
fi

echo "🔍 Version Flutter active :"
flutter --version

echo "📥 Téléchargement des dépendances pub..."
flutter pub get

# Injection de l'URL du Backend Render via --dart-define
API_BASE_URL="${API_URL:-https://cinebook-api.onrender.com/api}"
echo "🌐 Compilation Flutter Web avec API_URL : $API_BASE_URL..."

flutter build web --release --no-tree-shake-icons --dart-define=API_URL="$API_BASE_URL"

echo "🎉 Compilation terminée dans build/web !"
