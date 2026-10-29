local function printm(arg)
  ChatFrame1:AddMessage(tostring(arg))
end

function TargetMaster_Initialize()
  TM = getglobal("TargetMaster")
  TM:RegisterEvent("PLAYER_TARGET_CHANGED")
  TM:SetScript("OnEvent", TargetMaster_OnEvent)
  TM.Targets = {}
  TM.GroupStatus = ""
  TM.NumberOfMembers = 0
  TM.CountFontString = nil
end

function Create_CountTexture()
  if not TM.TargetCountFrame then 
    -- Creating the target count frame from the CountTemplate defined in the XML file
    TM.TargetCountFrame = CreateFrame("Button", "TargetCountFrame", TargetFrame, "CountTemplate")

    -- Target portrait count text
    TM.CountFontString = getglobal("TargetCountFrame_Text")

    -- Gets the counter frame background and darkens its color texture
    local FrameBackground = getglobal("TargetCountFrame_Background")
    FrameBackground:SetVertexColor(0,0,0,0.8)

  end
end

function TargetMaster_CheckGroup()
  if GetNumRaidMembers() > 0 then
    TM.GroupStatus = "raid"
  elseif GetNumPartyMembers() > 0 then
    TM.NumberOfMembers = GetNumPartyMembers()
    TM.GroupStatus = "party"
  end
end

function TargetMaster_OnEvent()
  if event == "PLAYER_TARGET_CHANGED" then 
    if TM.GroupStatus == "raid" or TM.GroupStatus == "party" then
      TargetMaster_GetTargets()
      Update_CountTexture()
    end
  end
end

function TargetMaster_GetCountFromTarget(TargetToken)
  -- If this function is called, the player must
  -- be targeting the unit, therefore, initialize
  -- the count variable as one
  local TargetCount = 1

  -- Find the target count of the given TargetToken
  -- inside of the TM.Targets table
  for token, names in pairs(TM.Targets) do 
    if UnitIsUnit(token, TargetToken) then
      TargetCount = table.getn(names)
    end
  end

  return TargetCount
end

function TargetMaster_ClearTargets()
  TM.Targets = {}
end

function TargetMaster_GetTargets()
  -- Reset targets every function call, so counts don't add up
  TargetMaster_ClearTargets()

  -- First of all, adding the player's target if there is one
  if UnitExists("target") then 
    TM.Targets["target"] = { UnitName("player") }
  end

  for i = 1, TM.NumberOfMembers do 
    local token = "party" .. i .. "target"
    
    if UnitExists(token) then 
      -- `found` will be recreated every iteration, no
      -- need to turn it back to false at the end of the loop body
      local found = false
      
      -- Iterate through every target inside `targets` frequency table
      for tgt, _ in pairs(TM.Targets) do 
        -- Check if the unit being targeted matches
        -- the anyone from the frequency table
        if UnitIsUnit(token, tgt) then 
          -- If the unit token is targeting matches `tgt`, then add
          -- the name of the member that is targeting it to the existing record
          table.insert(TM.Targets[tgt], table.getn(TM.Targets[tgt]) + 1, UnitName("party" .. i))
          found = true
          break
        end
      end
  
      -- If no match was found, create a new record from scratch
      if not found then 
        TM.Targets[token] = { UnitName("party" .. i) }
      end
    end
  end
  
  TM.TargetCountFrame:Show()
end

function Update_CountTexture()

  if UnitExists("target") then
    TM.TargetCountFrame:ClearAllPoints()
    TM.TargetCountFrame:SetPoint("CENTER", TargetFrame, "CENTER", 80, 15)

    -- Get the target count 
    TM.CountFontString:SetText(tostring(TargetMaster_GetCountFromTarget("target")))
    TM.TargetCountFrame:Show()

    -- Handling the target count frame tooltip
    TM.TargetCountFrame:SetScript("OnEnter", function() 
      GameTooltip:SetOwner(TM.TargetCountFrame, ANCHOR_BOTTOMLEFT)
      GameTooltip:SetText("Targeted by: ", NORMAL_FONT_COLOR.r,NORMAL_FONT_COLOR.g,NORMAL_FONT_COLOR.b)

      for i = 1, table.getn(TM.Targets["target"]) do 
        GameTooltip:AddLine(TM.Targets["target"][i], 1,1,1)
      end

      GameTooltip:Show()
    end)
    TM.TargetCountFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

  else
    TM.TargetCountFrame:Hide()
  end

end

function TargetMaster_GetMostTargeted()
  -- Most targetd variable, containing the token string
  -- and the target count
  local mtgtd = {
    Token = "",
    Count = 0
  }

  for tgt, name in pairs(TM.Targets) do 
    if table.getn(name) > mtgtd.Count then 
      mtgtd.Token = tgt
      mtgtd.Count = table.getn(name)
    end
  end

  return mtgtd
end

function TargetMaster_IssueTargeting()
  local MostTargeted = TargetMaster_GetMostTargeted()

  if MostTargeted.Count ~= 0  and UnitExists(MostTargeted.Token) then 
    TargetUnit(MostTargeted.Token)
  end
end

TargetMaster_Initialize()
TargetMaster_CheckGroup()
Create_CountTexture()