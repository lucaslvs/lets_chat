## Context

The app currently serves `/` via `PageController`, a static controller with no session logic. There is no concept of guest identity — anyone navigating to `/rooms` (once it exists) would have no name or avatar to display in the chat.

`LetsChatWeb.LiveUserAuth` already handles authenticated users via `on_mount` guards, but has no pattern for guest session validation. The session cookie is managed by Phoenix's default session plug.

This change establishes the identity foundation that every subsequent change depends on: rooms-lobby needs a name to display, chat-core needs a name to attribute messages, presence-interactivity needs a name + color to render participant avatars.

## Goals / Non-Goals

**Goals:**

- Replace the static home controller with a `HomeLive` that collects a display name before entering the app
- Persist a minimal guest session (`session_id` + `name`) in the Phoenix cookie session
- Compute avatar (initials + deterministic color) from `name` at render time — never stored
- Add `on_mount :require_guest_name` guard to `LiveUserAuth` with `return_to` support
- Provide a reusable `<.avatar>` function component for use across all LiveViews
- Handle authenticated users transparently: skip the form, use email as display name

**Non-Goals:**

- Linking guest `session_id` to a `User` record (deferred to post-Change 3)
- Persistent name across sessions (cookie expiration resets identity — intentional)
- Profile editing after onboarding (out of scope for all 5 changes)
- Gravatar fetching or any external HTTP request for avatars

## Decisions

### 1. Home route is a LiveView, not a Controller

`HomeLive` replaces `PageController` at `/`. Since Phoenix LiveView 1.0+, `put_session/3` is available inside LiveView, making a controller redirect for session persistence unnecessary. This keeps the pattern consistent with the rest of the app and enables the live avatar preview (`phx-change` → recompute initials) without a round-trip.

Alternative considered: keep a controller as a POST handler for the form and redirect back. Rejected — adds indirection with no benefit.

### 2. Session structure: `{session_id: UUID, name: string}` only

The cookie session stores exactly two keys under the `:guest` namespace (or top-level if simpler):

```
session["guest_session_id"]  # UUID, generated once on HomeLive mount if absent
session["guest_name"]        # String, set on form submit
```

`avatar_initials` and `avatar_color` are **never** stored. They are computed from `name` on every render via a pure function. Changing the name in the future automatically changes the avatar without any migration.

Alternative considered: storing avatar color to avoid recomputation. Rejected — phash2 is O(1), and storing derived state creates sync risk.

### 3. Deterministic avatar color via `:erlang.phash2/2`

```elixir
@avatar_colors ["primary", "secondary", "accent", "info", "success", "warning", "error"]

def avatar_color(name) do
  Enum.at(@avatar_colors, :erlang.phash2(name, length(@avatar_colors)))
end
```

Uses DaisyUI semantic color tokens (not hex values), so the avatar adapts to theme changes automatically. The hash is stable across processes and nodes — the same name always yields the same color.

Alternative considered: MD5 of name. Rejected — `:erlang.phash2` is built-in and sufficient; no need for `:crypto`.

### 4. `on_mount :require_guest_name` with `return_to`

Added to `LetsChatWeb.LiveUserAuth`. Guards routes that require identity (all `/rooms/*` routes). Logic:

```
if current_user → :cont  (authenticated users are always identified)
else if session["guest_name"] present → :cont
else → :halt + redirect to /?return_to=<current_path>
```

`return_to` is read from params on `HomeLive` mount and stored in socket assigns. After the form is submitted, `push_navigate` uses the stored `return_to` value (defaulting to `/rooms`).

`return_to` is validated to only accept paths (not full URLs) to prevent open redirect. Validation: `URI.parse(value).host == nil`.

### 5. `<.avatar>` component API

Function component in `LetsChatWeb.CoreComponents`:

```elixir
attr :name, :string, required: true
attr :src, :string, default: nil      # Gravatar URL for authenticated users
attr :size, :atom, default: :md       # :xs | :sm | :md | :lg
attr :class, :string, default: ""
```

Size maps to DaisyUI avatar size classes: `w-6` (xs), `w-8` (sm), `w-10` (md), `w-14` (lg).

When `src` is provided (authenticated user with Gravatar), renders `<img>`. When `src` is nil, renders a `<div>` with initials text and `bg-{color}` DaisyUI class. The two rendering paths share the outer DaisyUI `avatar` wrapper markup.

### 6. `HomeLive` assigns and events

```
assigns:
  :name          String.t()  — current input value, "" on mount
  :return_to     String.t()  — path to navigate after submit, default "/rooms"
  :current_user  User.t() | nil — from AshAuthentication session
```

Events:
- `"validate"` (phx-change on form): updates `:name` assign, re-renders avatar preview
- `"submit"` (phx-submit on form): calls `put_session/3`, then `push_navigate` to `:return_to`

On mount, if `current_user` is present, immediately `push_navigate` to `:return_to` — authenticated users skip onboarding. If `session["guest_name"]` is already set (returning guest), same redirect.

## Risks / Trade-offs

**Cookie session size** → The Phoenix session cookie has a ~4KB limit. Adding two small string keys poses no risk, but downstream changes must not bloat the session (e.g., storing full room history). Mitigation: authorized_rooms in Change 5 stores only room IDs (UUIDs), not names.

**Avatar color collisions** → With 7 colors and `phash2`, collisions are expected (~14% chance any two users share a color). This is a UX trade-off, not a bug — the goal is visual differentiation, not uniqueness. Accepted.

**`return_to` open redirect** → A crafted `?return_to=https://evil.com` would be a security issue. Mitigation: validate that `return_to` has no host component (internal paths only) before using it in `push_navigate`.

**Guest identity loss on cookie expiry** → When the session cookie expires, the user loses their name and must re-onboard. This is intentional for the guest flow but means any messages sent in that session are no longer attributed to a recognizable identity. Accepted for MVP; persistent identity is part of the authenticated user path.
