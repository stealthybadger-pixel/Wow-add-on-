# MistPanel Development Session - 2026-08-10

## Session summary

This session moved MistPanel from an early party-frame prototype into a substantially more complete Mistweaver-focused party panel.

The core addon frame is now usable in-game: it renders secure party-member frames, supports click-casting compatibility, tracks the live party roster, sorts by role, displays health, shows Mistweaver HoTs, supports key combat visual states, and can be moved/scaled through slash commands.

The main unresolved issue at end of night is Blizzard party-frame suppression. Blizzard party frames remained visible even with ElvUI disabled, despite MistPanel debug output reporting `PartyFrame`, `CompactPartyFrame`, and `CompactRaidFrameContainer` as hidden. This should be the first task in the next session.

## Implemented and working

- MistPanel addon shell and slash command surface.
- Secure Clique-compatible party frames.
- Live roster updates for solo, party, and test mode.
- Role-based sorting: tank, healer, then DPS.
- Per-unit health tracking and a bottom health bar.
- Panel movement, locking, unlocking, scaling, and position persistence.
- Blizzard party-frame auto-hide attempt and debug audit tooling.
- Mistweaver-focused HoT tracking and display.
- Correct-role-icon work using Blizzard role icon atlases.
- Combat visual states for aggro and actionable dispels.

## Visual design decisions

- Party frames use a compact 210px-wide layout.
- Frames prioritise readability over dense text: role icon only, no large name/number clutter.
- The role icon is the primary identity marker.
- Frames use a glow/outline treatment, with a restrained 1px internal outline for clean separation.
- Health is shown as a thin bottom bar rather than large text.
- HoT icons are deliberately smaller than the frame's main visual elements.
- HoT expiry/EQ information is represented with vertical bars beside/within the HoT treatment rather than oversized countdown text.
- Aggro state uses a red warning treatment.
- Actionable-dispel state uses pink and takes visual priority over aggro where both are present.

## Secure frame and Clique compatibility

The party frames were built around secure frame constraints rather than ordinary clickable UI widgets.

The working direction is:

- Use secure unit buttons for party members.
- Preserve click-casting compatibility, including Clique-style bindings.
- Avoid insecure frame replacement patterns that would break in combat.
- Keep party frame updates compatible with Retail's combat lockdown restrictions.

This is the correct architectural direction for a healer addon. It is more awkward than a simple frame stack, naturally, because Retail UI security likes to punish optimism.

## Roster, role sorting, and health

Roster handling now follows the live group rather than a fixed visual list.

Implemented behaviour includes:

- Build visible frames from the current party roster.
- Include the player correctly when in a party.
- Hide the panel while solo unless test mode is enabled.
- Sort units by assigned role.
- Update role information as group state changes.
- Update health from live unit health values.
- Reflect health visually using the bottom health bar.

## HoT tracking and icon work

Mistweaver HoT tracking was added and refined.

Work covered:

- Tracking player-cast Mistweaver HoTs on party members.
- Distinguishing player-owned HoTs from other similar auras where Retail allows it.
- Displaying the correct HoT icons.
- Fixing role icon rendering by moving toward Blizzard's current atlas-based role icons.
- Adding debug commands for HoT/aura visibility investigation.

Relevant limitation: Retail's modern aura data is restricted in several ways, and some aura details are not available as ordinary addon-readable values.

## Combat visual states

Two important healer-action states were added:

- Aggro: red visual state when a party member has threat.
- Actionable dispel: pink visual state when the player can meaningfully dispel the unit.

The pink actionable-dispel state should take priority over the red aggro state, because dispel is the more immediate healer action.

## Panel movement work

Panel movement was implemented through slash commands:

- `/mistpanel unlock`
- `/mistpanel lock`
- `/mistpanel resetpos`
- `/mistpanel resetposition`
- scale presets for small, medium, and large

Movement applies to the panel as a single block, not to individual frames. Position persistence was part of the intended working behaviour and should remain covered by manual testing.

## Retail secret-value failures and lessons

