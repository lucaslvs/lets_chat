## ADDED Requirements

### Requirement: Visitor without access sees blocked state in RoomLive
When a visitor navigates directly to `/rooms/:slug` for a private room and does not have the room's ID in their session `:authorized_rooms`, `RoomLive` SHALL render a `:blocked` state instead of the chat UI, presenting a "Request access" option.

#### Scenario: Unauthorized visitor navigates to private room URL
- **WHEN** a visitor opens `/rooms/:slug` for a private room and the room ID is not in their session `:authorized_rooms`
- **THEN** `RoomLive` renders the `:blocked` state with a "Request access" form instead of the chat interface

#### Scenario: Authorized visitor navigates to private room URL
- **WHEN** a visitor opens `/rooms/:slug` and the room ID is present in their session `:authorized_rooms`
- **THEN** `RoomLive` renders the full chat interface (`:in_room` state)

#### Scenario: Public room visitor is never blocked
- **WHEN** a visitor opens `/rooms/:slug` for a public room
- **THEN** `RoomLive` renders the full chat interface regardless of `:authorized_rooms`

### Requirement: Visitor can submit a knock request
A visitor in the `:blocked` state SHALL be able to submit a knock request by providing a display name. The system SHALL create a `RoomKnock` record and notify present members.

#### Scenario: Submitting a knock request
- **WHEN** a visitor fills in their display name and clicks "Request access" in the `:blocked` state
- **THEN** a `RoomKnock` record is created with `status: :pending` and the visitor's session ID and display name, and the visitor's `RoomLive` transitions to `:waiting` state

#### Scenario: Knock broadcast to present room members
- **WHEN** a knock request is submitted
- **THEN** a `{:knock_request, %{knock_id: id, knock_name: name}}` message is broadcast to the `"room:{slug}:knock"` PubSub topic

#### Scenario: Members receive knock notification toast
- **WHEN** a `{:knock_request, ...}` message is received by a member's `RoomLive`
- **THEN** the member sees a toast notification with the visitor's name and "Accept" and "Reject" buttons

### Requirement: Visitor enters waiting state after submitting knock
After submitting a knock, the visitor's `RoomLive` SHALL enter the `:waiting` state, subscribe to the knock-specific PubSub topic, and schedule a 5-minute timeout.

#### Scenario: Waiting state rendered
- **WHEN** the visitor's knock is submitted
- **THEN** `RoomLive` renders a waiting spinner with a cancel option instead of the chat or blocked UI

#### Scenario: PubSub subscription for knock outcome
- **WHEN** the visitor transitions to `:waiting`
- **THEN** `RoomLive` subscribes to the `"knock:{knock_id}"` PubSub topic to receive the member's decision

#### Scenario: 5-minute timeout scheduled
- **WHEN** the visitor transitions to `:waiting`
- **THEN** `Process.send_after(self(), {:knock_timeout, knock_id}, 300_000)` is called to schedule an automatic expiry

#### Scenario: Visitor closes tab while waiting
- **WHEN** the visitor closes the browser tab while in `:waiting` state
- **THEN** the LiveView process exits, the PubSub subscription is cleaned up, and the scheduled timer is garbage-collected automatically

### Requirement: Member can approve a knock
Any authorized member currently in the room SHALL be able to approve a knock. Approval SHALL grant the visitor session access and redirect them into the room.

#### Scenario: Member approves knock
- **WHEN** a member clicks "Accept" on the knock toast
- **THEN** the `RoomKnock` status is updated to `:approved` and a `{:knock_approved}` message is broadcast to `"knock:{knock_id}"`

#### Scenario: Visitor receives approval
- **WHEN** the visitor's `RoomLive` receives `{:knock_approved}`
- **THEN** the room ID is added to the visitor's session `:authorized_rooms` via `Phoenix.LiveView.put_session/3` and the visitor is redirected into the room chat (`:in_room` state)

#### Scenario: Only one member needs to approve
- **WHEN** multiple members are present and one clicks "Accept"
- **THEN** only that member's action is processed; the knock is resolved and the visitor gains access

### Requirement: Member can reject a knock
Any authorized member currently in the room SHALL be able to reject a knock. Rejection SHALL notify the visitor and return them to the `:blocked` state.

#### Scenario: Member rejects knock
- **WHEN** a member clicks "Reject" on the knock toast
- **THEN** the `RoomKnock` status is updated to `:rejected` and a `{:knock_rejected}` message is broadcast to `"knock:{knock_id}"`

#### Scenario: Visitor receives rejection
- **WHEN** the visitor's `RoomLive` receives `{:knock_rejected}`
- **THEN** the visitor is shown a flash message and `RoomLive` transitions back to the `:blocked` state

#### Scenario: Visitor can try again after rejection
- **WHEN** the visitor is back in the `:blocked` state after a rejection
- **THEN** a "Try again" option is available to re-submit the knock form

### Requirement: Knock expires after 5 minutes without a response
If no member approves or rejects within 5 minutes, the knock SHALL automatically expire, transitioning the visitor back to `:blocked`.

#### Scenario: Timeout fires after 5 minutes
- **WHEN** `handle_info({:knock_timeout, knock_id}, socket)` is called and the knock is still `:pending`
- **THEN** the `RoomKnock` status is updated to `:expired` and the visitor's `RoomLive` transitions to `:blocked` with an informational message

