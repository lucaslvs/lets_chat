## Execution Order

```
[1] Database Migrations
     ├── [2] Room — invite_token   ← parallel with [3]
     └── [3] RoomKnock Resource    ← parallel with [2]
              ├── [4] Invite Link Route     ← parallel with [5] and [6]
              ├── [5] Lobby Query Filter    ← parallel with [4] and [6]
              └── [6] Room Creation Form    ← parallel with [4] and [5]
                       └── [7] RoomLive State Machine
                                ├── [8] Knock Submission (visitor)   ← parallel with [9]
                                └── [9] Knock Notification (member)  ← parallel with [8]
                                         ├── [10] Member Actions   ← parallel with [11] and [12]
                                         ├── [11] Visitor Outcome  ← parallel with [10] and [12]
                                         └── [12] Knock Timeout    ← parallel with [10] and [11]
                                                  └── [13] Waiting State UI
                                                           └── [14] Verification
                                                                    └── [15] Tests
```

> Sub-agent opportunities:
> - After [1]: sections 2+3 in parallel (2 sub-agents)
> - After [2+3]: sections 4+5+6 in parallel (3 sub-agents)
> - After [7]: sections 8+9 in parallel (2 sub-agents)
> - After [8+9]: sections 10+11+12 in parallel (3 sub-agents)

---

## 15. Tests

### ExUnit / LiveViewTest Tests

