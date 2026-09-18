# POC NOVAREG — Directus (sans Docker) + PostgreSQL (Neon) + Vue.js
### Processus pilote : Bureau d'Ordre

POC de transformation de processus métier bâti sur le schéma canonique
`01_novareg_schema.sql`. Directus s'exécute **sans Docker**, comme un simple
process Node dans GitHub Codespaces — même logique que
[maghder/GEDMVP](https://github.com/maghder/GEDMVP) : secrets Codespaces →
devcontainer Node seul → script de démarrage → port 8055. Un frontend
Vue.js consomme l'API pour le cycle de vie du courrier (enregistrement →
orientation → traitement → expédition → accusé de réception).

**Démarrez ici : [`docs/SETUP.md`](docs/SETUP.md)**

## Arborescence

```
db/                       Scripts SQL, à exécuter dans cet ordre contre Neon
  01_novareg_schema.sql        schéma canonique (fourni en entrée du POC)
  02_novareg_seed.sql          référentiels (tables cfg_*)
  03_bo_demo_data.sql        jeu de données de démonstration Bureau d'Ordre

directus/                 Directus comme dépendance npm (pas d'image Docker)
  package.json               dépendance "directus"
  snapshots/                 snapshot de collections (généré à l'étape 7 du runbook)

scripts/
  start-directus.sh          bootstrap + démarrage, à partir des 4 secrets

frontend/                 App Vue.js (Vite) — liste, détail, création de courrier

.devcontainer/             Codespaces : image Node 22 seule, aucun Docker
docs/SETUP.md              Runbook détaillé (Neon → Codespaces → Directus → Vue)
```

## Pourquoi pas d'INSERT SQL direct dans les tables `directus_*` ?

Voir `docs/SETUP.md` §0 et §7 : le schéma interne de Directus n'est pas un
contrat stable entre versions. Ce POC utilise le mécanisme officiel —
adoption des tables existantes puis `directus schema snapshot` / `schema
apply` — pour un provisioning tout aussi automatisé mais robuste et
rejouable, exécuté ici en une commande npx directe (plus simple encore que
via Docker, puisqu'il n'y a plus de conteneur à `exec`).

## Périmètre actuel

Seul le module **Bureau d'Ordre** est câblé de bout en bout (SQL → Directus
→ Vue.js). Le reste du schéma (dossiers transversaux, référentiel
réglementaire, actes et décisions) est déjà en base et prêt à être
provisionné selon le même runbook, module par module.
