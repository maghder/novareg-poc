#!/usr/bin/env bash
# Génère directus/snapshots/snapshot.yaml en réutilisant les mêmes variables
# d'environnement que start-directus.sh (même clé locale, mêmes secrets).
set -euo pipefail

cd "$(dirname "$0")/../directus"

: "${DB_CONNECTION_STRING:?DB_CONNECTION_STRING manquant (secret Codespaces).}"
: "${DIRECTUS_SECRET:?DIRECTUS_SECRET manquant (secret Codespaces).}"

KEY_FILE=".directus-key"
if [ ! -f "$KEY_FILE" ]; then
  echo "Aucune clé locale (.directus-key) trouvée."
  echo "Lancez d'abord ./scripts/start-directus.sh au moins une fois, puis relancez ce script."
  exit 1
fi

export KEY="$(cat "$KEY_FILE")"
export SECRET="$DIRECTUS_SECRET"
export DB_CLIENT="pg"
export DB_CONNECTION_STRING

mkdir -p snapshots
npx directus schema snapshot ./snapshots/snapshot.yaml --yes
echo "Snapshot écrit : directus/snapshots/snapshot.yaml"
