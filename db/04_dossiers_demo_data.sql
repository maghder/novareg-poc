-- ============================================================================
-- 04_dossiers_demo_data.sql
-- Jeu de données de démonstration — Module Dossiers (dos_*)
-- ----------------------------------------------------------------------------
-- Périmètre : dos_dossiers, dos_parties, dos_courriers, dos_documents,
-- dos_affectations, dos_statuts_hist.
-- S'appuie entièrement sur des données déjà créées par 03_bo_demo_data.sql
-- (org_unites, core_tiers, bo_courriers, doc_documents) : aucune nouvelle
-- table de référence n'est nécessaire.
-- Pré-requis : 01_novareg_schema.sql, 02_novareg_seed.sql,
-- 03_bo_demo_data.sql déjà exécutés.
-- Rejouable : nettoyage par id avant ré-insertion.
-- ============================================================================

BEGIN;

DELETE FROM dos_statuts_hist   WHERE id::text LIKE 'eeeeeeee-0005-%';
DELETE FROM dos_affectations   WHERE id::text LIKE 'eeeeeeee-0004-%';
DELETE FROM dos_documents      WHERE id::text LIKE 'eeeeeeee-0003-%';
DELETE FROM dos_courriers      WHERE id::text LIKE 'eeeeeeee-0002-%';
DELETE FROM dos_parties        WHERE id::text LIKE 'eeeeeeee-0001-%';
DELETE FROM dos_dossiers       WHERE id::text LIKE 'eeeeeeee-0000-%';

-- ----------------------------------------------------------------------------
-- 1. Dossiers
-- ----------------------------------------------------------------------------

INSERT INTO dos_dossiers
    (id, numero_dossier, type_dossier_code, statut_code, unite_responsable_id,
     tiers_principal_id, priorite_code, confidentialite_code, date_ouverture, objet, commentaire)
VALUES
    -- D1 : changement d'adresse Atlas, en instruction à la DSA (suite du courrier BO-2026-000101)
    ('eeeeeeee-0000-0000-0000-000000000001', 'DOS-2026-000045', 'changement_adresse', 'en_instruction',
     'aaaaaaaa-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000001',
     'normale', 'interne', '2026-07-02 10:05:00+01',
     'Changement d''adresse du siège social - Atlas Assurances SA',
     'Ouvert automatiquement suite à l''orientation du courrier BO-2026-000101 vers la DSA'),

    -- D2 : réclamation Zineb Alaoui, close à la DAJ
    ('eeeeeeee-0000-0000-0000-000000000002', 'DOS-2026-000012', 'reclamation', 'clos',
     'aaaaaaaa-0000-0000-0000-000000000004', 'bbbbbbbb-0000-0000-0000-000000000002',
     'haute', 'confidentiel', '2026-07-10 12:00:00+01',
     'Réclamation concernant un délai de remboursement - Zineb Alaoui',
     'Traité et clôturé par la DAJ');

UPDATE dos_dossiers
   SET date_cloture = '2026-08-05 16:00:00+01'
 WHERE id = 'eeeeeeee-0000-0000-0000-000000000002';

-- ----------------------------------------------------------------------------
-- 2. Parties du dossier
-- ----------------------------------------------------------------------------

INSERT INTO dos_parties (id, dossier_id, tiers_id, role_partie) VALUES
    ('eeeeeeee-0001-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001', 'demandeur'),
    ('eeeeeeee-0001-0000-0000-000000000002', 'eeeeeeee-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'demandeur');

-- ----------------------------------------------------------------------------
-- 3. Courriers rattachés (lien direct avec le module Bureau d'Ordre)
-- ----------------------------------------------------------------------------

INSERT INTO dos_courriers (id, dossier_id, courrier_id, role_courrier) VALUES
    ('eeeeeeee-0002-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000001', 'dddddddd-0000-0000-0000-000000000001', 'courrier_initiateur'),
    ('eeeeeeee-0002-0000-0000-000000000002', 'eeeeeeee-0000-0000-0000-000000000002', 'dddddddd-0000-0000-0000-000000000002', 'courrier_initiateur');

-- ----------------------------------------------------------------------------
-- 4. Documents rattachés
-- ----------------------------------------------------------------------------

INSERT INTO dos_documents (id, dossier_id, document_id, role_document) VALUES
    ('eeeeeeee-0003-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000001', 'cccccccc-0000-0000-0000-000000000001', 'piece_principale'),
    ('eeeeeeee-0003-0000-0000-000000000002', 'eeeeeeee-0000-0000-0000-000000000002', 'cccccccc-0000-0000-0000-000000000002', 'piece_jointe');

-- ----------------------------------------------------------------------------
-- 5. Affectations aux unités
-- ----------------------------------------------------------------------------

INSERT INTO dos_affectations (id, dossier_id, unite_id, role_affectation, date_debut, date_fin) VALUES
    ('eeeeeeee-0004-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000002', 'instructeur', '2026-07-02 10:05:00+01', NULL),
    ('eeeeeeee-0004-0000-0000-000000000002', 'eeeeeeee-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000004', 'instructeur', '2026-07-10 12:00:00+01', '2026-08-05 16:00:00+01');

-- ----------------------------------------------------------------------------
-- 6. Historique des statuts
-- ----------------------------------------------------------------------------

INSERT INTO dos_statuts_hist (id, dossier_id, ancien_statut_code, nouveau_statut_code, changed_at, motif) VALUES
    ('eeeeeeee-0005-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000001', NULL, 'ouvert', '2026-07-02 10:05:00+01', 'Ouverture automatique à la réception du courrier'),
    ('eeeeeeee-0005-0000-0000-000000000002', 'eeeeeeee-0000-0000-0000-000000000001', 'ouvert', 'en_instruction', '2026-07-02 14:25:00+01', 'Pris en charge par la DSA'),

    ('eeeeeeee-0005-0000-0000-000000000003', 'eeeeeeee-0000-0000-0000-000000000002', NULL, 'ouvert', '2026-07-10 12:00:00+01', 'Ouverture automatique à la réception de la réclamation'),
    ('eeeeeeee-0005-0000-0000-000000000004', 'eeeeeeee-0000-0000-0000-000000000002', 'ouvert', 'en_instruction', '2026-07-10 13:00:00+01', 'Pris en charge par la DAJ'),
    ('eeeeeeee-0005-0000-0000-000000000005', 'eeeeeeee-0000-0000-0000-000000000002', 'en_instruction', 'clos', '2026-08-05 16:00:00+01', 'Remboursement effectué, réclamation résolue');

COMMIT;

-- ============================================================================
-- Vérification :
--   SELECT numero_dossier, type_dossier_code, statut_code, objet
--   FROM dos_dossiers ORDER BY numero_dossier;
-- Doit renvoyer 2 lignes (DOS-2026-000012, DOS-2026-000045).
-- ============================================================================
