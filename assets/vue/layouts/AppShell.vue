<script setup lang="ts">
withDefaults(
  defineProps<{
    current_user?: unknown
    current_guest?: unknown
  }>(),
  {
    current_user: null,
    current_guest: null,
  }
)
</script>

<template>
  <slot />
</template>
