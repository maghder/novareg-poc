-- ============================================================================
-- 03_bo_demo_data.sql
-- Jeu de données de démonstration — Processus Bureau d'Ordre
-- ----------------------------------------------------------------------------
-- Périmètre du POC : org_unites, core_tiers (+ sous-tables), doc_documents,
-- bo_courriers et toute la chaîne bo_* (parties, orientations, pièces
-- jointes, expédition, tentative, accusé de réception).
-- Pré-requis : 01_novareg_schema.sql puis 02_novareg_seed.sql déjà exécutés.
-- Les UUID sont codés en dur (lisibles par bloc fonctionnel) pour permettre
-- les références croisées explicites dans ce script ; à ne jamais faire
-- en production.
-- Rejouable : DELETE de sûreté sur les mêmes id avant ré-insertion.
-- ============================================================================

BEGIN;

-- Nettoyage idempotent (ordre inverse des dépendances)
DELETE FROM bo_accuses_reception       WHERE id = 'dddddddd-0006-0000-0000-000000000001';
DELETE FROM bo_expedition_tentatives   WHERE id = 'dddddddd-0005-0000-0000-000000000001';
DELETE FROM bo_expeditions             WHERE id = 'dddddddd-0004-0000-0000-000000000001';
DELETE FROM bo_courrier_documents      WHERE id::text LIKE 'dddddddd-0003-%';
DELETE FROM bo_orientations            WHERE id::text LIKE 'dddddddd-0002-%';
DELETE FROM bo_courrier_parties        WHERE id::text LIKE 'dddddddd-0001-%';
DELETE FROM bo_courriers               WHERE id::text LIKE 'dddddddd-0000-%';
DELETE FROM doc_versions               WHERE id::text LIKE 'cccccccc-0001-%';
DELETE FROM doc_documents              WHERE id::text LIKE 'cccccccc-0000-%';
DELETE FROM core_tiers_contacts        WHERE id::text LIKE 'bbbbbbbb-0005-%';
DELETE FROM core_tiers_adresses        WHERE id::text LIKE 'bbbbbbbb-0004-%';
DELETE FROM core_tiers_identifiants    WHERE id::text LIKE 'bbbbbbbb-0003-%';
DELETE FROM core_tiers_roles           WHERE id::text LIKE 'bbbbbbbb-0002-%';
DELETE FROM core_tiers_noms            WHERE id::text LIKE 'bbbbbbbb-0001-%';
DELETE FROM core_tiers                 WHERE id::text LIKE 'bbbbbbbb-0000-%';
DELETE FROM org_unites                 WHERE id::text LIKE 'aaaaaaaa-0000-%';

-- ----------------------------------------------------------------------------
-- 1. Organisation interne
-- ----------------------------------------------------------------------------

INSERT INTO org_unites (id, code_unite, libelle, type_unite, parent_id, actif) VALUES
    ('aaaaaaaa-0000-0000-0000-000000000001', 'DG',   'Direction Générale', 'direction', NULL, true);

INSERT INTO org_unites (id, code_unite, libelle, type_unite, parent_id, actif) VALUES
    ('aaaaaaaa-0000-0000-0000-000000000002', 'DSA',  'Direction de la Surveillance des Assurances', 'direction', 'aaaaaaaa-0000-0000-0000-000000000001', true),
    ('aaaaaaaa-0000-0000-0000-000000000003', 'DSPS', 'Direction de la Surveillance de la Prévoyance Sociale', 'direction', 'aaaaaaaa-0000-0000-0000-000000000001', true),
    ('aaaaaaaa-0000-0000-0000-000000000004', 'DAJ',  'Direction des Affaires Juridiques et du Contentieux', 'direction', 'aaaaaaaa-0000-0000-0000-000000000001', true),
    ('aaaaaaaa-0000-0000-0000-000000000005', 'BO',   'Bureau d''Ordre Central', 'service', 'aaaaaaaa-0000-0000-0000-000000000001', true);

-- ----------------------------------------------------------------------------
-- 2. Tiers (correspondants externes)
-- ----------------------------------------------------------------------------