#### Scenario: Timeout is a no-op if knock already resolved
- **WHEN** `handle_info({:knock_timeout, knock_id}, socket)` is called after the knock was already approved or rejected
- **THEN** no state change occurs and the message is silently ignored

#### Scenario: No members online — knock silently expires
- **WHEN** a visitor submits a knock and no members are in the room
- **THEN** no notification is sent (no member processes are subscribed to `"room:{slug}:knock"`), and the knock expires after 5 minutes

### Requirement: RoomKnock Ash resource
The system SHALL have an Ash resource `LetsChat.Chat.RoomKnock` within the `LetsChat.Chat` domain persisted in a `room_knocks` table.

#### Scenario: RoomKnock record created on knock submission
- **WHEN** a visitor submits a knock
- **THEN** a `RoomKnock` record is persisted with: `id` (UUID pk), `room_id` (FK → rooms), `session_id` (visitor's session identifier), `knock_name` (visitor display name), `status: :pending`, `inserted_at`

#### Scenario: RoomKnock status transitions
- **WHEN** a knock is approved, rejected, or timed out
- **THEN** the `RoomKnock` record's `status` is updated to `:approved`, `:rejected`, or `:expired` respectively

#### Scenario: RoomKnock actions available
- **WHEN** the `RoomKnock` resource is used
- **THEN** the following actions SHALL exist: `create` (visitor), `approve` (member), `reject` (member)

## Test Requirements

| Scenario | Test type | Test ID | Notes |
|---|---|---|---|
| Unauthorized visitor navigates to private room URL | LiveViewTest (`RoomLiveTest`) | T-K1 | Mount with session missing room ID; assert `:blocked` state rendered |
| Authorized visitor navigates to private room URL | LiveViewTest (`RoomLiveTest`) | T-K2 | Mount with room ID in session `:authorized_rooms`; assert chat UI rendered |
| Public room visitor is never blocked | LiveViewTest (`RoomLiveTest`) | T-K3 | Mount public room with empty `:authorized_rooms`; assert chat UI rendered |
| Submitting a knock request | LiveViewTest (`RoomLiveTest`) | T-K4 | Submit knock form; assert `RoomKnock` created with `status: :pending` and socket in `:waiting` |
| Knock broadcast to present room members | LiveViewTest (`RoomLiveTest`) | T-K5 | Subscribe test process to `"room:{slug}:knock"`; submit knock; assert broadcast received |
| Members receive knock notification toast | LiveViewTest (`RoomLiveTest`) | T-K6 | Send `{:knock_request, ...}` info message to member LV; assert toast HTML rendered |
| Waiting state rendered | LiveViewTest (`RoomLiveTest`) | T-K7 | After knock submit; assert spinner and cancel button in rendered HTML |
| PubSub subscription for knock outcome | LiveViewTest (`RoomLiveTest`) | T-K8 | After knock submit; assert LV subscribed to `"knock:{knock_id}"` (verify via broadcast round-trip) |
| 5-minute timeout scheduled | LiveViewTest (`RoomLiveTest`) | T-K9 | After knock submit; send `{:knock_timeout, knock_id}` directly; assert `:blocked` transition (validates handler, not exact timer) |
| Visitor closes tab while waiting | — | — | Covered implicitly by process-exit semantics; no explicit test required (no side-effects to assert) |
| Member approves knock | LiveViewTest (`RoomLiveTest`) | T-K10 | Click "Accept" phx event; assert `RoomKnock` status `:approved` and broadcast to `"knock:{knock_id}"` |
| Visitor receives approval | LiveViewTest (`RoomLiveTest`) | T-K11 | Send `{:knock_approved}` to visitor LV; assert session updated and redirect issued |
| Only one member needs to approve | LiveViewTest (`RoomLiveTest`) | T-K10 | Implicit in approve test; only one action expected per knock |
| Member rejects knock | LiveViewTest (`RoomLiveTest`) | T-K12 | Click "Reject" phx event; assert `RoomKnock` status `:rejected` and broadcast |
| Visitor receives rejection | LiveViewTest (`RoomLiveTest`) | T-K13 | Send `{:knock_rejected}` to visitor LV; assert flash and `:blocked` state |
| Visitor can try again after rejection | LiveViewTest (`RoomLiveTest`) | T-K14 | After rejection, assert "Try again" option present in rendered HTML |
| Timeout fires after 5 minutes | LiveViewTest (`RoomLiveTest`) | T-K15 | Send `{:knock_timeout, knock_id}` to LV with pending knock; assert `:expired` status and `:blocked` state |
| Timeout is a no-op if knock already resolved | LiveViewTest (`RoomLiveTest`) | T-K16 | Approve knock first, then send `{:knock_timeout, knock_id}`; assert no state change |
| No members online — knock silently expires | LiveViewTest (`RoomLiveTest`) | T-K15 | Covered by timeout test — no members needed for handler to run |
| RoomKnock record created on knock submission | ExUnit (`RoomKnockTest`) | T-K17 | Call `RoomKnock.create/1` directly; assert all attributes persisted |
| RoomKnock status transitions | ExUnit (`RoomKnockTest`) | T-K18 | Call `approve` and `reject` actions; assert status changes |
| RoomKnock actions available | ExUnit (`RoomKnockTest`) | T-K18 | Covered by T-K17/T-K18 action call tests |
| Knock submission → approve → join (integration) | LiveViewTest (integration) | T-INT1 | Full flow across visitor and member LV instances in a single test |
