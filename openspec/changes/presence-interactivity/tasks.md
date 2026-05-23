## Execution Order

```
[1] Presence Module + Supervision   ← must be first
     ├── [2+3] RoomLive presence + typing   ← parallel with [4] and [5+6+7]
     ├── [4]   LobbyLive presence counts    ← parallel with [2+3] and [5+6+7]
     └── [5+6+7] ChatWindow.vue changes     ← parallel with [2+3] and [4]
              └── [8] Participant List UI   ← after [2+3] and [5+6+7] complete
```

> Sub-agent opportunity: after section 1, spawn three parallel sub-agents — one for RoomLive (sections 2+3), one for LobbyLive (section 4), one for ChatWindow.vue (sections 5+6+7). Section 8 requires all three to be done.

---

## 1. Presence Module and Supervision

- [ ] 1.1 Create `lib/lets_chat_web/presence.ex` with `use Phoenix.Presence, otp_app: :lets_chat, pubsub_server: LetsChat.PubSub`
- [ ] 1.2 Add `LetsChatWeb.Presence` as a child in `lib/lets_chat/application.ex` supervision tree (before the endpoint)
- [ ] 1.3 Verify the application starts without errors and `LetsChatWeb.Presence` process is running

## 2. Room Presence Tracking in RoomLive

- [ ] 2.1 On `mount` (connected socket), call `LetsChatWeb.Presence.track/4` on topic `"room:{slug}"` with `session_id` as key and metadata `%{name: name, avatar_initials: initials, avatar_color: color, typing: false}`
- [ ] 2.2 On `mount` (connected socket), call `LetsChatWeb.Presence.track/4` on topic `"lobby"` with `session_id` as key and metadata `%{slug: slug}`
- [ ] 2.3 Subscribe `RoomLive` to the `"room:{slug}"` PubSub topic on mount so it receives `presence_diff` broadcasts
- [ ] 2.4 Add `handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket)` in `RoomLive` to rebuild `@participants` assign from `LetsChatWeb.Presence.list/1` (deduplicated, one entry per user)
- [ ] 2.5 After updating `@participants`, call `push_event("presence_update", %{participants: participants, typing_users: typing_users})` to notify `ChatWindow.vue`
- [ ] 2.6 Initialize `@participants` assign to `[]` and `@typing_timer` assign to `nil` on mount

## 3. Typing Indicator in RoomLive

- [ ] 3.1 Add `handle_event("typing", _, socket)` that cancels any existing `@typing_timer` ref and calls `LetsChatWeb.Presence.update/4` to set `typing: true` in `"room:{slug}"` metadata for this session
- [ ] 3.2 After updating Presence, schedule `Process.send_after(self(), {:clear_typing, session_id}, 3_000)` and store the returned ref in `@typing_timer` assign
- [ ] 3.3 Add `handle_info({:clear_typing, session_id}, socket)` that calls `LetsChatWeb.Presence.update/4` to set `typing: false` and clears `@typing_timer` assign
- [ ] 3.4 In the existing message-send handler, cancel `@typing_timer` and set `typing: false` via `Presence.update/4` before or after persisting the message
- [ ] 3.5 When building `typing_users` for `push_event`, filter `@participants` where `typing: true` and exclude the current user's own session

## 4. Lobby Presence Tracking in LobbyLive

- [ ] 4.1 On `mount` (connected socket), subscribe `LobbyLive` to the `"lobby"` PubSub topic
- [ ] 4.2 Initialize `@room_counts` assign (map of `%{slug => count}`) from `LetsChatWeb.Presence.list("lobby")` on mount
- [ ] 4.3 Add `handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket)` in `LobbyLive` to recompute `@room_counts` from `LetsChatWeb.Presence.list("lobby")` metadata
- [ ] 4.4 Update the lobby LiveView template to pass `@room_counts` to each room entry and conditionally render an active badge (DaisyUI `badge`) when count > 0

### Mobile-First Notes
- The active badge must be styled with a base (mobile) class first; any responsive variant (e.g., different size on larger screens) must build on top of the base
- Badge text and size must be legible on small screens (minimum font size, sufficient color contrast)
- The online indicator dot/badge must have a minimum visible size that works on high-DPI mobile screens
- All room-entry touch targets in the lobby must be at least 44px tall on mobile

## 5. ChatWindow.vue — Presence Props and Typing Indicator

- [ ] 5.1 Add `participants` prop to `ChatWindow.vue` (array of `{name, avatar_initials, avatar_color}`)
- [ ] 5.2 Add `typingUsers` prop to `ChatWindow.vue` (array of name strings)
- [ ] 5.3 Register a LiveVue `handleEvent("presence_update", ...)` listener in `ChatWindow.vue` to update local reactive `participants` and `typingUsers` state when the server pushes updates
- [ ] 5.4 Render a typing indicator below the message list when `typingUsers` is non-empty (e.g., "Alice is typing...")
- [ ] 5.5 Add CSS `@keyframes bounce` animation for the three-dot typing indicator directly in `ChatWindow.vue` `<style>` block
- [ ] 5.6 Hide the typing indicator entirely when `typingUsers` is empty

