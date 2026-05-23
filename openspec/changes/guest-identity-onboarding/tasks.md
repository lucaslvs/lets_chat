## Execution Order

```
[1] Avatar Helpers & Component   ← must be first (2 and 3 depend on it)
     ├── [2] HomeLive            ← parallel with [3]
     └── [3] Session Guard       ← parallel with [2]
              └── [4] Router     ← after [2] + [3]
                       └── [5] Cleanup
```

> Sub-agent opportunity: after completing section 1, spawn two parallel sub-agents — one for HomeLive (section 2) and one for Session Guard (section 3).

---

## 1. Avatar Helpers & Component

- [ ] 1.1 Add `avatar_initials/1` and `avatar_color/1` as **public** functions (`def`, not `defp`) to `LetsChatWeb.CoreComponents` — initials extracts up to 2 words' first letters; color uses `:erlang.phash2(name, length(@avatar_colors))` against the 7 DaisyUI semantic color tokens; must be public because `RoomLive.serialize/1` (Change 3) and `LetsChatWeb.Presence` metadata (Change 4) call them directly
- [ ] 1.2 Add `<.avatar>` function component to `core_components.ex` with attrs `name` (required), `src` (default nil), `size` (default `:md`), `class` (default `""`); render `<img>` when `src` present, initials `<div>` otherwise; map size to DaisyUI width classes (`w-6 / w-8 / w-10 / w-14`)

### Mobile-First Notes (Avatar Component)
- Size mapping must cover all screen sizes; `:sm` (`w-6 h-6`) and `:md` (`w-10 h-10`) are the default sizes used on mobile — do not rely on size scaling via `md:` breakpoint modifiers
- Initials text size must scale proportionally with the avatar size using DaisyUI or Tailwind text utilities (e.g. `text-xs` for `:sm`, `text-sm` for `:md`)
- `<img>` and initials `<div>` must both use `rounded-full` to maintain circular shape at any screen density
- All interactive wrappers around `<.avatar>` (if any) must have at least 44px touch target area; use `p-1` padding on the wrapper if the avatar itself is smaller than 44px

## 2. HomeLive

- [ ] 2.1 Create `lib/lets_chat_web/live/home_live.ex` — in `mount/3`: generate and write `guest_session_id` to session if absent; redirect to `return_to` (default `/rooms`) if `current_user` present or `guest_name` already in session; assign `name: ""` and `return_to` from params
- [ ] 2.2 Add `handle_event("validate", %{"name" => name}, socket)` — update `:name` assign (no session write yet)
- [ ] 2.3 Add `handle_event("submit", %{"name" => name}, socket)` — trim name, return error assign if blank; on valid: call `put_session(socket, "guest_name", name)`, `push_navigate` to `socket.assigns.return_to`
- [ ] 2.4 Create `lib/lets_chat_web/live/home_live.html.heex` — DaisyUI card with name `<input>` (`phx-change="validate"`, `phx-submit="submit"`), live `<.avatar>` preview bound to `:name` assign, submit button "Explorar salas"

### Mobile-First Notes (HomeLive)
- Name input must be `w-full` on mobile (no `md:` prefix without a mobile base); min height `h-12` or `min-h-[44px]` for accessible tap target
- Submit button "Explorar salas" must have `w-full` on mobile and a minimum height of 44px (`min-h-[44px]` or `btn-lg`)
- The DaisyUI card wrapper must use `w-full max-w-sm mx-auto` so it fills the screen on small viewports and is centered on larger ones
- Avatar preview must have at least `w-10 h-10` on mobile (matching the `:md` size in the `<.avatar>` component)
- No `md:` layout class without a corresponding mobile base class on the same element

## 3. Session Guard

