-- Create a new table for our code:
TaskManager= { }
-- Some local variables we use in our module:
TaskManager.taskPath = GetStartupPath()..[[\LuaMods\TaskManager\Tasks\]]
TaskManager.lastticks = 0
TaskManager.windowName = "Task Manager"
TaskManager.task_listitems = ""
TaskManager.taskInfo =""
TaskManager.currentTask = nil
TaskManager.taskIndex = -1
TaskManager.taskState = 0
TaskManager.contentCount = 0
TaskManager.initialItemCount = 0
TaskManager.fateComplete = false
TaskManager.dutyComplete = false
TaskManager.timeout = 0
TaskManager.fateCompletion = -1
TaskManager.targetCompletion = -1
TaskManager.falsePositiveTarget = 60
TaskManager.falsePositiveFate = 60

TaskManager.inventories = 
	{
		[0] =FFXIV.INVENTORYTYPE.INV_ARMORY_MAINHAND,
		[1] =FFXIV.INVENTORYTYPE.INV_ARMORY_OFFHAND,
		[2] =FFXIV.INVENTORYTYPE.INV_ARMORY_HEAD,
		[3] =FFXIV.INVENTORYTYPE.INV_ARMORY_BODY,
		[4] =FFXIV.INVENTORYTYPE.INV_ARMORY_HANDS,
		[5] =FFXIV.INVENTORYTYPE.INV_ARMORY_WAIST,
		[6] =FFXIV.INVENTORYTYPE.INV_ARMORY_LEGS,
		[7] =FFXIV.INVENTORYTYPE.INV_ARMORY_FEET,
		[8] =FFXIV.INVENTORYTYPE.INV_ARMORY_NECK,
		[9] =FFXIV.INVENTORYTYPE.INV_ARMORY_EARS,
		[10] =FFXIV.INVENTORYTYPE.INV_ARMORY_WRIST,
		[11] =FFXIV.INVENTORYTYPE.INV_ARMORY_RINGS,
		[12] =FFXIV.INVENTORYTYPE.INV_ARMORY_RINGS,
		[13] =FFXIV.INVENTORYTYPE.INV_BAG0,
		[14] =FFXIV.INVENTORYTYPE.INV_BAG1,
		[15] =FFXIV.INVENTORYTYPE.INV_BAG2,
		[16] =FFXIV.INVENTORYTYPE.INV_BAG3
		
	}
	
-- taskState :
-- 0 : waiting for the next task to start
-- 1 : Teleported
-- 2 : Stuff is being done (creating marker, moving char, Teleporting etc.). Just wait until it's finished
-- 3 : condition check
-- 4 : completed




function TaskManager.Update(event, ticks)
    if ( gTmgrRunning == "1" and ticks - TaskManager.lastticks > 1000 ) then
		if(TaskManager.taskState == 0 or TaskManager.taskState == 4) then 
			TaskManager.TeleportToNextTask()
		elseif(TaskManager.taskState == 1) then
			TaskManager.DoNextTask()
		elseif(TaskManager.taskState == 3) then
			TaskManager.CheckCondition()
		end
		TaskManager.lastticks = ticks
    end  
end

function TaskManager.ModuleInit()
	
	TaskManager.UpdateTasks()
	
	GUI_NewWindow(TaskManager.windowName,400, 30, 300, 120)
	GUI_NewCheckbox(TaskManager.windowName,"Enabled","gTmgrRunning", "Main")
    GUI_NewComboBox(TaskManager.windowName, "Task", "gTmgrTask","Main", TaskManager.task_listitems)
	GUI_NewNumeric(TaskManager.windowName,"Task Index", "gTmgrTaskIndex", "Main","0", "999")
	
	GUI_NewNumeric(TaskManager.windowName,"Current Task", "gTmgrCurrentTask", "Informations")
	GUI_NewNumeric(TaskManager.windowName,"Kill count", "gTmgrKillCount", "Informations")
	GUI_SizeWindow(TaskManager.windowName,200,300)
	GUI_UnFoldGroup(TaskManager.windowName,"Main")
	
	gTmgrTaskIndex = 0

end

