<script setup>
import { onMounted, ref } from 'vue'
import { readItems } from '@directus/sdk'
import { directus } from '../lib/directus'
import StatusBadge from '../components/StatusBadge.vue'
import { PRIORITES, labelFor, colorFor, formatDateTime } from '../lib/labels'

const courriers = ref([])
const loading = ref(true)
const error = ref(null)

async function charger() {
  loading.value = true
  error.value = null
  try {
    const bruts = await directus.request(
      readItems('bo_courriers', {
        filter: { statut_code: { _eq: 'enregistre' } },
        fields: [
          'id',
          'numero_chrono',
          'objet',
          'date_enregistrement',
          'priorite_code',
          'parties.role_code',
          'parties.libelle_snapshot'
        ],
        sort: ['date_enregistrement'],
        limit: 100
      })
    )
    courriers.value = bruts.map((c) => ({
      id: c.id,
      numero_chrono: c.numero_chrono,
      objet: c.objet,
      date_enregistrement: c.date_enregistrement,
      priorite_code: c.priorite_code,
      expediteur: c.parties?.find((p) => p.role_code === 'expediteur')?.libelle_snapshot ?? null
    }))
  } catch (e) {
    error.value =
      "Impossible de charger la file d'affectation. Vérifiez les droits de lecture sur " +
      "bo_courriers et bo_courrier_parties."
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
      <h1>File d'affectation</h1>
      <span class="count" v-if="!loading">{{ courriers.length }} en attente</span>
    </div>
    <p class="hint">Courriers indexés, à orienter vers l'unité en charge.</p>

    <p v-if="loading" class="hint">Chargement…</p>
    <p v-else-if="error" class="error">{{ error }}</p>
    <p v-else-if="!courriers.length" class="hint">Aucun courrier en attente d'affectation.</p>

    <table v-else class="table">
      <thead>
        <tr>
          <th>N° chrono</th>
          <th>Objet</th>
          <th>Expéditeur</th>
          <th>Enregistré le</th>
          <th>Priorité</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="c in courriers"
          :key="c.id"
          class="row-link"
          @click="$router.push(`/affectation/${c.id}`)"
        >
          <td class="mono">{{ c.numero_chrono }}</td>
          <td class="objet">{{ c.objet }}</td>
          <td class="muted">{{ c.expediteur || '—' }}</td>
          <td>{{ formatDateTime(c.date_enregistrement) }}</td>
          <td>
            <StatusBadge :label="labelFor(PRIORITES, c.priorite_code)" :color="colorFor(PRIORITES, c.priorite_code)" />
          </td>
        </tr>
      </tbody>
    </table>
  </section>
</template>

<style scoped>
.toolbar { display: flex; align-items: center; gap: 12px; margin-bottom: 8px; }
h1 { font-size: 1.3rem; margin: 0; }
.count { font-size: 0.8rem; color: var(--muted); background: #f1f5f9; padding: 3px 10px; border-radius: 999px; }
.hint { color: var(--muted); font-size: 0.88rem; margin-bottom: 18px; }
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
.objet { max-width: 320px; }
.muted { color: var(--muted); }
.error { color: #dc2626; }
</style>
