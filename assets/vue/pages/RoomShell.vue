<script setup lang="ts">
import { Link } from "live_vue"

type Room = {
  id: string
  name: string
  slug: string
}

withDefaults(
  defineProps<{
    room?: Room | null
    currentUser?: unknown
    currentGuest?: unknown
  }>(),
  {
    room: null,
    currentUser: null,
    currentGuest: null,
  }
)
</script>

<template>
  <div class="flex flex-col h-screen">
    <header class="flex items-center justify-between p-4 border-b border-base-300 bg-base-100">
      <h1 class="text-xl font-bold font-brand">{{ room?.name }}</h1>
      <div class="flex items-center gap-2">
        <Link navigate="/rooms" class="btn btn-ghost min-h-[44px]">
          ← Salas
        </Link>
      </div>
    </header>

    <div class="flex flex-1 overflow-hidden">
      <main class="flex flex-col flex-1 overflow-hidden"></main>
    </div>
  </div>
</template>
