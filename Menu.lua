
function Initialize_Menu()
  MenuFrame = getglobal("MenuFrame")
  MenuFrame.ShowTargetButtons = getglobal("MenuFrame_ShowTargetButtons")
  MenuFrame.TankInputBox = getglobal("MenuFrame_TankInput")
  MenuFrame.OnTargetingCheckButton = getglobal("MenuFrame_OnTargetingCheckButton")
  MenuFrame.TargetedByCountInput = getglobal("MenuFrame_TargetedByCountInput")
  MenuFrame:RegisterEvent("ADDON_LOADED")
  MenuFrame:SetScript("OnEvent", MenuFrame_OnEvent)
  tinsert(UISpecialFrames, "MenuFrame") -- Makes it possible to close the frame by hitting Escape
end

function MenuFrame_OnEvent()
  if event == "ADDON_LOADED" then 
    -- Create a brand new config if the character is logging in for the first time
    if not TM_config then 
      TM_config = { TargetedByCount = DEFAULT_NAMES_TARGET_COUNT } 
      MenuFrame:Show()
    end

    MenuFrame.TargetedByCountInput:SetText(tostring(TM_config.TargetedByCount))

    -- Handling saved configs for the TankInput
    if TM_config.TankInputText then 
      MenuFrame.TankInputBox:SetText(TM_config.TankInputText)
    end

    -- Handling saved configs for the OnTargetingCheckButton
    if TM_config.AttackOnTarget then 
      MenuFrame.OnTargetingCheckButton:SetChecked(true)
    else
      MenuFrame.OnTargetingCheckButton:SetChecked(false)
    end
  
    -- Handling saved configs for the TargetButtons
    if TM_config.ButtonsVisible == nil then
      -- Default to visible on first run
      TM_config.ButtonsVisible = true
      MenuFrame.ShowTargetButtons:SetChecked(true)
    
    elseif TM_config.ButtonsVisible then
      TM.TargetButtons:Show()
      MenuFrame.ShowTargetButtons:SetChecked(true)
    else
      TM.TargetButtons:Hide()
      MenuFrame.ShowTargetButtons:SetChecked(false)
    end
  end
end

Initialize_Menu()

SLASH_TARGETMASTER1 = "/targetmaster"
SLASH_TARGETMASTER2 = "/tm"
SLASH_RESET1 = "/tmr"

SlashCmdList["TARGETMASTER"] = function() MenuFrame:Show() end
SlashCmdList["RESET"] = function()
  TM_config = {}
  ReloadUI()
end