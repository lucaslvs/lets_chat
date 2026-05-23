## MODIFIED Requirements

### Requirement: Room shell — active chat input
The room shell at `/rooms/:slug` SHALL render a fully active `ChatWindow.vue` component (via `<.live_vue>`). The message input SHALL be enabled and functional. `RoomLive` SHALL pass `messages` (list of serialized message maps, last 100 ordered ASC) and `current_user` (`%{name, avatar_initials, avatar_color}`) as props to `ChatWindow.vue`.

This replaces the Change 2 behavior where the input was visible but disabled.

#### Scenario: User visits a valid room
- **WHEN** a user navigates to `/rooms/:slug` for a known room
- **THEN** `RoomLive` SHALL mount, load the last 100 messages, subscribe to `"room:{slug}"` on `LetsChat.PubSub`, create a `:system` join event, and render `ChatWindow.vue` with the message list and current user props

#### Scenario: Input is enabled and accepts text
- **WHEN** `RoomLive` is mounted and the chat shell is rendered
- **THEN** the textarea inside `ChatWindow.vue` SHALL be enabled and focused, ready to accept input

---

### Requirement: Room shell — handle unknown slug
`RoomLive` SHALL redirect to `/rooms` with an informative flash message when the `:slug` parameter does not match any room in the database.

#### Scenario: Unknown slug on mount
- **WHEN** a user navigates to `/rooms/:slug` where `slug` does not match any room
- **THEN** `RoomLive` SHALL redirect to `/rooms` and display a flash message indicating the room was not found

---

### Requirement: Room shell — PubSub subscription lifecycle
`RoomLive` SHALL subscribe to `LetsChat.PubSub` on the topic `"room:{slug}"` during `mount/3` and the subscription SHALL be automatically cleaned up when the LiveView process terminates.

#### Scenario: Subscription on mount
- **WHEN** `RoomLive` mounts successfully for a valid room
- **THEN** `Phoenix.PubSub.subscribe(LetsChat.PubSub, "room:{slug}")` SHALL be called exactly once, where `{slug}` is the room's slug

#### Scenario: Subscription cleanup on disconnect
- **WHEN** the `RoomLive` LiveView process terminates (user navigates away or disconnects)
- **THEN** the PubSub subscription SHALL be automatically released (no explicit unsubscribe needed — the process death cleans up)

---

### Requirement: Room shell — handle_event for send-message
`RoomLive` SHALL handle the `"send-message"` LiveVue event emitted by `ChatWindow.vue`, create a `Message` record, and broadcast it.

#### Scenario: Valid message submitted from Vue
- **WHEN** `ChatWindow.vue` emits `"send-message"` with a non-empty `content` string
- **THEN** `RoomLive` SHALL call `handle_event("send-message", %{"content" => content}, socket)`, create a `Message` with `type: :text`, and broadcast `{:new_message, payload}` on `"room:{slug}"`

#### Scenario: Broadcast received by sender's own LiveView
- **WHEN** the sending `RoomLive` receives its own broadcast via `handle_info/2`
- **THEN** it SHALL forward the message to its `ChatWindow.vue` via `push_event` just like any other subscriber (no deduplication)

---

## Test Requirements

| BDD Scenario | Test Type | Description |
|---|---|---|
| User visits a valid room | LiveViewTest | `test "mounts RoomLive, loads messages, subscribes to PubSub, creates join event, and renders ChatWindow"` |
| Input is enabled and accepts text | Vitest | `it("renders ChatWindow.vue with messages prop and currentGuest prop from RoomLive")` |
| Unknown slug on mount | LiveViewTest | `test "redirects to /rooms with flash when slug is unknown"` |
| Subscription on mount | LiveViewTest | `test "subscribes to PubSub room topic on successful mount"` |
| Subscription cleanup on disconnect | LiveViewTest | `test "PubSub subscription is released when RoomLive process terminates"` — assert no stale messages delivered after disconnect |
| Valid message submitted from Vue | LiveViewTest | `test "creates a :text message and broadcasts on send-message event"` |
| Broadcast received by sender's own LiveView | LiveViewTest | `test "sender's own LiveView receives its own broadcast via push_event"` |
