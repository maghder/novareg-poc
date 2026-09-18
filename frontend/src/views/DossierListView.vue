<script setup>
import { onMounted, ref } from 'vue'
import { readItems } from '@directus/sdk'
import { directus } from '../lib/directus'
import StatusBadge from '../components/StatusBadge.vue'
import { STATUTS_DOSSIER, PRIORITES, labelFor, colorFor, formatDate } from '../lib/labels'

const dossiers = ref([])
const loading = ref(true)
const error = ref(null)

async function chargerDossiers() {
  loading.value = true
  error.value = null
  try {
    dossiers.value = await directus.request(
      readItems('dos_dossiers', {
        fields: [
          'id',
          'numero_dossier',
          'type_dossier_code',
          'statut_code',
          'priorite_code',
          'objet',
          'date_ouverture',
          'unite_responsable_id.libelle'
        ],
        sort: ['-date_ouverture'],
        limit: 100
      })
    )
  } catch (e) {
    error.value =
      "Impossible de charger les dossiers. Vérifiez que les 6 collections dos_* " +
      "sont adoptées dans Directus et que le jeton a les droits de lecture dessus."
    console.error(e)
  } finally {
    loading.value = false
  }
}

onMounted(chargerDossiers)
</script>

<template>
  <section>
    <div class="toolbar">
      <h1>Dossiers</h1>
    </div>

    <p v-if="loading" class="hint">Chargement…</p>
    <p v-else-if="error" class="error">{{ error }}</p>
    <p v-else-if="!dossiers.length" class="hint">Aucun dossier à afficher.</p>

    <table v-else class="table">
      <thead>
        <tr>
          <th>N° dossier</th>
          <th>Type</th>
          <th>Ouvert le</th>
          <th>Objet</th>
          <th>Unité responsable</th>
          <th>Priorité</th>
          <th>Statut</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="d in dossiers"
          :key="d.id"
          class="row-link"
          @click="$router.push(`/dossiers/${d.id}`)"
        >
          <td class="mono">{{ d.numero_dossier }}</td>
          <td class="muted">{{ d.type_dossier_code }}</td>
          <td>{{ formatDate(d.date_ouverture) }}</td>
          <td class="objet">{{ d.objet }}</td>
          <td class="muted">{{ d.unite_responsable_id?.libelle || '—' }}</td>
          <td>
            <StatusBadge :label="labelFor(PRIORITES, d.priorite_code)" :color="colorFor(PRIORITES, d.priorite_code)" />
          </td>
          <td>
            <StatusBadge :label="labelFor(STATUTS_DOSSIER, d.statut_code)" :color="colorFor(STATUTS_DOSSIER, d.statut_code)" />
          </td>
        </tr>
      </tbody>
    </table>
  </section>
</template>

<style scoped>
.toolbar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; }
h1 { font-size: 1.3rem; margin: 0; }
.table { width: 100%; border-collapse: collapse; background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 1px 2px rgba(0,0,0,0.04); }
.table th {
  text-align: left;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: var(--muted);
  padding: 10px 14px;
  border-bottom: 1px solid var(--border);
}
.table td { padding: 12px 14px; border-bottom: 1px solid var(--border); font-size: 0.9rem; }
.row-link { cursor: pointer; }
.row-link:hover { background: #f1f5f9; }
.mono { font-family: 'SFMono-Regular', Consolas, monospace; font-size: 0.85rem; }
.objet { max-width: 280px; }
.muted { color: var(--muted); }
.hint { color: var(--muted); }
.error { color: #dc2626; }
</style>
