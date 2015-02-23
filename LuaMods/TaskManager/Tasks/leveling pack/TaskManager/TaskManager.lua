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
TaskManager.fateComplete = false
TaskManager.dutyCount = 0
TaskManager.lastDutyCountTick = 0
TaskManager.timeout = 0
-- TaskManager.questComplete = false
TaskManager.fateCompletion = -1
TaskManager.targetCompletion = -1
TaskManager.falsePositiveTarget = 60
TaskManager.falsePositiveFate = 60

TaskManager.inventories = 
	{
		[0] = FFXIV.INVENTORYTYPE.INV_CURRENCY,
		[1] = FFXIV.INVENTORYTYPE.INV_SHARDS,
		[2] = 2004, -- Quest and Key items
		[3] =FFXIV.INVENTORYTYPE.INV_ARMORY_MAINHAND,
		[4] =FFXIV.INVENTORYTYPE.INV_ARMORY_OFFHAND,
		[5] =FFXIV.INVENTORYTYPE.INV_ARMORY_HEAD,
		[6] =FFXIV.INVENTORYTYPE.INV_ARMORY_BODY,
		[7] =FFXIV.INVENTORYTYPE.INV_ARMORY_HANDS,
		[8] =FFXIV.INVENTORYTYPE.INV_ARMORY_WAIST,
		[9] =FFXIV.INVENTORYTYPE.INV_ARMORY_LEGS,
		[10] =FFXIV.INVENTORYTYPE.INV_ARMORY_FEET,
		[11] =FFXIV.INVENTORYTYPE.INV_ARMORY_NECK,
		[12] =FFXIV.INVENTORYTYPE.INV_ARMORY_EARS,
		[13] =FFXIV.INVENTORYTYPE.INV_ARMORY_WRIST,
		[14] =FFXIV.INVENTORYTYPE.INV_ARMORY_RINGS,
		[15] =FFXIV.INVENTORYTYPE.INV_ARMORY_RINGS,
		[16] =FFXIV.INVENTORYTYPE.INV_BAG0,
		[17] =FFXIV.INVENTORYTYPE.INV_BAG1,
		[18] =FFXIV.INVENTORYTYPE.INV_BAG2,
		[19] =FFXIV.INVENTORYTYPE.INV_BAG3,
		
	}
	
-- taskState :
-- 0 : waiting for the next task to start
-- 1 : Teleported
-- 2 : Stuff is being done (creating marker, moving char, Teleporting etc.). Just wait until it's finished
-- 3 : condition check
-- 4 : completed
-- 5 : player died and respawned

function TaskManager.Update(event, ticks)
    if ( gTmgrRunning == "1" and ticks - TaskManager.lastticks > 1000 ) then
		TaskManager.CheckForAggro()
		if(TaskManager.taskState == 0 or TaskManager.taskState == 4 or TaskManager.taskState == 5) then 
			TaskManager.MoveToNextTask()
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
	GUI_NewNumeric(TaskManager.windowName,"Start Task", "gTmgrTaskIndex", "Main","0", "999")
	
	GUI_NewNumeric(TaskManager.windowName,"Current Task", "gTmgrCurrentTask", "Informations")
	GUI_NewNumeric(TaskManager.windowName,"Kill count", "gTmgrKillCount", "Informations")
	GUI_NewNumeric(TaskManager.windowName,"Item count", "gTmgrItemCount", "Informations")
	GUI_SizeWindow(TaskManager.windowName,300,300)
	GUI_UnFoldGroup(TaskManager.windowName,"Main")
	GUI_UnFoldGroup(TaskManager.windowName,"Informations")
	
	gTmgrTaskIndex = 0
	gTmgrRunning = "0"

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
	gTmgrItemCount = 0
	TaskManager.fateComplete = false
	TaskManager.dutyCount = 0
	TaskManager.fateCompletion = -1
	TaskManager.targetCompletion = -1
	TaskManager.taskState = 0
	-- TaskManager.questComplete = false
end

function TaskManager.CheckForAggro()
	-- Extra check in case player is attacked by  monster while trying to tping or working on the next task
	if(Player.incombat and gBotRunning == "0") then
		TaskManager.ToggleBot(true)
	end
end

function TaskManager.MoveToNextTask()
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

-- Player died, so we need to disable the bot and unmount the player to avoid mounting loop
	if(TaskManager.taskState == 5) then
		TaskManager.ToggleBot(false)
	end
	--TaskManager.taskState = 2
	
	-- we need to repeat this until the player is teleported correctly. A lot of things can prevent a player from tping (monster attack for example)
	TaskManager.taskState = 0
	
	local location = TaskManager.currentTask.location
	
	-- Teleport player to the next task location
	if(Player.localmapid ~= location.map) then
		TaskManager.Teleport(location)
	elseif(gmeshname ~= location.mesh) then
	-- Change the mesh if it doesn't match
		mm.ChangeNavMesh(location.mesh, false)
	else
		TaskManager.taskState = 1
	end
	
end

