# ⚔️ Blizz Nameplates+

**Blizz Nameplates+** enhances the original Blizzard nameplates for **Vanilla WoW / 1.12** while preserving their classic look.

It adds multi-target aura tracking, castbars, Crowd Control, Combo Points and useful visual options without replacing the original nameplate design.

**Current version:** `v1.0.7`
**Required:** `SuperWoW.dll` and `ClassicAPI.dll`

## ✨ Features

* GUID-based multi-target debuff and DoT tracking
* Numeric aura timers and stack counters
* Separate Crowd Control tracking with an optional dedicated row
* Optional supported CC effects from other players
* Enemy castbars with spell icons
* Blizzard-style Combo Points for Rogues and Druids
* Target Glow and Target Plate on Top
* Health text, class colors and Tank Mode
* Foreign-tagged mobs shown with a neutral grey healthbar
* Adjustable nameplate scale, Y offset, aura size and non-target alpha
* Instant target-alpha updates and clean nameplate/aura layering
* In-game settings through the **BN+ minimap button** or `/bnp`

## 🔎 New: Missing Spell / Aura Recorder

Missing a spell, DoT, proc or custom-server aura? The new recorder creates one complete, copyable diagnostic report—no screenshots or manual chat commands required.

1. Open the BNP settings and click **Missing Spell / Aura...**
2. Select the affected unit.
3. Click **Start Recording**.
4. Apply the aura, refresh it while active, then let it expire or remove it.
5. Click **Stop**, followed by **Copy Report**.
6. Paste the report into your bug report or support message.

The report includes the relevant Spell IDs, aura timing, target data and refresh events. The recorder is completely inactive until **Start Recording** is pressed and stops when the window is closed.

## 📦 Requirements

Both DLLs are required and must be loaded before the game starts.

### SuperWoW.dll

Provides the GUID, unit, combat and cast information used for multi-target tracking, castbars and nameplate identification.

[Download SuperWoW](https://github.com/balakethelock/SuperWoW)

### ClassicAPI.dll

Provides exact nameplate resolution and more reliable aura information, including Spell IDs, durations and expiration times. It is also used for instant target-alpha updates and the recorder’s direct **Copy Report** function.

[Download ClassicAPI](https://github.com/brues-code/ClassicAPI)

> Keep both DLLs up to date. Without them, Blizz Nameplates+ is not supported.

## 📥 Installation

1. Install `SuperWoW.dll` and `ClassicAPI.dll` using the instructions supplied with those projects.

2. Make sure both DLLs are enabled in your DLL loader or `dlls.txt`.

3. Delete any older `BlizzNameplatesPlus` addon folder.

4. Extract the new folder into `Interface\AddOns\`.

5. Verify the final path:

   `Interface\AddOns\BlizzNameplatesPlus\BlizzNameplatesPlus.toc`

6. Start the game through your DLL-enabled launcher and enable enemy nameplates.

## ⚙️ Main Settings

* **Nameplates:** Scale, Y Offset, Non-Target Alpha, Class Colors, Tank Mode and Health Text
* **Target:** Target Glow, glow color and Target Plate on Top
* **Auras:** Icon Size, Debuffs, Crowd Control, separate CC row and CCs from other players
* **Castbar:** Enable/disable and adjust height
* **Class Features:** Combo Points for Rogue and Druid

Changes are applied immediately.

## ❤️ Credits

Created by **Wurmschwanz**.
Thanks to everyone who tested the addon, reported bugs and supplied recorder data.
