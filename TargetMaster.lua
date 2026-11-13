-- #################### FUNCTIONS ####################
-- TM = TargetMaster
-- Create_TargetCountFrame()
-- Update_TargetCountFrame()
-- TM_Initialize()
-- TM_CheckGroup()
-- TM_OnEvent()
-- TM_GetCountFromTarget(TargetToken)
-- TM_GetTargets()
-- TM_ClearTargets()
-- TM_GetMostTargeted()
-- TM_IssueTargeting()
-- TM_GetMembersInfo()
-- TM_TargetTank()
-- TM_TargetLeastHealthyMember()
-- TM_HandleButtonsVisibility()
-- TryAttackingOnTarget()

-- Relates to binding elements in Bindings.xml
BINDING_HEADER_TARGETMASTER = "TargetMaster"
BINDING_NAME_TARGETMASTER_MOSTTARGETED = "Target most targeted unit"
BINDING_NAME_TARGETMASTER_TARGETLEASTHEALTHY = "Target least healthy member"
BINDING_NAME_TARGETMASTER_TARGETTANK = "Target tank member"
DEFAULT_NAMES_TARGET_COUNT = 5
RAID_CLASS_COLORS = {
      ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" },
      ["MAGE"]    = { r = 0.41, g = 0.8,  b = 0.94, colorStr = "ff69ccf0" },
      ["ROGUE"]   = { r = 1,    g = 0.96, b = 0.41, colorStr = "fffff569" },
      ["DRUID"]   = { r = 1,    g = 0.49, b = 0.04, colorStr = "ffff7d0a" },
      ["HUNTER"]  = { r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473" },
      ["SHAMAN"]  = { r = 0.14, g = 0.35, b = 1.0,  colorStr = "ff0070de" },
      ["PRIEST"]  = { r = 1,    g = 1,    b = 1,    colorStr = "ffffffff" },
      ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79, colorStr = "ff9482c9" },
      ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
    }

TM_config = {}

-- Helper print function
function Printm(arg)
  ChatFrame1:AddMessage(tostring(arg))
end

-- Initializes TM as the main table, register events
-- and create table properties
function TM_Initialize()
  TM = getglobal("TargetMaster")
  TM:RegisterEvent("PLAYER_TARGET_CHANGED")
  TM:RegisterEvent("PARTY_MEMBERS_CHANGED")
  TM:RegisterEvent("RAID_ROSTER_UPDATE")
  TM:RegisterEvent("ADDON_LOADED")
  TM:SetScript("OnEvent", TM_OnEvent)
  TM.TargetButtons = getglobal("TargetButtons")
  TM.Targets = {}
  TM.MembersInfo = {} -- Holds member's name, hp and party token
  TM.GroupStatus = ""
  TM.PlayerRaidToken = ""
  TM.NumberOfMembers = 0
  TM.CountFontString = nil
end

function Create_TargetCountFrame()
  -- Creating the target count frame from the CountTemplate defined in the XML file
  TM.TargetCountFrame = CreateFrame("Button", "TargetCountFrame", TargetFrame, "CountTemplate")

  -- Target portrait count text
  TM.CountFontString = getglobal("TargetCountFrame_Text")

  
  -- Gets the counter frame background and darkens its color texture
  local FrameBackground = getglobal("TargetCountFrame_Background")
  -- Fits the texture into a round border
  SetPortraitToTexture(FrameBackground, "Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")
  FrameBackground:SetVertexColor(0,0,0,1)

end

function TM_CheckGroup()
  if GetNumRaidMembers() > 0 then
    TM.NumberOfMembers = GetNumRaidMembers()
    TM.GroupStatus = "raid"
  elseif GetNumPartyMembers() > 0 then
    TM.NumberOfMembers = GetNumPartyMembers()
    TM.GroupStatus = "party"
  else 
    TM.NumberOfMembers = 0
    TM.GroupStatus = "alone"
  end
end

function TM_OnEvent()
  -- Updates the TargetMaster properties per target change
  if event == "PLAYER_TARGET_CHANGED" then 
    if TM.GroupStatus == "raid" or TM.GroupStatus == "party" then
      TM_GetTargets()
      Update_TargetCountFrame()
      TM.TargetCountFrame:Show()
    else 
      TM.TargetCountFrame:Hide()
    end
    

  -- Checks if the player joined a group midgame, updating the UI
  -- and the TargetMaster properties without having to reload the UI
  elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
    TM_CheckGroup() -- Checks if the player is inside a group
    if TM.NumberOfMembers == 0 and TM.GroupStatus == "alone" then
      TM.TargetCountFrame:Hide()
    else
      -- Will run a single update to check targets and
      -- update the UI as the player joins a group
      TM_GetTargets()
      Update_TargetCountFrame()
      TM.TargetCountFrame:Show()
    end
    
  end
end

function TM_GetMembersInfo()
  -- Iterate through all members in the party and get their name and token
  for i = 1, TM.NumberOfMembers do 
    local member = TM.GroupStatus .. i
    local NameTokenTbl = { name = string.lower(UnitName(member)), token = member, hp = UnitHealth(member) }
    table.insert(TM.MembersInfo, getn(TM.MembersInfo) + 1, NameTokenTbl)
  end
