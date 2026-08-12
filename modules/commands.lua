SLASH_BLIZZNAMEPLATESPLUS1 = "/bnp"
SlashCmdList["BLIZZNAMEPLATESPLUS"] = function(msg)
  msg = string.lower(msg or "")

  if msg == "" or msg == "config" or msg == "options" then
    if BNP.ToggleOptions then BNP:ToggleOptions() end
  elseif msg == "spellprobe" or msg == "spellbook" then
    if BNP.SpellbookProbe then BNP:SpellbookProbe() else BNP:Print("Spellbook probe is not loaded.") end
  elseif msg == "spellprobe corruption" then
    if BNP.SpellbookProbe then BNP:SpellbookProbe("corruption") end
  elseif msg == "spellprobe agony" then
    if BNP.SpellbookProbe then BNP:SpellbookProbe("agony") end
  elseif msg == "spellprobe siphon" then
    if BNP.SpellbookProbe then BNP:SpellbookProbe("siphon") end
  elseif msg == "unknown" or msg == "learn" then
    if BNP.PrintUnknownBeta then BNP:PrintUnknownBeta(false) else BNP:Print("Unknown collector is not loaded.") end
  elseif msg == "unknown verbose" or msg == "learn verbose" then
    if BNP.PrintUnknownBeta then BNP:PrintUnknownBeta(true) else BNP:Print("Unknown collector is not loaded.") end
  elseif msg == "unknown reset" or msg == "learn reset" then
    if BNP.ResetUnknownBeta then BNP:ResetUnknownBeta() end
    BNP.unknownDirectEvents = {}
  elseif msg == "direct" then
    if BNP.PrintUnknownDirectEvents then
      BNP:PrintUnknownDirectEvents()
    else
      BNP:Print("Direct event collector is not loaded.")
    end
  elseif msg == "spelldb" or msg == "audit" then
    if BNP.PrintSpellDBAudit then BNP:PrintSpellDBAudit() else BNP:Print("SpellDB audit is not loaded.") end
  elseif msg == "spelldb reset" or msg == "audit reset" then
    if BNP.ResetSpellDBAudit then BNP:ResetSpellDBAudit() end
  elseif msg == "guid" or msg == "guiddebug" or msg == "diag" then
    if BNP.PrintGUIDDiagnostic then BNP:PrintGUIDDiagnostic() else BNP:Print("GUID diagnostics are not loaded.") end
  elseif msg == "status" then
    local visible = 0
    local plate
    for plate in pairs(BNP.plates) do
      if plate:IsShown() then visible = visible + 1 end
    end
    BNP:Print("registered: " .. BNP.detected .. ", visible: " .. visible .. ", test spell: " .. tostring(BNP.corruptionName or "not found"))
  elseif msg == "cache" then
    local name = UnitName("target")
    if not name then
      BNP:Print("No target selected.")
      return
    end
    local remaining = BNP.FindCachedCorruption and BNP.FindCachedCorruption(name)
    BNP:Print("Cache for " .. name .. ": " .. tostring(remaining or "no Corruption found"))
  elseif msg == "castbars on" then
    if BNP.SetCastbarsEnabled then BNP:SetCastbarsEnabled(true) end
  elseif msg == "castbars off" then
    if BNP.SetCastbarsEnabled then BNP:SetCastbarsEnabled(false) end
  elseif msg == "scale" then
    BNP:Print("Current nameplate scale: " .. tostring(BNP:GetNameplateScale()))
  elseif msg == "scale reset" then
    if BNP.ResetNameplateScale then BNP:ResetNameplateScale() end
  elseif string.find(msg, "^scale%s+") then
    local _, _, value = string.find(msg, "^scale%s+([0-9%.]+)")
    if BNP.SetNameplateScale then BNP:SetNameplateScale(value) end
  elseif msg == "classcolors on" then
    BNP_DB = BNP_DB or {}
    BNP_DB.classColors = true
    BNP:Print("Class colors enabled.")
  elseif msg == "classcolors off" then
    BNP_DB = BNP_DB or {}
    BNP_DB.classColors = false
    BNP:Print("Class colors disabled.")
  elseif msg == "debug on" then
    BNP:SetDebug(true)
  elseif msg == "debug off" then
    BNP:SetDebug(false)
  elseif msg == "debug" then
    BNP:SetDebug(not BNP.debugEnabled)
  else
    BNP:Print("Commands: /bnp unknown, /bnp direct, /bnp spellprobe, /bnp spelldb, /bnp guid, /bnp status, /bnp castbars on/off, /bnp scale <0.5-1.5>, /bnp scale reset, /bnp classcolors on/off, /bnp debug on, /bnp debug off")
  end
end
