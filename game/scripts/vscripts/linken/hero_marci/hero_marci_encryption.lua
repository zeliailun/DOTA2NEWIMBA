imba_marci_companion_run = class({})
LinkLuaModifier("modifier_imba_companion_run_move", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_jump", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_adhere", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_auto", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_auto2", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_pfx", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_buff", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_debuff", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_sce_debuff", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
--function imba_marci_companion_run:GetIntrinsicModifierName() return "modifier_imba_companion_run_auto" end
--[[function imba_marci_companion_run:GetManaCost(a) 
	if self:GetCaster():HasModifier("modifier_imba_companion_run_adhere") then  
		return 0	
	end
	return 90 
end
function imba_marci_companion_run:GetCastPoint() 
	if self:GetCaster():HasModifier("modifier_imba_companion_run_adhere") then  
		return 0	
	end
	return 0.1     
end
function imba_marci_companion_run:GetCastRange()
	if self:GetCaster():HasModifier("modifier_imba_companion_run_adhere") then 
		return 99999
	else
		return self:GetSpecialValueFor("cast_range") + self:GetCaster():GetCastRangeBonus()
	end
end]]
--[[function imba_marci_companion_run:GetBehavior() 
	if self:GetCaster():HasModifier("modifier_imba_companion_run_auto2") then
		if self:GetCaster():HasModifier("modifier_imba_companion_run_adhere") or self:GetCaster():HasModifier("modifier_imba_companion_run_move") then
			return 	
					DOTA_ABILITY_BEHAVIOR_POINT + 
					DOTA_ABILITY_BEHAVIOR_UNIT_TARGET +
					DOTA_ABILITY_BEHAVIOR_AOE +
					DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES +
					DOTA_ABILITY_BEHAVIOR_IGNORE_SILENCE

		else
			return 	
					DOTA_ABILITY_BEHAVIOR_UNIT_TARGET +
					DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES +
					DOTA_ABILITY_BEHAVIOR_AUTOCAST +
					DOTA_ABILITY_BEHAVIOR_IGNORE_SILENCE
		end
	else
		return 	
					DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + 
					DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING + 
					DOTA_ABILITY_BEHAVIOR_DONT_RESUME_MOVEMENT + 
					DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES +
					DOTA_ABILITY_BEHAVIOR_AUTOCAST +
					DOTA_ABILITY_BEHAVIOR_IGNORE_SILENCE
	end
end]]
function imba_marci_companion_run:CastFilterResultTarget( hTarget )
	if self:GetCaster() == hTarget then
		return UF_FAIL_CUSTOM
	end
	if self:GetCaster():IsHexed() then
		return UF_FAIL_CUSTOM
	end
	--[[local nResult = UnitFilter(
		hTarget,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_TREE + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		self:GetCaster():GetTeamNumber()
	)]]
	if nResult ~= UF_SUCCESS then
		return nResult
	end
	return UF_SUCCESS
end
function imba_marci_companion_run:CastFilterResultLocation( vLocation )
	self.pointcast = vLocation
	return UF_SUCCESS
end
function imba_marci_companion_run:GetCustomCastErrorTarget( hTarget )
	if self:GetCaster() == hTarget then
		return "#dota_hud_error_cant_cast_on_self"
	end
	if self:GetCaster():IsHexed() then
		return "#dota_hud_error_ability_inactive"
	end
end
function imba_marci_companion_run:GetCastRange() 
	local caster = self:GetCaster()	
	return self:GetSpecialValueFor("cast_range") + caster:TG_GetTalentValue("special_bonus_imba_marci_2")
end
function imba_marci_companion_run:OnSpellStart()
	local caster = self:GetCaster()	
	local min_range = self:GetSpecialValueFor("min_range")
	local move_speed = self:GetSpecialValueFor("move_speed")
	local landing_radius = self:GetSpecialValueFor("landing_radius")
    local tree_range = self:GetSpecialValueFor("tree_range")
    local tar_range = self:GetSpecialValueFor("tar_range")
	if self.targetcast == nil then
		self.targetcast = self:GetCursorTarget()
		if self.targetcast:GetMaxHealth() ~= 0 then
			self.agh = false
		elseif self.targetcast:GetMaxHealth() == 0  then
			self.agh = true
		end
	end
	if caster:HasScepter() then
		self.agh = false
	end
	TG_Remove_Modifier(caster,"modifier_imba_companion_run_pfx",0)
	--[[if self:GetCaster():HasModifier("modifier_imba_companion_run_auto2") then
		if not caster:HasModifier("modifier_imba_companion_run_adhere") then
			local target = self:GetCursorTarget()
			caster:AddNewModifier(
				caster, 
				self, 
				"modifier_imba_companion_run_move", 
				{
					duration = 5,
					target = target:entindex(),
					int = 0
				})
			self:EndCooldown()
		else
			local pos = self:GetCursorPosition()
			if CalculateDistance(caster:GetAbsOrigin(), pos)  > self:GetSpecialValueFor("cast_range") + caster:GetCastRangeBonus() then
				pos = caster:GetAbsOrigin() + GetDirection2D(pos, caster:GetAbsOrigin()) * (self:GetSpecialValueFor("cast_range") + caster:GetCastRangeBonus())
			elseif CalculateDistance(caster:GetAbsOrigin(), pos)  < min_range then
				pos = caster:GetAbsOrigin() + GetDirection2D(pos, caster:GetAbsOrigin()) * min_range
			end
			local target = self:GetCursorTarget()
			local duration = 1
			if target then
				duration = CalculateDistance(caster:GetAbsOrigin(), target:GetAbsOrigin()) / move_speed
				target = target:entindex()
			end
			if pos then
				duration = CalculateDistance(pos, caster:GetAbsOrigin()) / move_speed
			end
			TG_Remove_Modifier(caster,"modifier_imba_companion_run_adhere",0)
			caster:AddNewModifier(
				caster, 
				self, 
				"modifier_imba_companion_run_jump", 
				{
					duration = duration,
					pos = pos,
					target = target,
				})
		end
	else]]
		local target = self.targetcast
		local point = self.pointcast	
		local duration = CalculateDistance(caster:GetAbsOrigin(), target:GetAbsOrigin()) / move_speed
		local tar_range = self:GetSpecialValueFor("tar_range") + caster:GetCastRangeBonus() + caster:TG_GetTalentValue("special_bonus_imba_marci_2")
		if CalculateDistance(target:GetAbsOrigin(), point)  > tar_range then
			point = target:GetAbsOrigin() + GetDirection2D(point, target:GetAbsOrigin()) * (tar_range)
		elseif CalculateDistance(target:GetAbsOrigin(), point)  < min_range then
			point = target:GetAbsOrigin() + GetDirection2D(point, target:GetAbsOrigin()) * min_range
		end
		if self.agh then
			--print("目标是树")
			point = target:GetAbsOrigin() + GetDirection2D(point, target:GetAbsOrigin()) * tree_range
		else
			--print("目标是单位")
		end
		
		local pfx = ParticleManager:CreateParticleForPlayer("particles/ui_mouseactions/range_finder_cone.vpcf", PATTACH_POINT, caster, caster:GetPlayerOwner())
		ParticleManager:SetParticleControl(pfx, 1, GetGroundPosition(caster:GetAbsOrigin(), nil)) 
		ParticleManager:SetParticleControl(pfx, 2, GetGroundPosition(self.targetcast:GetAbsOrigin(), nil))
		if pfx then
			Timers:CreateTimer(0.7, function()
				ParticleManager:DestroyParticle(pfx, false)
				ParticleManager:ReleaseParticleIndex(pfx)
				return nil
			end)
		end
		local pfx2 = ParticleManager:CreateParticleForPlayer("particles/ui_mouseactions/range_finder_cone.vpcf", PATTACH_POINT, caster, caster:GetPlayerOwner())
		ParticleManager:SetParticleControl(pfx2, 1, GetGroundPosition(self.targetcast:GetOrigin(), nil)) 
		ParticleManager:SetParticleControl(pfx2, 2, GetGroundPosition(point, nil))
		if pfx then
			Timers:CreateTimer(0.7, function()
				ParticleManager:DestroyParticle(pfx2, false)
				ParticleManager:ReleaseParticleIndex(pfx2)
				return nil
			end)
		end
		local pfx1 = ParticleManager:CreateParticleForPlayer("particles/ui_mouseactions/range_finder_targeted_aoe.vpcf", PATTACH_POINT, caster, caster:GetPlayerOwner())
		ParticleManager:SetParticleControl(pfx1, 3, Vector(landing_radius, 0, 0))
		ParticleManager:SetParticleControl(pfx1, 2, point)
		if pfx1 then
			Timers:CreateTimer(0.7, function()
				ParticleManager:DestroyParticle(pfx1, false)
				ParticleManager:ReleaseParticleIndex(pfx1)
				return nil
			end)
		end
		caster:AddNewModifier(
				caster, 
				self, 
				"modifier_imba_companion_run_move", 
				{
					duration = duration,
					target = target:entindex(),
					pos = point,
					int = 1,
				})
	--end
	self.targetcast = nil
	self.agh = false
end	
modifier_imba_companion_run_move = class({})
function modifier_imba_companion_run_move:IsDebuff()			return false end
function modifier_imba_companion_run_move:IsHidden() 			return false end
function modifier_imba_companion_run_move:IsPurgable() 			return false end
function modifier_imba_companion_run_move:IsPurgeException() 	return false end
function modifier_imba_companion_run_move:CheckState() return 
    {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true, 
	[MODIFIER_STATE_STUNNED] = true,
	[MODIFIER_STATE_DISARMED] = true,
    } 
end
function modifier_imba_companion_run_move:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION_WEIGHT,
        
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, 
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
    }
