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
  frame:SetHeight(575)
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

  local version = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  version:SetPoint("TOP", title, "BOTTOM", 0, -4)
  version:SetText("Version " .. tostring(BNP.version or "?"))
  frame.versionText = version

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

  local scale = CreateSlider(frame, "Nameplate Scale", 0.70, 1.50, 0.05, -78)
  scale:SetScript("OnValueChanged", function()
    if not BNP_DB then return end
    local value = Round(this:GetValue(), 0.05)
    BNP_DB.nameplateScale = value
    getglobal(this:GetName() .. "Text"):SetText("Nameplate Scale: " .. string.format("%.2f", value))
    if BNP.ApplyNameplateScaleAll then BNP:ApplyNameplateScaleAll() end
  end)
  frame.scaleSlider = scale

  local icon = CreateSlider(frame, "Debuff Icon Size", 12, 32, 1, -133)
  icon:SetScript("OnValueChanged", function()
    if not BNP_DB then return end
    local value = math.floor(this:GetValue() + 0.5)
    BNP_DB.iconSize = value
    getglobal(this:GetName() .. "Text"):SetText("Debuff Icon Size: " .. value)
    if BNP.RefreshAllAuraLayouts then BNP:RefreshAllAuraLayouts() end
  end)
  frame.iconSlider = icon

  local castbarHeight = CreateSlider(frame, "Castbar Height", 4, 14, 1, -188)
  castbarHeight:SetScript("OnValueChanged", function()
    if not BNP_DB then return end
    local value = math.floor(this:GetValue() + 0.5)
    BNP_DB.castbarHeight = value
    getglobal(this:GetName() .. "Text"):SetText("Castbar Height: " .. value)
    if BNP.RefreshCastbarHeights then BNP:RefreshCastbarHeights() end
  end)
  frame.castbarHeightSlider = castbarHeight

  local classColors = CreateCheck(frame, "Class Colors", -226, function()
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

  local castbars = CreateCheck(frame, "Castbars", -256, function()
    local enabled = this:GetChecked() and true or false
    if BNP.SetCastbarsEnabled then
      BNP:SetCastbarsEnabled(enabled)
    else
      BNP_DB.castbars = enabled
    end
  end)
  frame.castbarsCheck = castbars

  local tank = CreateCheck(frame, "Tank Mode", -286, function()
    BNP_DB.tankMode = this:GetChecked() and true or false
    if BNP.UpdateTankMode then BNP:UpdateTankMode() end
  end)
  frame.tankCheck = tank

  local healthTextLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  healthTextLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -318)
  healthTextLabel:SetText("Health Text")

  local healthTextDropdown = CreateFrame("Frame", "BNPHealthTextDropdown", frame, "UIDropDownMenuTemplate")
  healthTextDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -330)
  UIDropDownMenu_SetWidth(150, healthTextDropdown)

  local healthModeLabels = {
    off = "Off",
    percent = "Percent",
    hp = "HP",
    both = "HP + Percent",
  }

  local function SetHealthTextMode(mode)
    if not healthModeLabels[mode] then mode = "off" end

    BNP_DB.healthText = mode
    -- Keep the legacy setting synchronized for backwards compatibility.
    BNP_DB.healthPercent = (mode == "percent" or mode == "both")

    UIDropDownMenu_SetSelectedValue(healthTextDropdown, mode)
    UIDropDownMenu_SetText(healthModeLabels[mode], healthTextDropdown)

    if BNP.RefreshHealthPercent then BNP:RefreshHealthPercent() end
  end

  UIDropDownMenu_Initialize(healthTextDropdown, function()
    local modes = { "off", "percent", "hp", "both" }
    local i
    for i = 1, table.getn(modes) do
      local mode = modes[i]
      local info = {}
      info.text = healthModeLabels[mode]
      info.value = mode
      info.func = function()
        SetHealthTextMode(this.value)
      end
      info.checked = (BNP:GetHealthTextMode() == mode)
      UIDropDownMenu_AddButton(info)
    end
  end)

  frame.healthTextDropdown = healthTextDropdown
  frame.SetHealthTextMode = SetHealthTextMode

  local targetFocus = CreateCheck(frame, "Target Glow", -374, function()
    BNP_DB.targetFocus = this:GetChecked() and true or false
    if BNP.RefreshTargetFocus then BNP:RefreshTargetFocus() end
  end)
  frame.targetFocusCheck = targetFocus

  local glowColorLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  glowColorLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -406)
  glowColorLabel:SetText("Target Glow Color")

  local glowColorDropdown = CreateFrame("Frame", "BNPTargetGlowColorDropdown", frame, "UIDropDownMenuTemplate")
  glowColorDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -418)
  UIDropDownMenu_SetWidth(150, glowColorDropdown)

  local glowColorLabels = {
    white = "White",
    gold = "Gold",
    blue = "Blue",
    green = "Green",
    red = "Red",
    purple = "Purple",
  }

  local function SetTargetGlowColor(color)
    if not glowColorLabels[color] then color = "white" end

    BNP_DB.targetGlowColor = color
    UIDropDownMenu_SetSelectedValue(glowColorDropdown, color)
    UIDropDownMenu_SetText(glowColorLabels[color], glowColorDropdown)

    if BNP.RefreshTargetFocus then BNP:RefreshTargetFocus() end
  end

  UIDropDownMenu_Initialize(glowColorDropdown, function()
    local colors = { "white", "gold", "blue", "green", "red", "purple" }
    local i
    for i = 1, table.getn(colors) do
      local color = colors[i]
      local info = {}
      info.text = glowColorLabels[color]
      info.value = color
      info.func = function()
        SetTargetGlowColor(this.value)
      end
      info.checked = ((BNP_DB and BNP_DB.targetGlowColor) or "white") == color
      UIDropDownMenu_AddButton(info)
    end
  end)

  frame.glowColorDropdown = glowColorDropdown
  frame.SetTargetGlowColor = SetTargetGlowColor

  local targetOnTop = CreateCheck(frame, "Target Plate on Top", -462, function()
    BNP_DB.targetOnTop = this:GetChecked() and true or false
    if BNP.RefreshTargetOnTop then BNP:RefreshTargetOnTop() end
  end)
  frame.targetOnTopCheck = targetOnTop

  local note = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  note:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -502)
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
  if frame.healthTextDropdown then
    local mode = self:GetHealthTextMode()
    UIDropDownMenu_SetSelectedValue(frame.healthTextDropdown, mode)
    local labels = { off = "Off", percent = "Percent", hp = "HP", both = "HP + Percent" }
    UIDropDownMenu_SetText(labels[mode] or "Off", frame.healthTextDropdown)
  end
  frame.targetFocusCheck:SetChecked(self:IsTargetFocusEnabled())

  if frame.glowColorDropdown then
    local _, _, _, color = self:GetTargetGlowColor()
    local labels = {
      white = "White",
      gold = "Gold",
      blue = "Blue",
      green = "Green",
      red = "Red",
      purple = "Purple",
    }
    UIDropDownMenu_SetSelectedValue(frame.glowColorDropdown, color or "white")
    UIDropDownMenu_SetText(labels[color] or "White", frame.glowColorDropdown)
  end

  frame.targetOnTopCheck:SetChecked(self:IsTargetOnTopEnabled())
  frame.versionText:SetText("Version " .. tostring(self.version or "?"))
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

  BNP_DB = BNP_DB or {}
  if BNP_DB.minimapAngle == nil then BNP_DB.minimapAngle = 225 end

  local button = CreateFrame("Button", "BNPMinimapButton", Minimap)
  button:SetWidth(31)
  button:SetHeight(31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 8)
  button:RegisterForClicks("LeftButtonUp")
  button:RegisterForDrag("LeftButton")
  button:EnableMouse(true)
  button:SetMovable(true)

  -- Classic round minimap-button background.
  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetWidth(22)
  bg:SetHeight(22)
  bg:SetPoint("CENTER", button, "CENTER", 0, 0)
  button.bg = bg

  -- Addon identity: simple BN+ lettering instead of a spell/item icon.
  -- Rendered directly by the client, so no external texture file is needed.
  local iconBG = button:CreateTexture(nil, "ARTWORK")
  iconBG:SetTexture(0.03, 0.03, 0.03, 1)
  iconBG:SetWidth(20)
  iconBG:SetHeight(20)
  iconBG:SetPoint("CENTER", button, "CENTER", 0, 0)
  button.iconBG = iconBG

  local label = button:CreateFontString(nil, "OVERLAY")
  label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  label:SetPoint("CENTER", button, "CENTER", 0, 0)
  label:SetText("BN+")
  label:SetTextColor(0.20, 0.60, 1.00)
  button.label = label

  -- Standard Blizzard circular minimap border.
  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetWidth(54)
  border:SetHeight(54)
  border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
  button.border = border

  local highlight = button:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  highlight:SetBlendMode("ADD")
  highlight:SetAllPoints(button)
  button.highlight = highlight

  local function UpdatePosition()
    local angle = tonumber(BNP_DB.minimapAngle) or 225
    local radius = 78
    local rad = math.rad(angle)

    button:ClearAllPoints()
    button:SetPoint(
      "CENTER",
      Minimap,
      "CENTER",
      math.cos(rad) * radius,
      math.sin(rad) * radius
    )
  end

  local function UpdateAngleFromCursor()
    local mx, my = Minimap:GetCenter()
    local scale = 1
    if UIParent.GetEffectiveScale then
      scale = UIParent:GetEffectiveScale() or 1
    elseif UIParent.GetScale then
      scale = UIParent:GetScale() or 1
    end
    local cx, cy = GetCursorPosition()
    cx = cx / scale
    cy = cy / scale

    local dx = cx - mx
    local dy = cy - my

    local angle
    if math.atan2 then
      angle = math.deg(math.atan2(dy, dx))
    else
      if dx == 0 then
        angle = dy >= 0 and 90 or -90
      else
        angle = math.deg(math.atan(dy / dx))
        if dx < 0 then angle = angle + 180 end
      end
    end
    BNP_DB.minimapAngle = angle
    UpdatePosition()
  end

  button:SetScript("OnDragStart", function()
    this:SetScript("OnUpdate", UpdateAngleFromCursor)
  end)

  button:SetScript("OnDragStop", function()
    this:SetScript("OnUpdate", nil)
    UpdateAngleFromCursor()
  end)

  button:SetScript("OnClick", function()
    BNP:ToggleOptions()
  end)

  button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("Blizz Nameplates+")
    GameTooltip:AddLine("Left-click: Open settings", 1, 1, 1)
    GameTooltip:AddLine("Drag: Move minimap button", 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  UpdatePosition()
  self.minimapButton = button
end
