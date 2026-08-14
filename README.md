# ⚔️ Blizz Nameplates+

**Blizz Nameplates+** enhances the original Blizzard nameplates for **Vanilla WoW / 1.12** while keeping their classic look and feel.

It adds modern quality-of-life features such as **multi-target debuff tracking, crowd control tracking, castbars, combo points, target highlighting, health information, class colors and Tank Mode** without replacing the original Blizzard nameplate design.

**Current Version:** `v1.0.6`  
**Required:** `SuperWoW`

---

# 🛠️ What's New in v1.0.6

## 🔴 Blizzard Combo Points

Added optional **Combo Points directly above enemy nameplates** for:

- Rogue
- Druid

The feature uses the original **Blizzard TargetFrame combo point artwork** instead of custom graphics.

Combo Points automatically follow your current target and are positioned so they do not overlap with debuffs or Crowd Control effects.

---

## 🧠 Improved Resist & Failed Cast Handling

Debuff tracking has received additional safeguards against false icons after unsuccessful casts.

BNP now keeps a short rollback state for recent aura applications and refreshes.

This helps correctly handle:

- **Resist**
- **Miss**
- **Immune**
- **Evade**
- Failed casts
- Failed debuff refreshes

If a refresh fails, BNP can restore the previously active timer instead of incorrectly replacing or removing it.

Additional protection was also added for effects that require strict live-aura confirmation, including many:

- Crowd Control effects
- Stuns
- Roots
- Traps
- Talent procs
- Poisons
- Secondary effects

Warlock curses continue to use stricter aura confirmation due to server-specific mechanics where multiple curse effects can succeed or resist independently.

---

## 🧊 Separate Crowd Control Tracking

Crowd Control can now be handled independently from normal debuffs.

The configuration menu contains separate options for:

- **Debuffs**
- **Crowd Control**

This allows players to disable normal DoTs/debuffs while keeping important Crowd Control effects visible, or vice versa.

---

## 📊 Separate CC Row

Crowd Control can optionally be displayed in its own row.

When enabled, the layout is:

**Crowd Control**  
**Debuffs / DoTs**  
**Combo Points** *(Rogue / Druid)*  
**Nameplate**

This keeps important CC effects visually separated from normal DoTs and debuffs.

The layout automatically accounts for Rogue and Druid Combo Points to prevent overlapping elements.

The separate row works in both **PvE and PvP**.

---

## 👥 Crowd Control from Other Players

BNP can optionally display supported Crowd Control effects applied by **other players**.

Unlike your own normal debuffs, foreign CCs are only displayed when the corresponding aura is actually present on the unit.

This is especially useful for quickly seeing effects such as:

- Fear
- Polymorph
- Stuns
- Roots
- Sap
- Blind
- Traps
- Silence
- Banish
- Similar supported Crowd Control effects

This option works on both player and NPC nameplates.

---

## 🎛️ Reorganized Configuration Menu

The configuration menu has been reorganized into clearer sections.

### Nameplates

- Nameplate Scale
- Class Colors
- Tank Mode
- Health Text
- Target Glow
- Target Glow Color
- Target Plate on Top

### Auras

- Aura Icon Size
- Debuffs
- Crowd Control
  - Display CCs in Separate Row
  - Show CCs from Other Players

### Castbar

- Castbars
- Castbar Height

### Class Features

- Combo Points *(Rogue / Druid only)*

Options that depend on another feature are visually grouped together to make the menu easier to understand.

---

# ✨ Features

## 🩸 Debuff Tracking

Track your own debuffs directly above enemy nameplates.

- GUID-based multi-target tracking
- Up to **8 active debuffs** per nameplate
- DoTs, curses, roots, traps, stuns and other supported effects
- Numeric countdown timers
- Compact minute timers for long effects
- Stack counters for genuinely stacking debuffs
- Debuffs stay attached to the correct enemy when switching targets
- Same-name enemies are tracked independently
- Early removal when supported effects are dispelled or broken
- Failed applications can be rolled back when detected
- Failed refreshes can restore the previously valid timer

BNP includes handling for unsuccessful attacks and casts such as:

