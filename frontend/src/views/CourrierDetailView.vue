<script setup>
import { onMounted, ref } from 'vue'
import { readItem } from '@directus/sdk'
import { directus } from '../lib/directus'
import StatusBadge from '../components/StatusBadge.vue'
import {
  STATUTS_COURRIER,
  SENS_COURRIER,
  PRIORITES,
  labelFor,
  colorFor,
  formatDate,
  formatDateTime
} from '../lib/labels'

const props = defineProps({ id: { type: String, required: true } })

const courrier = ref(null)
const loading = ref(true)
const error = ref(null)

async function charger() {
  loading.value = true
  error.value = null
  try {
    courrier.value = await directus.request(
      readItem('bo_courriers', props.id, {
        fields: [
          '*',
          'parties.*',
          'orientations.*',
          'orientations.unite_source_id.libelle',
          'orientations.unite_destination_id.libelle',
          'pieces_jointes.*',
          'pieces_jointes.document_id.titre',
          'pieces_jointes.document_id.type_document_code',
          'expeditions.*',
          'expeditions.tentatives.*',
          'expeditions.tentatives.accuses_reception.*'
        ]
      })
    )
  } catch (e) {
    error.value =
      "Impossible de charger ce courrier. Vérifiez que les champs alias " +
      "'parties', 'orientations', 'pieces_jointes', 'expeditions', 'tentatives' " +
      "et 'accuses_reception' ont bien été créés (voir docs/SETUP.md §6)."
    console.error(e)
  } finally {
    loading.value = false
  }
}

onMounted(charger)
</script>

<template>
  <section v-if="loading" class="hint">Chargement…</section>
  <section v-else-if="error" class="error">{{ error }}</section>

  <section v-else-if="courrier" class="detail">
    <RouterLink to="/" class="back">← Retour à la liste</RouterLink>

    <header class="detail-header">
      <div>
        <p class="mono muted">{{ courrier.numero_chrono }}</p>
        <h1>{{ courrier.objet }}</h1>
      </div>
      <div class="badges">
        <StatusBadge :label="labelFor(SENS_COURRIER, courrier.sens)" :color="colorFor(SENS_COURRIER, courrier.sens)" />
        <StatusBadge :label="labelFor(STATUTS_COURRIER, courrier.statut_code)" :color="colorFor(STATUTS_COURRIER, courrier.statut_code)" />
        <StatusBadge :label="labelFor(PRIORITES, courrier.priorite_code)" :color="colorFor(PRIORITES, courrier.priorite_code)" />
      </div>
    </header>

    <dl class="meta-grid">
      <div><dt>Date d'enregistrement</dt><dd>{{ formatDateTime(courrier.date_enregistrement) }}</dd></div>
      <div><dt>Date du document</dt><dd>{{ formatDate(courrier.date_document) }}</dd></div>
      <div><dt>Référence externe</dt><dd>{{ courrier.reference_externe || '—' }}</dd></div>
      <div><dt>Canal</dt><dd>{{ courrier.canal_code || '—' }}</dd></div>
    </dl>

    <div class="card" v-if="courrier.parties?.length">
      <h2>Parties</h2>
      <ul class="plain-list">
        <li v-for="p in courrier.parties" :key="p.id">
          <strong>{{ p.role_code }}</strong> — {{ p.libelle_snapshot }}
        </li>
      </ul>
    </div>

    <div class="card" v-if="courrier.orientations?.length">
      <h2>Orientation</h2>
      <ul class="plain-list">
        <li v-for="o in courrier.orientations" :key="o.id">
          {{ o.unite_source_id?.libelle || 'Bureau d\'Ordre' }} → <strong>{{ o.unite_destination_id?.libelle }}</strong>
          — {{ formatDateTime(o.date_transmission) }}
          <span class="muted">({{ o.statut }})</span>
        </li>
      </ul>
    </div>

    <div class="card" v-if="courrier.pieces_jointes?.length">
      <h2>Pièces jointes</h2>
      <ul class="plain-list">
        <li v-for="pj in courrier.pieces_jointes" :key="pj.id">
          {{ pj.document_id?.titre }} <span class="muted">({{ pj.role_document }})</span>
        </li>
      </ul>
    </div>

    <div class="card" v-if="courrier.expeditions?.length">
      <h2>Expédition</h2>
      <div v-for="e in courrier.expeditions" :key="e.id" class="expedition">
        <p>
          Mode : <strong>{{ e.mode_expedition_code }}</strong> via {{ e.operateur || '—' }}
          — statut <StatusBadge :label="e.statut_code" color="#2563eb" />
        </p>
        <ul class="plain-list" v-if="e.tentatives?.length">
          <li v-for="t in e.tentatives" :key="t.id">
            Tentative {{ t.numero_tentative }} — suivi {{ t.numero_suivi || '—' }}
            — expédié le {{ formatDateTime(t.date_expedition) }}
            — distribué le {{ formatDateTime(t.date_distribution) }}
            <div v-if="t.accuses_reception?.length" class="ar">
              <span v-for="ar in t.accuses_reception" :key="ar.id">
                AR {{ ar.statut_ar_code }} le {{ formatDateTime(ar.date_reception_ar) }}
                — reçu par {{ ar.nom_recepteur || '—' }}
              </span>
            </div>
          </li>
        </ul>
      </div>
    </div>

    <div class="card" v-if="courrier.commentaire_bo">
      <h2>Commentaire Bureau d'Ordre</h2>
      <p>{{ courrier.commentaire_bo }}</p>
    </div>
  </section>
</template>

<style scoped>
.back { color: var(--muted); text-decoration: none; font-size: 0.85rem; }
.detail-header { display: flex; align-items: flex-start; justify-content: space-between; margin: 10px 0 20px; gap: 16px; }
h1 { margin: 2px 0 0; font-size: 1.4rem; }
.badges { display: flex; gap: 6px; flex-wrap: wrap; }
.mono { font-family: 'SFMono-Regular', Consolas, monospace; }
.muted { color: var(--muted); }
.meta-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 14px;
  background: white;
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 16px 20px;
  margin-bottom: 18px;
}
.meta-grid dt { font-size: 0.72rem; text-transform: uppercase; color: var(--muted); margin-bottom: 2px; }
.meta-grid dd { margin: 0; font-size: 0.92rem; }
.card {
  background: white;
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 16px 20px;
  margin-bottom: 16px;
}
.card h2 { font-size: 0.95rem; margin: 0 0 10px; }
.plain-list { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 8px; font-size: 0.9rem; }
.expedition + .expedition { margin-top: 14px; border-top: 1px solid var(--border); padding-top: 14px; }
.ar { margin-top: 4px; font-size: 0.85rem; color: #16a34a; }
.hint { color: var(--muted); }
.error { color: #dc2626; }
</style>
