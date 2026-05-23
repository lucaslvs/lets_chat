## ADDED Requirements

### Requirement: Presence module exists and is supervised
The system SHALL define a `LetsChatWeb.Presence` module using `use Phoenix.Presence` backed by `LetsChat.PubSub`, and it SHALL be started as a child of the application supervision tree.

#### Scenario: Application starts with Presence supervised
- **WHEN** the application starts
- **THEN** `LetsChatWeb.Presence` is running as a supervised process under `LetsChat.Application`

### Requirement: Room presence tracking on two topics
When a user enters a room, the system SHALL track their presence on two separate Phoenix.Presence topics:
- `"room:{slug}"` with metadata `%{name: name, avatar_initials: initials, avatar_color: color, typing: false}`
- `"lobby"` with metadata `%{slug: slug}`

#### Scenario: User mounts RoomLive
- **WHEN** a user's browser mounts `RoomLive` for a room with slug `"general"`
- **THEN** `LetsChatWeb.Presence.track/4` is called on topic `"room:general"` with their `session_id` as key and metadata including `name`, `avatar_initials`, `avatar_color`, and `typing: false`
- **THEN** `LetsChatWeb.Presence.track/4` is called on topic `"lobby"` with their `session_id` as key and metadata `%{slug: "general"}`

#### Scenario: Multiple browser tabs from the same user
- **WHEN** a user opens the same room in two browser tabs (two LiveView connections, same user, different `session_id` values)
- **THEN** each tab registers as a separate Presence key under the same user identity
- **THEN** the participant list in the room shows the user only once (deduplicated by user identity when building the participants list)

### Requirement: Room participant list updated in real-time
`RoomLive` SHALL subscribe to the `"room:{slug}"` Presence topic and maintain a `@participants` assign that is updated whenever a `presence_diff` broadcast is received, without querying the database.

#### Scenario: User joins room
- **WHEN** a new user connects to a room
- **THEN** all existing `RoomLive` processes subscribed to `"room:{slug}"` receive a `presence_diff` event
- **THEN** each `RoomLive` updates its `@participants` assign to include the new user
- **THEN** the updated participant list is passed as the `participants` prop to `ChatWindow.vue`

#### Scenario: User leaves room
- **WHEN** a user's `RoomLive` process terminates (tab closed, navigation away, disconnect)
- **THEN** Phoenix.Presence removes the entry and broadcasts a `presence_diff` to remaining subscribers
- **THEN** each remaining `RoomLive` updates `@participants` to exclude the departed user

### Requirement: Typing indicator via Presence metadata
The system SHALL support per-user typing state tracked in Presence metadata. When a user types in the chat input, `RoomLive` SHALL update the user's Presence metadata to `typing: true` and schedule a reset to `typing: false` after 3 seconds of inactivity.

#### Scenario: User starts typing
- **WHEN** `ChatWindow.vue` fires a `"typing"` event to LiveView (on keystroke)
- **THEN** `handle_event("typing", _, socket)` calls `LetsChatWeb.Presence.update/4` to set `typing: true` in the `"room:{slug}"` metadata for this session
- **THEN** any previously scheduled `{:clear_typing, session_id}` message is cancelled
- **THEN** a new `Process.send_after(self(), {:clear_typing, session_id}, 3_000)` is scheduled and its ref stored in assigns

#### Scenario: Typing timeout clears indicator
- **WHEN** 3 seconds pass without a new `"typing"` event from the user
- **THEN** `handle_info({:clear_typing, session_id}, socket)` is called
- **THEN** `LetsChatWeb.Presence.update/4` sets `typing: false` for this session in `"room:{slug}"`
- **THEN** the `presence_diff` broadcast propagates to all subscribers and `typingUsers` prop in Vue is updated

#### Scenario: Sending a message clears typing indicator immediately
- **WHEN** the user submits a chat message
- **THEN** `RoomLive` cancels the active typing timer
- **THEN** `LetsChatWeb.Presence.update/4` sets `typing: false` immediately before or after sending the message

### Requirement: Lobby presence tracking for room occupancy counts
`LobbyLive` SHALL subscribe to the `"lobby"` Presence topic and maintain a map of `%{room_slug => online_count}` derived from Presence metadata, updated whenever a `presence_diff` is received.