**Miss • Dodge • Resist • Immune • Evade**

Additional live-aura confirmation is used for effects where cast information alone is not reliable enough.

---

## 🧊 Crowd Control

Crowd Control tracking can be enabled independently from normal debuffs.

Supported types include effects such as:

- Fear
- Stuns
- Roots
- Polymorph
- Sap
- Blind
- Silence
- Traps
- Banish
- Similar supported control effects

CCs can either share the normal aura row or be displayed in a dedicated row above your regular debuffs.

BNP can also optionally display supported **Crowd Control effects from other players**.

---

## 🔴 Combo Points

Rogues and Druids can optionally display their current target's Combo Points directly above the nameplate.

- Uses the original Blizzard TargetFrame Combo Point artwork
- Displays up to **5 Combo Points**
- Only appears on your current target
- Automatically updates when Combo Points change
- Automatically hides when switching targets
- Aura rows automatically account for the Combo Point area

The feature keeps the original Vanilla visual style instead of replacing the Combo Points with custom graphics.

---

## 🎯 Target Glow

Make your current target immediately recognizable with a clearly visible glow around the complete nameplate.

Choose between:

**White • Gold • Blue • Green • Red • Purple**

The glow is centered around the entire visible nameplate, including the level area.

---

## ❤️ Health Text

Optionally display health information directly inside the Blizzard healthbar.

Choose between:

**Off • Percent • HP • HP + Percent**

Examples:

- **Percent:** `73%`
- **HP:** `3.5k`
- **HP + Percent:** `3.5k | 73%`

Large health values are displayed in a compact format to keep the original nameplates readable.

---

## 🔮 Nameplate Castbars

See enemy casts directly underneath their nameplates.

- Normal casts fill from left to right
- Channels drain from right to left
- Active spell icon
- Smooth animation
- Compact full-width layout
- Adjustable castbar height
- Spell icon remains separated from the castbar itself

Only active castbars are animated every rendered frame.

---

## 🎨 Player Class Colors

Player nameplates can automatically use their corresponding **class color**.

Resolved class colors are protected from Blizzard temporarily overwriting them during combat or nameplate recycling.

NPC colors remain untouched unless another BNP feature intentionally changes them.

---

## 🛡️ Tank Mode

Optional **Tank Mode** provides additional visual information for hostile NPC nameplates.

Nameplate state is safely reset when Blizzard recycles frames, preventing old Tank Mode colors from appearing on unrelated enemies.

---

## ⚔️ Foreign Tagged Mobs

Immediately recognize mobs already tagged by players **outside your party or raid**.

Their healthbar is displayed in **neutral grey**.

Your own mobs and mobs tagged by your party or raid remain unchanged.

This feature works automatically and independently from Tank Mode.

---

## ⬆️ Target Plate on Top

Overlapping nameplates?

Enable **Target Plate on Top** to raise your current target above surrounding plates.

Debuffs, Crowd Control, castbars and health information remain clearly readable.

---

## 📏 Nameplate Scaling

Adjust the size of your Blizzard nameplates directly through BNP.

**Range:** `0.5 – 1.5`  
**Default:** `1.0`

---

# 🔍 Reliable Multi-Target Tracking

Vanilla nameplates can behave unpredictably when units disappear, die or move in and out of visibility.

BNP includes several safeguards for this:

- GUID-based aura tracking
- Same-name enemies remain separated
- Killing one mob does not remove debuffs from another mob with the same name
- Conservative DoT and curse removal
- Protection against temporary incomplete aura information
- GUID stability checks during nameplate recycling
- Protection against brief **ghost debuffs** when units move behind walls or out of line of sight
- Boss / NPC reset cleanup
- Failed-cast rollback protection
- Failed refresh restoration
- Strict live-aura confirmation for sensitive effects
- Separate handling for normal debuffs and Crowd Control

---

# 📦 Requirements

## ⚠️ SuperWoW is Required

**Blizz Nameplates+ requires SuperWoW.**

SuperWoW provides the additional GUID and unit information required for reliable:

