if not BNP.libnameplate then return end
if not CombatLogAdd or not SpellInfo then return end

local _, playerClass = UnitClass("player")
local UI = BNP.UI or {}
local ICON_SIZE = UI.ICON_SIZE or 18
local function GetIconSize()
  return (BNP.GetIconSize and BNP:GetIconSize()) or ICON_SIZE
end
local ICON_OFFSET_Y = UI.ICON_OFFSET_Y or 15
local COMBO_LAYOUT_CLASS = (playerClass == "ROGUE" or playerClass == "DRUID")
local COMBO_LAYOUT_OFFSET = 16
local ROW_SPACING = 2

local function GetBaseAuraOffsetY()
  if COMBO_LAYOUT_CLASS and BNP.AreComboPointsEnabled and BNP:AreComboPointsEnabled() then
    return ICON_OFFSET_Y + COMBO_LAYOUT_OFFSET
  end
  return ICON_OFFSET_Y
end

local function UseSeparateCCRow()
  return BNP.IsSeparateCCRowEnabled and BNP:IsSeparateCCRowEnabled()
end

local function GetAuraOffsetY()
  return GetBaseAuraOffsetY()
end

local function GetCCOffsetY()
  local y = GetBaseAuraOffsetY()
  if UseSeparateCCRow() and BNP.AreCrowdControlEnabled and BNP:AreCrowdControlEnabled() then
    y = y + GetIconSize() + ROW_SPACING
  end
  return y
end
local ICON_SPACING = UI.ICON_SPACING or 2
local UPDATE_INTERVAL = 0.05

-- SuperWoW GUID cache. Auras are learned while a unit is the current target
-- and remain attached to that unit's unique GUID after the target changes.
BNP.guidAuras = BNP.guidAuras or {}
BNP.guidNames = BNP.guidNames or {}
BNP.guidLiveCCs = BNP.guidLiveCCs or {}

BNP.pvpAuraProtection = BNP.pvpAuraProtection or {}
local PVP_AURA_PROTECTION_TIME = 6.0

local function ProtectAuraCache(guid, reason)
  if not guid then return end
  BNP.pvpAuraProtection[guid] = {
    untilTime = GetTime() + PVP_AURA_PROTECTION_TIME,
    reason = reason,
  }
end

local function AuraCacheProtected(guid, now)
  local state = guid and BNP.pvpAuraProtection[guid]
  if not state then return false end
  if now <= (state.untilTime or 0) then return true end
  BNP.pvpAuraProtection[guid] = nil
  return false
end

local CLASS_AURAS = {
  WARLOCK = BNP.WarlockAuras,
  PRIEST = BNP.PriestAuras,
  WARRIOR = BNP.WarriorAuras,
  ROGUE = BNP.RogueAuras,
  HUNTER = BNP.HunterAuras,
  MAGE = BNP.MageAuras,
  DRUID = BNP.DruidAuras,
  SHAMAN = BNP.ShamanAuras,
  PALADIN = BNP.PaladinAuras,
}
local AURA_DEFS = CLASS_AURAS[playerClass] or {}
local MAX_VISIBLE_ICONS = 8

local function CleanText(text)
  if not text then return nil end
  text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
  text = string.gsub(text, "|r", "")
  return text
end

local function NameMatches(def, name)
  if not name then return false end
  local lower = string.lower(name)
  for _, known in ipairs(def.names) do
    if lower == string.lower(known) then return true end
  end
  return false
end

local function AuraMatches(def, effect, texture)
  if NameMatches(def, effect) then return true end
  if texture and def.textureMatch then
    return string.find(string.lower(texture), def.textureMatch) and true or false
  end
  return false
end

local function ScanSpellbook()
  if table.getn(AURA_DEFS) == 0 then return end

  local i = 1
  while true do
    local name = GetSpellName(i, BOOKTYPE_SPELL)
    if not name then break end

    local texture = GetSpellTexture(i, BOOKTYPE_SPELL)
    local lowerTexture = texture and string.lower(texture) or ""

    for _, def in ipairs(AURA_DEFS) do
      if NameMatches(def, name) or (def.textureMatch and string.find(lowerTexture, def.textureMatch)) then
        def.localizedName = name
        def.texture = texture or def.texture
      end
    end

    i = i + 1
  end
  if BNP.RefreshSpellbookDurations then BNP:RefreshSpellbookDurations() end
end

