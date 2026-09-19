<script setup>
import { ref, computed, nextTick } from 'vue'
import { createItem } from '@directus/sdk'
import { directus } from '../lib/directus'
import { formatDateTime } from '../lib/labels'
import JsBarcode from 'jsbarcode'

// Unité Bureau d'Ordre — voir db/03_bo_demo_data.sql (org_unites, code BO).
const UNITE_BO_ID = 'aaaaaaaa-0000-0000-0000-000000000005'

const TYPES_DEPOT = [
  {
    value: 'main',
    label: 'À main',
    description: 'Dépôt en personne au guichet',
    canal: 'remise_main_propre',
    nbEtiquettes: 2
  },
  {
    value: 'poste_normale',
    label: 'Poste normale',
    description: 'Courrier postal sans suivi',
    canal: 'courrier_postal',
    nbEtiquettes: 1
  },
  {
    value: 'recommande',
    label: 'Recommandé',
    description: 'Courrier postal avec numéro de suivi',
    canal: 'recommande',
    nbEtiquettes: 1
  }
]

const typeDepot = ref(null)
const numeroSuiviReception = ref('')
const saving = ref(false)
const error = ref(null)
const courrierCree = ref(null)

const typeDepotChoisi = computed(() => TYPES_DEPOT.find((t) => t.value === typeDepot.value) ?? null)

function genererNumeroChrono() {
  const now = new Date()
  const rand = Math.floor(Math.random() * 900000 + 100000)
  return `BO-${now.getFullYear()}-${rand}`
}

async function enregistrerReception() {
  if (!typeDepot.value) {
    error.value = 'Choisissez un type de dépôt avant de continuer.'
    return
  }
  saving.value = true
  error.value = null

  const t = typeDepotChoisi.value
  const MAX_TENTATIVES = 3

  for (let tentative = 1; tentative <= MAX_TENTATIVES; tentative++) {
    const numero_chrono = genererNumeroChrono()
    try {
      const courrier = await directus.request(
        createItem('bo_courriers', {
          numero_chrono,
          sens: 'arrivee',
          canal_code: t.canal,
          support_code: 'papier',
          statut_code: 'recu',
          unite_enregistrement_id: UNITE_BO_ID,
          langue_code: 'fr',
          numero_suivi_reception: numeroSuiviReception.value.trim() || null
        })
      )
      courrierCree.value = courrier
      await nextTick()
      dessinerCodesBarres()
      saving.value = false
      return
    } catch (e) {
      console.error(`Tentative ${tentative} échouée`, e)
      if (tentative === MAX_TENTATIVES) {
        error.value =
          "Échec de l'enregistrement après plusieurs tentatives (conflit de numéro ou droits " +
          "insuffisants sur bo_courriers). Réessayez, ou signalez le problème."
      }
    }
  }
  saving.value = false
}

function dessinerCodesBarres() {
  document.querySelectorAll('.barcode-canvas').forEach((canvas) => {
    JsBarcode(canvas, courrierCree.value.numero_chrono, {
      format: 'CODE128',
      width: 2,
      height: 46,
      displayValue: true,
      fontSize: 13,
      margin: 6
    })
  })
}

function imprimer() {
  window.print()
}

function nouvelleReception() {
  typeDepot.value = null
  numeroSuiviReception.value = ''
  courrierCree.value = null
  error.value = null
}
</script>

