--==================Set Return Mode=======================

ctrl.AddComboBox("Return To Location","RETURN","Settings","RisingStones,WakingSands")
function compileReturnMessage()
    return "100;".._G["CONTROLLERUI_RETURN"]
end
local handlerReturnTo = { 
    evaluate = function ()
        if (mb.ReceivedID == 100) then
            return true
        end
        return false
    end,
    execute = function ()
	
        local destid = 0
        local message = mb.ReceivedMsg
        if (message == "RisingStones") then
            destid = 351
        elseif (message == "WakingSands") then
            destid = 212
        end

        if (Player.localmapid ~= destid and destid ~= 0) then   
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
mb.AddHandler(handlerReturnTo)

local action = function () 
    local destid = 0
	local destString = _G["CONTROLLERUI_RETURN"]
	if (destString == "RisingStones") then
		destid = 351
	elseif (destString == "WakingSands") then
		destid = 212
	end
    if (Player.localmapid ~= destid and destid ~= 0) then
		if (gBotRunning == "1") then
			ml_task_hub.ToggleRun()
		end

		ml_task_hub.shouldRun = true
		gBotRunning = "1"
		ml_task_hub:ClearQueues()
			
		local task = ffxiv_task_movetomap.Create()
		task.destMapID = destid
		task.task_complete_execute = function()
			ml_task_hub.ToggleRun()
		end
		ml_task_hub:Add(task, LONG_TERM_GOAL, TP_ASAP)
    end
end
ctrl.AddInitiator("Return To", compileReturnMessage, action)