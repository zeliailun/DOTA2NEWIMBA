-- Editors:
-- MysticBug, 20.09.2021
-- Extra API

function CheckBumped(hCaster,vLocation)
	--初始化kv
	local tree_radius = 120
	local wall_radius = 50
	local building_radius = 30
	local blocker_radius = 70
	--查看是否遇到墙 类似玛尔斯大招的墙
	local arena_walls = Entities:FindAllByClassnameWithin( "npc_dota_phantomassassin_gravestone", vLocation, wall_radius )
	for _,arena_wall in pairs(arena_walls) do
		if arena_wall:HasModifier( "modifier_mars_arena_of_blood_lua_blocker" ) then
			return true		
		end
	end
	--查看是否遇到地图边界墙
	local thinkers = Entities:FindAllByClassnameWithin( "npc_dota_thinker", vLocation, wall_radius )
	for _,thinker in pairs(thinkers) do
		if thinker:IsPhantomBlocker() then
			return true
		end
	end
	--查看是否遇到悬崖
	local base_loc = GetGroundPosition( vLocation, hCaster )
	local search_loc = GetGroundPosition( base_loc + hCaster:GetForwardVector() * wall_radius, hCaster )
	if search_loc.z-base_loc.z>10 and (not GridNav:IsTraversable( search_loc )) then
		return true
	end
	--查看是否遇到树
	if GridNav:IsNearbyTree( vLocation, tree_radius, false) then
		return true
	end
	--查看是否遇到建筑
	local buildings = FindUnitsInRadius(
		hCaster:GetTeamNumber(),	-- int, your team number
		vLocation,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		building_radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_BOTH,	-- int, team filter
		DOTA_UNIT_TARGET_BUILDING,	-- int, type filter
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)
	if #buildings>0 then
		return true
	end
	return false
end

----------------------------------------------------------
--		   		 RANGER_SLIDING_SHOOTING               	--
----------------------------------------------------------
ranger_sliding_shooting = class({})

LinkLuaModifier("modifier_ranger_sliding_shooting", "mb/ranger/ranger_sliding_shooting.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ranger_sliding_shooting_motion", "mb/ranger/ranger_sliding_shooting.lua", LUA_MODIFIER_MOTION_NONE)

function ranger_sliding_shooting:IsHiddenWhenStolen() 	return false end
function ranger_sliding_shooting:IsRefreshable() 		return true  end
function ranger_sliding_shooting:IsStealable() 			return true  end
function ranger_sliding_shooting:GetCastRange(location, target)
	if IsClient() then return self.BaseClass.GetCastRange(self, location, target) end 
end

function ranger_sliding_shooting:OnSpellStart()
	local caster      = self:GetCaster()
	local caster_pos  = caster:GetAbsOrigin()
	local target_pos  = self:GetCursorPosition()
	local direction   = (target_pos ~= caster_pos and (target_pos - caster_pos):Normalized()) or caster:GetForwardVector()
	      direction.z = 0.0
	local pos         = (target_pos - caster_pos):Length2D() <= self:GetSpecialValueFor("slide_range") and target_pos or caster_pos + direction * self:GetSpecialValueFor("slide_range")
	local duration    = self:GetSpecialValueFor("slide_duration");
	caster:AddNewModifier(caster, self, "modifier_ranger_sliding_shooting_motion", {duration = duration, pos_x = pos.x, pos_y = pos.y, pos_z = pos.z})
	caster:EmitSound("Ability.MKG_AssassinateLoad")
	ProjectileManager:ProjectileDodge(caster)
	caster:Purge(false, true, false, false, false)
end

modifier_ranger_sliding_shooting_motion = class({})

