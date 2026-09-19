# POC NOVAREG — Directus (sans Docker) + PostgreSQL (Neon) + Vue.js
## Processus pilote : Bureau d'Ordre

Runbook complet pour faire tourner le POC dans GitHub Codespaces contre une
base Neon, **sans Docker** : Directus s'exécute comme un simple process Node
dans le Codespace, sur le même modèle que
[maghder/GEDMVP](https://github.com/maghder/GEDMVP) (secrets Codespaces →
devcontainer Node seul → script de démarrage → port 8055).

Périmètre couvert : module **Bureau d'Ordre** (courrier entrant/sortant,
orientation, expédition, accusé de réception). Les 32 tables du schéma
restent en place ; les autres modules pourront être provisionnés de la même
façon dans une itération suivante.

---

## 0. Architecture du POC

```
Neon (Postgres managé, TLS)
   └── schéma applicatif (01/02/03) + tables système Directus (directus_*)
            ▲
            │ DB_CONNECTION_STRING
   Directus (process Node, npx directus start — PAS de conteneur)
            ▲                                                    │
            │ dans le même Codespace                    API REST/GraphQL
            │                                                    ▼
   GitHub Codespace ──────────────────────────▶ Frontend Vue.js (Vite, port 5173)
```

Points clés :
- **Aucun Docker.** Le devcontainer est une simple image Node 22 (le
  moteur `isolated-vm` des versions récentes de Directus a besoin d'un
  binaire précompilé pour Node 22). `directus` est installé comme
  dépendance npm dans `directus/`, comme n'importe quel outil CLI Node.
- **Neon héberge tout** : tables métier + tables système `directus_*`
  cohabitent dans la même base.
- **Directus adopte vos tables**, il ne les recrée jamais (mode
  "database-first").
- Le provisioning des collections se fait une fois dans l'admin, puis se
  fige dans un **snapshot versionné** (`directus/snapshots/snapshot.yaml`),
  rejouable sur n'importe quel nouvel environnement via
  `npx directus schema apply` — sans dépendre du format interne (non
  documenté, non stable entre versions) des tables `directus_collections` /
  `directus_fields`.
- **Fichiers non persistants** : comme dans GEDMVP, tout ce qui est
  téléversé directement dans `directus/uploads` disparaît si le Codespace
  est recréé. Seule la base Neon est durable. Un stockage documentaire
  externe (S3 ou équivalent) sera ajouté dans une itération ultérieure.

---

## 1. Base Neon

La base `novareg_poc` est déjà créée sur Neon. Récupérez sa **connection
string** depuis Neon Console → *Connect* si besoin ; elle a cette forme
(le paramètre `channel_binding=require` est ajouté par défaut par Neon
depuis 2024, en plus de `sslmode=require`) :
   ```
   postgresql://<user>:<password>@<ep-xxxx>.<region>.aws.neon.tech/novareg_poc?sslmode=require&channel_binding=require
   ```
Ne la mettez jamais dans un fichier committé — uniquement dans le secret
Codespaces `DB_CONNECTION_STRING` (étape 2).

## 2. Configurer les 4 secrets Codespaces

Dans le dépôt GitHub : **Settings → Secrets and variables → Codespaces →
New repository secret**. Créer exactement ces quatre secrets :

| Secret | Contenu |
|---|---|
| `DB_CONNECTION_STRING` | La chaîne Neon complète de l'étape 1 |
| `ADMIN_EMAIL` | Email du compte admin Directus à créer au premier démarrage |
| `ADMIN_PASSWORD` | Mot de passe de ce compte |
| `DIRECTUS_SECRET` | Valeur aléatoire longue, dédiée à ce POC (`openssl rand -hex 32`) |

Ne jamais mettre ces valeurs dans un fichier committé, même `.env` local
(voir `.env.example` pour le format attendu si vous testez hors Codespaces).

Il n'y a **pas de 5ᵉ secret pour `KEY`** : `scripts/start-directus.sh` en
génère une automatiquement au premier lancement et la garde en local
(`directus/.directus-key`, jamais committée).