- [ ] T-K1 `RoomLiveTest` — unauthorized visitor navigating to a private room URL renders `:blocked` state (covers knock/spec.md: "Unauthorized visitor navigates to private room URL")
- [ ] T-K2 `RoomLiveTest` — authorized visitor navigating to a private room URL renders the chat interface (covers knock/spec.md: "Authorized visitor navigates to private room URL")
- [ ] T-K3 `RoomLiveTest` — public room visitor is never blocked (covers knock/spec.md: "Public room visitor is never blocked")
- [ ] T-K4 `RoomLiveTest` — submitting knock form creates a `RoomKnock` with `status: :pending` and transitions LV to `:waiting` (covers knock/spec.md: "Submitting a knock request")
- [ ] T-K5 `RoomLiveTest` — knock submission broadcasts `{:knock_request, %{knock_id:, knock_name:}}` to `"room:{slug}:knock"` PubSub topic (covers knock/spec.md: "Knock broadcast to present room members")
- [ ] T-K6 `RoomLiveTest` — member's `RoomLive` receiving `{:knock_request, ...}` renders the toast notification with "Accept" and "Reject" buttons (covers knock/spec.md: "Members receive knock notification toast")
- [ ] T-K7 `RoomLiveTest` — after knock submission `:waiting` state renders spinner and cancel button (covers knock/spec.md: "Waiting state rendered")
- [ ] T-K8 `RoomLiveTest` — after knock submission the visitor LV subscribes to `"knock:{knock_id}"` PubSub topic (covers knock/spec.md: "PubSub subscription for knock outcome")
- [ ] T-K9 `RoomLiveTest` — after knock submission `Process.send_after/3` schedules `{:knock_timeout, knock_id}` with 300_000ms delay (covers knock/spec.md: "5-minute timeout scheduled")
- [ ] T-K10 `RoomLiveTest` — member clicks "Accept": `RoomKnock` status becomes `:approved`, `{:knock_approved}` is broadcast to `"knock:{knock_id}"` (covers knock/spec.md: "Member approves knock")
- [ ] T-K11 `RoomLiveTest` — visitor's LV receives `{:knock_approved}`: room ID added to session `:authorized_rooms` and visitor is redirected into the room (covers knock/spec.md: "Visitor receives approval")
- [ ] T-K12 `RoomLiveTest` — member clicks "Reject": `RoomKnock` status becomes `:rejected`, `{:knock_rejected}` is broadcast to `"knock:{knock_id}"` (covers knock/spec.md: "Member rejects knock")
- [ ] T-K13 `RoomLiveTest` — visitor's LV receives `{:knock_rejected}`: flash message shown and LV transitions back to `:blocked` (covers knock/spec.md: "Visitor receives rejection")
- [ ] T-K14 `RoomLiveTest` — visitor in `:blocked` state after rejection sees "Try again" option (covers knock/spec.md: "Visitor can try again after rejection")
- [ ] T-K15 `RoomLiveTest` — `handle_info({:knock_timeout, knock_id})` when knock is still `:pending`: sets `RoomKnock` status to `:expired` and transitions to `:blocked` (covers knock/spec.md: "Timeout fires after 5 minutes")
- [ ] T-K16 `RoomLiveTest` — `handle_info({:knock_timeout, knock_id})` when knock already resolved: no state change (covers knock/spec.md: "Timeout is a no-op if knock already resolved")
- [ ] T-K17 `RoomKnockTest` — `RoomKnock.create/1` persists record with all expected attributes (covers knock/spec.md: "RoomKnock record created on knock submission")
- [ ] T-K18 `RoomKnockTest` — `RoomKnock.approve/1` and `RoomKnock.reject/1` update status correctly (covers knock/spec.md: "RoomKnock status transitions")
- [ ] T-PR1 `RoomNewLiveTest` — creating a public room does not set `invite_token` (covers private-rooms/spec.md: "Creating a public room (default)")
- [ ] T-PR2 `RoomNewLiveTest` — creating a private room persists a non-null unique UUID `invite_token` (covers private-rooms/spec.md: "Creating a private room")
- [ ] T-PR3 `RoomNewLiveTest` — after private room creation the UI shows the invite link with "Copy link" and "Enter now" buttons (covers private-rooms/spec.md: "Invite link displayed after creation")
- [ ] T-PR4 `RoomControllerTest` — `GET /rooms/:slug/join/:token` with valid token adds room ID to session `:authorized_rooms` and redirects to `/rooms/:slug` (covers private-rooms/spec.md: "Valid token — access granted")
- [ ] T-PR5 `RoomControllerTest` — `GET /rooms/:slug/join/:token` with mismatched token redirects to lobby with flash error (covers private-rooms/spec.md: "Invalid or mismatched token")
- [ ] T-PR6 `RoomControllerTest` — `GET /rooms/:slug/join/:token` for non-existent slug redirects to lobby with flash error (covers private-rooms/spec.md: "Token for a non-existent room")
- [ ] T-PR7 `RoomControllerTest` — the same invite link used twice adds the room to each visitor's own session independently (covers private-rooms/spec.md: "Repeated use of the same invite link")
- [ ] T-R1 `RoomTest` — `Room.create/1` with `visibility: :private` generates a non-null `invite_token` UUID (covers rooms/spec.md: "invite_token generated on private room creation")
- [ ] T-R2 `RoomTest` — `Room.create/1` with `visibility: :public` leaves `invite_token: nil` (covers rooms/spec.md: "invite_token is null for public rooms")
- [ ] T-R3 `LobbyLiveTest` — visitor with empty `:authorized_rooms` only sees public rooms (covers rooms/spec.md: "Visitor with no authorized rooms sees only public rooms")
- [ ] T-R4 `LobbyLiveTest` — visitor with `:authorized_rooms` containing a private room ID sees that room plus public rooms (covers rooms/spec.md: "Visitor with authorized rooms sees public and their private rooms")
- [ ] T-R5 `LobbyLiveTest` — private room not in visitor `:authorized_rooms` does not appear in lobby (covers rooms/spec.md: "Private room invisible to unauthorized visitor")
- [ ] T-R6 `LobbyLiveTest` — private room visible to authorized visitor renders a lock icon (covers rooms/spec.md: "Private room shows lock icon in lobby")
- [ ] T-INT1 Integration — full knock → approve → join flow: visitor navigates to private room URL, submits knock, member approves, visitor lands in chat (end-to-end LiveViewTest)
- [ ] T-INT2 Integration — full invite-link flow: private room created, invite URL visited, visitor redirected into room

