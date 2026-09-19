<script setup>
import { onMounted, ref } from 'vue'
import { readItems } from '@directus/sdk'
import { directus } from '../lib/directus'
import { formatDateTime } from '../lib/labels'

const tentatives = ref([])
const loading = ref(true)
const error = ref(null)

async function charger() {
  loading.value = true
  error.value = null
  try {
    tentatives.value = await directus.request(
      readItems('bo_expedition_tentatives', {
        filter: { statut_code: { _eq: 'expedie' } },
        fields: [
          'id',
          'numero_suivi',
          'date_expedition',
          'expedition_id.mode_expedition_code',
          'expedition_id.operateur',
          'expedition_id.courrier_id.numero_chrono',
          'expedition_id.courrier_id.objet',
          'expedition_id.destinataire_partie_id.libelle_snapshot'
        ],
        sort: ['date_expedition'],
        limit: 100
      })
    )
  } catch (e) {
    error.value =
      "Impossible de charger la file des AR. Vérifiez les droits de lecture sur " +
      "bo_expedition_tentatives et bo_expeditions."
    console.error(e)
  } finally {
    loading.value = false
  }
}

onMounted(charger)
</script>

<template>
  <section>
    <div class="toolbar">
      <h1>AR à traiter</h1>
      <span class="count" v-if="!loading">{{ tentatives.length }} en attente</span>
    </div>
    <p class="hint">Expéditions envoyées avec accusé de réception attendu — à clôturer dès réception, ou à marquer comme retournées.</p>

    <p v-if="loading" class="hint">Chargement…</p>
    <p v-else-if="error" class="error">{{ error }}</p>
    <p v-else-if="!tentatives.length" class="hint">Aucun AR en attente.</p>

    <table v-else class="table">
      <thead>
        <tr>
          <th>N° chrono</th>
          <th>Objet</th>
          <th>Destinataire</th>
          <th>Mode</th>
          <th>Envoyé le</th>
          <th>N° de suivi</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="t in tentatives"
          :key="t.id"
          class="row-link"
          @click="$router.push(`/accuses-reception/${t.id}`)"
        >
          <td class="mono">{{ t.expedition_id?.courrier_id?.numero_chrono }}</td>
          <td class="objet">{{ t.expedition_id?.courrier_id?.objet }}</td>
          <td class="muted">{{ t.expedition_id?.destinataire_partie_id?.libelle_snapshot || '—' }}</td>
          <td class="muted">{{ t.expedition_id?.mode_expedition_code }}</td>
          <td>{{ formatDateTime(t.date_expedition) }}</td>
          <td class="mono muted">{{ t.numero_suivi || '—' }}</td>
        </tr>
      </tbody>
    </table>
  </section>
</template>

<style scoped>
.toolbar { display: flex; align-items: center; gap: 12px; margin-bottom: 8px; }
h1 { font-size: 1.3rem; margin: 0; }
.count { font-size: 0.8rem; color: var(--muted); background: #f1f5f9; padding: 3px 10px; border-radius: 999px; }
.hint { color: var(--muted); font-size: 0.88rem; margin-bottom: 18px; max-width: 640px; }
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
.mono { font-family: 'SFMono-Regular', Consolas, monospace; font-size: 0.9rem; }
.objet { max-width: 260px; }
.muted { color: var(--muted); }
.error { color: #dc2626; }
</style>
