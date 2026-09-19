<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { readItem, updateItem, createItem } from '@directus/sdk'
import { directus } from '../lib/directus'
import { formatDateTime } from '../lib/labels'

const props = defineProps({ id: { type: String, required: true } })
const router = useRouter()

const tentative = ref(null)
const loading = ref(true)
const saving = ref(false)
const error = ref(null)

const issue = ref(null) // 'ar' | 'retour'

const ar = ref({
  date_reception_ar: new Date().toISOString().slice(0, 10),
  reference_ar: '',
  nom_recepteur: '',
  qualite_recepteur: ''
})
const retour = ref({
  date_retour: new Date().toISOString().slice(0, 10),
  motif_retour: ''
})

async function charger() {
  loading.value = true
  error.value = null
  try {
    tentative.value = await directus.request(
      readItem('bo_expedition_tentatives', props.id, {
        fields: [
          'id',
          'numero_suivi',
          'date_expedition',
          'statut_code',
          'expedition_id.id',
          'expedition_id.mode_expedition_code',
          'expedition_id.courrier_id.id',
          'expedition_id.courrier_id.numero_chrono',
          'expedition_id.courrier_id.objet',
          'expedition_id.destinataire_partie_id.libelle_snapshot'
        ]
      })
    )
    ar.value.reference_ar = tentative.value.numero_suivi || ''
    if (tentative.value.statut_code !== 'expedie') {
      error.value = `Cette tentative n'est plus en attente (statut actuel : ${tentative.value.statut_code}).`
    }
  } catch (e) {
    error.value = 'Impossible de charger cette tentative. Vérifiez les droits de lecture.'
    console.error(e)
  } finally {
    loading.value = false
  }
}

async function enregistrerAR() {
  saving.value = true
  error.value = null
  try {
    await directus.request(
      createItem('bo_accuses_reception', {
        tentative_id: props.id,
        statut_ar_code: 'recu',
        date_reception_ar: ar.value.date_reception_ar,
        reference_ar: ar.value.reference_ar.trim() || null,
        nom_recepteur: ar.value.nom_recepteur.trim() || null,
        qualite_recepteur: ar.value.qualite_recepteur.trim() || null
      })
    )
    await directus.request(
      updateItem('bo_expedition_tentatives', props.id, {
        date_distribution: ar.value.date_reception_ar,
        statut_code: 'distribue'
      })
    )
    await directus.request(
      updateItem('bo_expeditions', tentative.value.expedition_id.id, { statut_code: 'distribue' })
    )
    await directus.request(
      updateItem('bo_courriers', tentative.value.expedition_id.courrier_id.id, { statut_code: 'cloture' })
    )
    router.push(`/courriers/${tentative.value.expedition_id.courrier_id.id}`)
  } catch (e) {
    error.value = "Échec de l'enregistrement de l'AR. Vérifiez les droits d'écriture sur bo_accuses_reception."
    console.error(e)
    saving.value = false
  }
}

async function enregistrerRetour() {
  if (!retour.value.motif_retour.trim()) {
    error.value = 'Le motif de retour est obligatoire.'
    return
  }
  saving.value = true
  error.value = null
  try {
    await directus.request(
      updateItem('bo_expedition_tentatives', props.id, {
        date_retour: retour.value.date_retour,
        motif_retour: retour.value.motif_retour.trim(),
        statut_code: 'retourne'
      })
    )
    await directus.request(
      updateItem('bo_expeditions', tentative.value.expedition_id.id, { statut_code: 'retourne' })
    )
    router.push(`/courriers/${tentative.value.expedition_id.courrier_id.id}`)
  } catch (e) {
    error.value = "Échec de l'enregistrement du retour. Vérifiez les droits d'écriture sur bo_expedition_tentatives."
    console.error(e)
    saving.value = false
  }
}

onMounted(charger)
</script>

