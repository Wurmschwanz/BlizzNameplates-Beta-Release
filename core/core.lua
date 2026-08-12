BNP = BNP or {}
BNP.version = "1.0.4"
BNP.plates = BNP.plates or {}
BNP.detected = 0
BNP.debugEnabled = false

function BNP:Print(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Blizz Nameplates+:|r " .. tostring(msg))
  end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:SetScript("OnEvent", function()
  BNP_DB = BNP_DB or {}

  if BNP.InitConfig then BNP:InitConfig() end
  if BNP.CreateMinimapButton then BNP:CreateMinimapButton() end
  if BNP.InstallTankMode then BNP:InstallTankMode() end

  if BNP_DB.debugEnabled == nil then BNP_DB.debugEnabled = false end
  BNP.debugEnabled = BNP_DB.debugEnabled

  if CombatLogAdd and SpellInfo then
    BNP:Print(BNP.version .. " loaded. Standalone nameplates + SuperWoW tracking active.")
    if ShaguTweaks then
      BNP:ApplyShaguTweaksCompatibility()
      local count = 0
      local k
      for k in pairs(BNP.shaguCompat.patched or {}) do count = count + 1 end
      BNP:Print("ShaguTweaks compatibility active (" .. tostring(count) .. "/3 nameplate modules suppressed).")
    end
  else
    BNP:Print("ERROR: SuperWoW API not detected. Blizz Nameplates+ requires SuperWoW.")
  end
end)