end
function modifier_imba_companion_run_move:GetEffectName() return "particles/econ/events/fall_major_2016/force_staff_fm06.vpcf" end
function modifier_imba_companion_run_move:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_imba_companion_run_move:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_2_ALLY
end

function modifier_imba_companion_run_move:GetOverrideAnimationWeight()
    return 10
end

function modifier_imba_companion_run_move:GetModifierMoveSpeed_Absolute() 
    if IsServer()  then 
        return 1 
    end 
end
function modifier_imba_companion_run_move:GetModifierMoveSpeed_Limit() 
    if IsServer()  then 
        return 1 
    end 
end
function modifier_imba_companion_run_move:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.buff_duration = self.ability:GetSpecialValueFor("buff_duration")
	self.move_speed = self.ability:GetSpecialValueFor("move_speed")
	self.landing_radius = self.ability:GetSpecialValueFor("landing_radius")
	if IsServer() then
		self.target = EntIndexToHScript(keys.target)
		self.speed = self.move_speed
		self.int = keys.int
		if self.int == 1 then
			self.pos = StringToVector(keys.pos)
		end
		EmitSoundOn( "Hero_Marci.Rebound.Cast", self.caster )
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_imba_companion_run_move:OnRefresh(keys)
	self:OnCreated()
end
function modifier_imba_companion_run_move:OnIntervalThink(keys)
	AddFOWViewer(self.caster:GetTeamNumber(), self.target:GetAbsOrigin(), 30, FrameTime(), false)
	local pos = self.target:GetAbsOrigin()
	local speed = self.speed / (1 / FrameTime())
	local direction = GetDirection2D(pos, self.caster:GetAbsOrigin())
	local next_pos = self.caster:GetAbsOrigin() + direction * speed
	self.parent:SetAbsOrigin(next_pos)
	if CalculateDistance(self.target:GetAbsOrigin(), self.caster:GetAbsOrigin()) <= 50 or CalculateDistance(self.target:GetAbsOrigin(), self.caster:GetAbsOrigin()) > 2000 then
		self:Destroy()
	end
	if not self.target:IsAlive() or not self.target then
		self:Destroy()
		--self:GetAbility():StartCooldown((self:GetAbility():GetCooldown(self:GetAbility():GetLevel() -1 ) * self:GetCaster():GetCooldownReduction()) - (self:GetElapsedTime()))
	end
