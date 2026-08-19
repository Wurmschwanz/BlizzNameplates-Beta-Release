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

local function CaptureAnchorState(object, plate, wrapper)
  if not object or not object.GetPoint then return nil end

  local state = {
    object = object,
    points = {},
  }

  local count = 1
  if object.GetNumPoints then
    count = object:GetNumPoints() or 1
    if count < 1 then count = 1 end
  end

  local i
  for i = 1, count do
    local point, relativeTo, relativePoint, x, y = object:GetPoint(i)
    if point then
      if relativeTo == plate then
        relativeTo = wrapper
      end

      state.points[table.getn(state.points) + 1] = {
        point = point,
        relativeTo = relativeTo or wrapper,
        relativePoint = relativePoint or point,
        x = x or 0,
        y = y or 0,
      }
    end
  end

  return state
end

local function AnchorStateMatches(state)
  if not state or not state.object or not state.object.GetPoint then return false end

  local object = state.object
  local expectedCount = table.getn(state.points)
  local currentCount = expectedCount

  if object.GetNumPoints then
    currentCount = object:GetNumPoints() or 0
  end

  if currentCount ~= expectedCount then
    return false
  end

  local i
  for i = 1, expectedCount do
    local expected = state.points[i]
    local point, relativeTo, relativePoint, x, y = object:GetPoint(i)

    if point ~= expected.point
      or relativeTo ~= expected.relativeTo
      or relativePoint ~= expected.relativePoint
      or math.abs((x or 0) - expected.x) > 0.01
      or math.abs((y or 0) - expected.y) > 0.01 then
      return false
    end
  end

  return true
end

local function RestoreAnchorState(state, wrapper)
  if not state or not state.object then return end

  local object = state.object

  if object.GetParent and object.SetParent and object:GetParent() ~= wrapper then
    object:SetParent(wrapper)
  end

  -- Do nothing in the common case. Blizzard normally only rewrites a subset
  -- of nameplate anchors while moving, most notably the level FontString.
  if AnchorStateMatches(state) then return end

  if not object.ClearAllPoints or not object.SetPoint then return end

  object:ClearAllPoints()

  local i
  for i = 1, table.getn(state.points) do
    local p = state.points[i]
    object:SetPoint(
      p.point,
      p.relativeTo or wrapper,
      p.relativePoint or p.point,
      p.x,
      p.y
    )
  end
end

local VALID_STRATA = {
  BACKGROUND=true, LOW=true, MEDIUM=true, HIGH=true,
  DIALOG=true, FULLSCREEN=true, FULLSCREEN_DIALOG=true, TOOLTIP=true,
}

local function RestoreOriginalHitRect(plate)
  if not plate or not plate.SetHitRectInsets or not plate.BNPOriginalHitRect then return end
  local base = plate.BNPOriginalHitRect
  plate:SetHitRectInsets(base.left, base.right, base.top, base.bottom)
end

local function CaptureOriginalHitRect(plate)
  if not plate or plate.BNPOriginalHitRect then return end

  local left, right, top, bottom = 0, 0, 0, 0
  if plate.GetHitRectInsets then
    local ok, l, r, t, b = pcall(plate.GetHitRectInsets, plate)
    if ok then
      left = tonumber(l) or 0
      right = tonumber(r) or 0
      top = tonumber(t) or 0
      bottom = tonumber(b) or 0
    end
  end

  plate.BNPOriginalHitRect = {
    left = left,
    right = right,
    top = top,
    bottom = bottom,
  }
end

local function EnsureYOffsetClickProxy(plate, wrapper)
  if not plate or not wrapper then return nil end
  if plate.BNPYOffsetClickProxy then return plate.BNPYOffsetClickProxy end

  -- A child hit rectangle cannot reliably live far outside the projected
  -- Blizzard nameplate. Use an independent WorldFrame button at the actual
  -- visual position instead. It is mouse-only and draws nothing.
  local proxy = CreateFrame("Button", nil, WorldFrame)
  proxy.plate = plate
  proxy:EnableMouse(true)
  if proxy.RegisterForClicks then
    proxy:RegisterForClicks("LeftButtonUp")
  end

  local strata = plate.GetFrameStrata and plate:GetFrameStrata() or nil
  if not VALID_STRATA[strata] then strata = "BACKGROUND" end
  proxy:SetFrameStrata(strata)
  if proxy.SetFrameLevel and plate.GetFrameLevel then
    proxy:SetFrameLevel((plate:GetFrameLevel() or 0) + 20)
  end

  proxy:ClearAllPoints()
  proxy:SetPoint("TOPLEFT", wrapper, "TOPLEFT", 0, 0)
  proxy:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", 0, 0)

  proxy:SetScript("OnClick", function()
    local currentPlate = this and this.plate or plate
    if not currentPlate or not currentPlate:IsShown() then return end
    if not TargetUnit or not currentPlate.GetName then return end

    local token = currentPlate:GetName(1)
    if token and UnitExists and UnitExists(token) then
      TargetUnit(token)
    end
  end)

  proxy:Hide()
  plate.BNPYOffsetClickProxy = proxy
  return proxy
