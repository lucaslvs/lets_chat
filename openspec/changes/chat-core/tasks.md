## Execution Order

```
[1] Message Ash Resource (+ migration)
     ├── [SERVER TRACK]                    [VUE TRACK — parallel with server]
     │   [2] Serialization + PubSub        [6] ChatWindow.vue
     │   [3] RoomLive — Mount + Wiring
     │   [4] RoomLive — Event Handlers
     │   [5] RoomLive — Template Update
     └── [7] Verification                  ← after both tracks complete
```

> Sub-agent opportunity: after section 1, spawn two parallel sub-agents — one for the server track (sections 2–5) and one for the Vue component (section 6). The Vue sub-agent only needs the interface contract from the spec (props: `messages`, `currentGuest`; event: `"new_message"`).

---

## 1. Message Ash Resource

- [ ] 1.1 Create `lib/lets_chat/chat/message.ex` with the `Message` Ash resource: attributes `id` (UUID pk), `content` (string, required), `type` (atom enum `[:text, :system]`, default `:text`), `room_id` (UUID FK), `sender_name` (string), `session_id` (string), `inserted_at`
- [ ] 1.2 Add `belongs_to :room, LetsChat.Chat.Room` relationship to the `Message` resource
- [ ] 1.3 Define `create` action and `list_by_room` action (paginated, ordered by `inserted_at ASC`, accepts `room_id` filter, limit 100)
- [ ] 1.4 Register `Message` in `lib/lets_chat/chat.ex` domain resource list
- [ ] 1.5 Generate and run AshPostgres migration for the `messages` table (`mix ash_postgres.generate_migrations` then `mix ecto.migrate`)

## 2. Serialization and PubSub Broadcast

- [ ] 2.1 Add a `serialize/1` private helper in `RoomLive` (or a dedicated module) that converts a `%Message{}` struct to a plain map with keys: `id`, `content`, `type`, `sender_name`, `session_id`, `avatar_initials`, `avatar_color`, `inserted_at`
- [ ] 2.2 Implement `avatar_initials/1` and `avatar_color/1` helper calls (reuse Change 1 functions) inside `serialize/1` to compute derived avatar fields from `sender_name`
- [ ] 2.3 Add a `broadcast_message/2` helper that calls `Phoenix.PubSub.broadcast(LetsChat.PubSub, "room:{slug}", {:new_message, serialize(message)})`

## 3. RoomLive — Mount and PubSub Wiring

- [ ] 3.1 In `RoomLive.mount/3`, fetch the room by slug; redirect to `/rooms` with flash if not found
- [ ] 3.2 In `RoomLive.mount/3`, load the last 100 messages via `Message` `list_by_room` action and assign to `socket` as `:messages`
- [ ] 3.3 In `RoomLive.mount/3`, subscribe to `LetsChat.PubSub` on topic `"room:{slug}"`
- [ ] 3.4 In `RoomLive.mount/3`, create a `:system` `Message` with content `"<sender_name> entrou na sala"` and broadcast it
- [ ] 3.5 Implement `RoomLive.terminate/2` to create a `:system` `Message` with content `"<sender_name> saiu da sala"` and broadcast it

## 4. RoomLive — Event and Info Handlers

- [ ] 4.1 Implement `handle_event("send-message", %{"content" => content}, socket)`: validate non-empty content, create `Message` with `type: :text`, broadcast via `broadcast_message/2`
- [ ] 4.2 Implement `handle_info({:new_message, payload}, socket)`: call `push_event(socket, "new_message", payload)` and return the unchanged socket (do NOT re-assign `@messages`)

## 5. RoomLive — Template Update

- [ ] 5.1 Replace the disabled input placeholder in the `RoomLive` template with `<.live_vue name="ChatWindow" props={%{messages: serialize_list(@messages), current_guest: @current_guest}} />`
- [ ] 5.2 Ensure `@current_guest` assign is populated in `mount/3` with `%{name: name, avatar_initials: initials, avatar_color: color, session_id: session_id}` from the guest session — use `@current_guest` (not `@current_user`) to avoid collision with the authenticated user assign set by `LiveUserAuth`

## 6. ChatWindow.vue Component

- [ ] 6.1 Create `assets/vue/ChatWindow.vue` with `messages` and `currentGuest` props defined (list and object respectively)
- [ ] 6.2 Implement `handleEvent("new_message", payload => messages.value.push(payload))` using LiveVue's `handleEvent` composable
- [ ] 6.3 Render the message list in the template, iterating over `messages` ref in order
- [ ] 6.4 Add grouping logic: compare each message's `sessionId` with the previous message's `sessionId`; hide avatar and sender name when they match
- [ ] 6.5 Apply right-alignment CSS for own messages (`sessionId === currentGuest.sessionId`), left-alignment for others, centered neutral style for `type === "system"` messages
- [ ] 6.6 Add textarea for message composition; handle `keydown` event: Enter (without Shift) emits `"send-message"` via LiveVue `pushEvent` with `{content}` and clears textarea; Shift+Enter inserts newline
- [ ] 6.7 Guard against sending empty/whitespace-only content: if trimmed content is empty, do not emit `"send-message"`
- [ ] 6.8 Add empty state display when `messages` is empty

## 7. Verification

