## Purpose

Defines the Rooms capability: the `LetsChat.Chat` domain and `Room` resource, slug generation, the Lobby LiveView at `/rooms`, the Room shell LiveView at `/rooms/:slug`, the room creation modal, and the auth guard protecting both LiveViews.

---

## Requirements

### Requirement: Room resource with attributes
The system SHALL define an Ash resource `LetsChat.Chat.Room` within the `LetsChat.Chat` domain, with the following attributes: `id` (UUID primary key), `name` (string, required, non-empty), `slug` (string, required, unique, URL-safe identifier), `visibility` (atom enum `[:public, :private]`, default `:public`), `owner_session_id` (string, allow nil), `owner_user_id` (UUID, allow nil, references users with `on_delete: :nothing`), and `inserted_at` (AshPostgres.Timestamptz, auto-set).

#### Scenario: Room is created with valid name
- **WHEN** a user submits a valid room name
- **THEN** the system creates a Room record with all required attributes persisted to the database

#### Scenario: Room slug is unique
- **WHEN** two rooms are created with the same name
- **THEN** the second room receives a numeric suffix on its slug (e.g., `elixir-study-group-2`)

#### Scenario: Room visibility defaults to public
- **WHEN** a room is created without specifying visibility
- **THEN** the room is stored with `visibility: :public`

#### Scenario: Room owner fields allow nil
- **WHEN** a room is created without an authenticated user
- **THEN** `owner_user_id` is stored as nil without error

## Test Requirements

| Scenario | Test type | Module |
|---|---|---|
| Room is created with valid name | ExUnit (Ash resource test) | `LetsChat.Chat.RoomTest` |
| Room slug is unique | ExUnit (Ash resource test) | `LetsChat.Chat.RoomTest` |
| Room visibility defaults to public | ExUnit (Ash resource test) | `LetsChat.Chat.RoomTest` |
| Room owner fields allow nil | ExUnit (Ash resource test) | `LetsChat.Chat.RoomTest` |

---

### Requirement: Slug auto-generation from name
The system SHALL automatically generate a URL-safe slug from the room `name` on the `create` action using a `before_action` hook. The generation process SHALL apply `Slug.slugify/1` (from the `slug` hex package) to produce a lowercase, hyphen-separated identifier, then resolve any uniqueness collision by appending an incrementing numeric suffix (e.g., `-2`, `-3`).

#### Scenario: Basic slug generation
- **WHEN** a room is created with name "Elixir Study Group!"
- **THEN** the slug is set to `elixir-study-group`

#### Scenario: Collision produces numeric suffix
- **WHEN** a room named "Elixir Study Group" already exists with slug `elixir-study-group`
- **THEN** a new room with the same name receives slug `elixir-study-group-2`

#### Scenario: Slug is never editable after creation
- **WHEN** the room resource is examined for update actions
- **THEN** no update action allows changing the `slug` attribute

## Test Requirements

| Scenario | Test type | Module |
|---|---|---|
| Basic slug generation | ExUnit (Ash resource test) | `LetsChat.Chat.RoomTest` |
| Collision produces numeric suffix | ExUnit (Ash resource test) | `LetsChat.Chat.RoomTest` |
| Slug is never editable after creation | ExUnit (Ash resource test) | `LetsChat.Chat.RoomTest` |

---

### Requirement: Real-time slug availability check during creation
The system SHALL validate slug availability in real-time via `phx-change` with `debounce="300"` on the room name input in the creation modal. The LiveView SHALL derive a candidate slug from the current name value using the same `Slug.slugify/1` logic and check whether an exact match exists in the database. The result SHALL be displayed inline as a status indicator below the slug preview.

#### Scenario: Available slug shows positive feedback
- **WHEN** a user types a name whose derived slug does not exist in the database
- **THEN** the form shows a "✓ available" indicator below the slug preview

#### Scenario: Taken slug shows negative feedback and blocks submission
- **WHEN** a user types a name whose derived slug already exists in the database
- **THEN** the form shows a "✗ already taken" indicator below the slug preview and the submit button is disabled

