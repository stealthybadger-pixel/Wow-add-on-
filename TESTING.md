# Testing MistPanel (Phase 1 + Phase 2)

Phase 1 is the party frame shell: a five-slot block, role ordering, a
health bar, scale presets, lock/unlock + dragging, hide when solo, and
optional auto-hiding of the default Blizzard party frames.

Phase 2 adds the combat-state visual layer on top of that shell: a red
outline for aggro, a pink outline (priority over red) for an actionable
dispellable debuff, out-of-range dimming, and a heavier dead/grey dim.
There is still **no** HoT duration bars, **no** click-casting, and **no**
full configuration UI — those are later phases and are intentionally
absent right now.

A `/mistpanel test` developer test mode is included so most of this
checklist can be done solo, without needing a real 4-person group — see
section 2.1. Phase 2's combat states additionally benefit from testing
in a solo-queueable **Follower Dungeon** — see section 2.6.

## 1. Install / live-dev setup

`MistPanel.toc`, `Core.lua`, and `PartyFrame.lua` live directly at the
**root of this git repository** — there is no `MistPanel/` subfolder.
This lets the repo working copy itself be the live AddOns folder:
`git pull` + `/reload` instead of copying files by hand each time.

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
- Confirm the 5 health bars show visibly different lengths/colors: 55%
  (tank), 100% (healer), 82%, 38%, and 0% (the last DPS, since it's also
  demonstrating "dead").
- **Phase 2: confirm each slot demonstrates a distinct combat state:**
  1. **Tank** — red outer outline (aggro), full brightness.
  2. **Healer** — no outline, full brightness (normal/idle state — this
     is what every frame should look like with nothing active).
  3. **DPS (3rd slot)** — pink outer outline (dispellable debuff). Pink
     should look clearly different from the tank's red.
  4. **DPS (4th slot)** — no outline, but visibly dimmed (out of range).
  5. **DPS (5th slot)** — no outline, dimmed more heavily than the
     out-of-range slot (dead) — the two dim levels should be
     distinguishable from each other at a glance.
- Confirm dragging (see 2.9), scale presets (see 2.10), and the
  near-black background/role gutter/health-line layout all look correct
  on the simulated frames — this is the same rendering code path real
  frames use, so anything wrong here will also be wrong live.
