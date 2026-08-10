# Testing MistPanel (Phase 1)

Phase 1 is the "party frame shell" only: a five-slot block, role
ordering, a health bar, scale presets, lock/unlock + dragging, hide when
solo, and optional auto-hiding of the default Blizzard party frames.
There is **no** aggro/dispel/range/dead styling, **no** HoT bars, and
**no** click-casting yet — those are later phases and are intentionally
absent right now.

A `/mistpanel test` developer test mode is included so most of this
checklist can be done solo, without needing a real 4-person group — see
section 2.1.

## 1. Install / live-dev setup

As of this change, `MistPanel.toc`, `Core.lua`, and `PartyFrame.lua`
live directly at the **root of this git repository** — there is no
`MistPanel/` subfolder anymore. This lets the repo working copy itself
be the live AddOns folder: `git pull` + `/reload` instead of
copying files by hand each time.

**Important:** Claude Code runs this repo in a separate cloud
environment, not on your Windows PC. Claude commits and pushes to
GitHub; it cannot write directly into your local
`D:\World of Warcraft\_retail_\Interface\AddOns\MistPanel`. You still
need to `git pull` there yourself after each push — this setup just
removes the manual copy/download step, it doesn't make edits appear
instantly on your machine.

### One-time setup
1. If `D:\World of Warcraft\_retail_\Interface\AddOns\MistPanel`
   already exists with files manually copied in from before (no `.git`
   folder inside it), rename it aside as a backup, e.g. to
   `MistPanel_manual_backup` — `git clone` needs an empty or
   nonexistent target directory.
2. Clone this repo directly into that exact path and branch:
   ```
   git clone -b claude/wow-addon-gdrive-github-rbrb6i https://github.com/stealthybadger-pixel/Wow-add-on- "D:\World of Warcraft\_retail_\Interface\AddOns\MistPanel"
   ```
