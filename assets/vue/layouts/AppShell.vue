<script setup lang="ts">
withDefaults(
  defineProps<{
    currentUser?: unknown
    currentGuest?: unknown
  }>(),
  {
    currentUser: null,
    currentGuest: null,
  }
)
</script>

<template>
  <slot />
</template>
