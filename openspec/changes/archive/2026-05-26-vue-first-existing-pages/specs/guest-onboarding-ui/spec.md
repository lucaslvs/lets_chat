## ADDED Requirements

### Requirement: GuestOnboarding Vue component
The system SHALL render the guest onboarding form via `GuestOnboarding.vue` instead of HEEx. The component SHALL be mounted by `home_live.html.heex` reduced to a single `<.vue v-component="GuestOnboarding" />` call. The component SHALL receive the `return_to` path and `guest_session_id` as props. The LiveView (`HomeLive`) SHALL retain all event handlers (`validate`, `submit`) unchanged; the Vue component SHALL fire these events via standard `phx-change` and `phx-submit` on the form element.

#### Scenario: GuestOnboarding is mounted by HomeLive
- **WHEN** an unauthenticated user without a guest session navigates to `/`
- **THEN** the LiveView renders a single `<.vue v-component="GuestOnboarding" .../>` and the component mounts successfully

#### Scenario: Form events reach HomeLive handlers
- **WHEN** a user types in the name field
- **THEN** a `phx-change` event with `%{"name" => value}` reaches `HomeLive.handle_event("validate", ...)`

#### Scenario: Submit event triggers redirect
- **WHEN** a user submits a valid non-empty name
- **THEN** a `phx-submit` event reaches `HomeLive.handle_event("submit", ...)` and the LiveView redirects to `/session/guest`

### Requirement: Reactive avatar preview via Vue computed
The system SHALL compute the avatar preview entirely in `GuestOnboarding.vue` as a Vue `computed` property derived from the name input `ref`. The avatar SHALL update on every keystroke without any server round-trip. The initials and color logic SHALL mirror the server-side `avatar_initials/1` and `avatar_color/1` helper behavior: up to 2 initials, deterministic color from name hash.

#### Scenario: Avatar preview updates on every keystroke without a server event
- **WHEN** a user types in the name field
- **THEN** the avatar preview updates immediately (same microtask) with no `phx-change` round-trip required for the avatar itself

#### Scenario: Single-word name shows one initial in preview
- **WHEN** the user has typed a single word in the name field
- **THEN** the avatar preview shows the first letter in uppercase

#### Scenario: Multi-word name shows two initials in preview
- **WHEN** the user has typed two or more words separated by a space
- **THEN** the avatar preview shows the first letter of the first and last words in uppercase

#### Scenario: Empty name shows placeholder
- **WHEN** the name field is empty
- **THEN** the avatar preview shows "?" as the placeholder initial

### Requirement: Inline validation error display
The system SHALL display a validation error message inline below the name input when the submitted name is blank. The error state SHALL be driven by a prop received from the LiveView after a failed `submit` event — it is NOT computed locally in Vue.

#### Scenario: Error message is shown after blank submit
- **WHEN** the user submits an empty or whitespace-only name
- **THEN** the LiveView pushes an updated `error` prop and the component renders the error message below the input

#### Scenario: Error clears when user starts typing again
- **WHEN** a `phx-change` "validate" event fires (user types after an error)
- **THEN** `HomeLive` assigns `error: nil` and the component re-renders without the error message

## Test Requirements

### Requirement: GuestOnboarding Vue component

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| GuestOnboarding is mounted by HomeLive | LiveViewTest | `HomeLiveTest` | Use `LiveVue.Test.get_vue(view, name: "GuestOnboarding")` to assert component is present with correct props |
| Form events reach HomeLive handlers | LiveViewTest | `HomeLiveTest` | Send `phx-change` event; assert `handle_event("validate", ...)` is called (via resulting assigns) |
| Submit event triggers redirect | LiveViewTest | `HomeLiveTest` | Submit form with valid name; assert redirect to `/session/guest` |

### Requirement: Reactive avatar preview via Vue computed

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| Avatar preview updates on every keystroke without a server event | LiveViewTest | `HomeLiveTest` | Verify that Vue component receives no `name` prop from server (it's local state); test is behavioral |
| Single-word name shows one initial in preview | Vitest (unit) | `GuestOnboarding.spec.ts` | Mount component with `name = "Alice"`; assert avatar shows "A" |
| Multi-word name shows two initials in preview | Vitest (unit) | `GuestOnboarding.spec.ts` | Mount with `name = "Alice Smith"`; assert avatar shows "AS" |
| Empty name shows placeholder | Vitest (unit) | `GuestOnboarding.spec.ts` | Mount with `name = ""`; assert avatar shows "?" |

### Requirement: Inline validation error display

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| Error message is shown after blank submit | LiveViewTest | `HomeLiveTest` | Submit blank form; assert `LiveVue.Test.get_vue` returns component with `error` prop non-nil |
| Error clears when user starts typing again | LiveViewTest | `HomeLiveTest` | Submit blank, then send validate event; assert `error` prop is nil |
