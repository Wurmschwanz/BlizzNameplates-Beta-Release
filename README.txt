Blizz Nameplates+ 0.3.4 - Visual Update

Requires the original ShaguTweaks addon.

This test version:
- detects Blizzard nameplates through ShaguTweaks.libnameplate
- uses ShaguTweaks.libdebuff timer data
- displays only Corruption/Verderbnis for the first prototype
- shows an icon and numeric countdown above the matching nameplate

Test:
1. Delete the old BlizzNameplatesPlus folder.
2. Install this version and /reload.
3. Show enemy nameplates with V.
4. Cast Corruption/Verderbnis on a visible target.
5. The icon should remain above that nameplate after changing target.

Commands:
/bnp status
/bnp debug on
/bnp debug off

Visual changes in 0.3.4:
- icon moved higher so the name remains readable
- bright Blizzard debuff border removed
- subtle one-pixel black border
- classic white whole-second timer
- no tracking or renderer changes

Visual change in v0.3.4: removed the black one-pixel icon border.


v0.3.6: First stable multi-aura step: Corruption, Curse of Agony and Siphon Life.


v0.3.10 Timer Polish:
- 18px icons retained
- timer reduced to 8px
- centered timer with thin black outline
- removed drop shadow

v0.3.11 GUID Probe
------------------
This diagnostic build keeps the stable name+level aura display unchanged.
Use /bnp guid while targeting a visible enemy to inspect SuperWoW's GUID
returned by UnitExists() and each nameplate's plate:GetName(1) unit token.


v0.3.12 GUID Render Alpha
--------------------------
Uses SuperWoW's second UnitExists return value for target and nameplate GUIDs.
Real target debuffs are synchronized into a GUID cache and rendered only on the
nameplate with the matching GUID. Visual settings are unchanged from v0.3.10.

v0.3.13
- Active debuffs now pack together without empty slots.
- Icons follow the order in which debuffs were applied to each GUID.
- The active icon row remains centered above the nameplate.


v0.3.14
- Only the local player's successful SuperWoW cast events create aura entries.
- Target scans no longer import debuffs from other players.


0.3.15 Warlock
- Expanded own-cast tracking to standard Vanilla Warlock DoTs, curses, control and channel debuffs.
- Rank-specific durations for Corruption, Fear, Howl of Terror and Banish.
- Maximum of five visible icons per nameplate to preserve performance and readability.
- Dark Harvest and proc-created debuffs remain a separate follow-up.

v0.3.17 SpellDB Shadow Mode
- The proven v0.3.15 tracking and renderer remain unchanged.
- /bnp spelldb prints how successful own casts would resolve in the future registry.
- /bnp spelldb reset clears the audit counters.
- The shadow registry never creates, removes, filters, or renders an aura.


v0.3.17 Shadow audit:
- Added classic rank SpellIDs for all supported Warlock auras.
- Ignores Shadow Trance and LOGINEFFECT in audit statistics.
- Tracking and rendering remain unchanged.


v0.3.19
- Replaces the previously tracked own Warlock curse when a new curse is cast on the same GUID.
- Other DoTs and control effects are unaffected.


0.3.19
- Curse of Agony is excluded from regular curse replacement on Turtle WoW.
- CoA can remain active together with one of CoE/CoR/CoS/etc.


0.3.20 Smart Timer
- Long aura durations use compact labels: 5m, 4m, 3m, 2m, 1m.
- Below 60 seconds the classic numeric countdown is shown.
- Timer text updates only when the displayed value changes.


v0.4.0 alpha: class debuff lists curated from ShaguPlates debuff data; Shagu by Shagu credited as reference source.


Beta Unknown Spell Collector
----------------------------
The beta silently records unknown own cast/effect IDs while playing.

Use:
  /bnp unknown
to print the collected list. A screenshot of that output is enough to report
missing Turtle/custom effects.

Use:
  /bnp unknown reset
to clear the list.

AURA entries are strongest: an unknown negative aura appeared shortly after
your own cast on the same GUID. CAST entries help identify separate trap/proc
effect IDs that may not yet exist in the class database.


Filtered Beta Collector
-----------------------
/bnp unknown
  Shows only unknown negative AURA IDs and useful indirect effect lines.

