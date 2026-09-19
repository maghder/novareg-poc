import { createRouter, createWebHistory } from 'vue-router'
import CourrierListView from '../views/CourrierListView.vue'
import CourrierDetailView from '../views/CourrierDetailView.vue'
import CourrierCreateView from '../views/CourrierCreateView.vue'
import DossierListView from '../views/DossierListView.vue'
import DossierDetailView from '../views/DossierDetailView.vue'
import AgentReceptionView from '../views/AgentReceptionView.vue'
import IndexationQueueView from '../views/IndexationQueueView.vue'
import IndexationFormView from '../views/IndexationFormView.vue'
import AffectationQueueView from '../views/AffectationQueueView.vue'
import AffectationFormView from '../views/AffectationFormView.vue'
import ExpeditionQueueView from '../views/ExpeditionQueueView.vue'
import ExpeditionFormView from '../views/ExpeditionFormView.vue'
import AccuseReceptionQueueView from '../views/AccuseReceptionQueueView.vue'
import AccuseReceptionFormView from '../views/AccuseReceptionFormView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', name: 'courrier-list', component: CourrierListView },
    { path: '/courriers/nouveau', name: 'courrier-create', component: CourrierCreateView },
    { path: '/courriers/:id', name: 'courrier-detail', component: CourrierDetailView, props: true },
    { path: '/dossiers', name: 'dossier-list', component: DossierListView },
    { path: '/dossiers/:id', name: 'dossier-detail', component: DossierDetailView, props: true },
    { path: '/reception', name: 'agent-reception', component: AgentReceptionView },
    { path: '/indexation', name: 'indexation-queue', component: IndexationQueueView },
    { path: '/indexation/:id', name: 'indexation-form', component: IndexationFormView, props: true },
    { path: '/affectation', name: 'affectation-queue', component: AffectationQueueView },
    { path: '/affectation/:id', name: 'affectation-form', component: AffectationFormView, props: true },
    { path: '/expedition', name: 'expedition-queue', component: ExpeditionQueueView },
    { path: '/expedition/:id', name: 'expedition-form', component: ExpeditionFormView, props: true },
    { path: '/accuses-reception', name: 'ar-queue', component: AccuseReceptionQueueView },
    { path: '/accuses-reception/:id', name: 'ar-form', component: AccuseReceptionFormView, props: true }
  ]
})

export default router
