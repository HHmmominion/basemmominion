Tour = { }
Tour.lastticks = 0
Tour.aetheryteList = {
	[2] = {
		mapid = 132, x = 30.390216827393, y = 1.8258748054504, z = 26.265508651733
	},
	[3] = {
		mapid = 148, x = 13.585005760193, y = -1.1827243566513, z = 41.725193023682
	},
	[8] = {
		mapid = 129, x = -85.681526184082, y = 18.800333023071, z = -6.4848699569702
	},
	[52] = {
		mapid = 134, x = 224.27067565918, y = 113.09999084473, z = -261.05822753906
	},
	[10] = {
		mapid = 135, x = 156.93988037109, y = 14.09584903717, z = 668.01940917969
	},
	[11] = {
		mapid = 137, x = 490.56713867188, y = 17.416807174683, z = 474.01110839844
	},
	[12] = {
		mapid = 137, x = -20.159227371216, y = 70.599250793457, z = 7.4133810997009
	},
	[14] = {
		mapid = 138, x = 259.89932250977, y = -22.75, z = 223.38513183594
	},
	[13] = {
		mapid = 138, x = 652.9736328125, y = 9.2408666610718, z = 509.41586303711
	},
	[15] = {
		mapid = 139, x = 433.61944580078, y = 3.6090106964111, z = 92.736114501953
	},
	[16] = {
		mapid = 180, x = -122.27465820313, y = 64.79615020752, z = -211.87341308594
	},
	[4] = {
		mapid = 152, x = -189.0665435791, y = 4.4424576759338, z = 293.23275756836
	},
	[5] = {
		mapid = 153, x = 181.93789672852, y = 8.6657190322876, z = -66.213958740234
	},
	[6] = {
		mapid = 153, x = -226.1929473877, y = 21.010675430298, z = 355.90420532227
	},
	[7] = {
		mapid = 154, x = -45.544578552246, y = -39.256271362305, z = 230.90368652344
	},
	[9] = {
		mapid = 130, x = -143.30297851563, y = -3.1548881530762, z = -165.79141235352
	},
	[17] = {
		mapid = 140, x = 71.629104614258, y = 45.432174682617, z = -230.00273132324
	},
	[53] = {
		mapid = 141, x = -15.56315612793, y = -1.8785282373428, z = -169.75825500488
	},
	[18] = {
		mapid = 145, x = -379.7414855957, y = -59, z = 142.57489013672
	},
	[19] = {
		mapid = 146, x = -165.46360778809, y = 26.138355255127, z = -414.46130371094
	},
	[20] = {
		mapid = 146, x = -321.84567260742, y = 8.2604389190674, z = 406.19985961914
	},
	[21] = {
		mapid = 147, x = 21.909135818481, y = 6.9785833358765, z = 458.83193969727
	},
	[22] = {
		mapid = 147, x = -24.236480712891, y = 48.309478759766, z = -27.79927444458
	},
	[23] = {
		mapid = 155, x = 227.28480529785, y = 312, z = -229.6822052002
	},
	[24] = {
		mapid = 156, x = 48.166370391846, y = 20.295000076294, z = -667.26159667969
	},
}

function Tour.ModuleInit()
	--Add the new mode to the preload modes table and refresh it
	ffxivminion.AddMode("WorldTour", ffxiv_task_worldtour)
end

ffxiv_task_worldtour = inheritsFrom(ml_task)
ffxiv_task_worldtour.name = "LT_WORLDTOUR"
function ffxiv_task_worldtour.Create()
    local newinst = inheritsFrom(ffxiv_task_worldtour)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    newinst.name = "LT_WORLDTOUR"
    
    return newinst
end

function ffxiv_task_worldtour:UIInit()
	ffxivminion.Windows.WorldTour = { id = "WorldTour", Name = "WorldTour", x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.WorldTour)
	
	local winName = "WorldTour"
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].botMode,"gBotMode",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].skillProfile,"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,strings[gCurrentLanguage].navmesh ,"gmeshname",group,ffxivminion.Strings.Meshes())
	GUI_NewCheckbox(winName,strings[gCurrentLanguage].botEnabled,"gBotRunning",group)

	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
end

function ffxiv_task_worldtour:Init()
    --init Process() cnes
	local ke_tourNextLocation = ml_element:create( "NextLocation", c_nexttourlocation, e_nexttourlocation, 25 )
    self:add(ke_tourNextLocation, self.process_elements)
	
	local ke_moveToAetheryte = ml_element:create( "MoveToAetheryte", c_movetoaetheryte, e_movetoaetheryte, 23 )
    self:add(ke_moveToAetheryte, self.process_elements)

    self:AddTaskCheckCEs()
end