<template>
  <section>
    <!-- Étape 1 : formulaire de réception -->
    <div v-if="!courrierCree" class="form-page">
      <h1>Réception d'un courrier</h1>
      <p class="hint">Choisissez le type de dépôt. Les étiquettes à imprimer et coller en dépendent.</p>

      <div class="depot-grid">
        <button
          v-for="t in TYPES_DEPOT"
          :key="t.value"
          type="button"
          class="depot-card"
          :class="{ active: typeDepot === t.value }"
          @click="typeDepot = t.value"
        >
          <strong>{{ t.label }}</strong>
          <span class="muted">{{ t.description }}</span>
          <span class="tag">{{ t.nbEtiquettes }} étiquette{{ t.nbEtiquettes > 1 ? 's' : '' }}</span>
        </button>
      </div>

      <label v-if="typeDepot === 'recommande'" class="field">
        Numéro de suivi du recommandé (optionnel, si lisible sur l'enveloppe)
        <input v-model="numeroSuiviReception" placeholder="Ex. RA123456789MA" />
      </label>

      <p v-if="error" class="error">{{ error }}</p>

      <button type="button" class="cta" :disabled="!typeDepot || saving" @click="enregistrerReception">
        {{ saving ? 'Enregistrement…' : 'Enregistrer et générer les étiquettes' }}
      </button>
    </div>

    <!-- Étape 2 : confirmation + impression -->
    <div v-else class="confirm-page">
      <h1>Courrier enregistré</h1>
      <p class="numero">{{ courrierCree.numero_chrono }}</p>
      <p class="muted">Reçu le {{ formatDateTime(courrierCree.date_enregistrement) }} — collez les étiquettes ci-dessous, puis transmettez le courrier à l'indexation.</p>

      <div class="print-area">
        <div class="label">
          <p class="label-dest">Courrier</p>
          <canvas class="barcode-canvas"></canvas>
        </div>
        <div v-if="typeDepotChoisi?.nbEtiquettes === 2" class="label">
          <p class="label-dest">Accusé de dépôt (à remettre au déposant)</p>
          <canvas class="barcode-canvas"></canvas>
        </div>
      </div>

      <div class="actions">
        <button type="button" class="cta" @click="imprimer">Imprimer les étiquettes</button>
        <button type="button" class="secondary" @click="nouvelleReception">Nouvelle réception</button>
      </div>
    </div>
  </section>
</template>

<style scoped>
h1 { font-size: 1.3rem; margin: 0 0 6px; }
.hint { color: var(--muted); font-size: 0.9rem; margin-bottom: 20px; }
.muted { color: var(--muted); }
.error { color: #dc2626; font-size: 0.85rem; }

.depot-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 14px; margin-bottom: 20px; max-width: 720px; }
.depot-card {
  display: flex;
  flex-direction: column;
  gap: 6px;
  text-align: left;
  background: white;
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 16px;
  cursor: pointer;
  font: inherit;
}
.depot-card:hover { border-color: #94a3b8; }
.depot-card.active { border-color: #0f172a; box-shadow: 0 0 0 1px #0f172a; }
.depot-card .tag { align-self: flex-start; font-size: 0.72rem; color: #2563eb; background: #eff6ff; padding: 2px 8px; border-radius: 999px; margin-top: 4px; }

.field { display: flex; flex-direction: column; gap: 5px; font-size: 0.82rem; color: var(--muted); font-weight: 600; max-width: 360px; margin-bottom: 18px; }
.field input { font: inherit; padding: 8px 10px; border: 1px solid var(--border); border-radius: 7px; }

.cta {
  background: #0f172a;
  color: white;
  border: none;
  padding: 10px 18px;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
}
.cta:disabled { opacity: 0.6; cursor: default; }
.secondary {
  background: white;
  color: var(--text);
  border: 1px solid var(--border);
  padding: 10px 18px;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
}

.numero { font-family: 'SFMono-Regular', Consolas, monospace; font-size: 1.1rem; font-weight: 700; margin: 6px 0; }
.actions { display: flex; gap: 10px; margin-top: 20px; }

.print-area { display: flex; gap: 16px; flex-wrap: wrap; margin-top: 20px; }
.label {
  background: white;
  border: 1px dashed var(--border);
  border-radius: 8px;
  padding: 12px;
  width: 220px;
  text-align: center;
}
.label-dest { font-size: 0.78rem; color: var(--muted); margin: 0 0 8px; }
</style>

<style>
/* Non scopé volontairement : ne s'applique qu'au moment de l'impression,
   quelle que soit la vue affichée — donc sans risque pour le reste de l'app. */
@media print {
  body * { visibility: hidden; }
  .print-area, .print-area * { visibility: visible; }
  .print-area {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    display: flex;
    gap: 0;
  }
  .label {
    border: none;
    page-break-after: always;
    width: 62mm;
  }
}
</style>
