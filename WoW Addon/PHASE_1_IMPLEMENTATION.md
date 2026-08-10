PHASE 1 — PARTY FRAME SHELL — IMPLEMENTATION NOTES
Status: Implemented, not yet verified in a live client. See TESTING.md for the in-game verification checklist.

This document records what was actually built for Phase 1 (05 - Roadmap.md),
implementation decisions made where the spec left something open, and API
discoveries made while writing the code. It supplements, and does not
replace or edit, the original specification documents.

1. WHAT WAS BUILT
Code lives at the repo root (MistPanel.toc, Core.lua, PartyFrame.lua),
so the repository itself doubles as the live WoW AddOns folder. It
originally lived in a MistPanel/ subfolder; that was flattened to the
repo root so this repo can be git-cloned directly into
Interface/AddOns/MistPanel without creating a nested MistPanel/MistPanel/
duplicate. See TESTING.md section 1 for the live-dev git workflow.

Files:
- MistPanel.toc — addon manifest, SavedVariables declaration.
- Core.lua — saved-variable defaults/init, PLAYER_LOGIN bootstrap, a
  temporary `/mistpanel` slash command (see section 3).
- PartyFrame.lua — the five-slot frame block itself.

Roadmap Phase 1 bullet list, mapped to implementation:
- Five-player vertical block → `container` frame holding 5 child slot
  frames stacked top-to-bottom with a fixed gap.
- Role ordering Tank → Healer/user → DPS → DPS → DPS → `SortedRoster()`
  sorts player + partyN units by `UnitGroupRolesAssigned`, with ties
  broken by original party order (stable, so DPS don't reshuffle on
  every roster update).
- Near-black frames → solid backdrop, RGBA (0.03, 0.03, 0.03, 0.9), thin
  1px lighter border for edge definition.
- Role gutter/icons → 16x16 icon in the left gutter using
  `GetTexCoordsForRoleSmallCircle` against Blizzard's shared role-icon
  atlas (same one LFG tools use).
- Thin bottom health line → 4px-tall StatusBar anchored along the full
  bottom width of the frame; left-anchored default StatusBar fill means
  it retreats right-to-left as health drops, matching the spec exactly
  with no custom logic needed.
- Green-to-red health colouring → linear interpolation from red (0%) to
  green (100%), applied as a single flat `SetStatusBarColor` (not a
  gradient texture), per "one health-state colour at a time."
- Small frame gaps → 4px between slots.
- Small/Medium/Large scale presets → `container:SetScale()` with
  multipliers 0.8 / 1.0 / 1.2, so all children (icons, bars, text) scale
  proportionally for free.
- Lock/Unlock and block dragging → the whole `container` is the drag
  handle (mouse passes through the child slot frames, which don't call
  `EnableMouse`); locked disables mouse on the container entirely.
  Position persists to `MistPanelDB.point` on drag stop and is restored
  on login.
- Hide when solo / No raid mode → the roster builder returns an empty
  unit list whenever `IsInGroup()` is false or `IsInRaid()` is true; the
  container is hidden whenever that list is empty.
- Optional automatic hiding of Blizzard party frames → implemented via
  `RegisterStateDriver`/`UnregisterStateDriver` on `CompactPartyFrame`
  (the secure-driver approach PHASE_0_FEASIBILITY.md section 10
  recommends to avoid combat-lockdown taint), toggleable, default ON per
  01 - Product Vision.md section 2.

Explicitly NOT built (deferred to later phases, per the roadmap):
- Aggro/dispel outlines, range/death dimming (Phase 2).
- Any HoT/duration-bar rendering (Phase 3).
- Secure click-casting, spell bindings, modifier handling (Phase 4).
- Settings UI, AddOns panel entry, simulated Test Mode (Phase 5).
Party member frames are plain `Frame`/`BackdropTemplate` objects, not
`SecureUnitButtonTemplate` — there is no click-cast surface area yet, so
there was no reason to take on secure-template/combat-lockdown
complexity this early.

2. IMPLEMENTATION DECISIONS NOT FULLY SPECIFIED
The specification documents don't address these; each was resolved with
the smallest, most literal reading of the surrounding text rather than
inventing new product behaviour:

- Partial groups (2-4 members): the spec only describes "five-player
  dungeon parties" and never states what a 2-4 person group should look
  like. The block always has 5 slots, but a slot with no corresponding
  real unit is simply hidden rather than shown empty — consistent with
  the "when inactive, NOTHING is shown" principle used elsewhere in
  02 - Unit Frame Design.md for HoT tracks. This means the panel is
  usable (and testable) with any group size, not only a full 5.
- Default `locked = true` on first install, so the block doesn't drift
  the first time a user mouses over it.
- Default `scale = MEDIUM`.
- Addon folder/internal name `MistPanel` is a placeholder only, since
  01 - Product Vision.md explicitly marks the final name as TBD. No
  user-facing name decision has been made.
- `## Interface: 120007` in the .toc is a computed guess for WoW Retail
  12.0.7 ("Midnight", per PHASE_0_FEASIBILITY.md) using Blizzard's
  standard major*10000 + minor*100 + patch numbering. This has not been
  confirmed against a live client — see TESTING.md.

3. TEMPORARY TEST-ONLY SLASH COMMAND
Phase 5 owns the real configuration surface (AddOns settings panel,
slash command, binding UI, Test Mode). Phase 1 still needs *some* way to
exercise scale/lock/drag/auto-hide in-game before Phase 5 exists, so a
minimal `/mistpanel` command was added:
  /mistpanel lock | unlock
  /mistpanel scale small|medium|large
  /mistpanel blizzframes on|off
  /mistpanel status
This is scaffolding, not a product feature — it should be superseded
(not extended) when Phase 5 is implemented.

4. API DISCOVERIES / THINGS CARRIED OVER FROM PHASE 0
No new API blockers were found; Phase 1 only touches functionality
PHASE_0_FEASIBILITY.md already classified SUPPORTED or SUPPORTED WITH
RESTRICTIONS:
- `UnitGroupRolesAssigned`, `UnitHealth`/`UnitHealthMax`, `IsInGroup`,
  `IsInRaid`, `UnitExists` all behaved exactly as documented in Phase 0's
  read-only sections — no surprises during implementation.
- Confirmed (by re-reading Blizzard's FrameXML documentation patterns,
  not by live testing) that a plain `StatusBar` with default orientation
  and no `SetReverseFill` already produces the "retreats right to left"
  behaviour the spec asks for, with zero custom math.
- The `CompactPartyFrame` auto-hide path could not be exercised outside
  a live client. This was already flagged in PHASE_0_FEASIBILITY.md's
  "items requiring an in-game proof of concept" list (#2) and remains
  open — see TESTING.md.
- `GetTexCoordsForRoleSmallCircle` is assumed present based on its long
  history as a Blizzard FrameXML utility used by LFG-adjacent UI; its
  existence and visual correctness on 12.0.7 is unverified. The code
  guards for its absence (falls back to hiding the role icon rather than
  erroring) so a missing function degrades gracefully instead of
  breaking the addon.

5. WHAT COULD NOT BE VERIFIED WITHOUT RUNNING WOW
See TESTING.md, "What I could not verify without running the game," for
the complete list. In short: everything about actual in-client
rendering, the exact Interface version number, whether
`CompactPartyFrame` is still the correct global on this client, and
whether the secure-driver Blizzard-frame-hide approach is taint-free in
practice (versus in Phase 0's research) all remain to be confirmed by
you in-game.
