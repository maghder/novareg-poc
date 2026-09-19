import { createRouter, createWebHistory } from 'vue-router'
import CourrierListView from '../views/CourrierListView.vue'
import CourrierDetailView from '../views/CourrierDetailView.vue'
import CourrierCreateView from '../views/CourrierCreateView.vue'
import DossierListView from '../views/DossierListView.vue'
import DossierDetailView from '../views/DossierDetailView.vue'
import AgentReceptionView from '../views/AgentReceptionView.vue'
import IndexationQueueView from '../views/IndexationQueueView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', name: 'courrier-list', component: CourrierListView },
    { path: '/courriers/nouveau', name: 'courrier-create', component: CourrierCreateView },
    { path: '/courriers/:id', name: 'courrier-detail', component: CourrierDetailView, props: true },
    { path: '/dossiers', name: 'dossier-list', component: DossierListView },
    { path: '/dossiers/:id', name: 'dossier-detail', component: DossierDetailView, props: true },
    { path: '/reception', name: 'agent-reception', component: AgentReceptionView },
    { path: '/indexation', name: 'indexation-queue', component: IndexationQueueView }
  ]
})

export default router
