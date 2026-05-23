## ADDED Requirements

### Requirement: Room can be created as private
When creating a new room, the creator SHALL be able to choose between `public` and `private` visibility. If `private` is selected, the system SHALL automatically generate a permanent `invite_token` (UUID) and store it on the `Room` record.

#### Scenario: Creating a public room (default)
- **WHEN** a user submits the new-room form without selecting private visibility
- **THEN** the room is created with `visibility: :public` and no `invite_token` is set

#### Scenario: Creating a private room
- **WHEN** a user selects private visibility and submits the new-room form
- **THEN** the room is created with `visibility: :private` and a unique UUID `invite_token` is persisted on the record

#### Scenario: Invite token uniqueness
- **WHEN** a private room is created
- **THEN** the generated `invite_token` SHALL be unique across all rooms

### Requirement: Post-creation invite link page
After successfully creating a private room, the system SHALL display the invite magic link to the creator so it can be shared.

#### Scenario: Invite link displayed after creation
- **WHEN** a private room is created
- **THEN** the UI displays the full invite URL in the format `/rooms/:slug/join/:token` with a "Copy link" button and an "Enter now" button

#### Scenario: Copying the invite link
- **WHEN** the creator clicks the "Copy link" button
- **THEN** the full invite URL is copied to the clipboard

#### Scenario: Entering the room immediately
- **WHEN** the creator clicks the "Enter now" button
- **THEN** the creator is navigated directly into the private room

### Requirement: Access via invite magic link
The system SHALL expose a route `/rooms/:slug/join/:token` that validates the invite token and grants the visitor access to the private room.

#### Scenario: Valid token — access granted
- **WHEN** a visitor navigates to `/rooms/:slug/join/:token` with a matching `invite_token`
- **THEN** the system adds the room's `id` to the visitor's session `:authorized_rooms` list and redirects to `/rooms/:slug`

#### Scenario: Invalid or mismatched token
- **WHEN** a visitor navigates to `/rooms/:slug/join/:token` and the token does not match the room's `invite_token`
- **THEN** the system redirects to the lobby with a flash error message

#### Scenario: Token for a non-existent room
- **WHEN** a visitor navigates to `/rooms/:slug/join/:token` and the slug does not correspond to any room
- **THEN** the system redirects to the lobby with a flash error message

### Requirement: Invite token is permanent
The `invite_token` SHALL not expire while the room exists. Any visitor who obtains the link can use it to gain access at any time.

#### Scenario: Repeated use of the same invite link
- **WHEN** multiple different visitors navigate to the same `/rooms/:slug/join/:token` URL
- **THEN** each visitor is individually granted access and added to their own session's `:authorized_rooms`

#### Scenario: Re-using the link after a page reload
- **WHEN** a visitor who previously used the invite link reloads `/rooms/:slug`
- **THEN** their session still contains the room ID in `:authorized_rooms` and they retain access without re-visiting the join URL

## Test Requirements

| Scenario | Test type | Test ID | Notes |
|---|---|---|---|
| Creating a public room (default) | LiveViewTest (`RoomNewLiveTest`) | T-PR1 | Submit form without private visibility selected; assert `invite_token: nil` on created room |
| Creating a private room | LiveViewTest (`RoomNewLiveTest`) | T-PR2 | Submit form with `visibility: :private`; assert `invite_token` is a non-nil UUID string |
| Invite token uniqueness | ExUnit (`RoomTest`) | T-PR2 | Create two private rooms; assert their `invite_token` values differ |
| Invite link displayed after creation | LiveViewTest (`RoomNewLiveTest`) | T-PR3 | After private room creation; assert invite URL, "Copy link" button, and "Enter now" button rendered |
| Copying the invite link | Vitest (`InviteLinkDisplay.test.ts`) | T-V4 | Mock clipboard API; click "Copy link"; assert `navigator.clipboard.writeText` called with correct URL |
| Entering the room immediately | LiveViewTest (`RoomNewLiveTest`) | T-PR3 | Click "Enter now"; assert redirect to `/rooms/:slug` |
| Valid token — access granted | ConnTest (`RoomControllerTest`) | T-PR4 | GET `/rooms/:slug/join/:token` with matching token; assert session `:authorized_rooms` contains room ID and response redirects to `/rooms/:slug` |
| Invalid or mismatched token | ConnTest (`RoomControllerTest`) | T-PR5 | GET with wrong token; assert redirect to lobby and flash error present |
| Token for a non-existent room | ConnTest (`RoomControllerTest`) | T-PR6 | GET with unknown slug; assert redirect to lobby and flash error present |
| Repeated use of the same invite link | ConnTest (`RoomControllerTest`) | T-PR7 | Two separate conns use same URL; assert each conn's session independently contains room ID |
| Re-using the link after a page reload | ConnTest (`RoomControllerTest`) | T-PR4 | Covered by T-PR4 — session persists between requests by default in Plug tests |
| Full invite-link flow (integration) | LiveViewTest (integration) | T-INT2 | Create private room, visit invite URL, assert LV mounts in `:in_room` state |
