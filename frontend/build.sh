#!/usr/bin/env bash
# build.sh — Compilation automatisée de Flutter Web pour Vercel / CI
set -eo pipefail

FLUTTER_VERSION="3.38.5"
FLUTTER_CHANNEL="stable"

# L'archive officielle du SDK Flutter preserve un uid propriétaire : sur l'image
# de build Vercel (root), git déclare alors le dépôt "dubious ownership" et
# `flutter --version` sort en code 128. Gardé conditionnel au root pour ne pas
# modifier la configuration git globale d'un poste de développement.
if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
  git config --global --add safe.directory '*'
fi

if [ -z "${API_URL:-}" ]; then
  echo "❌ API_URL manquant. Ex : API_URL=https://<ton-service-render>/api" >&2
  exit 1
fi

echo "🎬 CineBook Frontend — Démarrage du build Flutter Web..."
echo "🌐 API_URL : $API_URL"

if ! command -v flutter &> /dev/null; then
  echo "📦 Téléchargement du SDK Flutter ($FLUTTER_VERSION, ~1.6 Go)..."
  mkdir -p "$HOME/flutter_sdk"
  curl -fsSL -o "$HOME/flutter.tar.xz" \
    "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
  tar -xJf "$HOME/flutter.tar.xz" -C "$HOME/flutter_sdk"
  rm -f "$HOME/flutter.tar.xz"
  export PATH="$HOME/flutter_sdk/flutter/bin:$PATH"
fi

export CI=true

echo "🔍 Version Flutter active :"
flutter --version

echo "📥 Téléchargement des dépendances pub..."
flutter pub get

echo "🔧 Compilation Flutter Web..."
flutter build web --release --no-tree-shake-icons --pwa-strategy=none --dart-define=API_URL="$API_URL"

echo "🎉 Compilation terminée dans build/web !"
