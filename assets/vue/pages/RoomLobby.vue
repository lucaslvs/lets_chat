<script lang="ts">
export function slugify(text: string): string | null {
  const trimmed = text.trim()
  if (!trimmed) return null
  return trimmed
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[^a-z0-9\s-]/g, "")
    .trim()
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-") || null
}

export function relativeTime(insertedAt: string): string {
  const diffSecs = Math.floor((Date.now() - new Date(insertedAt).getTime()) / 1000)
  if (diffSecs < 60) return "agora mesmo"
  if (diffSecs < 3600) return `${Math.floor(diffSecs / 60)} min atrás`
  if (diffSecs < 86400) return `${Math.floor(diffSecs / 3600)}h atrás`
  return `${Math.floor(diffSecs / 86400)} dias atrás`
}
</script>

<script setup lang="ts">
import { ref, computed, watch, nextTick } from "vue"
import { useLiveVue, useLiveEvent, useLiveForm, type Form } from "live_vue"
import { Link } from "live_vue"

type Room = {
  id: string
  name: string
  slug: string
  inserted_at: string
}

type RoomFields = {
  name: string
}

const props = withDefaults(
  defineProps<{
    rooms: Room[]
    form: Form<RoomFields>
    show_modal: boolean
    current_user?: unknown
    current_guest?: unknown
  }>(),
  {
    rooms: () => [],
    show_modal: false,
    current_user: null,
    current_guest: null,
  }
)

const live = useLiveVue()

const { field, submit } = useLiveForm<RoomFields>(() => props.form, {
  changeEvent: "validate",
  submitEvent: "create_room",
})

const nameField = field("name")

const slugPreview = computed(() => slugify(nameField.value.value as string ?? ""))
const slugAvailable = ref<boolean | null>(null)

watch(slugPreview, () => {
  slugAvailable.value = null
})

useLiveEvent("slug_availability", (data: { available: boolean }) => {
  slugAvailable.value = data.available
})

const nameInputRef = ref<HTMLInputElement | null>(null)

watch(
  () => props.show_modal,
  (isOpen) => {
    if (isOpen) {
      nextTick(() => nameInputRef.value?.focus())
    }
  },
  { immediate: true }
)
</script>

<template>
  <div class="min-h-screen p-4 max-w-5xl mx-auto">
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold font-brand">Salas</h1>
      <button
        @click="live.pushEvent('open_modal', {})"
        class="btn btn-primary min-h-[44px]"
      >
        Nova sala
      </button>
    </div>

    <div v-if="props.rooms.length === 0" class="text-center py-16">
      <p class="text-base-content/60">
        Nenhuma sala criada ainda. Use o botão <strong>Nova sala</strong> acima para começar.
      </p>
    </div>

    <div v-else class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <Link
        v-for="room in props.rooms"
        :key="room.id"
        :navigate="`/rooms/${room.slug}`"
        class="card bg-base-200 hover:bg-base-300 transition-colors cursor-pointer"
      >
        <div class="card-body min-h-[44px]">
          <h2 class="card-title text-base">{{ room.name }}</h2>
          <p class="text-sm font-mono text-base-content/60">{{ room.slug }}</p>
          <p class="text-xs text-base-content/40">{{ relativeTime(room.inserted_at) }}</p>
        </div>
      </Link>
    </div>

    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-150 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="props.show_modal"
        class="modal modal-open"
        role="dialog"
        @click.self="live.pushEvent('close_modal', {})"
      >
        <div class="modal-box">
          <h3 class="font-bold text-lg mb-4">Nova sala</h3>
          <form @submit.prevent="submit">
            <div class="fieldset">
              <label for="room_name" class="label">Nome da sala</label>
              <input
                id="room_name"
                ref="nameInputRef"
                v-bind="nameField.inputAttrs.value"
                type="text"
                placeholder="Ex: Elixir Study Group"
                :class="['w-full input min-h-[44px]', (nameField.errorMessage.value || slugAvailable === false) && 'input-error']"
              />
            </div>

            <div class="h-5 mt-1 text-sm flex items-center">
              <template v-if="nameField.errorMessage.value">
                <span class="flex gap-2 items-center text-error">
                  <span>⚠</span>
                  Nome da sala não pode ficar em branco
                </span>
              </template>
              <template v-else-if="slugPreview">
                <span class="text-base-content/60">URL: /rooms/</span>
                <span class="font-mono">{{ slugPreview }}</span>
                <span v-if="slugAvailable === true" class="text-success ml-2">✓ disponível</span>
                <span v-if="slugAvailable === false" class="text-error ml-2">✗ já em uso</span>
              </template>
            </div>

            <div class="modal-action">
              <button
                type="button"
                @click="live.pushEvent('close_modal', {})"
                class="btn min-h-[44px]"
              >
                Cancelar
              </button>
              <button
                type="submit"
                :disabled="slugAvailable === null || slugAvailable === false"
                class="btn btn-primary min-h-[44px]"
              >
                Criar sala
              </button>
            </div>
          </form>
        </div>
      </div>
    </Transition>
  </div>
</template>
