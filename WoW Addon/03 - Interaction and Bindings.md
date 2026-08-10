INTERACTION AND BINDINGS  
Status: V1 interaction specification

1\. Primary Interaction  
The entire party unit frame acts as the click-casting target.

Click-cast healing should apply to the unit represented by the hovered/clicked frame without requiring the player's current target to change.

2\. Binding Philosophy  
The user has a multi-button Logitech G502 Lightspeed mouse. The design therefore prioritizes direct physical mouse-button bindings rather than modifier-heavy combinations.

Routine healing should be possible without Shift/Ctrl modifiers if enough physical buttons are available.

Shift and Ctrl support remains available as reserve capacity.

Mouse-wheel up/down bindings are not required for V1.

3\. Clique-Style Binding Capture  
The configuration screen must not require the user to understand technical mouse-button names.

Desired flow:  
1\. Choose a currently available Mistweaver healing spell/action.  
2\. Enter binding-capture mode.  
3\. Physically press the desired mouse button.  
4\. The addon records the button WoW reports.  
5\. Save/display the resulting binding.

The same capture mechanism should support Shift or Ctrl combinations if the user chooses to use them.

4\. Available Spell List  
The binding configuration should automatically present the user's currently available Mistweaver healing spells.

Do not require manual spell-name entry.

The available list should reflect the player's actual current abilities/talents rather than assuming a static build where the WoW API permits this reliably.

5\. Dispel  
There is one dedicated dispel binding.

The frame's pink outline communicates that this action is currently relevant; the user does not need to know the identity of the dispellable debuff.

6\. Blizzard Frame Interaction  
Primary unmodified mouse buttons may be used for healing.

Normal Blizzard-style unit-frame interactions should remain accessible through modifiers. The exact modifier mapping is configurable/implementation-defined but must not interfere with the primary click-casting goal.

7\. Configuration Access  
Configuration must be accessible through:  
• A slash command (exact addon command TBD until the addon is named).  
• WoW's AddOns settings interface.

8\. Frame Configuration  
Required frame controls:  
• Small / Medium / Large scale preset.  
• Unlock Frames.  
• Lock Frames.  
• Toggle automatic hiding of Blizzard party frames.

The whole five-player block is positioned together.

9\. Test Mode  
Test mode displays five simulated party frames without requiring a real party.

The simulated frames should demonstrate representative states such as:  
• Different health levels.  
• Different active duration-based healing effects and remaining durations.  
• Aggro outline.  
• Dispel outline.  
• Out-of-range/dim state where useful.

Binding testing in Test Mode must NOT cast spells.

When the user clicks a fake frame, the test UI reports which binding would have fired, for example conceptually: “Mouse Button X → Spell Y”.

10\. Persistence  
Settings and bindings are shared across characters by default.

Per-character profiles are not a V1 requirement.

11\. Secure UI Constraint  
Actual click casting must be implemented using WoW-supported secure mechanisms. Combat-lockdown restrictions are an implementation constraint and must not be bypassed or worked around in unsupported ways.

If a requested binding/configuration behaviour cannot legally change during combat, the UI should communicate that limitation cleanly and apply changes when permitted.

TBD  
• Final wording/layout of configuration screens.  
• Exact modifier used for retained Blizzard interactions.  
• Exact secure implementation after current Retail API validation.  
