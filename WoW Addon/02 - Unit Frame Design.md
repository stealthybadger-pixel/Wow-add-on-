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

The reference design is a compact horizontal frame approximately in the 200–220 px wide and \~50 px tall family before scaling. Exact implementation dimensions may be tuned during in-game testing.

3\. Background & Outer Border  
The frame features a thin black outer border surrounding a dark, heavily desaturated class-coloured inner background (derived from official class hex codes and heavily darkened).

The class-tinted interior provides subtle unit identity while remaining dark and mostly empty to preserve maximum contrast for duration-based healing indicators.

4\. Role Indicator  
A small standard role indicator sits in a narrow gutter on the far left.

Roles shown: Tank, Healer, DPS.

No player name is displayed. The stable party ordering and role icon provide identity sufficient for this personal use case.

5\. Health & Primary Resource  
Health is NOT a full-frame fill.

Health is a 7px horizontal bar anchored along the bottom of the main content area (starting immediately after the role-gutter divider at `X = ROLE_COLUMN_WIDTH + 1`, leaving a 1px black gap above the health bar).

Behaviour:  
• Full health = full-width line.  
• Damage causes the line to retreat from right to left.  
• Length is the primary health measure.  
• Colour communicates health level, shifting dynamically from Green (high/100%) → Yellow (mid/50%) → Red (low/0%).  
• The line is one solid health-level colour at a time; it is not a decorative left-to-right rainbow gradient.  
• No health number or percentage is displayed.

A very thin (3px) primary resource bar sits directly below the health bar in the main content area (starting at `X = ROLE_COLUMN_WIDTH + 1`). It displays the unit's primary resource (Mana, Rage, Energy, Focus, Runic Power) coloured by power type using standard WoW power colours. It occupies the main content area only, keeping the left role icon gutter completely clear. No numeric values or text are displayed.

5b\. Role Gutter Auxiliary State Bars  
The left role-icon gutter carries two compact horizontal state bars rendered behind the role icon:  
• **Shield Absorb Bar** (7px near-white `#EAF7FF`): Anchored at Y=5..12 (matching health bar height). Shows percentage remaining of current shield amount, draining right-to-left as damage is absorbed.  
• **Threat Intensity Bar** (3px red/orange): Anchored at Y=1..4 (matching resource bar height). Shows graduated threat intensity (0 = empty, 1 = 1/3, 2 = 2/3, 3 = full) filling right-to-left. Subordinate to the primary red outer aggro outline.  
• Both bars remain inside the left role column and render behind the role icon so the role icon remains clear, visible, and readable.  
• No text or numbers are displayed.

6\. Duration-Based Healing Effects  
Only the user's own healing effects with a duration are visualized.

Each active effect is represented as one vertical instrument:  
• Genuine spell icon at the bottom.  
• A coloured vertical duration bar rising directly above the icon.  
• Full/tall bar \= high remaining duration.  
• Bar progressively drops toward the icon as duration expires.  
• No numeric timer.  
• When the effect expires, both icon and bar disappear completely.  
• When an effect is inactive, NOTHING is shown: no track, placeholder, dim icon or label.

Effects dynamically pack from left to right. There are no permanently visible empty HoT slots.

Ordering is predetermined by spell/effect rather than cast order, so the display remains spatially stable. Active effects close gaps while retaining that predetermined ordering.

When an existing effect is refreshed, its existing indicator remains in its ordered position and its vertical bar returns to the refreshed remaining duration.

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
• Numeric Mana/resource numbers or text.  
• Portraits.  
• Cast bars unless explicitly added in a future specification.  
• HoT expiry pulses/flashes/prompts.  
• Empty HoT tracks.  
• Generic debuff icons.  
• Additional border colours or invented status indicators.

The visual design should remain closer to a compact healer instrument panel than a conventional filled-health unit frame.  