#### Scenario: Room becomes active
- **WHEN** the first user enters a room
- **THEN** `LobbyLive` receives a `presence_diff` on `"lobby"`
- **THEN** `LobbyLive` recomputes the occupancy map and the count for that room's slug becomes `>= 1`
- **THEN** the room entry in the lobby UI shows an active badge with the count

#### Scenario: Room becomes empty
- **WHEN** the last user leaves a room
- **THEN** `LobbyLive` receives a `presence_diff` on `"lobby"` with the departure
- **THEN** `LobbyLive` recomputes the occupancy map and the count for that room's slug becomes `0`
- **THEN** the room entry in the lobby UI hides the active badge

#### Scenario: Single lobby subscription covers all rooms
- **WHEN** users are present in multiple rooms simultaneously
- **THEN** a single `"lobby"` topic subscription in `LobbyLive` receives diffs for all rooms
- **THEN** `LobbyLive` correctly computes independent counts for each room slug from the metadata

### Requirement: `push_event` delivers presence updates to Vue
After updating `@participants` from a `presence_diff`, `RoomLive` SHALL call `push_event("presence_update", payload)` to notify `ChatWindow.vue` with the latest participants and typing users list.

#### Scenario: Presence diff triggers Vue update
- **WHEN** `RoomLive` processes a `presence_diff` broadcast
- **THEN** it calls `push_event("presence_update", %{participants: [...], typing_users: [...]})` on the socket
- **THEN** `ChatWindow.vue` receives the event via its LiveVue hook and updates its local reactive state

---

## Test Requirements

| Scenario | Test Type | Notes |
|---|---|---|
| Application starts with Presence supervised | **LiveViewTest** (`ExUnit`) | Assert `Process.whereis(LetsChatWeb.Presence)` is non-nil after app start |
| User mounts RoomLive — room topic tracking | **LiveViewTest** (`ExUnit`) | Assert `LetsChatWeb.Presence.list("room:general")` contains the session key with correct metadata after connected mount |
| User mounts RoomLive — lobby topic tracking | **LiveViewTest** (`ExUnit`) | Assert `LetsChatWeb.Presence.list("lobby")` contains the session key with `%{slug: "general"}` after connected mount |
| Multiple browser tabs from the same user | **LiveViewTest** (`ExUnit`) | Mount two live views for the same user; assert the rendered participant list deduplicates to one entry |
| User joins room | **LiveViewTest** (`ExUnit`) | Two connected live views to the same room; assert the first view's `@participants` assign grows after the second mounts |
| User leaves room | **LiveViewTest** (`ExUnit`) | After the second connection is closed, assert `@participants` in the remaining view shrinks |
| User starts typing | **LiveViewTest** (`ExUnit`) | Send `"typing"` event; assert `typing: true` in Presence metadata and `@typing_timer` assign is non-nil |
| User starts typing — timer cancellation | **LiveViewTest** (`ExUnit`) | Send two `"typing"` events rapidly; assert only one outstanding `{:clear_typing}` timer (previous ref was cancelled) |
| Typing timeout clears indicator (3000ms) | **LiveViewTest** (`ExUnit`) | Send `{:clear_typing, session_id}` message; assert `typing: false` in Presence metadata and `@typing_timer` is `nil` |
| Sending a message clears typing indicator immediately | **LiveViewTest** (`ExUnit`) | After a `"typing"` event, simulate message send; assert `typing: false` and `@typing_timer` is `nil` |
| Room becomes active | **LiveViewTest** (`ExUnit`) | Mount `LobbyLive`; inject a Presence entry on `"lobby"`; assert `@room_counts` updates and badge renders |
| Room becomes empty | **LiveViewTest** (`ExUnit`) | Remove the Presence entry; assert `@room_counts` for that slug drops to `0` and badge is absent |
| Single lobby subscription covers all rooms | **LiveViewTest** (`ExUnit`) | Inject entries for two slugs; assert both counts are correct in `@room_counts` from a single subscription |
| Presence diff triggers Vue update | **LiveViewTest** (`ExUnit`) | Assert `push_event("presence_update", ...)` is emitted after `presence_diff` is processed |
