#!/usr/bin/env bash
# Exécuté une fois à la création du Codespace. N'exige aucun secret pour
# fonctionner : il ne fait qu'installer les dépendances npm. Le démarrage de
# Directus lui-même se fait via ./scripts/start-directus.sh (voir docs/SETUP.md).
set -euo pipefail

echo "== Installation des dépendances Directus (sans Docker) =="
(cd directus && npm install)

echo "== Installation des dépendances du frontend =="
(cd frontend && npm install)

cat <<'MSG'

Prochaines étapes (détail dans docs/SETUP.md) :
  1. Configurez les 4 secrets du repo (Settings > Secrets and variables >
     Codespaces) : DB_CONNECTION_STRING, ADMIN_EMAIL, ADMIN_PASSWORD,
     DIRECTUS_SECRET. Ils sont déjà injectés comme variables d'environnement
     dans ce terminal si le Codespace a été (re)créé après leur ajout.
  2. Si ce n'est pas déjà fait, chargez le schéma et les données dans Neon :
       psql "$DB_CONNECTION_STRING" -f db/01_novareg_schema.sql
       psql "$DB_CONNECTION_STRING" -f db/02_novareg_seed.sql
       psql "$DB_CONNECTION_STRING" -f db/03_bo_demo_data.sql
  3. Démarrez Directus :
       ./scripts/start-directus.sh
  4. Ouvrez le port 8055 (onglet Ports), connectez-vous, puis suivez le
     runbook de provisioning des collections (docs/SETUP.md §6).
  5. Démarrez le frontend :
       cd frontend && npm run dev -- --host
MSG