### Vitest Tests (Vue / LiveVue Components)

- [ ] T-V1 `KnockRequestForm.test.ts` — renders display name input and submit button in blocked state; emits submit event with entered name
- [ ] T-V2 `KnockWaitingState.test.ts` — renders spinner and "Cancel" button; emits cancel event on button click
- [ ] T-V3 `KnockToast.test.ts` — renders visitor name plus "Accept" and "Reject" buttons; emits correct events for each action
- [ ] T-V4 `InviteLinkDisplay.test.ts` — renders invite URL and both action buttons; clicking "Copy link" calls clipboard API
- [ ] T-V5 `PrivateRoomGate.test.ts` — renders correctly on small (mobile) viewports; all interactive elements meet 44px min touch target

---

## 1. Database Migrations

- [ ] 1.1 Generate migration to add `invite_token` (UUID, nullable) column to the `rooms` table
- [ ] 1.2 Generate migration to create the `room_knocks` table with columns: `id` (UUID pk), `room_id` (UUID FK → rooms), `session_id` (string), `knock_name` (string), `status` (string, default `"pending"`), `inserted_at` (utc_datetime_usec)
- [ ] 1.3 Run `mix ecto.migrate` and verify both migrations apply cleanly

## 2. Room Resource — invite_token Attribute

- [ ] 2.1 Add `invite_token` attribute (`:uuid_primary_key` type or `:string` with UUID constraint) to the `LetsChat.Chat.Room` Ash resource
- [ ] 2.2 Add a `before_action` change (or `change`) on the `create` action to auto-generate a UUID `invite_token` when `visibility == :private` and leave it nil otherwise
- [ ] 2.3 Confirm `invite_token` is excluded from mass-assignable attributes (not user-settable directly)

## 3. RoomKnock Ash Resource

- [ ] 3.1 Create `LetsChat.Chat.RoomKnock` module with AshPostgres data layer, registered in the `LetsChat.Chat` domain
- [ ] 3.2 Define attributes: `id` (UUID pk), `room_id`, `session_id`, `knock_name`, `status` (atom enum `[:pending, :approved, :rejected, :expired]`, default `:pending`), `inserted_at`
- [ ] 3.3 Add `belongs_to :room, LetsChat.Chat.Room` relationship
- [ ] 3.4 Implement `create` action: accepts `room_id`, `session_id`, `knock_name`; sets `status: :pending`
- [ ] 3.5 Implement `approve` action: updates `status` to `:approved`
- [ ] 3.6 Implement `reject` action: updates `status` to `:rejected`
- [ ] 3.7 Add a generic update action or use `approve`/`reject` to also handle transitioning to `:expired` (for timeout path)

## 4. Invite Link — Route and Controller

- [ ] 4.1 Add route `get "/rooms/:slug/join/:token", RoomController, :join` to the router
- [ ] 4.2 Implement `RoomController.join/2`: load room by slug, compare `invite_token`
- [ ] 4.3 On token match: add room ID to session `:authorized_rooms` via `put_session/3`, redirect to `/rooms/:slug`
- [ ] 4.4 On token mismatch or room not found: redirect to lobby with a flash error message

## 5. Lobby Query — Private Room Filtering

- [ ] 5.1 Update the lobby room list query to filter by `visibility = :public OR (visibility = :private AND id IN authorized_rooms)`
- [ ] 5.2 Pass `:authorized_rooms` from the session into `LobbyLive` mount and supply it to the query
- [ ] 5.3 Add a lock icon visual indicator next to private rooms in the lobby template for authorized visitors

## 6. Room Creation Form — Private Visibility Option