- [ ] 3.1 Add `on_mount :require_guest_name` to `LetsChatWeb.LiveUserAuth` — if `current_user` present: `:cont`; else if `session["guest_name"]` present: `:cont`; else: `:halt` + redirect to `/?return_to=<current_path>` (path derived from socket's `host_uri` + `view`)
- [ ] 3.2 Add `validate_return_to/1` private function — parse with `URI.parse/1`, return default `/rooms` if `host` field is non-nil (rejects external URLs)

## 4. Router

- [ ] 4.1 Move the `get "/", PageController, :home` route: replace with `live "/", HomeLive, :index` inside the `ash_authentication_live_session` block (no extra `on_mount` needed here — `HomeLive` handles redirect logic internally)
- [ ] 4.2 Verify auth routes (`/sign-in`, `/register`, etc.) still work and their `live_no_user` guard still redirects authenticated users to `/`

## 5. Cleanup

- [ ] 5.1 Delete `lib/lets_chat_web/controllers/page_controller.ex` and `lib/lets_chat_web/controllers/page_html/home.html.heex` after confirming no other routes reference `PageController`
- [ ] 5.2 Run `mix precommit` and fix any formatter or Credo warnings

## 6. Verification

- [ ] 6.1 Run `mix test` and confirm all tests pass, including the ExUnit/LiveViewTest tests added in section 8 that cover each BDD scenario from `specs/guest-identity/spec.md`
- [ ] 6.2 Run Vitest (`npm run test --prefix assets`) if any Vue components were introduced or modified in this change
- [ ] 6.3 Manually verify the onboarding flow end-to-end on a mobile viewport (e.g. 375px width): enter a name, confirm avatar preview updates, submit, confirm redirect to `/rooms`
- [ ] 6.4 Manually verify the `return_to` flow: navigate directly to `/rooms`, confirm redirect to `/?return_to=/rooms`, complete onboarding, confirm landing on `/rooms`

---

## 8. Tests

> Each test entry references the BDD scenario it covers from `specs/guest-identity/spec.md`.

### ExUnit / LiveViewTest

- [ ] 8.1 `HomeLiveTest` — "renders the onboarding form for a new unauthenticated visitor" — covers: *New visitor submits a name* (precondition: no session)
- [ ] 8.2 `HomeLiveTest` — "submitting a valid name writes guest_session_id and guest_name to session and redirects to /rooms" — covers: *New visitor submits a name*
- [ ] 8.3 `HomeLiveTest` — "submitting a valid name with return_to redirects to the return_to path" — covers: *Onboarding with return_to resumes the original destination*
- [ ] 8.4 `HomeLiveTest` — "submitting a blank or whitespace-only name shows a validation error and does not persist session" — covers: *Blank name is rejected*
- [ ] 8.5 `HomeLiveTest` — "authenticated user visiting / is redirected to /rooms without seeing the form" — covers: *Authenticated user is redirected past onboarding*
- [ ] 8.6 `HomeLiveTest` — "returning guest with guest_name in session is redirected to /rooms" — covers: *Returning guest bypasses onboarding*
- [ ] 8.7 `HomeLiveTest` — "guest_session_id is generated and written to session on mount before form submission" — covers: *guest_session_id is stable across submits*
- [ ] 8.8 `HomeLiveTest` — "avatar preview changes on phx-change validate event when name is typed" — covers: *Avatar preview updates live during input*
- [ ] 8.9 `CoreComponentsTest` — "avatar_initials/1 returns single uppercase letter for a one-word name" — covers: *Single-word name produces one initial*
- [ ] 8.10 `CoreComponentsTest` — "avatar_initials/1 returns two uppercase letters for a multi-word name" — covers: *Multi-word name produces two initials*
- [ ] 8.11 `CoreComponentsTest` — "avatar_color/1 returns the same DaisyUI color token for the same name across multiple calls" — covers: *Same name always yields same color*
- [ ] 8.12 `CoreComponentsTest` — "avatar/1 component renders an img tag when src is provided (Gravatar upgrade path)" — covers: *Gravatar URL is used as avatar src when provided*
- [ ] 8.13 `LiveUserAuthTest` — "require_guest_name halts and redirects to /?return_to=<path> when no identity is present" — covers: *Unauthenticated visitor without name is redirected*
- [ ] 8.14 `LiveUserAuthTest` — "require_guest_name allows access when guest_name is present in session" — covers: *Unauthenticated visitor without name is redirected* (happy path)
- [ ] 8.15 `LiveUserAuthTest` — "require_guest_name allows access when current_user is present, regardless of guest_name" — covers: *Authenticated user satisfies the guard*
- [ ] 8.16 `HomeLiveTest` (or `LiveUserAuthTest`) — "validate_return_to/1 rejects a return_to value containing a host component and falls back to /rooms" — covers: *return_to rejects external URLs*

### Vitest (Vue components)

No Vue components are introduced in this change. If a LiveVue component is added in a follow-up change that wraps the avatar or the onboarding form, add Vitest tests here at that point.
