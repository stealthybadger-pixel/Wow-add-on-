PHASE 0 — FEASIBILITY AND API REVIEW  
Status: Investigation complete. Verified against current Retail WoW 12.0.7 (Midnight), API state as documented through August 2026\.

SUMMARY TABLE

Feature | Classification  
Custom secure 5-player party frames | SUPPORTED  
Fixed role ordering (Tank/Healer/DPS/DPS/DPS) | SUPPORTED  
Health tracking | SUPPORTED  
Role detection | SUPPORTED  
Aggro/threat detection | SUPPORTED  
Dispel-type detection (actionable-only, no identity) | SUPPORTED  
Range detection | SUPPORTED  
Dead-state detection | SUPPORTED  
Renewing Mist tracking (duration, source, refresh) | SUPPORTED  
Enveloping Mist tracking (duration, source, refresh) | SUPPORTED  
Soothing Mist tracking as a duration bar | UNCERTAIN / NEEDS IN-GAME TEST  
Aspect of Harmony (excluded per spec rule 4.2) | NOT APPLICABLE — correctly excluded by spec, confirmed technically trackable if ever reconsidered  
Click casting without changing target | SUPPORTED  
Arbitrary mouse-button capture (incl. Logitech G502 side buttons) | SUPPORTED  
Optional Shift/Ctrl modifiers, preserved Blizzard interaction | SUPPORTED  
Combat-lockdown-safe configuration | SUPPORTED WITH RESTRICTIONS  
Automatic discovery of available Mistweaver healing spells | SUPPORTED  
Hiding Blizzard party frames | SUPPORTED WITH RESTRICTIONS  
Simulated Test Mode frames | SUPPORTED

Overall feasibility: HIGH. Every core mechanic the specification depends on has a supported, non-hacky, current API path. No part of the design requires an insecure workaround. Two items carry implementation restrictions that affect \*how\*, not \*whether\*, they are built. One item (Soothing Mist as a duration bar) needs a short in-game check before Phase 3 commits to it.

\===================================================================  
1\. CUSTOM SECURE PARTY FRAMES \+ CLICK CASTING WITHOUT CHANGING TARGET  
\===================================================================  
Classification: SUPPORTED

What the spec wants: Five custom-built party frames that are simultaneously (a) visually bespoke instrument panels and (b) directly click-castable, healing the clicked/hovered unit without disturbing the player's current target.

What Blizzard permits: This is a first-class, officially supported pattern. Blizzard added native "Click Casting" to the default UI in Patch 9.2.0, built on the same secure template system available to addons: SecureUnitButtonTemplate / SecureActionButtonTemplate. A button created with these templates and given SetAttribute("unit", partyUnit) plus SetAttribute("type1", "spell") / SetAttribute("spell1", spellName) will cast that spell on that specific unit when clicked — completely independent of whatever the player currently has hard-targeted. This is exactly the mechanism Clique, Cell, DandersFrames and other current (2026, patch 12.0.7-compatible) party/raid frame addons use for click-casting today.

Effect on the addon: None negative. This is the intended, sanctioned path — not a workaround.