end
function modifier_imba_companion_run_move:OnRemoved()
	if IsServer() then
		if self.target and self.target:IsAlive() then
			if self.int == 0 then
				self.caster:AddNewModifier(
					self.caster, 
					self.ability, 
					"modifier_imba_companion_run_adhere", 
					{
						duration = 3,
						target = self.target:entindex(),
						time = self:GetElapsedTime(),
					})
			elseif self.int == 1 then
				local duration = CalculateDistance(self.caster:GetAbsOrigin(), self.pos) / self.speed
				self.caster:AddNewModifier(
					self.caster, 
					self.ability, 
					"modifier_imba_companion_run_jump", 
					{
						duration = duration,
						pos = self.pos,
					})
				if not IsEnemy(self.caster,self.target) then
					self.target:AddNewModifier(
						self.caster, 
						self.ability, 
						"modifier_imba_companion_run_buff", 
						{
							duration = self.buff_duration,
						})
				end
					
				local pfx_name = "particles/units/heroes/hero_marci/marci_rebound_landing_zone.vpcf"
				local pfx = ParticleManager:CreateParticle( pfx_name, PATTACH_WORLDORIGIN, nil )
				ParticleManager:SetParticleControl( pfx, 0, self.pos )
				ParticleManager:SetParticleControl( pfx, 1, Vector(self.landing_radius, self.landing_radius, self.landing_radius) )
				ParticleManager:ReleaseParticleIndex( pfx )

				local tree = {
					EffectName ="particles/econ/items/windrunner/windranger_arcana/windranger_arcana_spell_powershot.vpcf",
					Ability = self.ability,
					vSpawnOrigin =self.parent:GetAbsOrigin(),
					vVelocity =self.parent:GetForwardVector(),
					Source = self.parent,
					bHasFrontalCone = false,
					bReplaceExisting = false,
					iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_NONE,
					iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
					iUnitTargetType = DOTA_UNIT_TARGET_NONE,
					bProvidesVision = false,
				}
				ProjectileManager:CreateLinearProjectile( tree )
			end
		end
	end
