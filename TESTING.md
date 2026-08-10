# Testing MistPanel (Phase 1)

Phase 1 is the "party frame shell" only: a five-slot block, role
ordering, a health bar, scale presets, lock/unlock + dragging, hide when
solo, and optional auto-hiding of the default Blizzard party frames.
There is **no** aggro/dispel/range/dead styling, **no** HoT bars, and
**no** click-casting yet — those are later phases and are intentionally
absent right now.

## 1. Install

1. Locate your WoW Retail AddOns folder, typically:
   - Windows: `World of Warcraft\_retail_\Interface\AddOns\`
   - macOS: `World of Warcraft/_retail_/Interface/AddOns/`
2. Copy the entire `MistPanel` folder from this repo (the folder that
   contains `MistPanel.toc`) into that AddOns directory, so you end up
   with `Interface/AddOns/MistPanel/MistPanel.toc`.
3. Fully restart WoW (or if already at the character-select screen,
   just log in — addon lists are read at launch).
4. At the character-select screen, open **AddOns** and confirm
   "Mist Panel" is listed and enabled.

### If the addon refuses to load ("out of date")
The `.toc` declares `## Interface: 120007`, a computed guess for Retail
12.0.7 ("Midnight"). This number has **not** been confirmed against a
live client. If WoW refuses to load the addon as out of date:
1. Enable **Load out of date AddOns** in the AddOns list, or
2. In-game, run `/dump select(4, GetBuildInfo())` to get your client's
   real interface number, then edit the first line of `MistPanel.toc` to
   match it exactly.

## 2. What to verify in-game

Log in on your Mistweaver Monk. Nothing installed here reads talents or
class — role sorting works off `UnitGroupRolesAssigned`, so any class
works for testing group behaviour.

### 2.1 Hidden while solo
- Solo, out of a group: the panel should be completely invisible
  (no empty frames, no placeholder).

### 2.2 Basic group (2-4 players)
- Group with at least one other player (an alt on a second account, a
  friend, or a low-level dungeon queue).
- You should see one frame per real group member — not always 5 — near
  the center of the screen (default position), stacked vertically with
  a small gap between them.
- Verify frame background is near-black, and each frame shows a small
  role icon in the top-left area (tank/healer/DPS icon matching each
  member's actual assigned role).
- Verify the healer/role icon on **your own** frame shows correctly.

### 2.3 Role ordering
- With a tank, healer, and DPS all present, confirm the vertical order
  is Tank, then Healer (you, presumably), then DPS — top to bottom.
- If two DPS are present, confirm their relative order doesn't visibly
  swap/jitter across normal roster updates (e.g. someone briefly
  disconnecting and reconnecting).

### 2.4 Health bar behaviour
- Take damage (or have a group member take damage) and confirm the thin
  bottom bar on that unit's frame shrinks from the **right edge toward
  the left** as health drops (left edge stays fixed).
- Confirm the bar color shifts from green (high health) toward red
  (low/critical health), and that it's a single flat color at any given
  moment (not a rainbow gradient across the bar's own width).
- Heal back up and confirm the bar grows back out to the right and the
  color shifts back toward green.

### 2.5 Full 5-player group
- If possible, get a full 5-player dungeon group (queue for anything,
  even a low-level dungeon). Confirm all 5 frames render correctly and
  role ordering is Tank → Healer → DPS → DPS → DPS.

### 2.6 No raid mode
- Convert your party to a raid (or queue something that puts you in a
  raid group) and confirm the entire panel disappears while in a raid
  group, then reappears if you convert back to a party.

### 2.7 Lock / Unlock / drag / persistence
Use the temporary Phase 1 test command (see note below):
- `/mistpanel unlock` — the panel should now be draggable; click and
  drag anywhere on the block (including on top of a slot frame) and
  confirm it moves as a single unit, not frame-by-frame.
- `/mistpanel lock` — confirm dragging no longer moves it.
- While unlocked, move it somewhere, then `/reload` (or fully relog).
  Confirm it reappears in the same position you left it.

### 2.8 Scale presets
- `/mistpanel scale small`, `/mistpanel scale medium`,
  `/mistpanel scale large` — confirm the entire block (frame size,
  health bar thickness, role icon size) scales proportionally, and that
  nothing looks stretched, misaligned, or clipped at any of the three
  sizes.

### 2.9 Blizzard party frame auto-hide
- With the default (`/mistpanel status` should show
  `hideBlizzardPartyFrames: true`), join a group and confirm Blizzard's
  own default party frames do **not** appear.
- `/mistpanel blizzframes off`, then rejoin/re-trigger a roster update
  (e.g. leave and rejoin the group, or `/reload`) and confirm Blizzard's
  default party frames **do** appear again.
- `/mistpanel blizzframes on` to restore the default.
- Watch for any red Lua error popups during these toggles, especially
  right as combat starts/ends or when party composition changes while
  in combat (e.g. someone disconnects/reconnects mid-fight). If you
  don't normally see Lua errors, enable them with
  `/console scriptErrors 1`, or install a lightweight error-catcher
  addon (e.g. BugSack + BugGrabber) for a readable log instead of popups.

### 2.10 General health check
- Watch for any Lua errors on login, on joining/leaving a group, and
  during ordinary combat health-change spam (a full dungeon pull is a
  good stress test).

## 3. Temporary test command

Phase 1 has no settings UI yet (that's Phase 5), so a minimal
`/mistpanel` slash command exists purely to exercise Phase 1 mechanics:

```
/mistpanel lock
/mistpanel unlock
/mistpanel scale small|medium|large
/mistpanel blizzframes on|off
/mistpanel status
```

This is scaffolding for testing, not a designed feature — expect it to
be replaced, not extended, once Phase 5 delivers the real configuration
UI.

## 4. What I could not verify without running the game

Everything below was written against documented WoW API behaviour and
Phase 0's research, and passed a Lua-level smoke test against a stubbed
API (catches typos/logic errors, not real game behaviour), but none of
it has been confirmed against an actual running client:

- **Interface version number.** `120007` is a computed guess for
  12.0.7; unconfirmed.
- **`CompactPartyFrame` as the correct global.** This is the frame name
  Phase 0's research identified for the default party frame system;
  whether it's still correct on your exact client build is unverified.
  The addon checks `if CompactPartyFrame then ...` so if the global is
  missing entirely, the auto-hide feature silently does nothing rather
  than erroring — but that also means it just won't work if the name
  has changed, with no visible error to tell you why.
- **Whether the secure-driver hide/unhide approach is actually
  taint-free in this client**, including across mid-combat roster
  changes (disconnect/reconnect, mid-fight join). This was Phase 0's
  own flagged "needs in-game proof of concept" item and is still open.
- **`GetTexCoordsForRoleSmallCircle` existing and rendering the correct
  icon.** The code degrades gracefully (hides the icon) if the function
  is missing, but visual correctness when present is unverified.
- **All visual/layout judgment calls**: whether 210x50px frames at the
  three scale presets actually look right, whether 4px gaps read as
  "small," whether the near-black background/border contrast is
  legible against typical UI backgrounds — the spec gives target
  numbers, not a rendered reference, so these are only as correct as
  the numbers were followed.
- **Drag/clamp feel and position persistence across relog**, in
  practice rather than in the stubbed logic test.
- **Any runtime error that only manifests against real WoW frame/event
  behavior** — the Lua smoke test (see repo `MistPanel/` — the stub
  script itself isn't checked in) exercises every function path with
  fake data, but it is not a substitute for the real client.

Please report back anything in this list that fails, along with any
Lua error text, so it can be fixed before Phase 2 starts.