- [ ] 6.1 Add a visibility toggle (public/private) to the new-room form in the LiveView template
- [ ] 6.2 Wire the `visibility` field through the `Room` changeset so it is submitted with the form
- [ ] 6.3 After creating a private room, redirect to an invite-link display page (or render inline) showing the full `/rooms/:slug/join/:token` URL with "Copy link" and "Enter now" buttons
- [ ] 6.4 Implement clipboard copy on "Copy link" button (JS hook or `phx-hook`)
- [ ] 6.5 Wire "Enter now" button to navigate to `/rooms/:slug`

### Mobile-First Notes (Section 6)
- The invite-link display (task 6.3) must be centered with adequate horizontal padding on mobile (`px-4` or equivalent); the invite URL text should wrap or truncate gracefully — no horizontal scroll
- "Copy link" and "Enter now" buttons must each have a minimum touch target of 44px height (`min-h-[44px]` or `btn` DaisyUI class which already satisfies this); stack them vertically on mobile (`flex flex-col sm:flex-row`)
- The visibility toggle (task 6.1) must be tappable on mobile — use a full-width radio group or toggle switch, not small radio inputs
- No `md:` layout class on the invite-link panel without a mobile-first base layout class

## 7. RoomLive State Machine

- [ ] 7.1 Add `@knock_state` assign to `RoomLive` with initial value determined at mount (`:in_room` or `:blocked`)
- [ ] 7.2 Implement mount guard: check `room.visibility`, fetch `:authorized_rooms` from session, set `@knock_state` accordingly
- [ ] 7.3 Subscribe present members to `"room:{slug}:knock"` PubSub topic on mount (authorized members only)
- [ ] 7.4 Add template branches rendering different UI for `:in_room`, `:blocked`, and `:waiting` states

### Mobile-First Notes (Section 7)
- The `:blocked` gate screen (task 7.4) must be vertically and horizontally centered, with `p-4` minimum padding on all sides; it must feel like a full-page gate on small screens — use `min-h-screen flex items-center justify-center` as the outer wrapper
- The `:waiting` spinner screen (task 7.4) follows the same full-page centering pattern so it is clearly visible on small viewports
- Template branches must not assume a wide viewport; each state renders correctly at 375px width (iPhone SE baseline)

## 8. Knock Submission Flow (Visitor Side)

- [ ] 8.1 Render "Request access" form (display name input + submit button) in the `:blocked` template branch
- [ ] 8.2 Handle `phx-submit` event for knock form: call `RoomKnock.create`, transition socket to `:waiting`
- [ ] 8.3 Subscribe the visitor's `RoomLive` process to `"knock:{knock_id}"` after knock creation
- [ ] 8.4 Schedule timeout: `Process.send_after(self(), {:knock_timeout, knock_id}, 300_000)`
- [ ] 8.5 Broadcast `{:knock_request, %{knock_id: id, knock_name: name}}` to `"room:{slug}:knock"` after knock creation

### Mobile-First Notes (Section 8)
- The "Request access" form (task 8.1) must be fullscreen or near-fullscreen on mobile — use `w-full max-w-sm mx-auto` to constrain on desktop while filling available width on mobile
- The display name input must have a minimum height of 44px and an appropriately sized font (at least `text-base`) to avoid iOS auto-zoom on focus
- The submit button must span full width on mobile (`w-full`) and have `min-h-[44px]`
- The "Try again" option that appears after rejection (task 8.1 re-render in `:blocked`) must be equally accessible: full-width button, 44px touch target

## 9. Knock Notification — Member Side

- [ ] 9.1 Implement `handle_info({:knock_request, %{knock_id: _, knock_name: _}}, socket)` in `RoomLive`
- [ ] 9.2 Store pending knock info in socket assigns so the toast can be rendered
- [ ] 9.3 Render knock notification toast with visitor name, "Accept" and "Reject" buttons

### Mobile-First Notes (Section 9)
- The knock notification toast (task 9.3) must use a sticky/fixed positioning pattern so it remains visible even when the member is scrolled down in the chat — use `fixed bottom-4 left-4 right-4` (or `toast toast-bottom` DaisyUI pattern) so it does not get hidden below the fold on small screens
- "Accept" and "Reject" buttons inside the toast must each have `min-h-[44px]` and be wide enough to tap without precision on mobile; lay them out with `flex gap-2` so they do not overlap
- Toast should have adequate padding (`p-4`) and legible font size so the visitor's name is readable at a glance on a small screen