function TaskManager.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		if (k == "gTmgrRunning") then
			if(v =="1") then
				TaskManager.ToggleRun(true)
			else
				TaskManager.ToggleRun(false)
			end
		elseif(k=="gTmgrTask") then
			gTmgrTask = v
			TaskManager.LoadTask(gTmgrTask)
			TaskManager.InitTask()
		elseif(k=="gTmgrTaskIndex") then
			gTmgrTaskIndex = v
		end
	end
	GUI_RefreshWindow(TaskManager.windowName)
end

function TaskManager.ToggleBot(mode)
	
	if (mode==true or mode =="1") then
		if (gBotRunning == "0") then
			gBotRunning = "1"
			ml_task_hub.ToggleRun()
		end
	else
		dbg("Stopping all movement (if any)")
		Player:Stop()
		Dismount()
		if (gBotRunning == "1") then
			gBotRunning = "0"
			ml_task_hub.ToggleRun()
		end
	end	
end

function TaskManager.ToggleRun(mode)
	if(mode) then
		gTmgrRunning = "1"
		TaskManager.InitTask()
		TaskManager.UpdateTaskIndex(tonumber(gTmgrTaskIndex))
	else
		gTmgrRunning = "0"
	end
	TaskManager.ToggleBot(mode)
end

function TaskManager.UpdateTasks()
    local tasks = "None"
    local found = "None"	
    local taskList = dirlist(TaskManager.taskPath,".*info")
    if ( TableSize(taskList) > 0) then			
        local i,task = next ( taskList)
        while i and task do				
            task = string.gsub(task, ".info", "")
            tasks = tasks..","..task
            i,task = next ( taskList,i)
        end		
    else
        dbg("No task found")
    end
    TaskManager.task_listitems = tasks
    TaskManager.task = found
end

function TaskManager.UpdateTaskIndex(index)

TaskManager.taskIndex = index
gTmgrCurrentTask = index

end

function TaskManager.LoadTask(strName)
	if(strName == nil) then
		return
	end
	
	TaskManager.taskInfo = persistence.load(TaskManager.taskPath..strName..".info")
	if (not ValidTable(TaskManager.taskInfo)) then
		dbg("The task ["..strName.."] is structured incorrectly or does not exist.")
		TaskManager.UpdateTaskIndex(-1)
	else
		if(TaskManager.taskInfo.taskIndex ~= nil) then
			TaskManager.UpdateTaskIndex(TaskManager.taskInfo.taskIndex)
		else
			TaskManager.UpdateTaskIndex(0)
		end
		
	end
end

function TaskManager.InitTask()
	TaskManager.contentCount =0
	gTmgrKillCount = 0
	TaskManager.initialItemCount = 0
	TaskManager.fateComplete = false
	TaskManager.dutyComplete = false
	TaskManager.fateCompletion = -1
	TaskManager.targetCompletion = -1
	TaskManager.taskState = 0
end

function TaskManager.TeleportToNextTask()
	-- If the player is in combat, loading, gathering or is fishing, not need to check the conditions
	if(IsLoading() or ml_mesh_mgr.meshLoading or Player.incombat or Player:GetGatherableSlotList() ~= nil or Player:GetFishingState() ~= 0 or OnDutyMap()) then
		return
	end
	
	if( TaskManager.taskIndex == -1) then
		dbg("No task selected or the selected task is invalid.")
		TaskManager.ToggleRun(false)
		return
	end

	if(TaskManager.taskState == 4) then
		TaskManager.UpdateTaskIndex(TaskManager.taskIndex +1)
		TaskManager.InitTask()
	end
	
	TaskManager.currentTask = TaskManager.taskInfo.tasks[TaskManager.taskIndex]
	
	if(TaskManager.currentTask == nil) then
		dbg("No more tasks to do.")
		TaskManager.ToggleRun(false)
		-- Teleport to Mor Dhona when all tasks are done
		Player:Teleport(24)
		return
	end

	--TaskManager.taskState = 2
	
	-- we need to repeat this until the player is teleported correctly. A lot of things can prevent a player from tping (monster attack for example)
	TaskManager.taskState = 0
	
	local location = TaskManager.currentTask.location
	-- Teleport player to the next task location
	if(Player.localmapid ~= location.map or gmeshname ~= location.mesh) then
		TaskManager.Teleport(location)
	else
		TaskManager.taskState = 1
	end
	