end
modifier_imba_companion_run_adhere = class({})
function modifier_imba_companion_run_adhere:IsDebuff()			return false end
function modifier_imba_companion_run_adhere:IsHidden() 			return false end
function modifier_imba_companion_run_adhere:IsPurgable() 			return false end
function modifier_imba_companion_run_adhere:IsPurgeException() 	return false end
function modifier_imba_companion_run_adhere:CheckState() return 
    {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true, 
	[MODIFIER_STATE_DISARMED] = true,
	--[MODIFIER_STATE_STUNNED] = true,
    } 
end
function modifier_imba_companion_run_adhere:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION_WEIGHT,
        
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, 
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
    }
end
--function modifier_imba_companion_run_adhere:GetEffectName() return "particles/econ/events/fall_major_2016/force_staff_fm06.vpcf" end
--function modifier_imba_companion_run_adhere:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_imba_companion_run_adhere:GetOverrideAnimation()
    return ACT_DOTA_DEFEAT
end

function modifier_imba_companion_run_adhere:GetOverrideAnimationWeight()
    return 10
end

function modifier_imba_companion_run_adhere:GetModifierMoveSpeed_Absolute() 
    if IsServer()  then 
        return 1 
    end 
end
function modifier_imba_companion_run_adhere:GetModifierMoveSpeed_Limit() 
    if IsServer()  then 
        return 1 
    end 
end
function modifier_imba_companion_run_adhere:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	
	if IsServer() then
		self.target = EntIndexToHScript(keys.target)
		self.time = keys.time
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_imba_companion_run_adhere:OnRefresh(keys)
	self:OnCreated()
end
function modifier_imba_companion_run_adhere:OnIntervalThink(keys)
	if self.target and self.target:IsAlive() then
		self.parent:SetAbsOrigin(self.target:GetAbsOrigin()+Vector(0,0,200))
	elseif not self.target or not self.target:IsAlive() then
		self:Destroy()
	end
end
function modifier_imba_companion_run_adhere:OnRemoved()
	if IsServer() then
		if self:GetElapsedTime() == self:GetDuration() then
			--self:GetAbility():StartCooldown((self:GetAbility():GetCooldown(self:GetAbility():GetLevel() -1 ) * self:GetCaster():GetCooldownReduction()) - (self:GetElapsedTime()+self.time))
		end
	end
end

modifier_imba_companion_run_jump = class({})
function modifier_imba_companion_run_jump:IsDebuff()			return false end
function modifier_imba_companion_run_jump:IsHidden() 			return false end
function modifier_imba_companion_run_jump:IsPurgable() 			return false end
function modifier_imba_companion_run_jump:IsPurgeException() 	return false end
function modifier_imba_companion_run_jump:CheckState() return 
    {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true, 
	[MODIFIER_STATE_STUNNED] = true,
	[MODIFIER_STATE_DISARMED] = true,
    } 
end
function modifier_imba_companion_run_jump:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, 
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    }
end
function modifier_imba_companion_run_jump:GetOverrideAnimation()
	return ACT_DOTA_OVERRIDE_ABILITY_2
end
--function modifier_imba_companion_run_jump:GetEffectName() return "particles/econ/events/fall_major_2016/force_staff_fm06.vpcf" end
--function modifier_imba_companion_run_jump:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_imba_companion_run_jump:GetModifierMoveSpeed_Absolute() 
    if IsServer()  then 
        return 1 
    end 
end
function modifier_imba_companion_run_jump:GetModifierMoveSpeed_Limit() 
    if IsServer()  then 
        return 1 
    end 