/bnp unknown verbose
  Also shows raw unknown own CAST IDs for developer troubleshooting.

/bnp unknown reset
  Clears the collector.


v0.5.0 Beta
------------
- All in-game diagnostic/help text is English.
- Unknown-aura collector scan interval reduced from 0.20s to 0.35s to lower overhead.
- Normal aura rendering remains at its existing update rate.
- Use /bnp unknown to report missing Turtle/custom debuffs.
- Use /bnp unknown verbose only when additional developer diagnostics are requested.


v0.5.1 Beta Performance Pass
----------------------------
- Unknown-aura collector only scans for 8 seconds after the player's own CAST/CHANNEL event.
- Hit-confirmation GUID/UnitDebuff work only runs while pending auras exist.
- Aura renderer, timers, Dark Harvest, UI and spell behavior are unchanged.


v0.5.2 ShaguPlates Class Audit
------------------------------
All class aura lists were re-audited against ShaguPlates enUS debuff tables.
Added missing direct debuffs, CC, talent procs and effect names across all 9 classes.

Turtle-specific ShaguPlates overrides mirrored as fallbacks:
- Druid Moonfire: 18s
- Druid Insect Swarm: 18s
- Paladin Hand of Reckoning: 3s

Known indirect/proc effects are intentionally present by NAME even where their
SuperWoW effect SpellID is not yet known. The beta collector remains enabled to
discover those concrete IDs during play.


v0.5.3 Live Aura Removal
------------------------
- Already-confirmed own auras are re-checked against UnitDebuff every 0.10s.
- If a tracked aura disappears early (break, dispel, trinket, damage break, etc.),
  its nameplate icon is removed immediately instead of waiting for the timer.
- The scan never imports foreign auras; it can only remove auras already created
  by the player's own confirmed cast/effect.
- 0.35s grace period prevents transient aura-list updates from deleting fresh effects.


v0.6.0 Standalone / Class Colors
--------------------------------
- ShaguTweaks is no longer required.
- SuperWoW remains required.
- Embedded lightweight Vanilla Blizzard-nameplate discovery based on the
  original Blizzard plate signature used by Shagu's projects.
- Player nameplates use class colors by default.
- NPC nameplate colors are left untouched.
- /bnp classcolors on
- /bnp classcolors off


v0.6.1 Nameplate Scale
----------------------
Standalone nameplate scaling added.

Commands:
  /bnp scale
  /bnp scale 0.9
  /bnp scale 1.1
  /bnp scale reset

Allowed range: 0.5 to 1.5
Default: 1.0

The setting is saved per account via BNP_DB and is applied to newly created
or reused Blizzard nameplates automatically.


v0.6.2 Shagu UI Scale Behavior
------------------------------
Nameplate scaling now matches ShaguTweaks by default:
  effective scale = UIParent:GetScale() * BNP multiplier

The BNP multiplier defaults to 1.0, so the default visual behavior follows
the current UI Scale exactly. /bnp scale remains available as an optional
extra multiplier.


v0.6.3 Shagu Scale Fix
----------------------
Fixed nameplates appearing near the ground.

The previous build incorrectly scaled the original Blizzard nameplate frame.
This build follows ShaguTweaks' actual method:
- keep the original world-positioned plate unscaled
- create a child visual wrapper
- reparent Blizzard healthbar/regions to that wrapper
- scale the wrapper using UIParent scale * BNP multiplier
- resize the original frame bounds accordingly


v0.6.4 Instant Class Colors
---------------------------
- Class colors are now applied immediately during nameplate initialization/show.
- Removed the normal 0.15s delay that could briefly show Blizzard hostile red.
- A 0.05s fallback only checks visible plates that have not received a class
  color yet, covering late SuperWoW unit-token resolution.
- Once colored, a plate is removed from the fallback work until Blizzard reuses it.


v0.7.0 Standalone Castbars
--------------------------
- Added standalone SuperWoW GUID-based nameplate castbars.
- Enabled by default.
- Casts fill left-to-right; channels drain right-to-left.
- Castbars are attached below the original Blizzard healthbar and inherit
  BNP/Shagu-style nameplate scaling.