end

function TaskManager.DoNextTask()
	if (IsLoading() or ml_mesh_mgr.meshLoading or Player.localmapid ~= TaskManager.currentTask.location.map) then
		return
	end
	
	TaskManager.taskState = 4
	
	local location = TaskManager.currentTask.location
	TaskManager.taskState = 2
	-- Create the marker if it doesn't exist
	if(TaskManager.currentTask.marker ~= nil) then
		local marker = ml_marker_mgr.GetClosestMarker( location.x, location.y, location.z, ml_mesh_mgr.averagegameunitsize*1)
		if( marker ~= nil) then
			if(marker:GetName() ~= TaskManager.currentTask.marker) then
				dbg("Marker already exist at position x: "..location.x.."y: "..location.y.."z: "..location.z)
				-- TODO: try to put the marker at a different location
			end
		else
			dbg("Creating marker...")
			if( not TaskManager.NewMarker()) then
				dbg("Marker "..TaskManager.currentTask.marker.." could not be create. Abording task")
				-- Setting taskState to complete so we can move on to the next task if there is one
				TaskManager.taskState = 4
				return
			end
		end
	elseif(location.x ~= nil and location.y ~= nil and location.z ~= nil) then
		-- Move the player
		Player:MoveTo(location.x, location.y, location.z, 10, false, gRandomPaths=="1")
	end
	
	-- Change the bot mode, gearset, skill profile etc...
	TaskManager.SetProfile()
end

function TaskManager.SetProfile()

	ffxivminion.SwitchMode(TaskManager.currentTask.mode)

	gAtma = "0"
	
	if(TaskManager.currentTask.gearset ~= nil) then
		SendTextCommand("/gs change "..TaskManager.currentTask.gearset)
	end
	
	if(TaskManager.currentTask.skillProfile ~= nil) then
		gSMprofile = TaskManager.currentTask.skillProfile
	end
		
	if(TaskManager.currentTask.marker ~= nil) then
		gMarkerMgrName = TaskManager.currentTask.marker
		-- Dont forget to force the marker mode to single
		gMarkerMgrMode = strings[gCurrentLanguage].singleMarker
	end
	
	if(TaskManager.currentTask.mode == "Grind") then
		if(TaskManager.currentTask.fateId ~= nil) then
			gDoFates = "1"
			gFatesOnly = "1"
		else
			gDoFates = "0"
			gFatesOnly = "0"
		end
	elseif(TaskManager.currentTask.mode == "Gather") then
			--d("gather stuff")
	elseif(TaskManager.currentTask.mode == "Duty") then
			if(TaskManager.currentTask.dutyProfile ~= nil) then
				gProfile = TaskManager.currentTask.dutyProfile
			end
	else
		--d("Unknown mode "..TaskManager.currentTask.mode)
	end
	
	TaskManager.ToggleBot(true)
	TaskManager.taskState = 3
	TaskManager.timeout = Now()
end


function TaskManager.Teleport(location)
	if (Player.incombat or IsLoading()) then
		return false
	end
	
		Player:Stop()
		Dismount()
		
		if (Player.ismounted) then
			return false
		end
		
		if (ActionIsReady(5)) then
			local tele = GetClosestAetheryteToMapIDPos(location.map,location)
			dbg("teleporting player to aetherite ".. tele..", mesh: ("..location.mesh..")")
			Player:Teleport(tele)
			local newTask = ffxiv_task_teleport.Create()
			dbg("Changing to new location for task number "..tostring(TaskManager.taskIndex))
			newTask.mapID = location.map
			newTask.mesh =  location.mesh
			ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
			return true
		end
end