function modifier_ranger_sliding_shooting_motion:IsDebuff()			return false end
function modifier_ranger_sliding_shooting_motion:IsHidden() 			return true end
function modifier_ranger_sliding_shooting_motion:IsPurgable() 		return false end
function modifier_ranger_sliding_shooting_motion:IsPurgeException() 	return false end
function modifier_ranger_sliding_shooting_motion:IsStunDebuff()		return true end
function modifier_ranger_sliding_shooting_motion:CheckState() return {[MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_DISARMED] = true, [MODIFIER_STATE_MAGIC_IMMUNE] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true} end
function modifier_ranger_sliding_shooting_motion:DeclareFunctions() return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_DISABLE_TURNING,MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,MODIFIER_PROPERTY_OVERRIDE_ANIMATION_WEIGHT} end
function modifier_ranger_sliding_shooting_motion:GetModifierDisableTurning() return 1 end
function modifier_ranger_sliding_shooting_motion:GetOverrideAnimation() return ACT_DOTA_TAUNT end
function modifier_ranger_sliding_shooting_motion:GetActivityTranslationModifiers() return "taunt_quickdraw_gesture" end
function modifier_ranger_sliding_shooting_motion:IsMotionController() return true end
function modifier_ranger_sliding_shooting_motion:GetMotionControllerPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end

function modifier_ranger_sliding_shooting_motion:OnCreated(keys)
	if IsServer() then
		self.caster = self:GetCaster()
		self.parent = self:GetParent()
		self.ability = self:GetAbility()
		self.hitted = {}
		self.pos = Vector(keys.pos_x, keys.pos_y, keys.pos_z)
		self.speed = self.ability:GetSpecialValueFor("slide_range") / self.ability:GetSpecialValueFor("slide_duration");
		--Check pos
		--print("Bumped Tree",GridNav:CanFindPath(self.parent:GetAbsOrigin(), self.pos),GridNav:FindPathLength(self.parent:GetAbsOrigin(), self.pos),self.parent:GetForwardVector())
		--[[if not GridNav:CanFindPath(self.parent:GetAbsOrigin(), self.pos) then 
			--self.pos = self.parent:GetAbsOrigin() + self.parent:GetForwardVector() * math.max(GridNav:FindPathLength(self.parent:GetAbsOrigin(), self.pos),25)
		end]]
		--if self:CheckMotionControllers() then
		self:OnIntervalThink()
		self:StartIntervalThink(FrameTime())
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_magnataur/magnataur_skewer.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControlEnt(pfx, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_horn", self.parent:GetAbsOrigin(), true)
		self:AddParticle(pfx, false, false, 15, false, false)
		--else
		--	self:Destroy()
		--end
	end
end

function modifier_ranger_sliding_shooting_motion:OnIntervalThink()
	local current_pos = self.parent:GetAbsOrigin()
	local distacne = self.speed / (1.0 / FrameTime())
	local direction = (self.pos - current_pos):Normalized()
	direction.z = 0
	local next_pos = GetGroundPosition((current_pos + direction * distacne), nil)
	self.parent:SetOrigin(next_pos)
	local horn_pos = self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_horn"))
	local enemies = FindUnitsInRadius(self.parent:GetTeamNumber(), self.parent:GetAbsOrigin(), nil, self:GetAbility():GetSpecialValueFor("slide_width"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_DAMAGE_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		if not IsInTable(enemy, self.hitted) then
			--attack once
			self.caster:PerformAttack(enemy, false, true, true, false, true, false, false)
			self.hitted[#self.hitted+1] = enemy
		end
	end
	if CheckBumped(self.parent,next_pos) then 
		self.parent:SetOrigin(GetGroundPosition(horn_pos, nil))
		self:Destroy()
	end 
end

function modifier_ranger_sliding_shooting_motion:OnDestroy()
	if IsServer() then
		FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
		self.hitted = nil
		self.pos = nil
		self.speed = nil
		self.parent:SetForwardVector(Vector(self.parent:GetForwardVector()[1], self.parent:GetForwardVector()[2], 0))
		--刷新手雷
		if self.parent:HasAbility("ranger_electric_grenade") then
			self.parent:FindAbilityByName("ranger_electric_grenade"):EndCooldown()
		end
	end
end