## 3. Créer le Codespace

Dans la page du dépôt : **Code → Codespaces → Create codespace on main**.
Le `.devcontainer` installe automatiquement les dépendances npm de
`directus/` et de `frontend/` (`postCreateCommand`). Aucun secret n'est
requis pour cette étape.

> Si les secrets ont été ajoutés *après* la création du Codespace, il faut
> le recréer (ou lancer *Codespaces: Rebuild Container*) pour qu'ils soient
> injectés comme variables d'environnement dans le terminal.

## 4. Charger le schéma et les données dans Neon

Depuis le terminal du Codespace (les secrets y sont déjà exportés comme
variables d'environnement) :

```bash
psql "$DB_CONNECTION_STRING" -f db/01_novareg_schema.sql
psql "$DB_CONNECTION_STRING" -f db/02_novareg_seed.sql
psql "$DB_CONNECTION_STRING" -f db/03_bo_demo_data.sql
```

Vérification :
```sql
SELECT numero_chrono, sens, statut_code, expediteur, destinataire
FROM vw_bo_courriers_suivi ORDER BY numero_chrono;
```
→ doit renvoyer 4 lignes.

## 5. Démarrer Directus

```bash
./scripts/start-directus.sh
```

Le script vérifie les 4 secrets, installe `directus` si besoin (première
fois seulement), génère la `KEY` locale, lance `directus bootstrap` (crée
les tables `directus_*` dans Neon si elles n'existent pas encore — vos
tables `cfg_*`/`org_*`/`core_*`/`doc_*`/`bo_*` ne sont jamais touchées),
puis `directus start`.

Ouvrez le port **8055** (onglet *Ports*) → connexion avec `ADMIN_EMAIL` /
`ADMIN_PASSWORD`.

## 6. Provisionner les collections (Bureau d'Ordre)

Dans l'app Directus : **Paramètres → Modèle de données**. Les tables déjà
présentes en base apparaissent comme *non suivies*. Adoptez-les dans cet
ordre (les M2O sont détectées automatiquement grâce aux clés étrangères déjà
en place dans le SQL) :

| # | Table à adopter | Icône suggérée | Modèle d'affichage | Notes |
|---|---|---|---|---|
| 1 | `org_unites` | `account_tree` | `{{libelle}} ({{code_unite}})` | `parent_id` → arbre auto-détecté |
| 2 | `core_tiers` | `badge` | `{{code_tiers}}` | |
| 3 | `core_tiers_noms` | — | `{{nom}}` | |
| 4 | `core_tiers_roles` | — | `{{role_code}}` | |
| 5 | `core_tiers_identifiants` | — | `{{type_identifiant_code}}: {{valeur}}` | Masquer `valeur` si sensible |
| 6 | `core_tiers_adresses` | — | `{{ligne_1}}, {{ville}}` | |
| 7 | `core_tiers_contacts` | — | `{{valeur}}` | |
| 8 | `doc_documents` | `description` | `{{titre}}` | |
| 9 | `doc_versions` | — | `{{nom_fichier}}` | |
| 10 | `bo_courriers` | `mail` | `{{numero_chrono}} — {{objet}}` | Collection principale |
| 11 | `bo_courrier_parties` | — | `{{role_code}}: {{libelle_snapshot}}` | |
| 12 | `bo_orientations` | — | `→ {{unite_destination_id}}` | |
| 13 | `bo_courrier_documents` | — | — | Table de liaison |
| 14 | `bo_expeditions` | `local_shipping` | `{{mode_expedition_code}}` | |
| 15 | `bo_expedition_tentatives` | — | `Tentative {{numero_tentative}}` | |
| 16 | `bo_accuses_reception` | — | `{{statut_ar_code}}` | |
| 17 | `vw_bo_courriers_suivi` | `visibility` | `{{numero_chrono}}` | **Vue**, lecture seule |

Référentiels `cfg_*` à adopter aussi (modèle d'affichage `{{libelle}}`) :
`cfg_canaux_courrier`, `cfg_supports_courrier`, `cfg_priorites`,
`cfg_statuts_courrier`, `cfg_roles_parties_courrier`, `cfg_modes_expedition`,
`cfg_statuts_expedition`, `cfg_statuts_ar`, `cfg_types_documents`,
`cfg_niveaux_confidentialite`, `cfg_types_adresses`, `cfg_types_contacts`,
`cfg_types_identifiants`, `cfg_natures_tiers`, `cfg_roles_tiers`.

**Relations inverses à créer manuellement** (Directus ne crée que le sens
Many-to-One porté par la clé étrangère) :

| Sur la collection | Champ alias | Type | Pointe vers |
|---|---|---|---|
| `bo_courriers` | `parties` | O2M | `bo_courrier_parties.courrier_id` |
| `bo_courriers` | `orientations` | O2M | `bo_orientations.courrier_id` |
| `bo_courriers` | `pieces_jointes` | O2M | `bo_courrier_documents.courrier_id` |
| `bo_courriers` | `expeditions` | O2M | `bo_expeditions.courrier_id` |
| `bo_expeditions` | `tentatives` | O2M | `bo_expedition_tentatives.expedition_id` |
| `bo_expedition_tentatives` | `accuses_reception` | O2M | `bo_accuses_reception.tentative_id` |

(*Modèle de données → collection → Créer un champ → Autres champs → O2M →
"Utiliser une relation existante"*.)

## 7. Figer la configuration dans un snapshot versionné

Une fois les collections configurées :

```bash
cd directus
npx directus schema snapshot ./snapshots/snapshot.yaml --yes
cd ..
```

Committez `directus/snapshots/snapshot.yaml`. Pour reproduire cette
configuration sur un autre Codespace / une autre base Neon déjà pourvue du
schéma SQL (étape 4) :

```bash
./scripts/start-directus.sh &     # laissez tourner
cd directus
npx directus schema apply ./snapshots/snapshot.yaml --yes
cd ..
```

N'appliquez jamais un snapshot pendant qu'une *autre* instance Directus
tourne sur la même base (désynchronisation du cache de schéma) — dans ce
cas, redémarrez `start-directus.sh` juste après.

## 8. Rôle et accès pour le frontend

Dans **Paramètres → Rôles et permissions** :
1. Créez un rôle `Agent Bureau d'Ordre`.
2. Policy associée : lecture/écriture sur `bo_*`, lecture seule sur
   `core_tiers*`, `org_unites`, `doc_documents`, `doc_versions`, les
   `cfg_*` du module, `vw_bo_courriers_suivi`.
3. Créez un utilisateur applicatif avec ce rôle, générez un **jeton
   statique** (profil utilisateur → *Static Token*) pour le frontend.

## 9. Démarrer le frontend

```bash
cd frontend
cp .env.example .env
npm run dev -- --host
```

Renseignez `frontend/.env` :
- `VITE_DIRECTUS_TOKEN` = le jeton de l'étape 8.
- `VITE_DIRECTUS_URL` : si vous travaillez dans le **navigateur** (github.dev
  ou l'onglet Ports), utilisez l'URL forwardée complète, visible dans
  l'onglet *Ports* pour le port 8055 — de la forme
  `https://<nom-du-codespace>-8055.app.github.dev`. Si vous utilisez **VS
  Code Desktop** (qui réexpose les ports forwardés sur votre propre
  `localhost`), `http://localhost:8055` fonctionne aussi.

Ouvrez le port **5173** de la même façon. Vous devez voir les 4 courriers de
démonstration, avec accès au détail de chacun (parties, orientation, pièces
jointes, et pour `BO-2026-000078` la chaîne complète expédition → tentative
→ accusé de réception).

---

## Partage pour une démonstration

Comme dans GEDMVP : gardez les ports **Private** pendant la construction.
Pour présenter, passez temporairement le port souhaité en **Public**
(clic droit sur le port dans l'onglet *Ports* → *Port Visibility* → *Public*)
puis repassez-le en *Private* après la démo. Notez que passer 8055 en public
expose l'écran de connexion Directus (pas les données : l'authentification
Directus reste requise) — évitez de le laisser public en dehors des
créneaux de démonstration.

## Dépannage

- **`Error: KEY is not defined` ou `SECRET is not defined`** : le
  Codespace a été créé avant l'ajout des secrets → *Rebuild Container*.
- **Le script échoue avec un message `... manquant`** : le secret
  correspondant n'est pas visible dans ce terminal — vérifiez qu'il est
  bien scoping *Codespaces* (pas *Actions*) sur le bon dépôt.
- **Directus ne démarre pas / erreur de connexion DB** : vérifiez que
  `DB_CONNECTION_STRING` contient bien `?sslmode=require` et que la base
  Neon n'est pas suspendue depuis trop longtemps (le premier appel la
  réveille, quelques secondes de latence).
- **Un champ FK affiche un UUID brut** : la table référencée (souvent un
  `cfg_*`) n'a pas encore été adoptée comme collection.
- **`isolated-vm` / erreur de compilation native au `npm install`** :
  vérifiez que l'image du devcontainer est bien Node 22 (`node -v`) — les
  versions récentes de Directus embarquent un binaire précompilé pour
  cette version précise, pas pour Node 18/20.

- **Erreur CORS dans la Console (`blocked by CORS policy`), sur toutes
  les pages du frontend d'un coup, alors que Directus répond bien en
  `curl` avec les bons en-têtes `Access-Control-*`** : ce n'est
  probablement pas un vrai problème CORS. Vérifiez la visibilité du port
  8055 dans l'onglet *Ports* — s'il est passé en *Private* (ou l'a
  toujours été), l'accès à `https://<codespace>-8055.app.github.dev`
  exige une authentification GitHub propre à Codespaces, que le `fetch()`
  du frontend n'envoie pas (pas de `credentials: 'include'`). Le
  navigateur rapporte l'échec comme une erreur CORS, ce qui égare le
  diagnostic. Correctif : clic droit sur le port 8055 → *Port
  Visibility* → *Public*. Un test rapide pour confirmer cette piste :
  ouvrir le frontend en navigation privée — si une page
  d'authentification GitHub apparaît avant même d'atteindre l'app,
  c'est confirmé. À repasser en *Private* dès que possible : Directus
  garde sa propre authentification derrière, mais un port public
  élargit la surface d'exposition.

## Dette technique connue — à corriger avant tout usage réel

**Séparation des rôles par métier (non faite à ce stade).** Aujourd'hui,
la policy `Agent Bureau d'Ordre` donne accès à la fois aux collections
`bo_*` (Bureau d'Ordre) et `dos_*` (Dossiers), parce que les permissions
`dos_*` ont été ajoutées à cette policy existante par simplicité pendant
le POC. Ce n'est pas le modèle cible.

Modèle cible, à mettre en place avant toute mise à disposition à de vrais
agents :

| Rôle | Policy | Accès |
|---|---|---|
| Agent Bureau d'Ordre | À restreindre | Create/Read/Update sur les 7 `bo_*` uniquement + Read sur `org_unites`, `doc_documents`. **Retirer** l'accès à `dos_*`. |
| Agent Direction Régulation | À créer | Create/Read/Update sur les 6 `dos_*` + Read sur `org_unites`, `core_tiers`, `doc_documents`, et Read seul (pas Create/Update) sur `bo_courriers` — uniquement pour résoudre l'affichage du courrier lié dans le détail d'un dossier, sans pouvoir le modifier. |

Cette séparation vaut aussi pour les futurs modules (`reg_*`, `act_*`) :
chaque direction métier devrait avoir sa propre policy, limitée aux
collections qui la concernent, plutôt qu'une policy unique élargie au fil
de l'eau.