function TaskManager.NewMarker()
		
	local markerType = strings[gCurrentLanguage][TaskManager.currentTask.markerType]
	local newMarker = nil
	templateMarker = ml_marker_mgr.templateList[markerType]
	if (ValidTable(templateMarker)) then
		newMarker = templateMarker:Copy()
		newMarker:SetName(newMarker:GetType())
	else
		ml_error("No Marker Types defined!")	
		return false		
	end
	
	if (ValidTable(newMarker)) then
		newMarker:SetName(TaskManager.currentTask.marker)
		newMarker:SetPosition(TaskManager.currentTask.location)
		if( TaskManager.currentTask.mode == "Grind") then
			newMarker:SetFieldValue(strings[gCurrentLanguage].contentIDEquals, TaskManager.currentTask.contentId)
		elseif( TaskManager.currentTask.markerType ~= "fishingMarker") then
			newMarker:SetFieldValue(strings[gCurrentLanguage].selectItem1,TaskManager.currentTask.gatherItemName)
		end
		ml_marker_mgr.AddMarker(newMarker)
		
		-- Set newMarker as currentMarker (not sure about that one)
		dbg("Setting new currentMarker...")
		ml_marker_mgr.currentMarker = newMarker
		return true
	end
	
	return false
end

function TaskManager.CheckCondition()	
	local timedout = false
	if(TaskManager.currentTask.timeout and TaskManager.currentTask.timeout > 0) then
		timedout = Now() - TaskManager.timeout >= (TaskManager.currentTask.timeout*1000)
	end
	
	if(timedout or TaskManager["CheckCondition"..TaskManager.currentTask.mode](TaskManager.currentTask)) then
		--TaskManager.ToggleBot(false)
		if( timedout) then
			dbg("Task ".. tostring(TaskManager.taskIndex).." timed out.")
		else
			dbg("Task ".. tostring(TaskManager.taskIndex).." completed.")
		end
		TaskManager.taskState = 4
	end
end

function TaskManager.CheckConditionGrind(task)
	-- if(gTmgrReduceFalsePositive == "1") then
		-- TaskManager.CheckTargetAndFate()
	-- end
	local contentKillCondition = TaskManager.CheckContentKillCount(task.contentId, task.contentCount)
	local itemCondition = TaskManager.CheckItemCount(task.itemId, task.itemCount)
	local fateComplete = TaskManager.CheckFateCondition()
	
	return contentKillCondition or itemCondition or fateComplete
	
end

function TaskManager.CheckFateCondition()
	if(TaskManager.currentTask.fateId == nil) then
		return false
	end
	
	return TaskManager.fateComplete
end

function TaskManager.CheckConditionGather()
	local itemCondition = TaskManager.CheckItemCount(task.itemId, task.itemCount, task.gatherItemName)
	
	return itemCondition
end

function TaskManager.CheckConditionDuty()
		if(TaskManager.currentTask.dutyProfile == nil) then
			return false
		end
		
		return TaskManager.dutyComplete
end
function TaskManager.CheckContentKillCount(contentId, contentCount)
	if(contentId == nil) then
		return false
	end
	
	if(contentCount == nil) then
		return false
	end
	
	return TaskManager.contentCount >= contentCount
end

function TaskManager.CheckItemCount(itemId, itemCount)
	if( itemId == nil) then
		return false
	end
	
	if( itemCount == nil) then
		return false
	end
	
	local count = TaskManager.CountItem(itemId) - TaskManager.initialItemCount
	
	return count >= itemCount
end

function TaskManager.CountItem(itemId)
	local itemCount = 0
	local invName = "type="..tostring(TaskManager.slotToInvType[slot])
	local invIndex = 0
	while invIndex <= 16 do
		invName = "type="..tostring(TaskManager.inventories[invIndex]) -- Check every inventories (Bags and armoury)
		inv = Inventory(invName)
		found = false
		if ( inv) then
			local i,item= next(inv)
			while (item~=nil) do
				-- The item should  have the same id, and a higher condition.
				if(item.id == itemId) then
					itemCount = itemCount + item.count
				end		  
				i,item= next(inv,i)  
			end  
		end
		invIndex = invIndex + 1
	end
	return itemCount
end

function dbg(message)
d("[TaskManager] "..message)
end

