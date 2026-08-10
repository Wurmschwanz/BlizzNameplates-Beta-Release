BNP = BNP or {}

-- Tank Mode for SuperWoW GUID nameplates.
-- GREEN = hostile NPC currently targets the player.
-- RED   = hostile NPC currently targets another unit.
-- Idle hostile NPCs keep their normal Blizzard color.

local GREEN_R, GREEN_G, GREEN_B = 0.00, 1.00, 0.00
local RED_R, RED_G, RED_B = 1.00, 0.00, 0.00

local playerGUID = nil

local function GetPlayerGUID()
  local exists, guid = UnitExists("player")
  if exists and guid then playerGUID = guid end
  return playerGUID
end

local function GetPlateGUID(plate)
  if not plate or not plate.GetName then return nil end
  local guid = plate:GetName(1)
  if guid and guid ~= "" then return guid end
  return nil
end

local function GetTargetGUID(guid)
  if not guid then return nil end
  local exists, targetGUID = UnitExists(guid .. "target")
  if exists then return targetGUID end
  return nil
end

local function GetBar(plate)
  return plate and (plate.healthbar or plate.healthBar) or nil
end

local function IsHostileNPC(guid)
  if not guid or not UnitExists(guid) then return false end
  if UnitIsPlayer(guid) then return false end
  return UnitCanAttack("player", guid) and true or false
end

local function RememberNormalColor(plate, bar)
  if plate.BNPTankActive then return end
  local r, g, b, a = bar:GetStatusBarColor()
  if r then plate.BNPNormalColor = { r, g, b, a or 1 } end
end

local function RestoreNormalColor(plate, bar)
  local c = plate.BNPNormalColor
  if c then bar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1) end
  plate.BNPTankActive = nil
  plate.BNPTankR = nil
  plate.BNPTankG = nil
  plate.BNPTankB = nil
end

local function ApplyTankColor(plate, bar, r, g, b)
  bar:SetStatusBarColor(r, g, b, 1)
  plate.BNPTankActive = true
  plate.BNPTankR = r
  plate.BNPTankG = g
  plate.BNPTankB = b
end

local function EnforceTankColor(plate)
  if not plate or not plate.BNPTankActive then return end
  local bar = GetBar(plate)
  if not bar or not plate.BNPTankR then return end

  local r, g, b = bar:GetStatusBarColor()
  if math.abs(r - plate.BNPTankR) > 0.01
    or math.abs(g - plate.BNPTankG) > 0.01
    or math.abs(b - plate.BNPTankB) > 0.01 then
    bar:SetStatusBarColor(plate.BNPTankR, plate.BNPTankG, plate.BNPTankB, 1)
  end
end

function BNP:UpdateTankModePlate(plate)
  if not plate or not plate:IsShown() then return end

  local bar = GetBar(plate)
  if not bar then return end

  if not self:IsTankModeEnabled() then
    RestoreNormalColor(plate, bar)
    return
  end

  local guid = GetPlateGUID(plate)
  if not IsHostileNPC(guid) then
    RestoreNormalColor(plate, bar)
    return
  end

  local myGUID = GetPlayerGUID()
  if not myGUID then return end

  RememberNormalColor(plate, bar)
  local targetGUID = GetTargetGUID(guid)

  if targetGUID and targetGUID == myGUID then
    ApplyTankColor(plate, bar, GREEN_R, GREEN_G, GREEN_B)
  elseif targetGUID then
    ApplyTankColor(plate, bar, RED_R, RED_G, RED_B)
  else
    RestoreNormalColor(plate, bar)
  end
end

function BNP:RefreshTankMode()
  local plate
  for plate in pairs(self.plates or {}) do
    if plate and plate:IsShown() then
      self:UpdateTankModePlate(plate)
    end
  end
end

function BNP:UpdateTankMode()
  self:RefreshTankMode()
end

function BNP:InstallTankMode()
  if self.BNPTankModeInstalled then return end
  if not self.libnameplate or not self.libnameplate.OnUpdate then return end

  GetPlayerGUID()

  table.insert(self.libnameplate.OnInit, function(plate)
    local current = plate or this
    if not current then return end

    local bar = GetBar(current)
    if bar and not current.BNPTankColorHooked then
      local old = bar:GetScript("OnValueChanged")
      bar:SetScript("OnValueChanged", function()
        if old then old() end
        EnforceTankColor(current)
      end)
      current.BNPTankColorHooked = true
    end
  end)

  table.insert(self.libnameplate.OnUpdate, function(plate, elapsed)
    local current = plate or this
    if not current then return end
    BNP:UpdateTankModePlate(current)
    EnforceTankColor(current)
  end)

  self.BNPTankModeInstalled = true
end
