# ⚔️ Blizz Nameplates+

**Blizz Nameplates+** enhances the original Blizzard nameplates for **Vanilla WoW / 1.12** while keeping the classic Blizzard look.

It adds **multi-target debuffs, Crowd Control tracking, castbars, Combo Points, Target Glow, health text, class colors, Tank Mode and more** without replacing the original nameplate design.

**Current Version:** `v1.0.7`  
**Required:** `SuperWoW`

---

# 🛠️ What's New in v1.0.7

- **Nameplate Y Offset** — move nameplates up by up to `+50 px`
- **Non-Target Alpha** — dim non-target nameplates from `30–100%`
- **Improved Target Glow layering** so the glow stays visible without dominating the healthbar
- **Improved Warlock curse synchronization**
  - only actually active curses remain visible
  - supports mechanics where multiple curses can coexist
  - resisted or failed curse casts keep the previous valid curse state
- **Foreign-tag flicker fixed**
  - mobs tagged by other players now stay consistently grey
  - Tank Mode no longer overwrites the foreign-tag color
- **Blizzard UI layering fixed**
  - nameplates no longer draw over UI elements such as the minimap
  - Target Plate on Top now works without changing the nameplate FrameStrata

v1.0.7 also includes the previous v1.0.6 additions: **Blizzard-style Combo Points, separate Crowd Control handling, optional CC row, CCs from other players and improved failed-cast/resist rollback.**

---

# ✨ Features

## 🩸 Debuffs & Crowd Control

Track supported debuffs directly above enemy nameplates.

- GUID-based multi-target tracking
- Up to **8 active effects** per nameplate
- Numeric timers and stack counters
- Same-name enemies tracked independently
- Separate **Debuffs** and **Crowd Control** options
- Optional dedicated CC row
- Optional supported CC effects from other players
- Protection against false icons after **Resist, Miss, Immune, Evade** and failed refreshes
- Strict live-aura confirmation for sensitive effects such as CCs, traps, poisons and special procs

Optional layout:

**Crowd Control**  
**Debuffs / DoTs**  
**Combo Points** *(Rogue / Druid)*  
**Nameplate**

---

## 🔴 Blizzard Combo Points

Optional Combo Points for **Rogue** and **Druid**.

- Uses the original Blizzard TargetFrame artwork
- Up to **5 Combo Points**
- Only shown on your current target
- Automatically updates and hides when switching targets

---

## 🎯 Target Glow

Highlights your current target while keeping the original nameplate readable.

Available colors:

**White • Gold • Blue • Green • Red • Purple**

The glow is drawn behind the main nameplate visuals.

---

## ❤️ Health Text

Display health information inside the Blizzard healthbar.

Modes:

**Off • Percent • HP • HP + Percent**

Example:

`3.5k | 73%`

---

## 🔮 Castbars

Enemy casts are shown directly below the nameplate.

- Casts and channels
- Spell icon
- Smooth animation
- Adjustable castbar height
- Only active castbars animate every frame

---

## 🎨 Class Colors

Player nameplates can use their class color.

NPC colors remain unchanged unless another BNP feature intentionally modifies them.

---

## 🛡️ Tank Mode

Optional Tank Mode provides aggro-related color feedback on hostile NPC nameplates.

Foreign-tagged mobs always keep their neutral grey color and are no longer overwritten by Tank Mode.

---

## ⚔️ Foreign Tagged Mobs

Mobs tagged by players outside your party or raid are shown with a **neutral grey healthbar**.

Your own mobs and party/raid tags remain unchanged.

---

## ⬆️ Target Plate on Top

Raises your current target above overlapping nameplates without moving nameplates into Blizzard UI layers.

---

## 📏 Nameplate Controls

- **Nameplate Scale:** `0.5 – 1.5`
- **Nameplate Y Offset:** `0 – +50 px`
- **Non-Target Alpha:** `30 – 100%`

---

# 📦 Requirements

## ⚠️ SuperWoW is Required

Blizz Nameplates+ requires **SuperWoW** for reliable GUID and unit information used by:

- Multi-target tracking
- Aura confirmation
- Castbars
- Crowd Control
- Nameplate identification

Without SuperWoW, BNP is **not supported**.

---

# 📥 Installation

1. Download the latest release.
2. Delete any old `BlizzNameplatesPlus` folder.
3. Extract the archive into:

`Interface\AddOns\`

Final path:

`Interface\AddOns\BlizzNameplatesPlus\BlizzNameplatesPlus.toc`

---

# ⚙️ Configuration

Open the menu with the **BN+ minimap button** or:

`/bnp`

### Nameplates

- **Nameplate Scale**
- **Nameplate Y Offset**
- **Non-Target Alpha**
- **Class Colors**
- **Tank Mode**
- **Health Text**
- **Target Glow**
- **Target Glow Color**
- **Target Plate on Top**

### Auras

- **Aura Icon Size**
- **Debuffs**
- **Crowd Control**
- **Display CCs in Separate Row**
- **Show CCs from Other Players**

### Castbar

- **Castbars**
- **Castbar Height**

### Class Features

- **Combo Points** *(Rogue / Druid)*

Changes are applied immediately.

---

# 🔎 Debug Commands

Missing a custom spell or aura?

### Unknown effects

`/bnp unknown`

More details:

`/bnp unknown verbose`

Reset collected data:

`/bnp unknown reset`

### Scan current target auras

`/bnp auras`

Displays detected negative auras with:

- **Spell ID**
- **Name**
- **Stacks**
- **Debuff type**

A screenshot of the chat output is usually enough for a bug report.

---

# ⚡ Performance

Blizz Nameplates+ is designed to keep background work low.

- Aura confirmation only when needed
- Cast discovery is throttled
- Only active castbars animate every frame
- Timer text only updates when the displayed value changes
- Foreign CC checks are throttled
- Y Offset and Non-Target Alpha reuse existing nameplate update logic
- Disabled display categories do not create unnecessary visual work

Designed for **raids, battlegrounds and situations with many visible units**.

---

# ❤️ Special Thanks

Thanks to everyone who tested Blizz Nameplates+, reported bugs and shared feedback. ❤️

---

# 👤 Author

**Wurmschwanz**
