--==================Disable Rendering=======================

local handlerDisableRender = { 
	evaluate = function ()
		if (mb.ReceivedID == 4 and mb.ReceivedMsg == "all") then
			return true
		end
		return false
	end,
	execute = function ()
		if (gDisableDrawing == "1") then
			gDisableDrawing = "0"
		end
		GameHacks:Disable3DRendering(true)
	end,
}
mb.AddHandler(handlerDisableRender)
local action = function () 
	if (gDisableDrawing == "0") then
		gDisableDrawing = "1"
	end
	GameHacks:Disable3DRendering(true)
end
ctrl.AddInitiator("Disable Rendering", "4;all", action)

--==================Enable Rendering=======================

local handlerEnableRender = { 
	evaluate = function ()
		if (mb.ReceivedID == 5 and mb.ReceivedMsg == "all") then
			return true
		end
		return false
	end,
	execute = function ()
		if (gDisableDrawing == "1") then
			gDisableDrawing = "0"
		end
		GameHacks:Disable3DRendering(false)
	end,
}
mb.AddHandler(handlerEnableRender)
local action = function ()
	if (gDisableDrawing == "0") then
		gDisableDrawing = "1"
	end
	GameHacks:Disable3DRendering(false)
end
ctrl.AddInitiator("Enable Rendering", "5;all", action)

--==================Accept Party Invites=======================

local handlerAcceptParty = { 
	evaluate = function ()
		if (mb.ReceivedID == 6 and mb.ReceivedMsg == "all") then
			return true
		end
		return false
	end,
	execute = function ()
		if (ControlVisible("_NotificationParty") and ControlVisible("SelectYesno")) then
			PressYesNo(true)
		end
	end,
}
mb.AddHandler(handlerAcceptParty)
local action = function () --[[do nothing--]] end
ctrl.AddInitiator("Accept Party Invites", "6;all", action)

--==================Accept Teleports=======================

local handlerAcceptTeleport = { 
	evaluate = function ()
		if (mb.ReceivedID == 7 and mb.ReceivedMsg == "all") then
			return true
		end
		return false
	end,
	execute = function ()
		if (ControlVisible("_NotificationTelepo") and ControlVisible("SelectYesno")) then
			PressYesNo(true)
		end
	end,
}
mb.AddHandler(handlerAcceptTeleport)
local action = function () --[[do nothing--]] end
ctrl.AddInitiator("Accept Teleport Invites", "7;all", action)

--==================Return to Nearest Inn=======================

local handlerReturnToInn = { 
	evaluate = function ()
		if (mb.ReceivedID == 8 and mb.ReceivedMsg == "all") then
			if (MultiComp(Player.localmapid,"177,178,179")) then
				return false
			end
			return true
		end
		return false
	end,
	execute = function ()		
		local bestMap = 0
		if (MultiComp(Player.localmapid,"134,135,137,138,139,180,128,129")) then
			bestMap = 177
		elseif (MultiComp(Player.localmapid,"140,141,145,146,147,212,130,131")) then
			bestMap = 178
		elseif (MultiComp(Player.localmapid,"148,152,153,154,155,156,132,133")) then
			bestMap = 179
		end
		
		if (bestMap ~= 0) then
			if (gBotRunning == "1") then
				ml_task_hub.ToggleRun()
			end

			ml_task_hub.shouldRun = true
			gBotRunning = "1"
			ml_task_hub:ClearQueues()
			
			local task = ffxiv_task_movetomap.Create()
			task.destMapID = bestMap
			task.task_complete_execute = function()
				ml_task_hub.ToggleRun()
			end
			ml_task_hub:Add(task, LONG_TERM_GOAL, TP_ASAP)
		end
	end,
}
mb.AddHandler(handlerReturnToInn)
local action = function () 
	local bestMap = 0
	if (MultiComp(Player.localmapid,"134,135,137,138,139,180,128,129")) then
		bestMap = 177
	elseif (MultiComp(Player.localmapid,"140,141,145,146,147,212,130,131")) then
		bestMap = 178
	elseif (MultiComp(Player.localmapid,"148,152,153,154,155,156,132,133")) then
		bestMap = 179
	end
	
	if (bestMap ~= 0) then
		if (gBotRunning == "1") then
			ml_task_hub.ToggleRun()
		end

		ml_task_hub.shouldRun = true
		gBotRunning = "1"
		ml_task_hub:ClearQueues()
		
		local task = ffxiv_task_movetomap.Create()
		task.destMapID = bestMap
		task.task_complete_execute = function()
			ml_task_hub.ToggleRun()
		end
		ml_task_hub:Add(task, LONG_TERM_GOAL, TP_ASAP)
	end
end
ctrl.AddInitiator("Return to Nearest Inn", "8;all", action)

--==================Set Mode=======================

