## MODIFIED Requirements

### Requirement: Lobby displays real-time room occupancy
The lobby SHALL display an active badge next to each room entry showing the number of users currently present, derived from Phoenix.Presence data on the `"lobby"` topic. Rooms with zero occupancy SHALL NOT display a badge.

#### Scenario: Room has active users
- **WHEN** one or more users are present in a room
- **THEN** the lobby displays an active badge on that room's entry showing the current occupant count
- **THEN** the badge updates automatically when users join or leave without a page refresh

#### Scenario: Room has no active users
- **WHEN** no users are present in a room
- **THEN** the lobby does NOT display an active/online badge for that room

#### Scenario: Lobby receives real-time updates
- **WHEN** `LobbyLive` mounts
- **THEN** it subscribes to the `"lobby"` Presence topic
- **WHEN** any user joins or leaves any room
- **THEN** `LobbyLive` updates the occupancy counts for affected rooms without a full page reload

---

## Test Requirements

| Scenario | Test Type | Notes |
|---|---|---|
| Room has active users — badge rendered | **LiveViewTest** (`ExUnit`) | Mount `LobbyLive`; inject a Presence entry on `"lobby"` with `%{slug: "general"}`; assert the DaisyUI badge is present in the rendered HTML with count `>= 1` |
| Room has no active users — badge absent | **LiveViewTest** (`ExUnit`) | With no Presence entries for a room slug, assert no active badge is rendered for that room |
| Lobby receives real-time updates — join | **LiveViewTest** (`ExUnit`) | After `LobbyLive` mounts, inject a new Presence entry and assert the rendered HTML updates (badge appears) without a page reload |
| Lobby receives real-time updates — leave | **LiveViewTest** (`ExUnit`) | Remove the Presence entry injected above; assert the badge disappears from the rendered HTML |
