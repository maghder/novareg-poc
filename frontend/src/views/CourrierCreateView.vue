<script setup>
import { reactive, ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { createItem } from '@directus/sdk'
import { directus } from '../lib/directus'

const router = useRouter()
const saving = ref(false)
const error = ref(null)

// Libellé de la partie interne, auto-affecté selon le sens — jamais saisi
// à la main : pour une arrivée, le courrier est destiné au Bureau d'Ordre
// en attente d'affectation ; pour un départ, il est initié par le Bureau
// d'Ordre (ou l'unité) avant expédition.
const PARTIE_INTERNE = {
  arrivee: "Affectation (Bureau d'Ordre)",
  depart: "Initiation (Bureau d'Ordre)"
}

const form = reactive({
  sens: 'arrivee',
  objet: '',
  reference_externe: '',
  date_document: '',
  canal_code: 'courrier_postal',
  support_code: 'papier',
  priorite_code: 'normale',
  confidentialite_code: 'interne',
  commentaire_bo: ''
})

// Seule la partie externe se saisit ; la partie interne est déduite du sens.
const partieExterne = ref('')

const estArrivee = computed(() => form.sens === 'arrivee')
const partieInterne = computed(() => PARTIE_INTERNE[form.sens])
const labelPartieExterne = computed(() => (estArrivee.value ? 'Expéditeur' : 'Destinataire'))
const labelPartieInterne = computed(() => (estArrivee.value ? 'Destinataire' : 'Expéditeur'))

// Changer de sens vide le champ externe : le contexte change complètement
// (un expéditeur arrivée n'a aucune raison d'être pré-rempli comme
// destinataire départ, par exemple).
watch(
  () => form.sens,
  () => {
    partieExterne.value = ''
  }
)

// Reflète db/02_novareg_seed.sql — voir la note dans lib/labels.js
const CANAUX = ['guichet', 'courrier_postal', 'email', 'portail_en_ligne', 'fax', 'remise_main_propre', 'recommande']
const SUPPORTS = ['papier', 'electronique', 'mixte']
const PRIORITES = ['basse', 'normale', 'haute', 'urgente']
const CONFIDENTIALITES = ['public', 'interne', 'restreint', 'confidentiel', 'secret']

function genererNumeroChrono() {
  const now = new Date()
  const rand = Math.floor(Math.random() * 900000 + 100000)
  return `BO-${now.getFullYear()}-${rand}`
}

async function enregistrer() {
  if (!partieExterne.value.trim()) {
    error.value = `Le champ « ${labelPartieExterne.value} » est obligatoire.`
    return
  }
  saving.value = true
  error.value = null
  try {
    const numero_chrono = genererNumeroChrono()

    const courrier = await directus.request(
      createItem('bo_courriers', {
        numero_chrono,
        sens: form.sens,
        objet: form.objet,
        reference_externe: form.reference_externe || null,
        date_document: form.date_document || null,
        // Le canal (comment le courrier est arrivé) n'a de sens que pour une
        // arrivée. Pour un départ, le mode d'envoi se choisit plus tard, à
        // l'étape d'expédition — on met une valeur neutre, non affichée.
        canal_code: estArrivee.value ? form.canal_code : 'courrier_postal',
        support_code: form.support_code,
        priorite_code: form.priorite_code,
        confidentialite_code: form.confidentialite_code,
        statut_code: 'enregistre',
        langue_code: 'fr',
        commentaire_bo: form.commentaire_bo || null
      })
    )

    const expediteur_libelle = estArrivee.value ? partieExterne.value.trim() : partieInterne.value
    const destinataire_libelle = estArrivee.value ? partieInterne.value : partieExterne.value.trim()

    await directus.request(
      createItem('bo_courrier_parties', {
        courrier_id: courrier.id,
        role_code: 'expediteur',
        libelle_snapshot: expediteur_libelle,
        ordre: 1
      })
    )
    await directus.request(
      createItem('bo_courrier_parties', {
        courrier_id: courrier.id,
        role_code: 'destinataire',
        libelle_snapshot: destinataire_libelle,
        ordre: 1
      })
    )

    router.push(`/courriers/${courrier.id}`)
  } catch (e) {
    error.value =
      "Échec de l'enregistrement. Vérifiez que le jeton du frontend a bien les " +
      "droits d'écriture sur bo_courriers et bo_courrier_parties (docs/SETUP.md §8)."
    console.error(e)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <section class="form-page">
    <RouterLink to="/" class="back">← Retour à la liste</RouterLink>
    <h1>Enregistrer un courrier</h1>

    <form @submit.prevent="enregistrer" class="form">
      <div class="row">
        <label>
          Sens
          <select v-model="form.sens">
            <option value="arrivee">Arrivée</option>
            <option value="depart">Départ</option>
          </select>
        </label>
        <label>
          Priorité
          <select v-model="form.priorite_code">
            <option v-for="p in PRIORITES" :key="p" :value="p">{{ p }}</option>
          </select>
        </label>
      </div>

      <label>
        Objet
        <input v-model="form.objet" required maxlength="500" placeholder="Objet du courrier" />
      </label>

      <div class="row">
        <label>
          {{ labelPartieExterne }}
          <input v-model="partieExterne" required :placeholder="`Nom du ${labelPartieExterne.toLowerCase()}`" />
        </label>
        <label>
          {{ labelPartieInterne }}
          <input :value="partieInterne" disabled />
        </label>
      </div>

      <div class="row">
        <label>
          Référence externe
          <input v-model="form.reference_externe" placeholder="Optionnel" />
        </label>
        <label>
          Date du document
          <input v-model="form.date_document" type="date" />
        </label>
      </div>

      <div class="row three">
        <label v-if="estArrivee">
          Canal
          <select v-model="form.canal_code">
            <option v-for="c in CANAUX" :key="c" :value="c">{{ c }}</option>
          </select>
        </label>
        <label>
          Support
          <select v-model="form.support_code">
            <option v-for="s in SUPPORTS" :key="s" :value="s">{{ s }}</option>
          </select>
        </label>
        <label>
          Confidentialité
          <select v-model="form.confidentialite_code">
            <option v-for="c in CONFIDENTIALITES" :key="c" :value="c">{{ c }}</option>
          </select>
        </label>
      </div>

      <label>
        Commentaire Bureau d'Ordre
        <textarea v-model="form.commentaire_bo" rows="3" placeholder="Optionnel"></textarea>
      </label>

      <p v-if="error" class="error">{{ error }}</p>

      <button type="submit" :disabled="saving">
        {{ saving ? 'Enregistrement…' : 'Enregistrer le courrier' }}
      </button>
    </form>
  </section>
</template>

<style scoped>
.back { color: var(--muted); text-decoration: none; font-size: 0.85rem; }
h1 { font-size: 1.3rem; margin: 8px 0 18px; }
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
.row.three { grid-template-columns: 1fr 1fr 1fr; }
label { display: flex; flex-direction: column; gap: 5px; font-size: 0.82rem; color: var(--muted); font-weight: 600; }
input, select, textarea {
  font: inherit;
  padding: 8px 10px;
  border: 1px solid var(--border);
  border-radius: 7px;
  color: var(--text);
  background: white;
}
input:disabled { background: #f1f5f9; color: var(--muted); }
button {
  align-self: flex-start;
  background: #0f172a;
  color: white;
  border: none;
  padding: 10px 18px;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
}
button:disabled { opacity: 0.6; cursor: default; }
.error { color: #dc2626; font-size: 0.85rem; }
</style>
