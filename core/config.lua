BNP = BNP or {}

BNP.defaults = BNP.defaults or {
  nameplateScale = 1.0,
  iconSize = 18,
  tankMode = false,
  classColors = true,
  castbars = true,
  castbarHeight = 6,
}

function BNP:InitConfig()
  BNP_DB = BNP_DB or {}

  if BNP_DB.nameplateScale == nil then BNP_DB.nameplateScale = self.defaults.nameplateScale end
  if BNP_DB.iconSize == nil then BNP_DB.iconSize = self.defaults.iconSize end
  if BNP_DB.tankMode == nil then BNP_DB.tankMode = self.defaults.tankMode end
  if BNP_DB.classColors == nil then BNP_DB.classColors = self.defaults.classColors end
  if BNP_DB.castbars == nil then BNP_DB.castbars = self.defaults.castbars end
  if BNP_DB.castbarHeight == nil then BNP_DB.castbarHeight = self.defaults.castbarHeight end
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
