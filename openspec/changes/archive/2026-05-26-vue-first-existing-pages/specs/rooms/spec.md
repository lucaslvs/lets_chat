## MODIFIED Requirements

### Requirement: Real-time slug availability check during creation
The system SHALL validate slug availability in real-time during room name input in the creation modal. The LiveView SHALL derive a candidate slug from the current name value using `Slug.slugify/1` and check whether an exact match exists in the database. The result SHALL be communicated to the Vue component via `push_event("slug_availability", %{available: bool})` — NOT via socket assigns. The `RoomLobby.vue` component SHALL listen with `useLiveEvent("slug_availability", ...)` and update a local `ref` to drive the availability badge and submit button state.

The submit button SHALL be disabled when `slugAvailable` ref is `null` (check in flight) or `false` (slug taken).

#### Scenario: Available slug shows positive feedback
- **WHEN** a user types a name whose derived slug does not exist in the database
- **THEN** the LiveView emits `push_event("slug_availability", %{available: true})` and the Vue component shows a "✓ disponível" indicator below the slug preview

#### Scenario: Taken slug shows negative feedback and blocks submission
- **WHEN** a user types a name whose derived slug already exists in the database
- **THEN** the LiveView emits `push_event("slug_availability", %{available: false})` and the component shows a "✗ já em uso" indicator with the submit button disabled

#### Scenario: Availability check uses no suffix
- **WHEN** the slug availability check is performed
- **THEN** no numeric suffix is applied during the check — only the base slug is tested

#### Scenario: Submit is disabled while availability result is pending
- **WHEN** the user has typed a name but the `push_event` response has not yet arrived
- **THEN** the submit button SHALL be disabled (slugAvailable ref is null)

---

### Requirement: Lobby LiveView at /rooms
The system SHALL provide a LiveView at `/rooms` (`LobbyLive`) that lists all public rooms ordered by `inserted_at DESC`. Room data SHALL be passed as the `rooms` prop to `RoomLobby.vue`. Each room object SHALL include `name`, `slug`, and `inserted_at` so the Vue component can compute relative timestamps locally. When no rooms exist, the Vue component SHALL render an empty state with an explanatory text message directing users to the "Nova sala" header button. The LiveView SHALL NOT display active/online member counts (deferred to Change 4). Flash messages SHALL be handled by the HEEx wrapper or `AppShell.vue` — NOT inside `RoomLobby.vue`.

#### Scenario: Rooms are listed in reverse chronological order
- **WHEN** multiple public rooms exist
- **THEN** `LobbyLive` passes them ordered newest first in the `rooms` prop; `RoomLobby.vue` renders them in that order

#### Scenario: Empty state is shown when no rooms exist
- **WHEN** no rooms are in the database
- **THEN** `RoomLobby.vue` renders an empty state with an explanatory message directing users to the "Nova sala" button (no secondary CTA button)

#### Scenario: Each card shows name, slug, and relative timestamp
- **WHEN** rooms are listed in the lobby
- **THEN** each card displays the room name, its slug, and a human-friendly relative timestamp computed in Vue from `inserted_at`

---

### Requirement: Room creation modal on /rooms
The system SHALL provide a room creation modal rendered inside `RoomLobby.vue` using Vue's `<Transition>` for animation. Modal state (`show_modal`) SHALL remain authoritative in the LiveView and SHALL be passed as the `showModal` prop. The LiveView SHALL handle all form submission logic via existing `open_modal`, `close_modal`, `validate`, and `create_room` event handlers. After successful creation the LiveView SHALL redirect to `/rooms/:slug` via `push_navigate`.

#### Scenario: New room button opens modal
- **WHEN** a user clicks "Nova sala" in the lobby header
- **THEN** the Vue component fires an `open_modal` event; the LiveView assigns `show_modal: true` and updates the prop; the modal becomes visible with a CSS transition

#### Scenario: Deep-link opens modal on mount
- **WHEN** a user navigates to `/rooms?new=true`
- **THEN** the creation modal is open on initial render (`showModal` prop is true from the start)

#### Scenario: Slug preview updates as user types
- **WHEN** a user types in the room name input
- **THEN** the slug preview updates immediately via Vue computed (no server round-trip for the preview display itself)

#### Scenario: Clicking outside modal closes it
- **WHEN** a user clicks on the backdrop area outside the modal box
- **THEN** the Vue component fires a `close_modal` event; the LiveView assigns `show_modal: false`; the modal leaves the DOM with a CSS transition

#### Scenario: Successful creation redirects to room
- **WHEN** a user submits a valid room name (slug is available)
- **THEN** the room is created server-side and the browser navigates to `/rooms/:slug` for the new room
