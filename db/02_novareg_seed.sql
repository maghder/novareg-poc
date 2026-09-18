-- ============================================================================
-- 02_novareg_seed.sql
-- Jeu de données de référence (vocabulaires contrôlés) — socle POC NOVAREG
-- ----------------------------------------------------------------------------
-- Alimente exclusivement les tables cfg_* créées par 01_novareg_schema.sql.
-- Idempotent : rejouable sans erreur grâce à ON CONFLICT DO NOTHING.
-- Ne contient aucune donnée métier (tiers, dossiers, courriers...) : voir
-- le jeu de données de démonstration livré séparément selon le périmètre
-- fonctionnel retenu pour le POC.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Natures et rôles des tiers
-- ----------------------------------------------------------------------------

INSERT INTO cfg_natures_tiers (code, libelle, description, ordre) VALUES
    ('personne_physique', 'Personne physique', 'Individu identifié par son CIN ou passeport', 10),
    ('personne_morale', 'Personne morale', 'Société, association ou organisme doté de la personnalité juridique', 20),
    ('organisme_public', 'Organisme public', 'Administration ou établissement public', 30),
    ('organisme_prive', 'Organisme privé', 'Entité privée non commerciale (fondation, ONG...)', 40)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_roles_tiers (code, libelle, description, ordre) VALUES
    ('assujetti', 'Assujetti', 'Entité soumise au contrôle de NOVAREG', 10),
    ('intermediaire', 'Intermédiaire', 'Intermédiaire en assurance ou en réassurance', 20),
    ('dirigeant', 'Dirigeant', 'Dirigeant effectif ou mandataire social', 30),
    ('actionnaire', 'Actionnaire', 'Détenteur de participation au capital', 40),
    ('representant_legal', 'Représentant légal', 'Représentant habilité à agir au nom d''un tiers', 50),
    ('commissaire_comptes', 'Commissaire aux comptes', 'Auditeur légal externe', 60),
    ('correspondant', 'Correspondant', 'Point de contact administratif', 70),
    ('tiers_declarant', 'Tiers déclarant', 'Auteur d''une déclaration ou réclamation', 80)
