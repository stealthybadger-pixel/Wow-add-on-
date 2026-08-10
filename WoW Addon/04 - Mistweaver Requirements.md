MISTWEAVER REQUIREMENTS  
Status: Initial class-specific specification, checked against current 2026 Retail references

1\. Scope  
This addon is specifically for the user's Mistweaver Monk in five-player dungeon content.

The visual healing-effect system tracks only:  
• Effects applied by the user.  
• Healing effects that have a duration.  
• Effects that materially help the user decide what healing spell to cast next.

It does NOT attempt to visualize every beneficial Monk aura.

2\. Current Duration-Based Mistweaver Effects  
Current Retail 12.x API-change documentation explicitly lists the following Mistweaver auras among tracked aura data:  
• Soothing Mist — spell ID 115175\.  
• Renewing Mist — spell ID 119611\.  
• Enveloping Mist — spell ID 124682\.  
• Aspect of Harmony — spell ID 450769\.

For V1, Renewing Mist and Enveloping Mist are clearly duration-based healing effects relevant to the intended decision model.

Soothing Mist is a duration/channel-related healing state and should only be included in the equaliser display if current in-game behaviour and API exposure make it useful as a per-unit duration indicator. This must be validated in-game rather than assumed.

Aspect of Harmony must NOT be included merely because it appears in the API aura list. It should only be displayed if it meets the product rule: the user's own duration-based healing effect on a party member that changes the next healing decision.

The implementation should discover/validate the player's actual current talent/ability state rather than hard-code every possible Mistweaver talent as permanently present.

3\. Dynamic Effect Display  
The addon should maintain a predetermined ordering for eligible tracked healing effects.

Only currently active effects are rendered. Active effects pack left-to-right according to that predetermined ordering.

If an effect is refreshed, its existing bar updates to the refreshed duration without changing its logical order.

Only effects cast/applied by the user should trigger these indicators where source information is available through the current API.

4\. No Separate Expiry Warning  
There is deliberately no flashing, pulse, colour warning, recast prompt or text countdown when an effect approaches expiry.

The decreasing vertical bar height is itself the expiry information.

5\. Direct Heals  
Direct/instant healing spells may appear in the click-binding list but do not receive equaliser indicators unless they create a qualifying duration-based healing effect.

Visual tracking and click binding are separate concepts.

6\. Shields and Absorbs  
Do not display shields or absorb effects in the equaliser system.

7\. Dispel  
The user wants one dedicated dispel mouse binding.

The unit frame should indicate only whether that party member currently has a harmful effect the Mistweaver can dispel.

The user does not need:  
• Debuff name.  
• Debuff icon.  
• Debuff timer.  
• Debuff type explanation.

Pink outer frame outline \= actionable dispel.

This outline overrides the red aggro outline until the dispellable condition is gone.

8\. Spell Binding Discovery  
The binding screen should automatically present currently available Mistweaver healing spells/actions from the player's actual current spell/talent state where supported by the API.

Do not require manual typing of spell names.

9\. Current-Retail Validation Notes  
Retail 12.0 changed Mistweaver substantially. Current references confirm that Renewing Mist remains a core Mistweaver effect and that current talents still interact with Renewing Mist and Enveloping Mist durations. For example, Rising Mist extends those effects, meaning the UI must use actual aura expiration/duration data rather than assuming a fixed timer after cast.

This is especially important because talent interactions can alter durations.

10\. API Safety Rule  
Do not implement class mechanics from memory or old addon examples.

Before coding each tracked effect, validate:  
• Current spell ID.  
• Whether it is available in the user's current build.  
• Whether it is applied to a party unit.  
• Whether the current WoW API exposes its active state and usable duration/expiration information during combat.  
• Whether source/caster information is sufficient to distinguish the user's effect from another Monk's effect.

If current Retail API restrictions prevent a requested visual from being implemented reliably, document the limitation instead of fabricating data or approximating a timer.

11\. Confirmed Exclusions  
• No raid-specific Mistweaver logic.  
• No generic healer abstraction in V1.  
• No shields/absorbs.  
• No every-buff display.  
• No HoTs from other players.  
• No separate expiry-warning system.  
• No generic debuff display.

TBD / MUST VALIDATE DURING IMPLEMENTATION  
• Final exact set and predetermined ordering of duration-based Mistweaver healing effects after testing the user's current talent build and Retail API behaviour.  
• Fixed visual colour assigned to each included effect.  
• Exact current Mistweaver dispel spell/action selected by the player's available toolkit.  
