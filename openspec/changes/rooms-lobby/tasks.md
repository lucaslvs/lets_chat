## Execution Order

```
[1] Dependencies & Configuration
     └── [2] Chat Domain
              └── [3] Room Resource (+ migration)
                       ├── [5] Lobby LiveView    ← parallel with [6]
                       └── [6] Room Shell LiveView ← parallel with [5]
                                └── [4] Router   ← after [5] + [6]
                                         └── [7] Verification
```

> Sub-agent opportunity: after completing sections 1–3, spawn two parallel sub-agents — one for LobbyLive (section 5) and one for RoomLive shell (section 6).

---

## 1. Dependencies & Configuration

- [ ] 1.1 Add `{:slug, "~> 1.1"}` to `mix.exs` and run `mix deps.get`
- [ ] 1.2 Add `LetsChat.Chat` to `ash_domains` list in `config/config.exs`

## 2. Chat Domain

- [ ] 2.1 Create `lib/lets_chat/chat.ex` defining `LetsChat.Chat` as an `Ash.Domain` with `otp_app: :lets_chat` and authorizing `LetsChat.Chat.Room`

## 3. Room Resource

- [ ] 3.1 Create `lib/lets_chat/chat/room.ex` with all required attributes: `id` (UUID primary key), `name` (string, required, non-empty), `slug` (string, required, unique), `visibility` (atom enum `[:public, :private]`, default `:public`), `owner_session_id` (string, allow nil), `owner_user_id` (UUID, allow nil), `inserted_at` (AshPostgres.Timestamptz)
- [ ] 3.2 Add `AshPostgres.DataLayer` to the `Room` resource with correct table name (`rooms`) and `public_simple_equality` on `slug`
- [ ] 3.3 Add a `:list` action that reads all rooms ordered `inserted_at: :desc`
- [ ] 3.4 Add a `:get_by_slug` action that accepts `slug` and returns a single room (or error when not found)
- [ ] 3.5 Implement the `before_action` hook on the `:create` action that calls `Slug.slugify/1` on `name`, then resolves uniqueness collisions by querying for existing slugs and appending an incrementing numeric suffix
- [ ] 3.6 Add `owner_user_id` as a foreign key reference to the users table with `null: true` and `on_delete: :nothing`
- [ ] 3.7 Run `mix ash.codegen rooms_lobby` to generate the AshPostgres migration and inspect the output
- [ ] 3.8 Run `mix ecto.migrate` to apply the migration

## 4. Router

- [ ] 4.1 Add `live "/rooms", LobbyLive` and `live "/rooms/:slug", RoomLive` inside the existing `ash_authentication_live_session` scope in `router.ex`, guarded by `require_guest_name`

## 5. Lobby LiveView

- [ ] 5.1 Create `lib/lets_chat_web/live/lobby_live.ex` with `mount/3` that loads `@rooms` via the `:list` action and sets `@show_modal` from the `?new=true` query param
- [ ] 5.2 Implement `handle_params/3` to toggle `@show_modal` based on the `new` query param without page navigation
- [ ] 5.3 Implement `handle_event("open_modal", ...)` and `handle_event("close_modal", ...)` to toggle `@show_modal` and initialize `@form` from an `AshPhoenix.Form` for room creation
- [ ] 5.4 Implement `handle_event("validate", ...)` that derives `@slug_preview` via `Slug.slugify/1` and sets `@slug_available` by checking slug existence with a lightweight `Ash.exists?` or `Ash.count` query (debounced in template with `phx-debounce="300"`)
- [ ] 5.5 Implement `handle_event("create_room", ...)` that submits the form, and on success calls `push_navigate` to `/rooms/:slug`
- [ ] 5.6 Create `lib/lets_chat_web/live/lobby_live.html.heex` (or inline `render/1`) with the room list ordered newest first, each card showing `name`, `slug`, and relative timestamp via `Calendar.strftime` or a helper
- [ ] 5.7 Add the empty state view (shown when `@rooms` is empty) with a "Create the first room" CTA that opens the creation modal
- [ ] 5.8 Add the creation modal markup controlled by `@show_modal`, containing the name input with `phx-change="validate"` and `phx-debounce="300"`, a read-only slug preview, and the inline `@slug_available` status indicator

### Mobile-First Notes (Lobby LiveView)

- Room list uses a stacked single-column layout by default; upgrade to a multi-column grid only with explicit responsive classes (e.g., `sm:grid-cols-2 lg:grid-cols-3`) on top of a mobile base class
- Each room card must have a minimum tap target height of 44px; use `min-h-[44px]` or equivalent padding
- The "New room" and "Create the first room" buttons must meet the 44px minimum touch target requirement
- All interactive elements (buttons, links) must have a mobile base style before any `md:` or `lg:` override

## 6. Room Shell LiveView

- [ ] 6.1 Create `lib/lets_chat_web/live/room_live.ex` with `mount/3` that loads the `Room` by `slug` param using the `:get_by_slug` action, and redirects to `/rooms` with a flash error if not found
- [ ] 6.2 Implement `handle_event("leave", ...)` that calls `push_navigate` to `/rooms`
- [ ] 6.3 Create `lib/lets_chat_web/live/room_live.html.heex` (or inline `render/1`) with the complete layout: header (room name + "Leave" button wired to the leave event), empty message area with placeholder text and a tooltip/helper ("Messaging coming soon"), participant sidebar placeholder, and message input with `disabled` attribute set