end
function modifier_imba_companion_run_jump:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.debuff_duration = self.ability:GetSpecialValueFor("debuff_duration")
	self.landing_radius = self.ability:GetSpecialValueFor("landing_radius")
	self.move_speed = self.ability:GetSpecialValueFor("move_speed")
	self.impact_damage = self.ability:GetSpecialValueFor("impact_damage")
	if IsServer() then
		EmitSoundOn( "Hero_Marci.Rebound.Leap", self.caster )
		if keys.target then
			self.target = EntIndexToHScript(keys.target)
			self.parent:MoveToTargetToAttack(self.target)
		end
		if keys.pos then
			self.pos = StringToVector(keys.pos)
			self.parent:MoveToPosition(self.pos)
		end
		self.speed = self.move_speed
		
		local particle_cast = "particles/units/heroes/hero_marci/marci_rebound_bounce.vpcf"
		local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.caster )
		ParticleManager:SetParticleControlEnt(effect_cast, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_attack1", Vector(0,0,0), true)
		ParticleManager:SetParticleControlEnt(effect_cast, 3, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
		self:AddParticle(effect_cast, false, false, -1, false, false)	
		--self.parent:StartGestureWithPlaybackRate(ACT_DOTA_OVERRIDE_ABILITY_2,1)
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_imba_companion_run_jump:OnIntervalThink(keys)
	if self.pos and CalculateDistance(self.pos, self.caster:GetAbsOrigin()) >= 50 then
		local pos = self.pos
		local motion_progress = math.min(self:GetElapsedTime() / (self:GetDuration()), 1.0)
		local speed = self.speed / (1 / FrameTime())
		local direction = GetDirection2D(pos, self.caster:GetAbsOrigin())
		local next_pos = GetGroundPosition(self.caster:GetAbsOrigin() + direction * speed, nil)
		next_pos.z = next_pos.z - 4 * 250 * motion_progress ^ 2 + 4 * 250 * motion_progress
		self.parent:SetOrigin(next_pos)
	end
	if CalculateDistance(self.pos, self.caster:GetAbsOrigin()) > 50 then
		self.parent:FaceTowards( self.pos )
	end
end
function modifier_imba_companion_run_jump:OnRemoved()
	if IsServer() then
		self.parent:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_2_END,1)
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_marci/marci_rebound_bounce_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(pfx, 9, Vector(self.landing_radius,0,0)) 
		ParticleManager:SetParticleControl(pfx, 10, GetGroundPosition(self.parent:GetAbsOrigin(), nil))
		ParticleManager:ReleaseParticleIndex(pfx)
		GridNav:DestroyTreesAroundPoint( self.parent:GetOrigin(), 200, true )
		self.parent:MoveToPositionAggressive(self.parent:GetAbsOrigin())
		EmitSoundOn( "Hero_Marci.Rebound.Impact", self.caster )
		local enemies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),
			self:GetCaster():GetAbsOrigin(),
			nil,
			self.landing_radius ,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_CLOSEST,
			false)
		for _,enemy in pairs(enemies) do
			enemy:AddNewModifier(
			self.caster, 
			self.ability, 
			"modifier_imba_companion_run_debuff", 
			{
				duration = self.debuff_duration,
			})
			local damageTable = {
					victim = enemy,
					attacker = self.caster,
					damage = self.impact_damage,
					damage_type = self.ability:GetAbilityDamageType(),
					ability = self.ability,
					}
			ApplyDamage(damageTable)
			if self.caster:HasScepter() then
				enemy:AddNewModifier(
				self.caster, 
				self.ability, 
				"modifier_imba_companion_run_sce_debuff", 
				{
					duration = 0.2,
					pos = self.caster:GetAbsOrigin(),
				})
			end	
		end
	end
end
modifier_imba_companion_run_sce_debuff = class({})
function modifier_imba_companion_run_sce_debuff:IsDebuff()			return true end
function modifier_imba_companion_run_sce_debuff:IsHidden() 			return false end
function modifier_imba_companion_run_sce_debuff:IsPurgable() 		return false end
function modifier_imba_companion_run_sce_debuff:IsPurgeException() 	return false end
function modifier_imba_companion_run_sce_debuff:CheckState() return 
    {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true, 
	[MODIFIER_STATE_STUNNED] = true,
    } 
end
function modifier_imba_companion_run_sce_debuff:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	if not IsServer() then return end
    self.pos = StringToVector(keys.pos)
    self.speed = CalculateDistance(self.pos, self.parent:GetAbsOrigin()) / self:GetDuration()
    self.direction = GetDirection2D(self.pos, self.parent:GetAbsOrigin())
	self:StartIntervalThink(FrameTime())
