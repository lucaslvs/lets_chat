## ADDED Requirements

### Requirement: Message persistence
The system SHALL persist chat messages and system events to the `messages` table via the `Message` Ash resource belonging to the `LetsChat.Chat` domain. A message SHALL have: `id` (UUID primary key), `content` (string, required), `type` (atom enum `[:text, :system]`, default `:text`), `room_id` (UUID foreign key to `rooms`), `sender_name` (string), `session_id` (string), and `inserted_at` (UTC datetime).

#### Scenario: User sends a chat message
- **WHEN** a user submits a non-empty message in the chat input
- **THEN** the system SHALL create a `Message` record with `type: :text`, `content` set to the submitted text, `sender_name` from the guest session, `session_id` from the guest session, and `room_id` matching the current room

#### Scenario: Message with empty content is rejected
- **WHEN** a user submits a message with blank or empty content
- **THEN** the system SHALL NOT create a `Message` record and SHALL NOT broadcast

#### Scenario: System event on room join
- **WHEN** a user mounts `RoomLive` for a known room
- **THEN** the system SHALL create a `Message` record with `type: :system` and `content` set to `"<sender_name> entrou na sala"`, with `session_id` and `sender_name` from the guest session

#### Scenario: System event on room leave
- **WHEN** a user unmounts `RoomLive` (navigates away or disconnects)
- **THEN** the system SHALL create a `Message` record with `type: :system` and `content` set to `"<sender_name> saiu da sala"`, with `session_id` and `sender_name` from the guest session

---

### Requirement: Initial message history on mount
The system SHALL load the last 100 messages for the current room (both `:text` and `:system` types), ordered by `inserted_at ASC`, and assign them to the LiveView socket as `@messages` on mount.

#### Scenario: Room with existing messages
- **WHEN** a user mounts `RoomLive` for a room that has existing messages
- **THEN** the system SHALL load up to 100 messages ordered oldest-first and pass them as the `messages` prop to `ChatWindow.vue`

#### Scenario: Room with no messages
- **WHEN** a user mounts `RoomLive` for a room with no message history
- **THEN** the system SHALL assign an empty list to `@messages` and `ChatWindow.vue` SHALL receive an empty `messages` prop

#### Scenario: Room with more than 100 messages
- **WHEN** a room has more than 100 messages in the database
- **THEN** the system SHALL load only the most recent 100 messages; older messages SHALL NOT be loaded in this change

---

### Requirement: Real-time message delivery via PubSub and push_event
The system SHALL broadcast new messages over `LetsChat.PubSub` on topic `"room:{slug}"` and deliver them to connected `RoomLive` sessions via `push_event/3`. Only the new message payload travels the wire after the initial mount — not the full list.

#### Scenario: Broadcast on message creation
- **WHEN** a `Message` is successfully created (`:text` or `:system`)
- **THEN** the system SHALL broadcast `{:new_message, payload}` on topic `"room:{slug}"` where `slug` is the current room's slug and `payload` is a map with keys: `id`, `content`, `type`, `sender_name`, `session_id`, `avatar_initials`, `avatar_color`, `inserted_at`

#### Scenario: Receiving a broadcast in a connected session
- **WHEN** `RoomLive` receives `{:new_message, payload}` via `handle_info/2`
- **THEN** the system SHALL call `push_event(socket, "new_message", payload)` to forward the serialized message to the Vue layer; it SHALL NOT re-assign the full `@messages` list

#### Scenario: Avatar fields are computed, not stored
- **WHEN** the system builds the broadcast payload
- **THEN** `avatar_initials` SHALL be computed from `sender_name` and `avatar_color` SHALL be a deterministic color derived from `sender_name`; neither field SHALL be stored in the `messages` table

---

### Requirement: `ChatWindow.vue` — initial render and real-time updates
The `ChatWindow.vue` Vue component SHALL accept a `messages` prop (list of message maps) and a `currentGuest` prop (`%{name, avatar_initials, avatar_color, session_id}`) for identifying the current user's own messages. It SHALL register a `handleEvent("new_message")` listener and append incoming messages to its local `messages` ref.

#### Scenario: Rendering initial message list
- **WHEN** `ChatWindow.vue` is mounted with a non-empty `messages` prop
- **THEN** the component SHALL render all messages in the prop list in `inserted_at ASC` order

#### Scenario: Appending a new message from the server
- **WHEN** the LiveView emits a `"new_message"` event via `push_event`
- **THEN** `ChatWindow.vue` SHALL push the new message map into its `messages` ref, causing the message to appear at the bottom of the timeline without re-rendering existing messages

