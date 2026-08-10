BNP = BNP or {}

local function Round(value, step)
  return math.floor((value / step) + 0.5) * step
end

local sliderCount = 0
local function CreateSlider(parent, label, minValue, maxValue, step, y)
  sliderCount = sliderCount + 1
  local slider = CreateFrame("Slider", "BNPOptionsSlider" .. sliderCount, parent, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 28, y)
  slider:SetWidth(220)
  slider:SetHeight(16)
  slider:SetMinMaxValues(minValue, maxValue)
  slider:SetValueStep(step)
  getglobal(slider:GetName() .. "Low"):SetText(tostring(minValue))
  getglobal(slider:GetName() .. "High"):SetText(tostring(maxValue))
  getglobal(slider:GetName() .. "Text"):SetText(label)
  return slider
end

local function CreateCheck(parent, label, y, onclick)
  local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  check:SetPoint("TOPLEFT", parent, "TOPLEFT", 22, y)
  check:SetWidth(24)
  check:SetHeight(24)

  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("LEFT", check, "RIGHT", 4, 0)
  text:SetText(label)

  check:SetScript("OnClick", onclick)
  return check
end

function BNP:CreateOptions()
  if self.optionsFrame then return end

  local frame = CreateFrame("Frame", "BNPOptionsFrame", UIParent)
  frame:SetWidth(290)
  frame:SetHeight(365)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
  frame:SetFrameStrata("DIALOG")
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  frame:Hide()

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -18)
  title:SetText("Blizz Nameplates+")

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

  local scale = CreateSlider(frame, "Nameplate Scale", 0.70, 1.50, 0.05, -65)
  scale:SetScript("OnValueChanged", function()
    if not BNP_DB then return end
    local value = Round(this:GetValue(), 0.05)
    BNP_DB.nameplateScale = value
    getglobal(this:GetName() .. "Text"):SetText("Nameplate Scale: " .. string.format("%.2f", value))
    if BNP.ApplyNameplateScaleAll then BNP:ApplyNameplateScaleAll() end
  end)
  frame.scaleSlider = scale

  local icon = CreateSlider(frame, "Debuff Icon Size", 12, 32, 1, -120)
  icon:SetScript("OnValueChanged", function()
    if not BNP_DB then return end
    local value = math.floor(this:GetValue() + 0.5)
    BNP_DB.iconSize = value
    getglobal(this:GetName() .. "Text"):SetText("Debuff Icon Size: " .. value)
    if BNP.RefreshAllAuraLayouts then BNP:RefreshAllAuraLayouts() end
  end)
  frame.iconSlider = icon

  local castbarHeight = CreateSlider(frame, "Castbar Height", 4, 14, 1, -175)
  castbarHeight:SetScript("OnValueChanged", function()
    if not BNP_DB then return end
    local value = math.floor(this:GetValue() + 0.5)
    BNP_DB.castbarHeight = value
    getglobal(this:GetName() .. "Text"):SetText("Castbar Height: " .. value)
    if BNP.RefreshCastbarHeights then BNP:RefreshCastbarHeights() end
  end)
  frame.castbarHeightSlider = castbarHeight

  local classColors = CreateCheck(frame, "Class Colors", -213, function()
    BNP_DB.classColors = this:GetChecked() and true or false
    if BNP_DB.classColors then
      local plate
      for plate in pairs(BNP.plates or {}) do
        plate.BNPClassColorApplied = nil
        plate.BNPClassR = nil
        plate.BNPClassG = nil
        plate.BNPClassB = nil
      end
    end
  end)
  frame.classColorsCheck = classColors

  local castbars = CreateCheck(frame, "Castbars", -243, function()
    local enabled = this:GetChecked() and true or false
    if BNP.SetCastbarsEnabled then
      BNP:SetCastbarsEnabled(enabled)
    else
      BNP_DB.castbars = enabled
    end
  end)
  frame.castbarsCheck = castbars

  local tank = CreateCheck(frame, "Tank Mode", -273, function()
    BNP_DB.tankMode = this:GetChecked() and true or false
    if BNP.UpdateTankMode then BNP:UpdateTankMode() end
  end)
  frame.tankCheck = tank

  local note = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  note:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -313)
  note:SetWidth(235)
  note:SetJustifyH("LEFT")
  note:SetText("Changes are applied immediately.\nTank Mode: green = targeting you, red = targeting someone else.")

  self.optionsFrame = frame
end

function BNP:SyncOptions()
  self:CreateOptions()
  local frame = self.optionsFrame
  frame.scaleSlider:SetValue(self:GetNameplateScale())
  frame.iconSlider:SetValue(self:GetIconSize())
  frame.castbarHeightSlider:SetValue(self:GetCastbarHeight())
  frame.classColorsCheck:SetChecked(self:AreClassColorsEnabled())
  frame.castbarsCheck:SetChecked(self:AreCastbarsEnabled())
  frame.tankCheck:SetChecked(self:IsTankModeEnabled())
end

function BNP:ToggleOptions()
  self:SyncOptions()
  if self.optionsFrame:IsShown() then
    self.optionsFrame:Hide()
  else
    self.optionsFrame:Show()
  end
end

function BNP:CreateMinimapButton()
  if self.minimapButton then return end

  local button = CreateFrame("Button", "BNPMinimapButton", Minimap)
  button:SetWidth(28)
  button:SetHeight(28)
  button:SetFrameStrata("MEDIUM")
  button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -2, -2)
  button:SetNormalTexture("Interface\\Icons\\Spell_Shadow_CurseOfTounges")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  button:RegisterForClicks("LeftButtonUp")

  button:SetScript("OnClick", function()
    BNP:ToggleOptions()
  end)

  button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("Blizz Nameplates+")
    GameTooltip:AddLine("Click to open settings.", 1, 1, 1)
    GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  self.minimapButton = button
end
