# ⚔️ Blizz Nameplates+

**Blizz Nameplates+** enhances the original Blizzard nameplates for **Vanilla WoW / 1.12** while keeping their classic look and feel.

It adds modern quality-of-life features such as **multi-target debuff tracking, castbars, target highlighting, health information, class colors and Tank Mode** without replacing the original Blizzard nameplate design.

**Current Version:** `v1.0.5`  
**Required:** `SuperWoW`

---

# ✨ Features

## 🩸 Debuff Tracking

Track your own debuffs directly above enemy nameplates.

- GUID-based multi-target tracking
- Up to **8 active debuffs** per nameplate
- DoTs, curses, CC, roots, traps, stuns and other supported effects
- Numeric countdown timers
- Compact minute timers for long effects
- Stack counters for genuinely stacking debuffs
- Debuffs stay attached to the correct enemy when switching targets
- Same-name enemies are tracked independently
- Early removal when supported effects are dispelled or broken

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

- GUID-based aura tracking
- Same-name enemies remain separated
- Killing one mob does not remove debuffs from another mob with the same name
- Conservative DoT and curse removal
- Protection against temporary incomplete aura information
- GUID stability checks during nameplate recycling
- Protection against brief **ghost debuffs** when units move behind walls or out of line of sight

---

# 📦 Requirements

## ⚠️ SuperWoW is Required

**Blizz Nameplates+ requires SuperWoW.**

SuperWoW provides the additional GUID and unit information required for reliable:

- Multi-target debuff tracking
- Nameplate identification
- Castbars
- Aura confirmation
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

## Available Options

- **Nameplate Scale**
- **Debuff Icon Size**
- **Class Colors**
- **Castbars**
- **Castbar Height**
- **Tank Mode**
- **Health Text**
- **Target Glow**
- **Target Glow Color**
- **Target Plate on Top**

Both **Health Text** and **Target Glow Color** use compact dropdown menus.

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

The goal is to provide additional nameplate information while keeping the addon suitable for **raids, battlegrounds and other situations with many visible units**.

---

# 🚀 What's New in v1.0.4

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

This keeps the configuration panel smaller and easier to navigate.

---

## 🔬 Target Aura Scanner

Added the new diagnostic command:

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
