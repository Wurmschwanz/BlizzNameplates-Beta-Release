BNP = BNP or {}

local NON_TARGET_ALPHA = 0.55

local function GetPlateGUID(plate)
  if not plate or not plate.GetName then return nil end
  local token = plate:GetName(1)
  if not token then return nil end
  local exists, guid = UnitExists(token)
  if exists and guid then return guid end
  return token
end

local function GetTargetGUID()
  local exists, guid = UnitExists("target")
  if exists and guid then return guid end
  return nil
end

local function IsForeignTagged(plate)
  if not plate or not plate.GetName then return false end
  local token = plate:GetName(1)
  if not token then return false end

  local exists = UnitExists(token)
  if not exists then return false end

  if UnitCanAttack and not UnitCanAttack("player", token) then
    return false
  end

  if not UnitIsTapped or not UnitIsTapped(token) then
    return false
  end

  if UnitIsTappedByPlayer and UnitIsTappedByPlayer(token) then
    return false
  end

  return true
end

local function DesiredAlpha(plate)
  -- No selected target: keep all nameplates fully visible.
  local targetGUID = GetTargetGUID()
  if not targetGUID then return 1 end

  -- Current target always stays fully visible.
  local plateGUID = GetPlateGUID(plate)
  if plateGUID and plateGUID == targetGUID then
    return 1
  end

  -- Only non-target plates use the configured alpha.
  if BNP.GetNonTargetAlpha then
    return BNP:GetNonTargetAlpha()
  end

  return 1
end

local function SetLevelSafe(frame, level)
  if frame and frame.SetFrameLevel and level then
    if frame:GetFrameLevel() ~= level then
      frame:SetFrameLevel(level)
    end
  end
end

local function ApplyTargetFrameLevel(plate)
  if not plate or not plate:IsShown() then return end

  -- IMPORTANT:
  -- Never change the FrameStrata of projected Vanilla nameplates.
  -- Their native client/world layer keeps them behind Blizzard UI frames.
  -- Target Plate on Top is therefore implemented only with FrameLevel.

  if plate.BNPBaseFrameLevel == nil then
    plate.BNPBaseFrameLevel = plate:GetFrameLevel() or 0
  end

  local wrapper = plate.BNPScaleWrapper
  if wrapper and plate.BNPBaseWrapperLevel == nil then
    plate.BNPBaseWrapperLevel = wrapper:GetFrameLevel() or plate.BNPBaseFrameLevel
  end

  local target = false
  if BNP.IsTargetOnTopEnabled and BNP:IsTargetOnTopEnabled() then
    local targetGUID = GetTargetGUID()
    local plateGUID = GetPlateGUID(plate)
    target = targetGUID and plateGUID and targetGUID == plateGUID
  end

  local plateLevel = plate.BNPBaseFrameLevel
  local wrapperLevel = plate.BNPBaseWrapperLevel or plateLevel

  if target then
    -- Raise the target only relative to other nameplates while preserving the
    -- native projected-nameplate strata beneath the Blizzard interface.
    plateLevel = plateLevel + 50
    wrapperLevel = wrapperLevel + 50
  end

  SetLevelSafe(plate, plateLevel)
  if wrapper then
    SetLevelSafe(wrapper, wrapperLevel)
  end
end

local function ApplyForeignTagVisual(plate)
  if not plate or not plate:IsShown() then return end

  local bar = plate.healthbar
  if not bar or not bar.SetStatusBarColor then return end

  local foreign = IsForeignTagged(plate)

  if foreign then
    if not plate.BNPForeignTagGrey then
      local r, g, b, a = bar:GetStatusBarColor()
      plate.BNPForeignTagOldR = r
      plate.BNPForeignTagOldG = g
      plate.BNPForeignTagOldB = b
      plate.BNPForeignTagOldA = a
      plate.BNPForeignTagGrey = true
    end

    -- Neutral grey: visually distinct from Target Focus transparency.
    bar:SetStatusBarColor(0.45, 0.45, 0.45, plate.BNPForeignTagOldA or 1)
  elseif plate.BNPForeignTagGrey then
    -- Restore the color that BNP/Shagu/class-color logic had before the mob
    -- became foreign-tagged. Clear state so future color changes can be learned.
    bar:SetStatusBarColor(
      plate.BNPForeignTagOldR or 1,
      plate.BNPForeignTagOldG or 0,
      plate.BNPForeignTagOldB or 0,
      plate.BNPForeignTagOldA or 1
    )
    plate.BNPForeignTagGrey = nil
    plate.BNPForeignTagOldR = nil
    plate.BNPForeignTagOldG = nil
    plate.BNPForeignTagOldB = nil
    plate.BNPForeignTagOldA = nil
  end