## 10. Knock Approval / Rejection — Member Actions

- [ ] 10.1 Handle `phx-click` "Accept" event: call `RoomKnock.approve`, broadcast `{:knock_approved}` to `"knock:{knock_id}"`
- [ ] 10.2 Handle `phx-click` "Reject" event: call `RoomKnock.reject`, broadcast `{:knock_rejected}` to `"knock:{knock_id}"`
- [ ] 10.3 Dismiss the knock toast from the member's UI after acting

## 11. Knock Outcome — Visitor Side

- [ ] 11.1 Implement `handle_info({:knock_approved}, socket)`: add room ID to session via `Phoenix.LiveView.put_session/3`, push redirect to `/rooms/:slug`
- [ ] 11.2 Implement `handle_info({:knock_rejected}, socket)`: show flash message, transition `@knock_state` back to `:blocked`
- [ ] 11.3 Render "Try again" option in `:blocked` state when returning from a rejection so the visitor can re-submit the knock form

## 12. Knock Timeout

- [ ] 12.1 Implement `handle_info({:knock_timeout, knock_id}, socket)`: check if knock is still `:pending` before acting
- [ ] 12.2 On pending knock: call the Ash action to set `status: :expired`, transition `@knock_state` to `:blocked` with an informational message
- [ ] 12.3 On already-resolved knock: no-op (silently ignore the message)

## 13. Waiting State UI

- [ ] 13.1 Render waiting spinner with descriptive text ("Waiting for a member to let you in…") in the `:waiting` template branch
- [ ] 13.2 Add a "Cancel" button in the `:waiting` state that resets the visitor back to the `:blocked` form

### Mobile-First Notes (Section 13)
- The waiting state screen must be centered on the full viewport height (`min-h-screen flex flex-col items-center justify-center`) — it is the only content visible, so it must feel intentional and uncluttered on mobile
- Descriptive text must be legible at small sizes (`text-sm` minimum, `text-center`, appropriate line-height)
- The "Cancel" button must have `min-h-[44px]` and be at least 160px wide (or `w-full max-w-xs`) so it is easy to tap
- The spinner itself should be large enough to be clearly visible on a small screen (`loading-lg` DaisyUI class or equivalent)

## 14. Verification and Cleanup

- [ ] 14.1 Run `mix precommit` and fix any Elixir formatting or Credo issues
- [ ] 14.2 Run `mix test` and confirm **all** knock flow BDD scenarios pass (T-K1 through T-K18 in section 15), all invite-link scenarios pass (T-PR1 through T-PR7), all Room/Lobby scenarios pass (T-R1 through T-R6), and all integration tests pass (T-INT1, T-INT2)
- [ ] 14.3 Run Vitest (`npm test` or `mix assets.build && vitest`) and confirm all Vue component tests pass (T-V1 through T-V5 in section 15)
- [ ] 14.4 Manually verify the invite-link happy path: create private room → copy link → open in incognito → confirm access granted
- [ ] 14.5 Manually verify the knock happy path: unauthorized visitor requests access → member approves → visitor enters room
- [ ] 14.6 Manually verify knock rejection path: member rejects knock → visitor receives flash and sees "Try again"
- [ ] 14.7 Manually verify knock timeout path: submit knock → wait 5 minutes (or trigger timeout in test) → visitor transitions to `:blocked` with informational message
- [ ] 14.8 Confirm private rooms are hidden from lobby for unauthorized visitors and visible (with lock icon) for authorized ones
- [ ] 14.9 Verify all UI screens on a 375px-wide viewport (mobile baseline): `:blocked` gate, `:waiting` spinner, knock toast, invite-link display page — all must render without horizontal scroll and all interactive elements must have ≥ 44px touch targets
