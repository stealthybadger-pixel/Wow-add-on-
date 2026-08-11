# Testing MistPanel (Phase 6 Additions)

MistPanel provides a sleek, high-contrast, secure 5-player healer unit frame panel with:
- **Exhaustive Blizzard Party Frame Suppression** (PartyFrame, CompactPartyFrame, CompactRaidFrameContainer, Pool Members).
- **Secure Click-Casting & Clique Compatibility**.
- **Alt + Left Click Drag Positioning & Persistence**.
- **Spec-Aware Mistweaver HoTs** with vertical EQ duration bars.
- **Thin Primary Resource Bar** (Mana, Energy, Rage, Focus, Runic Power, etc.) underneath health.
- **Dark Desaturated Class-Specific Backgrounds** (`RAID_CLASS_COLORS` tinted).
- **Cyan Absorb / Shield Overlay** (supporting Life Cocoon, Power Word: Shield, etc.).
- **Active Self-Defensive Mitigation Icons** (Barkskin, Shield Wall, Divine Shield, Ice Block, Fortifying Brew, Astral Shift, etc.).

A `/mistpanel test` developer test mode is included so all visual states can be verified solo — see section 2.1.

## 1. Install / live-dev setup

`MistPanel.toc`, `Core.lua`, and `PartyFrame.lua` live directly at the root of `D:\World of Warcraft\_retail_\Interface\AddOns\MistPanel`.

After edits, test in-game with `/reload`.

## 2. What to verify in-game

Log in on your Mistweaver Monk.

### 2.1 Developer test mode (solo verification)
`/mistpanel test` toggles a simulated 5-player roster that explicitly demonstrates all visual features:

- **Slot 1 (Tank - WARRIOR)**: Red aggro outline, Rage power bar, Shield Wall gold defensive icon, 70% health, My HoTs, Incoming Danger cast.
- **Slot 2 (Healer - MONK)**: Dark Monk background, Mana power bar, Cyan Life Cocoon absorb overlay, 100% health, My HoTs.
- **Slot 3 (DPS 1 - DRUID)**: Pink Dispel outline, Energy power bar, Barkskin gold defensive icon, 3 HoTs.
- **Slot 4 (DPS 2 - MAGE)**: Dark Mage background, Mana power bar, Ice Block gold defensive icon.
- **Slot 5 (DPS 3 - PRIEST)**: Low health (10%), Mana power bar, nearly expired HoT.

Toggle `/mistpanel test` off to return to your live roster.

### 2.2 Blizzard Frame Suppression Audit (Test with ElvUI Disabled)
1. **Disable ElvUI completely** in the AddOn menu and run `/reload`.
2. Join a party. Verify **zero Blizzard default party frames** are visible.
3. Type `/mistpanel debugblizzard` (or `/mistpanel blizzdebug`) in chat:
   Verify every frame object (`PartyFrame`, `CompactPartyFrame`, `CompactRaidFrameContainer`, `CompactRaidFrame1..5`) returns `[not visible]`.
4. Re-enable ElvUI if desired to verify co-existence.

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
