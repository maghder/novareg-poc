<script setup>
import { onMounted, ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { readItem, updateItem, createItem } from '@directus/sdk'
import { directus } from '../lib/directus'

const props = defineProps({ id: { type: String, required: true } })
const router = useRouter()

const courrier = ref(null)
const loading = ref(true)
const saving = ref(false)
const error = ref(null)

const MODES = [
  { value: 'recommande_ar', label: 'Recommandé avec AR', arRequis: true },
  { value: 'main_propre', label: 'Remise en main propre', arRequis: true },
  { value: 'courrier_simple', label: 'Courrier simple', arRequis: false },
  { value: 'coursier', label: 'Coursier', arRequis: false },
  { value: 'email', label: 'Email', arRequis: false },
  { value: 'portail', label: 'Portail en ligne', arRequis: false }
]

const modeExpedition = ref('')
const operateur = ref('')
const numeroSuivi = ref('')

const modeChoisi = computed(() => MODES.find((m) => m.value === modeExpedition.value) ?? null)
const arRequis = computed(() => modeChoisi.value?.arRequis ?? false)

async function charger() {
  loading.value = true
  error.value = null
  try {
    const c = await directus.request(
      readItem('bo_courriers', props.id, {
        fields: ['id', 'numero_chrono', 'objet', 'sens', 'statut_code', 'parties.id', 'parties.role_code', 'parties.libelle_snapshot']
      })
    )
    courrier.value = c
    if (c.sens !== 'depart' || c.statut_code !== 'enregistre') {
      error.value = `Ce courrier n'est pas éligible à l'expédition (sens : ${c.sens}, statut : ${c.statut_code}).`
    }
  } catch (e) {
    error.value = 'Impossible de charger ce courrier. Vérifiez les droits de lecture sur bo_courriers.'
    console.error(e)
  } finally {
    loading.value = false
  }
}

async function preparerExpedition() {
  if (!modeExpedition.value) {
    error.value = "Choisissez un mode d'expédition."
    return
  }
  const destinataire = courrier.value.parties?.find((p) => p.role_code === 'destinataire')
  if (!destinataire) {
    error.value = "Ce courrier n'a pas de partie destinataire enregistrée — impossible de préparer l'expédition."
    return
  }

  saving.value = true
  error.value = null
  try {
    const statutInitial = arRequis.value ? 'expedie' : 'distribue'
    const maintenant = new Date().toISOString()

    const expedition = await directus.request(
      createItem('bo_expeditions', {
        courrier_id: props.id,
        destinataire_partie_id: destinataire.id,
        mode_expedition_code: modeExpedition.value,
        operateur: operateur.value.trim() || null,
        ar_requis: arRequis.value,
        statut_code: statutInitial,
        date_preparation: maintenant
      })
    )

    await directus.request(
      createItem('bo_expedition_tentatives', {
        expedition_id: expedition.id,
        numero_tentative: 1,
        numero_suivi: numeroSuivi.value.trim() || null,
        date_expedition: maintenant,
        date_distribution: arRequis.value ? null : maintenant,
        statut_code: statutInitial
      })
    )

    await directus.request(
      updateItem('bo_courriers', props.id, {
        statut_code: arRequis.value ? 'traite' : 'cloture'
      })
    )

    router.push(`/courriers/${props.id}`)
  } catch (e) {
    error.value =
      "Échec de la préparation. Vérifiez les droits d'écriture sur bo_expeditions et bo_expedition_tentatives."
    console.error(e)
    saving.value = false
  }
}

onMounted(charger)
</script>

<template>
  <section v-if="loading" class="hint">Chargement…</section>

  <section v-else-if="courrier" class="form-page">
    <RouterLink to="/expedition" class="back">← Retour à la file d'expédition</RouterLink>

    <p class="mono muted">{{ courrier.numero_chrono }}</p>
    <h1>{{ courrier.objet }}</h1>

    <form v-if="courrier.sens === 'depart' && courrier.statut_code === 'enregistre'" @submit.prevent="preparerExpedition" class="form">
      <label class="field">
        Mode d'expédition
        <select v-model="modeExpedition" required>
          <option value="" disabled>Choisir un mode…</option>
          <option v-for="m in MODES" :key="m.value" :value="m.value">{{ m.label }}</option>
        </select>
      </label>

      <p v-if="modeChoisi" class="ar-note" :class="{ requis: arRequis }">
        {{ arRequis
          ? "Un accusé de réception sera attendu — le courrier apparaîtra dans la file « AR à traiter » jusqu'à son enregistrement."
          : "Aucun accusé de réception attendu — le courrier sera considéré clôturé dès la préparation." }}
      </p>

      <div class="row">
        <label class="field">
          Opérateur (optionnel)
          <input v-model="operateur" placeholder="Ex. Barid Al-Maghrib" />
        </label>
        <label class="field">
          N° de suivi (optionnel)
          <input v-model="numeroSuivi" placeholder="Si connu au moment de l'envoi" />
        </label>
      </div>

      <p v-if="error" class="error">{{ error }}</p>

      <button type="submit" class="cta" :disabled="saving">
        {{ saving ? 'Préparation…' : "Préparer et marquer comme envoyé" }}
      </button>
    </form>

    <p v-else class="error">{{ error }}</p>
  </section>
</template>

<style scoped>
.back { color: var(--muted); text-decoration: none; font-size: 0.85rem; }
.mono { font-family: 'SFMono-Regular', Consolas, monospace; }
.muted { color: var(--muted); }
h1 { font-size: 1.3rem; margin: 2px 0 20px; }
.form {
  background: white;
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 22px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  max-width: 520px;
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
.ar-note { font-size: 0.82rem; padding: 8px 12px; border-radius: 7px; background: #f1f5f9; color: var(--muted); }
.ar-note.requis { background: #fff7ed; color: #c2410c; }
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