end

function TM_TargetLeastHealthyMember()
  TM_GetMembersInfo() -- Gets the name, token and hp of every member in the group

  -- Assigning the first record of the table as the least healthy member
  local leastHealthy = nil

  -- Iterate through all members info
  for _, infoTbl in ipairs(TM.MembersInfo) do 
    local hp = infoTbl.hp
    local token = infoTbl.token

    if UnitIsConnected(token) then -- Check if the member is online 
      if leastHealthy == nil then
        leastHealthy = infoTbl
      elseif leastHealthy.hp > hp then
        leastHealthy = infoTbl
      end
    end
  end

  -- Target the least healthy member
  if leastHealthy then TargetUnit(leastHealthy.token) end
  
end

function TM_TargetTank()
  TM_GetMembersInfo() -- Gets the name, token and hp of every member in the group

  if TM_config.TankInputText then 

    -- Target the desired member
    local found = false

    -- Iterate through all members info
    for _, infoTbl in ipairs(TM.MembersInfo) do 
      local name = string.lower(infoTbl.name)
      local token = infoTbl.token

      -- Trim any whitespace before and after the tank name
      local clean_name = string.gsub(string.lower(TM_config.TankInputText), " ", "")

      if clean_name == name then
        found = true
        TargetUnit(token)
      end
    end

    -- If the given name for the tank member was not found,
    -- provide feedback to the user via the chat frame
    if not found then Printm("Player |cFF1EE08D [" .. TM_config.TankInputText .. "] |cFFFFFFFF was not found, check for typos or correct the member name fully.") end
  end
end

function TM_GetCountFromTarget(TargetToken)
  -- If this function is called, the player must
  -- be targeting the unit, therefore, initialize
  -- the count variable as one
  local TargetCount = 1

  -- Find TargetToken inside TM.Targets and retrieve is count
  for token, tbl in pairs(TM.Targets) do 
    if UnitIsUnit(token, TargetToken) then
      TargetCount = getn(tbl.names)
    end
  end

  return TargetCount
end

function TM_ClearTargets()
  TM.Targets = {}
end


-- TM.Targets will store its elements like so:
-- { "target": { names: { "Warriorwrecker" }, tokens: { "party1" } } }
-- { "raid1": { names: { "Magecd" }, tokens: { "raid3" } } }
function TM_GetTargets()
  -- Reset targets every function call, so counts don't add up
  TM_ClearTargets()

  -- First of all, adding the player's target if there is one
  if UnitExists("target") then 
    TM.Targets["target"] = { 
      names = { UnitName("player") },
      tokens = { "player" }
    }
  end

  for i = 1, TM.NumberOfMembers do 
    local member = TM.GroupStatus .. i
    local token = member .. "target"
    
    -- Skipping yourself since your target is added above
    if not UnitIsUnit(member, "player") and UnitExists(token) then 
      -- `found` will be recreated every iteration, no
      -- need to turn it back to false at the end of the loop body
      local found = false
      
      -- Iterate through every target inside `targets` frequency table
      for tgt, _ in pairs(TM.Targets) do 
        -- Check if the unit being targeted matches
        -- anyone from the frequency table
        if UnitIsUnit(token, tgt) then 
          -- If the unit token is targeting matches `tgt`, then add
          -- the name of the member that is targeting it to the existing record
          table.insert(TM.Targets[tgt].names, getn(TM.Targets[tgt].names) + 1, UnitName(member))
          table.insert(TM.Targets[tgt].tokens, getn(TM.Targets[tgt].tokens) + 1, member)
          found = true
          break
        end
      end
      -- If no match was found, create a new record from scratch
      if not found then 
        TM.Targets[token] = {
          names = { UnitName(member) },
          tokens = { member }
        }
      end
    end
  end
  
  TM.TargetCountFrame:Show()
end