- `/mistpanel test` again — the panel should revert to your real,
  live roster (or hide, if you're solo/not grouped).
- While test mode is on, joining/leaving a group or taking real damage
  should have **no effect** on the simulated display — it's frozen
  until you toggle test mode off.

Sections 2.2–2.5 below describe live-group behaviour test mode can't
substitute for (real roster composition, real health events). Section
2.6 covers the Phase 2 combat states specifically — these are simulated
(not API-driven) in test mode, so they need real verification. Sections
2.7 onward cover the rest of the Phase 1 checklist.

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
- (Test mode's fixed health spread already exercises the color range
  without needing live damage — this step is about confirming real
  `UNIT_HEALTH` events drive the same visuals.)

### 2.6 Combat states (Phase 2 — real group or Follower Dungeon)
Test mode's 5 combat states (2.1) are simulated flags, not live API
calls — they only prove the rendering code works, not that aggro/dispel/
range/death detection actually works against real game state. This
section needs either a real group or a solo-queueable **Follower
Dungeon** (Group Finder → Follower Dungeon — fills the rest of the party
with NPCs, queueable alone, real threat/aggro/damage/death happen).

- **Aggro (red outline):** Pull a pack with the follower tank (or a real
  tank) in the group. Confirm the tank's frame gets a red outline while
  actively tanking. Let threat build on a DPS/yourself instead (e.g. by
  healing/attacking before the tank has threat) and confirm the outline
  moves to whoever currently has aggro. Aggro should update promptly,
  not lag noticeably behind what you'd see on the tank's own threat
  plates/warnings.
- **Dispel (pink outline, priority over red):** Get a Magic/Poison/
  Disease debuff on a party member (many dungeon mobs apply these) and
  confirm a pink outline appears on that unit. If that unit *also* has
  aggro, confirm the outline is pink, not red. When the debuff expires
  or is cleansed, confirm the outline reverts immediately (back to red
  if aggro is still active, or to no outline otherwise).
  - If you have **Improved Detox** (or whatever the current talent that
    extends Detox to Poison/Disease is named) talented: confirm Poison/
    Disease debuffs light up pink. If you do **not** have it talented:
    confirm Poison/Disease debuffs do **not** light up pink (only Magic
    should). This distinction is the main thing to verify — the
    detection method (reading Detox's own tooltip text) is unverified
    and could be silently wrong in either direction.
  - If pink never appears even on a plain Magic debuff you should be
    able to dispel, or it appears when you shouldn't be able to dispel
    something, report the exact debuff and your current talent
    build.
- **Out of range (dim):** Move far enough from a party member that
  you'd be unable to heal them, and confirm their frame dims noticeably
  (but doesn't get a colored outline). Move back in range and confirm
  it returns to full brightness. Note it may take up to ~0.5s to update
  (it's polled, not event-driven).
- **Dead (heavier dim):** Let a party member (or yourself) die, and
  confirm their frame dims more heavily than the out-of-range state —
  the two should be visually distinguishable. Confirm it clears back to
  normal on a battle-rez or release+revive.
- **General:** Watch for Lua errors throughout, and note whether aggro/
  dispel state ever seems "stuck" (not updating when it obviously
  should have changed).

### 2.7 Full 5-player group
- If possible, get a full 5-player dungeon group (queue for anything,
  even a low-level dungeon, or a Follower Dungeon). Confirm all 5 frames
  render correctly and role ordering is Tank → Healer → DPS → DPS → DPS.

### 2.8 No raid mode
- Convert your party to a raid (or queue something that puts you in a
  raid group) and confirm the entire panel disappears while in a raid
  group, then reappears if you convert back to a party. (Test mode
  intentionally ignores this — it stays visible in a raid if toggled on,
  since it's meant to always show for shell inspection.)

### 2.9 Lock / Unlock / drag / persistence
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

### 2.10 Scale presets
Can be done in test mode or with a live roster.
- `/mistpanel scale small`, `/mistpanel scale medium`,
  `/mistpanel scale large` — confirm the entire block (frame size,
  health bar thickness, role icon size) scales proportionally, and that
  nothing looks stretched, misaligned, or clipped at any of the three
  sizes.

### 2.11 Blizzard party frame auto-hide
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

### 2.12 General health check
- Watch for any Lua errors on login, on joining/leaving a group, on
  toggling test mode on/off, and during ordinary combat health-change
  spam (a full dungeon pull is a good stress test) — this is also the
  best stress test for the new aggro/dispel/range/death polling.

## 3. Temporary test command

Phase 1/2 have no settings UI yet (that's Phase 5), so a minimal
`/mistpanel` slash command exists purely to exercise Phase 1/2 mechanics:

```
/mistpanel lock
/mistpanel unlock
/mistpanel scale small|medium|large
/mistpanel blizzframes on|off
/mistpanel test
/mistpanel status
```

`/mistpanel test` toggles the simulated 5-player developer test mode
described in section 2.1, now demonstrating all 5 Phase 1+2 states
(Normal, Aggro, Dispellable, Out of range, Dead). This is scaffolding
for testing, not a designed product feature — expect it to be
superseded (likely by the real Test Mode described in
05 - Roadmap.md's Phase 5), not extended, once Phase 5 is implemented.

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
- **Role icon rendering.** Fixed in the previous round (switched to
  Blizzard's `roleicon-tiny-*` atlas) — please reconfirm icons show on
  both test-mode and real frames now.
- **Aggro detection.** `UnitThreatSituation(unit)` returning any
  non-zero value is treated as "has aggro," collapsing Blizzard's 0-3
  threat-status scale to one binary red state. Whether this reads
  correctly during real tanking/threat-pulling is unverified — see 2.6.
- **The two threat event names**, `UNIT_THREAT_LIST_UPDATE` and
  `UNIT_THREAT_SITUATION_UPDATE`. Registered defensively (wrapped in
  `pcall`, so a bad name is silently skipped instead of breaking the
  addon), but whether either actually exists/fires on this client, and
  whether aggro updates feel responsive, is unverified.
- **Dispel-type detection.** Rather than hard-code an unverified talent
  spell ID, this reads Detox's own live tooltip text via
  `C_Spell.GetSpellDescription(218164)` and checks whether it currently
  mentions "Poison"/"Disease" (added only if so; Magic is always
  included as Detox's baseline). Whether spell ID 218164 is actually
  Detox on this client, and whether its description text updates the
  way this assumes when Improved Detox (or its current-patch
  equivalent) is talented, is entirely unverified — see 2.6.
- **`UnitAura`'s classic tuple return** (`name, icon, count, dispelType,
  ...`) is used for harmful-aura scanning instead of
  `C_UnitAuras.GetAuraDataByIndex`'s table, since its 4th-position
  `dispelType` has been stable for a long time and the newer table's
  exact field name could not be confirmed without a live client. Still
  unverified that `UnitAura` itself is fully functional on 12.0.7.
- **Range/death polling.** A 0.5s timer re-checks `UnitInRange`/
  `UnitIsDeadOrGhost` for all displayed real units. Whether 0.5s feels
  responsive (vs. too slow or wastefully fast) is unverified.
- **All visual/layout judgment calls**: whether 210x50px frames at the
  three scale presets actually look right, whether the red/pink border
  colors and the 0.55/0.35 alpha dim levels are legible and clearly
  distinguishable against the near-black background, whether 4px gaps
  read as "small" — the spec gives target numbers/colors, not a
  rendered reference, so these are only as correct as the numbers were
  followed.
- **Drag/clamp feel and position persistence across relog**, in
  practice rather than in the stubbed logic test.
- **Any runtime error that only manifests against real WoW frame/event
  behavior** — the Lua smoke test (not checked into this repo)
  exercises every function path with fake data, including test mode and
  all 4 combat states, but it is not a substitute for the real client.

Please report back anything in this list that fails, along with any
Lua error text, so it can be fixed before Phase 3 starts.
