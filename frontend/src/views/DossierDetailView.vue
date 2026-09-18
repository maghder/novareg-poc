<script setup>
import { onMounted, ref } from 'vue'
import { readItem } from '@directus/sdk'
import { directus } from '../lib/directus'
import StatusBadge from '../components/StatusBadge.vue'
import { STATUTS_DOSSIER, PRIORITES, labelFor, colorFor, formatDate, formatDateTime } from '../lib/labels'

const props = defineProps({ id: { type: String, required: true } })

const dossier = ref(null)
const loading = ref(true)
const error = ref(null)

async function charger() {
  loading.value = true
  error.value = null
  try {
    dossier.value = await directus.request(
      readItem('dos_dossiers', props.id, {
        fields: [
          '*',
          'unite_responsable_id.libelle',
          'tiers_principal_id.code_tiers',
          'parties.*',
          'courriers.*',
          'courriers.courrier_id.id',
          'courriers.courrier_id.numero_chrono',
          'courriers.courrier_id.objet',
          'documents.*',
          'documents.document_id.titre',
          'affectations.*',
          'affectations.unite_id.libelle',
          'statuts_historique.*'
        ]
      })
    )
  } catch (e) {
    error.value =
      "Impossible de charger ce dossier. Vérifiez que les alias 'parties', " +
      "'courriers', 'documents', 'affectations' et 'statuts_historique' ont " +
      "bien été créés sur dos_dossiers (voir la checklist précédente)."
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

  <section v-else-if="dossier" class="detail">
    <RouterLink to="/dossiers" class="back">← Retour aux dossiers</RouterLink>

    <header class="detail-header">
      <div>
        <p class="mono muted">{{ dossier.numero_dossier }}</p>
        <h1>{{ dossier.objet }}</h1>
      </div>
      <div class="badges">
        <StatusBadge :label="labelFor(STATUTS_DOSSIER, dossier.statut_code)" :color="colorFor(STATUTS_DOSSIER, dossier.statut_code)" />
        <StatusBadge :label="labelFor(PRIORITES, dossier.priorite_code)" :color="colorFor(PRIORITES, dossier.priorite_code)" />
      </div>
    </header>

    <dl class="meta-grid">
      <div><dt>Type</dt><dd>{{ dossier.type_dossier_code }}</dd></div>
      <div><dt>Ouvert le</dt><dd>{{ formatDateTime(dossier.date_ouverture) }}</dd></div>
      <div><dt>Clôturé le</dt><dd>{{ formatDateTime(dossier.date_cloture) }}</dd></div>
      <div><dt>Unité responsable</dt><dd>{{ dossier.unite_responsable_id?.libelle || '—' }}</dd></div>
      <div><dt>Tiers principal</dt><dd>{{ dossier.tiers_principal_id?.code_tiers || '—' }}</dd></div>
    </dl>

    <div class="card" v-if="dossier.courriers?.length">
      <h2>Courriers liés (Bureau d'Ordre)</h2>
      <ul class="plain-list">
        <li v-for="c in dossier.courriers" :key="c.id">
          <RouterLink :to="`/courriers/${c.courrier_id.id}`" class="link">
            {{ c.courrier_id.numero_chrono }} — {{ c.courrier_id.objet }}
          </RouterLink>
          <span class="muted"> ({{ c.role_courrier }})</span>
        </li>
      </ul>
    </div>

    <div class="card" v-if="dossier.parties?.length">
      <h2>Parties</h2>
      <ul class="plain-list">
        <li v-for="p in dossier.parties" :key="p.id">
          <strong>{{ p.role_partie }}</strong>
        </li>
      </ul>
    </div>

    <div class="card" v-if="dossier.documents?.length">
      <h2>Documents</h2>
      <ul class="plain-list">
        <li v-for="doc in dossier.documents" :key="doc.id">
          {{ doc.document_id?.titre }} <span class="muted">({{ doc.role_document }})</span>
        </li>
      </ul>
    </div>

    <div class="card" v-if="dossier.affectations?.length">
      <h2>Affectations</h2>
      <ul class="plain-list">
        <li v-for="a in dossier.affectations" :key="a.id">
          {{ a.unite_id?.libelle }} — <span class="muted">{{ a.role_affectation }}</span>
          <span v-if="!a.date_fin" class="badge-active">en cours</span>
        </li>
      </ul>
    </div>

    <div class="card" v-if="dossier.statuts_historique?.length">
      <h2>Historique des statuts</h2>
      <ul class="plain-list">
        <li v-for="h in dossier.statuts_historique" :key="h.id">
          {{ formatDateTime(h.changed_at) }} —
          <span v-if="h.ancien_statut_code">{{ h.ancien_statut_code }} → </span>
          <strong>{{ h.nouveau_statut_code }}</strong>
          <span v-if="h.motif" class="muted"> · {{ h.motif }}</span>
        </li>
      </ul>
    </div>

    <div class="card" v-if="dossier.commentaire">
      <h2>Commentaire</h2>
      <p>{{ dossier.commentaire }}</p>
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
.link { color: #2563eb; text-decoration: none; font-weight: 600; }
.link:hover { text-decoration: underline; }
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
.badge-active { margin-left: 6px; font-size: 0.72rem; color: #16a34a; font-weight: 600; }
.hint { color: var(--muted); }
.error { color: #dc2626; }
</style>
