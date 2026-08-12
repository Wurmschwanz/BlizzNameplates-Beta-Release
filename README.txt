Blizz Nameplates+ v1.0.3

A lightweight enhancement for the original Blizzard nameplates in
Vanilla WoW / 1.12.

Blizz Nameplates+ keeps the classic Blizzard look while adding modern
quality-of-life features such as personal debuff tracking, castbars,
health percentages, target highlighting, class colors and tank-oriented
nameplate information.

Author: Wurmschwanz

FEATURES

DEBUFF TRACKING

-   Tracks your own debuffs directly on enemy nameplates.
-   GUID-based tracking through SuperWoW prevents same-name target
    collisions.
-   Supports class debuffs, DoTs, curses, crowd control, traps, roots,
    stuns and other supported effects.
-   Up to 8 tracked effects can be displayed on a nameplate.
-   Debuffs remain attached to the correct enemy when changing targets.
-   Active icons are packed together in application order.
-   Numeric countdown timers are displayed directly on the icons.
-   Long durations use compact labels such as 5m, 4m, 3m, 2m and 1m.
-   Real stacking debuffs can display their current stack count.
-   Miss, Dodge, Resist, Immune and Evade do not create false debuff
    timers.
-   Early removal is supported for effects that are dispelled, broken or
    otherwise removed.
-   Conservative removal logic protects normal DoTs and curses from
    temporary incomplete aura scans.
-   Same-name enemy deaths no longer remove debuffs from surviving mobs.
-   Nameplate GUID stability protection prevents brief “ghost DoTs” when
    Blizzard/SuperWoW recycles plates during line-of-sight changes.

HUNTER’S MARK

-   Hunter’s Mark is treated as a shared tracking exception.
-   A mark applied by another Hunter can also be displayed.
-   Own Hunter’s Mark uses normal BNP timing.
-   Foreign Hunter’s Mark uses real expiration information when
    available.
-   If exact expiration information is unavailable, BNP uses a local
    duration estimate while still removing the icon from the actual live
    aura state.

PALADIN SUPPORT

-   Supports Judgement of Light.
-   Supports Judgement of Wisdom.
-   Supports Judgement of Justice.
-   Supports Judgement of the Crusader.
-   Existing own Judgement timers can refresh from successful melee
    attacks.
-   Holy Strike can refresh an already active own Judgement.

WARRIOR AOE SUPPORT

Improved per-target confirmation for: - Demoralizing Shout - Thunder
Clap - Piercing Howl - Challenging Shout

Each visible target is confirmed individually so resisted or unaffected
enemies do not receive false indicators.

CASTBARS

-   Standalone nameplate castbars.
-   Uses SuperWoW casting/channel information.
-   Casts fill from left to right.
-   Channels drain from right to left.
-   Active spell icon is displayed beside the castbar.
-   Compact layout spans the full visual width of the nameplate.
-   Castbar height can be adjusted in the options.
-   Only active castbars are animated every rendered frame.

TARGET GLOW

-   Optional Target Glow makes the current target immediately
    recognizable.
-   Glow is centered around the full visible nameplate, including the
    level area.
-   Available colors:
    -   White
    -   Gold
    -   Blue
    -   Green
    -   Red
    -   Purple

HEALTH %

-   Optional health percentage displayed directly inside the healthbar.
-   Read-only implementation avoids interfering with Blizzard healthbar
    behavior.
-   Positioned for optical centering on the full nameplate.

CLASS COLORS

-   Player nameplates can use class colors.
-   Colors are restored if Blizzard attempts to overwrite them during
    combat.
-   NPC colors remain controlled by Blizzard unless Tank Mode is
    actively changing them.

TANK MODE

-   Optional Tank Mode for hostile NPC nameplates.
-   Designed to make threat-related nameplate states easier to
    recognize.
-   Recycled nameplates are safely reset to avoid stale colors.

FOREIGN TAGGED MOBS

-   Hostile mobs tagged by players outside your party or raid are shown
    with a neutral grey healthbar.
-   Uses the actual Vanilla tap/tag ownership state.
-   Untapped mobs and mobs tagged by you, your party or your raid remain
    normal.
-   Works independently from Tank Mode.
-   A foreign-tagged current target remains grey while retaining normal
    target visibility.

TARGET PLATE ON TOP

-   Optional setting to raise the current target nameplate above
    overlapping plates.
