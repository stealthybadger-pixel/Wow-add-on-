ROADMAP  
Status: Initial implementation sequence

Guiding rule: implement the documented product. Do not redesign or broaden scope during coding.

PHASE 0 — CURRENT RETAIL API VALIDATION  
Goal: prove the requested design is feasible against the current WoW Retail API before building substantial UI.

Validate:  
• Secure clickable party frames.  
• Mouse-button capture/binding approach.  
• Combat-lockdown restrictions on changing bindings/frame attributes.  
• Party roster/role information.  
• Health updates.  
• Range state.  
• Death state.  
• Threat/aggro state.  
• Detection of only harmful effects the Mistweaver can dispel.  
• Aura source ownership.  
• Aura duration/expiration data for relevant Mistweaver healing effects.

Deliverable: short technical feasibility note listing any API limitations before implementation proceeds.

PHASE 1 — PARTY FRAME SHELL  
Build:  
• Five-player vertical block.  
• Role ordering: Tank → Healer/user → DPS → DPS → DPS.  
• Near-black frames.  
• Role gutter/icons.  
• Thin bottom health line.  
• Health length \+ green-to-red state colouring.  
• Small frame gaps.  
• Small / Medium / Large scale presets.  
• Lock / Unlock and block dragging.  
• Hide when solo.  
• No raid mode.  
• Optional automatic hiding of Blizzard party frames.

Acceptance: stable, readable five-player party panel with no healing-effect logic yet.

PHASE 2 — COMBAT STATES  
Add:  
• Red aggro outline for any party member with aggro.  
• Pink actionable-dispel outline, taking priority over red.  
• Out-of-range dim/desaturation.  
• Dead heavy dim/grey state.

Acceptance: all core non-HoT visual states are reliable and do not compete with each other.

PHASE 3 — MISTWEAVER DURATION DISPLAY  
Add only validated, relevant, user-owned duration-based healing effects.

Implement:  
• Genuine spell icon.  
• Fixed effect colour.  
• Vertical remaining-duration bar.  
• Predetermined effect ordering.  
• Dynamic left-to-right packing of active effects.  
• Refresh updates bar duration without unnecessary movement.  
• Complete disappearance on expiry.  
• No inactive tracks.  
• No timer numbers.  
• No expiry warning/pulse.

Acceptance: a glance across five frames clearly communicates the user's current healing-effect coverage and approximate remaining durations.

PHASE 4 — CLICK CASTING  
Implement secure click casting on the party frames.

Build:  
• Automatic list of currently available Mistweaver healing spells/actions.  
• Clique-style physical mouse-button capture.  
• Dedicated dispel binding.  
• Shift/Ctrl reserve modifier support.  
• No mouse-wheel requirement.  
• Retained Blizzard-style frame interaction via modifiers.

Acceptance: the user can configure the G502 by physically pressing desired buttons and heal party members without changing current target.

PHASE 5 — CONFIGURATION AND TEST MODE  
Build:  
• WoW AddOns settings entry.  
• Slash command.  
• Binding management UI.  
• Scale preset selection.  
• Lock/Unlock.  
• Blizzard party-frame hide toggle.  
• Five-player simulated Test Mode.  
• Test binding clicks report what would cast without actually casting.

Acceptance: configuration can be completed without joining a real party.

PHASE 6 — COMPACT FRAME VISUAL ADDITIONS & REFINEMENTS  
Implemented:  
• Exhaustive multi-frame Blizzard party suppression (PartyFrame, CompactPartyFrame, CompactRaidFrameContainer, Pool Members).  
• Thin primary resource bar (Mana, Energy, Rage, Focus, Runic Power, etc.) underneath health.  
• Class-colored dark desaturated backgrounds (`RAID_CLASS_COLORS` tinted).  
• Cyan absorb/shield overlay (supporting Life Cocoon, PW:Shield, etc.).  
• Active self-defensive mitigation icons (Barkskin, Shield Wall, Divine Shield, Ice Block, Fortifying Brew, Astral Shift, etc.).  

OUT OF V1  
• Raid frames.  
• Pets.  
• Other healer classes.  
• General-purpose unit frames.  
• Player/target/focus/boss replacement frames.  
• Names and numeric health text.  
• Generic debuff panels.  
• Mouse-wheel bindings.  
• AFK/disconnect indicators.  
• Per-character profiles.  
• Extensive visual/theme editor.

FUTURE DECISIONS  
Only after V1 is working in real dungeon use should any expansion of scope be considered.

Final addon name remains TBD.  
