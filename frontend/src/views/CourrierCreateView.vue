<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { createItem } from '@directus/sdk'
import { directus } from '../lib/directus'

const router = useRouter()
const saving = ref(false)
const error = ref(null)

const form = reactive({
  sens: 'arrivee',
  objet: '',
  reference_externe: '',
  date_document: '',
  canal_code: 'courrier_postal',
  support_code: 'papier',
  priorite_code: 'normale',
  confidentialite_code: 'interne',
  expediteur_libelle: '',
  destinataire_libelle: "NOVAREG - Bureau d'Ordre",
  commentaire_bo: ''
})

// Reflète db/02_novareg_seed.sql — voir la note dans lib/labels.js
const CANAUX = ['guichet', 'courrier_postal', 'email', 'portail_en_ligne', 'fax', 'remise_main_propre']
const SUPPORTS = ['papier', 'electronique', 'mixte']
const PRIORITES = ['basse', 'normale', 'haute', 'urgente']
const CONFIDENTIALITES = ['public', 'interne', 'restreint', 'confidentiel', 'secret']

function genererNumeroChrono(sens) {
  const prefix = sens === 'arrivee' ? 'BO' : 'BO'
  const now = new Date()
  const rand = Math.floor(Math.random() * 900000 + 100000)
  return `${prefix}-${now.getFullYear()}-${rand}`
}

async function enregistrer() {
  saving.value = true
  error.value = null
  try {
    const numero_chrono = genererNumeroChrono(form.sens)

    const courrier = await directus.request(
      createItem('bo_courriers', {
        numero_chrono,
        sens: form.sens,
        objet: form.objet,
        reference_externe: form.reference_externe || null,
        date_document: form.date_document || null,
        canal_code: form.canal_code,
        support_code: form.support_code,
        priorite_code: form.priorite_code,
        confidentialite_code: form.confidentialite_code,
        statut_code: 'enregistre',
        langue_code: 'fr',
        commentaire_bo: form.commentaire_bo || null
      })
    )

    await directus.request(
      createItem('bo_courrier_parties', {
        courrier_id: courrier.id,
        role_code: 'expediteur',
        libelle_snapshot: form.expediteur_libelle,
        ordre: 1
      })
    )
    await directus.request(
      createItem('bo_courrier_parties', {
        courrier_id: courrier.id,
        role_code: 'destinataire',
        libelle_snapshot: form.destinataire_libelle,
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
          Expéditeur
          <input v-model="form.expediteur_libelle" required placeholder="Nom de l'expéditeur" />
        </label>
        <label>
          Destinataire
          <input v-model="form.destinataire_libelle" required />
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
        <label>
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
