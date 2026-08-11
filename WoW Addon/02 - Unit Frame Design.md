UNIT FRAME DESIGN  
Status: Confirmed visual specification from design interview and Stitch iterations

1\. Party Block  
• Five horizontal unit frames stacked vertically.  
• Consistent role order: Tank → Healer/user → DPS → DPS → DPS.  
• Small visual gap between frames.  
• The whole block moves as one unit.  
• Individual frames are not independently positioned.  
• Lock mode prevents accidental movement.  
• Unlock mode exposes the block anchor/layout controls.

2\. Frame Scale  
Three presets: Small / Medium / Large.

Presets scale the same design proportionally rather than using different layouts. Health-line thickness, icons and other visual elements scale with the frame.

The reference design is a compact horizontal frame approximately in the 200–220 px wide and ~50 px tall family before scaling. Exact implementation dimensions may be tuned during in-game testing.

3\. Background  
The frame interior features a subtle, dark, desaturated class-specific tint (`RAID_CLASS_COLORS` desaturated and darkened to ~18% brightness + 4% base dark tint).

This class tint provides clear visual class context while maintaining maximum contrast for health bars, resource bars, HoTs, role icons, and combat state outlines.

4\. Role Indicator  
A small standard role indicator sits in a narrow gutter on the far left.

Roles shown: Tank, Healer, DPS.

No player name is displayed. The stable party ordering and role icon provide identity sufficient for this personal use case.

5\. Health & Primary Resource Bar  
Health is a 10px horizontal bar anchored along the bottom of the unit frame.

Directly underneath the health bar sits a thin (3px) primary resource bar displaying each unit's active resource type (Mana, Energy, Rage, Focus, Runic Power, etc.).

Absorbs / Shields:
Incoming shield absorbs (such as Life Cocoon or Power Word: Shield) render as a semi-transparent cyan overlay directly on top of the health bar.

Behaviour:  
• Full health = full-width green line.  
• Damage causes the line to retreat from right to left.  
• Primary resource bar sits below health as a thin subordinate indicator.  
• Absorbs overlay on the health bar dynamically.  
• No health, power, or absorb numbers are displayed.

6\. Duration-Based Healing Effects & Defensive Mitigation Icons  
Only the user's own healing effects with a duration are visualized via vertical duration bars (EQ bars) positioned directly above 11x11 spell icons.

Active Self-Defensive Mitigation Icons:
When a party member activates a major self-defensive cooldown (e.g. Barkskin, Shield Wall, Divine Shield, Ice Block, Fortifying Brew, Astral Shift), a small 14x14px defensive icon with a subtle gold border appears in the upper right main area of their frame for the duration of the buff.

Effects dynamically pack from left to right. There are no permanently visible empty HoT slots.

Ordering is predetermined by spell/effect rather than cast order, so the display remains spatially stable. Active effects close gaps while retaining that predetermined ordering.

All relevant duration-based Mistweaver healing effects that can coexist may be displayed; there is no arbitrary four-effect cap.

Each tracked effect receives a fixed colour assigned in code. V1 does not expose colour customization.

7\. Aggro  
Aggro is communicated through the outer frame outline.

• Red outer outline \= aggro.  
• Applies to any party member, including the tank.  
• Aggro does not alter the health bar or HoT indicators.

8\. Dispel  
A dispellable harmful effect is also communicated through the outer frame outline.

• Pink outer outline \= the Mistweaver can dispel something on this player.  
• The specific debuff does not need to be identified.  
• Pink dispel outline takes priority over the red aggro outline.  
• If the dispellable effect disappears while aggro remains, the outline immediately returns to red.

9\. Range and Death  
Out of range:  
• Entire frame dims/desaturates.

Dead:  
• Entire frame is heavily dimmed/greyed.

No additional text is required for either state.

10\. Visual Channel Rules  
Each visual channel has one job:  
• Bottom horizontal line length/colour \= health.  
• Vertical coloured bar height \= remaining duration.  
• Spell icon \= effect identity.  
• Predetermined left-to-right order \= stable effect recognition.  
• Red outer outline \= aggro.  
• Pink outer outline \= actionable dispel, overriding aggro.  
• Left role icon \= Tank / Healer / DPS.  
• Whole-frame dimming \= unavailable due to range/death.

11\. Explicitly Excluded Visuals  
Do not add:  
• Names.  
• Health percentages/numbers.  
• Mana/resource values.  
• Portraits.  
• Cast bars unless explicitly added in a future specification.  
• HoT expiry pulses/flashes/prompts.  
• Empty HoT tracks.  
• Shields/absorbs.  
• Generic debuff icons.  
• Additional border colours or invented status indicators.

The visual design should remain closer to a compact healer instrument panel than a conventional filled-health unit frame.  
