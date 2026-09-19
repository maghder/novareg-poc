import { ref } from 'vue'
import { readItems } from '@directus/sdk'
import { directus } from './directus'

// État partagé (singleton) : un seul jeu de compteurs pour toute l'app,
// consommé par App.vue pour afficher les badges dans la nav.
export const compteurs = ref({
  indexation: 0,
  affectation: 0,
  expedition: 0,
  ar: 0
})

async function compter(collection, filter) {
  try {
    const rows = await directus.request(
      readItems(collection, { filter, fields: ['id'], limit: -1 })
    )
    return rows.length
  } catch (e) {
    console.error(`Erreur de comptage sur ${collection}`, e)
    return 0
  }
}

export async function rafraichirCompteurs() {
  const [indexation, affectation, expedition, ar] = await Promise.all([
    compter('bo_courriers', { statut_code: { _eq: 'recu' } }),
    compter('bo_courriers', { statut_code: { _eq: 'enregistre' }, sens: { _eq: 'arrivee' } }),
    compter('bo_courriers', { statut_code: { _eq: 'enregistre' }, sens: { _eq: 'depart' } }),
    compter('bo_expedition_tentatives', { statut_code: { _eq: 'expedie' } })
  ])
  compteurs.value = { indexation, affectation, expedition, ar }
}