function TaskManager.DoNextTask()
	if (IsLoading() or ml_mesh_mgr.meshLoading or Player.localmapid ~= TaskManager.currentTask.location.map) then
		return
	end
	
	if(TaskManager.currentTask.gearset ~= nil) then
		SendTextCommand("/gs change "..TaskManager.currentTask.gearset)
	end
	
	-- if(TaskManager.currentTask.useTeleport ~= nil and TaskManager.currentTask.useTeleport == "1") then
	-- 	gTeleport = TaskManager.currentTask.useTeleport
	-- end

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
				dbg("Marker "..TaskManager.currentTask.marker.." could not be create. aborting task")
				-- Setting taskState to complete so we can move on to the next task if there is one
				TaskManager.taskState = 4
				return
			end
		end
	elseif(location.x ~= nil and location.y ~= nil and location.z ~= nil) then
		-- Move the player
			local newTask = ffxiv_task_movetopos.Create()
			newTask.pos = location
			if(gTeleport =="1") then
				newTask.useTeleport = true
			end
			newTask.useFollowMovement = false
			ml_task_hub:CurrentTask():AddSubTask(newTask)

		-- if(gTeleport == "1") then
		-- 	GameHacks:TeleportToXYZ(location.x,location.y,location.z)
		-- else
		-- 	Player:MoveTo(location.x, location.y, location.z, 10, false, gRandomPaths=="1")
		-- end
	end
	
	-- Change the bot mode, gearset, skill profile etc...
	-- if( TaskManager.currentTask.mode == "Interact" and TaskManager.currentTask.interactId) then
	-- 	Player:Interact(TaskManager.currentTask.interactId)
	-- end

	TaskManager.SetProfile()
end

function TaskManager.SetProfile()

	ffxivminion.SwitchMode(TaskManager.currentTask.mode)

	gAtma = "0"
	
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
	-- elseif(TaskManager.currentTask.mode == "Quest") then
	-- 		ffxiv_task_quest.LoadProfile(ffxiv_task_quest.profilePath..TaskManager.currentTask.questProfile..".info")
	-- 		Settings.FFXIVMINION["gLastQuestProfile"] = TaskManager.currentTask.questProfile
	elseif(TaskManager.currentTask.mode == "Gather") then
			--d("gather stuff")
	elseif(TaskManager.currentTask.mode == "Duty") then
			if(TaskManager.currentTask.dutyProfile ~= nil) then
				gProfile = TaskManager.currentTask.dutyProfile
				ffxiv_task_duty.LoadProfile(TaskManager.currentTask.dutyProfile)
				Settings.FFXIVMINION["gLastDutyProfile"] = TaskManager.currentTask.dutyProfile
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

	if (Player.ismounted) then
		return false
	end

	if (ActionIsReady(5)) then
		TaskManager.ToggleBot(false)
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
		
		if(TaskManager.currentTask.contentId ~=nil) then
			newMarker:SetFieldValue(strings[gCurrentLanguage].contentIDEquals, TaskManager.currentTask.contentId)
		end
		
		if(TaskManager.currentTask.gatherItemName ~= nil) then
			newMarker:SetFieldValue(strings[gCurrentLanguage].selectItem1,TaskManager.currentTask.gatherItemName)
		end
		
		if(TaskManager.currentTask.useStealth ~= nil) then
			newMarker:SetFieldValue(strings[gCurrentLanguage].useStealth, TaskManager.currentTask.useStealth)
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
	
	local contentKillCondition = TaskManager.CheckContentKillCount(TaskManager.currentTask.contentId, TaskManager.currentTask.contentCount)
	local itemCondition = TaskManager.CheckItemCount(TaskManager.currentTask.itemId, TaskManager.currentTask.itemCount)
	local fateComplete = TaskManager.CheckFateCondition()
	local dutyComplete = TaskManager.CheckConditionDuty()
	local levelCondition = TaskManager.CheckLevelCondition()
	
	if(timedout or (contentKillCondition or itemCondition or fateComplete or dutyComplete or levelCondition)) then
		if( timedout) then
			dbg("Task ".. tostring(TaskManager.taskIndex).." timed out.")
		else
			dbg("Task ".. tostring(TaskManager.taskIndex).." completed.")
		end
		TaskManager.taskState = 4
	end
end

-- function TaskManager.CheckConditionQuestDone()
-- 		if(TaskManager.currentTask.mode ~= "Quest" ) then
-- 			return false
-- 		end
		
-- 		return TaskManager.questComplete
-- end


function TaskManager.CheckFateCondition()
	if(TaskManager.currentTask.fateId == nil or TaskManager.currentTask.fateId == "") then
		return false
	end
	
	return TaskManager.fateComplete
end


function TaskManager.CheckLevelCondition()
	if(TaskManager.currentTask.maxLevel == nil) then
		return false
	end
	
	return Player.level >= TaskManager.currentTask.maxLevel
end

function TaskManager.CheckConditionDuty()
		if(TaskManager.currentTask.dutyCount == nil ) then
			return false
		end
		
		return TaskManager.dutyCount >= TaskManager.currentTask.dutyCount
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
	
	local count = TaskManager.CountItem(itemId)
	gTmgrItemCount = count
	
	return count >= itemCount