end
function modifier_imba_companion_run_sce_debuff:OnIntervalThink(keys)
    local speed = self.speed / (1 / FrameTime())
    local next_pos = self.parent:GetAbsOrigin() + self.direction * speed
    self.parent:SetAbsOrigin(next_pos)
end
function modifier_imba_companion_run_sce_debuff:OnRemoved()
	if IsServer() then
	end
end
modifier_imba_companion_run_auto = class({})
function modifier_imba_companion_run_auto:IsDebuff()			return false end
function modifier_imba_companion_run_auto:IsHidden() 			return true end
function modifier_imba_companion_run_auto:IsPurgable() 			return false end
function modifier_imba_companion_run_auto:IsPurgeException() 	return false end
function modifier_imba_companion_run_auto:OnCreated(keys)
	if not self:GetAbility() then
		return
	end
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	if not IsServer() then
		return
	end
end

function modifier_imba_companion_run_auto:DeclareFunctions()
	return {
			MODIFIER_EVENT_ON_ORDER,
			}
end
function modifier_imba_companion_run_auto:OnOrder(keys)
	if not IsServer() or keys.unit ~= self:GetParent() or keys.order_type ~= DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO or keys.ability ~= self:GetAbility() then return end
	if self.ability:GetAutoCastState() then	
		--print("自动施法关闭")
		TG_Remove_Modifier(self.caster,"modifier_imba_companion_run_auto2",0)
		
	else
		--print("自动施法开启")
		self.caster:AddNewModifier(
			self.caster, 
			self.ability, 
			"modifier_imba_companion_run_auto2", 
			{
				duration = -1,
			})
	end
end
function modifier_imba_companion_run_auto:OnRemoved()
    if IsServer() then
		
    end
