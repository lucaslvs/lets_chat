## Context

The `chat-core` change (Change 3) delivers a functional chat room with a basic `ChatWindow.vue`. This change layers real-time presence tracking and interactivity on top of that foundation. Phoenix.Presence is already available in Phoenix 1.8 and integrates directly with PubSub — `LetsChat.PubSub` is already configured. LiveVue (~> 1.0) handles the LiveView ↔ Vue boundary: LiveView owns all state and pushes it to Vue as props; Vue owns all rendering and client-side UX.

No database migrations are needed — Presence is entirely in-memory and maintained by the BEAM across all connected nodes.

This change depends on:
- `rooms-lobby` (Change 2): provides the `Room` resource with a `slug` field used as the Presence topic key
- `chat-core` (Change 3): provides `RoomLive` and the base `ChatWindow.vue` that this change extends

## Goals / Non-Goals

**Goals:**
- Track which users are present in each room using `Phoenix.Presence` on topic `"room:{slug}"`
- Track room occupancy counts in the lobby using a second Presence topic `"lobby"`
- Surface a participant list (avatars + names) in the room sidebar, updated in real-time without database queries
- Implement a typing indicator: LiveView-debounced, propagated via Presence diff, rendered as CSS animation in `ChatWindow.vue`
- Enrich `ChatWindow.vue` with message enter animations (`TransitionGroup`), smooth auto-scroll, and a growing textarea
- Handle multiple browser tabs from the same user gracefully (one entry per user, not per connection)

**Non-Goals:**
- Persistent presence history or analytics
- Push notifications for users not currently connected
- Per-tab tracking or multi-tab indicators (though the data is available)
- Presence across multiple BEAM nodes (single-node deployment; extending to distributed is a future concern)
- Private room slug confidentiality in the lobby topic (accepted tradeoff — see Risks)

## Decisions

### Two Presence topics: `"room:{slug}"` and `"lobby"`

Rather than a single global topic or one topic per room for lobby counts, the design uses two purpose-scoped topics:

- `"room:{slug}"`: subscribed by `RoomLive` only when a user is in that room. Metadata: `%{name: name, avatar_initials: initials, avatar_color: color, typing: false}`. Carries everything the room UI needs.
- `"lobby"`: subscribed by both `RoomLive` (on mount, to register occupancy) and `LobbyLive` (to receive diffs). Metadata: `%{slug: slug}`. One subscription in `LobbyLive` receives all room occupancy changes — avoids O(N rooms) subscriptions.

Alternative considered: a single `"room:{slug}"` topic for both room and lobby. Rejected because `LobbyLive` would have to subscribe to every room topic separately, and each room would receive lobby-irrelevant metadata.

### `session_id` as the Presence key

Each LiveView session is identified by a `session_id` (derived from the socket's session). Using `session_id` as the Presence key means multiple browser tabs from the same user map to multiple metas under the same key. When building the participants list, the LiveView reads one entry per key — the user appears once regardless of how many tabs they have open.

Alternative considered: using the user's database ID directly. Rejected because it conflates identity with session and makes per-session metadata (e.g., per-tab typing state) ambiguous.

### Typing indicator debounce in LiveView, not in Vue

The debounce timer lives in `RoomLive` using `Process.send_after(self(), {:clear_typing, session_id}, 3_000)`. The timer ref is stored in assigns so it can be cancelled when the user types again or sends a message. This keeps Vue stateless with respect to timing logic.

Vue fires a `"typing"` phx-hook event on each keystroke. `handle_event("typing", _, socket)` calls `Presence.update` to set `typing: true`, cancels any existing timer, and schedules a new one.

Alternative considered: debouncing in Vue with `setTimeout`. Rejected because it would require Vue to manage state that should belong to the server, and it bypasses the LiveView event system.

### Participants and typing list: initial props + `push_event` for updates

`participants` and `typingUsers` are delivered to Vue using the same hybrid pattern as message history (Change 3): on mount, initial state is passed as LiveView assigns (which become Vue props); on every `presence_diff`, `RoomLive` calls `push_event("presence_update", %{participants: [...], typing_users: [...]})` and Vue updates reactively via `handleEvent("presence_update", ...)`. This keeps Vue's reactive state authoritative for presence (no stale prop/event race), is consistent with the message delivery pattern already established, and avoids a full LiveView re-render on every Presence change.

### CSS-only typing animation in `ChatWindow.vue`

The three-dot typing animation uses a `@keyframes bounce` CSS animation inline within `ChatWindow.vue`. No separate Vue component is introduced. This keeps the component surface small and avoids the overhead of mounting/unmounting a child component for a simple visual effect.

## Risks / Trade-offs

**Private room slug leaks in lobby topic**: When `RoomLive` registers presence on `"lobby"` with `%{slug: slug}`, any process subscribed to the `"lobby"` topic (including `LobbyLive` for all users) can see all slugs — including slugs for private rooms. → Accepted tradeoff for this change. Future mitigation: filter lobby presence by room visibility before broadcasting counts, or use separate topics per visibility tier.

**Presence state lost on LiveView crash**: If `RoomLive` crashes, the Presence entry is removed (BEAM monitors the process). The user's client will reconnect and re-register. During the reconnect window, the user appears offline. → Phoenix's LiveView reconnect is fast (< 1s on LAN); the UX impact is minimal and consistent with how Presence works in Phoenix by design.

**Typing timer accumulation**: If a user types rapidly in many sessions simultaneously, many `Process.send_after` messages could accumulate. Each new keystroke cancels the previous timer ref — only one outstanding timer per session at any time. → The timer ref stored in assigns prevents unbounded accumulation.

**`presence_diff` frequency under load**: In a busy room, every keystroke generates a `Presence.update` → broadcast → `handle_info` cycle for all subscribers. For typical chat rooms (< 100 concurrent users), this is acceptable. → If rooms grow large, consider rate-limiting `Presence.update` calls on the LiveView side (e.g., only update if `typing` state actually changed).

## Migration Plan

1. Define `LetsChatWeb.Presence` module (`use Phoenix.Presence`)
2. Add `LetsChatWeb.Presence` to the application supervision tree in `application.ex`
3. Update `RoomLive` to track presence on both topics at mount, handle `presence_diff` broadcasts, and implement the typing debounce flow
4. Update `LobbyLive` to subscribe to `"lobby"` and compute per-room counts from Presence metadata
5. Update `ChatWindow.vue` with `participants` and `typingUsers` props, `TransitionGroup` for messages, auto-scroll, textarea resize, and CSS typing animation

No database changes. No data migration. Rollback: revert the five files listed above; Presence module removal requires restarting the supervision tree.

## Open Questions

- Should `avatar_color` be generated deterministically from the user's ID (stable across sessions) or randomly on first Presence track (changes on reconnect)? Current plan: deterministic from user ID hash to avoid color flicker on reconnect.
- Typing indicator timeout: **resolved — 3 seconds** (`3_000ms`). Proposal and tasks aligned.
- Should `LobbyLive` show a count of `0` for rooms with no presence, or hide the badge entirely? Current plan: hide the badge when count is 0, show it (with count) when > 0.
