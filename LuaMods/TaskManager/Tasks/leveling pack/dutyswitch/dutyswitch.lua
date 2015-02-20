dutyswitch= { }
dutyswitch.running = false
dutyswitch.latch = false
dutyswitch.lastticks = 0
dutyswitch.currentMap = nil
dutyswitch.swtichInfo =""
dutyswitch.windowName = "duty switch"
dutyswitch.path = GetStartupPath()..[[\LuaMods\dutyswitch\]]
dutyswitch.id = 0
--Main function	
function dutyswitch.Update(event, ticks)

	if ( dutyswitch.running and ticks - dutyswitch.lastticks > 500 ) then
		dutyswitch.lastticks = ticks
		if(ValidTable(dutyswitch.swtichInfo)) then
			if(dutyswitch.swtichInfo.id[Player.localmapid] ~= nil) then
				dutyswitch.currentMap = dutyswitch.swtichInfo.id[Player.localmapid]
				if(dutyswitch.id ~= dutyswitch.currentMap.mapID) then
					gProfile = dutyswitch.currentMap.profileName
					ffxiv_task_duty.LoadProfile(gProfile)
					dutyswitch.id = dutyswitch.currentMap.mapID
					d("Profile Loaded")
				end
			else
				dutyswitch.id = 0
			end
		end
    end  
end
--init the GUI
function dutyswitch.ModuleInit()
	local winName = GetString("dutyMode")
	local group = GetString("status")
	GUI_NewCheckbox(winName,"Switch","dutyswitch.running", group)
end
function dutyswitch.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		if (k == "dutyswitch.running") then
			dutyswitch.ToggleRun()
		end
	end
	GUI_RefreshWindow(dutyswitch.windowName)
end

--Toogle the run
function dutyswitch.ToggleRun()
	if(dutyswitch.running == false) then
		dutyswitch.running = true
		dutyswitch.loadSetting()
	else
		dutyswitch.running = false
	end
end
function dutyswitch.loadSetting()
	dutyswitch.swtichInfo = persistence.load(dutyswitch.path.."switchMapSetting.info")
	if (not ValidTable(dutyswitch.swtichInfo)) then
		dbg("unable to locate setting file")		
	end
end
-- Registering the Events
RegisterEventHandler("Gameloop.Update",dutyswitch.Update)
RegisterEventHandler("dutyswitch.toggle", dutyswitch.ToggleRun) 
RegisterEventHandler("Module.Initalize",dutyswitch.ModuleInit)
RegisterEventHandler("GUI.Update",dutyswitch.GUIVarUpdate)