function ffxiv_task_worldtour.task_complete_eval()
	if (GetClosestUnattuned() == nil) then
		return true
	end
	
	return false
end

function ffxiv_task_worldtour.task_complete_execute()
	if (gBotRunning == "1") then
		d("Your world tour is complete, congratulations superstar!")
		ml_task_hub:ToggleRun()
	end
end

function GetUnattunedAetherytes()
	local unattuned = {}
	local aetherytes = Tour.aetheryteList
	
	for id,aetheryte in pairs(aetherytes) do
		local adata = Player:GetAetheryteList()
		local found = false
		for k,v in pairs(adata) do
			if (id == v.id) then
				found = true
				if (not v.isattuned) then
					aetheryte.id = id
					table.insert(unattuned,aetheryte)
				end
			end
			if (found) then
				break
			end
		end
	end
	
	return unattuned
end

function GetClosestUnattuned()
	local unattunedAetherytes = GetUnattunedAetherytes()
	if (not ValidTable(unattunedAetherytes)) then
		return nil
	end
	
	local onMapAetherytes = {}
	local offMapAetherytes = {}
	
	for id,aetheryte in pairs(unattunedAetherytes) do
		if (aetheryte.mapid == Player.localmapid) then
			onMapAetherytes[id] = aetheryte
		else
			offMapAetherytes[id] = aetheryte
		end	
	end
	
	if (ValidTable(onMapAetherytes)) then
		local closest = nil
		local closestDistance = 2000
		local ppos = shallowcopy(Player.pos)
		
		for id,aetheryte in pairs(onMapAetherytes) do
		d(id)
			local dist = Distance3D(ppos.x,ppos.y,ppos.z,aetheryte.x,aetheryte.y,aetheryte.z)
			if (not closest or dist < closestDistance) then
				closest = aetheryte
				closestDistance = dist
			end
		end
		
		return closest
	else
		local closest = nil
		local closestDistance = 2000
		
		for id,aetheryte in pairs(offMapAetherytes) do
			local currNode = ml_nav_manager.GetNode(Player.localmapid)	
			local destNode = ml_nav_manager.GetNode(aetheryte.mapid)	
			
			if(ValidTable(currNode) and ValidTable(destNode)) then
				local path = ml_nav_manager.GetPath(currNode, destNode)
				if (ValidTable(path)) then
					local pathSize = TableSize(path)
					if (not closest or pathSize < closestDistance) then
						closest = aetheryte
						closestDistance = pathSize
					end
				end
			else
				d("Couldn't generate nodes for " .. currNode .. " and " .. destNode)
			end
		end
		
		return closest
	end
end

c_nexttourlocation = inheritsFrom( ml_cause )
e_nexttourlocation = inheritsFrom( ml_effect )
e_nexttourlocation.mapID = 0
e_nexttourlocation.pos = 0
function c_nexttourlocation:evaluate()
	if (not IsPositionLocked()) then
		local bestUnattuned = GetClosestUnattuned()
		if (bestUnattuned and bestUnattuned.mapid ~= Player.localmapid) then
			local mapID = bestUnattuned.mapid
			local pos = ml_nav_manager.GetNextPathPos( Player.pos, Player.localmapid, mapID )
			if(ValidTable(pos)) then
				e_nexttourlocation.mapID = mapID
				e_nexttourlocation.pos = {x = bestUnattuned.x, y = bestUnattuned.y, z = bestUnattuned.z} 
				return true
			else
				--ml_debug("No path found from map "..tostring(Player.localmapid).." to map "..tostring(mapID))
			end
		end
	end
	
	return false
end
function e_nexttourlocation:execute()
	local task = ffxiv_task_movetomap.Create()
	task.destMapID = e_nexttourlocation.mapID
	task.pos = e_nexttourlocation.pos
	ml_task_hub:CurrentTask():AddSubTask(task)
end

c_movetoaetheryte = inheritsFrom( ml_cause )
e_movetoaetheryte = inheritsFrom( ml_effect )
e_movetoaetheryte.pos = 0
e_movetoaetheryte.id = 0
function c_movetoaetheryte:evaluate()
	if (not IsPositionLocked() and not ActionList:IsCasting()) then
		local bestUnattuned = GetClosestUnattuned()
		if (bestUnattuned and bestUnattuned.mapid == Player.localmapid) then
			local apos = {x = bestUnattuned.x, y = bestUnattuned.y, z = bestUnattuned.z}
			local ppos = shallowcopy(Player.pos)
			local dist = Distance2D(ppos.x,ppos.z,apos.x,apos.z)
			
			if(dist > 5) then
				e_movetoaetheryte.pos = apos
				e_movetoaetheryte.id = bestUnattuned.id
				return true
			end
		end
	end
	
	return false
