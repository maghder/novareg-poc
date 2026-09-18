// Miroir applicatif des libellés définis dans db/02_novareg_seed.sql.
// Évite une requête cfg_* supplémentaire pour l'affichage des badges de la
// liste. Dans une V2, on peut charger ces libellés dynamiquement depuis
// Directus (GET /items/cfg_statuts_courrier) pour rester 100% piloté par la
// base ; on garde ici une version statique pour simplicité du POC.

export const STATUTS_COURRIER = {
  enregistre: { libelle: 'Enregistré', color: '#64748b' },
  oriente: { libelle: 'Orienté', color: '#2563eb' },
  en_cours_traitement: { libelle: 'En cours de traitement', color: '#d97706' },
  en_attente_complement: { libelle: 'En attente de complément', color: '#d97706' },
  traite: { libelle: 'Traité', color: '#16a34a' },
  cloture: { libelle: 'Clôturé', color: '#16a34a' },
  archive: { libelle: 'Archivé', color: '#64748b' },
  annule: { libelle: 'Annulé', color: '#dc2626' }
}

export const SENS_COURRIER = {
  arrivee: { libelle: 'Arrivée', color: '#2563eb' },
  depart: { libelle: 'Départ', color: '#7c3aed' }
}

export const STATUTS_ORIENTATION = {
  transmis: { libelle: 'Transmis', color: '#d97706' },
  recu: { libelle: 'Reçu', color: '#16a34a' },
  retourne: { libelle: 'Retourné', color: '#dc2626' },
  annule: { libelle: 'Annulé', color: '#dc2626' }
}

export const STATUTS_DOSSIER = {
  ouvert: { libelle: 'Ouvert', color: '#64748b' },
  en_instruction: { libelle: 'En instruction', color: '#2563eb' },
  en_attente_complement: { libelle: 'En attente de complément', color: '#d97706' },
  avis_favorable: { libelle: 'Avis favorable', color: '#16a34a' },
  avis_defavorable: { libelle: 'Avis défavorable', color: '#dc2626' },
  decide: { libelle: 'Décidé', color: '#16a34a' },
  clos: { libelle: 'Clos', color: '#64748b' },
  archive: { libelle: 'Archivé', color: '#64748b' }
}

export const PRIORITES = {
  basse: { libelle: 'Basse', color: '#64748b' },
  normale: { libelle: 'Normale', color: '#2563eb' },
  haute: { libelle: 'Haute', color: '#d97706' },
  urgente: { libelle: 'Urgente', color: '#dc2626' }
}

export function labelFor(map, code) {
  return map[code]?.libelle ?? code ?? '—'
}

export function colorFor(map, code) {
  return map[code]?.color ?? '#64748b'
}

export function formatDate(value) {
  if (!value) return '—'
  return new Date(value).toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  })
}

export function formatDateTime(value) {
  if (!value) return '—'
  return new Date(value).toLocaleString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}
