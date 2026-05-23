## Context

LetsChat currently supports only public rooms — all rooms are visible to every user in the lobby. This change introduces private rooms with two access paths: a permanent invite-link (magic link) and a real-time "knock" flow for visitors who arrive via URL without a token.

The system is built on Phoenix 1.8.7 + LiveView 1.1.0, Ash Framework 3.x (AshPostgres), Phoenix.PubSub, and DaisyUI/Tailwind (Kraken design system). Authorization in the app uses Phoenix sessions; there is no concept of authenticated "room membership" rows — access is tracked as a list of room IDs in the guest session (`:authorized_rooms`).

This change depends on:
- **rooms-lobby** (Change 2): `visibility` field on `Room`, `authorized_rooms` session concept, lobby query skeleton
- **chat-core** (Change 3): `RoomLive` lifecycle, mount/params handling
- **presence-interactivity** (Change 4): `LetsChat.Presence` setup, `"lobby"` and `"room:{slug}"` topics

## Goals / Non-Goals

**Goals:**
- Allow room creators to mark a room as private at creation time
- Generate a permanent `invite_token` (UUID) per private room; expose access via `/rooms/:slug/join/:token`
- Hide private rooms from the lobby for visitors without access
- Let visitors who navigate directly to `/rooms/:slug` without authorization submit a knock request
- Notify present room members of knock requests via PubSub + real-time UI toast
- Let any present member approve or reject a knock; grant or deny session access accordingly
- Time-out unanswered knocks after 5 minutes, transitioning the visitor to `:blocked`
- Persist granted access in Phoenix session (`:authorized_rooms`) so it survives page reloads without DB queries

**Non-Goals:**
- Authenticated membership rows or persistent access grants beyond the session
- Token expiration or revocation (regenerating `invite_token` is out of scope)
- Queuing knocks for offline members to review later
- Notifying the visitor differently when no members are present
- Restricting which member can approve/reject a knock (any present member may act)
- Rate limiting knock submissions

## Decisions

### 1. Authorization stored in Phoenix session (`authorized_rooms`)

Access to a private room is tracked as a list of room IDs (UUIDs) at `:authorized_rooms` in the Phoenix session, written with `put_session(conn, :authorized_rooms, [room_id | existing])` (for controller-based join flows) or `Phoenix.LiveView.put_session/3` (from inside LiveView).

**Why:** No DB round-trip on every `RoomLive` mount; persists across reloads naturally; works without user accounts.

**Alternatives considered:**
- Signed tokens in URL params: leak via referrer header, can't be invalidated easily.
- DB-backed `room_memberships` table: heavier, requires authenticated users.

### 2. Single permanent `invite_token` per room (UUID, no expiration)

A UUID `invite_token` is generated at room creation and stored on the `Room` record. The invite URL is `/rooms/:slug/join/:token`. The token never expires while the room exists.

**Why:** Simplest implementation that satisfies the invite-link use-case. The permanent nature is a feature for small groups who share the link once and reuse it.

**Alternatives considered:**
- Time-limited tokens: adds complexity (cron/Oban sweep, user-facing expiry messaging) for marginal security gain in a private-group chat context.
- Per-user invite tokens: requires user accounts.

**Token validation flow (controller action for `/rooms/:slug/join/:token`):**
1. Load room by slug, compare `invite_token`.
2. On match → `put_session(:authorized_rooms, ...)` → redirect to `/rooms/:slug`.
3. On mismatch → redirect to lobby with flash error.

### 3. Knock triggered from `RoomLive`, not from lobby

Private rooms are invisible in the lobby to unauthorized visitors. The knock flow begins when a visitor navigates directly to `/rooms/:slug` without being in `:authorized_rooms`.

`RoomLive` mount checks session `:authorized_rooms`. If the room is private and the visitor is not authorized, the LiveView starts in state `:blocked` and renders a "Request access" UI instead of the chat.

**Why:** Decouples knock discoverability from lobby visibility. Avoids the confusing "room visible but no access" UX. Visitors typically get the URL from someone who shares it.

**Alternatives considered:**
- Show knock button in lobby for visible private rooms: requires leaking room name in lobby, conflates two features.

### 4. `RoomLive` state machine: `:in_room | :waiting | :blocked`

The LiveView holds a `@knock_state` assign driven by the following transitions:

| State | Condition | UI |
|---|---|---|
| `:in_room` | `room.visibility == :public` OR `room.id in authorized_rooms` | Full chat UI |
| `:blocked` | Private, not authorized, knock not yet submitted OR rejected OR timed out | "Request access" form |
| `:waiting` | Knock submitted, awaiting member response | Waiting spinner + cancel |

Transitions:
- Mount → `:in_room` or `:blocked` (guard check)
- User submits knock form → create `RoomKnock` → broadcast → subscribe `"knock:{knock_id}"` → schedule `Process.send_after(:knock_timeout, 300_000)` → `:waiting`
- `handle_info({:knock_approved, ...})` → `put_session(:authorized_rooms, ...)` → redirect → `:in_room`
- `handle_info({:knock_rejected, ...})` → `:blocked` (with flash)
- `handle_info({:knock_timeout, knock_id})` → update `RoomKnock` status to `:expired` → `:blocked`