-- This is highly experimental because we can't know for sure if we got the gold medal for the fate or if the monster we just killed will count for the book
-- I tried to reduce as much as possible the false positive by saving the fate completion and the monster percent hp. If when we arrive at the FATE it's at more than 60% completion there is a hight chance that we won't get the gold
-- Same for the monster, if when we attack it has less that 60% of it's life there is a hight chance that it won't count for the book.
function TaskManager.CheckTargetAndFate()
	if ( gTmgrRunning == "1") then
		-- Check fate completion as soon a we get into the FATE radius
		if(TaskManager.currentTask.fateId ~=nil and TaskManager.fateCompletion == -1 ) then
			local myPos = Player.pos
			local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
			local distance = Distance2D(myPos.x, myPos.z, fate.x, fate.z)
			if (distance <= fate.radius) then				
				TaskManager.fateCompletion = fate.completion
				dbg("Fate Completion :"..tostring(fate.completion).."%")
			end
		-- Check the target hppercent as soon as we have it targeted
		elseif(TaskManager.currentTask.contentId ~= nil and TaskManager.targetCompletion == -1) then
				local target = Player:GeTarget()
				if(target and target.contentid == TaskManager.currentTask.contentId and target.aggropercentage > 0) then
					TaskManager.targetCompletion = target.hp.percent
					dbg("Target Completion :"..tostring(target.hp.percent).."%")
				end
		end
	end


end


--OVERRIDDEN METHODS-- FFXIV_COMMON_TASK.LUA
function ffxiv_task_grindCombat:task_complete_eval()
	target = EntityList:Get(self.targetid)
    if (not target or not target.alive or target.hp.percent == 0 or not target.attackable) then
		-- Extra check to count every time we kill a specific monster
		if( not target.alive and gTmgrRunning == "1") then
			if(target.contentid == TaskManager.currentTask.contentId) then
			-- Same as the FATE, if we start attacking the mobs when he has less than TaskManager.falsePositiveTarget of his life there is chance that it won't count for the book
				-- local validateKill = TaskManager.targetCompletion >= TaskManager.falsePositiveTarget
				-- if(gTmgrReduceFalsePositive == "0") then
					TaskManager.contentCount = TaskManager.contentCount+1
					gTmgrKillCount = TaskManager.contentCount
					dbg("killed monster: "..tostring(TaskManager.contentCount).."/"..tostring(TaskManager.currentTask.contentCount))
					TaskManager.targetCompletion = -1
				-- else
					-- if(validateKill) then
						-- TaskManager.contentCount = TaskManager.contentCount+1
						-- dbg("killed monster: "..tostring(TaskManager.contentCount).."/"..tostring(TaskManager.currentTask.contentCount))
					-- else
						-- dbg("Kill not validate. targetCompletion: "..tostring(TaskManager.targetCompletion)) 
					-- end
				-- end
			end
		end
        return true
    end
end

--OVERRIDDEN METHODS-- FFXIV_HELPERS.LUA
function GetClosestFate(pos)
    local fateList = MapObject:GetFateList()
    if (TableSize(fateList) > 0) then
        local nearestFate = nil
        local nearestDistance = 99999999
        local level = Player.level
		local myPos = Player.pos
		
		for k, fate in pairs(fateList) do
			if ( not ml_blacklist.CheckBlacklistEntry("Fates", fate.id) and (gTmgrRunning =="1" and fate.id == TaskManager.currentTask.fateId) and
				(fate.status == 2 or (fate.status == 7 and Distance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z) < 50))
				and fate.completion >= tonumber(gFateWaitPercent)) 
			then	
				if ( (tonumber(gMinFateLevel) == 0 or (fate.level >= level - tonumber(gMinFateLevel))) and 
					 (tonumber(gMaxFateLevel) == 0 or (fate.level <= level + tonumber(gMaxFateLevel))) ) then
					--d("DIST TO FATE :".."ID"..tostring(fate.id).." "..tostring(NavigationManager:GetPointToMeshDistance({x=fate.x, y=fate.y, z=fate.z})) .. " ONMESH: "..tostring(NavigationManager:IsOnMesh(fate.x, fate.y, fate.z)))
					local p,dist = NavigationManager:GetClosestPointOnMesh({x=fate.x, y=fate.y, z=fate.z},false)
					if (dist <= 5) then
						--local distance = PathDistance(NavigationManager:GetPath(myPos.x,myPos.y,myPos.z,p.x,p.y,p.z))
						local distance = Distance3D(myPos.x,myPos.y,myPos.z,p.x,p.y,p.z)
						if (distance) then
							if (not nearestFate or (nearestFate and (distance < nearestDistance))) then
								nearestFate = shallowcopy(fate)
								nearestDistance = distance
							end
						end
					end
				end
            end
        end
    
        if (nearestFate ~= nil) then
			--local fate = nearestFate
			--d("Fate details: Name="..fate.name..",id="..tostring(fate.id)..",completion="..tostring(fate.completion)..",pos="..tostring(fate.x)..","..tostring(fate.y)..","..tostring(fate.z))
            return nearestFate
        end
    end
    
    return nil