- /bnp castbars on
- /bnp castbars off


v0.7.1 Castbar SuperWoW Poll Fix
--------------------------------
Castbars now follow the actual ShaguTweaks/SuperWoW method:
- query UnitCastingInfo(nameplate SuperWoW token)
- fallback to UnitChannelInfo(nameplate SuperWoW token)
- use the returned start/end timestamps directly
- no dependency on UNIT_CASTEVENT for visual castbar creation


v0.7.2 Castbar START Fix
------------------------
Standalone castbars now mirror ShaguTweaks' actual SuperWoW event handling:
- START: begin normal castbar
- CAST: handle cast events with a non-zero timer
- CHANNEL: begin reverse/draining channel bar
- FAIL: immediately remove cast state

This fixes normal duel casts not appearing because v0.7.0 ignored START.


v0.7.3 Castbar Spell Icon
-------------------------
- Added the active spell icon to the left of the nameplate castbar.
- Icon texture comes directly from the SuperWoW SpellID via SpellInfo.
- Added a classic Blizzard quickslot border.
- Icon follows the nameplate/castbar alpha and hides immediately with the castbar.


v0.7.4 Class Color Lock
-----------------------
- Fixed hostile player plates reverting to Blizzard red when combat/threat state changes.
- Once a player class is resolved, its RGB is cached on that nameplate.
- Every 0.05s BNP compares the current healthbar color and restores the cached class
  color only if Blizzard changed it.
- UnitClass is not repeatedly queried for already-resolved plates.


v0.8.3 Standalone Merge
-----------------------
Merged the configuration/features from the ShaguTweaks v0.8.2 branch into
the standalone build while keeping it fully independent from ShaguTweaks.

New standalone menu:
- Nameplate Scale
- Debuff Icon Size
- Class Colors
- Castbars
- Tank Mode

Open via:
- Minimap button
- /bnp
- /bnp config

All settings apply immediately.


v0.8.4 Standalone Bridge Nil Fix
--------------------------------
- Ported the callback/bridge nil-safety from the ShaguTweaks v0.8.3 fix.
- Nameplate callbacks now safely resolve `plate or this`.
- Init/Show/Update callbacks ignore invalid/nil frames instead of propagating them.
- Standalone nameplate discovery remains independent from ShaguTweaks.


v0.8.5 Standalone Castbar Height
--------------------------------
Added a Castbar Height slider to the in-game options.

Range:
- 4 px minimum
- 14 px maximum
- 6 px default

Changes apply immediately to existing nameplate castbars.
The spell icon size remains unchanged.


v0.8.6 Standalone Tank Color Lock
---------------------------------
- Fixed Tank Mode briefly flashing Blizzard red whenever the unit takes damage.
- Current Tank Mode RGB is cached on the plate.
- Healthbar OnValueChanged immediately reapplies the active Tank Mode color.
- A lightweight OnUpdate fallback also restores the color if another Blizzard
  update changes it outside the health-value event.


v0.8.7 Smooth Castbar
---------------------
- Castbar visual progress now updates every rendered frame instead of every 0.02 s.
- Cast/GUID detection remains unchanged.
- This only removes the visible stepping from the bar animation.


v1.0.0
------
First stable standalone release.
Author/Publisher: Wurmschwanz


v1.0.2 - Robust ShaguTweaks Compatibility
-----------------------------------------
Fixed compatibility failing depending on addon load order.

BNP now:
- patches already registered ShaguTweaks nameplate modules
- hooks ShaguTweaks.register() so later registrations are also intercepted
- uses OptionalDeps: ShaguTweaks for deterministic ordering when available
- never changes ShaguTweaks saved settings

Expected login message with ShaguTweaks enabled:
  ShaguTweaks compatibility active (3/3 nameplate modules suppressed).


v1.0.3 - Nameplate Color Fix
----------------------------
- Fixed recycled nameplates keeping an old player class color.
- BNP now applies class colors only to actual player GUIDs.
- NPC and neutral unit colors remain fully controlled by Blizzard.
- Castbar logic is unchanged.


Blizz Nameplates+ v1.0.0
------------------------
Stable unified release.
Compatible with ShaguTweaks.
Author: Wurmschwanz
