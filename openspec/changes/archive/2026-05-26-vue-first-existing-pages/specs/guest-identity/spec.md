## MODIFIED Requirements

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
