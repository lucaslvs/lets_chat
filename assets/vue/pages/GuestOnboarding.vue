<script lang="ts">
const AVATAR_COLORS = ["primary", "secondary", "accent", "info", "success", "warning", "error"] as const

export function avatarInitials(name: string): string {
  const trimmed = name.trim()
  if (!trimmed) return "?"
  const words = trimmed.split(/\s+/)
  const first = words[0][0].toUpperCase()
  if (words.length === 1) return first
  const last = words[words.length - 1][0].toUpperCase()
  return first + last
}

function simpleHash(str: string): number {
  let hash = 5381
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) + hash + str.charCodeAt(i)) >>> 0
  }
  return hash
}

export function avatarColor(name: string): string {
  return AVATAR_COLORS[simpleHash(name) % AVATAR_COLORS.length]
}
</script>

<script setup lang="ts">
import { ref, computed } from "vue"

const props = withDefaults(
  defineProps<{
    return_to?: string | null
    guest_session_id?: string | null
    error?: string | null
    current_user?: unknown
    current_guest?: unknown
  }>(),
  {
    return_to: null,
    guest_session_id: null,
    error: null,
    current_user: null,
    current_guest: null,
  }
)

const name = ref("")

const initials = computed(() => avatarInitials(name.value))
const colorClass = computed(() => {
  const c = avatarColor(name.value || "")
  return `bg-${c} text-${c}-content`
})
const isValid = computed(() => name.value.trim().length > 0)
const buttonLabel = computed(() => {
  if (!props.return_to || props.return_to === "/rooms") return "Explorar salas"
  if (props.return_to.startsWith("/rooms/")) return "Entrar na sala"
  return "Continuar"
})
const spacesOnlyError = computed(() => name.value.length > 0 && name.value.trim().length === 0)
const errorMessage = computed(() => spacesOnlyError.value ? "Nome não pode ficar em branco" : props.error)
</script>

<template>
  <div class="min-h-screen flex items-center justify-center p-4">
    <div class="card bg-base-200 w-full max-w-sm mx-auto">
      <div class="card-body gap-5">
        <div class="text-center">
          <h1 class="text-3xl font-bold font-brand">Let's Chat!</h1>
          <p class="text-base-content/60 text-sm mt-1">
            Entre, escolha seu nome e explore as salas
          </p>
        </div>

        <div class="flex justify-center py-2">
          <div class="avatar avatar-placeholder">
            <div :class="['w-14 h-14 rounded-full', initials === '?' ? 'bg-neutral text-neutral-content' : colorClass]">
              <span class="text-base">{{ initials }}</span>
            </div>
          </div>
        </div>

        <form phx-change="validate" phx-submit="submit" class="flex flex-col gap-4">
          <input v-if="props.return_to" type="hidden" name="return_to" :value="props.return_to" />
          <input v-if="props.guest_session_id" type="hidden" name="guest_session_id" :value="props.guest_session_id" />
          <div class="fieldset">
            <label for="name" class="label">Seu nome</label>
            <input
              id="name"
              name="name"
              type="text"
              v-model="name"
              placeholder="Como devemos te chamar?"
              :class="['w-full input min-h-[44px]', errorMessage && 'input-error']"
              autocomplete="off"
              autofocus
            />
            <p v-if="errorMessage" class="mt-1.5 flex gap-2 items-center text-sm text-error">
              <span>⚠</span>
              {{ errorMessage }}
            </p>
          </div>

          <button type="submit" :disabled="!isValid" class="btn btn-primary w-full min-h-[44px]">
            {{ buttonLabel }}
          </button>
        </form>
      </div>
    </div>
  </div>
</template>
