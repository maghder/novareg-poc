-- ============================================================================
-- 01_novareg_schema.sql
-- Architecture PostgreSQL V2 — socle institutionnel NOVAREG
-- ----------------------------------------------------------------------------
-- Objectifs
--   * Modèle canonique indépendant du frontend et de Directus
--   * Bureau d'Ordre transversal
--   * GED / dossiers / actes / décisions séparés
--   * Référentiels réglementaires historisés (pas d'écrasement destructif)
--   * Traçabilité métier + Outbox pour Data Platform
--   * Compatible avec une exposition via Directus (tables préfixées dans public)
--
-- IMPORTANT
--   Ce fichier ne supprime aucune table existante.
--   Pour repartir réellement de zéro, utiliser un script 00_reset_poc.sql séparé.
--   Ne jamais exécuter un reset sur une base de production sans sauvegarde validée.
-- ============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- 0. FONCTIONS TECHNIQUES
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION fn_block_update_delete()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Table append-only: opération % interdite sur %', TG_OP, TG_TABLE_NAME;
END;
$$;

-- ============================================================================
-- 1. PARAMÉTRAGE / VOCABULAIRES CONTRÔLÉS
-- Les valeurs seront alimentées par 02_novareg_seed.sql
-- ============================================================================

CREATE TABLE cfg_natures_tiers (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_roles_tiers (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_types_identifiants (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    sensible boolean NOT NULL DEFAULT false,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_types_adresses (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_types_contacts (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_types_documents (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_niveaux_confidentialite (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    niveau integer NOT NULL,
    description text,
    actif boolean NOT NULL DEFAULT true,
    UNIQUE (niveau)
);

CREATE TABLE cfg_canaux_courrier (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_supports_courrier (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_priorites (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    niveau integer NOT NULL,
    actif boolean NOT NULL DEFAULT true,
    UNIQUE (niveau)
);

CREATE TABLE cfg_statuts_courrier (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    phase varchar(50),
    ordre integer NOT NULL DEFAULT 100,
    terminal boolean NOT NULL DEFAULT false,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_roles_parties_courrier (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_modes_expedition (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_statuts_expedition (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    ordre integer NOT NULL DEFAULT 100,
    terminal boolean NOT NULL DEFAULT false,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_statuts_ar (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    ordre integer NOT NULL DEFAULT 100,
    terminal boolean NOT NULL DEFAULT false,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_types_dossiers (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    domaine varchar(100),
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_statuts_dossiers (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    ordre integer NOT NULL DEFAULT 100,
    terminal boolean NOT NULL DEFAULT false,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_types_actes (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_statuts_actes (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    ordre integer NOT NULL DEFAULT 100,
    terminal boolean NOT NULL DEFAULT false,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_types_decisions (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_types_entites_regulees (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    secteur varchar(100),
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_statuts_entites_regulees (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    ordre integer NOT NULL DEFAULT 100,
    terminal boolean NOT NULL DEFAULT false,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_qualites_intermediaires (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_types_autorisations (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_statuts_autorisations (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    ordre integer NOT NULL DEFAULT 100,
    terminal boolean NOT NULL DEFAULT false,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_types_relations_reglementaires (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    directionnelle boolean NOT NULL DEFAULT true,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

CREATE TABLE cfg_roles_representants (
    code varchar(50) PRIMARY KEY,
    libelle varchar(150) NOT NULL,
    description text,
    ordre integer NOT NULL DEFAULT 100,
    actif boolean NOT NULL DEFAULT true
);

-- ============================================================================
-- 2. ORGANISATION INTERNE
-- ============================================================================

CREATE TABLE org_unites (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code_unite varchar(50) NOT NULL UNIQUE,
    libelle varchar(200) NOT NULL,
    type_unite varchar(80),
    parent_id uuid REFERENCES org_unites(id),
    actif boolean NOT NULL DEFAULT true,
    date_debut date,
    date_fin date,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(code_unite) <> ''),
    CHECK (code_unite = upper(btrim(code_unite))),
    CHECK (date_fin IS NULL OR date_debut IS NULL OR date_fin >= date_debut)
);

CREATE INDEX ix_org_unites_parent ON org_unites(parent_id);

-- ============================================================================
-- 3. SOCLE CANONIQUE DES TIERS
-- ============================================================================

CREATE TABLE core_tiers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code_tiers varchar(50) NOT NULL UNIQUE,
    nature_code varchar(50) NOT NULL REFERENCES cfg_natures_tiers(code),
    statut varchar(30) NOT NULL DEFAULT 'actif',
    date_entree_relation date,
    date_sortie_relation date,
    source_creation varchar(80),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(code_tiers) <> ''),
    CHECK (code_tiers = upper(btrim(code_tiers))),
    CHECK (statut IN ('actif','inactif','provisoire')),
    CHECK (
        date_sortie_relation IS NULL
        OR date_entree_relation IS NULL
        OR date_sortie_relation >= date_entree_relation
    )
);

CREATE TABLE core_tiers_noms (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tiers_id uuid NOT NULL REFERENCES core_tiers(id) ON DELETE RESTRICT,
    type_nom varchar(30) NOT NULL DEFAULT 'principal',
    nom varchar(300) NOT NULL,
    nom_normalise text GENERATED ALWAYS AS (lower(btrim(nom))) STORED,
    is_primary boolean NOT NULL DEFAULT true,
    valid_from date NOT NULL DEFAULT CURRENT_DATE,
    valid_to date,
    source_dossier_id uuid,
    source_decision_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(nom) <> ''),
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE UNIQUE INDEX ux_core_tiers_nom_primary_current
    ON core_tiers_noms(tiers_id)
    WHERE valid_to IS NULL AND is_primary;

CREATE INDEX ix_core_tiers_noms_search
    ON core_tiers_noms(nom_normalise);

CREATE TABLE core_tiers_roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tiers_id uuid NOT NULL REFERENCES core_tiers(id) ON DELETE RESTRICT,
    role_code varchar(50) NOT NULL REFERENCES cfg_roles_tiers(code),
    valid_from date NOT NULL DEFAULT CURRENT_DATE,
    valid_to date,
    source_dossier_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE UNIQUE INDEX ux_core_tiers_role_current
    ON core_tiers_roles(tiers_id, role_code)
    WHERE valid_to IS NULL;

CREATE INDEX ix_core_tiers_roles_role ON core_tiers_roles(role_code);

CREATE TABLE core_tiers_identifiants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tiers_id uuid NOT NULL REFERENCES core_tiers(id) ON DELETE RESTRICT,
    type_identifiant_code varchar(50) NOT NULL REFERENCES cfg_types_identifiants(code),
    valeur varchar(200) NOT NULL,
    valeur_normalisee varchar(200) NOT NULL,
    autorite_emettrice varchar(200),
    valid_from date,
    valid_to date,
    is_primary boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(valeur) <> ''),
    CHECK (btrim(valeur_normalisee) <> ''),
    CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from)
);

CREATE UNIQUE INDEX ux_core_tiers_identifiant_active
    ON core_tiers_identifiants(type_identifiant_code, valeur_normalisee)
    WHERE valid_to IS NULL;

CREATE INDEX ix_core_tiers_identifiants_tiers ON core_tiers_identifiants(tiers_id);

CREATE TABLE core_tiers_adresses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tiers_id uuid NOT NULL REFERENCES core_tiers(id) ON DELETE RESTRICT,
    type_adresse_code varchar(50) NOT NULL REFERENCES cfg_types_adresses(code),
    ligne_1 varchar(250) NOT NULL,
    ligne_2 varchar(250),
    quartier varchar(150),
    ville varchar(150),
    code_postal varchar(30),
    region varchar(150),
    pays_code char(2) NOT NULL DEFAULT 'MA',
    is_primary boolean NOT NULL DEFAULT false,
    valid_from date NOT NULL DEFAULT CURRENT_DATE,
    valid_to date,
    source_dossier_id uuid,
    source_decision_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(ligne_1) <> ''),
    CHECK (pays_code = upper(pays_code)),
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE UNIQUE INDEX ux_core_tiers_adresse_primary_current
    ON core_tiers_adresses(tiers_id, type_adresse_code)
    WHERE valid_to IS NULL AND is_primary;

CREATE INDEX ix_core_tiers_adresses_tiers ON core_tiers_adresses(tiers_id);

CREATE TABLE core_tiers_contacts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tiers_id uuid NOT NULL REFERENCES core_tiers(id) ON DELETE RESTRICT,
    type_contact_code varchar(50) NOT NULL REFERENCES cfg_types_contacts(code),
    valeur varchar(250) NOT NULL,
    valeur_normalisee varchar(250) NOT NULL,
    libelle varchar(150),
    is_primary boolean NOT NULL DEFAULT false,
    valid_from date NOT NULL DEFAULT CURRENT_DATE,
    valid_to date,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(valeur) <> ''),
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE INDEX ix_core_tiers_contacts_tiers ON core_tiers_contacts(tiers_id);
CREATE INDEX ix_core_tiers_contacts_lookup ON core_tiers_contacts(type_contact_code, valeur_normalisee);

CREATE UNIQUE INDEX ux_core_tiers_contact_primary_current
    ON core_tiers_contacts(tiers_id, type_contact_code)
    WHERE valid_to IS NULL AND is_primary;

-- ============================================================================
-- 4. GED / DOCUMENTS
-- ============================================================================

CREATE TABLE doc_documents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code_document varchar(60) NOT NULL UNIQUE,
    type_document_code varchar(50) NOT NULL REFERENCES cfg_types_documents(code),
    titre varchar(300) NOT NULL,
    langue_code varchar(10) NOT NULL DEFAULT 'fr',
    confidentialite_code varchar(50) REFERENCES cfg_niveaux_confidentialite(code),
    date_document date,
    description text,
    retention_code varchar(80),
    statut varchar(30) NOT NULL DEFAULT 'actif',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(code_document) <> ''),
    CHECK (code_document = upper(btrim(code_document))),
    CHECK (btrim(titre) <> ''),
    CHECK (statut IN ('actif','archive','annule'))
);

CREATE TABLE doc_versions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id uuid NOT NULL REFERENCES doc_documents(id) ON DELETE RESTRICT,
    version_no integer NOT NULL,
    directus_file_id uuid,
    object_key text,
    nom_fichier varchar(300) NOT NULL,
    mime_type varchar(150),
    taille_octets bigint,
    sha256 char(64),
    est_original boolean NOT NULL DEFAULT false,
    commentaire_version text,
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    UNIQUE (document_id, version_no),
    CHECK (version_no > 0),
    CHECK (taille_octets IS NULL OR taille_octets >= 0),
    CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-fA-F]{64}$'),
    CHECK (directus_file_id IS NOT NULL OR object_key IS NOT NULL)
);

CREATE INDEX ix_doc_versions_document ON doc_versions(document_id);

CREATE TABLE doc_relations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_source_id uuid NOT NULL REFERENCES doc_documents(id) ON DELETE RESTRICT,
    document_cible_id uuid NOT NULL REFERENCES doc_documents(id) ON DELETE RESTRICT,
    type_relation varchar(50) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (document_source_id <> document_cible_id),
    UNIQUE (document_source_id, document_cible_id, type_relation)
);

-- ============================================================================
-- 5. BUREAU D'ORDRE TRANSVERSAL
-- ============================================================================

CREATE TABLE bo_courriers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_chrono varchar(80) NOT NULL UNIQUE,
    sens varchar(10) NOT NULL,
    date_enregistrement timestamptz NOT NULL DEFAULT now(),
    date_document date,
    objet varchar(500) NOT NULL,
    reference_externe varchar(150),
    canal_code varchar(50) REFERENCES cfg_canaux_courrier(code),
    support_code varchar(50) REFERENCES cfg_supports_courrier(code),
    priorite_code varchar(50) REFERENCES cfg_priorites(code),
    confidentialite_code varchar(50) REFERENCES cfg_niveaux_confidentialite(code),
    statut_code varchar(50) NOT NULL REFERENCES cfg_statuts_courrier(code),
    unite_enregistrement_id uuid REFERENCES org_unites(id),
    unite_emettrice_id uuid REFERENCES org_unites(id),
    langue_code varchar(10) NOT NULL DEFAULT 'fr',
    commentaire_bo text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (sens IN ('arrivee','depart')),
    CHECK (btrim(numero_chrono) <> ''),
    CHECK (numero_chrono = upper(btrim(numero_chrono))),
    CHECK (btrim(objet) <> '')
);

CREATE INDEX ix_bo_courriers_date ON bo_courriers(date_enregistrement DESC);
CREATE INDEX ix_bo_courriers_statut ON bo_courriers(statut_code);
CREATE INDEX ix_bo_courriers_sens ON bo_courriers(sens);

CREATE TABLE bo_courrier_parties (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    courrier_id uuid NOT NULL REFERENCES bo_courriers(id) ON DELETE CASCADE,
    tiers_id uuid REFERENCES core_tiers(id) ON DELETE RESTRICT,
    role_code varchar(50) NOT NULL REFERENCES cfg_roles_parties_courrier(code),
    libelle_snapshot varchar(300) NOT NULL,
    adresse_snapshot text,
    reference_partie varchar(150),
    ordre integer NOT NULL DEFAULT 1,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(libelle_snapshot) <> ''),
    CHECK (ordre > 0),
    UNIQUE (id, courrier_id)
);

CREATE INDEX ix_bo_parties_courrier ON bo_courrier_parties(courrier_id);
CREATE INDEX ix_bo_parties_tiers ON bo_courrier_parties(tiers_id);
CREATE INDEX ix_bo_parties_role ON bo_courrier_parties(role_code);

CREATE TABLE bo_orientations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    courrier_id uuid NOT NULL REFERENCES bo_courriers(id) ON DELETE RESTRICT,
    unite_source_id uuid REFERENCES org_unites(id),
    unite_destination_id uuid NOT NULL REFERENCES org_unites(id),
    date_transmission timestamptz NOT NULL DEFAULT now(),
    date_reception timestamptz,
    statut varchar(30) NOT NULL DEFAULT 'transmis',
    motif varchar(300),
    commentaire text,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (statut IN ('transmis','recu','retourne','annule')),
    CHECK (date_reception IS NULL OR date_reception >= date_transmission)
);

CREATE INDEX ix_bo_orientations_courrier ON bo_orientations(courrier_id, date_transmission DESC);
CREATE INDEX ix_bo_orientations_destination ON bo_orientations(unite_destination_id, statut);

CREATE TABLE bo_courrier_documents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    courrier_id uuid NOT NULL REFERENCES bo_courriers(id) ON DELETE CASCADE,
    document_id uuid NOT NULL REFERENCES doc_documents(id) ON DELETE RESTRICT,
    role_document varchar(50) NOT NULL DEFAULT 'piece_jointe',
    ordre integer NOT NULL DEFAULT 1,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (courrier_id, document_id),
    CHECK (ordre > 0)
);

CREATE INDEX ix_bo_courrier_documents_document ON bo_courrier_documents(document_id);

CREATE TABLE bo_expeditions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    courrier_id uuid NOT NULL REFERENCES bo_courriers(id) ON DELETE RESTRICT,
    destinataire_partie_id uuid NOT NULL,
    mode_expedition_code varchar(50) NOT NULL REFERENCES cfg_modes_expedition(code),
    operateur varchar(150),
    ar_requis boolean NOT NULL DEFAULT false,
    statut_code varchar(50) NOT NULL REFERENCES cfg_statuts_expedition(code),
    date_preparation timestamptz,
    commentaire text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_bo_expedition_destinataire_meme_courrier
        FOREIGN KEY (destinataire_partie_id, courrier_id)
        REFERENCES bo_courrier_parties(id, courrier_id)
        ON DELETE RESTRICT
);

CREATE INDEX ix_bo_expeditions_courrier ON bo_expeditions(courrier_id);
CREATE INDEX ix_bo_expeditions_statut ON bo_expeditions(statut_code);

CREATE TABLE bo_expedition_tentatives (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    expedition_id uuid NOT NULL REFERENCES bo_expeditions(id) ON DELETE RESTRICT,
    numero_tentative integer NOT NULL,
    numero_suivi varchar(150),
    date_remise_operateur timestamptz,
    date_expedition timestamptz,
    date_distribution timestamptz,
    date_retour timestamptz,
    motif_retour varchar(300),
    statut_code varchar(50) NOT NULL REFERENCES cfg_statuts_expedition(code),
    preuve_distribution_document_id uuid REFERENCES doc_documents(id),
    commentaire text,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (expedition_id, numero_tentative),
    CHECK (numero_tentative > 0),
    CHECK (
        date_distribution IS NULL OR date_expedition IS NULL
        OR date_distribution >= date_expedition
    ),
    CHECK (
        date_retour IS NULL OR date_expedition IS NULL
        OR date_retour >= date_expedition
    )
);

CREATE INDEX ix_bo_tentatives_expedition ON bo_expedition_tentatives(expedition_id);
CREATE INDEX ix_bo_tentatives_suivi ON bo_expedition_tentatives(numero_suivi);

CREATE TABLE bo_accuses_reception (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tentative_id uuid NOT NULL UNIQUE REFERENCES bo_expedition_tentatives(id) ON DELETE RESTRICT,
    statut_ar_code varchar(50) NOT NULL REFERENCES cfg_statuts_ar(code),
    date_reception_ar timestamptz,
    reference_ar varchar(150),
    nom_recepteur varchar(250),
    qualite_recepteur varchar(150),
    preuve_ar_document_id uuid REFERENCES doc_documents(id),
    commentaire text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
-- 6. DOSSIERS TRANSVERSAUX
-- ============================================================================

CREATE TABLE dos_dossiers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_dossier varchar(80) NOT NULL UNIQUE,
    type_dossier_code varchar(50) NOT NULL REFERENCES cfg_types_dossiers(code),
    statut_code varchar(50) NOT NULL REFERENCES cfg_statuts_dossiers(code),
    unite_responsable_id uuid NOT NULL REFERENCES org_unites(id),
    tiers_principal_id uuid REFERENCES core_tiers(id),
    priorite_code varchar(50) REFERENCES cfg_priorites(code),
    confidentialite_code varchar(50) REFERENCES cfg_niveaux_confidentialite(code),
    date_ouverture timestamptz NOT NULL DEFAULT now(),
    date_cloture timestamptz,
    responsable_user_id uuid,
    objet varchar(500),
    commentaire text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (numero_dossier = upper(btrim(numero_dossier))),
    CHECK (date_cloture IS NULL OR date_cloture >= date_ouverture)
);

CREATE INDEX ix_dos_dossiers_statut ON dos_dossiers(statut_code);
CREATE INDEX ix_dos_dossiers_unite ON dos_dossiers(unite_responsable_id, statut_code);
CREATE INDEX ix_dos_dossiers_tiers ON dos_dossiers(tiers_principal_id);

CREATE TABLE dos_parties (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dossier_id uuid NOT NULL REFERENCES dos_dossiers(id) ON DELETE CASCADE,
    tiers_id uuid NOT NULL REFERENCES core_tiers(id) ON DELETE RESTRICT,
    role_partie varchar(80) NOT NULL,
    valid_from date NOT NULL DEFAULT CURRENT_DATE,
    valid_to date,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE INDEX ix_dos_parties_dossier ON dos_parties(dossier_id);
CREATE INDEX ix_dos_parties_tiers ON dos_parties(tiers_id);

CREATE UNIQUE INDEX ux_dos_partie_current
    ON dos_parties(dossier_id, tiers_id, role_partie)
    WHERE valid_to IS NULL;

CREATE TABLE dos_courriers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dossier_id uuid NOT NULL REFERENCES dos_dossiers(id) ON DELETE CASCADE,
    courrier_id uuid NOT NULL REFERENCES bo_courriers(id) ON DELETE RESTRICT,
    role_courrier varchar(50) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (dossier_id, courrier_id)
);

CREATE INDEX ix_dos_courriers_courrier ON dos_courriers(courrier_id);

CREATE TABLE dos_documents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dossier_id uuid NOT NULL REFERENCES dos_dossiers(id) ON DELETE CASCADE,
    document_id uuid NOT NULL REFERENCES doc_documents(id) ON DELETE RESTRICT,
    role_document varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (dossier_id, document_id)
);

CREATE TABLE dos_affectations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dossier_id uuid NOT NULL REFERENCES dos_dossiers(id) ON DELETE RESTRICT,
    unite_id uuid NOT NULL REFERENCES org_unites(id),
    user_id uuid,
    role_affectation varchar(50) NOT NULL,
    date_debut timestamptz NOT NULL DEFAULT now(),
    date_fin timestamptz,
    commentaire text,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (date_fin IS NULL OR date_fin >= date_debut)
);

CREATE INDEX ix_dos_affectations_dossier ON dos_affectations(dossier_id, date_fin);

CREATE TABLE dos_statuts_hist (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dossier_id uuid NOT NULL REFERENCES dos_dossiers(id) ON DELETE RESTRICT,
    ancien_statut_code varchar(50) REFERENCES cfg_statuts_dossiers(code),
    nouveau_statut_code varchar(50) NOT NULL REFERENCES cfg_statuts_dossiers(code),
    changed_at timestamptz NOT NULL DEFAULT now(),
    changed_by uuid,
    motif text,
    correlation_id uuid
);

CREATE INDEX ix_dos_statuts_hist_dossier ON dos_statuts_hist(dossier_id, changed_at DESC);

-- ============================================================================
-- 7. RÉFÉRENTIEL RÉGLEMENTAIRE
-- ============================================================================

CREATE TABLE reg_entites_regulees (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tiers_id uuid NOT NULL REFERENCES core_tiers(id) ON DELETE RESTRICT,
    type_entite_code varchar(50) NOT NULL REFERENCES cfg_types_entites_regulees(code),
    code_reglementaire varchar(80) NOT NULL UNIQUE,
    date_creation_reglementaire date,
    date_fin_reglementaire date,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (code_reglementaire = upper(btrim(code_reglementaire))),
    CHECK (
        date_fin_reglementaire IS NULL
        OR date_creation_reglementaire IS NULL
        OR date_fin_reglementaire >= date_creation_reglementaire
    )
);

CREATE INDEX ix_reg_entites_tiers ON reg_entites_regulees(tiers_id);
CREATE INDEX ix_reg_entites_type ON reg_entites_regulees(type_entite_code);

CREATE TABLE reg_entite_statuts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entite_regulee_id uuid NOT NULL REFERENCES reg_entites_regulees(id) ON DELETE RESTRICT,
    statut_code varchar(50) NOT NULL REFERENCES cfg_statuts_entites_regulees(code),
    valid_from date NOT NULL,
    valid_to date,
    source_acte_id uuid,
    source_decision_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE UNIQUE INDEX ux_reg_entite_statut_current
    ON reg_entite_statuts(entite_regulee_id)
    WHERE valid_to IS NULL;

CREATE TABLE reg_entite_adresses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entite_regulee_id uuid NOT NULL REFERENCES reg_entites_regulees(id) ON DELETE RESTRICT,
    type_adresse_code varchar(50) NOT NULL REFERENCES cfg_types_adresses(code),
    ligne_1 varchar(250) NOT NULL,
    ligne_2 varchar(250),
    quartier varchar(150),
    ville varchar(150),
    code_postal varchar(30),
    region varchar(150),
    pays_code char(2) NOT NULL DEFAULT 'MA',
    is_primary boolean NOT NULL DEFAULT true,
    valid_from date NOT NULL,
    valid_to date,
    source_tiers_adresse_id uuid REFERENCES core_tiers_adresses(id),
    source_acte_id uuid,
    source_decision_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(ligne_1) <> ''),
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE UNIQUE INDEX ux_reg_entite_adresse_current
    ON reg_entite_adresses(entite_regulee_id, type_adresse_code)
    WHERE valid_to IS NULL;

CREATE UNIQUE INDEX ux_reg_entite_adresse_primary_current
    ON reg_entite_adresses(entite_regulee_id)
    WHERE valid_to IS NULL AND is_primary;

CREATE TABLE reg_intermediaires (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entite_regulee_id uuid NOT NULL UNIQUE REFERENCES reg_entites_regulees(id) ON DELETE RESTRICT,
    code_intermediaire varchar(80) NOT NULL UNIQUE,
    date_premier_agrement date,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (code_intermediaire = upper(btrim(code_intermediaire)))
);

CREATE TABLE reg_ear (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entite_regulee_id uuid NOT NULL UNIQUE REFERENCES reg_entites_regulees(id) ON DELETE RESTRICT,
    code_ear varchar(80) NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (code_ear = upper(btrim(code_ear)))
);

CREATE TABLE reg_intermediaire_qualites (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    intermediaire_id uuid NOT NULL REFERENCES reg_intermediaires(id) ON DELETE RESTRICT,
    qualite_code varchar(50) NOT NULL REFERENCES cfg_qualites_intermediaires(code),
    valid_from date NOT NULL,
    valid_to date,
    source_acte_id uuid,
    source_decision_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE UNIQUE INDEX ux_reg_intermediaire_qualite_current
    ON reg_intermediaire_qualites(intermediaire_id)
    WHERE valid_to IS NULL;

CREATE TABLE reg_autorisations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entite_regulee_id uuid NOT NULL REFERENCES reg_entites_regulees(id) ON DELETE RESTRICT,
    type_autorisation_code varchar(50) NOT NULL REFERENCES cfg_types_autorisations(code),
    numero_autorisation varchar(120),
    date_octroi date,
    date_effet date,
    date_fin date,
    source_decision_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (date_fin IS NULL OR date_effet IS NULL OR date_fin >= date_effet)
);

CREATE INDEX ix_reg_autorisations_entite ON reg_autorisations(entite_regulee_id);

CREATE TABLE reg_autorisation_statuts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    autorisation_id uuid NOT NULL REFERENCES reg_autorisations(id) ON DELETE RESTRICT,
    statut_code varchar(50) NOT NULL REFERENCES cfg_statuts_autorisations(code),
    valid_from date NOT NULL,
    valid_to date,
    source_acte_id uuid,
    source_decision_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE UNIQUE INDEX ux_reg_autorisation_statut_current
    ON reg_autorisation_statuts(autorisation_id)
    WHERE valid_to IS NULL;

CREATE TABLE reg_relations_entites (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entite_source_id uuid NOT NULL REFERENCES reg_entites_regulees(id) ON DELETE RESTRICT,
    entite_cible_id uuid NOT NULL REFERENCES reg_entites_regulees(id) ON DELETE RESTRICT,
    type_relation_code varchar(50) NOT NULL REFERENCES cfg_types_relations_reglementaires(code),
    valid_from date NOT NULL,
    valid_to date,
    source_acte_id uuid,
    source_decision_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (entite_source_id <> entite_cible_id),
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE INDEX ix_reg_relations_source ON reg_relations_entites(entite_source_id, valid_to);
CREATE INDEX ix_reg_relations_cible ON reg_relations_entites(entite_cible_id, valid_to);

CREATE UNIQUE INDEX ux_reg_relation_current
    ON reg_relations_entites(entite_source_id, entite_cible_id, type_relation_code)
    WHERE valid_to IS NULL;

CREATE TABLE reg_entite_representants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entite_regulee_id uuid NOT NULL REFERENCES reg_entites_regulees(id) ON DELETE RESTRICT,
    tiers_representant_id uuid NOT NULL REFERENCES core_tiers(id) ON DELETE RESTRICT,
    role_representant_code varchar(50) NOT NULL REFERENCES cfg_roles_representants(code),
    valid_from date NOT NULL,
    valid_to date,
    source_acte_id uuid,
    source_decision_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE INDEX ix_reg_representants_entite ON reg_entite_representants(entite_regulee_id, valid_to);

CREATE UNIQUE INDEX ux_reg_representant_current
    ON reg_entite_representants(entite_regulee_id, tiers_representant_id, role_representant_code)
    WHERE valid_to IS NULL;

-- ============================================================================
-- 8. ACTES / INSTRUCTION / DÉCISION
-- ============================================================================

CREATE TABLE act_actes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dossier_id uuid NOT NULL REFERENCES dos_dossiers(id) ON DELETE RESTRICT,
    type_acte_code varchar(50) NOT NULL REFERENCES cfg_types_actes(code),
    statut_code varchar(50) NOT NULL REFERENCES cfg_statuts_actes(code),
    objet varchar(500),
    date_qualification timestamptz,
    qualified_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ix_act_actes_dossier ON act_actes(dossier_id);
CREATE INDEX ix_act_actes_type_statut ON act_actes(type_acte_code, statut_code);

CREATE TABLE act_instructions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    acte_id uuid NOT NULL REFERENCES act_actes(id) ON DELETE RESTRICT,
    version_no integer NOT NULL,
    instructeur_user_id uuid,
    proposition_code varchar(50),
    synthese text,
    date_soumission timestamptz,
    is_current boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (acte_id, version_no),
    CHECK (version_no > 0)
);

CREATE UNIQUE INDEX ux_act_instruction_current
    ON act_instructions(acte_id)
    WHERE is_current;

CREATE TABLE act_decisions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    acte_id uuid NOT NULL REFERENCES act_actes(id) ON DELETE RESTRICT,
    version_no integer NOT NULL,
    type_decision_code varchar(50) NOT NULL REFERENCES cfg_types_decisions(code),
    validateur_user_id uuid,
    date_decision timestamptz NOT NULL DEFAULT now(),
    date_effet date,
    motivation text,
    is_current boolean NOT NULL DEFAULT true,
    supersedes_decision_id uuid REFERENCES act_decisions(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (acte_id, version_no),
    CHECK (version_no > 0)
);

CREATE UNIQUE INDEX ux_act_decision_current
    ON act_decisions(acte_id)
    WHERE is_current;

CREATE OR REPLACE FUNCTION fn_assert_act_type()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    actual_type varchar(50);
BEGIN
    SELECT type_acte_code
      INTO actual_type
      FROM act_actes
     WHERE id = NEW.acte_id;

    IF actual_type IS NULL THEN
        RAISE EXCEPTION 'Acte parent % introuvable', NEW.acte_id;
    END IF;

    IF actual_type <> TG_ARGV[0] THEN
        RAISE EXCEPTION
            'Sous-type incompatible: acte % est de type %, type attendu %',
            NEW.acte_id, actual_type, TG_ARGV[0];
    END IF;

    RETURN NEW;
END;
$$;

CREATE TABLE act_changements_adresse (
    acte_id uuid PRIMARY KEY REFERENCES act_actes(id) ON DELETE CASCADE,
    entite_regulee_id uuid NOT NULL REFERENCES reg_entites_regulees(id) ON DELETE RESTRICT,
    ancienne_adresse_id uuid REFERENCES reg_entite_adresses(id) ON DELETE RESTRICT,
    type_adresse_code varchar(50) NOT NULL REFERENCES cfg_types_adresses(code),
    nouvelle_ligne_1 varchar(250) NOT NULL,
    nouvelle_ligne_2 varchar(250),
    nouveau_quartier varchar(150),
    nouvelle_ville varchar(150),
    nouveau_code_postal varchar(30),
    nouvelle_region varchar(150),
    nouveau_pays_code char(2) NOT NULL DEFAULT 'MA',
    nouvelle_adresse_id uuid REFERENCES reg_entite_adresses(id),
    CHECK (btrim(nouvelle_ligne_1) <> '')
);

CREATE TABLE act_changements_qualite (
    acte_id uuid PRIMARY KEY REFERENCES act_actes(id) ON DELETE CASCADE,
    intermediaire_id uuid NOT NULL REFERENCES reg_intermediaires(id) ON DELETE RESTRICT,
    ancienne_qualite_id uuid REFERENCES reg_intermediaire_qualites(id) ON DELETE RESTRICT,
    nouvelle_qualite_code varchar(50) NOT NULL REFERENCES cfg_qualites_intermediaires(code),
    nouvelle_qualite_id uuid REFERENCES reg_intermediaire_qualites(id)
);

CREATE TABLE act_nouveaux_agrements (
    acte_id uuid PRIMARY KEY REFERENCES act_actes(id) ON DELETE CASCADE,
    tiers_demandeur_id uuid NOT NULL REFERENCES core_tiers(id) ON DELETE RESTRICT,
    type_entite_code varchar(50) NOT NULL REFERENCES cfg_types_entites_regulees(code),
    qualite_intermediaire_code varchar(50) REFERENCES cfg_qualites_intermediaires(code),
    code_reglementaire_propose varchar(80),
    adresse_ligne_1 varchar(250) NOT NULL,
    adresse_ligne_2 varchar(250),
    ville varchar(150),
    code_postal varchar(30),
    region varchar(150),
    pays_code char(2) NOT NULL DEFAULT 'MA',
    entite_regulee_creee_id uuid REFERENCES reg_entites_regulees(id),
    intermediaire_cree_id uuid REFERENCES reg_intermediaires(id),
    CHECK (btrim(adresse_ligne_1) <> '')
);

CREATE TRIGGER trg_act_changement_adresse_type
BEFORE INSERT OR UPDATE ON act_changements_adresse
FOR EACH ROW EXECUTE FUNCTION fn_assert_act_type('changement_adresse');

CREATE TRIGGER trg_act_changement_qualite_type
BEFORE INSERT OR UPDATE ON act_changements_qualite
FOR EACH ROW EXECUTE FUNCTION fn_assert_act_type('changement_qualite');

CREATE TRIGGER trg_act_nouvel_agrement_type
BEFORE INSERT OR UPDATE ON act_nouveaux_agrements
FOR EACH ROW EXECUTE FUNCTION fn_assert_act_type('nouvel_agrement');

CREATE TABLE act_executions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    acte_id uuid NOT NULL REFERENCES act_actes(id) ON DELETE RESTRICT,
    decision_id uuid NOT NULL REFERENCES act_decisions(id) ON DELETE RESTRICT,
    type_execution varchar(80) NOT NULL,
    statut varchar(30) NOT NULL DEFAULT 'pending',
    started_at timestamptz,
    finished_at timestamptz,
    message text,
    correlation_id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (statut IN ('pending','running','success','error','cancelled')),
    CHECK (finished_at IS NULL OR started_at IS NULL OR finished_at >= started_at)
);

CREATE INDEX ix_act_executions_acte ON act_executions(acte_id, created_at DESC);

-- Ajout des FK de traçabilité vers les actes/décisions après création de ces tables.
ALTER TABLE core_tiers_noms
    ADD CONSTRAINT fk_core_tiers_noms_dossier
        FOREIGN KEY (source_dossier_id) REFERENCES dos_dossiers(id),
    ADD CONSTRAINT fk_core_tiers_noms_decision
        FOREIGN KEY (source_decision_id) REFERENCES act_decisions(id);

ALTER TABLE core_tiers_roles
    ADD CONSTRAINT fk_core_tiers_roles_dossier
        FOREIGN KEY (source_dossier_id) REFERENCES dos_dossiers(id);

ALTER TABLE core_tiers_adresses
    ADD CONSTRAINT fk_core_tiers_adresses_dossier
        FOREIGN KEY (source_dossier_id) REFERENCES dos_dossiers(id),
    ADD CONSTRAINT fk_core_tiers_adresses_decision
        FOREIGN KEY (source_decision_id) REFERENCES act_decisions(id);

ALTER TABLE reg_entite_statuts
    ADD CONSTRAINT fk_reg_entite_statuts_acte
        FOREIGN KEY (source_acte_id) REFERENCES act_actes(id),
    ADD CONSTRAINT fk_reg_entite_statuts_decision
        FOREIGN KEY (source_decision_id) REFERENCES act_decisions(id);

ALTER TABLE reg_entite_adresses
    ADD CONSTRAINT fk_reg_entite_adresses_acte
        FOREIGN KEY (source_acte_id) REFERENCES act_actes(id),
    ADD CONSTRAINT fk_reg_entite_adresses_decision
        FOREIGN KEY (source_decision_id) REFERENCES act_decisions(id);

ALTER TABLE reg_intermediaire_qualites
    ADD CONSTRAINT fk_reg_qualites_acte
        FOREIGN KEY (source_acte_id) REFERENCES act_actes(id),
    ADD CONSTRAINT fk_reg_qualites_decision
        FOREIGN KEY (source_decision_id) REFERENCES act_decisions(id);

ALTER TABLE reg_autorisations
    ADD CONSTRAINT fk_reg_autorisations_decision
        FOREIGN KEY (source_decision_id) REFERENCES act_decisions(id);

ALTER TABLE reg_autorisation_statuts
    ADD CONSTRAINT fk_reg_autorisation_statuts_acte
        FOREIGN KEY (source_acte_id) REFERENCES act_actes(id),
    ADD CONSTRAINT fk_reg_autorisation_statuts_decision
        FOREIGN KEY (source_decision_id) REFERENCES act_decisions(id);

ALTER TABLE reg_relations_entites
    ADD CONSTRAINT fk_reg_relations_acte
        FOREIGN KEY (source_acte_id) REFERENCES act_actes(id),
    ADD CONSTRAINT fk_reg_relations_decision
        FOREIGN KEY (source_decision_id) REFERENCES act_decisions(id);

ALTER TABLE reg_entite_representants
    ADD CONSTRAINT fk_reg_representants_acte
        FOREIGN KEY (source_acte_id) REFERENCES act_actes(id),
    ADD CONSTRAINT fk_reg_representants_decision
        FOREIGN KEY (source_decision_id) REFERENCES act_decisions(id);

-- ============================================================================
-- 9. AUDIT MÉTIER & INTÉGRATION DATA PLATFORM
-- ============================================================================

CREATE TABLE audit_evenements (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    occurred_at timestamptz NOT NULL DEFAULT now(),
    actor_id uuid,
    actor_type varchar(50),
    entity_type varchar(80) NOT NULL,
    entity_id uuid NOT NULL,
    event_type varchar(100) NOT NULL,
    dossier_id uuid REFERENCES dos_dossiers(id),
    acte_id uuid REFERENCES act_actes(id),
    correlation_id uuid NOT NULL DEFAULT gen_random_uuid(),
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    source_application varchar(80) NOT NULL DEFAULT 'directus',
    CHECK (btrim(entity_type) <> ''),
    CHECK (btrim(event_type) <> '')
);

CREATE INDEX ix_audit_entity ON audit_evenements(entity_type, entity_id, occurred_at DESC);
CREATE INDEX ix_audit_dossier ON audit_evenements(dossier_id, occurred_at DESC);
CREATE INDEX ix_audit_event_type ON audit_evenements(event_type, occurred_at DESC);
CREATE INDEX ix_audit_payload_gin ON audit_evenements USING gin(payload);

CREATE TABLE int_outbox (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type varchar(100) NOT NULL,
    aggregate_type varchar(80) NOT NULL,
    aggregate_id uuid NOT NULL,
    correlation_id uuid NOT NULL DEFAULT gen_random_uuid(),
    payload jsonb NOT NULL,
    statut varchar(20) NOT NULL DEFAULT 'pending',
    attempts integer NOT NULL DEFAULT 0,
    available_at timestamptz NOT NULL DEFAULT now(),
    processed_at timestamptz,
    last_error text,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (statut IN ('pending','processing','done','error')),
    CHECK (attempts >= 0)
);

CREATE INDEX ix_int_outbox_pending
    ON int_outbox(available_at, created_at)
    WHERE statut IN ('pending','error');

CREATE INDEX ix_int_outbox_aggregate
    ON int_outbox(aggregate_type, aggregate_id, created_at DESC);

CREATE TABLE int_inbox (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    external_event_id varchar(200) NOT NULL UNIQUE,
    source_system varchar(100) NOT NULL,
    event_type varchar(100) NOT NULL,
    payload jsonb NOT NULL,
    received_at timestamptz NOT NULL DEFAULT now(),
    processed_at timestamptz,
    statut varchar(20) NOT NULL DEFAULT 'received',
    last_error text,
    CHECK (statut IN ('received','processing','done','error'))
);

-- ============================================================================
-- 10. TRIGGERS UPDATED_AT
-- ============================================================================

CREATE TRIGGER trg_org_unites_updated_at
BEFORE UPDATE ON org_unites
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_core_tiers_updated_at
BEFORE UPDATE ON core_tiers
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_doc_documents_updated_at
BEFORE UPDATE ON doc_documents
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_bo_courriers_updated_at
BEFORE UPDATE ON bo_courriers
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_bo_expeditions_updated_at
BEFORE UPDATE ON bo_expeditions
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_bo_ar_updated_at
BEFORE UPDATE ON bo_accuses_reception
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_dos_dossiers_updated_at
BEFORE UPDATE ON dos_dossiers
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_reg_entites_updated_at
BEFORE UPDATE ON reg_entites_regulees
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_reg_intermediaires_updated_at
BEFORE UPDATE ON reg_intermediaires
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_reg_ear_updated_at
BEFORE UPDATE ON reg_ear
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_reg_autorisations_updated_at
BEFORE UPDATE ON reg_autorisations
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_act_actes_updated_at
BEFORE UPDATE ON act_actes
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- Audit métier append-only.
CREATE TRIGGER trg_audit_evenements_no_update
BEFORE UPDATE OR DELETE ON audit_evenements
FOR EACH ROW EXECUTE FUNCTION fn_block_update_delete();

-- ============================================================================
-- 11. VUES DE LECTURE COURANTE
-- Les vues servent au frontend, à Directus (lecture) et au reporting opérationnel.
-- ============================================================================

CREATE OR REPLACE VIEW vw_core_tiers_courants AS
SELECT
    t.id,
    t.code_tiers,
    t.nature_code,
    t.statut,
    n.nom AS nom_principal,
    n.nom_normalise,
    t.date_entree_relation,
    t.date_sortie_relation,
    t.created_at,
    t.updated_at
FROM core_tiers t
LEFT JOIN core_tiers_noms n
    ON n.tiers_id = t.id
   AND n.valid_to IS NULL
   AND n.is_primary = true;

CREATE OR REPLACE VIEW vw_reg_entites_courantes AS
SELECT
    e.id AS entite_regulee_id,
    e.code_reglementaire,
    e.type_entite_code,
    e.tiers_id,
    tc.code_tiers,
    tc.nom_principal,
    s.statut_code,
    a.id AS adresse_reglementaire_id,
    a.type_adresse_code,
    a.ligne_1,
    a.ligne_2,
    a.ville,
    a.code_postal,
    a.region,
    a.pays_code
FROM reg_entites_regulees e
JOIN vw_core_tiers_courants tc
    ON tc.id = e.tiers_id
LEFT JOIN reg_entite_statuts s
    ON s.entite_regulee_id = e.id
   AND s.valid_to IS NULL
LEFT JOIN LATERAL (
    SELECT ra.*
    FROM reg_entite_adresses ra
    WHERE ra.entite_regulee_id = e.id
      AND ra.valid_to IS NULL
    ORDER BY ra.is_primary DESC, ra.created_at DESC
    LIMIT 1
) a ON true;

CREATE OR REPLACE VIEW vw_reg_intermediaires_courants AS
SELECT
    i.id AS intermediaire_id,
    i.code_intermediaire,
    e.entite_regulee_id,
    e.code_reglementaire,
    e.tiers_id,
    e.code_tiers,
    e.nom_principal,
    e.statut_code,
    q.id AS qualite_id,
    q.qualite_code,
    e.adresse_reglementaire_id,
    e.type_adresse_code,
    e.ligne_1,
    e.ligne_2,
    e.ville,
    e.code_postal,
    e.region,
    e.pays_code,
    i.date_premier_agrement
FROM reg_intermediaires i
JOIN vw_reg_entites_courantes e
    ON e.entite_regulee_id = i.entite_regulee_id
LEFT JOIN reg_intermediaire_qualites q
    ON q.intermediaire_id = i.id
   AND q.valid_to IS NULL;

CREATE OR REPLACE VIEW vw_bo_courriers_suivi AS
SELECT
    c.id,
    c.numero_chrono,
    c.sens,
    c.date_enregistrement,
    c.date_document,
    c.objet,
    c.reference_externe,
    c.statut_code,
    c.canal_code,
    c.support_code,
    c.priorite_code,
    c.confidentialite_code,
    exp.libelle_snapshot AS expediteur,
    dest.libelle_snapshot AS destinataire,
    o.unite_destination_id AS derniere_unite_destination,
    o.statut AS statut_orientation
FROM bo_courriers c
LEFT JOIN LATERAL (
    SELECT p.libelle_snapshot
    FROM bo_courrier_parties p
    WHERE p.courrier_id = c.id
      AND p.role_code = 'expediteur'
    ORDER BY p.ordre, p.created_at
    LIMIT 1
) exp ON true
LEFT JOIN LATERAL (
    SELECT p.libelle_snapshot
    FROM bo_courrier_parties p
    WHERE p.courrier_id = c.id
      AND p.role_code = 'destinataire'
    ORDER BY p.ordre, p.created_at
    LIMIT 1
) dest ON true
LEFT JOIN LATERAL (
    SELECT x.unite_destination_id, x.statut
    FROM bo_orientations x
    WHERE x.courrier_id = c.id
    ORDER BY x.date_transmission DESC
    LIMIT 1
) o ON true;

CREATE OR REPLACE VIEW vw_dossiers_synthese AS
SELECT
    d.id AS dossier_id,
    d.numero_dossier,
    d.type_dossier_code,
    d.statut_code AS statut_dossier,
    d.unite_responsable_id,
    d.tiers_principal_id,
    tc.nom_principal AS tiers_principal,
    d.date_ouverture,
    d.date_cloture,
    a.id AS acte_id,
    a.type_acte_code,
    a.statut_code AS statut_acte,
    dec.id AS decision_id,
    dec.type_decision_code,
    dec.date_decision,
    dec.date_effet
FROM dos_dossiers d
LEFT JOIN vw_core_tiers_courants tc
    ON tc.id = d.tiers_principal_id
LEFT JOIN act_actes a
    ON a.dossier_id = d.id
LEFT JOIN act_decisions dec
    ON dec.acte_id = a.id
   AND dec.is_current = true;

-- ============================================================================
-- 12. COMMENTAIRES MÉTIER / NORMES DE SAISIE
-- ============================================================================

COMMENT ON TABLE core_tiers IS
'Référentiel canonique des personnes physiques, personnes morales et organismes. Un tiers peut cumuler plusieurs rôles.';

COMMENT ON TABLE bo_courriers IS
'Courriers entrants et sortants du Bureau d''Ordre. Aucune qualification réglementaire ne doit être portée ici.';

COMMENT ON TABLE bo_expeditions IS
'Expédition d''un courrier sortant vers un destinataire donné. Un même courrier peut avoir plusieurs expéditions.';

COMMENT ON TABLE bo_expedition_tentatives IS
'Tentatives successives d''expédition. Permet de tracer retour, réexpédition et distribution sans dupliquer le courrier.';

COMMENT ON TABLE bo_accuses_reception IS
'Accusé de réception rattaché à une tentative d''expédition avec preuve documentaire éventuelle.';

COMMENT ON TABLE dos_dossiers IS
'Dossier transversal de traitement. Les données spécialisées restent dans les tables métier/actes.';

COMMENT ON TABLE act_actes IS
'Supertype des actes métier. Les données spécifiques sont portées par une table spécialisée selon type_acte_code.';

COMMENT ON TABLE reg_entite_adresses IS
'Historique des adresses réglementaires. Une nouvelle adresse clôture la précédente au lieu de l''écraser.';

COMMENT ON TABLE reg_intermediaire_qualites IS
'Historique des qualités réglementaires d''un intermédiaire. Une seule qualité active est autorisée par index partiel.';

COMMENT ON TABLE audit_evenements IS
'Journal métier append-only. Ne remplace pas les logs techniques Directus mais conserve les événements institutionnels significatifs.';

COMMENT ON TABLE int_outbox IS
'Transactional Outbox destinée à l''alimentation fiable de la Data Platform ou d''autres systèmes.';

-- Normes transversales:
-- 1. Les PK sont techniques (UUID) et ne sont jamais exposées comme identifiant métier.
-- 2. Les codes métier sont séparés des PK et restent stables.
-- 3. Les dates métier utilisent DATE ; les événements système utilisent TIMESTAMPTZ.
-- 4. Les valeurs de listes viennent des tables cfg_*.
-- 5. Les données réglementaires historisées utilisent valid_from / valid_to.
-- 6. valid_to = NULL signifie "valeur actuellement active".
-- 7. Les PDF/binaires ne sont pas stockés en BYTEA dans PostgreSQL.
-- 8. directus_file_id est un pointeur applicatif ; les fichiers vivent dans un stockage documentaire.
-- 9. Hidden/Readonly dans le frontend ou Directus = ergonomie, jamais sécurité.
-- 10. La sécurité réelle relève des permissions Directus, des extensions serveur et des rôles DB.
-- 11. Les changements critiques doivent produire un audit_evenements + int_outbox dans la même transaction.
-- 12. Aucun DELETE physique des historiques réglementaires en fonctionnement normal.

COMMIT;