end

--OVERRIDDEN METHODS-- FFXIV_TASK_FATE.LUA
function ffxiv_task_fate:task_complete_eval()
    local fate = GetFateByID(self.fateid)
    if (fate == nil) then
		dbg("Fate "..tonumber(self.fateid).." ended")
		if(self.fateid == TaskManager.currentTask.fateId) then
			-- There is a hight chance that if we started the FATE after 50% progression we won't get the gold medal
			-- if(TaskManager.fateCompletion <= 50) then
				TaskManager.fateComplete= true
				dbg("Zodiac book fate completed")
			-- end
			-- Reset the completion
			-- TaskManager.fateCompletion = -1
		end
        return true
    end
    
    return false
end

function e_fatewait:execute()
    local newTask = ffxiv_task_movetopos.Create()
    local evacPoint = ml_marker_mgr.markerList["evacPoint"]
    local newPos = NavigationManager:GetRandomPointOnCircle(evacPoint.x,evacPoint.y,evacPoint.z,1,5)
    if (ValidTable(newPos)) then
        newTask.pos = {x = newPos.x, y = newPos.y, z = newPos.z}
    else
        newTask.pos = {x = evacPoint.x, y = evacPoint.y, z = evacPoint.z}
    end
    
	-- If TM is enabled and the current task is a FATE we replace the coords so the bot will wate at the FATE spawn
	if(TaskManager.currentTask and TaskManager.currentTask.fateId and gTmgrRunning == "1") then
		newTask.pos = TaskManager.currentTask.location
	end
	
    newTask.remainMounted = true
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