Closest option preserving intent: Build each of the five frames as a SecureUnitButtonTemplate-based button with unit set to party1-4 (or partyN plus a role-mapped slot for the player) and register it in the standard ClickCastFrames table (Blizzard's own cross-addon click-cast registry, documented via the "Guide to Click Casting" pattern) so it also cooperates with any other click-cast addon the user might layer in later. Attribute configuration must happen only when not InCombatLockdown() (see Section 6).

\===================================================================  
2\. FIXED ROLE ORDERING, ROLE ICONS, ROSTER INFO  
\===================================================================  
Classification: SUPPORTED

UnitGroupRolesAssigned(unit) returns "TANK", "HEALER", "DAMAGER", or "NONE" for any party unit and is freely readable at all times, including in combat. Building a fixed Tank \-\> Healer/user \-\> DPS \-\> DPS \-\> DPS ordering is a matter of addon-side sorting logic over the party1-4 \+ player unit tokens; no API restriction applies to reading or reordering based on this data.

\===================================================================  
3\. HEALTH, AGGRO, RANGE, DEAD-STATE  
\===================================================================  
Classification: SUPPORTED

\- Health: UnitHealth / UnitHealthMax, updated via the standard UNIT\_HEALTH event. No restrictions.  
\- Aggro/threat: UnitThreatSituation(unit) returns 0-3 threat status for any party member (including the tank) at all times. This is the same call the default UI uses for its aggro glow. No restrictions, no combat lockdown issue — it is a plain read.  
\- Range: UnitInRange(unit) returns inRange plus a checkedRange flag confirming whether a check was actually possible. Reliable, unrestricted read.  
\- Dead-state: UnitIsDeadOrGhost(unit) / UnitIsConnected(unit), standard reads, unrestricted.

None of these are protected or secured values — they can be read and used to drive frame visuals from ordinary insecure addon code at any time, including mid-combat. The only combat-lockdown-relevant part of the design is changing secure frame \*attributes\* or \*showing/hiding protected frames\* (see Section 6), not reading unit state.

\===================================================================  
4\. DISPEL DETECTION (ACTIONABLE-ONLY, NO IDENTITY)  
\===================================================================  
Classification: SUPPORTED

What the spec wants: Know only whether the Mistweaver can currently dispel something on a party member — no debuff name, icon, or type shown to the user.

What Blizzard permits: UnitAura / C\_UnitAuras.GetAuraDataByIndex (filter "HARMFUL") exposes each harmful aura's dispelType ("Magic", "Curse", "Poison", "Disease", or nil). This is a plain, unrestricted read available at all times, including combat.

Current Mistweaver dispel capability (verified against 12.0.7 Mistweaver kit): Detox is the Mistweaver's dispel. In its base form it removes Magic-type effects only. The talent Improved Detox extends this to also cover Poison and Disease. This talent state must be discovered at runtime — the addon should check C\_SpellBook.IsSpellKnown() / the player's current talent loadout for Improved Detox rather than assuming a fixed dispel-type set, exactly as the spec's Section 10 "API Safety Rule" requires. The addon iterates each party member's harmful auras and lights the pink outline if any debuff's dispelType is in the currently-known dispellable set.

Effect on the addon: Fully buildable exactly as specified, provided dispel-type coverage is computed from current talent state rather than hard-coded.

\===================================================================  
5\. RENEWING MIST, ENVELOPING MIST, SOOTHING MIST, DURATION TRACKING  
\===================================================================  
Classification: SUPPORTED (Renewing Mist, Enveloping Mist) / UNCERTAIN — NEEDS IN-GAME TEST (Soothing Mist)

What the spec wants: For each qualifying duration-based Mistweaver healing effect the player applies, track: current existence on a unit, remaining duration, and whether a talent-driven refresh/extension is reflected accurately — all readable during combat.

What Blizzard permits: UnitAura / UnitDebuff / C\_UnitAuras.GetAuraDataByIndex return, per aura: name, icon, spellId, dispelType, duration, expirationTime, source (caster unit), and castByPlayer / isFromPlayerOrPlayerPet (a boolean confirming the aura's origin is the player or the player's pet/vehicle). All of these fields are available unrestricted at all times, including in combat — there is no "secret" gating on this data for ordinary party members. Remaining duration is simply expirationTime \- GetTime(), recomputed live; when a talent like Rising Mist refreshes/extends Renewing Mist or Enveloping Mist, the API's expirationTime value updates to reflect the new true expiry, so the addon does not need to model talent math itself — it only needs to re-read the aura data on refresh events (UNIT\_AURA).

Verified current spell state (12.0.7 Midnight):  
\- Renewing Mist (spell ID 119611): confirmed as a core, currently-live Mistweaver HoT in all mainstream 2026 guides (Method, Maxroll, Icy Veins). Duration-based, applies to any party member, player-source distinguishable via castByPlayer/source. SUPPORTED.  
\- Enveloping Mist (spell ID 124682): confirmed as a core, currently-live Mistweaver HoT/heal-over-time-adjacent effect for 12.0.7. Same aura-data guarantees apply. SUPPORTED.  
\- Rising Mist talent: confirmed still present in 12.0.7 talent trees, extending Renewing Mist and Enveloping Mist durations (guides describe it extending both by a fixed number of seconds on Rushing Wind Kick/Rising Sun Kick casts). Because this shows up as an updated expirationTime on the existing aura rather than a new aura instance, the vertical-bar "refresh without repositioning" behavior specified in doc 02/04 is directly achievable by re-reading expirationTime on UNIT\_AURA and adjusting bar height, with no ID/position change.  
\- Soothing Mist (spell ID 115175): this is Mistweaver's channelled heal, not a classic duration-buff in the same sense as the other two. Whether it manifests as a per-unit "HELPFUL" aura with a stable duration/expirationTime useful for a vertical bar (versus purely a channel state on the caster, or a very short/rolling duration that would look visually noisy) needs to be confirmed by watching /dump UnitAura output live during a channel. The specification (doc 04, Section 2\) already anticipates this and explicitly defers the decision to in-game validation rather than assuming inclusion. This document concurs: do not include Soothing Mist in the V1 equalizer track list until that check is done.  
\- Aspect of Harmony (spell ID 450769): technically present in current aura-list documentation, but the specification (doc 04\) correctly excludes it because it isn't a simple player-owned duration-based heal in the decision-relevant sense the equalizer is meant to convey (it's a proc/passive-triggered effect). No API concern — this is a design decision already made correctly in the spec, not a Phase 0 blocker.

