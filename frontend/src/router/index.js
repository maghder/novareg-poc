import { createRouter, createWebHistory } from 'vue-router'
import CourrierListView from '../views/CourrierListView.vue'
import CourrierDetailView from '../views/CourrierDetailView.vue'
import CourrierCreateView from '../views/CourrierCreateView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', name: 'courrier-list', component: CourrierListView },
    { path: '/courriers/nouveau', name: 'courrier-create', component: CourrierCreateView },
    { path: '/courriers/:id', name: 'courrier-detail', component: CourrierDetailView, props: true }
  ]
})

export default router
