<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { readItem, readItems, updateItem, createItem } from '@directus/sdk'
import { directus } from '../lib/directus'
import StatusBadge from '../components/StatusBadge.vue'
import { PRIORITES, labelFor, colorFor, formatDateTime } from '../lib/labels'

// Unité Bureau d'Ordre — voir db/03_bo_demo_data.sql (org_unites, code BO).
const UNITE_BO_ID = 'aaaaaaaa-0000-0000-0000-000000000005'

const props = defineProps({ id: { type: String, required: true } })
const router = useRouter()

const courrier = ref(null)
const unites = ref([])
const loading = ref(true)
const saving = ref(false)
const error = ref(null)

const uniteDestinationId = ref('')
const motif = ref('')

async function charger() {
  loading.value = true
  error.value = null
  try {
    const [c, u] = await Promise.all([
      directus.request(
        readItem('bo_courriers', props.id, {
          fields: [
            'id',
            'numero_chrono',
            'objet',
            'statut_code',
            'priorite_code',
            'parties.role_code',
            'parties.libelle_snapshot'
          ]
        })
      ),
      directus.request(
        readItems('org_unites', {
          filter: { code_unite: { _neq: 'BO' } },
          fields: ['id', 'libelle', 'code_unite'],
          sort: ['libelle'],
          limit: 100
        })
      )
    ])
    courrier.value = {
      ...c,
      expediteur: c.parties?.find((p) => p.role_code === 'expediteur')?.libelle_snapshot ?? null
    }
    unites.value = u
    if (c.statut_code !== 'enregistre') {
      error.value = `Ce courrier n'est plus en attente d'affectation (statut actuel : ${c.statut_code}).`
    }
  } catch (e) {
    error.value = "Impossible de charger ce courrier ou la liste des unités. Vérifiez les droits de lecture."
    console.error(e)
  } finally {
    loading.value = false
  }
}

async function orienter() {
  if (!uniteDestinationId.value) {
    error.value = 'Choisissez une unité destinataire.'
    return
  }
  saving.value = true
  error.value = null
  try {
    await directus.request(
      createItem('bo_orientations', {
        courrier_id: props.id,
        unite_source_id: UNITE_BO_ID,
        unite_destination_id: uniteDestinationId.value,
        date_transmission: new Date().toISOString(),
        statut: 'transmis',
        motif: motif.value.trim() || null
      })
    )
    await directus.request(
      updateItem('bo_courriers', props.id, { statut_code: 'oriente' })
    )
    router.push(`/courriers/${props.id}`)
  } catch (e) {
    error.value = "Échec de l'orientation. Vérifiez les droits d'écriture sur bo_orientations et bo_courriers."
    console.error(e)
    saving.value = false
  }
}

onMounted(charger)
</script>

<template>
  <section v-if="loading" class="hint">Chargement…</section>

  <section v-else-if="courrier" class="form-page">
    <RouterLink to="/affectation" class="back">← Retour à la file d'affectation</RouterLink>

    <div class="detail-header">
      <div>
        <p class="mono muted">{{ courrier.numero_chrono }}</p>
        <h1>{{ courrier.objet }}</h1>
      </div>
      <StatusBadge :label="labelFor(PRIORITES, courrier.priorite_code)" :color="colorFor(PRIORITES, courrier.priorite_code)" />
    </div>
    <p class="muted">Expéditeur : {{ courrier.expediteur || '—' }}</p>

    <form v-if="courrier.statut_code === 'enregistre'" @submit.prevent="orienter" class="form">
      <label class="field">
        Unité destinataire
        <select v-model="uniteDestinationId" required>
          <option value="" disabled>Choisir une unité…</option>
          <option v-for="u in unites" :key="u.id" :value="u.id">{{ u.libelle }}</option>
        </select>
      </label>

      <label class="field">
        Motif / instruction (optionnel)
        <textarea v-model="motif" rows="3" placeholder="Ex. Instruction changement d'adresse réglementaire"></textarea>
      </label>

      <p v-if="error" class="error">{{ error }}</p>

      <button type="submit" class="cta" :disabled="saving">
        {{ saving ? 'Orientation…' : 'Orienter le courrier' }}
      </button>
    </form>

    <p v-else class="error">{{ error }}</p>
  </section>
</template>

<style scoped>
.back { color: var(--muted); text-decoration: none; font-size: 0.85rem; }
.detail-header { display: flex; align-items: flex-start; justify-content: space-between; margin: 10px 0 4px; gap: 16px; }
h1 { margin: 2px 0 0; font-size: 1.3rem; }
.mono { font-family: 'SFMono-Regular', Consolas, monospace; }
.muted { color: var(--muted); font-size: 0.88rem; margin-bottom: 20px; }
.form {
  background: white;
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 22px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  max-width: 480px;
}
.field { display: flex; flex-direction: column; gap: 5px; font-size: 0.82rem; color: var(--muted); font-weight: 600; }
.field select, .field textarea {
  font: inherit;
  padding: 8px 10px;
  border: 1px solid var(--border);
  border-radius: 7px;
  color: var(--text);
  background: white;
  resize: vertical;
}
.cta {
  align-self: flex-start;
  background: #0f172a;
  color: white;
  border: none;
  padding: 10px 18px;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
}
.cta:disabled { opacity: 0.6; cursor: default; }
.error { color: #dc2626; font-size: 0.85rem; }
.hint { color: var(--muted); }
</style>