end


function TaskManager.CountItem(itemId)
	local itemCount = 0
	local invName = nil
	local invIndex = 0
	while TaskManager.inventories[invIndex] ~= nil do
		invName = "type="..tostring(TaskManager.inventories[invIndex]) -- Check every inventories
		-- dbg("Cheking inventory "..invName)
		inv = Inventory(invName)
		if ( inv) then
			local i,item= next(inv)
			while (item~=nil) do
				-- The item should  have the same id, and a higher condition.
				if(item.id == itemId) then
					-- dbg("item found, count: "..tostring(item.count))
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
		if( target and not target.alive and gTmgrRunning == "1" and TaskManager.currentTask.contentId) then
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
			if ( not ml_blacklist.CheckBlacklistEntry("Fates", fate.id) and
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
							if ( ( (not nearestFate or (nearestFate and (distance < nearestDistance) ))  and (gTmgrRunning == "0" or (gTmgrRunning == "1" and TaskManager.currentTask.fateId ==""))) or (gTmgrRunning =="1" and fate.id == TaskManager.currentTask.fateId)) then
								-- dbg("fateid: "..tostring(fate.id).."gTmgrRunning: "..tostring(gTmgrRunning))"
								nearestFate = shallowcopy(fate)
								nearestDistance = distance
							end
						end
					end
				end
            end
        end
    
        if (nearestFate ~= nil) then
			local fate = nearestFate
			-- dbg("Fate details: Name="..fate.name..",id="..tostring(fate.id)..",completion="..tostring(fate.completion)..",pos="..tostring(fate.x)..","..tostring(fate.y)..","..tostring(fate.z))
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
		if(gTmgrRunning == "1" and TaskManager.currentTask.fateId ~= nil and self.fateid == TaskManager.currentTask.fateId) then
			-- There is a hight chance that if we started the FATE after 50% progression we won't get the gold medal
			-- if(TaskManager.fateCompletion <= 50) then
				TaskManager.fateComplete= true
				dbg("Zodiac book fate completed")
			-- 
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
    
	-- If TM is enabled and the current task is a FATE we replace the coords so the bot will wait at the FATE spawn
	if(gTmgrRunning == "1" and TaskManager.currentTask and TaskManager.currentTask.fateId) then
		newTask.pos = TaskManager.currentTask.location
	end
	
    newTask.remainMounted = true
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

--OVERRIDDEN METHODS-- FFXIV_TASK_DUTY.LUA

function e_leaveduty:execute()
	if not ControlVisible("ContentsFinder") then
		Player:Stop()
        ActionList:Cast(33,0,10)
		ml_task_hub:ThisTask().leaveTimer = Now() + 2000
    elseif ControlVisible("ContentsFinder") and not ControlVisible("SelectYesno") then
        PressDutyJoin()
		ml_task_hub:ThisTask().leaveTimer = Now() + 2000
	elseif ControlVisible("ContentsFinder") and ControlVisible("SelectYesno") then
        PressYesNo(true)
		if(gTmgrRunning == "1" and TaskManager.currentTask and TaskManager.currentTask.mode == "Duty" and TaskManager.lastticks - TaskManager.lastDutyCountTick > 10000) then
				TaskManager.dutyCount = TaskManager.dutyCount +1
				TaskManager.lastDutyCountTick = TaskManager.lastticks
				dbg("Adding duty count")
		end
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

function e_dead:execute()
    ml_debug("Respawning...")
	-- The player will tp to the next task
	TaskManager.taskState = 5
	-- try raise first
    if(PressYesNo(true)) then
		c_dead.timer = 0
		return
    end
	-- press ok
    if(PressOK()) then
		c_dead.timer = 0
		return
    end
end


--OVERRIDDEN METHODS-- FFXIV_TASK_QUEST.LUA
-- function c_nextquest:evaluate()
-- 	local currQuest = tonumber(Settings.FFXIVMINION.gCurrQuestID)

-- 	if (currQuest ~= nil and 
-- 		Quest:HasQuest(currQuest) and
-- 		ValidTable(ffxiv_task_quest.questList[currQuest]))
-- 	then
-- 		e_nextquest.quest = ffxiv_task_quest.questList[currQuest]
-- 		return true
-- 	end
	
-- 	for id, quest in pairsByKeys(ffxiv_task_quest.questList) do
-- 		if (Quest:HasQuest(quest.id)) then
-- 			e_nextquest.quest = quest
-- 			return true
-- 		end
-- 	end

-- 	for id, quest in pairsByKeys(ffxiv_task_quest.questList) do
-- 		if (quest:canStart()) then
-- 			e_nextquest.quest = quest
-- 			return true
-- 		end
-- 	end
	
-- 	TaskManager.questComplete = true
-- 	return false
-- end

RegisterEventHandler("Gameloop.Update",TaskManager.Update)
RegisterEventHandler("Module.Initalize",TaskManager.ModuleInit)
RegisterEventHandler("GUI.Update",TaskManager.GUIVarUpdate)