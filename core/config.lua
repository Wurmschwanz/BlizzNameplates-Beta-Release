BNP = BNP or {}

BNP.defaults = BNP.defaults or {
  nameplateScale = 1.0,
  iconSize = 18,
  tankMode = false,
  classColors = true,
  castbars = true,
  castbarHeight = 6,
  minimapAngle = 225,
  healthPercent = false,
  healthText = "off",
  targetFocus = true,
  targetGlowColor = "white",
  targetOnTop = true,
}

function BNP:InitConfig()
  BNP_DB = BNP_DB or {}

  if BNP_DB.nameplateScale == nil then BNP_DB.nameplateScale = self.defaults.nameplateScale end
  if BNP_DB.iconSize == nil then BNP_DB.iconSize = self.defaults.iconSize end
  if BNP_DB.tankMode == nil then BNP_DB.tankMode = self.defaults.tankMode end
  if BNP_DB.classColors == nil then BNP_DB.classColors = self.defaults.classColors end
  if BNP_DB.castbars == nil then BNP_DB.castbars = self.defaults.castbars end
  if BNP_DB.castbarHeight == nil then BNP_DB.castbarHeight = self.defaults.castbarHeight end
  if BNP_DB.minimapAngle == nil then BNP_DB.minimapAngle = self.defaults.minimapAngle end
  if BNP_DB.healthPercent == nil then BNP_DB.healthPercent = self.defaults.healthPercent end
  if BNP_DB.healthText == nil then
    -- Backwards-compatible migration from the old Health % checkbox.
    BNP_DB.healthText = BNP_DB.healthPercent and "percent" or self.defaults.healthText
  end
  if BNP_DB.targetFocus == nil then BNP_DB.targetFocus = self.defaults.targetFocus end
  if BNP_DB.targetGlowColor == nil then BNP_DB.targetGlowColor = self.defaults.targetGlowColor end
  if BNP_DB.targetOnTop == nil then BNP_DB.targetOnTop = self.defaults.targetOnTop end
end

function BNP:GetNameplateScale()
  return (BNP_DB and tonumber(BNP_DB.nameplateScale)) or self.defaults.nameplateScale
end

function BNP:GetIconSize()
  return (BNP_DB and tonumber(BNP_DB.iconSize)) or self.defaults.iconSize
end

function BNP:IsTankModeEnabled()
  return BNP_DB and BNP_DB.tankMode and true or false
end

function BNP:AreClassColorsEnabled()
  return not BNP_DB or BNP_DB.classColors ~= false
end

function BNP:AreCastbarsEnabled()
  return not BNP_DB or BNP_DB.castbars ~= false
end

function BNP:GetCastbarHeight()
  local value = (BNP_DB and tonumber(BNP_DB.castbarHeight)) or self.defaults.castbarHeight
  if value < 4 then value = 4 end
  if value > 14 then value = 14 end
  return value
end

function BNP:GetHealthTextMode()
  local mode = (BNP_DB and BNP_DB.healthText) or self.defaults.healthText or "off"
  if mode ~= "off" and mode ~= "percent" and mode ~= "hp" and mode ~= "both" then
    mode = "off"
  end
  return mode
end

function BNP:IsHealthPercentEnabled()
  local mode = self:GetHealthTextMode()
  return mode == "percent" or mode == "both"
end

function BNP:IsHealthTextEnabled()
  return self:GetHealthTextMode() ~= "off"
end

function BNP:IsTargetFocusEnabled()
  return not BNP_DB or BNP_DB.targetFocus ~= false
end

function BNP:IsTargetOnTopEnabled()
  return not BNP_DB or BNP_DB.targetOnTop ~= false
end

function BNP:GetTargetGlowColor()
  local key = (BNP_DB and BNP_DB.targetGlowColor) or self.defaults.targetGlowColor or "white"

  local colors = {
    white  = { 1.00, 1.00, 1.00 },
    gold   = { 1.00, 0.82, 0.10 },
    blue   = { 0.25, 0.55, 1.00 },
    green  = { 0.25, 1.00, 0.35 },
    red    = { 1.00, 0.20, 0.20 },
    purple = { 0.75, 0.35, 1.00 },
  }

  local c = colors[key] or colors.white
  return c[1], c[2], c[3], key
end