### Mobile-First Notes
- The typing indicator must appear above (not overlapping) the message input bar on mobile; ensure sufficient vertical spacing via a mobile-first margin or padding class
- The typing indicator text must be legible at mobile font sizes (do not rely on `sm:`/`md:` size classes alone)
- The three-dot animation dots must be large enough to be visible on small screens (min ~6px per dot)
- No `md:` or `lg:` layout class on the typing indicator without a corresponding mobile-first base class

## 6. ChatWindow.vue — Typing Event Emission

- [ ] 6.1 Add an `input` event listener on the chat textarea in `ChatWindow.vue` that calls `pushEvent("typing", {})` via the LiveVue hook on each keystroke when textarea is non-empty

### Mobile-First Notes
- The chat textarea must have a minimum height and touch target of at least 44px on mobile
- The send button adjacent to the textarea must also meet the 44px minimum touch target on mobile
- Ensure the `input` event fires correctly on mobile soft keyboards (no special mobile-only event handling needed, but verify the UX is not broken by virtual keyboard layout shifts)

## 7. ChatWindow.vue — Message Animations and UX Enhancements

- [ ] 7.1 Wrap the message list in a Vue `TransitionGroup` with a `slide-in` CSS transition class
- [ ] 7.2 Define `slide-in-enter-active`, `slide-in-enter-from`, and `slide-in-enter-to` CSS classes for the enter animation
- [ ] 7.3 After a new message is appended to the list, call `scrollToBottom()` inside `nextTick(() => ...)` to auto-scroll the message container
- [ ] 7.4 Implement auto-resize for the chat textarea: on `input` event, set `el.style.height = 'auto'` then `el.style.height = el.scrollHeight + 'px'` with a defined `max-height`
- [ ] 7.5 Reset textarea height to auto after a message is sent

### Mobile-First Notes
- The `max-height` for auto-resize textarea must be defined in mobile-safe units (e.g., `25vh`) so it does not push the send button off-screen when the mobile keyboard is open
- The message list container must have its own scrollable area on mobile (`overflow-y: auto` with a constrained height) and must not rely on the page scroll
- The `slide-in` animation duration must be short enough (≤ 200ms) to avoid feeling sluggish on lower-end mobile hardware
- Message bubbles must not exceed viewport width on mobile; use `max-w-full` or equivalent as the base class

## 8. Participant List in Room UI

- [ ] 8.1 Render the `participants` list in the room sidebar (or header): show each participant's avatar (colored circle with initials) and name
- [ ] 8.2 Show the total participant count in the room header alongside the room name
- [ ] 8.3 Ensure avatar color is generated deterministically from user identity (not randomly on each mount) to prevent color flicker on reconnect

### Mobile-First Notes
- The participant list sidebar MUST be hidden by default on mobile (`hidden lg:block` or equivalent) with a toggle button (min 44px touch target) to reveal it as an overlay or drawer
- Avatar circles and names must stack/wrap correctly on small screens; do not assume a fixed sidebar width on mobile
- The participant count badge in the room header must remain visible on all screen sizes as it is the primary mobile-accessible indicator
- All avatar interactive elements (if any) must meet the 44px minimum touch target requirement
- No `md:`/`lg:` class may be used without a mobile-first base class defined first

---

## 9. Tests

### 9.1 ExUnit / LiveViewTest — Presence Module and Supervision

- [ ] 9.1.1 **[Scenario: Application starts with Presence supervised]** Assert that `LetsChatWeb.Presence` is listed among running processes in the supervision tree after application start (`Process.whereis/1` or `Supervisor.which_children/1`)

### 9.2 ExUnit / LiveViewTest — Room Presence Tracking

- [ ] 9.2.1 **[Scenario: User mounts RoomLive]** On connected mount of `RoomLive`, assert that `LetsChatWeb.Presence.list("room:general")` contains an entry for the session's key with metadata fields `name`, `avatar_initials`, `avatar_color`, and `typing: false`
- [ ] 9.2.2 **[Scenario: User mounts RoomLive]** On connected mount, assert that `LetsChatWeb.Presence.list("lobby")` contains an entry for the session's key with metadata `%{slug: "general"}`
- [ ] 9.2.3 **[Scenario: User joins room]** With two live-view connections to the same room, assert that the second join triggers a `presence_diff` and that the first view's `@participants` assign is updated to include the new user
- [ ] 9.2.4 **[Scenario: User leaves room]** When the second connection disconnects, assert that the remaining view's `@participants` assign is updated to exclude the departed user
- [ ] 9.2.5 **[Scenario: Multiple browser tabs from the same user]** When two connections share the same user identity (different `session_id` values for same user), assert the rendered participant list shows the user only once
- [ ] 9.2.6 **[Scenario: Presence diff triggers Vue update]** After a `presence_diff`, assert that `push_event("presence_update", ...)` is called with a `participants` list and a `typing_users` list

### 9.3 ExUnit / LiveViewTest — Typing Indicator