end

local function ApplyYOffsetClickProxy(plate, wrapper, offset)
  CaptureOriginalHitRect(plate)
  RestoreOriginalHitRect(plate)

  local proxy = EnsureYOffsetClickProxy(plate, wrapper)
  if not proxy then return end

  if offset and offset > 0 and plate:IsShown() then
    local strata = plate.GetFrameStrata and plate:GetFrameStrata() or nil
    if not VALID_STRATA[strata] then strata = "BACKGROUND" end
    if proxy:GetFrameStrata() ~= strata then proxy:SetFrameStrata(strata) end
    if proxy.SetFrameLevel and plate.GetFrameLevel then
      proxy:SetFrameLevel((plate:GetFrameLevel() or 0) + 20)
    end
    proxy:Show()
  else
    proxy:Hide()
  end
end

local function ApplyWrapperOffset(plate, wrapper)
  if not plate or not wrapper then return end

  local offset = 0
  if BNP.GetNameplateYOffset then
    offset = BNP:GetNameplateYOffset()
  end

  -- Move only the child visual container. The WorldFrame-projected Blizzard
  -- nameplate itself keeps its original anchor and can continue to be
  -- repositioned by the client every frame.
  wrapper:ClearAllPoints()
  wrapper:SetPoint("TOPLEFT", plate, "TOPLEFT", 0, offset)
  wrapper:SetPoint("BOTTOMRIGHT", plate, "BOTTOMRIGHT", 0, offset)

  ApplyYOffsetClickProxy(plate, wrapper, offset)
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
  wrapper.BNPAnchorStates = {}

  plate.BNPScaleWrapper = wrapper

  -- The click proxy is parented to WorldFrame so it must be hidden explicitly
  -- when Blizzard hides/recycles this projected nameplate.
  if not plate.BNPYOffsetHideHook then
    local oldOnHide = plate:GetScript("OnHide")
    plate:SetScript("OnHide", function(self)
      local current = self or this or plate
      if oldOnHide then oldOnHide(current) end
      if current and current.BNPYOffsetClickProxy then
        current.BNPYOffsetClickProxy:Hide()
      end
    end)
    plate.BNPYOffsetHideHook = true
  end

  -- Capture the ORIGINAL Blizzard anchors before changing parentage.
  -- Those stored anchors become BNP's authoritative visual layout whenever
  -- Y-offset is enabled.
  if plate.healthbar then
    local state = CaptureAnchorState(plate.healthbar, plate, wrapper)
    if state then
      table.insert(wrapper.BNPAnchorStates, state)
    end

    plate.healthbar:SetParent(wrapper)
    RestoreAnchorState(state, wrapper)
    plate.healthbar:SetFrameLevel(1)
  end

  local regions = { plate:GetRegions() }
  local i, object
  for i, object in pairs(regions) do
    if object and object.SetParent then
      local state = CaptureAnchorState(object, plate, wrapper)
      if state then
        table.insert(wrapper.BNPAnchorStates, state)
      end

      object:SetParent(wrapper)
      RestoreAnchorState(state, wrapper)
    end
  end

  ApplyWrapperOffset(plate, wrapper)
end

function BNP:ApplyNameplateScale(plate)
  if not plate then return end
  EnsureScaleWrapper(plate)

  local wrapper = plate.BNPScaleWrapper
  if not wrapper then return end

  local scale = EffectiveScale()
  wrapper:SetScale(scale)
  ApplyWrapperOffset(plate, wrapper)

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

function BNP:ApplyNameplateYOffsetAll()
  local plate
  for plate in pairs(self.plates or {}) do
    if plate then
      self:ApplyNameplateScale(plate)
    end
  end
end

function BNP:MaintainNameplateYOffset(plate)
  if not plate or not plate:IsShown() then return end
  if not self.GetNameplateYOffset or self:GetNameplateYOffset() <= 0 then return end

  EnsureScaleWrapper(plate)

  local wrapper = plate.BNPScaleWrapper
  if not wrapper then return end

  -- Never rediscover regions through plate:GetRegions() here. Once BNP moves
  -- Blizzard regions into the wrapper they are no longer guaranteed to be
  -- returned by plate:GetRegions(). Keep and maintain the original region
  -- objects captured during wrapper creation instead.
  local states = wrapper.BNPAnchorStates or {}
  local i
  for i = 1, table.getn(states) do
    RestoreAnchorState(states[i], wrapper)
  end

  ApplyWrapperOffset(plate, wrapper)
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