#### Scenario: Rendering an empty state
- **WHEN** `ChatWindow.vue` is mounted with an empty `messages` prop
- **THEN** the component SHALL render an appropriate empty state indicator

---

### Requirement: `ChatWindow.vue` — message input interaction
The `ChatWindow.vue` component SHALL provide a textarea for composing messages. Pressing Enter (without Shift) SHALL emit a `"send-message"` LiveVue event with `%{content: content}` and clear the textarea. Pressing Shift+Enter SHALL insert a newline without sending.

#### Scenario: Send on Enter key
- **WHEN** the user presses Enter without holding Shift while the textarea is focused
- **THEN** `ChatWindow.vue` SHALL emit a `"send-message"` event with the current textarea content and clear the textarea

#### Scenario: Newline on Shift+Enter
- **WHEN** the user presses Shift+Enter while the textarea is focused
- **THEN** `ChatWindow.vue` SHALL insert a newline character into the textarea and SHALL NOT emit `"send-message"`

#### Scenario: Send with empty input is ignored
- **WHEN** the user presses Enter while the textarea contains only whitespace
- **THEN** `ChatWindow.vue` SHALL NOT emit `"send-message"` and SHALL NOT clear the textarea

---

### Requirement: `ChatWindow.vue` — visual grouping and message alignment
The component SHALL group consecutive messages from the same sender: if a message's `session_id` matches the previous message's `session_id`, the avatar and sender name SHALL be hidden for the subsequent message in the group. Own messages (matching `currentUser`) SHALL be aligned right; others SHALL be aligned left; system messages SHALL be centered in a neutral style.

#### Scenario: Consecutive messages from the same sender are grouped
- **WHEN** two or more consecutive messages share the same `session_id`
- **THEN** only the first message in the group SHALL display the avatar and sender name; subsequent messages in the group SHALL omit them

#### Scenario: Own messages are right-aligned
- **WHEN** a message's `session_id` matches the current user's session
- **THEN** the message bubble SHALL be visually aligned to the right side of the chat window

#### Scenario: Other users' messages are left-aligned
- **WHEN** a message's `session_id` does not match the current user's session and `type` is `:text`
- **THEN** the message bubble SHALL be visually aligned to the left side of the chat window

#### Scenario: System messages are centered
- **WHEN** a message has `type: :system`
- **THEN** it SHALL be rendered centered with a neutral/muted visual style, distinct from chat bubbles

---

## Test Requirements

| BDD Scenario | Test Type | Description |
|---|---|---|
| User sends a chat message | LiveViewTest | `test "creates a :text message and broadcasts on send-message event"` |
| Message with empty content is rejected | LiveViewTest | `test "does not create a message or broadcast when content is blank"` |
| System event on room join | LiveViewTest | `test "creates a :system join message on RoomLive mount"` |
| System event on room leave | LiveViewTest | `test "creates a :system leave message on RoomLive terminate"` |
| Room with existing messages | LiveViewTest | `test "assigns last 100 messages ordered ASC on mount for a room with messages"` |
| Room with no messages | LiveViewTest | `test "assigns empty list to @messages on mount for a room with no messages"` |
| Room with more than 100 messages | LiveViewTest | `test "loads only the 100 most recent messages when room has more than 100"` |
| Broadcast on message creation | LiveViewTest | `test "broadcasts {:new_message, payload} on topic room:{slug} after message creation"` |
| Receiving a broadcast in a connected session | LiveViewTest | `test "push_events new_message payload to the socket on broadcast"` |
| Avatar fields are computed, not stored | LiveViewTest | `test "broadcast payload includes computed avatar_initials and avatar_color"` |
| Rendering initial message list | Vitest | `it("renders all messages from the messages prop in order")` |
| Appending a new message from the server | Vitest | `it("appends a new message when handleEvent new_message fires")` |
| Rendering an empty state | Vitest | `it("shows the empty state when messages prop is empty")` |
| Send on Enter key | Vitest | `it("emits send-message and clears textarea on Enter without Shift")` |
| Newline on Shift+Enter | Vitest | `it("inserts a newline and does not emit send-message on Shift+Enter")` |
| Send with empty input is ignored | Vitest | `it("does not emit send-message when textarea contains only whitespace")` |
| Consecutive messages from the same sender are grouped | Vitest | `it("hides avatar and sender name for consecutive messages from the same session_id")` |
| Own messages are right-aligned | Vitest | `it("aligns own messages to the right")` |
| Other users' messages are left-aligned | Vitest | `it("aligns other users' messages to the left")` |
| System messages are centered | Vitest | `it("renders system messages centered with neutral style")` |