- [ ] 9.3.1 **[Scenario: User starts typing]** Simulate a `"typing"` event from the client; assert that `LetsChatWeb.Presence.list("room:{slug}")` shows `typing: true` for the current session's key
- [ ] 9.3.2 **[Scenario: User starts typing]** After a `"typing"` event, assert that a `{:clear_typing, session_id}` message is scheduled (verify via `@typing_timer` assign being non-nil)
- [ ] 9.3.3 **[Scenario: User starts typing — timer reset]** Simulate two rapid `"typing"` events; assert that only one `:clear_typing` timer is outstanding (the previous ref was cancelled)
- [ ] 9.3.4 **[Scenario: Typing timeout clears indicator]** Send a `{:clear_typing, session_id}` message directly to the live view process; assert that `LetsChatWeb.Presence.list("room:{slug}")` shows `typing: false` for the session and `@typing_timer` is `nil`
- [ ] 9.3.5 **[Scenario: Sending a message clears typing indicator immediately]** After a `"typing"` event, simulate sending a message; assert that `typing: false` is set in Presence metadata and `@typing_timer` is `nil`
- [ ] 9.3.6 **[Scenario: Typing timeout clears indicator — 3000ms]** Confirm the timer is scheduled with `3_000` ms delay (inspect the `Process.send_after` call or assert the timer fires after ~3 seconds in an integration test)

### 9.4 ExUnit / LiveViewTest — Lobby Presence

- [ ] 9.4.1 **[Scenario: Room becomes active]** Mount `LobbyLive`; have a separate process join `LetsChatWeb.Presence` on `"lobby"` with `%{slug: "general"}`; assert that `LobbyLive` updates its `@room_counts` assign with `"general" => 1` and the lobby template renders an active badge
- [ ] 9.4.2 **[Scenario: Room becomes empty]** After the presence entry from 9.4.1 is removed, assert that `@room_counts["general"]` is `0` (or absent) and the badge is no longer rendered
- [ ] 9.4.3 **[Scenario: Single lobby subscription covers all rooms]** Have processes join with slugs `"general"` and `"random"`; assert `@room_counts` reflects correct independent counts for both slugs from a single `"lobby"` subscription

### 9.5 Vitest — ChatWindow.vue Presence and Typing UI

- [ ] 9.5.1 **[Scenario: Participants prop received]** Mount `ChatWindow.vue` with a `participants` prop containing two entries; assert both avatars (initials + color) and names are rendered in the DOM
- [ ] 9.5.2 **[Scenario: Participants prop received — count]** Assert the participant count shown in the header/sidebar matches `participants.length`
- [ ] 9.5.3 **[Scenario: Participants list updates in real-time]** Simulate a `"presence_update"` event on the LiveVue hook; assert the component updates rendered participants without a remount
- [ ] 9.5.4 **[Scenario: Another user is typing]** Mount with `typingUsers: ["Alice"]`; assert the typing indicator element is present and contains "Alice is typing..."
- [ ] 9.5.5 **[Scenario: No users typing]** Mount with `typingUsers: []`; assert the typing indicator element is absent or hidden
- [ ] 9.5.6 **[Scenario: Current user's own typing is excluded]** Assert that the component renders the typing indicator correctly when `typingUsers` does not include the current user (this is a server-side guarantee; the test verifies the Vue component renders only what it receives)
- [ ] 9.5.7 **[Scenario: User types in chat textarea]** Simulate an `input` event on the textarea; assert that `pushEvent("typing", {})` is called via the LiveVue hook
- [ ] 9.5.8 **[Scenario: New message received]** Append a message to the list; assert the new item has the `slide-in` transition class applied
- [ ] 9.5.9 **[Scenario: New message appended — auto-scroll]** After a message is appended, assert that `scrollToBottom()` is called (or that the message container's `scrollTop` equals `scrollHeight`)
- [ ] 9.5.10 **[Scenario: User types multiple lines]** Simulate multi-line input in the textarea; assert that `element.style.height` is updated to match `scrollHeight`
- [ ] 9.5.11 **[Scenario: User types a single line]** Assert textarea height remains at its minimum (or is reset) when content is a single line

---

## 10. Verification

- [ ] 10.1 Run `mix test` and confirm all tests pass, including the new presence and typing indicator tests covering the BDD scenarios in `specs/presence/spec.md` and `specs/rooms/spec.md`
- [ ] 10.2 Run Vitest (`mix assets.build` or `npm run test` in `assets/`) and confirm all `ChatWindow.vue` Vitest tests pass, covering the BDD scenarios in `specs/chat-ux/spec.md`
- [ ] 10.3 Run `mix precommit` to confirm all formatting, linting, and static analysis checks pass
- [ ] 10.4 Manually verify in the browser: open two tabs in the same room, confirm both appear in the participant list, confirm the typing indicator appears in one tab when typing in the other, and confirm the indicator disappears after ~3 seconds of inactivity
- [ ] 10.5 Manually verify in the browser: navigate to the lobby while a user is in a room; confirm the active badge shows the correct count and disappears when the user leaves