ctrl.AddComboBox("Mode to Set","MODEOPTION","Settings","Quest,Duty,Party")
function compileModeMessage()
	return "9;".._G["CONTROLLERUI_MODEOPTION"]
end
local handlerSetMode = { 
	evaluate = function ()
		if (mb.ReceivedID == 9) then
			return true
		end
		return false
	end,
	execute = function ()
		taskRef = {
			Quest = GetString("questMode"),
			Duty = GetString("dutyMode"),
			Party = GetString("partyMode"),
		}
		
		local taskName = taskRef[mb.ReceivedMsg]
		if (gBotMode ~= taskName) then
			ffxivminion.SwitchMode(taskName)
			Settings.FFXIVMINION.gBotMode = taskName
		end
	end,
}
mb.AddHandler(handlerSetMode)
local action = function () 
	taskRef = {
		Quest = GetString("questMode"),
		Duty = GetString("dutyMode"),
		Party = GetString("partyMode"),
	}
	
	local taskName = taskRef[_G["CONTROLLERUI_MODEOPTION"]]
	if (gBotMode ~= taskName) then
		ffxivminion.SwitchMode(taskName)
		Settings.FFXIVMINION.gBotMode = taskName
	end
end
ctrl.AddInitiator("Set Mode", compileModeMessage, action)

--==================Set Profile=======================

function GetDutyProfileStrings()
	local profiles = "None"
    local profileList = dirlist(GetStartupPath()..[[\LuaMods\ffxivminion\DutyProfiles\]],".*info")
    if (ValidTable(profileList)) then	
		for i,profile in pairs(profileList) do
			profile = string.gsub(profile, ".info", "")
            profiles = profiles..","..profile
		end
    end
    return profiles
end
function GetQuestProfileStrings()
	local profiles = "None"
    local profileList = dirlist(ffxiv_task_quest.profilePath,".*info")
	if (ValidTable(profileList)) then
		for i,profile in pairs(profileList) do
			profile = string.gsub(profile, ".info", "")
            profiles = profiles..","..profile
		end
    end
	return profiles
end
ctrl.AddComboBox("Duty Profiles","Duty Profiles","Settings",GetDutyProfileStrings())
ctrl.AddComboBox("Quest Profiles","Quest Profiles","Settings",GetQuestProfileStrings())
function compileProfileMessage()
	if (gBotMode == GetString("dutyMode")) then
		return "10;".._G["CONTROLLERUI_Duty Profiles"]
	elseif (gBotMode == GetString("questMode")) then
		return "10;".._G["CONTROLLERUI_Quest Profiles"]
	else
		if (_G["CONTROLLERUI_Duty Profiles"] ~= "None" and _G["CONTROLLERUI_Duty Profiles"] ~= "") then
			return "10;".._G["CONTROLLERUI_Duty Profiles"]
		elseif (_G["CONTROLLERUI_Quest Profiles"] ~= "None" and _G["CONTROLLERUI_Quest Profiles"] ~= "") then
			return "10;".._G["CONTROLLERUI_Quest Profiles"]		
		end
	end
end
local handlerSetProfile = { 
	evaluate = function ()
		if (mb.ReceivedID == 10) then
			return true
		end
		return false
	end,
	execute = function ()
		if (gBotMode == GetString("dutyMode") and mb.ReceivedMsg ~= "None" and mb.ReceivedMsg ~= "") then
			gProfile = mb.ReceivedMsg
			ffxiv_task_duty.LoadProfile(mb.ReceivedMsg)
		elseif (gBotMode == GetString("questMode") and mb.ReceivedMsg ~= "None" and mb.ReceivedMsg ~= "") then
			gProfile = mb.ReceivedMsg
			ffxiv_task_quest.LoadProfile(ffxiv_task_quest.profilePath..mb.ReceivedMsg..".info")
		end
	end,
}
mb.AddHandler(handlerSetProfile)
local action = function () 
	if (gBotMode == GetString("dutyMode") and _G["CONTROLLERUI_Duty Profiles"] ~= "None" and _G["CONTROLLERUI_Duty Profiles"] ~= "") then
		gProfile = _G["CONTROLLERUI_Duty Profiles"]
		ffxiv_task_duty.LoadProfile(_G["CONTROLLERUI_Duty Profiles"])
	elseif (gBotMode == GetString("questMode") and _G["CONTROLLERUI_Quest Profiles"] ~= "None" and _G["CONTROLLERUI_Quest Profiles"] ~= "") then
		gProfile = _G["CONTROLLERUI_Quest Profiles"]
		ffxiv_task_quest.LoadProfile(ffxiv_task_quest.profilePath.._G["CONTROLLERUI_Quest Profiles"]..".info")
	end
end
ctrl.AddInitiator("Set Profile", compileProfileMessage, action)