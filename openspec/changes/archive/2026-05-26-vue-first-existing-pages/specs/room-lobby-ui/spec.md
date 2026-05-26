## ADDED Requirements

### Requirement: RoomLobby Vue component
The system SHALL render the lobby (room list + creation modal) via `RoomLobby.vue` instead of HEEx. The component SHALL be mounted by `lobby_live.html.heex` reduced to a single `<.vue v-component="RoomLobby" rooms={@rooms} form={@form} show_modal={@show_modal} />`. The `LobbyLive` LiveView SHALL retain all existing event handlers (`open_modal`, `close_modal`, `validate`, `create_room`) unchanged. `RoomLobby.vue` SHALL fire these events via standard LiveView push mechanisms (`$live.pushEvent` or `phx-*` attributes on DOM elements).

#### Scenario: RoomLobby is mounted by LobbyLive
- **WHEN** an authenticated guest navigates to `/rooms`
- **THEN** the LiveView renders a single `<.vue v-component="RoomLobby" .../>` and the component mounts with `rooms`, `form`, and `showModal` props

#### Scenario: Room list renders all rooms passed as props
- **WHEN** the `rooms` prop contains 3 room objects
- **THEN** the component renders 3 room cards with name, slug, and relative timestamp

#### Scenario: Empty state is shown when rooms prop is empty
- **WHEN** `rooms` prop is an empty array
- **THEN** the component renders an empty state message directing users to create a new room

#### Scenario: Navigating to a room card fires a LiveView navigate
- **WHEN** a user clicks a room card
- **THEN** the browser navigates to `/rooms/:slug`

### Requirement: Animated creation modal in Vue
The system SHALL render the room creation modal inside `RoomLobby.vue` using Vue's `<Transition>` component for enter/leave animation. The modal SHALL be toggled by the `showModal` prop received from the LiveView. Opening and closing SHALL fire `open_modal` and `close_modal` events to the LiveView, which manages the authoritative modal state in `@show_modal`. The modal SHALL auto-focus the name input when it opens.

#### Scenario: Modal opens with animation when show_modal prop becomes true
- **WHEN** the LiveView assigns `show_modal: true` (e.g., after "open_modal" event)
- **THEN** the modal enters the DOM with a CSS transition applied by `<Transition>`

#### Scenario: Modal closes with animation when show_modal prop becomes false
- **WHEN** the LiveView assigns `show_modal: false` (e.g., after "close_modal" event)
- **THEN** the modal leaves the DOM with a CSS transition (not an abrupt removal)

#### Scenario: Clicking outside modal fires close_modal event
- **WHEN** a user clicks on the backdrop area outside the modal box
- **THEN** the component fires a `close_modal` LiveView event

#### Scenario: Name input is focused when modal opens
- **WHEN** the modal becomes visible (transition completes)
- **THEN** the name input field receives focus automatically

#### Scenario: Deep-link to /rooms?new=true opens modal immediately
- **WHEN** a user navigates directly to `/rooms?new=true`
- **THEN** the LiveView mounts with `show_modal: true` and the modal is rendered open on the first render

### Requirement: Reactive slug preview via Vue computed
The system SHALL compute the slug preview in `RoomLobby.vue` as a Vue `computed` property derived from the room name field in the `useLiveForm` state. The slug preview SHALL update on every keystroke without a round-trip to the server. The slug computation logic SHALL apply the same `slugify` transformation as the server (lowercase, hyphen-separated).

#### Scenario: Slug preview updates reactively as user types
- **WHEN** a user types in the room name input inside the creation modal
- **THEN** the slug preview below the input updates immediately without a server event

#### Scenario: Slug preview is empty when name is blank
- **WHEN** the room name field is empty
- **THEN** no slug preview text is shown

### Requirement: Asynchronous slug availability badge via push_event
The system SHALL display a slug availability badge (available/taken) inside `RoomLobby.vue` driven by `useLiveEvent("slug_availability", ...)`. The LiveView SHALL emit `push_event("slug_availability", %{available: bool})` from its `handle_event("validate", ...)` handler after computing slug availability. The Vue component SHALL track availability as a local `ref` that starts as `null` when the user begins typing (loading state) and is set on each event delivery.

