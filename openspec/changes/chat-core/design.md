## Context

This change builds on top of Change 2 (rooms-lobby), which establishes the `LetsChat.Chat` Ash domain and the `Room` resource. At the end of Change 2, a user can navigate to `/rooms/:slug` and see a shell layout with a disabled message input. Change 3 (this change) activates that shell: it introduces the `Message` resource, wires up Phoenix.PubSub broadcasts, and delivers real-time chat via a LiveVue `ChatWindow.vue` component.

`LetsChat.PubSub` is already registered in the application supervision tree. The guest identity system (session-based `session_id`, `sender_name`) was established in Change 1. No new OTP processes are introduced here.

## Goals / Non-Goals

**Goals:**
- Introduce the `Message` Ash resource (`:chat` and `:system` types) with Postgres persistence via AshPostgres
- Enable real-time message delivery: broadcast via `LetsChat.PubSub` → `push_event` to the Vue layer; only new items travel the wire after the initial load (O(1) updates)
- Load the last 100 messages on mount and pass them as the initial `@messages` prop to `ChatWindow.vue`
- Persist system events (join/leave) so they appear in room history even for users who join later
- Deliver a functional `ChatWindow.vue` component: renders message list, groups consecutive messages by sender, differentiates own/other/system messages visually, sends on Enter, newline on Shift+Enter
- Handle the unknown-slug case gracefully (redirect to `/rooms` with flash)

**Non-Goals:**
- Typing indicators, read receipts, or online presence (Change 4)
- Message editing or deletion
- Pagination UI beyond the initial 100-message load
- Private rooms or knock-to-enter (Change 5)
- Animations, scroll-snapping, or rich media in `ChatWindow.vue` (Change 4 enriches this component)
- Sender avatar stored in the database — avatar initials and color are always computed from `sender_name` at display time

## Decisions

### 1. `Message` type enum: `:text` / `:system` (not `:chat` / `:system`)

The proposal uses `:chat`, but the Ash resource will use `:text` as the atom for user-authored messages. This is consistent with common chat conventions (the *medium* is text, the *channel* is the room) and avoids confusion with the Ash `Chat` domain name. Both `:text` and `:system` are persisted to the same `messages` table.

**Alternatives considered:** keeping `:chat` (proposal wording). Rejected for the naming collision with the domain.

### 2. `push_event` over LiveView Streams for real-time updates

LiveVue owns the entire chat timeline DOM inside `ChatWindow.vue`. Using LiveView Streams would require MutationObserver tricks or re-rendering the full list from the server on each new message. Instead, the server sends only the new message payload via `push_event(socket, "new_message", payload)`, and `ChatWindow.vue` appends it with `messages.value.push(msg)` — O(1) on the wire and zero DOM reconciliation from the server.

The initial 100-message list travels as a prop on mount, which is the correct boundary: bulk data at mount time, incremental updates thereafter.

**Alternatives considered:** Phoenix LiveView Streams. Rejected because it conflicts with Vue's ownership of the DOM; mixing both would require complex coordination.

### 3. Broadcast the full serialized payload, not just the ID

Messages are immutable after creation. Broadcasting the serialized message map (id, content, type, sender_name, session_id, inserted_at, plus computed avatar_initials and avatar_color) means receivers do not need an additional database query. `push_event` serializes the map to JSON before sending to the Vue layer.

Snake_case keys from Elixir are passed through to the Vue component as camelCase (LiveVue handles this transformation automatically).

**Alternatives considered:** broadcast only the message ID and let receivers fetch from DB. Rejected — unnecessary DB round-trip per connected client per message.

### 4. Avatar computed at broadcast time, not stored

`avatar_initials/1` and `avatar_color/1` are deterministic functions of `sender_name` (established in Change 1). Computing them in the `serialize/1` helper at broadcast time keeps the `messages` table free of derived data and ensures display consistency without a sync problem.

### 5. System events persisted to the `messages` table

Join/leave events use `type: :system` and are stored alongside chat messages. This means a user who joins a room later sees the full join/leave history inline in the timeline — more informative than ephemeral presence events. The cost is a small write on every mount/unmount of `RoomLive`.

**Alternatives considered:** ephemeral PubSub events not persisted. Rejected because the timeline would be incomplete for late joiners.

### 6. PubSub topic: `"room:{slug}"` (not `"room:{id}"`)

The slug is the canonical URL identifier for a room in this app. Using slug as the topic key is consistent with routing and avoids the extra `Room` fetch to get the ID when subscribing. Slugs are unique and immutable.

### 7. Last 100 messages on mount (no lazy pagination UI)

Pagination UI adds complexity and is deferred to a later change. Loading 100 messages covers typical short sessions. AshPostgres pagination is used internally (offset-based, ordered ASC) but exposed only as a plain list to the LiveView assign.

## Risks / Trade-offs

- **Large room history on mount**: If a room accumulates thousands of messages, the initial load of 100 is safe, but older history is inaccessible without pagination UI. → Accepted trade-off; pagination UI is a future change.
- **Mount/unmount system events under rapid reconnect**: If a client reconnects quickly (e.g., mobile network blip), a join+leave pair is written. → Acceptable noise at this stage; deduplication or debounce is a future concern.
- **PubSub fan-out at scale**: Broadcasting to all subscribers of a busy room is handled by the BEAM's message passing — efficient for small-to-medium rooms. Very large rooms (hundreds of simultaneous users) would need a different strategy. → Out of scope; this app targets small group chat.
- **camelCase conversion by LiveVue**: The automatic snake_case → camelCase transform in `push_event` payloads is a LiveVue convention. If a future key has ambiguous casing, it could cause a mismatch. → Document the convention; test with the actual prop names used in Vue.

## Migration Plan

1. Run AshPostgres migration generator after defining the `Message` resource to produce `priv/repo/migrations/<timestamp>_create_messages.exs`
2. Deploy the migration with `mix ecto.migrate` (additive-only, no data backfill needed)
3. The `messages` table is new; no existing data is affected
4. Rollback: drop the `messages` table (the migration `down/0` handles this automatically)
5. `ChatWindow.vue` is a new file; `RoomLive` is modified. Both changes are backward-compatible with Change 2's layout — the disabled input placeholder is replaced by the live input

## Open Questions

- Should `sender_name` on `Message` be validated against the guest session at creation time, or is trusting the socket assign sufficient? (Current plan: trust `socket.assigns.current_guest.name` — no separate validation.)
- Max message content length: enforce at the Ash resource level (e.g., 2000 chars) or leave unrestricted for now? (Current plan: unrestricted in this change; a validation can be added later without a migration.)
