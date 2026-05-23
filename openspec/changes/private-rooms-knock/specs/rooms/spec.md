## ADDED Requirements

### Requirement: Room stores invite_token for private rooms
The `Room` resource SHALL have an `invite_token` attribute (UUID string) that is auto-generated when a room is created with `visibility: :private` and remains null for public rooms.

#### Scenario: invite_token generated on private room creation
- **WHEN** a room is created with `visibility: :private`
- **THEN** the `Room` record has a non-null `invite_token` UUID stored in the database

#### Scenario: invite_token is null for public rooms
- **WHEN** a room is created with `visibility: :public`
- **THEN** the `Room` record has `invite_token: nil`

## MODIFIED Requirements

### Requirement: Lobby lists rooms visible to the current visitor
The lobby SHALL display rooms based on visibility and the visitor's session-stored access list. Public rooms are visible to all visitors. Private rooms are visible only to visitors whose session `:authorized_rooms` list contains the room's ID.

#### Scenario: Visitor with no authorized rooms sees only public rooms
- **WHEN** a visitor with an empty `:authorized_rooms` session list opens the lobby
- **THEN** only rooms with `visibility: :public` are listed

#### Scenario: Visitor with authorized rooms sees public and their private rooms
- **WHEN** a visitor whose session `:authorized_rooms` contains one or more room IDs opens the lobby
- **THEN** public rooms AND private rooms whose IDs appear in `:authorized_rooms` are listed

#### Scenario: Private room invisible to unauthorized visitor
- **WHEN** a visitor whose session `:authorized_rooms` does not contain a given private room's ID opens the lobby
- **THEN** that private room does not appear in the lobby listing

#### Scenario: Private room shows lock icon in lobby
- **WHEN** an authorized visitor sees a private room in the lobby
- **THEN** a visual indicator (lock icon) distinguishes it from public rooms

## Test Requirements

| Scenario | Test type | Test ID | Notes |
|---|---|---|---|
| invite_token generated on private room creation | ExUnit (`RoomTest`) | T-R1 | Call `Room.create/1` with `visibility: :private`; assert `invite_token` is a non-nil UUID |
| invite_token is null for public rooms | ExUnit (`RoomTest`) | T-R2 | Call `Room.create/1` with `visibility: :public`; assert `invite_token: nil` |
| Visitor with no authorized rooms sees only public rooms | LiveViewTest (`LobbyLiveTest`) | T-R3 | Mount lobby with empty session `:authorized_rooms`; assert only public rooms appear in rendered HTML |
| Visitor with authorized rooms sees public and their private rooms | LiveViewTest (`LobbyLiveTest`) | T-R4 | Mount lobby with session `:authorized_rooms` containing a private room's ID; assert that private room and public rooms are listed |
| Private room invisible to unauthorized visitor | LiveViewTest (`LobbyLiveTest`) | T-R5 | Mount lobby without the private room ID in session; assert that room is absent from rendered HTML |
| Private room shows lock icon in lobby | LiveViewTest (`LobbyLiveTest`) | T-R6 | Mount lobby with authorized private room; assert lock icon element rendered alongside that room entry |
