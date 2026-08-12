# ⚔️ Blizz Nameplates+

**Blizz Nameplates+** enhances the original Blizzard nameplates for **Vanilla WoW / 1.12** while keeping their classic look and feel.

It adds modern quality-of-life features such as **multi-target debuff tracking, castbars, target highlighting, health percentages, class colors and Tank Mode** without replacing the original Blizzard nameplate design.

**Current Version:** `v1.0.3`
**Required:** `SuperWoW`

---

# ✨ Features

## 🩸 Debuff Tracking

Track your own debuffs directly above enemy nameplates.

* GUID-based multi-target tracking
* Up to **8 active debuffs** per nameplate
* DoTs, curses, CC, roots, traps, stuns and other supported effects
* Numeric countdown timers
* Compact minute timers for long effects
* Stack counters for genuinely stacking debuffs
* Debuffs stay attached to the correct enemy when switching targets
* Same-name enemies are tracked independently
* Early removal when supported effects are dispelled or broken

Failed attacks are handled correctly:

**Miss • Dodge • Resist • Immune • Evade**

They will **not** create false debuff timers.

---

## 🎯 Target Glow

Make your current target immediately recognizable with a clearly visible glow around the complete nameplate.

Choose between:

**White • Gold • Blue • Green • Red • Purple**

The glow is centered around the entire visible nameplate, including the level area.

---

## ❤️ Health Percentage

Optionally display the enemy's current **Health %** directly inside the Blizzard healthbar.

Designed to remain simple and readable while preserving the original nameplate style.

---

## 🔮 Nameplate Castbars

See enemy casts directly underneath their nameplates.

* Normal casts fill from left to right
* Channels drain from right to left
* Active spell icon
* Smooth animation
* Compact full-width layout
* Adjustable castbar height

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

Debuffs, castbars and health information remain clearly readable.

---

## 🏹 Shared Hunter's Mark

**Hunter's Mark** is supported as a special shared debuff.

A Hunter's Mark applied by another Hunter can also be displayed on the nameplate.

Other debuffs continue to follow the normal tracking rules.

---

## 📏 Nameplate Scaling

Adjust the size of your Blizzard nameplates directly through BNP.

**Range:** `0.5 – 1.5`
**Default:** `1.0`

---

# 🔍 Reliable Multi-Target Tracking

Vanilla nameplates can behave unpredictably when units disappear, die or move in and out of visibility.

BNP includes several safeguards for this:

* GUID-based aura tracking
* Same-name enemies remain separated
* Killing one mob does not remove debuffs from another mob with the same name
* Conservative DoT and curse removal
* Protection against temporary incomplete aura information
* GUID stability checks during nameplate recycling
* Protection against brief **ghost debuffs** when units move behind walls or out of line of sight

---

# 📦 Requirements

## ⚠️ SuperWoW is Required

**Blizz Nameplates+ requires SuperWoW.**

SuperWoW provides the additional GUID and unit information required for reliable:

* Multi-target debuff tracking
* Nameplate identification
* Castbars
* Aura confirmation
* Nameplate state handling

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

## Available Options

* **Nameplate Scale**
* **Debuff Icon Size**
* **Class Colors**
* **Castbars**
* **Castbar Height**
* **Tank Mode**
* **Health %**
* **Target Glow**
* **Target Glow Color**
* **Target Plate on Top**

Changes are applied immediately.

---

# 🔎 Missing Spell Reporting

Playing on a server with custom spells or noticed that BNP is missing a debuff?

Use:

`/bnp unknown`

BNP will display collected unknown negative aura/effect information.

A **screenshot of the output** is usually enough to report the missing spell.

For additional information when requested by the developer:

`/bnp unknown verbose`

To clear the collected information:

`/bnp unknown reset`

---

# ⚡ Performance

Blizz Nameplates+ is designed to keep permanent background work low.

* Aura confirmation work runs only when required
* No additional permanent scan for Target Glow
* Foreign-tag detection uses existing nameplate information
* Only active castbars animate every rendered frame
* Cast discovery is throttled
* Timer text updates only when the displayed value changes
* GUID stability protection does not add additional aura scans

The goal is to provide additional nameplate information while keeping the addon suitable for **raids, battlegrounds and other situations with many visible units**.

---

# 🚀 What's New in v1.0.3

### 🎯 Target Glow

Added a configurable target highlight with **six color presets**.

### ⚔️ Foreign Tagged Mobs

Mobs tagged outside your party or raid now use a **grey healthbar**.

### 🏹 Shared Hunter's Mark

Hunter's Mark from other Hunters can now be displayed.

### 🛡️ Debuff Stacks

Added stack counters for genuinely stacking debuffs.

### 🩸 Improved Debuff Reliability

Improved handling of **Miss, Dodge, Resist, Immune and Evade**.

### 💀 Same-Name Death Fix

Killing one mob no longer removes tracked debuffs from surviving mobs with the same name.

### 🔍 GUID Stability

Added protection against brief **ghost debuffs** caused by nameplate recycling and line-of-sight changes.

### ❤️ Health %

Added optional health percentage text inside the healthbar.

### ⬆️ Target Plate on Top

Your current target can optionally be raised above overlapping nameplates.

### 🔮 Castbar Improvements

Improved castbar layout and performance.

---

# ❤️ Special Thanks

A huge thank you to **everyone who helped test Blizz Nameplates+**, reported bugs, shared feedback and helped improve the addon!

Your testing has been incredibly helpful in making BNP more reliable and polished. ❤️

---

# 👤 Author

**Wurmschwanz**