-   Uses safe Vanilla-compatible frame strata.
-   Debuffs, castbar and health percentage retain their normal internal
    draw order.

NAMEPLATE SCALE

-   Adjustable nameplate scale.
-   Uses a Shagu-style visual wrapper so the original world-positioned
    Blizzard frame is not incorrectly scaled.
-   Default multiplier: 1.0
-   Supported range: 0.5 to 1.5

SHAGUTWEAKS COMPATIBILITY

Blizz Nameplates+ is fully standalone.

ShaguTweaks is NOT required.

If ShaguTweaks is installed, BNP includes compatibility handling for its
nameplate modules and Darkened UI styling without modifying ShaguTweaks
saved settings.

REQUIREMENTS

SuperWoW is required.

Blizz Nameplates+ relies on SuperWoW GUID/unit information for reliable
multi-target tracking and nameplate functionality.

INSTALLATION

MANUAL INSTALLATION

1.  Delete any old BlizzNameplatesPlus folder from your AddOns
    directory.

2.  Extract the new version.

3.  Copy the BlizzNameplatesPlus folder into:

    Interface

4.  The final path should look like:

    Interface.toc

5.  Start the game or use /reload if appropriate.

GIT / ADDON MANAGERS

The current addon files are maintained directly in the repository’s main
branch.

Git-based addon managers can therefore install and update Blizz
Nameplates+ directly from the repository instead of relying on GitHub
Release ZIP files.

Manual users can continue using the packaged ZIP from GitHub Releases.

OPTIONS

Open the configuration menu with: /bnp /bnp config

The addon also includes a movable BN+ minimap button.

Available options include: - Nameplate Scale - Debuff Icon Size - Class
Colors - Castbars - Castbar Height - Tank Mode - Health % - Target
Glow - Target Glow Color - Target Plate on Top

COMMANDS

/bnp Open the options menu.

/bnp config Open the options menu.

/bnp status Display addon status information.

/bnp debug on Enable debug output.

/bnp debug off Disable debug output.

/bnp unknown Show useful unknown negative aura/effect information for
reporting missing custom spells.

/bnp unknown verbose Show additional raw cast information for developer
troubleshooting.

/bnp unknown reset Clear collected unknown spell information.

/bnp direct Show collected direct player spell events.

/bnp guid Display SuperWoW GUID information for the current
target/nameplate.

/bnp spelldb Display SpellDB audit information.

/bnp spelldb reset Reset SpellDB audit counters.

PERFORMANCE

Blizz Nameplates+ is designed to keep permanent background work low.

-   Aura confirmation work runs only when required.
-   No permanent high-frequency scan was added for Target Glow or
    foreign-tag detection.
-   Only active castbars animate every rendered frame.
-   Cast discovery is throttled.
-   Timer text updates only when the displayed value changes.
-   GUID stability protection affects rendering only and does not add
    extra UnitDebuff scans.
-   ShaguTweaks Darkened UI compatibility uses limited recycle-time
    updates instead of a permanent scanner.

v1.0.3 HIGHLIGHTS

-   Added configurable Target Glow with six color presets.
-   Added grey healthbars for mobs tagged outside your party/raid.
-   Added shared Hunter’s Mark support including timer handling.
-   Added generic stack counters for genuinely stacking debuffs.
-   Improved Warrior AoE debuff confirmation.
-   Improved strict Miss/Dodge/Resist/Immune/Evade handling.
-   Improved Paladin Judgement support and refresh behavior.
-   Added Health % display.
-   Added Target Plate on Top.
-   Improved castbar layout and performance.
-   Improved ShaguTweaks compatibility and Darkened UI recycling.
-   Fixed SetFrameStrata(“UNKNOWN”) errors.
-   Fixed debuffs disappearing when another mob with the same name dies.
-   Improved normal DoT/curse removal reliability.
-   Added GUID stability protection against temporary ghost debuffs
    during nameplate recycling.

THANK YOU

A huge thank you to everyone who helped test Blizz Nameplates+, reported
bugs, shared feedback and helped improve the addon.

Your testing and feedback have been incredibly helpful in making the
addon more reliable and polished.

CREDITS

Blizz Nameplates+ Author / Publisher: Wurmschwanz

Shagu / ShaguTweaks / ShaguPlates: Referenced during development for
Vanilla nameplate behavior, compatibility patterns and selected
nameplate/debuff implementation concepts.

SuperWoW: Provides the GUID and extended unit functionality required for
reliable multi-target tracking.