--OVERRIDDEN METHODS-- FFXIV_TASK_DUTY.LUA
function ffxiv_task_duty:Process()
	if (IsLoading() or ml_mesh_mgr.meshLoading) then
		return false
	end
	
	if (IsDutyLeader() and OnDutyMap()) then
		if (self.state == "DUTY_ENTER") then
			local encounters = ffxiv_task_duty.dutyInfo["Encounters"]
			if (ValidTable(encounters)) then
				if ( ffxiv_task_duty.dutyInfo["EncounterIndex"] == 0 ) then
					self.encounter = encounters[1]
					ffxiv_task_duty.dutyInfo["EncounterIndex"] = 1
					self.encounterIndex = 1
					persistence.store(ffxiv_task_duty.dutyPath..".info",ffxiv_task_duty.dutyInfo)
				else
					self.encounterIndex = ffxiv_task_duty.dutyInfo["EncounterIndex"]
					self.encounter = encounters[self.encounterIndex]
				end
				
				self.state = "DUTY_NEXTENCOUNTER"
				self.encounterCompleted = false
			end
		elseif (self.state == "DUTY_NEXTENCOUNTER" and not self.encounterCompleted) then
			--Pull the positions, and the acceptable radius.
			local pos = self.encounter.startPos["General"]
			local myPos = Player.pos
			
			--Check if we need to teleport.  Changed the distance and made the non-teleport option explicit.
			if ((gTeleport == "0" and Distance3D(myPos.x, myPos.y, myPos.z, pos.x, pos.y, pos.z) < 6) or
				(gTeleport == "1" and Distance3D(myPos.x, myPos.y, myPos.z, pos.x, pos.y, pos.z) < 3)) then
				
				--Set state to "DO_ENCOUNTER".
				self.state = "DUTY_DOENCOUNTER"
				
				--Pull the taskFunction from the encounter.
				local encounterData = self.encounter
				local encounterTask = findfunction(encounterData.taskFunction)()
				encounterTask.encounterData = encounterData
				
				ml_task_hub:CurrentTask():AddSubTask(encounterTask)
				
				--Moved the delay processing here so that any future tasks don't have to explicitly handle this.
				local delay = 1500
				if (encounterData.waitTime and encounterData.waitTime > 0) then
					delay = encounterData.waitTime
				end
				
				--d("CurrentTask is: "..tostring(ml_task_hub:CurrentTask().name))
				ml_task_hub:CurrentTask():SetDelay(delay)
			else
				local gotoPos = pos
				if ValidTable(gotoPos) then
					if (gTeleport == "1") then
						GameHacks:TeleportToXYZ(tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z))
						Player:SetFacingSynced(tonumber(gotoPos.h))
					else
						ml_debug( "Moving to ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")	
						Player:MoveTo( tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z),1.0, false, false)
					end
				end
			end
		elseif (self.state == "DUTY_DOENCOUNTER" and self.encounterCompleted) then
			local encounters = ffxiv_task_duty.dutyInfo["Encounters"]
			self.encounterIndex = self.encounterIndex + 1
			ffxiv_task_duty.dutyInfo["EncounterIndex"] = self.encounterIndex
			local encounter = encounters[self.encounterIndex]
			
			if (ValidTable(encounter)) then
				self.state = "DUTY_NEXTENCOUNTER"
				self.encounter = encounter
				persistence.store(ffxiv_task_duty.dutyPath..".info",ffxiv_task_duty.dutyInfo )
				self.encounterCompleted = false
			else
				ffxiv_task_duty.dutyInfo["EncounterIndex"] = 0
				persistence.store(ffxiv_task_duty.dutyPath..".info",ffxiv_task_duty.dutyInfo )
				self.state = "DUTY_EXIT"
				if(gTmgrRunning == "1" and TaskManager.currentTask and TaskManager.currentTask.mode == "Duty") then
					TaskManager.dutyComplete = true
				end
			end
		end
	end

	if (TableSize(ml_task_hub:CurrentTask().process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(ml_task_hub:CurrentTask().process_elements)
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end

--OVERRIDDEN METHODS-- FFXIV_COMMON_CNE.LUA
function c_add_killtarget:evaluate()
	-- block killtarget for grinding when user has specified "Fates Only"
	if ((ml_task_hub:CurrentTask().name == "LT_GRIND" or ml_task_hub:CurrentTask().name == "LT_PARTY" ) and gFatesOnly == "1") then
		if (ml_task_hub:CurrentTask().name == "LT_GRIND") then
			local aggro = GetNearestAggro()
			if ValidTable(aggro) then
				if (aggro.hp.current > 0 and aggro.id and aggro.id ~= 0 and aggro.distance <= 30) then
					c_add_killtarget.targetid = aggro.id
					c_add_killtarget.targetPercent = aggro.hp.percent
					c_add_killtarget.contentId = aggro.contentid
					return true
				end
			end 
		end
        return false
    end
	
	if (gBotMode == strings[gCurrentLanguage].partyMode and not IsLeader()) then
        return false
    end
	
	if not (ml_task_hub:ThisTask().name == "LT_FATE" and ml_task_hub:CurrentTask().name == "MOVETOPOS") then
		local aggro = GetNearestAggro()
		if ValidTable(aggro) then
			if (aggro.hp.current > 0 and aggro.id and aggro.id ~= 0 and aggro.distance <= 30) then
				c_add_killtarget.targetid = aggro.id
				c_add_killtarget.targetPercent = aggro.hp.percent
				return true
			end
		end 
	end
    
	if (SkillMgr.Cast( Player, true)) then
		c_add_killtarget.oocCastTimer = Now() + 1500
		return false
	end
	
	if (ActionList:IsCasting() or Now() < c_add_killtarget.oocCastTimer) then
		return false
	end
	
	local target = ml_task_hub:CurrentTask().targetFunction()
    if (ValidTable(target)) then
        if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
            c_add_killtarget.targetid = target.id
			c_add_killtarget.targetPercent = target.hp.percent
            return true
        end
    end
    
    return false
end

RegisterEventHandler("Gameloop.Update",TaskManager.Update)
RegisterEventHandler("Module.Initalize",TaskManager.ModuleInit)
RegisterEventHandler("GUI.Update",TaskManager.GUIVarUpdate)