function Update_TargetCountFrame()

  -- Used to keep track of the user character's target.
  -- This can change in a raid, since while in raid groups,
  -- the user's target token becomes raid2target, where `2`
  -- can be random.
  local TargetToken = "target"

  -- Find the key target token that matches the player target
  -- and update TargetToken to store it
  if TM.GroupStatus == "raid" then 
    local PlayerRaidTokenTarget = TM.PlayerRaidToken .. "target"
    for TargetKey, _ in pairs(TM.Targets) do 
      if UnitIsUnit(TargetKey, PlayerRaidTokenTarget) then
        TargetToken = TargetKey
        break
      end
    end

    -- If no match was found, assign the target
    -- related to the raid player target
    if TargetToken == "target" then
      TargetToken = TM.PlayerRaidToken .. "target"
    end
  end

  
  if UnitExists(TargetToken) then
    TM.TargetCountFrame:ClearAllPoints()
    TM.TargetCountFrame:SetPoint("CENTER", TargetFrame, "CENTER", -113, 30)

    -- Get the target count 
    TM.CountFontString:SetText(tostring(TM_GetCountFromTarget(TargetToken)))
    TM.TargetCountFrame:Show()

    -- Handling the target count frame tooltip
    TM.TargetCountFrame:SetScript("OnEnter", function() 
      GameTooltip:SetOwner(TM.TargetCountFrame, ANCHOR_BOTTOMLEFT)
      GameTooltip:SetText("Targeted by: ", NORMAL_FONT_COLOR.r,NORMAL_FONT_COLOR.g,NORMAL_FONT_COLOR.b)

      local NamesLimitCount = TM_config.TargetedByCount
      local NamesCountRemainder = 0
      local NumberOfTargetNames = 0
      
      -- Find the player token as a raid member
      NumberOfTargetNames = getn(TM.Targets[TargetToken].names)

      -- Avoids the code from mistakenly crashing if the count is not convertible
      if (
        tonumber(NamesLimitCount) == nil or
        tonumber(NamesLimitCount) > NumberOfTargetNames or
        tonumber(NamesLimitCount) <= 0
      ) then 
        -- If the default number count is bigger than the
        -- amount of target names, default to the amount of names
        if DEFAULT_NAMES_TARGET_COUNT > NumberOfTargetNames then
          NamesLimitCount = NumberOfTargetNames
        else
          NamesLimitCount = DEFAULT_NAMES_TARGET_COUNT
        end
      else
        NamesLimitCount = tonumber(NamesLimitCount)
      end

      -- Will get the remainder number of names to display
      -- in the count frame hover tooltip
      if NumberOfTargetNames - NamesLimitCount > 0 then 
        NamesCountRemainder = NumberOfTargetNames - NamesLimitCount
      end

      for i = 1, NamesLimitCount do 
        -- Gets the member's class color and paint its
        -- name text with it
        local MemberName = TM.Targets[TargetToken].names[i]
        local MemberToken = TM.Targets[TargetToken].tokens[i]
        local UnitClassName = string.upper(UnitClass(MemberToken))

        -- Finding the right class color
        local color = RAID_CLASS_COLORS[UnitClassName]

        -- Inserting the party member name
        GameTooltip:AddLine(MemberName, color.r,color.g,color.b)
        
        -- If the names count was capped, this line 
        -- shows the count remainder to the user
        if NamesCountRemainder > 0 then 
          GameTooltip:AddLine("And " .. NamesCountRemainder .. " more...", 1,1,1)
        end
      end

      GameTooltip:Show()
    end)
    TM.TargetCountFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
  else
    TM.TargetCountFrame:Hide()
  end

end

function TM_GetMostTargeted()
  -- Most targetd variable, containing the token string
  -- and the target count
  local mtgtd = {
    Token = "",
    Count = 0
  }

  for tgt, tbl in pairs(TM.Targets) do 
    if getn(tbl.names) > mtgtd.Count then 
      mtgtd.Token = tgt
      mtgtd.Count = getn(tbl.names)
    end
  end

  return mtgtd
end

function TryAttackingOnTarget()

  local AttackActionSlot = nil
  local Attacking = false

  if TM_config.AttackOnTarget then 

    -- Will try to find the attack slot in the player action bar
    -- to trigger an automatic attack when this function is executed
    for lActionSlot = 1, 120 do 
      if IsAttackAction(lActionSlot) then 
        AttackActionSlot = lActionSlot

        -- Check if the attack action was previously active,
        -- making sure that the TargetMaster function doesn't
        -- deactivate if by accident
        if IsCurrentAction(AttackActionSlot) then
          Attacking = true
        else
          Attacking = false
        end
      end
    end

    -- If the attack action was found, attack the current target,
    -- otherwise, warn the user that the action wasn't found
    if AttackActionSlot then
      if not Attacking then 
        AttackTarget()
      end
    else
      -- Error feedback message
      Printm("\n|cFF1EE08D[TargetMaster] |cFFFFFFFF- |cFFFF0000[ERROR]|cFFFFFFFF")
      Printm("\n|cFFFF0000Attack on target feature failed!|cFFFFFFFF")
      Printm("Please, assign an action bar slot to your attack action with a valid keybind so the attack on target feature can run successfully.\n")
    end
  end

end

function TM_IssueTargeting()
  local MostTargeted = TM_GetMostTargeted()

  if MostTargeted.Count ~= 0  and UnitExists(MostTargeted.Token) then 
    TargetUnit(MostTargeted.Token)
    TryAttackingOnTarget()
  end
end

function TM_HandleButtonsVisibility()
  if TM.TargetButtons:IsVisible() then 
    TM_config.ButtonsVisible = false
    TM.TargetButtons:Hide()
  else 
    TM_config.ButtonsVisible = true
    TM.TargetButtons:Show()
  end
end

-- Order matters
TM_Initialize() -- Create table props and register events
TM_CheckGroup() -- Checks if the group is a raid or a party
Create_TargetCountFrame() -- Creates the count prop frame that shows on top of your target portrait