INSERT INTO core_tiers (id, code_tiers, nature_code, statut, date_entree_relation, source_creation) VALUES
    ('bbbbbbbb-0000-0000-0000-000000000001', 'TIERS-ATLAS-0001', 'personne_morale', 'actif', '2026-01-15', 'poc_demo'),
    ('bbbbbbbb-0000-0000-0000-000000000002', 'TIERS-ZALAOUI-0001', 'personne_physique', 'actif', '2026-06-01', 'poc_demo');

INSERT INTO core_tiers_noms (id, tiers_id, type_nom, nom, is_primary, valid_from) VALUES
    ('bbbbbbbb-0001-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001', 'principal', 'Atlas Assurances SA', true, '2026-01-15'),
    ('bbbbbbbb-0001-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'principal', 'Zineb Alaoui', true, '2026-06-01');

INSERT INTO core_tiers_roles (id, tiers_id, role_code, valid_from) VALUES
    ('bbbbbbbb-0002-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001', 'assujetti', '2026-01-15'),
    ('bbbbbbbb-0002-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'tiers_declarant', '2026-06-01');

INSERT INTO core_tiers_identifiants (id, tiers_id, type_identifiant_code, valeur, valeur_normalisee, autorite_emettrice, valid_from, is_primary) VALUES
    ('bbbbbbbb-0003-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001', 'rc', '123456', '123456', 'Tribunal de Commerce de Casablanca', '2026-01-15', true),
    ('bbbbbbbb-0003-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'cin', 'BE482913', 'be482913', 'Direction Générale de la Sûreté Nationale', '2026-06-01', true);

INSERT INTO core_tiers_adresses (id, tiers_id, type_adresse_code, ligne_1, ville, code_postal, region, pays_code, is_primary, valid_from) VALUES
    ('bbbbbbbb-0004-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001', 'siege_social', '12 Avenue Hassan II', 'Casablanca', '20000', 'Casablanca-Settat', 'MA', true, '2026-01-15'),
    ('bbbbbbbb-0004-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'domicile', 'Résidence Al Andalous, Immeuble 4, Appt 12', 'Rabat', '10000', 'Rabat-Salé-Kénitra', 'MA', true, '2026-06-01');

INSERT INTO core_tiers_contacts (id, tiers_id, type_contact_code, valeur, valeur_normalisee, is_primary, valid_from) VALUES
    ('bbbbbbbb-0005-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001', 'email', 'contact@atlas-assurances.example.ma', 'contact@atlas-assurances.example.ma', true, '2026-01-15'),
    ('bbbbbbbb-0005-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'email', 'zineb.alaoui@example.ma', 'zineb.alaoui@example.ma', true, '2026-06-01');

-- ----------------------------------------------------------------------------
-- 3. Documents (GED) et versions
-- ----------------------------------------------------------------------------

INSERT INTO doc_documents (id, code_document, type_document_code, titre, langue_code, confidentialite_code, date_document, statut) VALUES
    ('cccccccc-0000-0000-0000-000000000001', 'DOC-2026-000001', 'courrier', 'Demande de mise à jour d''adresse du siège social', 'fr', 'interne', '2026-06-28', 'actif'),
    ('cccccccc-0000-0000-0000-000000000002', 'DOC-2026-000002', 'piece_identite', 'Copie CIN - Zineb Alaoui', 'fr', 'confidentiel', '2026-07-10', 'actif'),
    ('cccccccc-0000-0000-0000-000000000003', 'DOC-2026-000003', 'attestation', 'Accusé de réception NOVAREG - dossier ATLAS-0001', 'fr', 'interne', '2026-07-05', 'actif');

INSERT INTO doc_versions (id, document_id, version_no, object_key, nom_fichier, mime_type, est_original) VALUES
    ('cccccccc-0001-0000-0000-000000000001', 'cccccccc-0000-0000-0000-000000000001', 1, 'poc-demo/documents/demande_adresse_atlas.pdf', 'demande_adresse_atlas.pdf', 'application/pdf', true),
    ('cccccccc-0001-0000-0000-000000000002', 'cccccccc-0000-0000-0000-000000000002', 1, 'poc-demo/documents/cin_zineb_alaoui.pdf', 'cin_zineb_alaoui.pdf', 'application/pdf', true),
    ('cccccccc-0001-0000-0000-000000000003', 'cccccccc-0000-0000-0000-000000000003', 1, 'poc-demo/documents/ar_novareg_atlas_0001.pdf', 'ar_novareg_atlas_0001.pdf', 'application/pdf', true);

-- ----------------------------------------------------------------------------
-- 4. Courriers Bureau d'Ordre (4 cas représentatifs du cycle de vie)
-- ----------------------------------------------------------------------------

INSERT INTO bo_courriers
    (id, numero_chrono, sens, date_enregistrement, date_document, objet, reference_externe,
     canal_code, support_code, priorite_code, confidentialite_code, statut_code,
     unite_enregistrement_id, unite_emettrice_id, langue_code, commentaire_bo)
VALUES
    -- C1 : arrivée, orientée vers la DSA (instruction en cours)
    ('dddddddd-0000-0000-0000-000000000001', 'BO-2026-000101', 'arrivee', '2026-07-02 09:14:00+01', '2026-06-28',
     'Demande de mise à jour d''adresse du siège social', 'ATLAS/DG/2026-0456',
     'courrier_postal', 'papier', 'normale', 'interne', 'oriente',
     'aaaaaaaa-0000-0000-0000-000000000005', NULL, 'fr',
     'Dossier complet reçu, transmis à la DSA pour instruction'),

    -- C2 : arrivée, réclamation en cours de traitement par la DAJ
    ('dddddddd-0000-0000-0000-000000000002', 'BO-2026-000102', 'arrivee', '2026-07-10 11:02:00+01', '2026-07-09',
     'Réclamation concernant un délai de remboursement', NULL,
     'portail_en_ligne', 'electronique', 'haute', 'confidentiel', 'en_cours_traitement',
     'aaaaaaaa-0000-0000-0000-000000000005', NULL, 'fr',
     'Réclamation individuelle, à instruire par la DAJ'),

    -- C3 : départ, AR envoyé et distribué — dossier clôturé
    ('dddddddd-0000-0000-0000-000000000003', 'BO-2026-000078', 'depart', '2026-07-05 15:30:00+01', '2026-07-05',
     'Accusé de réception - dossier ATLAS-0001', 'BO-2026-000101',
     'courrier_postal', 'papier', 'normale', 'interne', 'cloture',
     'aaaaaaaa-0000-0000-0000-000000000005', 'aaaaaaaa-0000-0000-0000-000000000005', 'fr',
     'AR envoyé le jour même de l''enregistrement du dossier ATLAS'),

    -- C4 : arrivée, tout juste enregistrée, pas encore orientée
    ('dddddddd-0000-0000-0000-000000000004', 'BO-2026-000115', 'arrivee', '2026-09-15 08:47:00+01', '2026-09-12',
     'Transmission de statuts mis à jour', NULL,
     'email', 'electronique', 'normale', 'interne', 'enregistre',
     'aaaaaaaa-0000-0000-0000-000000000005', NULL, 'fr', NULL);

-- ----------------------------------------------------------------------------
-- 5. Parties prenantes par courrier
-- ----------------------------------------------------------------------------

INSERT INTO bo_courrier_parties (id, courrier_id, tiers_id, role_code, libelle_snapshot, ordre) VALUES
    ('dddddddd-0001-0000-0000-000000000001', 'dddddddd-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001', 'expediteur', 'Atlas Assurances SA', 1),
    ('dddddddd-0001-0000-0000-000000000002', 'dddddddd-0000-0000-0000-000000000001', NULL, 'destinataire', 'NOVAREG - Bureau d''Ordre', 1),

    ('dddddddd-0001-0000-0000-000000000003', 'dddddddd-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'expediteur', 'Zineb Alaoui', 1),
    ('dddddddd-0001-0000-0000-000000000004', 'dddddddd-0000-0000-0000-000000000002', NULL, 'destinataire', 'NOVAREG - Bureau d''Ordre', 1),

    ('dddddddd-0001-0000-0000-000000000005', 'dddddddd-0000-0000-0000-000000000003', NULL, 'expediteur', 'NOVAREG - Bureau d''Ordre', 1),
    ('dddddddd-0001-0000-0000-000000000006', 'dddddddd-0000-0000-0000-000000000003', 'bbbbbbbb-0000-0000-0000-000000000001', 'destinataire', 'Atlas Assurances SA', 1),

    ('dddddddd-0001-0000-0000-000000000007', 'dddddddd-0000-0000-0000-000000000004', 'bbbbbbbb-0000-0000-0000-000000000001', 'expediteur', 'Atlas Assurances SA', 1),
    ('dddddddd-0001-0000-0000-000000000008', 'dddddddd-0000-0000-0000-000000000004', NULL, 'destinataire', 'NOVAREG - Bureau d''Ordre', 1);

-- ----------------------------------------------------------------------------
-- 6. Orientations vers les unités métier
-- ----------------------------------------------------------------------------

INSERT INTO bo_orientations (id, courrier_id, unite_source_id, unite_destination_id, date_transmission, date_reception, statut, motif) VALUES
    ('dddddddd-0002-0000-0000-000000000001', 'dddddddd-0000-0000-0000-000000000001',
     'aaaaaaaa-0000-0000-0000-000000000005', 'aaaaaaaa-0000-0000-0000-000000000002',
     '2026-07-02 10:00:00+01', '2026-07-02 14:20:00+01', 'recu', 'Instruction changement d''adresse réglementaire'),

    ('dddddddd-0002-0000-0000-000000000002', 'dddddddd-0000-0000-0000-000000000002',
     'aaaaaaaa-0000-0000-0000-000000000005', 'aaaaaaaa-0000-0000-0000-000000000004',
     '2026-07-10 11:30:00+01', NULL, 'transmis', 'Instruction réclamation');

-- ----------------------------------------------------------------------------
-- 7. Pièces jointes rattachées aux courriers
-- ----------------------------------------------------------------------------

INSERT INTO bo_courrier_documents (id, courrier_id, document_id, role_document, ordre) VALUES
    ('dddddddd-0003-0000-0000-000000000001', 'dddddddd-0000-0000-0000-000000000001', 'cccccccc-0000-0000-0000-000000000001', 'piece_jointe', 1),
    ('dddddddd-0003-0000-0000-000000000002', 'dddddddd-0000-0000-0000-000000000002', 'cccccccc-0000-0000-0000-000000000002', 'piece_jointe', 1),
    ('dddddddd-0003-0000-0000-000000000003', 'dddddddd-0000-0000-0000-000000000003', 'cccccccc-0000-0000-0000-000000000003', 'preuve', 1);

-- ----------------------------------------------------------------------------
-- 8. Expédition, tentative et accusé de réception (courrier C3 sortant)
-- ----------------------------------------------------------------------------

INSERT INTO bo_expeditions (id, courrier_id, destinataire_partie_id, mode_expedition_code, operateur, ar_requis, statut_code, date_preparation) VALUES
    ('dddddddd-0004-0000-0000-000000000001', 'dddddddd-0000-0000-0000-000000000003',
     'dddddddd-0001-0000-0000-000000000006', 'recommande_ar', 'Barid Al-Maghrib', true, 'distribue', '2026-07-05 14:00:00+01');

INSERT INTO bo_expedition_tentatives
    (id, expedition_id, numero_tentative, numero_suivi, date_remise_operateur, date_expedition, date_distribution, statut_code, commentaire)
VALUES
    ('dddddddd-0005-0000-0000-000000000001', 'dddddddd-0004-0000-0000-000000000001', 1, 'RA123456789MA',
     '2026-07-05 16:00:00+01', '2026-07-06 08:00:00+01', '2026-07-08 10:15:00+01', 'distribue',
     'Distribué en 2 jours ouvrés');

INSERT INTO bo_accuses_reception
    (id, tentative_id, statut_ar_code, date_reception_ar, reference_ar, nom_recepteur, qualite_recepteur, preuve_ar_document_id, commentaire)
VALUES
    ('dddddddd-0006-0000-0000-000000000001', 'dddddddd-0005-0000-0000-000000000001', 'recu',
     '2026-07-08 10:15:00+01', 'RA123456789MA', 'M. Youssef Bennis', 'Agent d''accueil - Atlas Assurances',
     'cccccccc-0000-0000-0000-000000000003', 'AR scanné et classé au dossier');

COMMIT;

-- ============================================================================
-- Vérification : la vue de suivi doit renvoyer 4 courriers avec expéditeur/
-- destinataire résolus et le statut d'orientation le plus récent.
--   SELECT numero_chrono, sens, statut_code, expediteur, destinataire,
--          statut_orientation
--   FROM vw_bo_courriers_suivi ORDER BY numero_chrono;
-- ============================================================================
