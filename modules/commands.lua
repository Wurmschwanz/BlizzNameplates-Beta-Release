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
  elseif msg == "auras" or msg == "targetauras" then
    if BNP.PrintTargetAuraProbe then
      BNP:PrintTargetAuraProbe()
    else
      BNP:Print("Target aura probe is not loaded.")
    end
  elseif msg == "raidcheck" then
    local exists, guid = UnitExists("target")
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBNP RAIDCHECK|r")
    if not exists or not guid then
      DEFAULT_CHAT_FRAME:AddMessage("No target / no target GUID.")
      return
    end
    DEFAULT_CHAT_FRAME:AddMessage("Target: "..tostring(UnitName("target") or "?").." | GUID: "..tostring(guid))
    local cache=BNP.guidAuras and BNP.guidAuras[guid]
    local n=0
    if cache then
      local key,aura
      for key,aura in pairs(cache) do
        if type(aura)=="table" and aura.spellID then
          n=n+1
          local mode = aura.castPrimary and "CAST" or (aura.liveConfirmed and "LIVE" or "?")
        DEFAULT_CHAT_FRAME:AddMessage(
          "CACHE | "..tostring(key).." | ID "..tostring(aura.spellID).." | "..mode
        )
        end
      end
    end
    if n==0 then DEFAULT_CHAT_FRAME:AddMessage("CACHE: EMPTY") end
    local pending = BNP.pendingAuras and BNP.pendingAuras[guid]
    if pending then
      DEFAULT_CHAT_FRAME:AddMessage("-- PENDING FOR TARGET --")
      local pk,pv
      for pk,pv in pairs(pending) do
        if type(pv)=="table" then
          DEFAULT_CHAT_FRAME:AddMessage(
            "PENDING | "..tostring(pk)..
            " | ID "..tostring(pv.spellID or "?")..
            " | age "..string.format("%.1fs", GetTime()-(pv.created or GetTime()))
          )
        end
      end
    else
      DEFAULT_CHAT_FRAME:AddMessage("PENDING: none")
    end

    DEFAULT_CHAT_FRAME:AddMessage("-- LAST TRACKED CAST EVENTS --")
    local trace=BNP.raidTrace or {}
    local start=math.max(1,table.getn(trace)-14)
    local ti
    for ti=start,table.getn(trace) do
      local e=trace[ti]
      DEFAULT_CHAT_FRAME:AddMessage(
        tostring(e.stage)..
        " | "..tostring(e.key or "-")..
        " | ID "..tostring(e.spellID or "?")..
        " | GUID "..tostring(e.guid or "nil")..
        " | "..string.format("%.1fs ago",GetTime()-(e.time or GetTime()))
      )
    end

    DEFAULT_CHAT_FRAME:AddMessage("-- LIVE TARGET AURAS (up to 64) --")
    local i
    for i=1,64 do
      local tex,stacks,dtype,id=UnitDebuff("target",i)
      if not tex then break end
      local name=(id and SpellInfo and SpellInfo(id)) or "?"
      DEFAULT_CHAT_FRAME:AddMessage("LIVE "..tostring(i).." | ID "..tostring(id or "?").." | "..tostring(name))
    end
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