<template>
  <section v-if="loading" class="hint">Chargement…</section>

  <section v-else-if="tentative" class="form-page">
    <RouterLink to="/accuses-reception" class="back">← Retour à la file des AR</RouterLink>

    <p class="mono muted">{{ tentative.expedition_id?.courrier_id?.numero_chrono }}</p>
    <h1>{{ tentative.expedition_id?.courrier_id?.objet }}</h1>
    <p class="muted">
      Destinataire : {{ tentative.expedition_id?.destinataire_partie_id?.libelle_snapshot || '—' }}
      · Envoyé le {{ formatDateTime(tentative.date_expedition) }}
      · Mode : {{ tentative.expedition_id?.mode_expedition_code }}
    </p>

    <template v-if="tentative.statut_code === 'expedie'">
      <div class="choice-grid">
        <button type="button" class="choice-card" :class="{ active: issue === 'ar' }" @click="issue = 'ar'">
          <strong>Accusé de réception reçu</strong>
          <span class="muted">Le destinataire a signé / accusé réception</span>
        </button>
        <button type="button" class="choice-card retour" :class="{ active: issue === 'retour' }" @click="issue = 'retour'">
          <strong>Retourné, non distribué</strong>
          <span class="muted">L'envoi est revenu sans avoir été remis</span>
        </button>
      </div>

      <form v-if="issue === 'ar'" @submit.prevent="enregistrerAR" class="form">
        <div class="row">
          <label class="field">
            Date de réception de l'AR
            <input v-model="ar.date_reception_ar" type="date" required />
          </label>
          <label class="field">
            Référence AR
            <input v-model="ar.reference_ar" placeholder="Numéro figurant sur l'AR retourné" />
          </label>
        </div>
        <div class="row">
          <label class="field">
            Nom du récepteur
            <input v-model="ar.nom_recepteur" placeholder="Personne ayant signé" />
          </label>
          <label class="field">
            Qualité du récepteur
            <input v-model="ar.qualite_recepteur" placeholder="Ex. Agent d'accueil" />
          </label>
        </div>
        <p v-if="error" class="error">{{ error }}</p>
        <button type="submit" class="cta" :disabled="saving">
          {{ saving ? 'Enregistrement…' : "Enregistrer l'AR et clôturer" }}
        </button>
      </form>

      <form v-if="issue === 'retour'" @submit.prevent="enregistrerRetour" class="form">
        <label class="field">
          Date de retour
          <input v-model="retour.date_retour" type="date" required />
        </label>
        <label class="field">
          Motif de retour
          <textarea v-model="retour.motif_retour" rows="3" required placeholder="Ex. Destinataire inconnu à l'adresse indiquée"></textarea>
        </label>
        <p v-if="error" class="error">{{ error }}</p>
        <button type="submit" class="cta retour" :disabled="saving">
          {{ saving ? 'Enregistrement…' : 'Marquer comme retourné' }}
        </button>
      </form>
    </template>

    <p v-else class="error">{{ error }}</p>
  </section>
</template>

<style scoped>
.back { color: var(--muted); text-decoration: none; font-size: 0.85rem; }
.mono { font-family: 'SFMono-Regular', Consolas, monospace; }
h1 { font-size: 1.3rem; margin: 2px 0 4px; }
.muted { color: var(--muted); font-size: 0.88rem; }

.choice-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; max-width: 560px; margin: 20px 0; }
.choice-card {
  display: flex;
  flex-direction: column;
  gap: 4px;
  text-align: left;
  background: white;
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 14px 16px;
  cursor: pointer;
  font: inherit;
}
.choice-card:hover { border-color: #94a3b8; }
.choice-card.active { border-color: #16a34a; box-shadow: 0 0 0 1px #16a34a; }
.choice-card.retour.active { border-color: #dc2626; box-shadow: 0 0 0 1px #dc2626; }

.form {
  background: white;
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 22px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  max-width: 560px;
}
.row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.field { display: flex; flex-direction: column; gap: 5px; font-size: 0.82rem; color: var(--muted); font-weight: 600; }
.field input, .field textarea {
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
  background: #16a34a;
  color: white;
  border: none;
  padding: 10px 18px;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
}
.cta.retour { background: #dc2626; }
.cta:disabled { opacity: 0.6; cursor: default; }
.error { color: #dc2626; font-size: 0.85rem; }
.hint { color: var(--muted); }
</style>
