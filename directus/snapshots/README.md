Le fichier `snapshot.yaml` apparaîtra ici après l'étape 7 du runbook
(`docs/SETUP.md`), une fois Directus démarré via `./scripts/start-directus.sh`
et les collections du module Bureau d'Ordre configurées dans l'admin :

    npx directus schema snapshot ./directus/snapshots/snapshot.yaml --yes

(à exécuter depuis `directus/`, ou avec le chemin relatif ajusté).

Committez ensuite ce fichier : il permet de reproduire à l'identique la
configuration des collections sur tout nouveau Codespace / toute nouvelle
base Neon de test, via :

    npx directus schema apply ./directus/snapshots/snapshot.yaml --yes