**Why a state machine:** Keeps conditional rendering simple; each state maps to exactly one rendered template branch.

### 5. PubSub contracts

Two topics per knock lifecycle:

- **`"room:{slug}:knock"`** — subscribed by `RoomLive` instances of authorized members in that room.
  - Message on knock created: `{:knock_request, %{knock_id: id, knock_name: knock_name}}`
- **`"knock:{knock_id}"`** — subscribed by the visitor's `RoomLive` process.
  - Message on approve: `{:knock_approved}`
  - Message on reject: `{:knock_rejected}`

Member actions (`approve`/`reject`) are sent via LiveView events (`phx-click`), call the `RoomKnock` Ash action, then broadcast to `"knock:{knock_id}"` and also add `:authorized_rooms` entry (approve path) or just broadcast (reject path).

**Why separate topics:** Cleanly separates "room members listening for knocks" from "visitor listening for their knock outcome." Avoids filtering noise on either side.

### 6. Timeout managed by `Process.send_after` — no Oban

The 5-minute knock timeout is managed entirely in the visitor's LiveView process:

```elixir
Process.send_after(self(), {:knock_timeout, knock_id}, 300_000)
```

On `handle_info({:knock_timeout, knock_id})`: mark `RoomKnock` status `:expired`, transition visitor to `:blocked`.

If the visitor closes the tab, the LV process exits and the timer is garbage-collected automatically — no orphaned records in a "pending" state beyond the 5-minute window.

**Why:** Zero infrastructure overhead; aligns naturally with LV process lifecycle. Oban would be over-engineering for a 5-minute in-process timer with no durability requirement.

**Alternatives considered:**
- Oban job: persistent, survives server restarts, but adds a queue, worker module, and migration for a simple UX timeout.
- GenServer timer per knock: same outcome as `send_after` but more indirection.

### 7. Ash Resource `RoomKnock`

New resource in the `LetsChat.Chat` domain:

| Attribute | Type | Notes |
|---|---|---|
| `id` | `UUID` (pk) | Auto-generated |
| `room_id` | `UUID` | FK → `Room` |
| `session_id` | `string` | Visitor session identifier |
| `knock_name` | `string` | Display name entered by visitor |
| `status` | `atom enum` | `[:pending, :approved, :rejected, :expired]`, default `:pending` |
| `inserted_at` | `utc_datetime_usec` | Auto-set |

Actions: `create` (visitor), `approve` (member), `reject` (member).

### 8. Lobby query for private rooms

```sql
WHERE visibility = 'public'
   OR (visibility = 'private' AND id = ANY(:authorized_rooms))
```

`:authorized_rooms` is passed from session. Members with access see their private rooms with live Presence counts; unauthorized visitors do not see them at all.

### 9. Presence slug leak (accepted tradeoff)

Users inside a private room register in the `"lobby"` Presence topic as `%{room_slug: slug}`. Other `LobbyLive` subscribers can observe the slug (not the room name) in Presence diffs. This leaks slug existence but not room content or name.

**Accepted tradeoff:** Correct Presence-based member counts for authorized lobby viewers outweigh the minimal slug-existence leak. Fixing this properly would require a separate Presence topic per room and cross-topic count aggregation — out of scope.

## Risks / Trade-offs

- **Session-only access grants** → If a user clears their cookies/session, they lose access to private rooms they entered via knock. They would need to knock again. Mitigation: document this limitation; in a future change, introduce persistent membership for logged-in users.

- **Any member can approve/reject** → There is no owner/admin concept. Any present member seeing the knock toast can accept or reject. Mitigation: acceptable for small private groups; ownership model is out of scope.

- **No re-knock after rejection** → After a reject or timeout the visitor lands on `:blocked` with no visible way to knock again unless they navigate away and back. Mitigation: add a "Try again" button that resets to the knock form within the `:blocked` state.

- **Presence slug leak** → Private room slugs are observable in `"lobby"` Presence diffs (see Decision 9). Mitigation: accepted tradeoff; no sensitive information beyond slug string.

- **No knock queue for offline members** → If no members are online, knocks silently expire. Mitigation: out of scope per proposal; visitor can try again later or get the invite link from the room creator.

- **`invite_token` in URL / server logs** → The token appears in the URL path, meaning it may appear in server access logs. Mitigation: acceptable for a low-security group-chat context; production deployments should configure log filtering if required.

## Migration Plan

1. Add migration: `alter table(:rooms)` — add `invite_token uuid` column (nullable initially, backfilled or left null for existing public rooms).
2. Add migration: create `room_knocks` table with all attributes above.
3. Deploy: no downtime risk — additive columns only.
4. Rollback: drop `room_knocks` table; remove `invite_token` column from `rooms`.

No data transformation required. Existing public rooms are unaffected.

## Open Questions

- Should the "Request access" knock form ask for a display name, or use the visitor's existing session name if one exists? (Proposal implies a name input — confirm UX.)
- Should approved knocks' `RoomKnock` records be cleaned up over time, or retained for an audit log? (Retention policy undefined.)
- Should private room slugs be excluded from `"lobby"` Presence to eliminate the slug-leak tradeoff? (Deferred to a future change.)