#### Scenario: Badge starts as null (loading) when user begins typing
- **WHEN** a user has typed at least one character and the server has not yet responded
- **THEN** no availability badge is shown (null state — neither ✓ nor ✗)

#### Scenario: Available badge shown when server confirms slug is free
- **WHEN** the LiveView emits `push_event("slug_availability", %{available: true})`
- **THEN** the component shows a "✓ disponível" indicator below the slug preview

#### Scenario: Taken badge shown and submit disabled when slug is taken
- **WHEN** the LiveView emits `push_event("slug_availability", %{available: false})`
- **THEN** the component shows a "✗ já em uso" indicator and the submit button is disabled

#### Scenario: Submit button is disabled while availability is null or false
- **WHEN** `slugAvailable` ref is `null` or `false`
- **THEN** the submit button has `disabled` attribute set

### Requirement: useLiveForm for room creation
The system SHALL use `useLiveForm(props.form, { changeEvent: "validate", submitEvent: "create_room" })` in `RoomLobby.vue` to integrate the `AshPhoenix.Form` passed as the `form` prop. The `LobbyLive` LiveView SHALL pass the form via `form={@form}` on the `<.vue>` tag. After successful creation, `LobbyLive` SHALL call `push_navigate` to `/rooms/:slug`, and the form state in the component SHALL reset via LiveView re-render.

#### Scenario: Form validation fires via useLiveForm changeEvent
- **WHEN** a user changes a field in the room creation form
- **THEN** `useLiveForm` fires the `validate` event to the LiveView with debounce

#### Scenario: Form submission fires via useLiveForm submitEvent
- **WHEN** a user clicks the submit button (and slug is available)
- **THEN** `useLiveForm` fires the `create_room` event to the LiveView

#### Scenario: Server-side validation errors are shown inline
- **WHEN** the LiveView returns an error-state form after a failed submission
- **THEN** the component renders field errors from the updated `form` prop

## Test Requirements

### Requirement: RoomLobby Vue component

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| RoomLobby is mounted by LobbyLive | LiveViewTest | `LobbyLiveTest` | `LiveVue.Test.get_vue(view, name: "RoomLobby")` asserts component present with `rooms` prop |
| Room list renders all rooms passed as props | LiveViewTest | `LobbyLiveTest` | Seed DB with rooms; assert vue props contain correct room list |
| Empty state is shown when rooms prop is empty | LiveViewTest | `LobbyLiveTest` | Mount with no rooms; check component `rooms` prop is empty array |

### Requirement: Animated creation modal in Vue

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| Modal opens with animation when show_modal prop becomes true | LiveViewTest | `LobbyLiveTest` | Click open button; assert `LiveVue.Test.get_vue` returns `showModal: true` prop |
| Clicking outside modal fires close_modal event | LiveViewTest | `LobbyLiveTest` | Push close_modal event; assert `showModal` prop becomes false |
| Deep-link to /rooms?new=true opens modal immediately | LiveViewTest | `LobbyLiveTest` | Mount with `?new=true`; assert `showModal` prop is true on first render |

### Requirement: Asynchronous slug availability badge via push_event

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| Available badge shown when server confirms slug is free | LiveViewTest | `LobbyLiveTest` | Send validate event with unique name; assert `push_event("slug_availability", %{available: true})` was emitted |
| Taken badge shown and submit disabled when slug is taken | LiveViewTest | `LobbyLiveTest` | Pre-create room with slug; send validate; assert `push_event` emits `available: false` |

### Requirement: useLiveForm for room creation

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| Form validation fires via useLiveForm changeEvent | LiveViewTest | `LobbyLiveTest` | Send validate event; assert form prop updated in component |
| Successful creation redirects to room | LiveViewTest | `LobbyLiveTest` | Submit valid room; assert `push_navigate` to `/rooms/:slug` |
| Server-side validation errors are shown inline | LiveViewTest | `LobbyLiveTest` | Submit invalid form; assert component receives form with errors in props |