### Mobile-First Notes (Room Shell LiveView)

- The room layout must stack vertically on mobile: header on top, full-width message area below, sidebar hidden or collapsed by default (revealed by toggle) on small screens
- The "Leave" button in the header must meet the 44px minimum touch target size
- The disabled message input must still be full-width on mobile and visually clear that it is inactive
- Navigation from lobby to room and back via the "Leave" button must work correctly on viewport widths below 640px
- No `md:` or `lg:` class may appear without a corresponding mobile base class defined first

## 7. Verification

- [ ] 7.1 Run `mix test` and fix any failures — the suite must cover all BDD scenarios defined in `specs/rooms/spec.md` (Room resource, slug generation, slug availability, lobby listing, modal creation, room shell, and auth guard)
- [ ] 7.2 Smoke test in dev: create a room, verify slug auto-generation, verify real-time slug availability check, verify redirect to room shell, verify unknown slug redirects to lobby with flash error
- [ ] 7.3 Verify unauthenticated access to `/rooms` and `/rooms/:slug` redirects to `/?return_to=<path>`
- [ ] 7.4 Run `mix precommit` and resolve any remaining issues

## 8. Tests

### ExUnit / LiveViewTest

- [ ] 8.1 `LetsChat.Chat.RoomTest` — Room is created with valid name (covers Scenario: Room is created with valid name)
- [ ] 8.2 `LetsChat.Chat.RoomTest` — Slug uniqueness collision appends numeric suffix (covers Scenario: Collision produces numeric suffix and Scenario: Room slug is unique)
- [ ] 8.3 `LetsChat.Chat.RoomTest` — Room visibility defaults to `:public` (covers Scenario: Room visibility defaults to public)
- [ ] 8.4 `LetsChat.Chat.RoomTest` — `owner_user_id` is stored as nil without error (covers Scenario: Room owner fields allow nil)
- [ ] 8.5 `LetsChat.Chat.RoomTest` — Basic slug generation from "Elixir Study Group!" produces `elixir-study-group` (covers Scenario: Basic slug generation)
- [ ] 8.6 `LetsChat.Chat.RoomTest` — No update action allows changing the `slug` attribute (covers Scenario: Slug is never editable after creation)
- [ ] 8.7 `LetsChat.Chat.RoomTest` — `LetsChat.Chat` domain is registered in `ash_domains` and Room is reachable via the domain (covers Scenario: Domain is registered and Scenario: Room resource is reachable via domain)
- [ ] 8.8 `LobbyLiveTest` — Rooms are listed in reverse chronological order (covers Scenario: Rooms are listed in reverse chronological order)
- [ ] 8.9 `LobbyLiveTest` — Empty state renders with "Create the first room" CTA when no rooms exist (covers Scenario: Empty state is shown when no rooms exist)
- [ ] 8.10 `LobbyLiveTest` — Each card shows name, slug, and relative timestamp (covers Scenario: Each card shows name, slug, and relative timestamp)
- [ ] 8.11 `LobbyLiveTest` — Clicking "New room" opens the creation modal without page navigation (covers Scenario: New room button opens modal)
- [ ] 8.12 `LobbyLiveTest` — Navigating to `/rooms?new=true` opens the modal on initial render (covers Scenario: Deep-link opens modal on mount)
- [ ] 8.13 `LobbyLiveTest` — Typing in the name input updates the slug preview (covers Scenario: Slug preview updates as user types)
- [ ] 8.14 `LobbyLiveTest` — Available slug candidate shows `✓ available` indicator (covers Scenario: Available slug shows positive feedback)
- [ ] 8.15 `LobbyLiveTest` — Taken slug candidate shows `✗ already taken` indicator (covers Scenario: Taken slug shows negative feedback)
- [ ] 8.16 `LobbyLiveTest` — Availability check uses only the base slug with no numeric suffix (covers Scenario: Availability check uses no suffix)
- [ ] 8.17 `LobbyLiveTest` — Successful room creation redirects to `/rooms/:slug` (covers Scenario: Successful creation redirects to room)
- [ ] 8.18 `RoomLiveTest` — Room header displays the correct room name (covers Scenario: Room shell renders with correct room name)
- [ ] 8.19 `RoomLiveTest` — Message input is present in the DOM and has the `disabled` attribute (covers Scenario: Message input is visible but disabled)
- [ ] 8.20 `RoomLiveTest` — Unknown slug redirects to `/rooms` with a flash error (covers Scenario: Unknown slug redirects to lobby)
- [ ] 8.21 `RoomLiveTest` — Clicking "Leave" navigates to `/rooms` (covers Scenario: Leave button navigates back to lobby)
- [ ] 8.22 `LobbyLiveTest` / `RoomLiveTest` — Unauthenticated visitor accessing `/rooms` is redirected to `/?return_to=/rooms` (covers Scenario: Unauthenticated access to lobby is blocked)
- [ ] 8.23 `LobbyLiveTest` / `RoomLiveTest` — Unauthenticated visitor accessing `/rooms/:slug` is redirected to `/?return_to=/rooms/:slug` (covers Scenario: Unauthenticated access to room shell is blocked)
- [ ] 8.24 `LobbyLiveTest` — Authenticated guest can access `/rooms` without redirection (covers Scenario: Authenticated guest can access lobby)

### Vitest (Vue components)

No Vue components are introduced in this change. If any Vue components are extracted for the room card or modal, add corresponding Vitest tests at that time.
