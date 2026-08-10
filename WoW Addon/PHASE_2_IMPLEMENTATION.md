PHASE 2 — COMBAT STATES — IMPLEMENTATION NOTES
Status: Implemented, ready for in-game verification. See TESTING.md.

This document records what was built for Phase 2 (05 - Roadmap.md), design decisions made, and API mechanisms used.

1. WHAT WAS BUILT
Files:
- MistPanel.toc — updated title and version to 0.2.0-phase2.
- PartyFrame.lua — extended with Phase 2 visual states (aggro, dispel, range, dead) and updated test mode.

Roadmap Phase 2 requirements, mapped to implementation:
- Red outer outline for aggro:
  `UnitThreatSituation(unit)` checks threat status. Status > 0 sets border color to bright red (RGBA 1.0, 0.0, 0.0, 1.0).
- Pink outer outline for actionable dispel:
  `UnitHasDispellableAura(unit)` iterates unit harmful auras via `C_UnitAuras.GetAuraDataByIndex` / `UnitDebuff` and checks if any aura's `dispelType` matches the player's runtime dispellable types. Dispellable unit gets a bright pink/magenta border (RGBA 1.0, 0.2, 0.8, 1.0).
- Dispel priority over aggro:
  In `RenderSlotState`, if `hasDispel` is true, the pink border is rendered even if `hasAggro` is true. When the dispellable aura is removed (`hasDispel` becomes false) and `hasAggro` remains true, the red outline immediately returns.
- Dispel capability discovered at runtime:
  `ns.GetDispellableTypes()` checks the player's active spellbook and talent state (`C_SpellBook.IsSpellKnown` / `IsPlayerSpell`). Detox (spell ID 115450 / Monk healer base) enables "Magic" dispels. Improved Detox (spell ID 388874) adds "Poison" and "Disease" dispels.
- Out-of-range dim/desaturation:
  `UnitIsInRange(unit)` checks `UnitInRange(unit)`. If out of range, slot alpha is set to 0.45, role icon is desaturated, and health bar alpha is set to 0.45.
- Dead heavy dim/grey state:
  `UnitIsDead(unit)` checks `UnitIsDeadOrGhost(unit)` or disconnected state. If dead/ghost/disconnected, slot alpha is set to 0.35, role icon is desaturated, and health bar alpha is set to 0.35.

2. EXTENDED TEST MODE
`/mistpanel test` has been extended so that while solo it visibly demonstrates all 5 states:
- Slot 1 (Tank): Aggro (Red outline, 75% health)
- Slot 2 (Healer): Normal (Dark border, 100% health)
- Slot 3 (DPS 1): Dispellable (Pink outline overriding aggro, 50% health)
- Slot 4 (DPS 2): Out of range (Dimmed 0.45 alpha, desaturated role icon, 30% health)
- Slot 5 (DPS 3): Dead (Heavy dim 0.35 alpha, desaturated role icon, 0% health)

3. API EVENTS REGISTERED
- `UNIT_THREAT_SITUATION_UPDATE` for aggro updates.
- `UNIT_AURA` for dispel updates.
- `UNIT_FLAGS` for dead/ghost/disconnect state changes.
- `SPELLS_CHANGED` & `PLAYER_TALENT_UPDATE` for dispel capability talent updates.
- 0.2s `OnUpdate` ticker for responsive live range state updates.