#### Scenario: Availability check uses no suffix
- **WHEN** the slug availability check is performed
- **THEN** no numeric suffix is applied during the check — only the base slug is tested

## Test Requirements

| Scenario | Test type | Module |
|---|---|---|
| Available slug shows positive feedback | LiveViewTest | `LobbyLiveTest` |
| Taken slug shows negative feedback | LiveViewTest | `LobbyLiveTest` |
| Availability check uses no suffix | LiveViewTest | `LobbyLiveTest` |

---

### Requirement: Chat domain registration
The system SHALL define an Ash domain `LetsChat.Chat` using `Ash.Domain` with `otp_app: :lets_chat`, and SHALL register it in `config/config.exs` alongside `LetsChat.Accounts` in the `ash_domains` list.

#### Scenario: Domain is registered
- **WHEN** the application starts
- **THEN** `LetsChat.Chat` is included in the configured `ash_domains` list

#### Scenario: Room resource is reachable via domain
- **WHEN** calling `Ash.read(LetsChat.Chat.Room)` or any action via the domain
- **THEN** the call succeeds without domain resolution errors

## Test Requirements

| Scenario | Test type | Module |
|---|---|---|
| Domain is registered | ExUnit (application config test) | `LetsChat.Chat.RoomTest` |
| Room resource is reachable via domain | ExUnit (Ash resource test) | `LetsChat.Chat.RoomTest` |

---

### Requirement: Lobby LiveView at /rooms
The system SHALL provide a LiveView at `/rooms` (`LobbyLive`) that lists all public rooms ordered by `inserted_at DESC`. Each room card SHALL display the room `name`, `slug`, and a relative timestamp (e.g., "5 minutes ago"). When no rooms exist, the LiveView SHALL render an empty state with an explanatory text message directing users to the "Nova sala" header button; no secondary CTA button is present. The LiveView SHALL NOT display active/online member counts (deferred to Change 4). The LiveView SHALL render both `:info` and `:error` flash messages via `<.flash>` components and SHALL auto-dismiss them after 5 seconds using `Process.send_after/3` in the connected mount.

#### Scenario: Rooms are listed in reverse chronological order
- **WHEN** multiple public rooms exist
- **THEN** the lobby renders them ordered newest first

#### Scenario: Empty state is shown when no rooms exist
- **WHEN** no rooms are in the database
- **THEN** the lobby renders an empty state with an explanatory message directing users to the "Nova sala" header button (no secondary CTA button)

#### Scenario: Each card shows name, slug, and relative timestamp
- **WHEN** rooms are listed in the lobby
- **THEN** each card displays the room name, its slug, and a human-friendly relative timestamp derived from `inserted_at`

## Test Requirements

| Scenario | Test type | Module |
|---|---|---|
| Rooms are listed in reverse chronological order | LiveViewTest | `LobbyLiveTest` |
| Empty state is shown when no rooms exist | LiveViewTest | `LobbyLiveTest` |
| Each card shows name, slug, and relative timestamp | LiveViewTest | `LobbyLiveTest` |

---

### Requirement: Room creation modal on /rooms
The system SHALL provide a modal on the Lobby LiveView that allows users to create a new room. The modal SHALL contain a name input field (auto-focused on open) and a read-only slug preview updated on `phx-change`. The modal SHALL be opened by clicking "New room" in the lobby header. The URL `/rooms?new=true` SHALL open the modal directly on mount (deep-link support). Clicking outside the modal SHALL close it. After successful creation the LiveView SHALL redirect to `/rooms/:slug` via `push_navigate`.

#### Scenario: New room button opens modal
- **WHEN** a user clicks "New room" in the lobby header
- **THEN** the creation modal becomes visible without a page navigation

#### Scenario: Deep-link opens modal on mount
- **WHEN** a user navigates to `/rooms?new=true`
- **THEN** the creation modal is open on initial render