ON CONFLICT (code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2. Identifiants, adresses, contacts
-- ----------------------------------------------------------------------------

INSERT INTO cfg_types_identifiants (code, libelle, sensible, ordre) VALUES
    ('cin', 'Carte d''identité nationale', true, 10),
    ('passeport', 'Passeport', true, 20),
    ('rc', 'Registre de commerce', false, 30),
    ('if', 'Identifiant fiscal', false, 40),
    ('ice', 'Identifiant commun de l''entreprise', false, 50),
    ('agrement_novareg', 'Numéro d''agrément NOVAREG', false, 60)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_types_adresses (code, libelle, description, ordre) VALUES
    ('siege_social', 'Siège social', 'Adresse légale de l''entité', 10),
    ('correspondance', 'Correspondance', 'Adresse utilisée pour les échanges courrier', 20),
    ('domicile', 'Domicile', 'Résidence d''une personne physique', 30),
    ('succursale', 'Succursale', 'Établissement secondaire', 40),
    ('agence', 'Agence', 'Point de vente ou d''exploitation', 50)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_types_contacts (code, libelle, description, ordre) VALUES
    ('telephone_fixe', 'Téléphone fixe', NULL, 10),
    ('telephone_mobile', 'Téléphone mobile', NULL, 20),
    ('email', 'Adresse électronique', NULL, 30),
    ('fax', 'Fax', NULL, 40),
    ('site_web', 'Site web', NULL, 50)
ON CONFLICT (code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 3. Documents et confidentialité
-- ----------------------------------------------------------------------------

INSERT INTO cfg_types_documents (code, libelle, description, ordre) VALUES
    ('courrier', 'Courrier', 'Correspondance entrante ou sortante', 10),
    ('decision', 'Décision', 'Acte de décision formel', 20),
    ('rapport', 'Rapport', 'Rapport de contrôle ou d''instruction', 30),
    ('statuts', 'Statuts', 'Statuts d''une entité régulée', 40),
    ('proces_verbal', 'Procès-verbal', 'PV d''assemblée ou de conseil', 50),
    ('piece_identite', 'Pièce d''identité', 'Copie de CIN, passeport...', 60),
    ('attestation', 'Attestation', 'Attestation administrative', 70),
    ('releve', 'Relevé', 'Relevé financier ou statistique', 80),
    ('correspondance_interne', 'Correspondance interne', 'Note ou mémo interne', 90),
    ('autre', 'Autre', NULL, 999)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_niveaux_confidentialite (code, libelle, niveau, description) VALUES
    ('public', 'Public', 1, 'Accessible sans restriction'),
    ('interne', 'Interne', 2, 'Réservé au personnel NOVAREG'),
    ('restreint', 'Restreint', 3, 'Accès limité à l''unité en charge'),
    ('confidentiel', 'Confidentiel', 4, 'Accès nominatif limité'),
    ('secret', 'Secret', 5, 'Accès strictement contrôlé')
ON CONFLICT (code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 4. Bureau d'Ordre : canaux, priorités, statuts, expédition, AR
-- ----------------------------------------------------------------------------

INSERT INTO cfg_canaux_courrier (code, libelle, description, ordre) VALUES
    ('guichet', 'Guichet', 'Dépôt physique au guichet NOVAREG', 10),
    ('courrier_postal', 'Courrier postal', 'Voie postale classique', 20),
    ('email', 'Email', 'Courrier électronique', 30),
    ('portail_en_ligne', 'Portail en ligne', 'Téléservice NOVAREG', 40),
    ('fax', 'Fax', NULL, 50),
    ('remise_main_propre', 'Remise en main propre', NULL, 60)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_supports_courrier (code, libelle, description, ordre) VALUES
    ('papier', 'Papier', 'Support physique original', 10),
    ('electronique', 'Électronique', 'Support numérique natif', 20),
    ('mixte', 'Mixte', 'Original papier numérisé', 30)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_priorites (code, libelle, niveau) VALUES
    ('basse', 'Basse', 1),
    ('normale', 'Normale', 2),
    ('haute', 'Haute', 3),
    ('urgente', 'Urgente', 4)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_statuts_courrier (code, libelle, phase, ordre, terminal) VALUES
    ('enregistre', 'Enregistré', 'reception', 10, false),
    ('oriente', 'Orienté', 'orientation', 20, false),
    ('en_cours_traitement', 'En cours de traitement', 'traitement', 30, false),
    ('en_attente_complement', 'En attente de complément', 'traitement', 40, false),
    ('traite', 'Traité', 'traitement', 50, false),
    ('cloture', 'Clôturé', 'cloture', 60, true),
    ('archive', 'Archivé', 'cloture', 70, true),
    ('annule', 'Annulé', 'cloture', 80, true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_roles_parties_courrier (code, libelle, ordre) VALUES
    ('expediteur', 'Expéditeur', 10),
    ('destinataire', 'Destinataire', 20),
    ('copie', 'Copie (pour information)', 30),
    ('tiers_concerne', 'Tiers concerné', 40)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_modes_expedition (code, libelle, description, ordre) VALUES
    ('recommande_ar', 'Recommandé avec AR', 'Envoi postal recommandé avec accusé de réception', 10),
    ('courrier_simple', 'Courrier simple', 'Envoi postal sans suivi', 20),
    ('coursier', 'Coursier', 'Remise via société de coursiers', 30),
    ('main_propre', 'Main propre', 'Remise directe contre décharge', 40),
    ('email', 'Email', 'Envoi électronique', 50),
    ('portail', 'Portail en ligne', 'Notification via téléservice', 60)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_statuts_expedition (code, libelle, ordre, terminal) VALUES
    ('en_preparation', 'En préparation', 10, false),
    ('remis_operateur', 'Remis à l''opérateur', 20, false),
    ('expedie', 'Expédié', 30, false),
    ('distribue', 'Distribué', 40, true),
    ('retourne', 'Retourné', 50, true),
    ('annule', 'Annulé', 60, true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_statuts_ar (code, libelle, ordre, terminal) VALUES
    ('en_attente', 'En attente', 10, false),
    ('recu', 'Reçu', 20, true),
    ('non_recu', 'Non reçu', 30, true),
    ('illisible', 'Illisible / inexploitable', 40, true)
ON CONFLICT (code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 5. Dossiers
-- ----------------------------------------------------------------------------

INSERT INTO cfg_types_dossiers (code, libelle, domaine, description, ordre) VALUES
    ('agrement_nouveau', 'Nouvel agrément', 'agrement', 'Demande d''agrément initial', 10),
    ('agrement_modification', 'Modification d''agrément', 'agrement', 'Extension ou modification d''agrément existant', 20),
    ('retrait_agrement', 'Retrait d''agrément', 'agrement', 'Procédure de retrait d''agrément', 30),
    ('changement_adresse', 'Changement d''adresse', 'gestion', 'Mise à jour d''adresse réglementaire', 40),
    ('changement_qualite', 'Changement de qualité', 'gestion', 'Changement de qualité d''un intermédiaire', 50),
    ('changement_dirigeants', 'Changement de dirigeants', 'gouvernance', 'Nomination ou changement de dirigeants', 60),
    ('controle_sur_place', 'Contrôle sur place', 'controle', 'Mission de contrôle sur site', 70),
    ('controle_sur_piece', 'Contrôle sur pièces', 'controle', 'Contrôle documentaire', 80),
    ('reclamation', 'Réclamation', 'protection_assures', 'Réclamation d''un assuré ou tiers', 90),
    ('contentieux', 'Contentieux', 'contentieux', 'Procédure contentieuse', 100),
    ('autre', 'Autre', NULL, NULL, 999)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_statuts_dossiers (code, libelle, ordre, terminal) VALUES
    ('ouvert', 'Ouvert', 10, false),
    ('en_instruction', 'En instruction', 20, false),
    ('en_attente_complement', 'En attente de complément', 30, false),
    ('avis_favorable', 'Avis favorable', 40, false),
    ('avis_defavorable', 'Avis défavorable', 50, false),
    ('decide', 'Décidé', 60, false),
    ('clos', 'Clos', 70, true),
    ('archive', 'Archivé', 80, true)
ON CONFLICT (code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 6. Actes et décisions
-- ----------------------------------------------------------------------------

INSERT INTO cfg_types_actes (code, libelle, description, ordre) VALUES
    ('changement_adresse', 'Changement d''adresse', 'Acte de mise à jour d''adresse réglementaire', 10),
    ('changement_qualite', 'Changement de qualité', 'Acte de changement de qualité d''intermédiaire', 20),
    ('nouvel_agrement', 'Nouvel agrément', 'Acte de création d''entité régulée et d''octroi d''agrément', 30),
    ('retrait_agrement', 'Retrait d''agrément', 'Acte de retrait d''agrément', 40),
    ('mise_en_demeure', 'Mise en demeure', 'Acte de mise en demeure', 50),
    ('sanction', 'Sanction', 'Acte de sanction disciplinaire ou pécuniaire', 60),
    ('autre', 'Autre', NULL, 999)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_statuts_actes (code, libelle, ordre, terminal) VALUES
    ('initie', 'Initié', 10, false),
    ('en_cours', 'En cours', 20, false),
    ('valide', 'Validé', 30, false),
    ('execute', 'Exécuté', 40, true),
    ('rejete', 'Rejeté', 50, true),
    ('annule', 'Annulé', 60, true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_types_decisions (code, libelle, description, ordre) VALUES
    ('decision_octroi', 'Décision d''octroi', 'Octroi d''un agrément ou d''une autorisation', 10),
    ('decision_refus', 'Décision de refus', 'Refus d''une demande', 20),
    ('decision_retrait', 'Décision de retrait', 'Retrait d''un agrément ou d''une autorisation', 30),
    ('decision_suspension', 'Décision de suspension', 'Suspension temporaire', 40),
    ('mise_en_demeure', 'Mise en demeure', 'Injonction formelle', 50),
    ('sanction_pecuniaire', 'Sanction pécuniaire', 'Amende ou pénalité financière', 60),
    ('avis', 'Avis', 'Avis consultatif', 70),
    ('note_interne', 'Note interne', 'Décision à portée interne', 80)
ON CONFLICT (code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 7. Référentiel réglementaire : entités régulées, intermédiaires, autorisations
-- ----------------------------------------------------------------------------

INSERT INTO cfg_types_entites_regulees (code, libelle, secteur, description, ordre) VALUES
    ('entreprise_assurance', 'Entreprise d''assurance', 'assurance', 'Entreprise agréée pour exercer l''assurance directe', 10),
    ('entreprise_reassurance', 'Entreprise de réassurance', 'reassurance', 'Entreprise agréée pour exercer la réassurance', 20),
    ('intermediaire_assurance', 'Intermédiaire d''assurance', 'intermediation', 'Agent général, courtier ou bancassureur', 30),
    ('organisme_prevoyance_sociale', 'Organisme de prévoyance sociale', 'prevoyance_sociale', 'Organisme gérant un régime de prévoyance', 40),
    ('mutuelle', 'Mutuelle', 'prevoyance_sociale', 'Société mutualiste', 50),
    ('caisse_retraite', 'Caisse de retraite', 'prevoyance_sociale', 'Organisme de gestion de retraite', 60),
    ('societe_gestion_actifs', 'Société de gestion d''actifs', 'gestion_actifs', 'Gestionnaire d''actifs pour compte de tiers régulés', 70)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_statuts_entites_regulees (code, libelle, ordre, terminal) VALUES
    ('en_cours_agrement', 'En cours d''agrément', 10, false),
    ('en_activite', 'En activité', 20, false),
    ('suspendu', 'Suspendu', 30, false),
    ('en_liquidation', 'En liquidation', 40, false),
    ('retire', 'Agrément retiré', 50, true),
    ('radie', 'Radié', 60, true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_qualites_intermediaires (code, libelle, description, ordre) VALUES
    ('agent_general', 'Agent général', 'Intermédiaire personne physique ou morale mandaté par une entreprise', 10),
    ('courtier', 'Courtier', 'Intermédiaire indépendant représentant l''assuré', 20),
    ('bancassureur', 'Bancassureur', 'Établissement bancaire habilité à distribuer de l''assurance', 30),
    ('mandataire', 'Mandataire', 'Mandataire d''intermédiaire', 40),
    ('autre', 'Autre', NULL, 999)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_types_autorisations (code, libelle, description, ordre) VALUES
    ('agrement_exercice', 'Agrément d''exercice', 'Autorisation générale d''exercer', 10),
    ('agrement_produit', 'Agrément de produit', 'Autorisation d''un produit ou d''une branche', 20),
    ('extension_agrement', 'Extension d''agrément', 'Extension du périmètre d''un agrément existant', 30),
    ('visa_produit', 'Visa de produit', 'Visa préalable de conditions générales', 40),
    ('habilitation_dirigeant', 'Habilitation de dirigeant', 'Habilitation individuelle d''un dirigeant', 50)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_statuts_autorisations (code, libelle, ordre, terminal) VALUES
    ('en_instance', 'En instance', 10, false),
    ('octroyee', 'Octroyée', 20, false),
    ('suspendue', 'Suspendue', 30, false),
    ('retiree', 'Retirée', 40, true),
    ('expiree', 'Expirée', 50, true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_types_relations_reglementaires (code, libelle, description, directionnelle, ordre) VALUES
    ('filiale_de', 'Filiale de', 'Relation de filiation capitalistique', true, 10),
    ('actionnaire_de', 'Actionnaire de', 'Détention de participation', true, 20),
    ('groupe_avec', 'Appartient au même groupe que', 'Appartenance à un même groupe financier', false, 30),
    ('delegataire_de', 'Délégataire de gestion de', 'Délégation de gestion opérationnelle', true, 40),
    ('reassure_par', 'Réassuré par', 'Relation de cession en réassurance', true, 50)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_roles_representants (code, libelle, description, ordre) VALUES
    ('dirigeant_effectif', 'Dirigeant effectif', 'Personne assurant la direction effective', 10),
    ('administrateur', 'Administrateur', 'Membre du conseil d''administration', 20),
    ('president_conseil', 'Président du conseil', 'Président du conseil d''administration ou de surveillance', 30),
    ('directeur_general', 'Directeur général', NULL, 40),
    ('mandataire_social', 'Mandataire social', NULL, 50),
    ('commissaire_comptes', 'Commissaire aux comptes', NULL, 60),
    ('representant_legal', 'Représentant légal', NULL, 70)
ON CONFLICT (code) DO NOTHING;

COMMIT;

-- ============================================================================
-- Vérification rapide après exécution :
--   SELECT relname, n_live_tup FROM pg_stat_user_tables
--   WHERE relname LIKE 'cfg_%' ORDER BY relname;
-- Chaque table cfg_* doit contenir au moins une ligne.
-- ============================================================================
