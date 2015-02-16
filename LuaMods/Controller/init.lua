ctrl = {}
ctrl.filesPath = GetStartupPath()..[[\LuaMods\Controller\CustomHandlers\]]
ctrl.lastTick = 0
ctrl.currentFiles = {}
ctrl.Initiators = {}

function ctrl.ModuleInit()
	if ( not ffxivminion.Windows) then
		ffxivminion.Windows = {}
	end

	ffxivminion.Windows.Controller = { id = "Controller", Name = "Controller", x=50, y=50, width=260, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Controller)
	
	if (Settings.Controller.gControllerIncludeSelf == nil) then
		Settings.Controller.gControllerIncludeSelf = "1"
	end
	
	local winName = ffxivminion.Windows.Controller.Name
	GUI_NewCheckbox(winName,"Include Self","gControllerIncludeSelf",GetString("settings"))
	ctrl.LoadHandlers()
	
	local winName = ffxivminion.Windows.Controller.Name
	for i,initiator in pairsReverse(ctrl.Initiators) do
		GUI_NewButton(ffxivminion.Windows.Controller.Name,initiator.name,"CONTROLLER_"..initiator.name)
	end
	
	gControllerIncludeSelf = Settings.Controller.gControllerIncludeSelf
	
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
end

function ctrl.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
		if ((string.find(k,"gController") ~= nil)) then
			Settings.Controller[k] = v
		elseif (string.find(k,"CONTROLLERUI_") ~= nil) then
			--just catch the ui piece
		end
	end
end

function ctrl.LoadHandlers()
	ctrl.AddDefaultHandlers()
	
	local customFiles = dirlist(ctrl.filesPath,".*lua")
	if (ValidTable(customFiles)) then
		for i,file in pairs(customFiles) do
			persistence.load(ctrl.filesPath..file)
		end	
		d("Loaded "..tostring(TableSize(customFiles)).." custom handler files.")
    end
end

function ctrl.AddDefaultHandlers()
	local handlerStart = { 
		evaluate = function ()
			if (mb.ReceivedID == 1 and mb.ReceivedMsg == "all") then
				if (gBotRunning == "0") then
					return true
				end
			end
			return false
		end,
		execute = function ()
			ml_task_hub.ToggleRun()
		end,
	}
	mb.AddHandler(handlerStart)
	local action = function ()
		if (gBotRunning == "0") then 
			ml_task_hub.ToggleRun()	
		end 
	end
	ctrl.AddInitiator("Start All", "1;all", action)
	
	local handlerStop = { 
		evaluate = function ()
			if (mb.ReceivedID == 2 and mb.ReceivedMsg == "all") then
				if (gBotRunning == "1") then
					return true
				end
			end
			return false
		end,
		execute = function ()
			ml_task_hub.ToggleRun()
		end,
	}
	mb.AddHandler(handlerStop)
	local action = function ()
		if (gBotRunning == "1") then 
			ml_task_hub.ToggleRun()	
		end 
	end
	ctrl.AddInitiator("Stop All", "2;all", action)
	
	local handlerReload = { 
		evaluate = function ()
			if (mb.ReceivedID == 3 and mb.ReceivedMsg == "all") then
				return true
			end
			return false
		end,
		execute = function ()
			Reload()
		end,
	}
	mb.AddHandler(handlerReload)
	local action = function ()
		Reload()
	end
	ctrl.AddInitiator("Reload All", "3;all", action)
end

function ctrl.AddInitiator(name, message, action)
	assert(type(name) == "string","Expected string for name,received type "..tostring(type(name)))
	assert(type(message) == "string" or type(message) == "function","Expected string or function for message,received type "..tostring(type(message)))
	assert(type(action) == "function","Expected function for action,received type "..tostring(type(action)))
	
	table.insert(ctrl.Initiators, { ["name"] = name, ["process"] = "CONTROLLER_"..name, ["message"] = message, ["action"] = action })
end

function ctrl.AddComboBox(name, varname, group, options)
	assert(type(name) == "string","Expected string for name,received type "..tostring(type(name)))
	assert(type(varname) == "string","Expected string for varname,received type "..tostring(type(varname)))
	assert(type(group) == "string","Expected string for group,received type "..tostring(type(group)))
	assert(type(options) == "string","Expected string for options,received type "..tostring(type(options)))
	
	local winName = ffxivminion.Windows.Controller.Name
	GUI_NewComboBox(winName,varname,"CONTROLLERUI_"..varname,group,options)
end

function ctrl.SafeSend(message)
	local message = message
	if (type(message) == "function") then
		message = message()
	end
	
	d("sending "..message)
	MultiBotSend(message, gMultiChannel)
end

function ctrl.OnUpdate( event, tickcount )
	if (TimeSince(ctrl.lastTick) >= 250) then
		ctrl.lastTick = tickcount
	end
end

function ctrl.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" ) then
		if (string.find(Button,"CONTROLLER_")) then
			for i,initiator in pairs(ctrl.Initiators) do
				if (initiator.process == Button) then
					if (initiator.action ~= nil and gControllerIncludeSelf == "1") then
						initiator.action()
					end
					ctrl.SafeSend(initiator.message)
				end
			end
		end
	end
end

function pairsReverse(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
		--table.sort(keys, function(a,b) return t[a].name < t[b].name end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = #keys+1
    return function()
        i = i - 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

RegisterEventHandler("Module.Initalize",ctrl.ModuleInit)
RegisterEventHandler("GUI.Update",ctrl.GUIVarUpdate)
RegisterEventHandler("GUI.Item", ctrl.HandleButtons )
RegisterEventHandler("Gameloop.Update",ctrl.OnUpdate)