- [ ] 7.1 Run `mix precommit` and fix any formatting or compilation issues
- [ ] 7.2 Manually test: open two browser tabs in the same room, send a message in one tab and verify it appears in the other in real time
- [ ] 7.3 Verify system join/leave messages appear in the timeline when a tab opens and closes
- [ ] 7.4 Verify that navigating to `/rooms/nonexistent-slug` redirects to `/rooms` with a flash message
- [ ] 7.5 Verify grouping: send multiple consecutive messages from the same user and confirm avatar/name is shown only on the first
- [ ] 7.6 Run `mix test` and confirm all ExUnit/LiveViewTest tests covering the BDD scenarios in `specs/messages/spec.md` and `specs/rooms/spec.md` pass
- [ ] 7.7 Run `npm run test` (or `npx vitest`) in `assets/` and confirm all Vitest tests for `ChatWindow.vue` pass, covering: initial render, `handleEvent("new_message")` append, empty state, Enter-to-send, Shift+Enter newline, empty-input guard, message grouping, and alignment

## 8. Tests

> Write these tests as part of the implementation. Each item references the BDD scenario it covers.

### ExUnit / LiveViewTest

- [ ] 8.1 `test "creates a :text message and broadcasts on send-message event"` — covers **Scenario: User sends a chat message** and **Scenario: Valid message submitted from Vue**
- [ ] 8.2 `test "does not create a message or broadcast when content is blank"` — covers **Scenario: Message with empty content is rejected** and **Scenario: Send with empty input is ignored** (server-side guard)
- [ ] 8.3 `test "creates a :system join message on RoomLive mount"` — covers **Scenario: System event on room join**
- [ ] 8.4 `test "creates a :system leave message on RoomLive terminate"` — covers **Scenario: System event on room leave**
- [ ] 8.5 `test "assigns last 100 messages ordered ASC on mount for a room with messages"` — covers **Scenario: Room with existing messages**
- [ ] 8.6 `test "assigns empty list to @messages on mount for a room with no messages"` — covers **Scenario: Room with no messages**
- [ ] 8.7 `test "loads only the 100 most recent messages when room has more than 100"` — covers **Scenario: Room with more than 100 messages**
- [ ] 8.8 `test "push_events new_message payload to the socket on broadcast"` — covers **Scenario: Receiving a broadcast in a connected session**
- [ ] 8.9 `test "broadcast payload includes computed avatar_initials and avatar_color"` — covers **Scenario: Avatar fields are computed, not stored**
- [ ] 8.10 `test "redirects to /rooms with flash when slug is unknown"` — covers **Scenario: Unknown slug on mount**
- [ ] 8.11 `test "subscribes to PubSub room topic on successful mount"` — covers **Scenario: Subscription on mount**
- [ ] 8.12 `test "broadcasts {:new_message, payload} on topic room:{slug} after message creation"` — covers **Scenario: Broadcast on message creation**
- [ ] 8.13 `test "sender's own LiveView receives its own broadcast via push_event"` — covers **Scenario: Broadcast received by sender's own LiveView**

### Vitest (`assets/`)

- [ ] 8.14 `it("renders all messages from the messages prop in order")` — covers **Scenario: Rendering initial message list**
- [ ] 8.15 `it("appends a new message when handleEvent new_message fires")` — covers **Scenario: Appending a new message from the server**
- [ ] 8.16 `it("shows the empty state when messages prop is empty")` — covers **Scenario: Rendering an empty state**
- [ ] 8.17 `it("emits send-message and clears textarea on Enter without Shift")` — covers **Scenario: Send on Enter key**
- [ ] 8.18 `it("inserts a newline and does not emit send-message on Shift+Enter")` — covers **Scenario: Newline on Shift+Enter**
- [ ] 8.19 `it("does not emit send-message when textarea contains only whitespace")` — covers **Scenario: Send with empty input is ignored**
- [ ] 8.20 `it("hides avatar and sender name for consecutive messages from the same session_id")` — covers **Scenario: Consecutive messages from the same sender are grouped**
- [ ] 8.21 `it("aligns own messages to the right")` — covers **Scenario: Own messages are right-aligned**
- [ ] 8.22 `it("aligns other users' messages to the left")` — covers **Scenario: Other users' messages are left-aligned**
- [ ] 8.23 `it("renders system messages centered with neutral style")` — covers **Scenario: System messages are centered**
- [ ] 8.24 `it("renders ChatWindow.vue with messages prop and currentGuest prop from RoomLive")` — covers **Scenario: User visits a valid room**

### Mobile-First Notes

The following mobile-first constraints apply to every task that touches `ChatWindow.vue` UI (tasks 6.1–6.8 and 5.1):

- **Layout**: The message list container SHALL fill available height using `flex-1 overflow-y-auto`; the input area SHALL be pinned to the bottom (`flex-col h-full`). No fixed pixel heights — use flexbox column layout so the component fills its parent on all screen sizes.
- **Message bubbles**: `max-w-[85%]` on mobile as the base class; may expand on larger screens (e.g., `sm:max-w-[70%]`). Never set `max-w-` only at a breakpoint without a mobile base.
- **Send button tap target**: minimum `44px × 44px` (`min-h-11 min-w-11` in Tailwind). If using an icon button, pad it to meet this size.
- **Textarea font size**: use `text-base` (16px) or larger to prevent iOS Safari from zooming on focus. Never use `text-sm` or smaller on the input textarea.
- **Scroll-to-bottom**: after appending a new message, call `nextTick(() => el.scrollTop = el.scrollHeight)`. On mobile Safari, `scrollIntoView({ behavior: 'smooth' })` is unreliable — use direct `scrollTop` assignment.
- **No breakpoint-only classes**: every Tailwind utility that affects layout or interaction MUST have a mobile base class. `md:flex` without a preceding `hidden` or `flex` is forbidden.
