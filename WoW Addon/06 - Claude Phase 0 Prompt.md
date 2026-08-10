PHASE 0 — FEASIBILITY AND API REVIEW

Read the five project specification documents in this folder before doing anything else:

1\. 01 \- Product Vision  
2\. 02 \- Unit Frame Design  
3\. 03 \- Interaction and Bindings  
4\. 04 \- Mistweaver Requirements  
5\. 05 \- Roadmap

Treat those documents as authoritative. Do not redesign the addon, add conventional unit-frame features, invent requirements, or start coding yet.

Your first task is ONLY to investigate whether the documented design is feasible against the current 2026 World of Warcraft Retail addon API.

Pay particular attention to:  
\- custom secure 5-player party frames and fixed role ordering;  
\- health, role, aggro, dispel, range and dead-state detection;  
\- tracking only the player’s own duration-based Mistweaver healing effects and obtaining accurate remaining durations in combat;  
\- click casting on custom frames without changing target;  
\- arbitrary mouse-button capture, including Logitech G502 side buttons;  
\- optional Shift/Ctrl bindings and preserving normal Blizzard interactions via modifiers;  
\- combat-lockdown restrictions and what must be configured out of combat;  
\- automatic discovery of currently available Mistweaver healing spells;  
\- hiding Blizzard party frames;  
\- simulated test-mode frames.

Verify the CURRENT Retail Mistweaver toolkit rather than relying on historical knowledge. Identify which player-cast healing effects with meaningful durations should appear in the vertical HoT display, and verify the current Mistweaver dispel ability and dispel types.

For each relevant duration-based healing effect, determine where possible:  
\- current spell name and spell ID;  
\- whether it can exist on another party member;  
\- whether it has a duration;  
\- whether the aura can be confirmed as originating from the player;  
\- whether remaining duration is exposed to addons during combat;  
\- whether talents can alter, refresh or extend that duration and whether the API reflects that change.

Also determine the supported current Retail method for secure click casting. Do not propose an insecure workaround if Blizzard provides an official secure mechanism.

OUTPUT

Create a new document named PHASE\_0\_FEASIBILITY.

For each major feature classify it as one of:  
SUPPORTED  
SUPPORTED WITH RESTRICTIONS  
UNCERTAIN / NEEDS IN-GAME TEST  
NOT POSSIBLE UNDER CURRENT API

For restrictions or blockers explain in plain English:  
1\. What the specification wants.  
2\. What Blizzard permits.  
3\. What effect that has on the addon.  
4\. The closest option that preserves the original intent.

Finish with:  
\- overall feasibility;  
\- blockers;  
\- anything requiring an in-game proof of concept;  
\- specification decisions that need user input;  
\- recommended scope for the smallest playable prototype.

Do not implement the addon yet. Do not modify the product specification silently. Flag genuine API conflicts for discussion.  