Effect on the addon: Renewing Mist and Enveloping Mist can be built exactly as specified in Phase 3\. Soothing Mist requires one short in-game observation pass (a few /dump UnitAura("partyN") calls while channeling) before deciding whether it gets a track.

\===================================================================  
6\. COMBAT-LOCKDOWN RESTRICTIONS  
\===================================================================  
Classification: SUPPORTED WITH RESTRICTIONS

What the spec wants: Configuration (bindings, scale, lock/unlock, Blizzard-frame-hide toggle) should work smoothly, and where something genuinely can't change during combat, the UI should say so cleanly rather than silently failing or being bypassed insecurely.

What Blizzard permits: This is standard, well-documented WoW addon behavior, not something specific to this design:  
\- Frame:SetAttribute() on a protected/secure frame is itself protected and can only succeed when not InCombatLockdown(). This governs: assigning which unit a click-cast frame targets, assigning which spell a button casts, and any macro-text changes.  
\- Secure frames generally cannot be created, resized, reparented, or have their protected state changed while in combat lockdown.  
\- Reading data (health, auras, threat, range, dead-state, spellbook) is unrestricted in combat; only writing secure attributes/frame state is restricted.  
\- InCombatLockdown() is a simple, reliable boolean check available at all times, and PLAYER\_REGEN\_DISABLED / PLAYER\_REGEN\_ENABLED events fire exactly at lockdown start/end, giving the addon a clean way to detect the transition and queue changes.

Effect on the addon: Binding capture, spell (re)assignment to click-cast buttons, and the scale/lock/frame-shape changes described in doc 03/05 must be disabled or deferred while InCombatLockdown() is true. This is a normal, expected constraint for this entire category of addon — not a design conflict.

Closest option preserving intent: On any configuration change request received while in combat, the addon should visibly disable/grey the relevant control (or show a short "available out of combat" note) rather than attempt the change and silently fail, and should apply the queued change automatically on the next PLAYER\_REGEN\_ENABLED event where appropriate (e.g., binding assignments the user made mid-fight via a non-secure UI can be applied to the secure buttons the moment combat ends).

\===================================================================  
7\. AUTOMATIC DISCOVERY OF AVAILABLE MISTWEAVER HEALING SPELLS  
\===================================================================  
Classification: SUPPORTED

What the spec wants: The binding UI should list the player's currently available Mistweaver healing spells/actions without manual typing, and reflect the player's actual current talent build.

What Blizzard permits: C\_SpellBook.GetNumSpellBookSkillLines() / C\_SpellBook.GetSpellBookSkillLineInfo() / C\_SpellBook.GetSpellBookItemInfo() give a full, current enumeration of the player's spellbook, including spells granted or altered by the active talent build. C\_SpellBook.IsSpellKnown(spellID) and IsPlayerSpell(spellID) both give simple, reliable per-spell checks. None of this is combat-restricted for reading.

Effect on the addon: The binding screen can enumerate the current Mistweaver healing spell set (Renewing Mist, Enveloping Mist, Vivify, Life Cocoon, Soothing Mist, Revival, etc., filtered to healing-relevant entries) live from the spellbook, re-scanning on PLAYER\_TALENT\_UPDATE / SPELLS\_CHANGED, with no manual entry required.

