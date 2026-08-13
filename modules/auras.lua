if not BNP.libnameplate then return end
if not CombatLogAdd or not SpellInfo then return end

local _, playerClass = UnitClass("player")
local UI = BNP.UI or {}
local ICON_SIZE = UI.ICON_SIZE or 18
local function GetIconSize()
  return (BNP.GetIconSize and BNP:GetIconSize()) or ICON_SIZE
end
local ICON_OFFSET_Y = UI.ICON_OFFSET_Y or 15
local ICON_SPACING = UI.ICON_SPACING or 2
local UPDATE_INTERVAL = 0.05

-- SuperWoW GUID cache. Auras are learned while a unit is the current target
-- and remain attached to that unit's unique GUID after the target changes.
BNP.guidAuras = BNP.guidAuras or {}
BNP.guidNames = BNP.guidNames or {}

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
    container:SetPoint("BOTTOM", plate.healthbar, "TOP", 0, ICON_OFFSET_Y)
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

-- Central all-class aura tracking policy -------------------------------------
-- Modeled after ShaguPlates' SuperWoW/libdebuff approach:
-- the player's exact SuperWoW CAST can seed a local debuff timer, while live
-- UnitDebuff data is used to correct/upgrade that cached state.
--
-- BNP intentionally keeps risky effects strict:
--   * Warlock curses (Turtle dual-curse talent can resist each curse separately)
--   * AoE effects (must be verified per victim)
--   * CC / roots / stuns / traps / silences / indirect talent procs
--   * melee effects where application can fail independently
--
-- Anything not explicitly audited below defaults to strict AURA confirmation.
local TRACK_CAST = {
  DRUID = {
    moonfire=true,
    insect_swarm=true,
    faerie_fire=true,
    faerie_fire_feral=true,
  },

  HUNTER = {
    serpent_sting=true,
    viper_sting=true,
    scorpid_sting=true,
  },

  PRIEST = {
    shadow_word_pain=true,
    devouring_plague=true,
    vampiric_embrace=true,
    holy_fire=true,
    starshards=true,
  },

  SHAMAN = {
    flame_shock=true,
  },

  WARLOCK = {
    corruption=true,
    siphon_life=true,
    immolate=true,
  },
}

local function GetTrackingMode(def)
  if not def or not def.key then return "AURA" end
  if def.category == "CURSE" then return "AURA" end
  if def.aoe then return "AURA" end

  local classPolicy = TRACK_CAST[playerClass]
  if classPolicy and classPolicy[def.key] then
    return "CAST"
  end

  return "AURA"
end

BNP.castPrimaryCommits = BNP.castPrimaryCommits or {}

local function MarkCastPrimaryCommit(guid, def, spellID)
  if not guid or not def or not def.key or not spellID then return end
  BNP.castPrimaryCommits[guid] = BNP.castPrimaryCommits[guid] or {}
  BNP.castPrimaryCommits[guid][def.key] = {
    spellID = spellID,
    time = GetTime(),
  }
end

local function RetractCastPrimaryOnFail(guid, spellID)
  if not guid or not spellID then return end

  local byGUID = BNP.castPrimaryCommits[guid]
  if not byGUID then return end

  local key, info
  for key, info in pairs(byGUID) do
    if info and info.spellID == spellID and (GetTime() - (info.time or 0)) <= 4.0 then
      local cache = BNP.guidAuras[guid]
      if cache and cache[key] and cache[key].castPrimary then
        cache[key] = nil
        RaidTrace("RETRACT", guid, key, spellID)
      end
      byGUID[key] = nil
    end
  end
end

local function IsCastPrimary(def)
  return GetTrackingMode(def) == "CAST"
end


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

local function CommitPendingAura(guid, key, pending)
  if not guid or not pending then return end

  local def = pending.def
  local cache = BNP.guidAuras[guid]
  if not cache then
    cache = {}
    BNP.guidAuras[guid] = cache
  end

  -- Only replace mutually-exclusive curses after the new curse is confirmed
  -- on the target. A resisted curse must never remove the existing one.
  if def.category == "CURSE" and def.curseExclusive ~= false then
    local _, oldDef
    for _, oldDef in ipairs(AURA_DEFS) do
      if oldDef.category == "CURSE" and oldDef.curseExclusive ~= false then
        cache[oldDef.key] = nil
      end
    end
  end

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

          CommitPendingAura(guid, def.key, confirmed)
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
          CommitPendingAura(guid, key, confirmed)
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
        })
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
    RetractCastPrimaryOnFail(targetGUID, spellID)
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
    MarkCastPrimaryCommit(targetGUID, def, spellID)
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
end


function BNP:RefreshAuraLayout(plate)
  if not plate or not plate.BNPAuraContainer then return end

  local container = plate.BNPAuraContainer
  local size = GetIconSize()
  local width = size * MAX_VISIBLE_ICONS + ICON_SPACING * (MAX_VISIBLE_ICONS - 1)

  container:SetWidth(width)
  container:SetHeight(size)

  local i
  for i = 1, table.getn(container.icons) do
    container.icons[i]:SetWidth(size)
    container.icons[i]:SetHeight(size)
  end
