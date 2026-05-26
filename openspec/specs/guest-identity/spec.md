# Guest Identity Spec

## Purpose

Defines how the system identifies visitors before they enter a chat room. A guest must provide a display name (or be an authenticated user) to access protected routes. The identity is stored in a minimal Phoenix cookie session and is used to compute a visual avatar at render time — no identity data is persisted beyond the session.

---

## Requirements

### Requirement: Guest session creation
The system SHALL collect a display name from a new visitor and persist a minimal guest identity in the Phoenix cookie session before allowing access to rooms. The session SHALL store a `guest_session_id` (UUID, generated once per browser session) and `guest_name` (the submitted display name). No other identity data SHALL be stored in the session.

#### Scenario: New visitor submits a name
- **WHEN** an unauthenticated user without an existing guest session visits `/` and submits a non-empty display name
- **THEN** the system SHALL persist `guest_session_id` and `guest_name` in the session cookie and redirect the user to `/rooms` (or the `return_to` path if present)

#### Scenario: Blank name is rejected
- **WHEN** an unauthenticated user submits an empty or whitespace-only name
- **THEN** the system SHALL NOT persist the session and SHALL display a validation error inline, keeping the user on the onboarding form

#### Scenario: Returning guest bypasses onboarding
- **WHEN** an unauthenticated user with `guest_name` already present in their session navigates to `/`
- **THEN** the system SHALL redirect to `/rooms` without showing the onboarding form

#### Scenario: `guest_session_id` is stable across submits
- **WHEN** a user opens the home page and a `guest_session_id` does not yet exist in their session
- **THEN** the system SHALL generate a UUID and write it to the session on mount, before form submission

---

### Requirement: Avatar computation from name
The system SHALL compute a visual avatar for every participant entirely from their display name at render time. Avatars SHALL consist of up to 2 initials extracted from the name and a background color chosen deterministically from the DaisyUI semantic color palette using `:erlang.phash2/2`. Avatar data SHALL NOT be stored in the session or database.

On the onboarding form (`GuestOnboarding.vue`), avatar preview SHALL be computed as a Vue `computed` property derived from the local name input `ref`, with no server round-trip. The initials and color logic in Vue SHALL mirror the server-side `avatar_initials/1` and `avatar_color/1` helper behavior.

#### Scenario: Single-word name produces one initial
- **WHEN** the display name is a single word (e.g. "Alice")
- **THEN** the avatar SHALL display the first letter in uppercase ("A")

#### Scenario: Multi-word name produces two initials
- **WHEN** the display name contains two or more words (e.g. "Alice Smith")
- **THEN** the avatar SHALL display the first letter of the first and last words in uppercase ("AS")

#### Scenario: Same name always yields same color
- **WHEN** the avatar color is computed for a given name on any render, on any node
- **THEN** the resulting DaisyUI color token SHALL be identical across renders

#### Scenario: Avatar preview updates live during input without server round-trip
- **WHEN** a user types in the name field on the onboarding form (`GuestOnboarding.vue`)
- **THEN** the avatar preview SHALL update on every keystroke via Vue computed (no `phx-change` event required for the avatar update itself), reflecting current initials and color

---

### Requirement: Authenticated user identity upgrade
The system SHALL transparently use an authenticated user's identity when present, bypassing the guest onboarding form. The display name SHALL be derived from the authenticated user's email address, and the avatar SHALL use a Gravatar URL when available, falling back to the initials-based avatar otherwise.

#### Scenario: Authenticated user is redirected past onboarding
- **WHEN** an authenticated user navigates to `/`
- **THEN** the system SHALL redirect them to `/rooms` (or the `return_to` path) without displaying the onboarding form

#### Scenario: Authenticated user's display name is their email
- **WHEN** an authenticated user is present in any LiveView that renders identity information
- **THEN** their display name SHALL be the email address from `current_user.email`