3. Confirm `MistPanel.toc` is directly at
   `D:\World of Warcraft\_retail_\Interface\AddOns\MistPanel\MistPanel.toc`
   (not nested inside another `MistPanel\` folder).
4. Fully restart WoW (or log in from character select — addon lists
   are read at launch).
5. At the character-select screen, open **AddOns** and confirm
   "Mist Panel" is listed and enabled. Once confirmed working, the
   `MistPanel_manual_backup` folder from step 1 can be deleted.

### Day-to-day loop
1. Claude edits files here and pushes to GitHub.
2. On your PC, in that same folder: `git pull`.
3. In WoW: `/reload`.
4. Test, report back what you see.

Note this folder will also contain the `WoW Addon/` documentation
folder and this `TESTING.md` alongside the addon code, since the whole
repo is now the addon folder. WoW only loads what `MistPanel.toc`
lists, so the extra files are harmless — just unusual to see sitting in
an AddOns folder.

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

### 2.1 Developer test mode (no group required)
`/mistpanel test` toggles a simulated 5-player roster — Tank, Healer,
DPS, DPS, DPS — rendered through the exact same slot frames, container,
scale setting and saved position as a real party. It's the fastest way
to iterate on the visual shell while solo:
- `/mistpanel test` (while solo, out of a group) — the panel should
  appear immediately with all 5 slots filled, even though you're solo
  (test mode intentionally overrides "hide when solo").
- Confirm role icons read Tank, Healer, DPS, DPS, DPS top to bottom.
  (Role icons were previously missing in test mode - the icon technique
  was switched to Blizzard's current role-icon atlas, the same one live
  party/raid frames use. This still needs to be re-confirmed in-game.)
- Confirm the 5 health bars show visibly different lengths/colors: the
  simulated roster is seeded at 55% (tank), 100% (healer), 82%, 38%,
  and 12% (the two DPS at the low end should read solidly red).
- Confirm dragging (see 2.8), scale presets (see 2.9), and the
  near-black background/role gutter/health-line layout all look correct
  on the simulated frames — this is the same rendering code path real
  frames use, so anything wrong here will also be wrong live.
- `/mistpanel test` again — the panel should revert to your real,
  live roster (or hide, if you're solo/not grouped).
- While test mode is on, joining/leaving a group or taking real damage
  should have **no effect** on the simulated display — it's frozen
  until you toggle test mode off.

Sections 2.2–2.7 below describe the live-group behaviour test mode
can't substitute for (real roster composition, real health events, real
raid detection) — worth doing at least once with an actual group, but
not required for day-to-day shell iteration.

### 2.2 Hidden while solo
- Solo, out of a group, with test mode **off**: the panel should be
  completely invisible (no empty frames, no placeholder).

### 2.3 Basic group (2-4 players)
- Group with at least one other player (an alt on a second account, a
  friend, or a low-level dungeon queue).
- You should see one frame per real group member — not always 5 — near
  the center of the screen (default position), stacked vertically with
  a small gap between them.
- Verify frame background is near-black, and each frame shows a small
  role icon in the top-left area (tank/healer/DPS icon matching each
  member's actual assigned role).
- Verify the healer/role icon on **your own** frame shows correctly.

### 2.4 Role ordering
- With a tank, healer, and DPS all present, confirm the vertical order
  is Tank, then Healer (you, presumably), then DPS — top to bottom.
- If two DPS are present, confirm their relative order doesn't visibly
  swap/jitter across normal roster updates (e.g. someone briefly
  disconnecting and reconnecting).

### 2.5 Health bar behaviour
- Take damage (or have a group member take damage) and confirm the thin
  bottom bar on that unit's frame shrinks from the **right edge toward
  the left** as health drops (left edge stays fixed).
- Confirm the bar color shifts from green (high health) toward red
  (low/critical health), and that it's a single flat color at any given
  moment (not a rainbow gradient across the bar's own width).
- Heal back up and confirm the bar grows back out to the right and the
  color shifts back toward green.
- (Test mode's fixed 55/100/82/38/12% spread already exercises the
  color range without needing live damage — this step is about
  confirming real `UNIT_HEALTH` events drive the same visuals.)

### 2.6 Full 5-player group
- If possible, get a full 5-player dungeon group (queue for anything,
  even a low-level dungeon). Confirm all 5 frames render correctly and
  role ordering is Tank → Healer → DPS → DPS → DPS.

### 2.7 No raid mode
- Convert your party to a raid (or queue something that puts you in a
  raid group) and confirm the entire panel disappears while in a raid
  group, then reappears if you convert back to a party. (Test mode
  intentionally ignores this — it stays visible in a raid if toggled on,
  since it's meant to always show for shell inspection.)

### 2.8 Lock / Unlock / drag / persistence
Can be done in test mode or with a live roster — dragging behaviour is
identical either way, since it's the same container frame.
- `/mistpanel unlock` — the panel should now be draggable; click and
  drag anywhere on the block (including on top of a slot frame) and
  confirm it moves as a single unit, not frame-by-frame.
- `/mistpanel lock` — confirm dragging no longer moves it.
- While unlocked, move it somewhere, then `/reload` (or fully relog).
  Confirm it reappears in the same position you left it. (Test mode
  itself does not persist across `/reload` — you'll need to run
  `/mistpanel test` again after reloading if you want it back.)

### 2.9 Scale presets
Can be done in test mode or with a live roster.
- `/mistpanel scale small`, `/mistpanel scale medium`,
  `/mistpanel scale large` — confirm the entire block (frame size,
  health bar thickness, role icon size) scales proportionally, and that
  nothing looks stretched, misaligned, or clipped at any of the three
  sizes.

### 2.10 Blizzard party frame auto-hide
Requires a real group — test mode does not affect Blizzard's own party
frames.
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

### 2.11 General health check
- Watch for any Lua errors on login, on joining/leaving a group, on
  toggling test mode on/off, and during ordinary combat health-change
  spam (a full dungeon pull is a good stress test).

## 3. Temporary test command

Phase 1 has no settings UI yet (that's Phase 5), so a minimal
`/mistpanel` slash command exists purely to exercise Phase 1 mechanics:

```
/mistpanel lock
/mistpanel unlock
/mistpanel scale small|medium|large
/mistpanel blizzframes on|off
/mistpanel test
/mistpanel status
```

`/mistpanel test` toggles the simulated 5-player developer test mode
described in section 2.1. This is scaffolding for testing, not a
designed product feature — expect it to be superseded (likely by the
real Test Mode described in 05 - Roadmap.md's Phase 5), not extended,
once Phase 5 is implemented.

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
- **Role icon rendering.** Role icons were reported missing in test mode
  in-game (no Lua error, just no icon). Real and test frames share the
  exact same rendering function, so this almost certainly affected real
  party frames too - it just hadn't been observed there yet. The likely
  cause was the old technique (a raw `Interface\LFGFrame\...` texture
  file + `GetTexCoordsForRoleSmallCircle`), which may no longer resolve
  correctly on this client. The fix switches to Blizzard's current
  small role-icon atlas (`roleicon-tiny-tank` / `-healer` / `-dps`) -
  the same atlas the live default party/raid frames use - with the old
  technique kept only as a fallback. This has not yet been re-verified
  in-game; please confirm role icons now appear on both test-mode and
  real frames.
- **All visual/layout judgment calls**: whether 210x50px frames at the
  three scale presets actually look right, whether 4px gaps read as
  "small," whether the near-black background/border contrast is
  legible against typical UI backgrounds, and whether the test-mode
  55/100/82/38/12% health spread actually reads as a useful visual
  range once rendered — the spec gives target numbers, not a rendered
  reference, so these are only as correct as the numbers were followed.
- **Drag/clamp feel and position persistence across relog**, in
  practice rather than in the stubbed logic test.
- **Any runtime error that only manifests against real WoW frame/event
  behavior** — the Lua smoke test (see repo `MistPanel/` — the stub
  script itself isn't checked in) exercises every function path with
  fake data, including the test-mode toggle, but it is not a substitute
  for the real client.

Please report back anything in this list that fails, along with any
Lua error text, so it can be fixed before Phase 2 starts.
