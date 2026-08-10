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
local MAX_VISIBLE_ICONS = 5

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
  local token = plate:GetName(1)
  if not token then return nil end
  local exists, guid = UnitExists(token)
  if exists and guid then return guid end
  return nil
end

local function GetTargetGUID()
  local exists, guid = UnitExists("target")
  if exists and guid then return guid end
  return nil
end

-- Only successful casts by the local player are allowed to create aura
-- entries. This prevents target scans from importing debuffs cast by other
-- players. SuperWoW supplies caster GUID, target GUID and spell ID.
local function GetPlayerGUID()
  local exists, guid = UnitExists("player")
  if exists and guid then return guid end
  return nil
end

local function FindAuraDef(spellID)
  if not spellID or not SpellInfo then return nil, nil end
  local spellName, _, texture = SpellInfo(spellID)
  if not spellName and not texture then return nil, nil end

  for _, def in ipairs(AURA_DEFS) do
    if AuraMatches(def, spellName, texture) then
      return def, texture, spellID
    end
  end

  return nil, nil
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


-- Cast confirmation ---------------------------------------------------------
-- UNIT_CASTEVENT "CAST" means the player finished the cast, but it does not
-- guarantee that the hostile aura actually landed. Resist/Miss/Immune must
-- therefore never create a visible timer.
--
-- We first remember the cast as "pending". It becomes a real aura only after
-- UnitDebuff confirms the same spell ID on that exact SuperWoW GUID.
BNP.pendingAuras = BNP.pendingAuras or {}
local PENDING_TIMEOUT = 2.0

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

local function ConfirmedSpellOnUnit(unit, spellID)
  if not unit or not spellID then return false end
  local i
  for i = 1, 32 do
    local texture, stacks, dtype, auraSpellID = UnitDebuff(unit, i)
    if not texture then break end
    if auraSpellID == spellID then
      return true
    end
  end
  return false
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
  aura.stacks = 0
  aura.confirmedAt = GetTime()
  cache[key] = aura
end

local function ConfirmPendingForUnit(unit, guid, now)
  if not unit or not guid then return end
  local pendingForGUID = BNP.pendingAuras[guid]
  if not pendingForGUID then return end

  local key, pending
  for key, pending in pairs(pendingForGUID) do
    if type(pending) == "table" then
      if ConfirmedSpellOnUnit(unit, pending.spellID) then
        CommitPendingAura(guid, key, pending)
        pendingForGUID[key] = nil
      elseif now - pending.created > PENDING_TIMEOUT then
        -- Nothing landed: resist, miss, immune, evade or otherwise failed.
        pendingForGUID[key] = nil
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

local castEvents = CreateFrame("Frame")
castEvents:RegisterEvent("UNIT_CASTEVENT")
castEvents:SetScript("OnEvent", function()
  local casterGUID = arg1
  local targetGUID = arg2
  local eventType = arg3
  local spellID = arg4
  local playerGUID = GetPlayerGUID()

  if not playerGUID or casterGUID ~= playerGUID or not targetGUID then return end

  -- Dark Harvest is a CHANNEL event, not CAST. Handle only this exact
  -- Turtle spell here so normal aura creation remains CAST-only.
  if eventType == "CHANNEL" and spellID == DARK_HARVEST_SPELL_ID then
    StartDarkHarvest(targetGUID, arg5)
    return
  end

  if eventType ~= "CAST" then return end

  -- Shadow audit only: this never changes the existing lookup or renderer.
  if BNP.AuditSpellDB then BNP:AuditSpellDB(spellID) end

  local def, texture = FindAuraDef(spellID)
  if not def then return end

  local duration = nil
  if BNP.GetSpellbookDurationForDef then
    duration = BNP:GetSpellbookDurationForDef(def)
  end
  duration = duration or (def.durations and def.durations[spellID]) or def.duration

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
end)


-- Live aura removal ---------------------------------------------------------
-- Timers alone are not enough for CC/roots/traps: effects may be dispelled,
-- broken by damage, removed by trinkets, or otherwise end early.
--
-- We NEVER create auras from this scan. It may only remove already-confirmed
-- own auras from the GUID cache when their exact spell ID is no longer present.
local REMOVAL_SCAN_INTERVAL = 0.10
local REMOVAL_GRACE = 0.35

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

local function SyncAuraRemoval(unit, guid, now)
  if not unit or not guid then return end
  local cache = BNP.guidAuras[guid]
  if not CacheHasTrackedAuras(cache) then return end

  local present = {}
  local i
  for i = 1, 32 do
    local texture, stacks, dtype, auraSpellID = UnitDebuff(unit, i)
    if not texture then break end
    if auraSpellID then
      present[auraSpellID] = true
    end
  end

  local key, aura
  for key, aura in pairs(cache) do
    if type(aura) == "table" and aura.spellID and aura.expires then
      -- Give the client a tiny grace period immediately after confirmation so
      -- transient aura-list updates cannot remove a freshly-landed effect.
      local age = now - (aura.confirmedAt or 0)
      if age >= REMOVAL_GRACE and not present[aura.spellID] then
        cache[key] = nil
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

local function UpdatePlate(plate)
  if not plate or not plate:IsShown() then return end
  if not plate.BNPAuraContainer then CreateAuraContainer(plate) end

  local container = plate.BNPAuraContainer
  if not container then return end

  local guid = GetPlateGUID(plate)
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

    if remaining and remaining > 0 then
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

      local timerText = FormatTimer(entry.remaining)
      if icon.lastTimerText ~= timerText then
        icon.timer:SetText(timerText)
        icon.lastTimerText = timerText
      end

      icon:Show()
    else
      icon.lastTimerText = nil
      icon.timer:SetText("")
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

  local hasPending = HasPendingAuras()
  local doRemovalScan = removalElapsed >= REMOVAL_SCAN_INTERVAL
  if doRemovalScan then removalElapsed = 0 end

  local targetGUID = nil
  if hasPending or doRemovalScan then
    targetGUID = GetTargetGUID()
  end

  if hasPending and targetGUID then
    -- Current target is the most reliable confirmation source.
    ConfirmPendingForUnit("target", targetGUID, now)
  end

  if doRemovalScan and targetGUID then
    SyncAuraRemoval("target", targetGUID, now)
  end

  -- The normal renderer always runs. Extra GUID/token/UnitDebuff work is only
  -- performed while pending casts exist or during the throttled removal scan.
  for plate in pairs(BNP.plates) do
    if plate:IsShown() and (hasPending or doRemovalScan) then
      local guid = GetPlateGUID(plate)
      local token = GetUnitTokenForPlate(plate)

      if guid and token then
        if hasPending then
          ConfirmPendingForUnit(token, guid, now)
        end
        if doRemovalScan then
          SyncAuraRemoval(token, guid, now)
        end
      end
    end

    UpdatePlate(plate)
  end

  if hasPending then
    CleanupPending(now)
  end
end)