end

function BNP:RefreshAllAuraLayouts()
  local plate
  for plate in pairs(BNP.plates or {}) do
    self:RefreshAuraLayout(plate)
  end
end

ScanSpellbook()
table.insert(BNP.libnameplate.OnInit, CreateAuraContainer)
table.insert(BNP.libnameplate.OnShow, CreateAuraContainer)

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

  local rguid, entries, rkey, info
  for rguid, entries in pairs(BNP.castPrimaryCommits or {}) do
    local any = false
    for rkey, info in pairs(entries) do
      if not info or now - (info.time or 0) > 2.0 then
        entries[rkey] = nil
      else
        any = true
      end
    end
    if not any then BNP.castPrimaryCommits[rguid] = nil end
  end

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


-- Shadow Vulnerability [17794]: isolated live-aura detector.
local svElapsed = 0
local svPresent = {}
local function SVDef()
  local i
  for i=1,table.getn(AURA_DEFS) do
    if AURA_DEFS[i] and AURA_DEFS[i].key=="shadow_vulnerability" then return AURA_DEFS[i] end
  end
end
local svFrame=CreateFrame("Frame")
svFrame:SetScript("OnUpdate",function()
  if playerClass~="WARLOCK" then return end
  svElapsed=svElapsed+arg1
  if svElapsed<0.10 then return end
  svElapsed=0
  local ok,guid=UnitExists("target")
  if not ok or not guid then return end
  local found,tex,count=false,nil,0
  local i
  for i=1,32 do
    local t,c,dt,id=UnitDebuff("target",i)
    if not t then break end
    if id==17794 then found,tex,count=true,t,tonumber(c) or 0 break end
  end
  local def=SVDef()
  if not def then return end
  if found then
    BNP.guidAuras[guid]=BNP.guidAuras[guid] or {}
    local cache=BNP.guidAuras[guid]
    local aura=cache[def.key]
    if not aura then
      cache._nextOrder=(cache._nextOrder or 0)+1
      aura={order=cache._nextOrder}
      cache[def.key]=aura
    end
    if not svPresent[guid] then
      aura.expires=GetTime()+10
      aura.duration=10
    end
    aura.spellID=17794
    aura.texture=tex or def.texture
    aura.stacks=count
    aura.confirmedAt=GetTime()
    aura.missingScans=nil
    svPresent[guid]=true
  elseif svPresent[guid] then
    local cache=BNP.guidAuras[guid]
    if cache then cache[def.key]=nil end
    svPresent[guid]=nil
  end
end)



-- Shadow Vulnerability refresh detector -------------------------------------
-- The aura can proc again while already active. The direct aura watcher keeps
-- existence correct; this helper only refreshes its local 10s timer when a
-- Shadow Bolt / Drain Soul event is followed by an active aura 17794.
local svRefreshGUID = nil
local svRefreshUntil = 0
local svRefreshElapsed = 0

local function IsShadowVulnerabilityTrigger(spellID)
  if not spellID or not SpellInfo then return false end
  local name = SpellInfo(spellID)
  return name == "Shadow Bolt" or name == "Drain Soul"
end

local function RefreshShadowVulnerabilityIfPresent(guid)
  if playerClass ~= "WARLOCK" or not guid then return false end

  local exists, currentGUID = UnitExists("target")
  if not exists or not currentGUID or currentGUID ~= guid then
    return false
  end

  local found = false
  local texture = nil
  local stacks = 0
  local i
  for i = 1, 64 do
    local t, c, dtype, auraSpellID = UnitDebuff("target", i)
    if not t then break end
    if auraSpellID == 17794 then
      found = true
      texture = t
      stacks = tonumber(c) or 0
      break
    end
  end

  if not found then return false end

  local def = nil
  for i = 1, table.getn(AURA_DEFS) do
    if AURA_DEFS[i] and AURA_DEFS[i].key == "shadow_vulnerability" then
      def = AURA_DEFS[i]
      break
    end
  end
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
  aura.stacks = stacks
  aura.confirmedAt = GetTime()
  aura.missingScans = nil

  return true
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

  if eventType ~= "CAST" and eventType ~= "CHANNEL" then return end
  if not IsShadowVulnerabilityTrigger(spellID) then return end
  if not targetGUID then return end

  -- Give the proc aura a brief moment to appear on the target.
  svRefreshGUID = targetGUID
  svRefreshUntil = GetTime() + 0.8
  svRefreshElapsed = 0
end)

local svRefreshFrame = CreateFrame("Frame")
svRefreshFrame:SetScript("OnUpdate", function()
  if not svRefreshGUID then return end

  svRefreshElapsed = svRefreshElapsed + arg1
  if svRefreshElapsed < 0.05 then return end
  svRefreshElapsed = 0

  if GetTime() > svRefreshUntil then
    svRefreshGUID = nil
    return
  end

  if RefreshShadowVulnerabilityIfPresent(svRefreshGUID) then
    svRefreshGUID = nil
  end
end)

