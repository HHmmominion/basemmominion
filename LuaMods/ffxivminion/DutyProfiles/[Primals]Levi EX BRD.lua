ffxiv_kill_levi = inheritsFrom(ml_task)
function ffxiv_kill_levi.Create()
    local newinst = inheritsFrom(ffxiv_kill_levi)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
	newinst.name = "DUTY_KILL_LEVI"
	newinst.timer = 0
	newinst.failed = false
	newinst.failTimer = 0
	newinst.encounterData = {}
	newinst.suppressFollow = false
	newinst.suppressFollowTimer = 0
	newinst.suppressAssist = false
	newinst.pullHandled = false
	newinst.hasSynced = false
	
	newinst.immunePulses = 0
	newinst.lastEntity = nil
	newinst.lastHPPercent = 100
	newinst.immuneMax = 80
	newinst.currentPos = nil
	
	newinst.noTelecast = false
	newinst.noTelecastTimer = 0
	
    return newinst
end

function ffxiv_kill_levi:Process()	
	if (not self.hasSynced) then
		Player:SetFacingSynced(Player.pos.h)
		self.hasSynced = true
	end
	
	local killPercent = nil
	if ( self.encounterData["killto%"]) then
		killPercent = tonumber(self.encounterData["killto%"])
	end

	local entity = GetDutyTarget(killPercent)
	
	local myPos = shallowcopy(Player.pos)
	local fightPos = nil
	if (self.encounterData.fightPos) then
		fightPos = self.encounterData.fightPos["General"]
	end
	
	local startPos = nil
	if (self.encounterData.startPos) then
		startPos = self.encounterData.startPos["General"]
	end
	
	if (fightPos and self.pullHandled) then
		self.currentPos = fightPos
	else
		self.currentPos = startPos
	end
	
	if (fightPos and self.pullHandled and Distance3D(myPos.x,myPos.y,myPos.z,fightPos.x,fightPos.y,fightPos.z) > 1) then
		GameHacks:TeleportToXYZ(fightPos.x, fightPos.y, fightPos.z)
		if (ValidTable(entity)) then
			SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
		else
			Player:SetFacing(Player.pos.h)
		end
	elseif (startPos and fightPos == nil and Distance3D(myPos.x,myPos.y,myPos.z,startPos.x,startPos.y,startPos.z) > 1 and TableSize(SkillMgr.teleBack) == 0) then
		GameHacks:TeleportToXYZ(startPos.x, startPos.y, startPos.z)
		if (ValidTable(entity)) then
			SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
		else
			Player:SetFacing(Player.pos.h)
		end
	end
	
	local el = EntityList("contentid=2550")
	if (ValidTable(el)) then
		for id,target in pairs(el) do
			if (target.castinginfo.channelingid ~= 0) then
				d("Leviathan is channeling:"..tostring(target.castinginfo.channelingid))
			end
			if (target.castinginfo.castingid ~= 0) then
				if ((target.castinginfo.castingid == 1860 or target.castinginfo.castingid == 2165) and not self.noTelecast) then
					if (Distance3D(Player.pos.x,Player.pos.y,Player.pos.z,self.currentPos.x,self.currentPos.y,self.currentPos.z) > 1) then
						SkillMgr.teleBack = {}
						SkillMgr.teleCastTimer = 0
						GameHacks:TeleportToXYZ(self.currentPos.x, self.currentPos.y, self.currentPos.z)
						Player:SetFacingSynced(self.currentPos.h)
					end
					self.noTelecast = true
					self.noTelecastTimer = Now() + 10000
					d("setting no telecast for 8 seconds")
				end
			end
		end
	end
	
	if (self.noTelecast and Now() > self.noTelecastTimer) then
		d("unsetting no telecast")
		self.noTelecast = false
		self.noTelecastTimer = 0
	end
	
	if (ValidTable(entity)) then
		--d("Attacking current entity:"..tostring(entity.name)..",id:"..tostring(entity.id)..",contentid:"..tostring(entity.uniqueid)..",attackable:"..tostring(entity.attackable))
		if (self.lastEntity == nil or self.lastEntity ~= entity.id) then
			self.lastEntity = entity.id
			self.lastHPPercent = entity.hp.percent
			self.immunePulses = 0
		elseif (self.lastEntity == entity.id) then
			if (self.lastHPPercent == entity.hp.percent) then
				self.immunePulses = self.immunePulses + 1
			elseif (self.lastHPPercent > entity.hp.percent) then
				self.lastHPPercent = entity.hp.percent
				self.immunePulses = 0
			end
		end
		
		if (fightPos and not self.pullHandled) then
			--fightPos is for handling pull situations
			if (entity.targetid == 0) then
				Player:SetTarget(entity.id)
				SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
				SkillMgr.Cast( entity )
				self.hasFailed = false
			else
				GameHacks:TeleportToXYZ(fightPos.x, fightPos.y, fightPos.z)
				SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
				self.pullHandled = true
			end
		elseif (ml_task_hub:CurrentTask().encounterData.doKill ~= nil and 
				ml_task_hub:CurrentTask().encounterData.doKill == false ) then
					if (entity.targetid == 0) then
						Player:SetTarget(entity.id)
						SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
						SkillMgr.Cast( entity )
						self.hasFailed = false
					else
						self.hasFailed = true
					end
		elseif (ml_task_hub:CurrentTask().encounterData.doKill == nil or 
				ml_task_hub:CurrentTask().encounterData.doKill == true) then
					self.hasFailed = false
					
					local pos = entity.pos
					Player:SetTarget(entity.id)
					
					--Telecasting, teleport to mob portion.
					if (ml_global_information.AttackRange < 5 and 
						gUseTelecast == "1" and 
						not self.noTelecast and 
						entity.castinginfo.channelingid == 0 and
						gTeleport == "1" and 
						SkillMgr.teleCastTimer == 0 and 
						SkillMgr.IsGCDReady() and 
						(entity.targetid ~= Player.id or self.encounterData.telecastAlways) and 
						Player.hp.percent > 30) 
					then
						self.suppressFollow = true
						self.suppressFollowTimer = Now() + 2000
						
						SkillMgr.teleBack = self.currentPos

						if (self.encounterData.telecastPos) then
							local telePos = self.encounterData.telecastPos
							GameHacks:TeleportToXYZ(telePos.x,telePos.y,telePos.z)
							Player:SetFacingSynced(pos.x,pos.y,pos.z)
						else
							GameHacks:TeleportToXYZ(pos.x + 1,pos.y, pos.z)
							Player:SetFacingSynced(pos.x,pos.y,pos.z)
						end
						
						SkillMgr.teleCastTimer = Now() + 1500
					end
					
					SetFacing(pos.x, pos.y, pos.z)
					SkillMgr.Cast( entity )
					
					if (TableSize(SkillMgr.teleBack) > 0) then
						returnable = false
						
						if (Now() > SkillMgr.teleCastTimer) then
							returnable = true
							--d("setting returnable in clause 1 - timer is up")
						end
						
						if (not entity.attackable) then
							returnable = true
						end
						
						if (entity.castinginfo.channelingid ~= 0) then
							returnable = true
							--d("setting returnable in clause 2 - enemy is casting")
						end
						
						if (entity.targetid == Player.id and not self.encounterData.telecastAlways) then
							returnable = true
							--d("setting returnable in clause 3 - enemy is targeting player and telecast always is not set")
						end
						
						if (Player.hp.percent < 30) then
							returnable = true
							--d("setting returnable in clause 4 - player has less than 30% hp")
						end
						
						if (Distance3D(Player.pos.x,Player.pos.y,Player.pos.z,pos.x,pos.y,pos.z) > (entity.hitradius + 5)) then
							returnable = true
							--d("setting returnable in clause 5 - distance from entity too far")
						end
						
						if (returnable) then
							local back = SkillMgr.teleBack
							--d("teleporting back")
							GameHacks:TeleportToXYZ(back.x, back.y, back.z)
							Player:SetFacingSynced(back.h)
							SkillMgr.teleBack = {}
							SkillMgr.teleCastTimer = 0
						end
					end
					
		end
	else
		if (Distance3D(Player.pos.x,Player.pos.y,Player.pos.z,self.currentPos.x,self.currentPos.y,self.currentPos.z) > 1) then
			--d("No entities found, returning to initial position.")
			SkillMgr.teleBack = {}
			SkillMgr.teleCastTimer = 0
			GameHacks:TeleportToXYZ(self.currentPos.x, self.currentPos.y, self.currentPos.z)
			Player:SetFacingSynced(self.currentPos.h)
		end
		d("Entity not targetable, using self as target.")
		SkillMgr.Cast( Player, true )
		self.hasFailed = true
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

function ffxiv_kill_levi:task_complete_eval()
	-- If the task has failed and we haven't yet started the countdown, start it.
	local el = EntityList("contentid=2550")
	if (not ValidTable(el)) then
		return true
	end
	
    return false
end
function ffxiv_kill_levi:task_complete_execute()
	d("Levi kill ending..")
    ml_task_hub:CurrentTask().completed = true
	ml_task_hub:CurrentTask():ParentTask().encounterCompleted = true
end

function ffxiv_kill_levi:Init()	
	local ke_dutyAvoid = ml_element:create( "DutyAvoid", c_dutyavoid, e_dutyavoid, 35 )
    self:add( ke_dutyAvoid, self.overwatch_elements)
	
    self:AddTaskCheckCEs()
end