end
modifier_imba_companion_run_auto2 = class({})
function modifier_imba_companion_run_auto2:IsDebuff()			return false end
function modifier_imba_companion_run_auto2:IsHidden() 			return true end
function modifier_imba_companion_run_auto2:IsPurgable() 			return false end
function modifier_imba_companion_run_auto2:IsPurgeException() 	return false end
modifier_imba_companion_run_pfx = class({})
function modifier_imba_companion_run_pfx:IsDebuff()			return false end
function modifier_imba_companion_run_pfx:IsHidden() 			return false end
function modifier_imba_companion_run_pfx:IsPurgable() 			return false end
function modifier_imba_companion_run_pfx:IsPurgeException() 	return false end
function modifier_imba_companion_run_pfx:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	
	if IsServer() then
		self.target = EntIndexToHScript(keys.target)
		
		if not self.pfx1 then
			self.pfx1 = ParticleManager:CreateParticle("particles/ui_mouseactions/range_finder_cone.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
			ParticleManager:SetParticleControl(self.pfx1, 1, self:GetCaster():GetAbsOrigin())
			ParticleManager:SetParticleControl(self.pfx1, 2, self.target:GetAbsOrigin())
		end
	end
end
function modifier_imba_companion_run_pfx:OnRemoved()
	if IsServer() then
		if self.pfx1 then
			ParticleManager:DestroyParticle(self.pfx1, false)
			ParticleManager:ReleaseParticleIndex(self.pfx1)
		end	
	end
end
modifier_imba_companion_run_buff = class({})
function modifier_imba_companion_run_buff:IsDebuff()			return false end
function modifier_imba_companion_run_buff:IsHidden() 			return false end
function modifier_imba_companion_run_buff:IsPurgable() 			return true end
function modifier_imba_companion_run_buff:IsPurgeException() 	return true end
function modifier_imba_companion_run_buff:DeclareFunctions()
    return
	{
	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_imba_companion_run_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_bonus
end
function modifier_imba_companion_run_buff:GetEffectName()
	return "particles/units/heroes/hero_marci/marci_rebound_allymovespeed.vpcf"
end

function modifier_imba_companion_run_buff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_imba_companion_run_buff:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.ms_bonus = self.ability:GetSpecialValueFor( "ally_movespeed_pct" )
	if not IsServer() then return end
	EmitSoundOn( "Hero_Marci.Rebound.Ally", self.parent )
end
function modifier_imba_companion_run_buff:OnRemoved()
	if IsServer() then
	end
end
modifier_imba_companion_run_debuff = class({})
function modifier_imba_companion_run_debuff:IsDebuff()			return true end
function modifier_imba_companion_run_debuff:IsHidden() 			return false end
function modifier_imba_companion_run_debuff:IsPurgable() 		return true end
function modifier_imba_companion_run_debuff:IsPurgeException() 	return true end
function modifier_imba_companion_run_debuff:DeclareFunctions()
    return
	{
	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_imba_companion_run_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_slow
end
function modifier_imba_companion_run_debuff:GetEffectName()
	return "particles/units/heroes/hero_marci/marci_rebound_bounce_impact_debuff.vpcf"
end

function modifier_imba_companion_run_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_imba_companion_run_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_snapfire_slow.vpcf"
end

function modifier_imba_companion_run_debuff:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end
function modifier_imba_companion_run_debuff:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.ms_slow = -self.ability:GetSpecialValueFor( "movement_slow_pct" )
	if not IsServer() then return end
	EmitSoundOn( "Hero_Marci.Rebound.Ally", self.parent )
end
function modifier_imba_companion_run_debuff:OnRemoved()
	if IsServer() then
	end
end
imba_marci_unleash = class({})
--LinkLuaModifier("modifier_imba_unleash", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_unleash_act_1", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_unleash_act_2", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_unleash_act_3", "linken/hero_marci/hero_marci_encryption", LUA_MODIFIER_MOTION_NONE)
function imba_marci_unleash:GetPlaybackRateOverride()
    return 2.0
end
function imba_marci_unleash:GetCastPoint()
    return 0.30
end
function imba_marci_unleash:GetCastAnimation()
    return ACT_DOTA_ATTACK
end
function imba_marci_unleash:OnAbilityPhaseStart()
    if IsServer() then
        local caster = self:GetCaster()
        caster:AddNewModifier(caster, self, "modifier_imba_unleash_act_1", {duration = 1 })
        caster:AddNewModifier(caster, self, "modifier_imba_unleash_act_2", {duration = 1 })
        caster:AddNewModifier(caster, self, "modifier_imba_unleash_act_3", {duration = 1 })
        self.pfx = ParticleManager:CreateParticle( "particles/heros/marci_5.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	    ParticleManager:SetParticleControl( self.pfx, 1, caster:GetAbsOrigin()+Vector(0,0,100))
    end
    return true
end
function imba_marci_unleash:OnAbilityPhaseInterrupted()
    if IsServer() then
        if self.pfx then
            ParticleManager:DestroyParticle(self.pfx, false)
            ParticleManager:ReleaseParticleIndex(self.pfx)
        end
    end
end
function imba_marci_unleash:OnSpellStart()
	local caster = self:GetCaster()	
    local pos = self:GetCursorPosition()
    if self.pfx then
        ParticleManager:DestroyParticle(self.pfx, false)
        ParticleManager:ReleaseParticleIndex(self.pfx)
	end	

    self.distance	=	self:GetSpecialValueFor("distance") + caster:TG_GetTalentValue("special_bonus_imba_marci_7")
	self.per_distance	=	self:GetSpecialValueFor("per_distance")
	self.st_width	=	self:GetSpecialValueFor("st_width")
	self.en_width	=	self:GetSpecialValueFor("en_width")
	self.speed	=	self:GetSpecialValueFor("speed")
	self.punch_range	=	self:GetSpecialValueFor("punch_range")
	self.restitution_cd	=	self:GetSpecialValueFor("restitution_cd")
	self.popup = (self:GetSpecialValueFor("bj") + caster:TG_GetTalentValue("special_bonus_imba_marci_6")) / 100

	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_marci/marci_attack_normal_punch.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl( pfx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl( pfx, 2, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl( pfx, 5, Vector(1000,0,0))
    ParticleManager:ReleaseParticleIndex(pfx)
    local sound_dummy = CreateModifierThinker(
        caster, 
        self, 
        "modifier_dummy_thinker", 
        {
            duration = 5,
        }, 
        caster:GetAbsOrigin(),
        caster:GetTeamNumber(),
        false
    )
    local distance = self.distance
    local effect = "particles/heros/marci.vpcf"
    EmitSoundOn( "Aegis.Timer", sound_dummy )
    EmitSoundOn( "Hero_Earthshaker.Arcana.GlobalLayer1", sound_dummy )
    
    local info =
        {
            Ability = self,
            EffectName = effect,
            vSpawnOrigin = caster:GetAbsOrigin(),
            fDistance = distance,
            fStartRadius = self.st_width,
            fEndRadius = self.en_width,
            Source = caster,
            iSourceAttachment = "attack1",
            bHasFrontalCone = false,
            bReplaceExisting = false,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            fExpireTime = GameRules:GetGameTime() + 10.0,
            bDeleteOnHit = false,
            vVelocity = caster:GetForwardVector() * self.speed,
            bProvidesVision = false,
            ExtraData = 
            {
                sound_dummy = sound_dummy:entindex(),
            }
        }
    ProjectileManager:CreateLinearProjectile(info)	
    if caster:TG_HasTalent("special_bonus_imba_marci_5") then	
        local ability = caster:FindAbilityByName("imba_marci_guardian")
        local stack = self:GetSpecialValueFor("stack")
        if ability and ability:IsTrained() then
            local modifier = caster:AddNewModifier(
            caster, 
            ability, 
            "modifier_imba_grapple_buff1", 
            {
                duration = -1,
                boll = true
            })
            caster:SetModifierStackCount("modifier_imba_grapple_buff1", caster, stack)
        end
	end
    local ability = caster:FindAbilityByName("imba_marci_swing")
    if ability and ability:IsTrained() then
        caster:AddNewModifier(
            caster, 
            ability, 
            "modifier_imba_swing", 
            {
                duration = 1,
                pos = pos,
                int = true
                --suc = suc
            })
    end
end	
function imba_marci_unleash:PopupNumber_Marci(target, number)
	local pfxPath = "particles/msg_fx/msg_marci_crit.vpcf"
    local pidx    = ParticleManager:CreateParticle(pfxPath, PATTACH_ABSORIGIN_FOLLOW, target)
    local digits  = #tostring(math.floor(number)) + 1
	local lifetime = 3.5
	local presymbol = nil
	local postsymbol = 4
	local color = Vector(255, 0, 0)
	--ParticleManager:SetParticleControl(pidx, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(pidx, 1, Vector(tonumber(presymbol or 9), tonumber(number), tonumber(postsymbol or 9)))
    ParticleManager:SetParticleControl(pidx, 2, Vector(lifetime, digits, 0))
    ParticleManager:SetParticleControl(pidx, 3, color)
    ParticleManager:ReleaseParticleIndex(pidx)
	
end	
function imba_marci_unleash:OnProjectileThink_ExtraData(pos, keys)
	if keys.sound_dummy and not EntIndexToHScript(keys.sound_dummy):IsNull() then
		EntIndexToHScript(keys.sound_dummy):SetAbsOrigin(pos)
	end
	AddFOWViewer(self:GetCaster():GetTeamNumber(), pos, 300, 1, false)
end
function imba_marci_unleash:OnProjectileHit_ExtraData(target, location, keys)
	local caster = self:GetCaster()
	local popup = (self:GetSpecialValueFor("bj") + caster:TG_GetTalentValue("special_bonus_imba_marci_6")) / 100
	if target then
        local damageTable = {
                victim = target,
                attacker = caster,
                damage = caster:GetAverageTrueAttackDamage(caster) * popup,
                damage_type = DAMAGE_TYPE_PHYSICAL,
                ability = self,
                }
        self:PopupNumber_Marci(target, damageTable.damage)
        ApplyDamage(damageTable)
		return false
	end
end
modifier_imba_unleash_act_1 = class({})
function modifier_imba_unleash_act_1:IsDebuff()				return false end
function modifier_imba_unleash_act_1:IsHidden() 			return true end
function modifier_imba_unleash_act_1:IsPurgable() 			return false end
function modifier_imba_unleash_act_1:IsPurgeException() 	return false end
function modifier_imba_unleash_act_1:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
	}
	return funcs
end
function modifier_imba_unleash_act_1:GetActivityTranslationModifiers()
	return "flurry_attack_a"
end
modifier_imba_unleash_act_2 = class({})
function modifier_imba_unleash_act_2:IsDebuff()				return false end
function modifier_imba_unleash_act_2:IsHidden() 			return true end
function modifier_imba_unleash_act_2:IsPurgable() 			return false end
function modifier_imba_unleash_act_2:IsPurgeException() 	return false end
function modifier_imba_unleash_act_2:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
	}
	return funcs
end
function modifier_imba_unleash_act_2:GetActivityTranslationModifiers()
	return "faster"
end
modifier_imba_unleash_act_3 = class({})
function modifier_imba_unleash_act_3:IsDebuff()				return false end
function modifier_imba_unleash_act_3:IsHidden() 			return true end
function modifier_imba_unleash_act_3:IsPurgable() 			return false end
function modifier_imba_unleash_act_3:IsPurgeException() 	return false end
function modifier_imba_unleash_act_3:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
	}
	return funcs
end
function modifier_imba_unleash_act_3:GetActivityTranslationModifiers()
	return "unleash"
end