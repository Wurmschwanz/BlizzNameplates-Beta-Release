# Blizz Nameplates+

**Blizz Nameplates+** is a lightweight enhancement for the original Blizzard nameplates in **Vanilla WoW / 1.12**.

The goal is simple: **keep the classic Blizzard look while adding useful modern nameplate features** without turning the UI into a completely different nameplate system.

> **Current Version:** v1.0.3
> **Requires:** SuperWoW

---

## ✨ Features

### 🩸 Debuff Tracking

* Displays your own debuffs directly above enemy nameplates.
* GUID-based multi-target tracking.
* Debuffs remain attached to the correct enemy when switching targets.
* Supports DoTs, curses, crowd control, roots, traps, stuns and other supported effects.
* Displays up to **8 active tracked effects** per nameplate.
* Icons automatically pack together in application order.
* Numeric countdown timers directly on the icons.
* Long durations use compact labels such as `5m`, `4m`, `3m`, `2m` and `1m`.
* Stack counters for genuinely stacking debuffs.
* Miss, Dodge, Resist, Immune and Evade do not create false debuff timers.
* Early removal support for dispels, broken CC and effects that end before their normal duration.
* Same-name enemies are tracked independently.
* Additional GUID safeguards prevent temporary nameplate recycling from displaying debuffs on the wrong enemy.

---

### 🎯 Target Glow

The current target can be highlighted with a clearly visible glow around the entire nameplate.

Available colors:

* White
* Gold
* Blue
* Green
* Red
* Purple

The glow is centered around the complete visible nameplate, including the level area.

---

### ❤️ Health Percentage

Optionally displays the enemy's current health percentage directly inside the healthbar.

Designed to preserve the original Blizzard nameplate appearance.

---

### 🔮 Castbars

Adds standalone castbars directly to enemy nameplates.

* Normal casts fill from left to right.
* Channels drain from right to left.
* Active spell icon displayed beside the castbar.
* Compact layout aligned with the full nameplate width.
* Adjustable castbar height.
* Smooth castbar animation.

---

### 🎨 Player Class Colors

Player nameplates can automatically use their class color.

NPC nameplate colors remain unchanged unless another BNP feature intentionally modifies them.

---

### 🛡️ Tank Mode

Optional Tank Mode provides additional visual information for hostile NPC nameplates.

Nameplate state is safely reset when Blizzard recycles frames to prevent stale colors from appearing on unrelated enemies.

---

### ⚔️ Foreign Tagged Mobs

Mobs already tagged by players **outside your party or raid** are automatically displayed with a neutral **grey healthbar**.

This makes it easy to immediately recognize enemies that have already been claimed by another player.

* Untapped mobs remain unchanged.
* Mobs tagged by you remain unchanged.
* Party/Raid tagged mobs remain unchanged.
* Works independently from Tank Mode.
* A foreign-tagged current target remains grey while retaining normal target visibility.

---

### ⬆️ Target Plate on Top

Optionally raises your current target above overlapping nameplates.

Debuff icons, castbars and health information remain clearly visible even when several nameplates overlap.

---

### 🏹 Shared Hunter's Mark

Hunter's Mark is supported as a shared tracking exception.

A Hunter's Mark applied by another Hunter can also be displayed, while other debuffs continue to follow the normal tracking rules.

Timer information is used when available.

---

### 📏 Nameplate Scaling

Adjust the size of Blizzard nameplates directly through the addon.

**Range:** `0.5 – 1.5`
**Default:** `1.0`

---

## 🔍 Reliable Multi-Target Tracking

Blizz Nameplates+ includes several safeguards specifically designed for Vanilla nameplate behavior:

* GUID-based aura tracking.
* Same-name enemies remain separated.
* The death of one enemy does not remove tracked debuffs from surviving enemies with the same name.
* Conservative DoT and curse removal prevents temporary incomplete aura information from deleting valid effects.
* Nameplate GUID stability checks prevent brief **ghost debuffs** when nameplates are recycled during visibility or line-of-sight changes.
* Failed attacks do not create false debuff indicators.

---

# 📦 Requirements

## SuperWoW

**SuperWoW is required to use Blizz Nameplates+.**

The addon relies on the additional GUID and unit information provided by SuperWoW for reliable multi-target debuff tracking, castbars and other nameplate functionality.

Without SuperWoW, Blizz Nameplates+ cannot provide reliable unit identification and is therefore not supported.

---

# 📥 Installation

1. Download the latest **Blizz Nameplates+** release.
2. Delete any existing `BlizzNameplatesPlus` folder from your AddOns directory.
3. Extract the downloaded archive.
4. Copy the `BlizzNameplatesPlus` folder into:

`Interface\AddOns\`

The final path should look like:

`Interface\AddOns\BlizzNameplatesPlus\BlizzNameplatesPlus.toc`

Start the game afterwards.

---

# ⚙️ Configuration

Open the configuration menu using the **BN+ minimap button** or:

`/bnp`

Available options include:

* Nameplate Scale
* Debuff Icon Size
* Class Colors
* Castbars
* Castbar Height
* Tank Mode
* Health %
* Target Glow
* Target Glow Color
* Target Plate on Top

Changes are applied immediately.

---

# 🔎 Missing Spell Reporting

Blizz Nameplates+ includes a small diagnostic collector to help identify missing or custom debuffs.

If a spell or debuff is not being detected correctly, use:

`/bnp unknown`

This displays collected unknown negative aura/effect information that can be reported to the developer.

For additional diagnostic information when specifically requested:

`/bnp unknown verbose`

To clear the collected information:

`/bnp unknown reset`

A screenshot of the output is usually enough for reporting a missing spell.

---

# ⚡ Performance

Blizz Nameplates+ is designed to keep permanent background work low.

* Aura confirmation work runs only when required.
* Target Glow does not require an additional permanent scanning loop.
* Foreign-tag detection uses existing nameplate state.
* Only active castbars are animated every rendered frame.
* Cast discovery is throttled.
* Timer text updates only when the displayed value changes.
* GUID stability protection affects rendering only and does not add additional aura scans.

---

# 🚀 v1.0.3 Highlights

* 🎯 Configurable Target Glow with six color presets.
* ⚔️ Grey healthbars for mobs tagged outside your party/raid.
* 🏹 Shared Hunter's Mark tracking.
* 🛡️ Stack counters for genuinely stacking debuffs.
* 🩸 Improved debuff confirmation and removal reliability.
* ❤️ Optional Health % display.
* ⬆️ Target Plate on Top.
* 🔮 Improved castbar layout and performance.
* 🔧 Fixed false debuffs after Miss, Dodge, Resist, Immune or Evade.
* 💀 Fixed debuffs disappearing when another mob with the same name dies.
* 🔍 Added GUID stability protection against temporary ghost debuffs during nameplate recycling.

---

# ❤️ Special Thanks

A huge thank you to **everyone who helped test Blizz Nameplates+**, reported bugs, shared feedback and helped improve the addon!

Your testing and feedback have been incredibly helpful in making the addon more reliable and polished. ❤️

---

# 👤 Author

**Wurmschwanz**