end
function e_movetoaetheryte:execute()
	local task = ffxiv_task_movetoaetheryte.Create()
	task.pos = e_movetoaetheryte.pos
	task.uniqueid = e_movetoaetheryte.id
	ml_task_hub:CurrentTask():AddSubTask(task)
end

ffxiv_task_movetoaetheryte = inheritsFrom(ml_task)
function ffxiv_task_movetoaetheryte.Create()
    local newinst = inheritsFrom(ffxiv_task_movetoaetheryte)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "MOVETOAETHERYTE"
	
	newinst.uniqueid = 0
	newinst.interact = 0
    newinst.lastinteract = 0
	newinst.delayTimer = 0
	newinst.conversationIndex = 0
	newinst.pos = false
	newinst.range = nil
	newinst.areaChanged = false
	newinst.addedMoveElement = false
	newinst.use3d = true
	newinst.lastDistance = nil
	
	GameHacks:SkipDialogue(true)
	
    return newinst
end

function ffxiv_task_movetoaetheryte:Init()
	self:AddTaskCheckCEs()
end

function ffxiv_task_movetoaetheryte:task_complete_eval()
	if (IsPositionLocked() or IsLoading() or ControlVisible("SelectString") or ControlVisible("SelectIconString") or IsShopWindowOpen()) then
		return true
	end
	
	if (self.interact ~= 0) then
		local interact = EntityList:Get(tonumber(self.interact))
		if (not interact or not interact.targetable or (self.lastDistance and interact.distance > (self.lastDistance * 1.5))) then
			return true
		end
	end

	if (self.pos and ValidTable(self.pos)) then
		if (not self.addedMoveElement) then
			local ke_useNavInteraction = ml_element:create( "UseNavInteraction", c_usenavinteraction, e_usenavinteraction, 26 )
			self:add( ke_useNavInteraction, self.process_elements)
	
			local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 25 )
			self:add( ke_teleportToPos, self.process_elements)
			
			local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 20 )
			self:add( ke_mount, self.process_elements)
			self.addedMoveElement = true
		end
	end
	
	if (Player.ismounted and Now() > self.delayTimer) then
		local interacts = EntityList("nearest,contentid="..tostring(self.uniqueid)..",maxdistance=10")
		if (ValidTable(interacts)) then
			Dismount()
			self.delayTimer = 1000
		end
	end
	
	if (self.interact == 0) then
		if (self.uniqueid ~= 0) then
			local interacts = EntityList("nearest,contentid="..tostring(self.uniqueid)..",maxdistance=10")
			if (interacts) then
				local i,interact = next(interacts)
				if (interact) then
					self.interact = interact.id
				end
			end
		end
	end
	
	if (not Player:GetTarget() and self.interact ~= 0) then
		local interact = EntityList:Get(tonumber(self.interact))
		if (interact and interact.targetable) then
			Player:SetTarget(self.interact)
			local ipos = shallowcopy(interact.pos)
			if (not deepcompare(ipos,self.pos)) then
				self.pos = shallowcopy(ipos)
			end
		end
	end
	
	local range = self.range
	if (Player:GetTarget() and self.interact ~= 0 and Now() > self.lastinteract) then
		if (not IsLoading() and not IsPositionLocked()) then
			local interact = EntityList:Get(tonumber(self.interact))
			local radius = (interact.hitradius >= 1 and interact.hitradius) or 1
			if (range) then
				if (interact and interact.distance <= range) then
					Player:SetFacing(interact.pos.x,interact.pos.y,interact.pos.z)
					Player:Interact(interact.id)
					self.lastDistance = interact.distance
					self.lastinteract = Now() + 500
				end
			else
				if (interact and interact.distance < (radius * 4)) then
					Player:SetFacing(interact.pos.x,interact.pos.y,interact.pos.z)
					Player:Interact(interact.id)
					self.lastDistance = interact.distance
					self.lastinteract = Now() + 500
				end
			end
		end
	end
	
	if (ValidTable(self.pos)) then
		Player:MoveTo(self.pos.x,self.pos.y,self.pos.z)
	end
	
	return false
end

function ffxiv_task_movetoaetheryte:task_complete_execute()
    Player:Stop()
	GameHacks:SkipDialogue(gSkipDialogue == "1")
	self.completed = true
end

function ffxiv_task_movetoaetheryte:task_fail_eval()
    if (not Player.alive) then
		return true
	end
	
	return false
end

function ffxiv_task_movetoaetheryte:task_fail_execute()
	GameHacks:SkipDialogue(gSkipDialogue == "1")
    self.valid = false
end

RegisterEventHandler("Module.Initalize",Tour.ModuleInit)