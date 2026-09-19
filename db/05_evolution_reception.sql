-- ============================================================================
-- 05_evolution_reception.sql
-- Évolution du schéma pour le processus de réception à 3 rôles
-- (agent réception → agent scan/indexation → agent affectation).
-- ----------------------------------------------------------------------------
-- 1. objet devient optionnel : l'agent réception ne le connaît pas encore,
--    il n'est renseigné qu'à l'indexation.
-- 2. numero_suivi_reception : code de suivi postal du recommandé, saisi
--    par l'agent réception s'il est disponible sur l'enveloppe.
-- 3. Nouveau statut 'recu' : courrier réceptionné, pas encore indexé.
-- 4. Nouveau canal 'recommande' : distinct de 'courrier_postal' (normal),
--    pour pouvoir filtrer/piloter séparément les recommandés.
-- Rejouable : chaque opération est idempotente (IF NOT EXISTS / ON CONFLICT).
-- ============================================================================

BEGIN;

ALTER TABLE bo_courriers ALTER COLUMN objet DROP NOT NULL;

ALTER TABLE bo_courriers ADD COLUMN IF NOT EXISTS numero_suivi_reception varchar(100);

INSERT INTO cfg_canaux_courrier (code, libelle, description, ordre) VALUES
    ('recommande', 'Recommandé', 'Courrier postal recommandé, reçu avec suivi', 25)
ON CONFLICT (code) DO NOTHING;

INSERT INTO cfg_statuts_courrier (code, libelle, phase, ordre, terminal) VALUES
    ('recu', 'Reçu (à indexer)', 'reception', 5, false)
ON CONFLICT (code) DO NOTHING;

COMMIT;

-- ============================================================================
-- Vérification :
--   SELECT column_name, is_nullable FROM information_schema.columns
--   WHERE table_name = 'bo_courriers' AND column_name IN ('objet', 'numero_suivi_reception');
--   → objet doit être YES, numero_suivi_reception doit exister.
--   SELECT code FROM cfg_canaux_courrier WHERE code = 'recommande';
--   SELECT code FROM cfg_statuts_courrier WHERE code = 'recu';
--   → chacune doit renvoyer 1 ligne.
-- ============================================================================
