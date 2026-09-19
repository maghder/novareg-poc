<script setup>
import { onMounted, ref } from 'vue'
import { readItems } from '@directus/sdk'
import { directus } from '../lib/directus'
import { formatDateTime } from '../lib/labels'

const courriers = ref([])
const loading = ref(true)
const error = ref(null)

async function charger() {
  loading.value = true
  error.value = null
  try {
    courriers.value = await directus.request(
      readItems('bo_courriers', {
        filter: { statut_code: { _eq: 'recu' } },
        fields: ['id', 'numero_chrono', 'canal_code', 'date_enregistrement', 'numero_suivi_reception'],
        sort: ['date_enregistrement'],
        limit: 100
      })
    )
  } catch (e) {
    error.value =
      "Impossible de charger la file d'indexation. Vérifiez que le statut 'recu' existe " +
      "(db/05_evolution_reception.sql) et que le jeton a les droits de lecture sur bo_courriers."
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
      <h1>File d'indexation</h1>
      <span class="count" v-if="!loading">{{ courriers.length }} en attente</span>
    </div>
    <p class="hint">
      Retrouvez le courrier physique grâce au numéro ci-dessous (celui de l'étiquette collée
      à la réception), scannez-le, puis cliquez la ligne pour compléter l'indexation.
    </p>

    <p v-if="loading" class="hint">Chargement…</p>
    <p v-else-if="error" class="error">{{ error }}</p>
    <p v-else-if="!courriers.length" class="hint">Aucun courrier en attente d'indexation.</p>

    <table v-else class="table">
      <thead>
        <tr>
          <th>N° chrono (étiquette)</th>
          <th>Canal</th>
          <th>Reçu le</th>
          <th>N° de suivi</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="c in courriers"
          :key="c.id"
          class="row-link"
          @click="$router.push(`/indexation/${c.id}`)"
        >
          <td class="mono">{{ c.numero_chrono }}</td>
          <td class="muted">{{ c.canal_code }}</td>
          <td>{{ formatDateTime(c.date_enregistrement) }}</td>
          <td class="mono muted">{{ c.numero_suivi_reception || '—' }}</td>
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
.muted { color: var(--muted); }
.error { color: #dc2626; }
</style>
