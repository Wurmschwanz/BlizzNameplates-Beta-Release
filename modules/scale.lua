BNP = BNP or {}

local MIN_SCALE = 0.50
local MAX_SCALE = 1.50
local DEFAULT_SCALE = 1.00

local function Clamp(value)
  if value < MIN_SCALE then return MIN_SCALE end
  if value > MAX_SCALE then return MAX_SCALE end
  return value
end

function BNP:GetNameplateScale()
  BNP_DB = BNP_DB or {}
  return Clamp(tonumber(BNP_DB.nameplateScale) or DEFAULT_SCALE)
end

local function EffectiveScale()
  local uiScale = 1.0
  if UIParent and UIParent.GetScale then
    uiScale = UIParent:GetScale() or 1.0
  end
  return uiScale * BNP:GetNameplateScale()
end

local function EnsureScaleWrapper(plate)
  if not plate or plate.BNPScaleWrapper then return end

  local originalWidth = plate:GetWidth()
  local originalHeight = plate:GetHeight()

  local wrapper = CreateFrame("Frame", nil, plate)
  wrapper:SetAllPoints(plate)
  wrapper.plate = plate
  wrapper.originalWidth = originalWidth
  wrapper.originalHeight = originalHeight

  plate.BNPScaleWrapper = wrapper

  -- Match ShaguTweaks: move Blizzard nameplate visuals into a child frame.
  -- Never SetScale() on the original WorldFrame nameplate itself, otherwise
  -- its projected screen position shifts toward the unit's feet.
  if plate.healthbar then
    plate.healthbar:SetParent(wrapper)
    plate.healthbar:SetFrameLevel(1)
  end

  local regions = { plate:GetRegions() }
  local i, object
  for i, object in pairs(regions) do
    if object and object.SetParent then
      object:SetParent(wrapper)
    end
  end
end

function BNP:ApplyNameplateScale(plate)
  if not plate then return end
  EnsureScaleWrapper(plate)

  local wrapper = plate.BNPScaleWrapper
  if not wrapper then return end

  local scale = EffectiveScale()
  wrapper:SetScale(scale)

  -- ShaguTweaks also adjusts the original frame bounds so Blizzard's world
  -- positioning remains correct while the child visuals honor UI scale.
  plate:SetWidth(wrapper.originalWidth * scale)
  plate:SetHeight(wrapper.originalHeight * scale)
end

function BNP:ApplyNameplateScaleAll()
  local plate
  for plate in pairs(self.plates) do
    self:ApplyNameplateScale(plate)
  end
end

function BNP:SetNameplateScale(value)
  value = tonumber(value)
  if not value then
    self:Print("Usage: /bnp scale 0.5-1.5")
    return
  end

  value = Clamp(value)
  BNP_DB = BNP_DB or {}
  BNP_DB.nameplateScale = value
  self:ApplyNameplateScaleAll()

  self:Print("Nameplate scale multiplier set to " .. tostring(value) .. ".")
end

function BNP:ResetNameplateScale()
  BNP_DB = BNP_DB or {}
  BNP_DB.nameplateScale = DEFAULT_SCALE
  self:ApplyNameplateScaleAll()
  self:Print("Nameplate scale multiplier reset to 1.0 (Shagu/UI scale behavior).")
end

if BNP.libnameplate then
  table.insert(BNP.libnameplate.OnInit, function(plate)
    local current = plate or this
    if not current then return end
    BNP:ApplyNameplateScale(current)
  end)

  table.insert(BNP.libnameplate.OnShow, function(plate)
    local current = plate or this
    if not current then return end
    BNP:ApplyNameplateScale(current)
  end)
end