end

local function EnsureTargetGlow(plate)
  if not plate then return nil end
  if plate.BNPTargetGlow then return plate.BNPTargetGlow end

  local anchor = plate.healthbar or plate
  local visualParent = plate.BNPScaleWrapper or plate

  -- Same glow geometry/position as the known-good reference build.
  -- Only the draw parent changes: BACKGROUND of BNP's visual wrapper,
  -- so the actual nameplate visuals render above it.
  local glow = visualParent:CreateTexture(nil, "BACKGROUND")
  glow:SetTexture("Interface\\AddOns\\BlizzNameplatesPlus\\media\\shagu_target_glow.tga")
  glow:SetPoint("CENTER", anchor, "CENTER", 10, 0)

  -- ShaguPlates uses health width + 60 and health height + 30.
  -- Use the actual Blizzard/BNP bar size so this also follows BNP scaling.
  local width = anchor.GetWidth and anchor:GetWidth() or 100
  local height = anchor.GetHeight and anchor:GetHeight() or 10
  glow:SetWidth(width + 59)
  glow:SetHeight(height + 22)
  local r, g, b = 1, 1, 1
  if BNP.GetTargetGlowColor then
    r, g, b = BNP:GetTargetGlowColor()
  end
  glow:SetVertexColor(r, g, b, 1)
  glow:Hide()

  plate.BNPTargetGlow = glow
  return glow
end

local function ApplyTargetGlow(plate)
  if not plate or not plate:IsShown() then return end

  local glow = EnsureTargetGlow(plate)
  if not glow then return end

  local enabled = BNP.IsTargetFocusEnabled and BNP:IsTargetFocusEnabled()
  if not enabled then
    glow:Hide()
    return
  end

  local targetGUID = GetTargetGUID()
  local plateGUID = GetPlateGUID(plate)

  if targetGUID and plateGUID and targetGUID == plateGUID then
    local anchor = plate.healthbar or plate
    local width = anchor.GetWidth and anchor:GetWidth() or 100
    local height = anchor.GetHeight and anchor:GetHeight() or 10
    glow:ClearAllPoints()
    glow:SetPoint("CENTER", anchor, "CENTER", 10, 0)
    glow:SetWidth(width + 59)
    glow:SetHeight(height + 22)
    if BNP.GetTargetGlowColor then
      local r, g, b = BNP:GetTargetGlowColor()
      glow:SetVertexColor(r, g, b, 1)
    end
    glow:Show()
  else
    glow:Hide()
  end
end

local function ApplyTargetAlpha(plate)
  if not plate or not plate:IsShown() then return end
  local wanted = DesiredAlpha(plate)
  if plate:GetAlpha() ~= wanted then
    plate:SetAlpha(wanted)
  end
end

local function InstallAlphaGuard(plate)
  plate = plate or this
  if not plate or plate.BNPFullAlphaGuard then return end

  local oldOnUpdate = plate:GetScript("OnUpdate")
  plate:SetScript("OnUpdate", function()
    if oldOnUpdate then oldOnUpdate() end
    local current = this or plate

    -- Apply the optional Y-offset after Blizzard has had a chance to update
    -- the projected nameplate for this frame. This uses the OnUpdate BNP
    -- already needs for alpha/glow/target-level handling.
    if BNP.MaintainNameplateYOffset then
      BNP:MaintainNameplateYOffset(current)
    end

    ApplyTargetAlpha(current)
    ApplyTargetGlow(current)
    ApplyForeignTagVisual(current)
    ApplyTargetFrameLevel(current)
  end)

  plate.BNPFullAlphaGuard = true
  ApplyTargetAlpha(plate)
end

if BNP.libnameplate then
  table.insert(BNP.libnameplate.OnInit, function(plate)
    InstallAlphaGuard(plate or this)
  end)

  table.insert(BNP.libnameplate.OnShow, function(plate)
    local current = plate or this
    if not current then return end
    InstallAlphaGuard(current)
    ApplyTargetAlpha(current)
    ApplyTargetGlow(current)
    ApplyForeignTagVisual(current)
    ApplyTargetFrameLevel(current)
  end)
end

function BNP:RefreshTargetFocus()
  local plate
  for plate in pairs(self.plates or {}) do
    ApplyTargetAlpha(plate)
    ApplyTargetGlow(plate)
    ApplyForeignTagVisual(plate)
  end
end

function BNP:RefreshNonTargetAlpha()
  local plate
  for plate in pairs(self.plates or {}) do
    ApplyTargetAlpha(plate)
  end
end

function BNP:RefreshTargetOnTop()
  local plate
  for plate in pairs(self.plates or {}) do
    ApplyTargetFrameLevel(plate)
  end
end
