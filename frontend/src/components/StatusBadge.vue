<script setup>
defineProps({
  label: { type: String, required: true },
  color: { type: String, default: '#64748b' }
})
</script>

<template>
  <span class="badge" :style="{ '--badge-color': color }">{{ label }}</span>
</template>

<style scoped>
.badge {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  border-radius: 999px;
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--badge-color);
  background: color-mix(in srgb, var(--badge-color) 14%, white);
  border: 1px solid color-mix(in srgb, var(--badge-color) 35%, white);
  white-space: nowrap;
}
</style>