\===================================================================  
8\. ARBITRARY MOUSE-BUTTON CAPTURE (INCLUDING LOGITECH G502 SIDE BUTTONS)  
\===================================================================  
Classification: SUPPORTED

What the spec wants: A Clique-style "press the physical button you want to bind" capture flow that works for any mouse button the OS reports, including G502 side buttons, without the user needing to know technical button names.

What Blizzard permits: Buttons/frames report mouse interaction via OnMouseDown / OnMouseUp / OnClick handlers, which pass a button-identifier string as an argument. Standard values are "LeftButton", "RightButton", "MiddleButton", "Button4", "Button5", and WoW is documented to pass through further numbered buttons (Button6, Button7, ...) for mice that expose more physical buttons at the OS/HID level — this is exactly how existing 2026-current addons (e.g., OneButtonMount, per its 2026 changelog, explicitly supporting "BUTTON4/5" chord capture) implement side-button-aware binding capture today. A capture-mode overlay frame that listens on OnMouseDown/AnyDown and records whatever button string comes back, without needing the addon (or the user) to know the button's name in advance, is the same approach Clique itself and its ecosystem use, and is fully supported. Shift/Ctrl modifier combinations are captured the same way by checking IsShiftKeyDown()/IsControlKeyDown() at the moment of capture.

Effect on the addon: Achievable exactly as specified, including making Shift/Ctrl fully optional reserve capacity rather than a requirement.

Caveat: whether a given Logitech G502 side button reports as "Button4"/"Button5"/etc. depends on the mouse's driver/software mode (native HID buttons vs. Logitech Options+ macro/keystroke remapping). If a G502 button is configured in Logitech's software to send a keystroke instead of acting as a native extra mouse button, WoW will see a keypress, not a mouse-button event, and the capture flow should handle both cases (keyboard capture and mouse-button capture) or the doc should note that G-side buttons must be left in "native button" mode in Logitech software for this addon's capture flow to see them as mouse buttons.

\===================================================================  
9\. RETAINED BLIZZARD-STYLE FRAME INTERACTION VIA MODIFIERS  
\===================================================================  
Classification: SUPPORTED

Secure templates support per-modifier attribute variants (e.g., type1 vs shift-type1 vs ctrl-type1), so an unmodified click can be bound to a heal while a modified click (Shift/Ctrl \+ click) is bound to "target" or "togglemenu" on the same button, exactly matching current Clique/DandersFrames behavior and the addon's own requirement that "primary unmodified mouse buttons may be used for healing" while "normal Blizzard-style unit-frame interactions remain accessible through modifiers."

\===================================================================  
10\. HIDING BLIZZARD PARTY FRAMES  
\===================================================================  
Classification: SUPPORTED WITH RESTRICTIONS

What the spec wants: Automatically hide the default Blizzard party frames while this addon is active, with an option to disable that behavior.

What Blizzard permits: This is achievable, but the \*method\* matters. Naively calling :Show()/:Hide() directly on Blizzard's protected CompactPartyFrame (or hooking its Show function) is a well-known source of taint, which can then propagate into Blizzard's own secure code and break party-frame updates during combat (e.g., frames failing to update if a player disconnects/reconnects or joins mid-fight) — this exact failure mode is documented by multiple existing "hide raid/party frame" addons going back years, including reports as recent as this expansion cycle. The safe, taint-free method (used by current, actively-updated 2026 addons such as "Hide Unit Frames") is to drive visibility through Blizzard's own secure visibility driver system (the same mechanism Edit Mode uses) rather than calling Show/Hide directly on the protected frame from insecure code.

Effect on the addon: Fully buildable, but must be implemented via the secure-driver approach, not a direct Hide() override, to avoid combat-lockdown taint bugs. This is an implementation-technique constraint, not a feasibility blocker.

\===================================================================  
11\. SIMULATED TEST-MODE FRAMES  
\===================================================================  
Classification: SUPPORTED

Test Mode frames are, by design, not bound to real secure unit tokens — they are ordinary addon-drawn frames the addon fully controls, populated with fabricated example state (health values, fake active effect timers, fake aggro/dispel/range flags) rather than live UnitAura/UnitHealth reads. Because they don't need to inherit secure templates at all (no real spellcasting occurs), there are no combat-lockdown or secure-attribute concerns whatsoever. "Clicking" a test frame can simply look up what the corresponding real binding would be (from the addon's saved binding table) and print/report it without invoking any secure action — trivially satisfying the "must not cast spells" requirement in doc 03, Section 9\.