local function CreateAuraIcon(parent, index)
  local icon = CreateFrame("Frame", nil, parent)
  local size = GetIconSize()
  icon:SetWidth(size)
  icon:SetHeight(size)
  icon:SetFrameLevel(40)

  local texture = icon:CreateTexture(nil, "ARTWORK")
  texture:SetAllPoints(icon)
  icon.texture = texture

  local timer = icon:CreateFontString(nil, "OVERLAY")
  timer:SetFont(UI.TIMER_FONT or "Fonts\\FRIZQT__.TTF", UI.TIMER_SIZE or 8, "OUTLINE")
  timer:SetPoint("CENTER", icon, "CENTER", UI.TIMER_OFFSET_X or 0, UI.TIMER_OFFSET_Y or 0)
  timer:SetTextColor(1, 1, 1)
  icon.timer = timer

  local stack = icon:CreateFontString(nil, "OVERLAY")
  stack:SetFont(UI.TIMER_FONT or "Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
  stack:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
  stack:SetTextColor(1, 1, 1)
  stack:SetText("")
  icon.stack = stack

  icon.index = index
  icon:Hide()

  return icon
end

local function CreateAuraContainer(plate)
  if not plate then return end
  BNP:RegisterPlate(plate)
  if plate.BNPAuraContainer then return end

  local size = GetIconSize()
  local width = size * MAX_VISIBLE_ICONS + ICON_SPACING * (MAX_VISIBLE_ICONS - 1)
  local container = CreateFrame("Frame", nil, plate)
  container:SetWidth(width)
  container:SetHeight(size)
  container:SetFrameLevel(40)

  if plate.healthbar then
    container:SetPoint("BOTTOM", plate.healthbar, "TOP", 0, GetAuraOffsetY())
  else
    container:SetPoint("BOTTOM", plate, "BOTTOM", 0, 24)
  end

  container.icons = {}
  for i = 1, MAX_VISIBLE_ICONS do
    local icon = CreateAuraIcon(container, i)
    if i == 1 then
      icon:SetPoint("LEFT", container, "LEFT", 0, 0)
    else
      icon:SetPoint("LEFT", container.icons[i - 1], "RIGHT", ICON_SPACING, 0)
    end
    container.icons[i] = icon
  end

  container:Hide()
  plate.BNPAuraContainer = container
end

local function CreateCCContainer(plate)
  if not plate then return end
  BNP:RegisterPlate(plate)
  if plate.BNPCCContainer then return end

  local size = GetIconSize()
  local width = size * MAX_VISIBLE_ICONS + ICON_SPACING * (MAX_VISIBLE_ICONS - 1)
  local container = CreateFrame("Frame", nil, plate)
  container:SetWidth(width)
  container:SetHeight(size)
  container:SetFrameLevel(41)

  if plate.healthbar then
    container:SetPoint("BOTTOM", plate.healthbar, "TOP", 0, GetCCOffsetY())
  else
    container:SetPoint("BOTTOM", plate, "BOTTOM", 0, 24)
  end

  container.icons = {}
  for i = 1, MAX_VISIBLE_ICONS do
    local icon = CreateAuraIcon(container, i)
    if i == 1 then
      icon:SetPoint("LEFT", container, "LEFT", 0, 0)
    else
      icon:SetPoint("LEFT", container.icons[i - 1], "RIGHT", ICON_SPACING, 0)
    end
    container.icons[i] = icon
  end

  container:Hide()
  plate.BNPCCContainer = container
end

local function GetPlateGUID(plate)
  if not plate or not plate.GetName then return nil end

  -- SuperWoW stores the unit GUID/token directly on the nameplate name slot.
  -- Use that exact token, just like Tank Mode and ShaguTweaks do. This avoids
  -- unreliable UnitExists() resolution and, importantly, avoids same-name
  -- fallback collisions between two mobs with identical names.
  local token = plate:GetName(1)
  if token and token ~= "" then return token end
  return nil
end

local function GetTargetGUID()
  local exists, guid = UnitExists("target")
  if exists and guid then return guid end
  return nil
end

local function ClearGUIDAuraState(guid)
  if not guid then return end
  BNP.guidAuras[guid] = nil
  if BNP.guidLiveCCs then BNP.guidLiveCCs[guid] = nil end
  if BNP.pendingAuras then BNP.pendingAuras[guid] = nil end
  if BNP.pvpAuraProtection then BNP.pvpAuraProtection[guid] = nil end
  if BNP.darkHarvest and BNP.darkHarvest.guid == guid then BNP.darkHarvest = nil end
  if BNP.guidNames then BNP.guidNames[guid] = nil end
end

local function CleanupDeadUnit(unit, guid, now)
  if not unit or not guid or not UnitIsDeadOrGhost then return false end
  if AuraCacheProtected and AuraCacheProtected(guid, now) then return false end
  if UnitIsDeadOrGhost(unit) then
    ClearGUIDAuraState(guid)
    return true
  end
  return false
end


-- Fallback for players/NPCs whose nameplate disappears before the periodic
-- dead-state check sees them. Vanilla combat chat reports "<name> dies." only,
-- so this fallback must NEVER clear multiple same-name GUIDs.
local function ClearAuraStateByName(name)
  if not name or name == "" then return end

  -- Combat death chat gives us only a name, never the exact GUID.
  -- Count ALL known GUIDs with this name, not only GUIDs that currently have
  -- tracked auras. Otherwise, if two same-name mobs exist but only one has our
  -- debuffs, the death of the other mob could wrongly clear the survivor.
  local matchGUID = nil
  local matches = 0
  local guid, knownName

  for guid, knownName in pairs(BNP.guidNames or {}) do
    if knownName == name then
      matches = matches + 1
      matchGUID = guid

      if matches > 1 then
        -- Ambiguous same-name death: never clear anything by name.
        -- Exact GUID-based target death cleanup remains authoritative.
        return
      end
    end
  end

  if matches == 1 and matchGUID then
    ClearGUIDAuraState(matchGUID)
  end
end


-- Boss / NPC evade-reset cleanup --------------------------------------------
-- On a real reset the server restores the NPC to full health and drops combat,
-- while BNP's local aura timers would otherwise keep running. Track only the
-- current hostile NPC and clear its exact GUID cache when that reset signature
-- is observed.
local resetWatch = {}
local resetElapsed = 0

local function CheckCurrentTargetReset(now)
  local exists, guid = UnitExists("target")
  if not exists or not guid then
    resetWatch.guid = nil
    resetWatch.wasDamaged = nil
    return
  end

  if UnitIsPlayer and UnitIsPlayer("target") then
    resetWatch.guid = guid
    resetWatch.wasDamaged = nil
    return
  end

  if resetWatch.guid ~= guid then
    resetWatch.guid = guid
    resetWatch.wasDamaged = nil
  end

  if not UnitHealth or not UnitHealthMax then return end
  local hp = tonumber(UnitHealth("target"))
  local maxhp = tonumber(UnitHealthMax("target"))
  if not hp or not maxhp or maxhp <= 0 then return end

  local pct = hp / maxhp
  if pct < 0.95 then
    resetWatch.wasDamaged = true
  end

  if not resetWatch.wasDamaged then return end
  if pct < 0.995 then return end

  -- Prefer the target's combat state when available. If the API is missing,
  -- require the player to be out of combat as a conservative fallback.
  local outOfCombat = false
  if UnitAffectingCombat then
    outOfCombat = not UnitAffectingCombat("target")
  elseif PlayerFrame and PlayerFrame.inCombat ~= nil then
    outOfCombat = not PlayerFrame.inCombat
  end

  if not outOfCombat then return end

  if BNP.guidAuras and BNP.guidAuras[guid] then
    ClearGUIDAuraState(guid)
    if RaidTrace then RaidTrace("RESET", guid, "-", nil) end
  end

  resetWatch.wasDamaged = nil
end

local resetFrame = CreateFrame("Frame")
resetFrame:SetScript("OnUpdate", function()
  resetElapsed = resetElapsed + arg1
  if resetElapsed < 0.10 then return end
  resetElapsed = 0
  CheckCurrentTargetReset(GetTime())
end)

local deathChatFrame = CreateFrame("Frame")
deathChatFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
deathChatFrame:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH")
deathChatFrame:SetScript("OnEvent", function()
  local raw = arg1
  if not raw then return end
  local _, _, deadName = string.find(raw, "^(.+) dies%.$")
  if deadName then ClearAuraStateByName(deadName) end
end)

-- Only successful casts by the local player are allowed to create aura
-- entries. This prevents target scans from importing debuffs cast by other
-- players. SuperWoW supplies caster GUID, target GUID and spell ID.
local function GetPlayerGUID()
  local exists, guid = UnitExists("player")
  if exists and guid then return guid end
  return nil
end

local function DefHasSpellID(def, spellID)
  if not def or not spellID then return false end

  local i
  if def.spellIDs then
    for i = 1, table.getn(def.spellIDs) do
      if def.spellIDs[i] == spellID then return true end
    end
  end

  if def.durations and def.durations[spellID] then return true end
  return false
end

local function FindAuraDef(spellID)
  if not spellID or not SpellInfo then return nil, nil end
  local spellName, _, texture = SpellInfo(spellID)
  if not spellName and not texture then return nil, nil end

  -- Exact IDs are authoritative and must win over shared spell textures.
  local _, def
  for _, def in ipairs(AURA_DEFS) do
    if DefHasSpellID(def, spellID) then
      return def, texture, spellID
    end
  end

  for _, def in ipairs(AURA_DEFS) do
    if NameMatches(def, spellName) then
      return def, texture, spellID
    end
  end

  for _, def in ipairs(AURA_DEFS) do
    if texture and def.textureMatch and string.find(string.lower(texture), def.textureMatch) then
      return def, texture, spellID
    end
  end

  return nil, nil
end


-- Paladin Judgements --------------------------------------------------------
-- SuperWoW reports the button press as Judgement [20271], while the target
-- receives a different aura ID (e.g. Light 20344, Justice 20184, Crusader
-- 20302, Wisdom 20353). Therefore normal CAST-ID == AURA-ID confirmation
-- cannot work for Judgements.
local PALADIN_JUDGEMENT_CAST_ID = 20271

local function IsJudgementDef(def)
  if not def or not def.key then return false end
  return string.find(def.key, "^judgement_") and true or false
end

local function FindJudgementAuraOnUnit(unit)
  if playerClass ~= "PALADIN" or not unit then return nil end

  local i, texture, stacks, dtype, auraSpellID
  for i = 1, 64 do
    texture, stacks, dtype, auraSpellID = UnitDebuff(unit, i)
    if not texture then break end

    if auraSpellID then
      local auraName = nil
      if SpellInfo then auraName = SpellInfo(auraSpellID) end

      local _, def
      for _, def in ipairs(AURA_DEFS) do
        if IsJudgementDef(def) then
          local explicitMatch = false
          local j
          if def.spellIDs then
            for j = 1, table.getn(def.spellIDs) do
              if def.spellIDs[j] == auraSpellID then
                explicitMatch = true
                break
              end
            end
          end

          if explicitMatch or NameMatches(def, auraName) then
            return def, auraSpellID, texture
          end
        end
      end
    end
  end

  return nil
end


-- Turtle WoW Dark Harvest (spell 52552).
-- It is reported by SuperWoW as CHANNEL; arg5 is channel length in ms.
-- A 30% shorter tick interval means aura time advances at 1/0.70 speed.
local DARK_HARVEST_SPELL_ID = 52552
local DARK_HARVEST_SPEED = 1 / 0.70
local DARK_HARVEST_AURAS = {
  corruption=true, curse_of_agony=true, siphon_life=true,
  curse_of_doom=true, drain_life=true, drain_soul=true,
}
BNP.darkHarvest = nil

local function StartDarkHarvest(guid, durationMS)
  local now=GetTime()
  local duration=tonumber(durationMS) or 8000
  if duration > 100 then duration=duration/1000 end
  BNP.darkHarvest={guid=guid, lastUpdate=now, ends=now+duration}
end

local function UpdateDarkHarvest(now)
  local st=BNP.darkHarvest
  if not st then return end
  local untilTime=now
  if untilTime > st.ends then untilTime=st.ends end
  local delta=untilTime-st.lastUpdate
  if delta > 0 then
    local cache=BNP.guidAuras[st.guid]
    if cache then
      local bonus=delta*(DARK_HARVEST_SPEED-1)
      local key,aura
      for key,aura in pairs(cache) do
        if DARK_HARVEST_AURAS[key] and type(aura)=="table" and aura.expires and aura.expires > st.lastUpdate then
          aura.expires=aura.expires-bonus
        end
      end
    end
    st.lastUpdate=untilTime
  end
  if now >= st.ends then BNP.darkHarvest=nil end
end



-- Raid confirmation trace ----------------------------------------------------
-- Tiny always-on ring buffer for the last tracked own-aura transitions.
-- No chat output and no scanning; entries are only added at existing events.
BNP.raidTrace = BNP.raidTrace or {}
BNP.raidTraceMax = 30

local function RaidTrace(stage, guid, key, spellID)
  local t = BNP.raidTrace
  table.insert(t, {
    time = GetTime(),
    stage = stage,
    guid = guid,
    key = key,
    spellID = spellID,
  })
  while table.getn(t) > BNP.raidTraceMax do
    table.remove(t, 1)
  end
end

-- Cast confirmation ---------------------------------------------------------
-- UNIT_CASTEVENT "CAST" means the player finished the cast, but it does not
-- guarantee that the hostile aura actually landed. Resist/Miss/Immune must
-- therefore never create a visible timer.
--
-- We first remember the cast as "pending". It becomes a real aura only after
-- UnitDebuff confirms the matching aura on that exact SuperWoW GUID.
-- Never infer success from CAST alone: melee abilities can still miss/dodge,
-- and hostile targets may resist or be immune after the cast event.
BNP.pendingAuras = BNP.pendingAuras or {}
BNP.pendingAoEAuras = BNP.pendingAoEAuras or {}

-- Pending failures are matched by exact SuperWoW UNIT_CASTEVENT data.
-- Never use global combat-text "miss/resist" lines here: in a raid those can
-- belong to another spell and previously caused unrelated pending DoTs to die.

local function FailPendingAura(targetGUID, spellID)
  if not targetGUID or not spellID then return end
  local entries = BNP.pendingAuras[targetGUID]
  if not entries then return end

  local def = FindAuraDef(spellID)
  if def and entries[def.key] then
    entries[def.key] = nil
  end

  -- Generic Paladin Judgement failure.
  if playerClass == "PALADIN" and spellID == PALADIN_JUDGEMENT_CAST_ID then
    entries.__judgement = nil
  end
end

local PENDING_TIMEOUT = 4.0

-- Shagu-style authoritative own-cast tracking --------------------------------
-- Exact own SuperWoW CAST on an exact GUID creates normal direct single-target
-- debuffs immediately. The application remains provisional for a short window:
-- SuperWoW FAIL and localized combat-log miss/resist/immune messages can roll it
-- back, including restoring the old timer after a resisted refresh.
local STRICT_AURA_KEYS = {
  -- Shared / proc / secondary effects
  shadow_vulnerability=true, hunters_mark=true,

  -- Warlock CC
  fear=true, howl_of_terror=true, banish=true, death_coil=true,

  -- Hunter traps / CC / talent procs
  immolation_trap_effect=true, explosive_trap_effect=true, freezing_trap_effect=true,
  improved_scorpid_sting=true, improved_wing_clip=true, improved_concussive_shot=true,
  scatter_shot=true, wyvern_sting=true, entrapment=true, counterattack=true,
  intimidation=true, scare_beast=true,

  -- Mage CC / proc effects
  polymorph=true, frost_nova=true, counterspell=true, counterspell_silence=true,
  ignite=true, impact=true, frostbite=true, fire_vulnerability=true, winters_chill=true,

  -- Priest CC / proc effects
  psychic_scream=true, silence=true, blackout=true, touch_of_weakness=true,
  shackle_undead=true, mind_control=true,

  -- Paladin CC
  hammer_of_justice=true, repentance=true, turn_undead=true,

  -- Rogue CC / poison procs
  gouge=true, kidney_shot=true, cheap_shot=true, sap=true, blind=true,
  kick_silenced=true, crippling_poison=true, mind_numbing_poison=true,
  wound_poison=true, deadly_poison=true,

  -- Druid CC / secondary effects
  entangling_roots=true, bash=true, pounce=true, pounce_bleed=true,
  hibernate=true, feral_charge_effect=true,

  -- Warrior CC / talent procs
  improved_hamstring=true, intimidating_shout=true, disarm=true,
  charge_stun=true, intercept_stun=true, concussion_blow=true,
  revenge_stun=true, pummel=true, shield_bash=true, deep_wound=true,

  -- Shaman totem / proc effects
  earthbind=true, earthgrab=true, frostbrand_attack=true,
}

local function GetTrackingMode(def)
  if not def or not def.key then return "AURA" end
  if def.category == "CURSE" then return "AURA" end
  if def.aoe then return "AURA" end
  local cat = string.upper(tostring(def.category or ""))
  if cat == "CC" or cat == "ROOT" or cat == "STUN"
    or cat == "TRAP" or cat == "SILENCE" or cat == "PROC" then
    return "AURA"
  end
  if STRICT_AURA_KEYS[def.key] then return "AURA" end
  return "CAST"
end

local function IsCastPrimary(def)
  return GetTrackingMode(def) == "CAST"
end

local AURA_ATTEMPT_WINDOW = 5.0
BNP.auraCastAttempts = BNP.auraCastAttempts or {}

local function CopyAuraState(aura)
  if type(aura) ~= "table" then return nil end
  local copy = {}
  local k, v
  for k, v in pairs(aura) do copy[k] = v end
  return copy
end

local function BuildAffectedKeys(def)
  local keys = {}
  if not def or not def.key then return keys end

  keys[def.key] = true

  -- Any Warlock curse cast can change the target's complete curse state.
  -- Snapshot every tracked curse so a later resist/fail can restore exactly
  -- what was active before the attempt. This also supports Turtle mechanics
  -- where Curse of Agony may coexist with one regular curse.
  if def.category == "CURSE" then
    local _, oldDef
    for _, oldDef in ipairs(AURA_DEFS) do
      if oldDef.category == "CURSE" then
        keys[oldDef.key] = true
      end
    end
  end

  return keys
end

local function StartAuraCastAttempt(guid, def, spellID, affectedKeys)
  if not guid or not spellID then return nil end

  local keys = affectedKeys or BuildAffectedKeys(def)
  local cache = BNP.guidAuras[guid]
  local before = {}
  local key

  for key in pairs(keys) do
    local aura = cache and cache[key]
    before[key] = {
      exists = type(aura) == "table" and true or false,
      aura = CopyAuraState(aura),
    }
  end

  local spellName = nil
  if SpellInfo then spellName = SpellInfo(spellID) end
  if not spellName and def and def.localizedName then spellName = def.localizedName end
  if not spellName and def and def.names then spellName = def.names[1] end

  local attempt = {
    guid = guid,
    key = def and def.key or "__special",
    spellID = spellID,
    spellName = spellName,
    time = GetTime(),
    before = before,
    done = false,
  }

  table.insert(BNP.auraCastAttempts, attempt)
  while table.getn(BNP.auraCastAttempts) > 32 do
    table.remove(BNP.auraCastAttempts, 1)
  end

  return attempt
end

local function RollbackAuraCastAttempt(attempt, reason)
  if not attempt or attempt.done then return false end

  local guid = attempt.guid
  local cache = BNP.guidAuras[guid]
  if not cache then
    cache = {}
    BNP.guidAuras[guid] = cache
  end

  local key, state
  for key, state in pairs(attempt.before or {}) do
    if state.exists and state.aura then
      cache[key] = CopyAuraState(state.aura)
    else
      cache[key] = nil
    end
  end

  attempt.done = true
  RaidTrace("ROLLBACK", guid, attempt.key, attempt.spellID)
  return true
end

local function RollbackAuraAttemptBySpell(guid, spellID, reason)
  if not spellID then return false end
  local now = GetTime()
  local i

  for i = table.getn(BNP.auraCastAttempts), 1, -1 do
    local attempt = BNP.auraCastAttempts[i]
    if attempt and not attempt.done
      and attempt.spellID == spellID
      and (not guid or attempt.guid == guid)
      and now - (attempt.time or 0) <= AURA_ATTEMPT_WINDOW then
      return RollbackAuraCastAttempt(attempt, reason)
    end
  end

  return false
end

local function CleanupAuraCastAttempts(now)
  local i
  for i = table.getn(BNP.auraCastAttempts), 1, -1 do
    local attempt = BNP.auraCastAttempts[i]
    if not attempt or attempt.done or now - (attempt.time or 0) > AURA_ATTEMPT_WINDOW then
      table.remove(BNP.auraCastAttempts, i)
    end
  end
end

-- ShaguPlates does more than just seed debuffs from UNIT_CASTEVENT CAST:
-- libdebuff also watches the local player's failure combat messages and
-- reverts the last application on miss/resist/immune/evade/etc. BNP mirrors
-- that safety, but keeps the exact SuperWoW GUID and can restore the previous
-- timer when a refresh fails.
local failurePatterns = {}

local function EscapeLuaPattern(text)
  return string.gsub(text, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

local function CombatFormatToPattern(formatText)
  if not formatText or formatText == "" then return nil end

  local text = formatText
  text = string.gsub(text, "%%%%", "__BNP_PERCENT__")
  text = string.gsub(text, "%%%d+%$s", "__BNP_STRING__")
  text = string.gsub(text, "%%s", "__BNP_STRING__")
  text = string.gsub(text, "%%%d+%$d", "__BNP_NUMBER__")
  text = string.gsub(text, "%%d", "__BNP_NUMBER__")
  text = EscapeLuaPattern(text)
  text = string.gsub(text, "__BNP_STRING__", ".+")
  text = string.gsub(text, "__BNP_NUMBER__", "%%d+")
  text = string.gsub(text, "__BNP_PERCENT__", "%%%%")
  return "^" .. text .. "$"
end

local function AddFailurePattern(formatText)
  local pattern = CombatFormatToPattern(formatText)
  if pattern then table.insert(failurePatterns, pattern) end
end

AddFailurePattern(SPELLIMMUNESELFOTHER)
AddFailurePattern(IMMUNEDAMAGECLASSSELFOTHER)
AddFailurePattern(SPELLMISSSELFOTHER)
AddFailurePattern(SPELLRESISTSELFOTHER)
AddFailurePattern(SPELLEVADEDSELFOTHER)
AddFailurePattern(SPELLDODGEDSELFOTHER)
AddFailurePattern(SPELLDEFLECTEDSELFOTHER)
AddFailurePattern(SPELLREFLECTSELFOTHER)
AddFailurePattern(SPELLPARRIEDSELFOTHER)
AddFailurePattern(SPELLFAILCASTSELF)

local function IsLocalFailureMessage(raw)
  if not raw or raw == "" then return false end
  local i
  for i = 1, table.getn(failurePatterns) do
    if string.find(raw, failurePatterns[i]) then return true end
  end
  return false
end

local function RollbackAuraAttemptFromCombatMessage(raw)
  if not IsLocalFailureMessage(raw) then return false end

  local now = GetTime()
  local i
  for i = table.getn(BNP.auraCastAttempts), 1, -1 do
    local attempt = BNP.auraCastAttempts[i]
    if attempt and not attempt.done
      and now - (attempt.time or 0) <= AURA_ATTEMPT_WINDOW
      and attempt.spellName
      and string.find(raw, attempt.spellName, 1, true) then
      return RollbackAuraCastAttempt(attempt, "COMBAT_FAIL")
    end
  end

  return false
end

local auraFailureFrame = CreateFrame("Frame")
auraFailureFrame:RegisterEvent("CHAT_MSG_SPELL_FAILED_LOCALPLAYER")
auraFailureFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
auraFailureFrame:SetScript("OnEvent", function()
  RollbackAuraAttemptFromCombatMessage(arg1)
end)

local function HasPendingAuras()
  local guid, entries, key, pending
  for guid, entries in pairs(BNP.pendingAuras) do
    for key, pending in pairs(entries) do
      if type(pending) == "table" then
        return true
      end
    end
  end
  return false
end

local function GetUnitTokenForPlate(plate)
  if not plate or not plate.GetName then return nil end
  return plate:GetName(1)
end

local function FindMatchingAuraOnUnit(unit, def, castSpellID)
  if not unit or not def then return nil, nil, nil end

  -- SuperWoW can expose more than the stock 16/32 debuff slots. In a 40-player
  -- raid our own debuff may therefore sit beyond slot 32. Stopping at 32 made
  -- valid casts time out instead of entering guidAuras.
  local i = 1
  while i <= 64 do
    local texture, stacks, dtype, auraSpellID = UnitDebuff(unit, i)
    if not texture then break end

    if auraSpellID then
      if auraSpellID == castSpellID or DefHasSpellID(def, auraSpellID) then
        return auraSpellID, texture, tonumber(stacks) or 0
      end

      local auraName = SpellInfo and SpellInfo(auraSpellID) or nil
      if NameMatches(def, auraName) then
        return auraSpellID, texture, tonumber(stacks) or 0
      end
    end

    if texture and def.textureMatch and string.find(string.lower(texture), def.textureMatch) then
      return auraSpellID or castSpellID, texture, tonumber(stacks) or 0
    end

    i = i + 1
  end

  return nil, nil, nil
end

local function ReconcileLiveCurseCache(unit, guid)
  if playerClass ~= "WARLOCK" or not unit or not guid then return end

  local cache = BNP.guidAuras[guid]
  if not cache then return end

  -- Curse casts are already strict aura-confirmed. Once a new curse has really
  -- appeared, use that same live target aura state to decide which older curse
  -- timers are still valid. This avoids hard-coding whether CoA is exclusive:
  -- if the server keeps two curses, BNP keeps two; if one was replaced, BNP
  -- removes only the aura that is actually gone.
  local _, curseDef
  for _, curseDef in ipairs(AURA_DEFS) do
    if curseDef.category == "CURSE" and cache[curseDef.key] then
      local cachedAura = cache[curseDef.key]
      local liveSpellID = FindMatchingAuraOnUnit(
        unit,
        curseDef,
        cachedAura and cachedAura.spellID or nil
      )

      if not liveSpellID then
        RaidTrace("CURSE_REMOVE", guid, curseDef.key, cachedAura and cachedAura.spellID)
        cache[curseDef.key] = nil
      end
    end
  end
end

local function CommitPendingAura(guid, key, pending, unit)
  if not guid or not pending then return end

  local def = pending.def
  local cache = BNP.guidAuras[guid]
  if not cache then
    cache = {}
    BNP.guidAuras[guid] = cache
  end

  -- Do not guess curse exclusivity here. Warlock curses are strict aura-
  -- confirmed and are reconciled against the live target state after commit.
  -- This supports both normal Vanilla replacement and Turtle dual-curse rules.

  cache._nextOrder = (cache._nextOrder or 0) + 1
  local aura = cache[key] or {}
  aura.order = cache._nextOrder
  aura.duration = pending.duration
  aura.expires = GetTime() + pending.duration
  aura.spellID = pending.spellID
  aura.texture = pending.texture or def.texture
  aura.stacks = tonumber(pending.stacks) or 0
  aura.confirmedAt = GetTime()
  aura.missingScans = nil

  if pending.liveConfirmed then
    aura.castPrimary = nil
    aura.castPrimaryAt = nil
    aura.liveConfirmed = true
  elseif pending.castPrimary then
    aura.castPrimary = true
    aura.castPrimaryAt = GetTime()
    aura.liveConfirmed = nil
  end

  cache[key] = aura

  if def.category == "CURSE" and unit then
    ReconcileLiveCurseCache(unit, guid)
  end

  RaidTrace("CONFIRM", guid, key, aura.spellID)
end

local function ConfirmPendingForUnit(unit, guid, now)
  if not unit or not guid then return end
  local pendingForGUID = BNP.pendingAuras[guid]
  if not pendingForGUID then return end

  local key, pending
  for key, pending in pairs(pendingForGUID) do
    if type(pending) == "table" then
      if pending.judgementProbe then
        local def, auraSpellID, texture = FindJudgementAuraOnUnit(unit)

        if def and auraSpellID then
          local duration = def.duration
          if BNP.GetSpellbookDurationForDef then
            duration = BNP:GetSpellbookDurationForDef(def) or duration
          end

          local confirmed = {
            def = def,
            spellID = auraSpellID,
            texture = texture or def.texture,
            duration = duration,
            created = pending.created,
            liveConfirmed = true,
          }

          CommitPendingAura(guid, def.key, confirmed, unit)
          pendingForGUID[key] = nil
        elseif now - pending.created > PENDING_TIMEOUT then
          RaidTrace("TIMEOUT", guid, key, pending.spellID)
          -- No Judgement aura appeared: resist, miss, immune or failed cast.
          pendingForGUID[key] = nil
        end
      else
        local auraSpellID, auraTexture, auraStacks = FindMatchingAuraOnUnit(unit, pending.def, pending.spellID)
        if auraSpellID then
          local confirmed = {
            def = pending.def,
            spellID = auraSpellID,
            texture = auraTexture or pending.texture,
            duration = pending.duration,
            created = pending.created,
            stacks = auraStacks or 0,
            liveConfirmed = true,
          }
          CommitPendingAura(guid, key, confirmed, unit)
          pendingForGUID[key] = nil
        elseif now - pending.created > PENDING_TIMEOUT then
          RaidTrace("TIMEOUT", guid, key, pending.spellID)
          -- Effects not approved for the raid fallback remain strict.
          pendingForGUID[key] = nil
        end
      end
    end
  end
end

local function CleanupPending(now)
  local guid, entries, key, pending
  for guid, entries in pairs(BNP.pendingAuras) do
    local any = false
    for key, pending in pairs(entries) do
      if type(pending) == "table" then
        if now - pending.created > PENDING_TIMEOUT then
          entries[key] = nil
        else
          any = true
        end
      end
    end
    if not any then BNP.pendingAuras[guid] = nil end
  end
end


local AOE_PENDING_TIMEOUT = 1.5

local function QueueAoEAura(def, spellID, texture, duration)
  if not def or not spellID then return end
  BNP.pendingAoEAuras[def.key] = {
    def = def,
    spellID = spellID,
    texture = texture or def.texture,
    duration = duration,
    created = GetTime(),
  }
end

local function ConfirmAoEAurasOnUnit(unit, guid)
  if not unit or not guid then return end
  local key, pending
  for key, pending in pairs(BNP.pendingAoEAuras) do
    if type(pending) == "table" then
      local auraSpellID, auraTexture, auraStacks = FindMatchingAuraOnUnit(unit, pending.def, pending.spellID)
      if auraSpellID then
        CommitPendingAura(guid, pending.def.key, {
          def = pending.def,
          spellID = auraSpellID,
          texture = auraTexture or pending.texture,
          duration = pending.duration,
          created = pending.created,
          stacks = auraStacks or 0,
          liveConfirmed = true,
        }, unit)
      end
    end
  end
end

local function HasPendingAoEAuras()
  local key, pending
  for key, pending in pairs(BNP.pendingAoEAuras) do
    if type(pending) == "table" then return true end
  end
  return false
end

local function CleanupPendingAoE(now)
  local key, pending
  for key, pending in pairs(BNP.pendingAoEAuras) do
    if type(pending) == "table" and now - (pending.created or 0) > AOE_PENDING_TIMEOUT then
      BNP.pendingAoEAuras[key] = nil
    end
  end
end

local castEvents = CreateFrame("Frame")
castEvents:RegisterEvent("UNIT_CASTEVENT")
castEvents:SetScript("OnEvent", function()
  local casterGUID = arg1
  local targetGUID = arg2
  local eventType = arg3
  local spellID = arg4
  local playerGUID = GetPlayerGUID()

  if not playerGUID or casterGUID ~= playerGUID then return end

  if eventType == "FAIL" then
    RaidTrace("FAIL", targetGUID, "-", spellID)
    FailPendingAura(targetGUID, spellID)
    RollbackAuraAttemptBySpell(targetGUID, spellID, "UNIT_FAIL")
    return
  end

  -- Dark Harvest is a CHANNEL event, not CAST. Handle only this exact
  -- Turtle spell here so normal aura creation remains CAST-only.
  if eventType == "CHANNEL" and spellID == DARK_HARVEST_SPELL_ID then
    StartDarkHarvest(targetGUID, arg5)
    return
  end

  if eventType ~= "CAST" then return end

  -- Shadow audit only: this never changes the existing lookup or renderer.
  if BNP.AuditSpellDB then BNP:AuditSpellDB(spellID) end

  -- Paladin Judgement is a generic cast (20271). The actual debuff ID is only
  -- known after it lands on the target, so defer identification to UnitDebuff.
  if playerClass == "PALADIN" and spellID == PALADIN_JUDGEMENT_CAST_ID then
    if not targetGUID then return end

    if targetGUID then
      local judgementKeys = {}
      local _, judgementDef
      for _, judgementDef in ipairs(AURA_DEFS) do
        if IsJudgementDef(judgementDef) then judgementKeys[judgementDef.key] = true end
      end
      StartAuraCastAttempt(targetGUID, { key = "__judgement" }, spellID, judgementKeys)
    end

    local pendingForGUID = BNP.pendingAuras[targetGUID]
    if not pendingForGUID then
      pendingForGUID = {}
      BNP.pendingAuras[targetGUID] = pendingForGUID
    end

    pendingForGUID.__judgement = {
      judgementProbe = true,
      created = GetTime(),
    }
    return
  end

  local def, texture = FindAuraDef(spellID)
  if not def then return end

  local duration = nil
  if BNP.GetSpellbookDurationForDef then
    duration = BNP:GetSpellbookDurationForDef(def)
  end
  duration = duration or (def.durations and def.durations[spellID]) or def.duration

  if def.aoe then
    QueueAoEAura(def, spellID, texture, duration)
    return
  end

  if not targetGUID then return end

  StartAuraCastAttempt(targetGUID, def, spellID)

  local pendingForGUID = BNP.pendingAuras[targetGUID]
  if not pendingForGUID then
    pendingForGUID = {}
    BNP.pendingAuras[targetGUID] = pendingForGUID
  end

  pendingForGUID[def.key] = {
    def = def,
    spellID = spellID,
    texture = texture or def.texture,
    duration = duration,
    created = GetTime(),
  }

  RaidTrace("CAST", targetGUID, def.key, spellID)

  if IsCastPrimary(def) then
    local direct = {
      def = def,
      spellID = spellID,
      texture = texture or def.texture,
      duration = duration,
      created = GetTime(),
      stacks = 0,
      castPrimary = true,
    }
    CommitPendingAura(targetGUID, def.key, direct)
    local cache = BNP.guidAuras and BNP.guidAuras[targetGUID]
    if cache and cache[def.key] then
      cache[def.key].castPrimary = true
      cache[def.key].castPrimaryAt = GetTime()
      cache[def.key].liveConfirmed = nil
    end
    pendingForGUID[def.key] = nil
    RaidTrace("DIRECT", targetGUID, def.key, spellID)
    return
  end

  -- Fast path: if the cast target is still our current target, try to confirm
  -- immediately. The normal pending loop remains as the retry path.
  local currentTargetGUID = GetTargetGUID()
  if currentTargetGUID and currentTargetGUID == targetGUID then
    ConfirmPendingForUnit("target", targetGUID, GetTime())
  end
end)



-- Paladin Judgement melee refresh ------------------------------------------
-- Vanilla Judgement debuffs refresh when the judging Paladin lands a melee
-- strike on that target. The aura itself does not get re-cast, so UNIT_CASTEVENT
-- cannot update our timer. Refresh only an already-confirmed OWN Judgement.
local function RefreshOwnJudgementForGUID(guid)
  if playerClass ~= "PALADIN" or not guid then return end

  local cache = BNP.guidAuras[guid]
  if not cache then return end

  local _, def
  for _, def in ipairs(AURA_DEFS) do
    if IsJudgementDef(def) then
      local aura = cache[def.key]
      if type(aura) == "table" and aura.expires then
        local duration = aura.duration or def.duration or 10
        aura.duration = duration
        aura.expires = GetTime() + duration
        aura.confirmedAt = GetTime()
        aura.missingScans = nil
      end
    end
  end
end

-- SuperWoW gives us the target GUID of the player's current target. For normal
-- auto-attacks, the combat text event is sufficient to know a successful melee
-- hit occurred; matching the current target GUID keeps the refresh scoped to
-- the unit actually being attacked.
local judgementMeleeFrame = CreateFrame("Frame")
judgementMeleeFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
judgementMeleeFrame:SetScript("OnEvent", function()
  if playerClass ~= "PALADIN" then return end

  local guid = GetTargetGUID()
  if not guid then return end

  -- CHAT_MSG_COMBAT_SELF_HITS only fires for landed melee attacks (hit/crit).
  RefreshOwnJudgementForGUID(guid)
end)



-- Holy Strike also counts as a melee-style Judgement refresh on Turtle/Octo.
-- It is reported via CHAT_MSG_SPELL_SELF_DAMAGE rather than the normal melee
-- hit event and does not expose a useful spell ID in this client.
local holyStrikeRefreshFrame = CreateFrame("Frame")
holyStrikeRefreshFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
holyStrikeRefreshFrame:SetScript("OnEvent", function()
  if playerClass ~= "PALADIN" then return end

  local raw = arg1
  if not raw then return end

  -- Only successful Holy Strike hit messages refresh the timer.
  -- Miss/resist/immune lines do not match this pattern.
  if not string.find(raw, "^Your Holy Strike hits ") then return end

  local guid = GetTargetGUID()
  if not guid then return end

  -- Extra safety: when the target name is available, require it to be present
  -- in the combat-log line so a stale/current target cannot refresh another GUID.
  local targetName = UnitName("target")
  if targetName and targetName ~= "" and not string.find(raw, targetName, 1, true) then
    return
  end

  RefreshOwnJudgementForGUID(guid)
end)


-- Enemy Feign Death / Vanish protection.
local pvpDisappearFrame = CreateFrame("Frame")
pvpDisappearFrame:RegisterEvent("UNIT_CASTEVENT")
pvpDisappearFrame:SetScript("OnEvent", function()
  local casterGUID = arg1
  local eventType = arg3
  local spellID = arg4

  if not casterGUID or not spellID or not SpellInfo then return end
  if eventType ~= "CAST" and eventType ~= "START" then return end

  local spellName = SpellInfo(spellID)

  -- Abilities that can temporarily drop target/nameplate visibility without
  -- actually cleansing existing harmful effects.
  local TEMPORARY_DISAPPEAR = {
    ["Feign Death"] = true,
    ["Vanish"] = true,
    ["Shadowmeld"] = true,
  }

  if spellName and TEMPORARY_DISAPPEAR[spellName] then
    ProtectAuraCache(casterGUID, spellName)
  end
end)



-- Shared/global aura exceptions ---------------------------------------------
-- Most BNP debuffs are strictly "own casts only". A very small number of
-- effects are globally unique on a target and are useful even when applied by
-- another player. These are explicitly opted in via def.shared = true.
local function FindSharedAuraOnUnit(unit, def)
  if not unit or not def then return nil, nil, nil, nil end

  local i
  for i = 1, 64 do
    local a1, a2, a3, a4, a5, a6, a7, a8, a9, a10 = UnitDebuff(unit, i)
    local texture = a1
    local auraSpellID = a4
    if not texture then break end

    local auraName = nil
    if auraSpellID and SpellInfo then
      auraName = SpellInfo(auraSpellID)
    end

    if AuraMatches(def, auraName, texture) then
      -- SuperWoW/extended clients may append duration/expiration data.
      -- Probe plausible numeric return pairs without assuming one exact fork.
      local duration, expires
      local vals = { a5, a6, a7, a8, a9, a10 }
      local n
      for n = 1, table.getn(vals) - 1 do
        local d = vals[n]
        local e = vals[n + 1]
        if type(d) == "number" and type(e) == "number"
          and d > 0 and d <= 3600 and e > GetTime() then
          duration = d
          expires = e
          break
        end
      end

      return auraSpellID, texture, duration, expires
    end
  end

  return nil, nil, nil, nil
end

local function SyncSharedAuras(unit, guid, now)
  if not unit or not guid then return end

  local _, def
  for _, def in ipairs(AURA_DEFS) do
    if def.shared then
      local auraSpellID, texture, liveDuration, liveExpires = FindSharedAuraOnUnit(unit, def)
      local cache = BNP.guidAuras[guid]

      if auraSpellID or texture then
        if not cache then
          cache = {}
          BNP.guidAuras[guid] = cache
        end

        local aura = cache[def.key]

        -- Never overwrite an accurately timed own aura with the shared/live
        -- fallback. Shared entries exist only when we don't own the timer.
        if not aura or aura.sharedLive then
          if not aura then
            cache._nextOrder = (cache._nextOrder or 0) + 1
            aura = { order = cache._nextOrder }
          end

          aura.sharedLive = true
          aura.spellID = auraSpellID
          aura.texture = texture or def.texture
          aura.confirmedAt = now

          if liveExpires and liveExpires > now then
            -- Best case: the client exposes the real remaining duration.
            aura.duration = liveDuration
            aura.expires = liveExpires
            aura.sharedEstimated = nil
          elseif not aura.expires then
            -- Vanilla fallback: the original application time is unavailable.
            -- Start a local countdown when BNP first sees the foreign mark.
            -- This is intentionally marked as estimated and will still be
            -- removed immediately when the real aura disappears.
            aura.duration = def.duration or 120
            aura.expires = now + aura.duration
            aura.sharedEstimated = true
          end

          cache[def.key] = aura
        end
      elseif cache and cache[def.key] and cache[def.key].sharedLive then
        cache[def.key] = nil
      end
    end
  end
end


-- Live aura removal ---------------------------------------------------------
-- Timers alone are not enough for CC/roots/traps: effects may be dispelled,
-- broken by damage, removed by trinkets, or otherwise end early.
--
-- We NEVER create auras from this scan. It may only remove already-confirmed
-- own auras from the GUID cache when their exact spell ID is no longer present.
local REMOVAL_SCAN_INTERVAL = 0.10
local REMOVAL_GRACE = 0.35
local NORMAL_REMOVAL_MISSING_SCANS = 4

local function CacheHasTrackedAuras(cache)
  if not cache then return false end
  local key, aura
  for key, aura in pairs(cache) do
    if type(aura) == "table" and aura.spellID and aura.expires then
      return true
    end
  end
  return false
end

local EXACT_LIVE_REMOVAL = {
  -- Warlock
  fear=true, howl_of_terror=true, banish=true, death_coil=true,
  -- Hunter
  freezing_trap_effect=true, improved_wing_clip=true, improved_concussive_shot=true,
  scatter_shot=true, wyvern_sting=true, entrapment=true, counterattack=true,
  intimidation=true, scare_beast=true,
  -- Mage
  polymorph=true, frost_nova=true, counterspell_silence=true, impact=true, frostbite=true,
  -- Priest
  psychic_scream=true, silence=true, blackout=true, shackle_undead=true, mind_control=true,
  -- Paladin
  hammer_of_justice=true, repentance=true, turn_undead=true,
  -- Rogue
  gouge=true, kidney_shot=true, cheap_shot=true, sap=true, blind=true, kick_silenced=true,
  -- Druid
  entangling_roots=true, bash=true, pounce=true, hibernate=true, feral_charge_effect=true,
  -- Warrior
  improved_hamstring=true, intimidating_shout=true, disarm=true, charge_stun=true,
  intercept_stun=true, concussion_blow=true, revenge_stun=true, pummel=true, shield_bash=true,
  -- Shaman / custom roots
  earthgrab=true,
}

local function NeedsExactLiveRemoval(key)
  return EXACT_LIVE_REMOVAL[key] and true or false
end

local function IsCrowdControlDef(def)
  return def and EXACT_LIVE_REMOVAL[def.key] and true or false
end

local function ShouldDisplayAuraDef(def)
  if IsCrowdControlDef(def) then
    if BNP.AreCrowdControlEnabled and not BNP:AreCrowdControlEnabled() then return false end
    if UseSeparateCCRow() then return false end
    return true
  end
  return not BNP.AreDebuffsEnabled or BNP:AreDebuffsEnabled()
end


-- Separate CC display -------------------------------------------------------
-- This layer is intentionally independent from guidAuras. It may display live
-- CCs from other players, but it can never create, refresh, remove or alter an
-- own DoT/debuff timer.
local GLOBAL_CC_DEFS = {}
local GLOBAL_CC_BY_ID = {}
local GLOBAL_CC_NEGATIVE = {}
local seenGlobalCC = {}

local function BuildGlobalCCDefs()
  local _, defs, _, ccDef, _, sid
  for _, defs in pairs(CLASS_AURAS) do
    for _, ccDef in ipairs(defs or {}) do
      if IsCrowdControlDef(ccDef) and not seenGlobalCC[ccDef.key] then
        seenGlobalCC[ccDef.key] = true
        table.insert(GLOBAL_CC_DEFS, ccDef)
        if ccDef.spellIDs then
          for _, sid in ipairs(ccDef.spellIDs) do GLOBAL_CC_BY_ID[sid] = ccDef end
        end
        if ccDef.durations then
          for sid in pairs(ccDef.durations) do GLOBAL_CC_BY_ID[sid] = ccDef end
        end
      end
    end
  end
end
BuildGlobalCCDefs()

local function ResolveGlobalCCDef(spellID, texture)
  if spellID and GLOBAL_CC_BY_ID[spellID] then return GLOBAL_CC_BY_ID[spellID] end
  if spellID and GLOBAL_CC_NEGATIVE[spellID] then return nil end

  local auraName = spellID and SpellInfo and SpellInfo(spellID) or nil
  local _, ccDef
  for _, ccDef in ipairs(GLOBAL_CC_DEFS) do
    if NameMatches(ccDef, auraName)
      or (texture and ccDef.textureMatch and string.find(string.lower(texture), ccDef.textureMatch)) then
      if spellID then GLOBAL_CC_BY_ID[spellID] = ccDef end
      return ccDef
    end
  end

  if spellID then GLOBAL_CC_NEGATIVE[spellID] = true end
  return nil
end

local function WantsForeignCCs()
  return BNP.AreCrowdControlEnabled and BNP:AreCrowdControlEnabled()
    and BNP.ShowOtherPlayersCCs and BNP:ShowOtherPlayersCCs()
end

local function SyncForeignCCs(unit, guid, now)
  if not unit or not guid then return end
  if not WantsForeignCCs() then
    BNP.guidLiveCCs[guid] = nil
    return
  end

  local seen = {}
  local live = BNP.guidLiveCCs[guid]
  local i
  for i = 1, 64 do
    local texture, stacks, dtype, auraSpellID = UnitDebuff(unit, i)
    if not texture then break end

    local ccDef = ResolveGlobalCCDef(auraSpellID, texture)
    if ccDef then
      seen[ccDef.key] = true
      if not live then
        live = {}
        BNP.guidLiveCCs[guid] = live
      end

      local aura = live[ccDef.key]
      if not aura then
        aura = { firstSeen = now, order = now }
        live[ccDef.key] = aura
      end
      aura.def = ccDef
      aura.spellID = auraSpellID
      aura.texture = texture or ccDef.texture
      aura.stacks = tonumber(stacks) or 0
      aura.lastSeen = now
      -- Vanilla/SuperWoW does not reliably provide foreign application time.
      -- Use a conservative local estimate for text only; live aura presence is
      -- authoritative for appearance/removal.
      if not aura.expires and ccDef.duration then
        aura.expires = now + ccDef.duration
      end
    end
  end

  if live then
    local key, aura
    for key, aura in pairs(live) do
      if not seen[key] and now - (aura.lastSeen or 0) >= 0.20 then
        live[key] = nil
      end
    end
  end
end

local function HideCCRow(plate)
  local container = plate and plate.BNPCCContainer
  if not container then return end
  local i
  for i = 1, table.getn(container.icons or {}) do
    local icon = container.icons[i]
    icon.lastTimerText = nil
    icon.timer:SetText("")
    if icon.stack then icon.stack:SetText("") end
    icon:Hide()
  end
  container:Hide()
end

local function FormatCCTimer(remaining)
  if not remaining or remaining <= 0 then return "" end
  if remaining >= 3600 then
    return math.ceil(remaining / 3600) .. "h"
  elseif remaining >= 60 then
    return math.ceil(remaining / 60) .. "m"
  end
  return tostring(math.ceil(remaining))
end

local function UpdateCCRow(plate, guid, cache, now)
  if not UseSeparateCCRow()
    or (BNP.AreCrowdControlEnabled and not BNP:AreCrowdControlEnabled()) then
    HideCCRow(plate)
    return
  end

  if not plate.BNPCCContainer then CreateCCContainer(plate) end
  local container = plate.BNPCCContainer
  if not container then return end

  local active = container.activeAuras
  if not active then active = {}; container.activeAuras = active end
  local pool = container.activeAuraPool
  if not pool then
    pool = {}
    for i = 1, MAX_VISIBLE_ICONS do pool[i] = {} end
    container.activeAuraPool = pool
  end
  local oldCount = table.getn(active)
  for i = 1, oldCount do active[i] = nil end
  local count = 0
  local seenOwn = {}

  local _, ccDef
  for _, ccDef in ipairs(AURA_DEFS) do
    if IsCrowdControlDef(ccDef) then
      local aura = cache and cache[ccDef.key]
      local remaining = aura and aura.expires and (aura.expires - now) or nil
      local sharedLive = aura and aura.sharedLive
      if aura and (sharedLive or (remaining and remaining > 0)) then
        count = count + 1
        if count <= MAX_VISIBLE_ICONS then
          local entry = pool[count]
          active[count] = entry
          entry.def = ccDef
          entry.aura = aura
          entry.remaining = remaining
          seenOwn[ccDef.key] = true
        end
      end
    end
  end

  if WantsForeignCCs() then
    local live = guid and BNP.guidLiveCCs[guid]
    local key, aura
    for key, aura in pairs(live or {}) do
      if count >= MAX_VISIBLE_ICONS then break end
      if aura.def and not seenOwn[key] and now - (aura.lastSeen or 0) <= 0.30 then
        count = count + 1
        local entry = pool[count]
        active[count] = entry
        entry.def = aura.def
        entry.aura = aura
        entry.remaining = aura.expires and (aura.expires - now) or nil
      end
    end
  end

  table.sort(active, function(a, b)
    return (a.aura.order or a.aura.firstSeen or 0) < (b.aura.order or b.aura.firstSeen or 0)
  end)

  local visibleCount = table.getn(active)
  local iconSize = GetIconSize()
  local maxWidth = iconSize * MAX_VISIBLE_ICONS + ICON_SPACING * (MAX_VISIBLE_ICONS - 1)
  local rowWidth = 0
  if visibleCount > 0 then rowWidth = iconSize * visibleCount + ICON_SPACING * (visibleCount - 1) end
  local startX = (maxWidth - rowWidth) / 2

  local i
  for i = 1, table.getn(container.icons) do
    local icon = container.icons[i]
    local entry = active[i]
    if entry then
      icon:ClearAllPoints()
      icon:SetPoint("LEFT", container, "LEFT", startX + (i - 1) * (iconSize + ICON_SPACING), 0)
      icon.texture:SetTexture(entry.aura.texture or entry.def.texture)
      local stackCount = tonumber(entry.aura.stacks) or 0
      if icon.stack then
        if stackCount > 1 then icon.stack:SetText(tostring(stackCount)) else icon.stack:SetText("") end
      end
      local timerText = FormatCCTimer(entry.remaining)
      if icon.lastTimerText ~= timerText then icon.timer:SetText(timerText); icon.lastTimerText = timerText end
      icon:Show()
    else
      icon.lastTimerText = nil
      icon.timer:SetText("")
      if icon.stack then icon.stack:SetText("") end
      icon:Hide()
    end
  end

  if visibleCount > 0 then container:Show() else container:Hide() end
end

local function SyncAuraRemoval(unit, guid, now)
  if not unit or not guid then return end
  if AuraCacheProtected(guid, now) then return end
  local cache = BNP.guidAuras[guid]
  if not CacheHasTrackedAuras(cache) then return end

  local present = {}
  local i
  for i = 1, 64 do
    local texture, stacks, dtype, auraSpellID = UnitDebuff(unit, i)
    if not texture then break end
    if auraSpellID then
      present[auraSpellID] = true

      local trackedKey, trackedAura
      for trackedKey, trackedAura in pairs(cache) do
        if type(trackedAura) == "table" and trackedAura.spellID == auraSpellID then
          trackedAura.stacks = tonumber(stacks) or 0
        end
      end
    end
  end

  local key, aura
  for key, aura in pairs(cache) do
    if type(aura) == "table" and aura.spellID and aura.expires then
      -- Give the client a tiny grace period immediately after confirmation so
      -- transient aura-list updates cannot remove a freshly-landed effect.
      local age = now - (aura.confirmedAt or 0)
      local exactRemoval = NeedsExactLiveRemoval(key)

      -- Normal DoTs on player nameplates are only safe to live-remove from the
      -- CURRENT target. During target switches, non-target SuperWoW nameplate
      -- tokens can briefly expose an incomplete/empty UnitDebuff list. Treating
      -- that as a dispel caused valid DoTs to disappear from the GUID cache.
      --
      -- CC/root/trap effects still use exact live removal on every visible plate
      -- because those effects genuinely need immediate break/dispel detection.
      local playerRemoval = false
      if unit == "target" and UnitIsPlayer and UnitIsPlayer("target") then
        local currentTargetGUID = GetTargetGUID()
        playerRemoval = currentTargetGUID and currentTargetGUID == guid
      end

      if age >= REMOVAL_GRACE then
        if present[aura.spellID] then
          -- Positive live sighting upgrades a CAST-seeded timer. Once upgraded,
          -- normal dispel/early-removal logic is safe again.
          aura.missingScans = nil
          if aura.castPrimary then
            aura.castPrimary = nil
            aura.castPrimaryAt = nil
            aura.liveConfirmed = true
          end
        elseif exactRemoval then
          RaidTrace("REMOVE", guid, key, aura.spellID)
          -- CC/roots/traps must disappear immediately when broken/dispelled.
          cache[key] = nil
        elseif playerRemoval then
          if aura.castPrimary then
            -- CAST-seeded auras may be omitted by crowded raid UnitDebuff lists.
            -- Do not use that same missing list to remove it early.
            aura.missingScans = nil
          else
            -- Normal positively-confirmed player DoTs/curses use conservative
            -- removal and still react to real dispels.
            aura.missingScans = (aura.missingScans or 0) + 1

            if aura.missingScans >= NORMAL_REMOVAL_MISSING_SCANS then
              RaidTrace("REMOVE", guid, key, aura.spellID)
              cache[key] = nil
            end
          end
        end
      end
    end
  end
end

local function FormatTimer(remaining)
  if not remaining or remaining <= 0 then return "" end

  -- Keep long durations compact on the small nameplate icons.
  -- Examples: 300s -> 5m, 61s -> 2m, 59s -> 59.
  if remaining >= 3600 then
    return math.ceil(remaining / 3600) .. "h"
  elseif remaining >= 60 then
    return math.ceil(remaining / 60) .. "m"
  end

  return tostring(math.ceil(remaining))
end

-- Nameplate GUID stability ---------------------------------------------------
-- Blizzard/SuperWoW can briefly recycle a visible plate while LOS/occlusion
-- changes (for example when a wall is between the player and nearby mobs).
-- During that tiny transition plate:GetName(1) may still expose the previous
-- unit GUID. Rendering that GUID's cache causes "ghost DoTs" on an unrelated
-- mob for a frame or two.
--
-- Require the same GUID on two consecutive renderer updates before using its
-- aura cache. This does not change aura tracking itself; it only gates display.
local function GetStablePlateGUID(plate)
  local guid = GetPlateGUID(plate)

  if not guid then
    plate.BNPAuraGUIDCandidate = nil
    plate.BNPAuraGUIDStable = nil
    return nil
  end

  if plate.BNPAuraGUIDCandidate ~= guid then
    plate.BNPAuraGUIDCandidate = guid
    plate.BNPAuraGUIDStable = nil
    return nil
  end

  plate.BNPAuraGUIDStable = guid
  return guid
end

local function UpdatePlate(plate)
  if BNP.AreAnyAurasEnabled and not BNP:AreAnyAurasEnabled() then
    if plate and plate.BNPAuraContainer then
      local i
      for i = 1, MAX_VISIBLE_ICONS do
        local icon = plate.BNPAuraContainer.icons and plate.BNPAuraContainer.icons[i]
        if icon then icon:Hide() end
      end
      plate.BNPAuraContainer:Hide()
    end
    HideCCRow(plate)
    return
  end

  if not plate or not plate:IsShown() then return end
  if not plate.BNPAuraContainer then CreateAuraContainer(plate) end

  local container = plate.BNPAuraContainer
  if not container then return end

  local guid = GetStablePlateGUID(plate)
  if guid and plate.name and plate.name.GetText then
    local visibleName = plate.name:GetText()
    if visibleName and visibleName ~= "" then BNP.guidNames[guid] = visibleName end
  end
  local cache = guid and BNP.guidAuras[guid] or nil
  local now = GetTime()

  -- Reuse one small table per plate. Active auras are packed without gaps and
  -- sorted by the order in which they were first applied to this GUID.
  local active = container.activeAuras
  if not active then
    active = {}
    container.activeAuras = active
  end
  local activePool = container.activeAuraPool
  if not activePool then
    activePool = {}
    for i = 1, MAX_VISIBLE_ICONS do activePool[i] = {} end
    container.activeAuraPool = activePool
  end
  local previousCount = table.getn(active)
  for i = 1, previousCount do active[i] = nil end
  local activeCount = 0

  for _, def in ipairs(AURA_DEFS) do
    if ShouldDisplayAuraDef(def) then
      local aura = cache and cache[def.key]
      local remaining = aura and aura.expires and (aura.expires - now) or nil
      local sharedLive = aura and aura.sharedLive

      if sharedLive or (remaining and remaining > 0) then
      if sharedLive and remaining and remaining <= 0 then
        remaining = nil
      end
        if activeCount < MAX_VISIBLE_ICONS then
          activeCount = activeCount + 1
          local entry = activePool[activeCount]
          active[activeCount] = entry
          entry.def = def
          entry.aura = aura
          entry.remaining = remaining
        end
      elseif cache and aura then
        cache[def.key] = nil
      end
    end
  end

  table.sort(active, function(a, b)
    return (a.aura.order or 0) < (b.aura.order or 0)
  end)

  local visibleCount = table.getn(active)
  local iconSize = GetIconSize()
  local maxWidth = iconSize * MAX_VISIBLE_ICONS + ICON_SPACING * (MAX_VISIBLE_ICONS - 1)
  local rowWidth = 0
  if visibleCount > 0 then
    rowWidth = iconSize * visibleCount + ICON_SPACING * (visibleCount - 1)
  end
  local startX = (maxWidth - rowWidth) / 2

  for i = 1, table.getn(container.icons) do
    local icon = container.icons[i]
    local entry = active[i]

    if entry then
      icon:ClearAllPoints()
      icon:SetPoint("LEFT", container, "LEFT", startX + (i - 1) * (iconSize + ICON_SPACING), 0)
      icon.texture:SetTexture(entry.aura.texture or entry.def.texture)

      local stackCount = tonumber(entry.aura.stacks) or 0
      if icon.stack then
        if stackCount > 1 then
          icon.stack:SetText(tostring(stackCount))
        else
          icon.stack:SetText("")
        end
      end

      local timerText = FormatTimer(entry.remaining)
      if icon.lastTimerText ~= timerText then
        icon.timer:SetText(timerText)
        icon.lastTimerText = timerText
      end

      icon:Show()
    else
      icon.lastTimerText = nil
      icon.timer:SetText("")
      if icon.stack then icon.stack:SetText("") end
      icon:Hide()
    end
  end

  if visibleCount > 0 then
    container:Show()
  else
    container:Hide()
  end

  UpdateCCRow(plate, guid, cache, now)
end


function BNP:RefreshAuraLayout(plate)
  if not plate then return end
  local size = GetIconSize()
  local width = size * MAX_VISIBLE_ICONS + ICON_SPACING * (MAX_VISIBLE_ICONS - 1)
  local containers = { plate.BNPAuraContainer, plate.BNPCCContainer }
  local _, container
  for _, container in ipairs(containers) do
    if container then
      container:SetWidth(width)
      container:SetHeight(size)
      local i
      for i = 1, table.getn(container.icons or {}) do
        container.icons[i]:SetWidth(size)
        container.icons[i]:SetHeight(size)
      end
    end
  end
end

function BNP:RefreshAllAuraLayouts()
  local plate
  for plate in pairs(BNP.plates or {}) do
    if plate and plate.healthbar then
      if plate.BNPAuraContainer then
        plate.BNPAuraContainer:ClearAllPoints()
        plate.BNPAuraContainer:SetPoint("BOTTOM", plate.healthbar, "TOP", 0, GetAuraOffsetY())
      end
      if plate.BNPCCContainer then
        plate.BNPCCContainer:ClearAllPoints()
        plate.BNPCCContainer:SetPoint("BOTTOM", plate.healthbar, "TOP", 0, GetCCOffsetY())
      end
    end
    self:RefreshAuraLayout(plate)
  end
end

ScanSpellbook()
table.insert(BNP.libnameplate.OnInit, CreateAuraContainer)
table.insert(BNP.libnameplate.OnInit, CreateCCContainer)
table.insert(BNP.libnameplate.OnShow, CreateAuraContainer)
table.insert(BNP.libnameplate.OnShow, CreateCCContainer)

-- Keep the proven central update loop and the existing icon implementation.
-- No CooldownFrame templates and no frames or tables are created here.
local renderer = CreateFrame("Frame")
local elapsedTotal = 0
local removalElapsed = 0
renderer:SetScript("OnUpdate", function()
  elapsedTotal = elapsedTotal + arg1
  removalElapsed = removalElapsed + arg1
  if elapsedTotal < UPDATE_INTERVAL then return end
  elapsedTotal = 0

  local now = GetTime()
  UpdateDarkHarvest(now)

  CleanupAuraCastAttempts(now)

  local hasPending = HasPendingAuras()
  local hasPendingAoE = HasPendingAoEAuras()
  local doRemovalScan = removalElapsed >= REMOVAL_SCAN_INTERVAL
  if doRemovalScan then removalElapsed = 0 end

  local targetGUID = nil
  if hasPending or hasPendingAoE or doRemovalScan then
    targetGUID = GetTargetGUID()
  end

  if hasPending and targetGUID then
    -- Current target is the most reliable confirmation source.
    ConfirmPendingForUnit("target", targetGUID, now)
  end

  if targetGUID then
    CleanupDeadUnit("target", targetGUID, now)
  end

  if doRemovalScan and targetGUID then
    SyncSharedAuras("target", targetGUID, now)

    if BNP.guidAuras[targetGUID] then
      SyncAuraRemoval("target", targetGUID, now)
    end
  end

  -- The normal renderer always runs. Extra GUID/token/UnitDebuff work is only
  -- performed while pending casts exist or during the throttled removal scan.
  for plate in pairs(BNP.plates) do
    if plate:IsShown() and (hasPending or hasPendingAoE or doRemovalScan) then
      local guid = GetPlateGUID(plate)
      local token = GetUnitTokenForPlate(plate)

      if guid and token then
        -- Do NOT call UnitIsDeadOrGhost() on SuperWoW nameplate tokens.
        -- During target changes/recycling those tokens can briefly report an
        -- invalid dead state and wipe the entire GUID aura cache.
        if hasPending then
          ConfirmPendingForUnit(token, guid, now)
        end

        if hasPendingAoE then
          ConfirmAoEAurasOnUnit(token, guid)
        end

        if doRemovalScan then
          SyncSharedAuras(token, guid, now)

          -- Current target is already handled above via the real "target" unit.
          -- Non-target exact-removal waits briefly after a target switch so a
          -- transient empty UnitDebuff list cannot delete valid auras.
          local currentTargetGUID = targetGUID
          local isCurrentTarget = currentTargetGUID and currentTargetGUID == guid
          SyncAuraRemoval(token, guid, now)
        end
      end
    end

    UpdatePlate(plate)
  end

  if hasPending then
    CleanupPending(now)
  end

  if hasPendingAoE then
    CleanupPendingAoE(now)
  end
end)


-- Foreign CC scanner ---------------------------------------------------------
-- Runs on its own frame so this optional feature can never interrupt the proven
-- own-debuff renderer/update loop.
local FOREIGN_CC_SCAN_INTERVAL = 0.15
local foreignCCElapsed = 0
local foreignCCScanner = CreateFrame("Frame")
foreignCCScanner:SetScript("OnUpdate", function()
  if not WantsForeignCCs() then return end
  foreignCCElapsed = foreignCCElapsed + arg1
  if foreignCCElapsed < FOREIGN_CC_SCAN_INTERVAL then return end
  foreignCCElapsed = 0

  local now = GetTime()
  local targetGUID = GetTargetGUID()
  if targetGUID then pcall(SyncForeignCCs, "target", targetGUID, now) end

  local plate
  for plate in pairs(BNP.plates or {}) do
    if plate and plate:IsShown() then
      local guid = GetPlateGUID(plate)
      if guid and guid ~= targetGUID then
        local token = GetUnitTokenForPlate(plate)
        if token then pcall(SyncForeignCCs, token, guid, now) end
      end
    end
  end
end)


-- Shadow Vulnerability [17794]: own-proc gated live detector -----------------
-- Keep the proven v1.0.5 live aura lookup, but do not passively import a
-- Shadow Vulnerability that merely happens to be visible from another Warlock.
--
-- Ownership rule:
--   * OUR Shadow Bolt / Drain Soul primes the exact target GUID.
--   * If [17794] was absent immediately before that trigger and appears after it,
--     BNP may claim it as ours.
--   * Once claimed, later own Shadow Bolt / Drain Soul triggers may refresh it.
--   * A pre-existing unowned [17794] stays foreign/unproven and is ignored.
--
-- START gives cast-time Shadow Bolt a true pre-impact baseline. CHANNEL handles
-- Drain Soul. For instant casts, the unchanged 0.10s target watcher remembers
-- the last moment [17794] was definitely absent, avoiding the old CAST timing
-- race where the proc aura could already be visible by the time CAST fired.
local svElapsed = 0
local svPresent = {}
local svOwned = {}
local svLastAbsent = {}
local svPrime = {}

local svVerifyGUID = nil
local svVerifyUntil = 0
local svVerifyElapsed = 0
local svVerifyCanCreate = false
local svVerifyWasOwned = false

local function SVDef()
  local i
  for i = 1, table.getn(AURA_DEFS) do
    if AURA_DEFS[i] and AURA_DEFS[i].key == "shadow_vulnerability" then
      return AURA_DEFS[i]
    end
  end
end

local function IsShadowVulnerabilityTrigger(spellID)
  if not spellID or not SpellInfo then return false end
  local name = SpellInfo(spellID)
  return name == "Shadow Bolt" or name == "Drain Soul"
end

local function FindShadowVulnerabilityOnUnit(unit)
  if not unit then return false, nil, 0 end
  local i
  for i = 1, 64 do
    local texture, count, dtype, auraSpellID = UnitDebuff(unit, i)
    if not texture then break end
    if auraSpellID == 17794 then
      return true, texture, tonumber(count) or 0
    end
  end
  return false, nil, 0
end

local function FindShadowVulnerabilityByGUID(guid)
  if not guid then return false, nil, 0 end

  local exists, targetGUID = UnitExists("target")
  if exists and targetGUID == guid then
    return FindShadowVulnerabilityOnUnit("target")
  end

  -- If the player switched targets immediately after the cast, keep the
  -- verification tied to the exact SuperWoW GUID instead of guessing by name.
  local plate
  for plate in pairs(BNP.plates or {}) do
    if plate and plate:IsShown() and GetPlateGUID(plate) == guid then
      local token = GetUnitTokenForPlate(plate)
      if token then
        return FindShadowVulnerabilityOnUnit(token)
      end
    end
  end

  return false, nil, 0
end

local function RemoveOwnedShadowVulnerability(guid)
  if not guid then return end
  local def = SVDef()
  local cache = BNP.guidAuras[guid]
  if def and cache then cache[def.key] = nil end
  svPresent[guid] = nil
  svOwned[guid] = nil
  svPrime[guid] = nil
end

local function CommitOwnShadowVulnerability(guid, texture, stacks)
  if not guid then return false end
  local def = SVDef()
  if not def then return false end

  BNP.guidAuras[guid] = BNP.guidAuras[guid] or {}
  local cache = BNP.guidAuras[guid]
  local aura = cache[def.key]
  if not aura then
    cache._nextOrder = (cache._nextOrder or 0) + 1
    aura = { order = cache._nextOrder }
    cache[def.key] = aura
  end

  aura.duration = 10
  aura.expires = GetTime() + 10
  aura.spellID = 17794
  aura.texture = texture or def.texture
  aura.stacks = tonumber(stacks) or 0
  aura.confirmedAt = GetTime()
  aura.missingScans = nil

  svOwned[guid] = true
  svPresent[guid] = true
  return true
end

-- Same lightweight 0.10s current-target scan used by the working v1.0.5 code.
-- It now records absence/presence for ownership, but only renders already-owned
-- Shadow Vulnerability. It never imports an unowned foreign aura by itself.
local svFrame = CreateFrame("Frame")
svFrame:SetScript("OnUpdate", function()
  if playerClass ~= "WARLOCK" then return end
  svElapsed = svElapsed + arg1
  if svElapsed < 0.10 then return end
  svElapsed = 0

  local exists, guid = UnitExists("target")
  if not exists or not guid then return end

  local now = GetTime()
  local found, texture, stacks = FindShadowVulnerabilityOnUnit("target")

  if not found then
    svLastAbsent[guid] = now
    if svOwned[guid] and svPresent[guid] then
      RemoveOwnedShadowVulnerability(guid)
    end
    return
  end

  if not svOwned[guid] then
    -- Foreign/unproven aura: remember that it exists, but never render it.
    return
  end

  local def = SVDef()
  if not def then return end
  local cache = BNP.guidAuras[guid]
  local aura = cache and cache[def.key]

  -- Our local 10-second ownership expires unless one of OUR trigger events
  -- explicitly refreshed it. If another Warlock keeps [17794] alive after our
  -- timer ends, do not silently inherit that foreign refresh.
  if aura and aura.expires and now > aura.expires + 0.25 then
    RemoveOwnedShadowVulnerability(guid)
    return
  end

  if not aura then
    -- Rebuild only an already-owned entry (e.g. visual cache was recycled).
    BNP.guidAuras[guid] = BNP.guidAuras[guid] or {}
    cache = BNP.guidAuras[guid]
    cache._nextOrder = (cache._nextOrder or 0) + 1
    aura = { order = cache._nextOrder, duration = 10, expires = now + 10 }
    cache[def.key] = aura
  end

  aura.spellID = 17794
  aura.texture = texture or def.texture
  aura.stacks = tonumber(stacks) or 0
  aura.confirmedAt = now
  aura.missingScans = nil
  svPresent[guid] = true
end)

local function PrimeShadowVulnerability(guid)
  if not guid then return end
  local now = GetTime()
  local found = FindShadowVulnerabilityByGUID(guid)

  -- If the aura became visible on the same frame as an instant/channel event,
  -- a very recent positive "absent" sample is the safer pre-trigger baseline.
  local recentlyAbsent = svLastAbsent[guid]
    and (now - svLastAbsent[guid]) <= 0.35

  svPrime[guid] = {
    created = now,
    canCreate = (not found) or recentlyAbsent,
    wasOwned = svOwned[guid] and true or false,
  }
end

local function StartShadowVulnerabilityVerification(guid)
  if not guid then return end
  local now = GetTime()
  local prime = svPrime[guid]

  -- START baselines are valid long enough for a normal Shadow Bolt cast. If an
  -- instant cast had no START event, use only a very recent definite absence.
  if prime and (now - (prime.created or 0)) <= 5.0 then
    svVerifyCanCreate = prime.canCreate and true or false
    svVerifyWasOwned = prime.wasOwned and true or false
  else
    local recentlyAbsent = svLastAbsent[guid]
      and (now - svLastAbsent[guid]) <= 0.35
    svVerifyCanCreate = recentlyAbsent and true or false
    svVerifyWasOwned = svOwned[guid] and true or false
  end

  svVerifyGUID = guid
  svVerifyUntil = now + 1.0
  svVerifyElapsed = 0
  svPrime[guid] = nil
end

local svRefreshEvent = CreateFrame("Frame")
svRefreshEvent:RegisterEvent("UNIT_CASTEVENT")
svRefreshEvent:SetScript("OnEvent", function()
  if playerClass ~= "WARLOCK" then return end

  local playerExists, playerGUID = UnitExists("player")
  if not playerExists or not playerGUID or arg1 ~= playerGUID then return end

  local targetGUID = arg2
  local eventType = arg3
  local spellID = arg4
  if not targetGUID or not IsShadowVulnerabilityTrigger(spellID) then return end

  if eventType == "START" then
    -- True pre-impact snapshot for normal cast-time Shadow Bolt.
    PrimeShadowVulnerability(targetGUID)
    return
  end

  if eventType == "CHANNEL" then
    -- Drain Soul may expose CHANNEL without a separate CAST. Capture a baseline
    -- if START was not seen, then verify the actual [17794] aura.
    if not svPrime[targetGUID] then PrimeShadowVulnerability(targetGUID) end
    StartShadowVulnerabilityVerification(targetGUID)
    return
  end

  if eventType == "CAST" then
    -- Shadow Bolt (including instant variants) verifies only after OUR cast.
    StartShadowVulnerabilityVerification(targetGUID)
    return
  end

  if eventType == "FAIL" then
    svPrime[targetGUID] = nil
    if svVerifyGUID == targetGUID then
      svVerifyGUID = nil
      svVerifyCanCreate = false
      svVerifyWasOwned = false
    end
  end
end)

local svRefreshFrame = CreateFrame("Frame")
svRefreshFrame:SetScript("OnUpdate", function()
  if not svVerifyGUID then return end

  svVerifyElapsed = svVerifyElapsed + arg1
  if svVerifyElapsed < 0.05 then return end
  svVerifyElapsed = 0

  local now = GetTime()
  if now > svVerifyUntil then
    svVerifyGUID = nil
    svVerifyCanCreate = false
    svVerifyWasOwned = false
    return
  end

  local found, texture, stacks = FindShadowVulnerabilityByGUID(svVerifyGUID)
  if not found then return end

  if svVerifyCanCreate or svVerifyWasOwned then
    CommitOwnShadowVulnerability(svVerifyGUID, texture, stacks)
  end

  -- If [17794] was already present and unowned before our trigger, it remains
  -- foreign/unproven. Do not keep polling and accidentally claim it later.
  svVerifyGUID = nil
  svVerifyCanCreate = false
  svVerifyWasOwned = false
end)

function BNP:RefreshDebuffVisibility()
  if not self:AreCrowdControlEnabled() or not self:ShowOtherPlayersCCs() then
    BNP.guidLiveCCs = {}
  end
  self:RefreshAllAuraLayouts()

  local plate
  for plate in pairs(BNP.plates or {}) do
    if plate and plate.BNPAuraContainer then
      if self:AreAnyAurasEnabled() then
        UpdatePlate(plate)
      else
        local i
        for i = 1, MAX_VISIBLE_ICONS do
          local icon = plate.BNPAuraContainer.icons and plate.BNPAuraContainer.icons[i]
          if icon then icon:Hide() end
        end
        plate.BNPAuraContainer:Hide()
        HideCCRow(plate)
      end
    end
  end
end
