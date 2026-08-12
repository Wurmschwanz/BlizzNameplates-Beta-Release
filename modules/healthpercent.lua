BNP = BNP or {}

local function Enabled()
  return BNP.IsHealthPercentEnabled and BNP:IsHealthPercentEnabled()
end

local function CreateHealthText(plate)
  if plate.BNPHealthPercent then return plate.BNPHealthPercent end
  if not plate or not plate.healthbar then return nil end

  -- Purely visual/read-only overlay. No hooks or writes to the healthbar.
  local parent = plate.BNPScaleWrapper or plate
  local text = parent:CreateFontString(nil, "OVERLAY")
  text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
  text:SetPoint("CENTER", plate.healthbar, "CENTER", 3, 0)
  text:SetTextColor(1, 1, 1)
  text:Hide()

  plate.BNPHealthPercent = text
  return text
end

local function GetPercentFromBar(plate)
  if not plate or not plate.healthbar then return nil end

  local minValue, maxValue = plate.healthbar:GetMinMaxValues()
  local value = plate.healthbar:GetValue()

  if value and minValue and maxValue and maxValue > minValue then
    local pct = ((value - minValue) / (maxValue - minValue)) * 100
    return math.floor(pct + 0.5)
  end

  return nil
end

local function GetPercentFromUnit(plate)
  if not plate or not plate.GetName then return nil end

  local token = plate:GetName(1)
  if not token or not UnitExists(token) then return nil end
  if not UnitHealth or not UnitHealthMax then return nil end

  local health = UnitHealth(token)
  local maxHealth = UnitHealthMax(token)

  if health and maxHealth and maxHealth > 0 then
    return math.floor((health / maxHealth) * 100 + 0.5)
  end

  return nil
end

local function UpdatePlate(plate)
  if not plate or not plate.healthbar then return end

  local text = plate.BNPHealthPercent

  if not Enabled() or not plate:IsShown() then
    if text then text:Hide() end
    return
  end

  text = text or CreateHealthText(plate)
  if not text then return end

  local pct = GetPercentFromBar(plate)
  if pct == nil then
    pct = GetPercentFromUnit(plate)
  end

  if pct == nil then
    text:Hide()
    return
  end

  if pct < 0 then pct = 0 end
  if pct > 100 then pct = 100 end

  text:SetText(tostring(pct) .. "%")
  text:Show()
end

-- Intentionally simple fallback: only reads values and updates text.
-- No SetScript calls on healthbar, no SetAlpha, no color changes.
local updater = CreateFrame("Frame")
local elapsed = 0
updater:SetScript("OnUpdate", function()
  elapsed = elapsed + arg1
  if elapsed < 0.10 then return end
  elapsed = 0

  local plate
  for plate in pairs(BNP.plates or {}) do
    if plate:IsShown() then
      UpdatePlate(plate)
    elseif plate.BNPHealthPercent then
      plate.BNPHealthPercent:Hide()
    end
  end
end)

function BNP:RefreshHealthPercent()
  local plate
  for plate in pairs(self.plates or {}) do
    if plate and plate:IsShown() then
      UpdatePlate(plate)
    elseif plate and plate.BNPHealthPercent then
      plate.BNPHealthPercent:Hide()
    end
  end
end