\===================================================================  
OVERALL FEASIBILITY  
\===================================================================  
High. Every mechanic central to the product vision — secure click-cast party frames independent of current target, full arbitrary mouse-button capture including gaming-mouse side buttons, live aggro/range/dead/dispel-type state, and accurate in-combat duration tracking for the player's own Renewing Mist and Enveloping Mist including talent-driven extensions — has a direct, currently-supported, non-workaround API path in the 12.0.7 Midnight client. Nothing in the specification requires taint, insecure hooking, or fabricated/approximated data.

\===================================================================  
BLOCKERS  
\===================================================================  
None. No feature in the specification is classified NOT POSSIBLE UNDER CURRENT API.

\===================================================================  
ITEMS REQUIRING AN IN-GAME PROOF OF CONCEPT  
\===================================================================  
1\. Soothing Mist as an equalizer track: confirm via live /dump UnitAura (or equivalent) on a party member during an actual Soothing Mist channel whether it presents as a stable per-unit HELPFUL aura with a usable duration/expirationTime, or whether it behaves more like a channel-only state that would look noisy/flickery as a vertical bar. Decide inclusion/exclusion only after this check, per doc 04's own instruction.  
2\. Blizzard party-frame hide toggle: confirm in a live dungeon party that the secure-driver-based hide approach does not reintroduce any frame-update issues when party composition changes mid-combat (member disconnect/reconnect, mid-combat join).  
3\. Logitech G502 side-button reporting: confirm in-client which of the mouse's side buttons arrive as native WoW mouse-button events (Button4/5/6...) versus emulated keystrokes under the user's current Logitech software configuration, since this determines whether the binding-capture flow needs to also listen for keyboard events.

\===================================================================  
SPECIFICATION DECISIONS THAT NEED USER INPUT  
\===================================================================  
1\. Fixed dispel-type coverage: should the pink dispel outline reflect only Magic (base Detox) or Magic+Poison+Disease (if/when Improved Detox is talented)? Recommended default: always compute from current live talent state (Section 4 above) rather than asking the user to choose — this matches doc 04's "API Safety Rule" and requires no additional decision, but the user should confirm this default behavior is acceptable versus, e.g., a manual override.  
2\. Whether to also expose Vivify, Life Cocoon, Revival, and other direct/instant Mistweaver heals in the auto-discovered click-binding spell list from Phase 4 onward (they carry no duration track per doc 04 Section 5, but are legitimate click-cast targets) — the current specs already answer this as "yes, in the binding list, no visual track," so no actual open decision here; flagged only to confirm shared understanding before Phase 4 begins.  
3\. Exact modifier key(s) reserved for retained Blizzard interactions (doc 03 Section 6 leaves this "configurable/implementation-defined") — recommend defaulting to Shift for target/menu actions and leaving Ctrl fully free for healing binds, but this is a product decision, not an API constraint.

\===================================================================  
RECOMMENDED SCOPE FOR SMALLEST PLAYABLE PROTOTYPE  
\===================================================================  
A minimal but genuinely useful first playable slice, consistent with the roadmap's own Phase 1-2 boundary:  
1\. Five-player vertical frame block, correct role ordering, near-black background, thin bottom health bar with green-to-red coloring, small gaps, Small/Medium/Large scale, Lock/Unlock — no click-casting yet, no HoT bars yet (Phase 1 exactly as scoped).  
2\. Add aggro (red) and dispel (pink, priority) outlines plus range/dead dimming (Phase 2 exactly as scoped) — this alone, even before any healing-effect visualization or click-casting exists, is already a usable "who needs attention" panel and a good point to validate frame stability in a real dungeon before adding more surface area.  
Recommend not attempting click-casting (Phase 4\) until after the Renewing Mist/Enveloping Mist duration display (Phase 3\) is confirmed working in a live dungeon, since Phase 3 is pure reads (safe, low-risk) while Phase 4 introduces the first secure-attribute/combat-lockdown surface area — validating the read-only visual layer first keeps early debugging entirely outside of secure-template territory.

Do not implement the addon yet. This document is investigation only. Specification decisions listed above should be resolved with the user before Phase 1 implementation begins in earnest, though none of them block starting Phase 1 itself since Phase 1 has no dependency on the open items.