import { createDirectus, rest, staticToken } from '@directus/sdk'

const url = import.meta.env.VITE_DIRECTUS_URL || 'http://localhost:8055'
const token = import.meta.env.VITE_DIRECTUS_TOKEN || ''

if (!token) {
  // Pas bloquant : les collections en lecture publique fonctionneront quand
  // même, mais toute écriture (création de courrier) échouera tant que le
  // jeton n'est pas renseigné dans frontend/.env — voir docs/SETUP.md §8-9.
  console.warn(
    '[directus] VITE_DIRECTUS_TOKEN est vide : les appels authentifiés échoueront.'
  )
}

export const directus = createDirectus(url).with(rest()).with(staticToken(token))
