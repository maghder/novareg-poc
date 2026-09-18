#!/usr/bin/env bash
# Démarre Directus comme simple processus Node dans le Codespace — aucun
# Docker impliqué. Reprend la logique de GEDMVP (maghder/GEDMVP) : 4 secrets
# Codespaces (DB_CONNECTION_STRING, ADMIN_EMAIL, ADMIN_PASSWORD,
# DIRECTUS_SECRET) -> devcontainer -> ce script -> port 8055.
set -euo pipefail

cd "$(dirname "$0")/../directus"

# --- 1. Vérification des 4 secrets attendus ------------------------------
: "${DB_CONNECTION_STRING:?DB_CONNECTION_STRING manquant. Définissez-le comme secret Codespaces (Settings > Secrets and variables > Codespaces) puis relancez un Codespace, ou exportez-le manuellement pour ce terminal.}"
: "${ADMIN_EMAIL:?ADMIN_EMAIL manquant (même remarque que DB_CONNECTION_STRING).}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD manquant (même remarque que DB_CONNECTION_STRING).}"
: "${DIRECTUS_SECRET:?DIRECTUS_SECRET manquant (même remarque que DB_CONNECTION_STRING).}"

# --- 2. Dépendances (au cas où le postCreateCommand n'a pas encore tourné) -
if [ ! -d node_modules ]; then
  echo "Installation de Directus (première exécution)…"
  npm install
fi

# --- 3. KEY technique -----------------------------------------------------
# Directus exige KEY (chiffrement) en plus de SECRET (signature JWT).
# GEDMVP n'en fait pas un secret séparé : on la génère une fois et on la
# garde en local (jamais committée, voir .gitignore) pour rester stable
# entre deux démarrages du même Codespace.
KEY_FILE=".directus-key"
if [ ! -f "$KEY_FILE" ]; then
  node -e "console.log(require('crypto').randomUUID())" > "$KEY_FILE"
fi

# --- 4. Variables d'environnement Directus --------------------------------
export KEY="$(cat "$KEY_FILE")"
export SECRET="$DIRECTUS_SECRET"
export ADMIN_EMAIL
export ADMIN_PASSWORD
export DB_CLIENT="pg"
export DB_CONNECTION_STRING
export HOST="0.0.0.0"
export PORT="8055"

# CORS ouvert : POC de démonstration derrière l'authentification Codespaces/
# Directus, jamais à reproduire tel quel en production.
export CORS_ENABLED="true"
export CORS_ORIGIN="true"

# URL publique correcte à l'intérieur d'un Codespace (nécessaire pour que
# Directus génère des liens absolus cohérents, ex. pièces jointes).
if [ -n "${CODESPACE_NAME:-}" ]; then
  DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  export PUBLIC_URL="https://${CODESPACE_NAME}-${PORT}.${DOMAIN}"
  echo "PUBLIC_URL détectée : $PUBLIC_URL"
fi

# --- 5. Bootstrap (idempotent) puis démarrage -----------------------------
echo "Bootstrap de la base (crée les tables directus_* si absentes, sans toucher aux tables métier)…"
npx directus bootstrap

echo "Démarrage de Directus sur le port $PORT…"
exec npx directus start
