PRODUCT VISION  
Working title: WoW Addon (final name TBD)  
Status: Initial product specification

1\. Purpose  
This is a personal World of Warcraft Retail addon built specifically around the user's Mistweaver Monk dungeon-healing playstyle.

Its core purpose is to let the healer make a fast visual judgement about which healing spell to cast on which party member, then cast that spell directly through mouse-button interaction with the party frame.

The addon replaces two things only:  
• Clique-style click casting.  
• Party unit frames.

It is not intended to replace the player's complete WoW UI.

2\. Product Scope  
V1 is deliberately narrow:  
• Mistweaver Monk only.  
• Five-player dungeon parties only.  
• Player characters only; no pets.  
• No raid frames.  
• Hidden while solo.  
• Automatically hides Blizzard party frames while active, with an option to disable that behaviour.

3\. Core Design Philosophy  
The interface is an instrument panel, not a conventional information-heavy unit-frame addon.

Every displayed element should answer an immediate healing decision. Information that does not change the next action should normally be omitted.

Primary principle: communicate through geometry, colour, position and state rather than text and numbers.

The healer should be able to glance at the five frames and rapidly determine:  
• Who needs healing.  
• Which of the healer's duration-based healing effects are active on each player.  
• Roughly how long those effects have remaining.  
• Who currently has aggro.  
• Who has a harmful effect the Mistweaver can dispel.  
• Who is out of range or dead.

4\. Interaction Philosophy  
The unit frame is also the click-casting surface. Healing should not require changing the player's current target.

The primary binding model uses physical mouse buttons. The user has a multi-button gaming mouse and expects enough physical buttons to avoid modifiers for routine healing. Shift and Ctrl remain available as optional reserve modifiers.

Normal Blizzard-style frame interactions are retained through modifier bindings rather than occupying the primary unmodified clicks.

5\. Deliberate Non-Goals  
V1 does NOT include:  
• Raid support.  
• Generic support for every healer/class.  
• Player names.  
• Health numbers or percentages.  
• Mana/resource numbers.  
• Portraits.  
• Pet frames.  
• Shields/absorb visualization.  
• Generic buff/debuff display.  
• Identification of dispellable debuffs; only whether the user can dispel something matters.  
• HoT expiry flashing, recast prompts or separate warning systems. The duration bar itself is the warning.  
• Mouse-wheel bindings.  
• AFK/disconnect-specific presentation.  
• Enemy-target indicators separate from aggro.  
• Extensive theme/colour customization.

6\. Configuration Philosophy  
Configuration should be small and task-focused, not an ElvUI-style settings system.

Required configuration includes:  
• Clique-style mouse-button binding capture.  
• Small / Medium / Large frame scale presets.  
• Lock / Unlock Frames.  
• Test mode.  
• Option to hide/show Blizzard party frames.  
• Access through both a slash command and WoW AddOns settings.

Bindings and settings are shared across characters by default.

7\. Product Identity  
This is a personal, Mistweaver-first dungeon healing tool. It should not grow into a general-purpose unit-frame framework unless that decision is made explicitly later.

TBD  
• Final addon name.  
• Exact implementation choices required by the current WoW secure UI and aura APIs.  
