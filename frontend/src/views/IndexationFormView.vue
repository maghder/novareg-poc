<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { readItem, updateItem, createItem } from '@directus/sdk'
import { directus } from '../lib/directus'
import { formatDateTime } from '../lib/labels'

const props = defineProps({ id: { type: String, required: true } })
const router = useRouter()

const courrier = ref(null)
const loading = ref(true)
const saving = ref(false)
const error = ref(null)

const form = ref({
  objet: '',
  expediteur_libelle: '',
  destinataire_libelle: "NOVAREG - Bureau d'Ordre",
  reference_externe: '',
  date_document: '',
  priorite_code: 'normale',
  confidentialite_code: 'interne'
})

const PRIORITES = ['basse', 'normale', 'haute', 'urgente']
const CONFIDENTIALITES = ['public', 'interne', 'restreint', 'confidentiel', 'secret']

async function charger() {
  loading.value = true
  error.value = null
  try {
    courrier.value = await directus.request(
      readItem('bo_courriers', props.id, {
        fields: ['id', 'numero_chrono', 'canal_code', 'date_enregistrement', 'numero_suivi_reception', 'statut_code']
      })
    )
    if (courrier.value.statut_code !== 'recu') {
      error.value = `Ce courrier n'est plus en attente d'indexation (statut actuel : ${courrier.value.statut_code}).`
    }
  } catch (e) {
    error.value = "Impossible de charger ce courrier. Vérifiez le lien ou les droits de lecture sur bo_courriers."
    console.error(e)
  } finally {
    loading.value = false
  }
}

async function validerIndexation() {
  if (!form.value.objet.trim()) {
    error.value = "L'objet est obligatoire pour valider l'indexation."
    return
  }
  if (!form.value.expediteur_libelle.trim()) {
    error.value = "L'expéditeur est obligatoire."
    return
  }

  saving.value = true
  error.value = null
  try {
    await directus.request(
      updateItem('bo_courriers', props.id, {
        objet: form.value.objet.trim(),
        reference_externe: form.value.reference_externe.trim() || null,
        date_document: form.value.date_document || null,
        priorite_code: form.value.priorite_code,
        confidentialite_code: form.value.confidentialite_code,
        statut_code: 'enregistre'
      })
    )

    await directus.request(
      createItem('bo_courrier_parties', {
        courrier_id: props.id,
        role_code: 'expediteur',
        libelle_snapshot: form.value.expediteur_libelle.trim(),
        ordre: 1
      })
    )
    await directus.request(
      createItem('bo_courrier_parties', {
        courrier_id: props.id,
        role_code: 'destinataire',
        libelle_snapshot: form.value.destinataire_libelle.trim(),
        ordre: 1
      })
    )

    router.push(`/courriers/${props.id}`)
  } catch (e) {
    error.value = "Échec de la validation. Vérifiez les droits d'écriture sur bo_courriers et bo_courrier_parties."
    console.error(e)
    saving.value = false
  }
}

onMounted(charger)
</script>

<template>
  <section v-if="loading" class="hint">Chargement…</section>

  <section v-else-if="courrier" class="form-page">
    <RouterLink to="/indexation" class="back">← Retour à la file d'indexation</RouterLink>

    <h1>Indexation — {{ courrier.numero_chrono }}</h1>
    <p class="muted">
      Reçu le {{ formatDateTime(courrier.date_enregistrement) }} · canal {{ courrier.canal_code }}
      <span v-if="courrier.numero_suivi_reception"> · suivi {{ courrier.numero_suivi_reception }}</span>
    </p>

    <form v-if="courrier.statut_code === 'recu'" @submit.prevent="validerIndexation" class="form">
      <label class="field">
        Objet du courrier
        <input v-model="form.objet" required placeholder="Ex. Demande de mise à jour d'adresse du siège social" />
      </label>

      <div class="row">
        <label class="field">
          Expéditeur
          <input v-model="form.expediteur_libelle" required placeholder="Nom de l'expéditeur" />
        </label>
        <label class="field">
          Destinataire
          <input v-model="form.destinataire_libelle" required />
        </label>
      </div>

      <div class="row">
        <label class="field">
          Référence externe
          <input v-model="form.reference_externe" placeholder="Optionnel" />
        </label>
        <label class="field">
          Date du document
          <input v-model="form.date_document" type="date" />
        </label>
      </div>

      <div class="row">
        <label class="field">
          Priorité
          <select v-model="form.priorite_code">
            <option v-for="p in PRIORITES" :key="p" :value="p">{{ p }}</option>
          </select>
        </label>
        <label class="field">
          Confidentialité
          <select v-model="form.confidentialite_code">
            <option v-for="c in CONFIDENTIALITES" :key="c" :value="c">{{ c }}</option>
          </select>
        </label>
      </div>

      <p v-if="error" class="error">{{ error }}</p>

      <button type="submit" class="cta" :disabled="saving">
        {{ saving ? 'Validation…' : "Valider l'indexation" }}
      </button>
    </form>

    <p v-else class="error">{{ error }}</p>
  </section>
</template>

<style scoped>
.back { color: var(--muted); text-decoration: none; font-size: 0.85rem; }
h1 { font-size: 1.3rem; margin: 10px 0 4px; }
.muted { color: var(--muted); font-size: 0.88rem; margin-bottom: 20px; }
.form {
  background: white;
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 22px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  max-width: 640px;
}
.row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.field { display: flex; flex-direction: column; gap: 5px; font-size: 0.82rem; color: var(--muted); font-weight: 600; }
.field input, .field select {
  font: inherit;
  padding: 8px 10px;
  border: 1px solid var(--border);
  border-radius: 7px;
  color: var(--text);
  background: white;
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