#### Scenario: Gravatar URL is used as avatar src when provided
- **WHEN** an authenticated user has a Gravatar URL available
- **THEN** the `<.avatar>` component SHALL render an `<img>` tag with the Gravatar URL as `src` instead of the initials div

---

### Requirement: Session guard with return_to preservation
The system SHALL protect all `/rooms/*` routes by requiring a guest name or authenticated user. When a visitor without identity attempts to access a protected route, the system SHALL redirect to `/?return_to=<original_path>` and resume navigation to the original destination after successful onboarding.

#### Scenario: Unauthenticated visitor without name is redirected
- **WHEN** a user without `guest_name` in session and without `current_user` navigates to `/rooms` or any sub-path
- **THEN** the system SHALL redirect to `/?return_to=/rooms/<subpath>` and not render the protected LiveView

#### Scenario: Onboarding with return_to resumes the original destination
- **WHEN** a user completes onboarding while `return_to` is set in the URL params
- **THEN** after successful session write the system SHALL navigate to the `return_to` path instead of the default `/rooms`

#### Scenario: `return_to` rejects external URLs
- **WHEN** the `return_to` query param contains a URL with a host component (e.g. `https://evil.com`)
- **THEN** the system SHALL ignore the value and use the default `/rooms` redirect instead

#### Scenario: Authenticated user satisfies the guard
- **WHEN** an authenticated user navigates to a protected route
- **THEN** the guard SHALL allow access without checking for `guest_name` in the session

---

## Test Requirements

### Requirement: Guest session creation

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| New visitor submits a name | LiveViewTest | `HomeLiveTest` | Assert session contains `guest_session_id` and `guest_name`; assert redirect to `/rooms` |
| Blank name is rejected | LiveViewTest | `HomeLiveTest` | Assert no session write; assert error message rendered in the form |
| Returning guest bypasses onboarding | LiveViewTest | `HomeLiveTest` | Seed session with `guest_name`; assert redirect to `/rooms` on mount |
| `guest_session_id` is stable across submits | LiveViewTest | `HomeLiveTest` | Assert UUID written to session on `mount/3` before any form event |

### Requirement: Avatar computation from name

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| Single-word name produces one initial | ExUnit (unit) | `CoreComponentsTest` | `avatar_initials("Alice") == "A"` |
| Multi-word name produces two initials | ExUnit (unit) | `CoreComponentsTest` | `avatar_initials("Alice Smith") == "AS"` |
| Same name always yields same color | ExUnit (unit) | `CoreComponentsTest` | Call `avatar_color/1` multiple times with the same input; assert identical output |
| Avatar preview updates live during input without server round-trip | LiveViewTest | `HomeLiveTest` | Verify Vue component receives no `name` prop from server (local state); avatar updates are behavioral via Vue computed |

### Requirement: Authenticated user identity upgrade

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| Authenticated user is redirected past onboarding | LiveViewTest | `HomeLiveTest` | Mount with `current_user` in session; assert redirect to `/rooms` |
| Authenticated user's display name is their email | LiveViewTest | `HomeLiveTest` or rendering test | Assert email rendered where display name appears |
| Gravatar URL is used as avatar src when provided | ExUnit (unit) | `CoreComponentsTest` | Render `<.avatar src="https://gravatar.com/...">` and assert `<img>` tag present |

### Requirement: Session guard with return_to preservation

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| Unauthenticated visitor without name is redirected | LiveViewTest | `LiveUserAuthTest` | Mount protected LiveView without identity; assert redirect to `/?return_to=…` |
| Onboarding with return_to resumes the original destination | LiveViewTest | `HomeLiveTest` | Submit form with `return_to` param; assert `push_navigate` goes to that path |
| `return_to` rejects external URLs | ExUnit (unit) | `HomeLiveTest` or `LiveUserAuthTest` | Pass `return_to=https://evil.com`; assert fallback to `/rooms` |
| Authenticated user satisfies the guard | LiveViewTest | `LiveUserAuthTest` | Mount with `current_user`; assert `:cont` without checking `guest_name` |