Several attempted prediction and state-detection approaches failed because current Retail hides or redacts values that would previously have been accessible.

Observed problem areas:

- Health fields can be secret or unavailable in contexts where enemy/unit prediction would need them.
- Range-related fields can be secret or unreliable for generic party-target prediction.
- Aura fields can be restricted, especially where source/ownership or detailed aura metadata is needed.
- Hostile GUID data is not generally available in a reliable way for arbitrary hostile units targeting party members.
- Cast timing and target linkage are restricted enough that generic cast-to-party prediction cannot be made dependable.
- `UnitIsUnit` hostile-target comparison is not sufficient as a general solution when the hostile units or target relationships are not exposed.

The practical lesson: do not design MistPanel around arbitrary hostile-unit inspection. Retail deliberately blocks much of that information.

## Incoming-danger prediction investigation

The session investigated whether MistPanel could predict incoming danger on party members by detecting hostile casts, hostile targets, or party members being targeted by enemies.

Conclusion:

Generic per-party targeted incoming-danger prediction is not viable under current Retail restrictions.

The proof attempts showed that the addon cannot reliably access enough hostile-unit identity, target, range, aura, health, and cast timing information to make a generic system trustworthy.

This should not be treated as a normal bug. It is a platform limitation.

## Parked future idea: encounter/static spell classification

A different future approach remains possible:

- Classify known encounter mechanics or spell IDs.
- Use static spell metadata and encounter-specific rules.
- Mark danger based on known events rather than generic hostile-target prediction.

That approach is explicitly parked for later. It should be designed as an encounter/spell knowledge system, not as a generic "who is this enemy targeting?" system.

## Temporary debug command to remove later

`/mistpanel predicttest` was useful for proving the Retail prediction limitations.

If incoming-danger prediction remains parked or removed from active development, this command should eventually be removed from the public slash-command surface. Keeping permanent dead-end debug commands is how addons become archaeological sites.

## End-of-night unresolved bug

### Blizzard party frames remain visible

This is the clear first task for the next session.

Observed facts:

- ElvUI was disabled completely.
- Blizzard party frames were still visible.
- MistPanel's Blizzard-frame audit reported:
  - `PartyFrame` exists and is hidden.
  - `CompactPartyFrame` exists and is hidden.
  - `CompactRaidFrameContainer` exists and is hidden.
- Despite that, visible Blizzard party frames remained on screen.

Conclusion:

The current suppression audit is incomplete or is checking the wrong frame objects. The visible Retail party-frame implementation is not fully represented by only `PartyFrame`, `CompactPartyFrame`, and `CompactRaidFrameContainer`.

Next-session task:

1. Audit the actual live Retail frame hierarchy for the visible Blizzard party frames.
2. Identify the specific visible objects, children, manager frames, or Edit Mode party-frame system responsible.
3. Add debug output that reports the visibility and parentage of those exact objects.
4. Suppress the correct frame hierarchy without breaking secure combat behaviour.
5. Re-test with ElvUI disabled first.
6. Only after Blizzard frames are correctly suppressed, re-test with ElvUI enabled to identify any separate ElvUI party-frame issue.

Candidate objects to investigate:

- `CompactPartyFrame`
- `CompactPartyFrameMember1` through `CompactPartyFrameMember5`
- `CompactRaidFrameContainer`
- `CompactRaidFrameManager`
- `PartyFrame`
- `PartyMemberFrame1` through `PartyMemberFrame4`
- Edit Mode party-frame containers
- Any modern Retail party-frame manager or compact unit-frame parent not currently audited

## Documentation and roadmap impact

Recommended follow-up documentation updates:

- Update `TESTING.md` once Blizzard-frame suppression is fixed.
- Record the Retail secret-value findings in the implementation notes or roadmap so prediction work is not repeatedly re-opened as though it were merely unfinished.
- Add a short ADR if the project formally decides to defer generic incoming-danger prediction and later pursue static encounter/spell classification instead.

Suggested next commit after the next session:

- `Fix Blizzard party frame suppression`