#### Scenario: Slug preview updates as user types
- **WHEN** a user types in the room name input
- **THEN** the slug preview below the input reflects the derived slug in real-time (debounced 300ms)

#### Scenario: Clicking outside modal closes it
- **WHEN** a user clicks outside the modal box (on the backdrop)
- **THEN** the modal closes without any navigation

#### Scenario: Successful creation redirects to room
- **WHEN** a user submits a valid room name
- **THEN** the room is created and the browser navigates to `/rooms/:slug` for the new room

## Test Requirements

| Scenario | Test type | Module |
|---|---|---|
| New room button opens modal | LiveViewTest | `LobbyLiveTest` |
| Deep-link opens modal on mount | LiveViewTest | `LobbyLiveTest` |
| Slug preview updates as user types | LiveViewTest | `LobbyLiveTest` |
| Clicking outside modal closes it | LiveViewTest | `LobbyLiveTest` |
| Successful creation redirects to room | LiveViewTest | `LobbyLiveTest` |

---

### Requirement: Room shell LiveView at /rooms/:slug
The system SHALL provide a LiveView at `/rooms/:slug` (`RoomLive`) that loads the Room by its slug on mount and renders a complete layout: a header with the room name and a "← Salas" link that navigates directly to `/rooms`, an empty message area with placeholder text, a participant sidebar placeholder, and a message input that is visible but `disabled`. If the slug does not match any room, the LiveView SHALL redirect to `/rooms` with a flash error message.

#### Scenario: Room shell renders with correct room name
- **WHEN** a user navigates to `/rooms/:slug` for an existing room
- **THEN** the header displays the room name

#### Scenario: Message input is visible but disabled
- **WHEN** a user views the room shell
- **THEN** the message input field is rendered in the DOM but has the `disabled` attribute set

#### Scenario: Unknown slug redirects to lobby
- **WHEN** a user navigates to `/rooms/nonexistent-slug`
- **THEN** the LiveView redirects to `/rooms` via `push_navigate` with a flash error ("Sala não encontrada.") in the navigation payload; the flash is displayed in the lobby and auto-dismissed after 5 seconds

#### Scenario: Leave button navigates back to lobby
- **WHEN** a user clicks the "← Salas" link in the room header
- **THEN** the browser navigates to `/rooms`

## Test Requirements

| Scenario | Test type | Module |
|---|---|---|
| Room shell renders with correct room name | LiveViewTest | `RoomLiveTest` |
| Message input is visible but disabled | LiveViewTest | `RoomLiveTest` |
| Unknown slug redirects to lobby | LiveViewTest | `RoomLiveTest` |
| Leave button navigates back to lobby | LiveViewTest | `RoomLiveTest` |

---

### Requirement: Auth guard for room LiveViews
The system SHALL protect both `LobbyLive` and `RoomLive` using the existing `require_guest_name` guard from `LiveUserAuth`, nested inside the `ash_authentication_live_session` scope in `router.ex`. Users without a guest session SHALL be redirected to `/?return_to=<destination>` before accessing any room route.

#### Scenario: Unauthenticated access to lobby is blocked
- **WHEN** a visitor without a guest session navigates to `/rooms`
- **THEN** they are redirected to `/?return_to=/rooms`

#### Scenario: Unauthenticated access to room shell is blocked
- **WHEN** a visitor without a guest session navigates to `/rooms/:slug`
- **THEN** they are redirected to `/?return_to=/rooms/:slug`

#### Scenario: Authenticated guest can access lobby
- **WHEN** a visitor with a valid guest session navigates to `/rooms`
- **THEN** the lobby renders without redirection

## Test Requirements

| Scenario | Test type | Module |
|---|---|---|
| Unauthenticated access to lobby is blocked | LiveViewTest | `LobbyLiveTest` |
| Unauthenticated access to room shell is blocked | LiveViewTest | `RoomLiveTest` |
| Authenticated guest can access lobby | LiveViewTest | `LobbyLiveTest` |
