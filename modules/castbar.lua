BNP = BNP or {}

local casts = {}
local BAR_HEIGHT = 6

local function GetCastbarHeight()
  if BNP.GetCastbarHeight then return BNP:GetCastbarHeight() end
  return BAR_HEIGHT
end
local BAR_GAP = 2

local function Enabled()
  if BNP.AreCastbarsEnabled then return BNP:AreCastbarsEnabled() end
  return not BNP_DB or BNP_DB.castbars ~= false
end

local function GetPlateGUID(plate)
  if not plate or not plate.GetName then return nil end

  local token = plate:GetName(1)
  if not token then return nil end

  local exists, guid = UnitExists(token)
  if exists and guid then return guid end

  -- On SuperWoW the plate token itself can already be the GUID.
  return token
end

local function SpellData(spellID)
  if SpellInfo and spellID then
    local name, _, texture = SpellInfo(spellID)
    return name or "Casting", texture
  end
  return "Casting", nil
end

local function CreateCastbar(plate)
  if plate.BNPCastbar then return plate.BNPCastbar end
  if not plate.healthbar then return nil end

  local parent = plate.BNPScaleWrapper or plate
  local bar = CreateFrame("StatusBar", nil, parent)
  bar:SetHeight(GetCastbarHeight())
  bar:SetPoint("TOPLEFT", plate.healthbar, "BOTTOMLEFT", 0, -BAR_GAP)
  bar:SetPoint("TOPRIGHT", plate.healthbar, "BOTTOMRIGHT", 0, -BAR_GAP)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(1.0, 0.8, 0.0)
  bar:SetMinMaxValues(0, 1)
  bar:SetValue(0)
  bar:SetFrameLevel((plate.healthbar:GetFrameLevel() or 1) + 1)
  bar:Hide()

  local bg = bar:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bg:SetVertexColor(0.10, 0.10, 0.00, 0.85)
  bg:SetAllPoints(bar)

  local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("CENTER", bar, "CENTER", 0, 0)
  text:SetTextColor(1, 1, 1)
  bar.text = text

  -- Spell icon to the left of the castbar.
  local icon = CreateFrame("Frame", nil, parent)
  icon:SetWidth(14)
  icon:SetHeight(14)
  icon:SetPoint("RIGHT", bar, "LEFT", -2, 0)
  icon:SetFrameLevel(bar:GetFrameLevel())

  local texture = icon:CreateTexture(nil, "ARTWORK")
  texture:SetAllPoints(icon)
  icon.texture = texture

  local border = icon:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
  border:SetPoint("CENTER", icon, "CENTER", 0, 0)
  border:SetWidth(23)
  border:SetHeight(23)
  icon.border = border

  icon:Hide()
  bar.icon = icon

  plate.BNPCastbar = bar
  return bar
end

local function Hide(plate)
  if plate and plate.BNPCastbar then
    plate.BNPCastbar:Hide()
    if plate.BNPCastbar.icon then
      plate.BNPCastbar.icon:Hide()
    end
  end
end

-- Exact SuperWoW event path used by ShaguTweaks' superwow module:
-- START / CAST / CHANNEL create cast state; FAIL removes it.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_CASTEVENT")
eventFrame:SetScript("OnEvent", function()
  local guid = arg1
  local eventType = arg3
  local spellID = arg4
  local timerMS = tonumber(arg5) or 0

  if not guid then return end

  if eventType == "START" or eventType == "CAST" or eventType == "CHANNEL" then
    if timerMS <= 0 then
      -- Instant casts do not need a visible castbar.
      casts[guid] = nil
      return
    end

    local name, texture = SpellData(spellID)
    local now = GetTime()
    local duration = timerMS / 1000

    casts[guid] = {
      name = name,
      texture = texture,
      startTime = now,
      endTime = now + duration,
      duration = duration,
      channel = eventType == "CHANNEL",
    }
  elseif eventType == "FAIL" then
    casts[guid] = nil
  end
end)

local updater = CreateFrame("Frame")
updater:SetScript("OnUpdate", function()
  -- Castbar animation is intentionally updated every rendered frame.
  -- Event/GUID detection remains event-driven; only the cheap visual progress
  -- interpolation runs here, so the bar no longer advances in visible 20ms steps.
  local enabled = Enabled()
  local now = GetTime()
  local plate

  for plate in pairs(BNP.plates) do
    if enabled and plate:IsShown() then
      local guid = GetPlateGUID(plate)
      local cast = guid and casts[guid]

      if cast and now < cast.endTime then
        local bar = CreateCastbar(plate)
        if bar then
          local current = now - cast.startTime
          if current < 0 then current = 0 end
          if current > cast.duration then current = cast.duration end

          bar:SetMinMaxValues(0, cast.duration)

          if cast.channel then
            bar:SetValue(cast.duration - current)
          else
            bar:SetValue(current)
          end

          bar.text:SetText(cast.name)
          bar:SetAlpha(plate:GetAlpha())

          if bar.icon then
            if cast.texture then
              bar.icon.texture:SetTexture(cast.texture)
              bar.icon:SetAlpha(plate:GetAlpha())
              bar.icon:Show()
            else
              bar.icon:Hide()
            end
          end

          bar:Show()
        end
      else
        if guid and cast and now >= cast.endTime then
          casts[guid] = nil
        end
        Hide(plate)
      end
    else
      Hide(plate)
    end
  end
end)


function BNP:RefreshCastbarHeights()
  local plate
  local height = GetCastbarHeight()

  for plate in pairs(BNP.plates or {}) do
    if plate and plate.BNPCastbar then
      plate.BNPCastbar:SetHeight(height)
    end
  end
end

function BNP:SetCastbarsEnabled(enabled)
  BNP_DB = BNP_DB or {}
  BNP_DB.castbars = enabled and true or false

  if not enabled then
    local plate
    for plate in pairs(BNP.plates) do Hide(plate) end
  end

  self:Print("Nameplate castbars " .. (enabled and "enabled." or "disabled."))
end
