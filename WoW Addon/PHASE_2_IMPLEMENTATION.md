PHASE 2 — COMBAT STATES — IMPLEMENTATION NOTES
Status: Implemented, not yet verified in a live client. See TESTING.md for the in-game verification checklist.

This document records what was actually built for Phase 2 (05 - Roadmap.md),
implementation decisions made where the spec left something open, and API
discoveries made while writing the code. It supplements, and does not
replace or edit, the original specification documents.

1. WHAT WAS BUILT
All in PartyFrame.lua, reusing the exact same slot frames/backdrop border
established in Phase 1 - no new frame elements were added.

Roadmap Phase 2 bullet list, mapped to implementation:
- Red aggro outline -> `HasAggro(unit)` reads `UnitThreatSituation(unit)`
  and treats any non-nil, non-zero result as "has aggro" (a deliberate
  simplification of Blizzard's 0-3 threat-status scale down to a single
  binary red/not-red state, since the spec only asks for one aggro
  state, not threat-security nuance).
- Pink actionable-dispel outline, priority over red -> `RenderCombatState`
  checks `dispellable` before `aggro` when choosing the backdrop border
  color, so pink always wins when both are true, and reverts to red the
  moment the dispellable aura is gone but aggro remains, satisfying
  02 - Unit Frame Design.md section 8 exactly.
- Out-of-range dim -> `UnitInRange(unit)` (only dims when `checkedRange`
  is true and `inRange` is false, avoiding false positives when a check
  isn't meaningful) sets the whole slot frame's alpha to 0.55.
- Dead heavy dim -> `UnitIsDeadOrGhost(unit)` sets alpha to 0.35 (lower
  than out-of-range's 0.55, so it reads as more extreme) and takes
  priority over out-of-range dimming if both would apply.
- All four states are computed together per unit in
  `ComputeUnitCombatState(unit)` and rendered by one shared
  `RenderCombatState(slot, state)` function, used by both real and
  test-mode slots (same pattern as Phase 1's RenderRoleIcon/
  RenderHealthFraction), so the two can't visually diverge.

Frame dimensions, scale presets (Small/Medium/Large), and the existing
1px idle border thickness were NOT changed - only the border's color and
the frame's alpha change dynamically. Nothing from this phase alters
frame size at any point.

2. DISPEL DETECTION (RUNTIME, NOT HARD-CODED)
Per your instruction, the dispel-type set is computed live rather than
fixed. Detox is Mistweaver's only dispel spell, so identifying "Detox is
the dispel spell" is a fixed fact of this addon's Mistweaver-only scope,
not the kind of hard-coded dispel-TYPE-set the instruction was about.
What actually varies by talent (Magic-only vs. Magic+Poison+Disease) is
computed fresh every check via `GetDispellableTypes()`:
- Magic is always included (Detox's guaranteed, talent-independent
  baseline per PHASE_0_FEASIBILITY.md section 4).
- Poison/Disease are added only if Detox's own current tooltip text
  (read live via `C_Spell.GetSpellDescription(218164)`) currently
  mentions "Poison" / "Disease" - this reads talent-modified spell
  behavior directly from Blizzard's own live spell data rather than
  hard-coding the "Improved Detox" talent's spell ID, which could not be
  verified without a live client. If the description can't be read for
  any reason, it safely falls back to Magic-only (under-reporting
  coverage is far less harmful than over-reporting a dispel the player
  can't actually make).

This was chosen deliberately over hard-coding a specific talent spell
ID: an unverified numeric ID that's subtly wrong would silently and
permanently under-detect with no visible symptom, whereas reading the
spell's own live description text is self-correcting across talent
changes and doesn't depend on knowing an exact, unconfirmed ID.

Harmful-aura scanning itself uses the classic `UnitAura(unit, i,
"HARMFUL")` tuple return (not `C_UnitAuras.GetAuraDataByIndex`'s table)
specifically because its 4th-return-value `dispelType` position has been
stable for a very long time; the newer structured table's exact field
name could not be confirmed without a live client, and guessing it wrong
would silently break dispel detection entirely.

3. EVENT WIRING / API DISCOVERIES
- `UNIT_AURA` drives dispel-state refreshes (well-established event, high
  confidence).
- Aggro refreshes are driven by both `UNIT_THREAT_LIST_UPDATE` and
  `UNIT_THREAT_SITUATION_UPDATE`. Registering both is a deliberate hedge:
  I'm reasonably but not 100% confident both are valid current event
  names, and an invalid event name passed to `RegisterEvent` throws a
  Lua error that could abort the rest of addon initialization - so both
  registrations are wrapped in `pcall` (`pcall(watcher.RegisterEvent,
  watcher, "...")`), so a bad name degrades to "that event just doesn't
  fire" instead of breaking the addon. This needs to be confirmed live;
  see TESTING.md.
- Range and death have no reliable single "changed" push event (this
  matches PHASE_0_FEASIBILITY.md's own framing of range/dead-state as
  plain polled reads, not event-driven), so a `C_Timer.NewTicker(0.5,
  ns.RefreshAllCombatStates)` polls all currently-displayed real units
  every 0.5s. This is guarded by `if C_Timer and C_Timer.NewTicker`.
  Death is also caught immediately (not just on the next tick) via the
  existing `UNIT_HEALTH` handler, since `UpdateSlot` already recomputes
  full combat state on every health change.
- All of this reuses Phase 1's existing `UNIT_HEALTH`/`UNIT_MAXHEALTH`
  wiring; nothing about the health-bar rendering itself changed.

4. TEST MODE EXTENSION
`/mistpanel test`'s fixed 5-slot roster now demonstrates one of each
requested state per slot, chosen to line up naturally with the existing
Tank/Healer/DPS/DPS/DPS role order (which was not changed):
1. Tank - Aggro (red border)
2. Healer - Normal (idle border, full alpha)
3. DPS - Dispellable debuff (pink border)
4. DPS - Out of range (idle border, 0.55 alpha)
5. DPS - Dead (idle border, 0.35 alpha, health set to 0%)
Test-mode slots go through the same `RenderCombatState` function real
slots do, driven by fixed flags on each `TEST_ROSTER` entry instead of
live unit reads - this is still just a developer aid layered on the
existing Phase 1 test mode, not Phase 5's Test Mode.

5. WHAT COULD NOT BE VERIFIED WITHOUT RUNNING WOW
See TESTING.md for the full list; in short:
- Whether `UNIT_THREAT_LIST_UPDATE` / `UNIT_THREAT_SITUATION_UPDATE` are
  valid event names on this client, and whether aggro updates feel
  responsive in a real pull.
- Whether treating any non-zero `UnitThreatSituation` result as "has
  aggro" reads correctly for both tanks and threat-pulling DPS in
  practice, or whether the binary simplification loses something the
  spec cares about.
- Whether Detox's live tooltip text actually contains "Poison"/"Disease"
  when Improved Detox (or whatever the current 12.0.7 talent is named)
  is selected - this whole detection path is unverified.
- Whether `UnitAura`'s classic tuple return still works reliably on
  12.0.7, versus needing `C_UnitAuras.GetAuraDataByIndex`.
- Visual correctness/legibility of the red/pink border colors and the
  0.55/0.35 alpha levels against the existing near-black background.
- Whether the 0.5s range/dead polling interval feels responsive enough
  without being wasteful.
