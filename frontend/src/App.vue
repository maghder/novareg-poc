<script setup>
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <div class="app-shell">
    <header class="app-header">
      <RouterLink to="/" class="brand">NOVAREG · Bureau d'Ordre</RouterLink>
      <nav>
        <RouterLink to="/reception">Réception</RouterLink>
        <RouterLink to="/indexation">À indexer</RouterLink>
        <RouterLink to="/affectation">À affecter</RouterLink>
        <RouterLink to="/">Courriers</RouterLink>
        <RouterLink to="/dossiers">Dossiers</RouterLink>
        <RouterLink to="/courriers/nouveau" class="cta">+ Enregistrer un courrier</RouterLink>
      </nav>
    </header>
    <main class="app-main">
      <RouterView />
    </main>
  </div>
</template>

<style>
:root {
  --border: #e2e8f0;
  --text: #0f172a;
  --muted: #64748b;
  --bg: #f8fafc;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
  color: var(--text);
  background: var(--bg);
}
.app-shell { min-height: 100vh; display: flex; flex-direction: column; }
.app-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 28px;
  background: white;
  border-bottom: 1px solid var(--border);
}
.brand { font-weight: 700; color: var(--text); text-decoration: none; font-size: 1.05rem; }
.app-header nav { display: flex; align-items: center; gap: 18px; }
.app-header nav a { color: var(--muted); text-decoration: none; font-size: 0.92rem; }
.app-header nav a.router-link-exact-active { color: var(--text); font-weight: 600; }
.app-header nav a.cta {
  background: #0f172a;
  color: white;
  padding: 7px 14px;
  border-radius: 8px;
  font-weight: 600;
}
.app-main { flex: 1; padding: 28px; max-width: 1080px; width: 100%; margin: 0 auto; }
</style>