- Multi-target debuff tracking
- Nameplate identification
- Castbars
- Aura confirmation
- Crowd Control tracking
- Nameplate state handling

Without SuperWoW, Blizz Nameplates+ is **not supported**.

---

# 📥 Installation

1. Download the latest **Blizz Nameplates+** release.
2. Delete any existing `BlizzNameplatesPlus` folder.
3. Extract the downloaded archive.
4. Copy the new folder into:

`Interface\AddOns\`

Your final installation should look like:

`Interface\AddOns\BlizzNameplatesPlus\BlizzNameplatesPlus.toc`

Start the game afterwards.

---

# ⚙️ Configuration

Open the configuration menu using the **BN+ minimap button** or type:

`/bnp`

## Nameplates

- **Nameplate Scale**
- **Class Colors**
- **Tank Mode**
- **Health Text**
- **Target Glow**
- **Target Glow Color**
- **Target Plate on Top**

## Auras

- **Aura Icon Size**
- **Debuffs**
- **Crowd Control**
- **Display CCs in Separate Row**
- **Show CCs from Other Players**

## Castbar

- **Castbars**
- **Castbar Height**

## Class Features

- **Combo Points** *(Rogue / Druid)*

Both **Health Text** and **Target Glow Color** use compact dropdown menus.

Dependent options are grouped together to make their purpose easier to understand.

Changes are applied immediately.

---

# 🔎 Missing Spell & Aura Reporting

Playing on a server with custom spells or noticed that BNP is missing a debuff?

BNP includes diagnostic tools to make missing effects easy to identify.

## 🧪 Unknown Spell Collector

Use:

`/bnp unknown`

BNP will display collected unknown negative aura/effect information.

A **screenshot of the output** is usually enough to report the missing spell.

For additional information when requested by the developer:

`/bnp unknown verbose`

To clear the collected information:

`/bnp unknown reset`

---

## 🔬 Target Aura Scan

If a missing debuff is **currently active on your target**, use:

`/bnp auras`

BNP will scan the target's currently active negative auras and display:

- **Spell ID**
- **Aura name**
- **Stack count**
- **Debuff type**

For best results, use `/bnp auras` **while the missing debuff is still active** and send a screenshot of the chat output.

This is especially useful for **talent procs, custom server abilities and effects that are not detected by the normal unknown spell collector**.

---

# ⚡ Performance

Blizz Nameplates+ is designed to keep permanent background work low.

- Aura confirmation work runs only when required
- No additional permanent scan for Target Glow
- Foreign-tag detection uses existing nameplate information
- Only active castbars animate every rendered frame
- Cast discovery is throttled
- Timer text updates only when the displayed value changes
- GUID stability protection does not add additional aura scans
- Foreign Crowd Control uses throttled live-aura checks
- Foreign CC tracking is kept separate from your own DoT tracking
- Disabled display categories do not create additional visual work

The goal is to provide additional nameplate information while keeping the addon suitable for **raids, battlegrounds and other situations with many visible units**.

---

# 📜 Previous Update – v1.0.4

## 🌑 Shadow Vulnerability

Added support for the Warlock talent proc **Shadow Vulnerability**.

- Correct **10-second duration**
- Detects the actual Shadow Vulnerability aura
- Supports refreshes when the effect procs again while already active

---

## ❤️ Health Text

Expanded the original Health % feature with multiple display modes:

**Off • Percent • HP • HP + Percent**

Large health values are automatically displayed in a compact format.

---

## 🎛️ Cleaner Configuration

Improved the configuration menu with compact dropdown selectors for:

- **Health Text**
- **Target Glow Color**

---

## 🔬 Target Aura Scanner

Added the diagnostic command:

`/bnp auras`

It displays all currently detected negative auras on your target together with their **Spell ID, name, stack count and debuff type**.

This makes identifying missing custom spells and talent procs significantly easier.

---

# ❤️ Special Thanks

A huge thank you to **everyone who helped test Blizz Nameplates+**, reported bugs, shared feedback and helped improve the addon!

Your testing has been incredibly helpful in making BNP more reliable and polished. ❤️

---

# 👤 Author

**Wurmschwanz**
