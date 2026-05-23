## MODIFIED Requirements

### Requirement: ChatWindow displays participant list
`ChatWindow.vue` SHALL accept a `participants` prop containing a list of maps with `name`, `avatar_initials`, and `avatar_color` fields, and SHALL render the list of currently present users in the room sidebar.

#### Scenario: Participants prop received
- **WHEN** `ChatWindow.vue` receives a non-empty `participants` prop
- **THEN** each participant is rendered with their avatar (initials on colored background) and name
- **THEN** the total participant count is shown in the room header or sidebar

#### Scenario: Participants list updates in real-time
- **WHEN** the LiveView calls `push_event("presence_update", ...)` with an updated participants list
- **THEN** `ChatWindow.vue` updates its reactive participant state without a full component remount

### Requirement: ChatWindow displays typing indicator
`ChatWindow.vue` SHALL accept a `typingUsers` prop containing a list of user names currently typing, and SHALL display a typing animation below the message list when the list is non-empty.

#### Scenario: Another user is typing
- **WHEN** `typingUsers` prop contains one or more names
- **THEN** `ChatWindow.vue` renders a typing indicator (three-dot CSS animation) below the latest message
- **THEN** the indicator shows the names of users who are typing (e.g., "Alice is typing...")

#### Scenario: No users typing
- **WHEN** `typingUsers` prop is empty
- **THEN** the typing indicator is not visible in the chat window

#### Scenario: Current user's own typing is excluded
- **WHEN** the current user is typing
- **THEN** the `typingUsers` list passed from LiveView does NOT include the current user's name (filtered server-side)
- **THEN** the typing indicator is only shown for other users' typing activity

### Requirement: Chat input fires typing events
The chat textarea in `ChatWindow.vue` SHALL emit a `"typing"` LiveVue event to the parent LiveView on each keystroke while the textarea is non-empty.

#### Scenario: User types in chat textarea
- **WHEN** the user presses a key in the chat textarea
- **THEN** `ChatWindow.vue` emits a `"typing"` event via the LiveVue push mechanism
- **THEN** `handle_event("typing", _, socket)` in `RoomLive` is triggered

### Requirement: New messages animate into the message list
`ChatWindow.vue` SHALL use a Vue `TransitionGroup` to animate new messages as they are appended to the message list.

#### Scenario: New message received
- **WHEN** a new message is appended to the message list (via LiveVue event or prop update)
- **THEN** the new message enters with a `slide-in` CSS transition
- **THEN** existing messages are not re-animated

### Requirement: Message list auto-scrolls to latest message
`ChatWindow.vue` SHALL automatically scroll the message list to the bottom when a new message is added.

#### Scenario: New message appended
- **WHEN** a new message is added to the message list
- **THEN** `ChatWindow.vue` calls `scrollToBottom()` after the DOM updates (using `nextTick`)
- **THEN** the user sees the latest message without manually scrolling

### Requirement: Chat textarea auto-resizes with content
The chat textarea in `ChatWindow.vue` SHALL grow vertically as the user types multi-line content, up to a defined maximum height.

#### Scenario: User types a single line
- **WHEN** the user types text that fits in one line
- **THEN** the textarea remains at its minimum height

#### Scenario: User types multiple lines
- **WHEN** the user types text that wraps or presses Enter for a new line
- **THEN** the textarea height increases to fit the content
- **THEN** the textarea does not exceed a maximum defined height (scroll appears beyond max)

---

## Test Requirements

| Scenario | Test Type | Notes |
|---|---|---|
| Participants prop received — avatars and names | **Vitest** | Mount with two-entry `participants` prop; assert initials, avatar color, and name are in the DOM |
| Participants prop received — count displayed | **Vitest** | Assert participant count in header/sidebar equals `participants.length` |
| Participants list updates in real-time | **Vitest** | Emit a `"presence_update"` event on the LiveVue hook; assert rendered list reflects the new data without a component remount |
| Another user is typing | **Vitest** | Mount with `typingUsers: ["Alice"]`; assert typing indicator element is present and includes "Alice is typing..." |
| No users typing | **Vitest** | Mount with `typingUsers: []`; assert typing indicator is absent or has `display: none` / `v-show` false |
| Current user's own typing is excluded | **Vitest** | Assert component renders correctly when `typingUsers` is an empty array (server already filters; test confirms no self-indicator leaks) |
| User types in chat textarea | **Vitest** | Simulate `input` event on textarea; assert `pushEvent` mock is called with `("typing", {})` |
| New message received — slide-in animation | **Vitest** | Append a message to the list; assert the entering item has the `slide-in` transition name applied via `TransitionGroup` |
| New message appended — auto-scroll | **Vitest** | After message append, assert `scrollToBottom` was called (spy) or `scrollTop === scrollHeight` on the list container |
| User types a single line | **Vitest** | Simulate single-line `input`; assert `textarea.style.height` is at minimum (or `'auto'`) |
| User types multiple lines | **Vitest** | Simulate multi-line `input` with `scrollHeight > minHeight`; assert `textarea.style.height` is set to `scrollHeight + 'px'` |
