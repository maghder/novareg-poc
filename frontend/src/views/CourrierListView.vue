<script setup>
import { onMounted, ref, computed } from 'vue'
import { readItems } from '@directus/sdk'
import { directus } from '../lib/directus'
import StatusBadge from '../components/StatusBadge.vue'
import {
  STATUTS_COURRIER,
  SENS_COURRIER,
  PRIORITES,
  labelFor,
  colorFor,
  formatDate
} from '../lib/labels'

const courriers = ref([])
const loading = ref(true)
const error = ref(null)
const filtreSens = ref('tous')

async function chargerCourriers() {
  loading.value = true
  error.value = null
  try {
    courriers.value = await directus.request(
      readItems('vw_bo_courriers_suivi', {
        fields: [
          'id',
          'numero_chrono',
          'sens',
          'date_enregistrement',
          'objet',
          'statut_code',
          'priorite_code',
          'expediteur',
          'destinataire',
          'statut_orientation'
        ],
        sort: ['-date_enregistrement'],
        limit: 100
      })
    )
  } catch (e) {
    error.value =
      "Impossible de charger les courriers. Vérifiez que vw_bo_courriers_suivi est " +
      "bien adoptée comme collection dans Directus et que le jeton a les droits de lecture."
    console.error(e)
  } finally {
    loading.value = false
  }
}

const courriersFiltres = computed(() => {
  if (filtreSens.value === 'tous') return courriers.value
  return courriers.value.filter((c) => c.sens === filtreSens.value)
})

onMounted(chargerCourriers)
</script>

<template>
  <section>
    <div class="toolbar">
      <h1>Courriers</h1>
      <div class="filters">
        <button
          v-for="opt in [
            { value: 'tous', label: 'Tous' },
            { value: 'arrivee', label: 'Arrivée' },
            { value: 'depart', label: 'Départ' }
          ]"
          :key="opt.value"
          :class="{ active: filtreSens === opt.value }"
          @click="filtreSens = opt.value"
        >
          {{ opt.label }}
        </button>
      </div>
    </div>

    <p v-if="loading" class="hint">Chargement…</p>
    <p v-else-if="error" class="error">{{ error }}</p>
    <p v-else-if="!courriersFiltres.length" class="hint">Aucun courrier à afficher.</p>

    <table v-else class="table">
      <thead>
        <tr>
          <th>N° chrono</th>
          <th>Sens</th>
          <th>Date</th>
          <th>Objet</th>
          <th>Expéditeur → Destinataire</th>
          <th>Priorité</th>
          <th>Statut</th>
          <th>Orientation</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="c in courriersFiltres"
          :key="c.id"
          class="row-link"
          @click="$router.push(`/courriers/${c.id}`)"
        >
          <td class="mono">{{ c.numero_chrono }}</td>
          <td>
            <StatusBadge :label="labelFor(SENS_COURRIER, c.sens)" :color="colorFor(SENS_COURRIER, c.sens)" />
          </td>
          <td>{{ formatDate(c.date_enregistrement) }}</td>
          <td class="objet">{{ c.objet }}</td>
          <td class="parties">{{ c.expediteur || '—' }} → {{ c.destinataire || '—' }}</td>
          <td>
            <StatusBadge :label="labelFor(PRIORITES, c.priorite_code)" :color="colorFor(PRIORITES, c.priorite_code)" />
          </td>
          <td>
            <StatusBadge :label="labelFor(STATUTS_COURRIER, c.statut_code)" :color="colorFor(STATUTS_COURRIER, c.statut_code)" />
          </td>
          <td class="muted">{{ c.statut_orientation || '—' }}</td>
        </tr>
      </tbody>
    </table>
  </section>
</template>

<style scoped>
.toolbar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; }
h1 { font-size: 1.3rem; margin: 0; }
.filters { display: flex; gap: 6px; }
.filters button {
  border: 1px solid var(--border);
  background: white;
  padding: 6px 12px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.85rem;
  color: var(--muted);
}
.filters button.active { background: #0f172a; color: white; border-color: #0f172a; }
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
.parties { color: var(--muted); }
.muted { color: var(--muted); }
.hint { color: var(--muted); }
.error { color: #dc2626; }
</style>
