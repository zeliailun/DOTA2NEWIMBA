--2021.10.30---by你收拾收拾准备出林肯吧
CreateTalents("npc_dota_hero_marci_lin", "linken/hero_marci")
imba_marci_swing = class({})

--俯冲到目标地点
LinkLuaModifier("modifier_imba_swing", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
function imba_marci_swing:Set_InitialUpgrade(tg)
    return {LV=1}
end
--[[function imba_marci_swing:GetBehavior() 
	return 	
			DOTA_ABILITY_BEHAVIOR_POINT + 
			DOTA_ABILITY_BEHAVIOR_IGNORE_SILENCE + 
			DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE + 
			DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_CHANNEL + 
			DOTA_ABILITY_BEHAVIOR_DONT_RESUME_MOVEMENT
end]]
function imba_marci_swing:OnSpellStart()
	local caster = self:GetCaster()		
	local pos = self:GetCursorPosition()
	--local st_direction 	= VectorToAngles(caster:GetForwardVector()).y
	--local end_direction = VectorToAngles(pos-caster:GetAbsOrigin()).y
	--local suc 			= math.abs( AngleDiff(st_direction,end_direction)) < 90
	local distance = self:GetSpecialValueFor("distance")
	if caster:IsSilenced() then
		distance = self:GetSpecialValueFor("silence_distance")
	end
	if CalculateDistance(pos, caster:GetAbsOrigin()) < 30 then
		pos = caster:GetAbsOrigin() + caster:GetForwardVector() * distance
	end
	local next_pos = pos
	if CalculateDistance(pos, caster:GetAbsOrigin()) > distance then
		next_pos = caster:GetAbsOrigin() + GetDirection2D(pos, caster:GetAbsOrigin()) * distance
	end
	caster:AddNewModifier(
		caster, 
		self, 
		"modifier_imba_swing", 
		{
			duration = 1,
			pos = next_pos,
			--suc = suc
		})	
end	
modifier_imba_swing = class({})
function modifier_imba_swing:IsDebuff()				return false end
function modifier_imba_swing:IsHidden() 			return true end
function modifier_imba_swing:IsPurgable() 			return false end
function modifier_imba_swing:IsPurgeException() 	return false end
function modifier_imba_swing:GetEffectName() return "particles/econ/events/fall_major_2016/force_staff_fm06.vpcf" end
function modifier_imba_swing:GetActivityTranslationModifiers() return "forcestaff_friendly" end
function modifier_imba_swing:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_imba_swing:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end	

function modifier_imba_swing:GetOverrideAnimationWeight()
    return 10
end

function modifier_imba_swing:GetModifierMoveSpeed_Absolute() 
    if IsServer()  then 
        return 1 
    end 
end
function modifier_imba_swing:GetModifierMoveSpeed_Limit() 
    if IsServer()  then 
        return 1 
    end 
end
function modifier_imba_swing:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end
function modifier_imba_swing:CheckState() return 
    {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true, 
	[MODIFIER_STATE_INVULNERABLE] = true,
	[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	[MODIFIER_STATE_DISARMED] = true,
    } 
end
function modifier_imba_swing:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION_WEIGHT,
        
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, 
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
    }
end
function modifier_imba_swing:OnCreated(keys)
	if not self:GetAbility() then
		return
	end
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	if not IsServer() then
		return
	end
	self.int = false
	self.unleash = 0
	self.hitted = {}
	self.pos = StringToVector(keys.pos)
	self.parent:MoveToPositionAggressive(self.pos)
	self.speed = 1500
	self.parent:SetForwardVector(GetDirection2D(self.pos, self.parent:GetAbsOrigin()))
	self.fv = self.parent:GetForwardVector()
	self.rv = self.parent:GetRightVector()
	self.uv = self.parent:GetUpVector()
	local swap_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_vengeful/vengeful_nether_swap.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlEnt(swap_pfx, 0, self.parent, PATTACH_POINT, "attach_hitloc", self.parent:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(swap_pfx, 1, nil, PATTACH_POINT, "attach_hitloc", self.pos, true)	
	--self.parent:EmitSound("Hero_FacelessVoid.TimeDilation.Cast.ti7_layer")
	--self.parent:EmitSound("Item.ForceField.Cast")
	--self.parent:EmitSound("soundboard.ti9.crowd_groan")
	self.parent:EmitSound("marci_marci_move_2")
	
	

	--[[local particle_cast = "particles/units/heroes/hero_faceless_void/faceless_void_time_walk_preimage.vpcf"
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT, self.parent )
	ParticleManager:SetParticleControl(effect_cast, 0, self.parent:GetAbsOrigin())
	ParticleManager:SetParticleControl(effect_cast, 1, self.pos)
	ParticleManager:SetParticleControlEnt(effect_cast, 2, self.parent, PATTACH_POINT, "attach_hitloc", self.parent:GetForwardVector(), true)
	self:AddParticle(effect_cast,false, false, -1, false, false )]]
	self:StartIntervalThink(FrameTime())
end
function modifier_imba_swing:OnIntervalThink()
	GridNav:DestroyTreesAroundPoint( self.parent:GetOrigin(), 80, true )
	--self.parent:SetForwardVector(GetDirection2D(self.pos, self.parent:GetAbsOrigin()))
	self.parent:FaceTowards( self.pos )
	local speed = self.speed / (1 / FrameTime())
	local next_pos = self.parent:GetAbsOrigin() + GetDirection2D(self.pos, self.parent:GetAbsOrigin()) * speed
	self.parent:SetAbsOrigin(next_pos)
	if CalculateDistance(self.pos, self.parent:GetAbsOrigin()) < 30 then
		self:Destroy()
	end
	if self.int then
		local ability = self.caster:FindAbilityByName("imba_marci_unleash")
		local enemies = FindUnitsInRadius(
			self.parent:GetTeamNumber(),	
			self.parent:GetAbsOrigin()+self.parent:GetForwardVector()*150,
			nil,	
			self.unleash,	
			DOTA_UNIT_TARGET_TEAM_ENEMY,	
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	
			DOTA_UNIT_TARGET_FLAG_NONE,	
			0,	
			false	
		)
		if not self.popup then
			self.popup = (ability:GetSpecialValueFor("bj") + self.caster:TG_GetTalentValue("special_bonus_imba_marci_6")) / 100
		end	
		for _, enemy in pairs(enemies) do
			if not IsInTable(enemy, self.hitted) then
				local damageTable = {
					victim = enemy,
					attacker = self.caster,
					damage = self.caster:GetAverageTrueAttackDamage(self.caster)*self.popup,
					damage_type = DAMAGE_TYPE_PHYSICAL,
					ability = self.ability,
					}
				ability:PopupNumber_Marci(enemy, damageTable.damage)
				ApplyDamage(damageTable)
				self.hitted[#self.hitted+1] = enemy	
			end
		end	
	end
end
function modifier_imba_swing:OnRemoved()
    if IsServer() then
		self.popup = nil
		local pfx = ParticleManager:CreateParticle("particles/econ/items/windrunner/windranger_arcana/windranger_arcana_powershot_channel_v2_endcap_model.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(pfx, 0, GetGroundPosition(self.parent:GetAbsOrigin(), self.parent)) 
		ParticleManager:SetParticleControl(pfx, 1, GetGroundPosition(self.pos, self.parent))
		ParticleManager:SetParticleControlOrientation(pfx, 1, self.fv, self.rv, self.uv)
		ParticleManager:ReleaseParticleIndex(pfx)
    end
end

imba_marci_grapple = class({})

--抓取一圈敌人 背摔

LinkLuaModifier("modifier_imba_grapple_move", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_grapple_damage", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_grapple_self", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_knockback_lua", "linken/modifier_generic_knockback_lua.lua", LUA_MODIFIER_MOTION_BOTH)
function imba_marci_grapple:Precache( context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_marci.vsndevts", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_marci/marci_dispose_aoe_damage.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_marci/marci_dispose_debuff.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_marci/marci_dispose_land_aoe.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_marci/marci_grapple.vpcf", context )
end
function imba_marci_grapple:GetCastPoint() 
	if self:GetCaster():HasModifier("modifier_imba_swing") then  
		return 0	
	end
	return 0.2     
end
function imba_marci_grapple:OnSpellStart()
	local caster = self:GetCaster()	
	caster:EmitSound("Hero_Marci.Grapple.Cast")	
	local air_duration = self:GetSpecialValueFor("air_duration")
	caster:AddNewModifier(
		caster, 
		self, 
		"modifier_imba_grapple_move", 
		{
			duration = air_duration+0.2,
		})
	local pfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_marci/marci_grapple.vpcf", PATTACH_POINT_FOLLOW, caster )
	ParticleManager:SetParticleControlEnt(pfx,1,caster,PATTACH_POINT_FOLLOW,"attach_attack1",Vector(0,0,0),true)
	ParticleManager:SetParticleControlEnt(pfx,2,caster,PATTACH_POINT_FOLLOW,"attach_attack2",Vector(0,0,0),true)
	ParticleManager:ReleaseParticleIndex( pfx )
end	
modifier_imba_grapple_move = class({})
function modifier_imba_grapple_move:IsDebuff()			return false end
function modifier_imba_grapple_move:IsHidden() 			return true end
function modifier_imba_grapple_move:IsPurgable() 		return false end
function modifier_imba_grapple_move:IsPurgeException() 	return false end
function modifier_imba_grapple_move:GetEffectName() return "particles/econ/events/fall_major_2016/force_staff_fm06.vpcf" end
function modifier_imba_grapple_move:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_imba_grapple_move:GetOverrideAnimation()
    return ACT_DOTA_GENERIC_CHANNEL_1
end

function modifier_imba_grapple_move:GetOverrideAnimationWeight()
    return 10
end

function modifier_imba_grapple_move:GetModifierMoveSpeed_Absolute() 
    if IsServer()  then 
        return 1 
    end 
end
function modifier_imba_grapple_move:GetModifierMoveSpeed_Limit() 
    if IsServer()  then 
        return 1 
    end 
end
function modifier_imba_grapple_move:CheckState() return 
    {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true, 
	[MODIFIER_STATE_STUNNED] = self:GetStackCount() ~= -1 ,
	[MODIFIER_STATE_DISARMED] = true,
    } 
end
function modifier_imba_grapple_move:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION_WEIGHT,
        
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, 
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
    }
end
function modifier_imba_grapple_move:OnCreated(keys)
	if not self:GetAbility() then
		return
	end
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.cap_radius = self.ability:GetSpecialValueFor("cap_radius")
	self.move_distance = self.ability:GetSpecialValueFor("move_distance") + self.caster:TG_GetTalentValue("special_bonus_imba_marci_1")
	if not IsServer() then
		return
	end
	self.pos = self.caster:GetAbsOrigin() - self.caster:GetForwardVector() * self.move_distance
	self.hitted = {}
	self.time = 0
	self.modif = true
	self:SetStackCount(1)
	self:StartIntervalThink(FrameTime())
end
function modifier_imba_grapple_move:OnIntervalThink()
	self.time = self.time + 1
	if self.time <= 5 then
		local pos = self.parent:GetAbsOrigin() + self.parent:GetForwardVector() * 100
		local next_pos = RotatePosition(self.parent:GetAbsOrigin(), QAngle(0,72,0), pos)
		--DebugDrawCircle(next_pos, Vector(255,0,0), 100, 50, true, 1.3)
		self.parent:SetForwardVector(GetDirection2D(next_pos, self.parent:GetAbsOrigin()))
		--self.parent:FaceTowards( next_pos )
		local hand = self.caster:ScriptLookupAttachment( "attach_attack2" )
		local hand_pos = self.caster:GetAttachmentOrigin( hand )
		local enemies = FindUnitsInRadius(
					self.parent:GetTeamNumber(),	
					next_pos,
					nil,	
					self.cap_radius,	
					DOTA_UNIT_TARGET_TEAM_ENEMY,	
					DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	
					DOTA_UNIT_TARGET_FLAG_NONE,	
					0,	
					false	
				)	
				for _, enemy in pairs(enemies) do
					if not IsInTable(enemy, self.hitted) then
						enemy:AddNewModifier(
							self.caster, 
							self.ability, 
							"modifier_imba_grapple_damage", 
							{
								duration = self:GetRemainingTime(),
							})
						self.hitted[#self.hitted+1] = enemy	
					end
				end			
				for i, enemy in pairs(self.hitted) do
					if enemy and enemy:IsAlive() then
						enemy:SetOrigin(GetGroundPosition(next_pos, nil))
					else
						self.hitted[i] = nil
					end
				end
	else
		self:SetStackCount(-1)
		if self.modif and #self.hitted > 0 then
			self.caster:AddNewModifier(
				self.caster, 
				self.ability, 
				"modifier_imba_grapple_self", 
				{
					duration = self:GetRemainingTime(),
				})
			self.parent:MoveToPositionAggressive(self.pos)
			self.modif = false
			self.caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_5,1.5)
			self.caster:AddNewModifier(
				self.caster, 
				self.ability, 
				"modifier_generic_knockback_lua",
				{
					distance = self.move_distance,
					height = 150,
					duration = self:GetRemainingTime(),
					direction_x = GetDirection2D(self.pos, self.caster:GetAbsOrigin()).x,
					direction_y = GetDirection2D(self.pos, self.caster:GetAbsOrigin()).y,
					IsStun = false,
					IsFreeControll = true,
				} -- kv
				)
		elseif #self.hitted <= 0 then
			if self.caster:TG_HasTalent("special_bonus_imba_marci_8") then
				self.ability:EndCooldown()
				self.ability:StartCooldown((self.ability:GetCooldown(self.ability:GetLevel() -1 ) * self.caster:GetCooldownReduction()) - self.caster:TG_GetTalentValue("special_bonus_imba_marci_8"))
			end
				self:Destroy()
			return
		end
		for i, enemy in pairs(self.hitted) do
			if enemy and enemy:IsAlive() then
				enemy:SetOrigin(self.caster:GetAbsOrigin())
			else
				self.hitted[i] = nil
			end
		end
	end
end
function modifier_imba_grapple_move:OnRemoved()
    if IsServer() then
		self.parent:MoveToPositionAggressive(self.parent:GetAbsOrigin())
	end
end

modifier_imba_grapple_damage = class({})
function modifier_imba_grapple_damage:IsDebuff()			return false end
function modifier_imba_grapple_damage:IsHidden() 			return true end
function modifier_imba_grapple_damage:IsPurgable() 		return false end
function modifier_imba_grapple_damage:IsPurgeException() 	return false end
function modifier_imba_grapple_damage:CheckState() return 
    {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true, 
	[MODIFIER_STATE_STUNNED] = true, 
    } 
end
function modifier_imba_grapple_damage:OnCreated(keys)
	if not self:GetAbility() then
		return
	end
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	if not IsServer() then
		return
	end
	local pfx_name = "particles/units/heroes/hero_marci/marci_dispose_debuff.vpcf"
	local pfx = ParticleManager:CreateParticle( pfx_name, PATTACH_POINT_FOLLOW, self.caster )
	ParticleManager:SetParticleControlEnt(pfx,0,self.parent,PATTACH_POINT_FOLLOW,"attach_hitloc",Vector(0,0,0),true )
	ParticleManager:SetParticleControlEnt(pfx,1,self.parent,PATTACH_POINT_FOLLOW,"attach_hitloc",Vector(0,0,0),true )
	ParticleManager:SetParticleControl(pfx, 5, Vector( self:GetDuration(), 0, 0 ) )
	ParticleManager:ReleaseParticleIndex(pfx)
	EmitSoundOn("Hero_Marci.Grapple.Target",self.parent)
end
function modifier_imba_grapple_damage:OnRemoved()
    if IsServer() then
	end
end
modifier_imba_grapple_self = class({})
function modifier_imba_grapple_self:IsDebuff()			return false end
function modifier_imba_grapple_self:IsHidden() 			return true end
function modifier_imba_grapple_self:IsPurgable() 		return false end
function modifier_imba_grapple_self:IsPurgeException() 	return false end
function modifier_imba_grapple_self:CheckState() return 
    {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true, 
    } 
end
function modifier_imba_grapple_self:OnCreated(keys)
	if not self:GetAbility() then
		return
	end
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.impact_damage = self.ability:GetSpecialValueFor("impact_damage")
	self.stun_duration = self.ability:GetSpecialValueFor("stun_duration")
	self.impact_radius = self.ability:GetSpecialValueFor("impact_radius")
	if not IsServer() then
		return
	end
end
function modifier_imba_grapple_self:OnRemoved()
    if IsServer() then
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_marci/marci_dispose_land_aoe.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(pfx, 0, GetGroundPosition(self.parent:GetAbsOrigin(), self.parent)) 
		ParticleManager:SetParticleControl(pfx, 1, Vector(500,0,0))
		ParticleManager:ReleaseParticleIndex(pfx)
		local enemies = FindUnitsInRadius(
			self.parent:GetTeamNumber(),	
			self.parent:GetAbsOrigin(),
			nil,	
			self.impact_radius,	
			DOTA_UNIT_TARGET_TEAM_BOTH,	
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	
			DOTA_UNIT_TARGET_FLAG_NONE,	
			0,	
			false	
		)	
		for _, enemy in pairs(enemies) do
			enemy:AddNewModifier(self.parent, self.ability, "modifier_phased", {duration = 0.2})
			if IsEnemy(self.caster,enemy) then
				enemy:AddNewModifier(self.parent, self.ability, "modifier_stunned", {duration = self.stun_duration})
				local damageTable = {
						victim = enemy,
						attacker = self.caster,
						damage = self.impact_damage,
						damage_type = self:GetAbility():GetAbilityDamageType(),
						ability = self.ability,
						}
				ApplyDamage(damageTable)
			end
		end
		GridNav:DestroyTreesAroundPoint( self.parent:GetOrigin(), 300, true )
		EmitSoundOnLocationWithCaster( self.parent:GetOrigin(), "Hero_Marci.Grapple.Stun", self.caster)
		EmitSoundOnLocationWithCaster( self.parent:GetOrigin(), "Hero_Marci.Grapple.Impact.Ally", self.caster)
		local pfx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_marci/marci_dispose_aoe_damage.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(pfx2, 0, GetGroundPosition(self.parent:GetAbsOrigin(), self.parent)) 
		ParticleManager:ReleaseParticleIndex(pfx2)
    end
end
imba_marci_companion_run = class({})
LinkLuaModifier("modifier_imba_companion_run_move", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_jump", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_adhere", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_auto", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_auto2", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_pfx", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_buff", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_debuff", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_companion_run_sce_debuff", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
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
	local nResult = UnitFilter(
		hTarget,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_TREE,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		self:GetCaster():GetTeamNumber()
	)
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
	if self.targetcast == nil then
		self.targetcast = self:GetCursorTarget()
		if self.targetcast:GetMaxHealth() ~= 0 then
			self.agh = false
		elseif self.targetcast:GetMaxHealth() == 0  then
			self.agh = true
		end
	end
	if caster:Has_Aghanims_Shard() then
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
		local cast_range = self:GetSpecialValueFor("cast_range") + caster:GetCastRangeBonus() + caster:TG_GetTalentValue("special_bonus_imba_marci_2")
		if CalculateDistance(target:GetAbsOrigin(), point)  > cast_range then
			point = target:GetAbsOrigin() + GetDirection2D(point, target:GetAbsOrigin()) * (cast_range)
		elseif CalculateDistance(target:GetAbsOrigin(), point)  < min_range then
			point = target:GetAbsOrigin() + GetDirection2D(point, target:GetAbsOrigin()) * min_range
		end
		if self.agh then
			--print("目标是树")
			point = target:GetAbsOrigin() + GetDirection2D(point, target:GetAbsOrigin()) * min_range
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
imba_marci_guardian = class({})
LinkLuaModifier("modifier_imba_grapple_passive", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_grapple_buff1", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_grapple_buff2", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_imba_grapple_buff3", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_grapple_cd", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_grapple_debuff", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
function imba_marci_guardian:GetIntrinsicModifierName() return "modifier_imba_grapple_passive" end
function imba_marci_guardian:OnSpellStart()
	local caster = self:GetCaster()		
	if caster:HasModifier("modifier_imba_unleash") then
		local modifier = caster:FindModifierByName("modifier_imba_unleash")
		modifier.punch = true
	end
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("buff_duration")
	local range = self:GetSpecialValueFor("nearest_ally_search_range")
	caster:RemoveModifierByName("modifier_imba_grapple_passive")
	caster:AddNewModifier(
		caster, 
		self, 
		"modifier_imba_grapple_passive",
		{
			duration = -1 ,
		}
		)
	if target == caster then
		caster:AddNewModifier(
			caster, 
			self, 
			"modifier_marci_guardian_buff", 
			{
				duration = duration,
			})
		local enemies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),
			self:GetCaster():GetAbsOrigin(),
			nil,
			range ,
			DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_CLOSEST,
			false)
		for _,enemy in pairs(enemies) do
			if enemy ~= caster then
				enemy:AddNewModifier(
				caster, 
				self, 
				"modifier_marci_guardian_buff", 
				{
					duration = duration,
				})
				break
			end
		end
	elseif target ~= caster then
		caster:AddNewModifier(
			caster, 
			self, 
			"modifier_marci_guardian_buff", 
			{
				duration = duration,
			})
		target:AddNewModifier(
			caster, 
			self, 
			"modifier_marci_guardian_buff", 
			{
				duration = duration,
			})
	end
	caster:MoveToPositionAggressive(caster:GetAbsOrigin())
	--[[local allmodif = caster:FindAllModifiers()
	for i =1 , #allmodif do 
		print(allmodif[i]:GetName())
	end]]
end	
modifier_imba_grapple_passive = class({})
function modifier_imba_grapple_passive:IsDebuff()			return false end
function modifier_imba_grapple_passive:IsHidden() 			return false end
function modifier_imba_grapple_passive:IsPurgable() 			return false end
function modifier_imba_grapple_passive:IsPurgeException() 	return false end
function modifier_imba_grapple_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
	return funcs
end
--[[function modifier_imba_grapple_passive:CheckState() 
	return 
		{
			[MODIFIER_STATE_SILENCED] = false 
		}
end
function modifier_imba_grapple_passive:GetPriority()
	return 10 
end]]
function modifier_imba_grapple_passive:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.duration	= 	-1
	self.cd_duration=	self.ability:GetSpecialValueFor("cd") - self.caster:TG_GetTalentValue("special_bonus_imba_marci_3")
	self.chance_pct = 	self.ability:GetSpecialValueFor("chance_pct")
	if not IsServer() then return end
	self.parent:AddNewModifier(self.parent, self.ability, "modifier_imba_grapple_buff2", {duration = -1})
end
function modifier_imba_grapple_passive:OnAttackLanded(keys)
	if not IsServer() then
		return
	end
	if keys.attacker ~= self.parent or self.parent:PassivesDisabled() or self.parent:IsIllusion() or not keys.target:IsAlive() or not keys.target:IsUnit() then
		return
	end
	if self.parent:HasModifier("modifier_imba_grapple_cd") then
		return
	end 
	if PseudoRandom:RollPseudoRandom(self.ability, self.chance_pct) then
		self.parent:AddNewModifier(self.parent, self.ability, "modifier_imba_grapple_buff1", {duration = self.duration})
		self.parent:AddNewModifier(self.parent, self.ability, "modifier_imba_grapple_cd", {duration = self.cd_duration})
		EmitSoundOn( "Hero_Marci.Unleash.Charged", self.parent )
		EmitSoundOn( "Hero_Marci.Unleash.Charged.2D", self.parent )	
	end
end
function modifier_imba_grapple_passive:OnAbilityFullyCast(keys)
	if IsServer() and not self.parent:PassivesDisabled() then
		if self.ability:GetLevel() == 0 then return end
		if keys.unit ~= self.parent or keys.ability:IsItem() then 
			return 
		end
		if self.parent:HasModifier("modifier_imba_grapple_cd") then
			return
		end 
		self.parent:AddNewModifier(self.parent, self.ability, "modifier_imba_grapple_buff1", {duration = self.duration})
		self.parent:AddNewModifier(self.parent, self.ability, "modifier_imba_grapple_cd", {duration = self.cd_duration})
		local pfx_name = "particles/units/heroes/hero_marci/marci_unleash_cast.vpcf"
		local pfx = ParticleManager:CreateParticle( pfx_name, PATTACH_ABSORIGIN_FOLLOW, self.parent )
		ParticleManager:ReleaseParticleIndex( pfx )
		EmitSoundOn( "Hero_Marci.Unleash.Charged.2D", self.parent )
	end		
end
function modifier_imba_grapple_passive:OnRemoved()
	if IsServer() then
	end
end
modifier_imba_grapple_buff1 = class({})
function modifier_imba_grapple_buff1:IsDebuff()			return false end
function modifier_imba_grapple_buff1:IsHidden() 			return false end
function modifier_imba_grapple_buff1:IsPurgable() 			return false end
function modifier_imba_grapple_buff1:IsPurgeException() 	return false end
function modifier_imba_grapple_buff1:DeclareFunctions()
	local funcs = {
		--MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,

		MODIFIER_PROPERTY_IGNORE_ATTACKSPEED_LIMIT,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,

	}
	return funcs
end
function modifier_imba_grapple_buff1:GetModifierAttackSpeed_Limit()
	return 1
end
function modifier_imba_grapple_buff1:ShouldUseOverheadOffset() return true end
function modifier_imba_grapple_buff1:GetModifierAttackSpeedBonus_Constant()
	return 1000
end
function modifier_imba_grapple_buff1:GetActivityTranslationModifiers()
	if self:GetStackCount()==1 then
		return "flurry_pulse_attack"
	end

	if self:GetStackCount()%2==0 then
		return "flurry_attack_b"
	end

	return "flurry_attack_a"
end
function modifier_imba_grapple_buff1:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.radius		=	self.ability:GetSpecialValueFor("aoe_range") + self.caster:TG_GetTalentValue("special_bonus_imba_marci_4")
	self.stack 		= 	self.ability:GetSpecialValueFor("max_stack")
	self.int		=	self.ability:GetSpecialValueFor("disap_time")
	self.debuff_duration = self.ability:GetSpecialValueFor("debuff_duration")
	self.aoe_damage = self.ability:GetSpecialValueFor("aoe_damage")
	if not IsServer() then return end
	local particle_cast = "particles/units/heroes/hero_marci/marci_unleash_buff.vpcf"
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, self.parent )
	ParticleManager:SetParticleControlEnt(effect_cast,1,self.parent,PATTACH_POINT_FOLLOW,"eye_l",Vector(0,0,0), true )
	ParticleManager:SetParticleControlEnt(effect_cast,2,self.parent,PATTACH_POINT_FOLLOW,"eye_r",Vector(0,0,0), true )
	ParticleManager:SetParticleControlEnt(effect_cast,3,self.parent,PATTACH_POINT_FOLLOW,"attach_attack1",Vector(0,0,0),true )
	ParticleManager:SetParticleControlEnt(effect_cast,4,self.parent,PATTACH_POINT_FOLLOW,"attach_attack2",Vector(0,0,0), true )
	ParticleManager:SetParticleControlEnt(effect_cast,5,self.parent,PATTACH_POINT_FOLLOW,"attach_attack1",Vector(0,0,0), true )
	ParticleManager:SetParticleControlEnt(effect_cast,6,self.parent,PATTACH_POINT_FOLLOW,"attach_attack2",Vector(0,0,0), true )
	self:AddParticle(effect_cast,false, false, -1, false, false )

	self:SetStackCount(self.stack)
	local pfx_name = "particles/units/heroes/hero_marci/marci_unleash_stack.vpcf"
	local pfx = ParticleManager:CreateParticle( pfx_name, PATTACH_OVERHEAD_FOLLOW, self.parent )
	ParticleManager:SetParticleControl( pfx, 1, Vector( 0, self:GetStackCount(), 0 ) )
	self:AddParticle(pfx,false, false, -1, false, false )
	self.effect_cast = pfx
end
function modifier_imba_grapple_buff1:GetModifierProcAttack_Feedback( keys )
	if self.caster:HasModifier("modifier_imba_unleash_bj") then return end
	--print(keys.target:IsBuilding())
	if self:GetStackCount() > self.stack and keys.target:IsBuilding() then
		self:SetStackCount(self.stack)
	end
	self:StartIntervalThink(self.int)
	self:DecrementStackCount()
	local pfx_name = "particles/units/heroes/hero_marci/marci_unleash_attack.vpcf"
	local pfx = ParticleManager:CreateParticle( pfx_name, PATTACH_ABSORIGIN_FOLLOW, self.parent )
	ParticleManager:SetParticleControlEnt(pfx,1,keys.target,PATTACH_POINT_FOLLOW,"attach_hitloc",Vector(0,0,0), true )
	ParticleManager:ReleaseParticleIndex( pfx )	
	if self:GetStackCount() <= 0 then
		local pfx_name = "particles/units/heroes/hero_marci/marci_unleash_pulse.vpcf"
		local pfx = ParticleManager:CreateParticle( pfx_name, PATTACH_WORLDORIGIN, nil )
		ParticleManager:SetParticleControl( pfx, 0, keys.target:GetAbsOrigin() )
		ParticleManager:SetParticleControl( pfx, 1, Vector(self.radius,self.radius,self.radius) )
		ParticleManager:ReleaseParticleIndex( pfx )
		EmitSoundOnLocationWithCaster( keys.target:GetAbsOrigin(), "Hero_Marci.Unleash.Pulse", self.parent )
		self:Destroy()
    end
	if self.effect_cast then
		ParticleManager:SetParticleControl(self.effect_cast, 1, Vector(0, self:GetStackCount(), 0))
	end
end
function modifier_imba_grapple_buff1:OnIntervalThink(keys)
	self:Destroy()
end

function modifier_imba_grapple_buff1:OnRemoved()
	if IsServer() then
		if self.caster:IsNull() or self:GetStackCount() > 0 then return end
		local enemies = FindUnitsInRadius(
			self.caster:GetTeamNumber(),
			self.caster:GetAbsOrigin(),
			nil,
			self.radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_CLOSEST,
			false)
		for _,enemy in pairs(enemies) do
			enemy:AddNewModifier(
			self.caster, 
			self.ability, 
			"modifier_imba_grapple_debuff", 
			{
				duration = self.debuff_duration,
			})	
			local damageTable = {
					victim = enemy,
					attacker = self.caster,
					damage = self.aoe_damage,
					damage_type = self.ability:GetAbilityDamageType(),
					ability = self.ability,
					}
			ApplyDamage(damageTable)
		end
	end
end
modifier_imba_grapple_buff2 = class({})
function modifier_imba_grapple_buff2:IsDebuff()				return false end
function modifier_imba_grapple_buff2:IsHidden() 			return true end
function modifier_imba_grapple_buff2:IsPurgable() 			return false end
function modifier_imba_grapple_buff2:IsPurgeException() 	return false end
function modifier_imba_grapple_buff2:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
	}
	return funcs
end
function modifier_imba_grapple_buff2:GetActivityTranslationModifiers()
	if self:GetParent():HasModifier("modifier_imba_grapple_buff1") then
		return "unleash"
	end
	return ""
end
--[[modifier_imba_grapple_buff3 = class({})
function modifier_imba_grapple_buff3:IsDebuff()			return false end
function modifier_imba_grapple_buff3:IsHidden() 			return false end
function modifier_imba_grapple_buff3:IsPurgable() 			return false end
function modifier_imba_grapple_buff3:IsPurgeException() 	return false end
function modifier_imba_grapple_buff3:ShouldUseOverheadOffset() return true end
function modifier_imba_grapple_buff3:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		
	}
	return funcs
end
function modifier_imba_grapple_buff3:GetStatusEffectName()
	return "particles/status_fx/status_effect_marci_sidekick.vpcf"
end

function modifier_imba_grapple_buff3:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end
function modifier_imba_grapple_buff3:GetModifierPreAttack_BonusDamage()
    return self.attack_bonus
end
function modifier_imba_grapple_buff3:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.radius		=	500
	self.stack 		= 	3
	self.int		=	1
	self.attack_bonus = 60
	self.hero_lifesteal = 20
	if not IsServer() then return end
	local pfx_name = "particles/units/heroes/hero_marci/marci_sidekick_self_buff.vpcf"
	local pfx = ParticleManager:CreateParticle( pfx_name, PATTACH_OVERHEAD_FOLLOW, self.parent )
	ParticleManager:SetParticleControl( pfx, 0, self.parent:GetAbsOrigin())
	ParticleManager:SetParticleControl( pfx, 1, self.parent:GetAbsOrigin())
	self:AddParticle(pfx,false, false, -1, false, false )
end
function modifier_imba_grapple_buff3:OnTakeDamage(keys)
	if not IsServer() then
		return
	end
	if keys.attacker == self.parent and not keys.inflictor and (keys.unit:IsHero() or keys.unit:IsCreep() or keys.unit:IsBoss()) and not Is_Chinese_TG(keys.attacker, keys.unit) and bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION and bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) ~= DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL then
		local lifesteal = keys.damage * (self.hero_lifesteal / 100)
		if keys.unit:IsCreep() or keys.unit:IsBoss() then
			lifesteal = lifesteal / 5
		end
		self:GetParent():Heal(lifesteal, self.ability)
		local pfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal_lanecreeps.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl( pfx, 0, self.parent:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(pfx)
	end
end
function modifier_imba_grapple_buff3:OnRemoved()
	if IsServer() then
	end
end]]
modifier_imba_grapple_cd = class({})
function modifier_imba_grapple_cd:IsDebuff()			return true end
function modifier_imba_grapple_cd:IsHidden() 			return false end
function modifier_imba_grapple_cd:IsPurgable() 			return false end
function modifier_imba_grapple_cd:IsPurgeException() 	return false end
modifier_imba_grapple_debuff = class({})
function modifier_imba_grapple_debuff:IsHidden()		return false end
function modifier_imba_grapple_debuff:IsDebuff()		return true end
function modifier_imba_grapple_debuff:IsPurgable()		return false end
function modifier_imba_grapple_debuff:IsPurgeException()return false end
function modifier_imba_grapple_debuff:OnCreated( keys )
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.as_slow = -self:GetAbility():GetSpecialValueFor( "atsp_slow" )
	self.ms_slow = -self:GetAbility():GetSpecialValueFor( "move_slow" )
	if not IsServer() then return end
end
function modifier_imba_grapple_debuff:OnRefresh( keys )
	self:OnCreated( keys )
end
function modifier_imba_grapple_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
	return funcs
end
function modifier_imba_grapple_debuff:GetModifierAttackSpeedBonus_Constant()
	return self.as_slow
end
function modifier_imba_grapple_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_slow
end
function modifier_imba_grapple_debuff:GetEffectName()
	return "particles/units/heroes/hero_marci/marci_unleash_pulse_debuff.vpcf"
end

function modifier_imba_grapple_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_imba_grapple_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_snapfire_slow.vpcf"
end

function modifier_imba_grapple_debuff:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end
imba_marci_unleash = class({})
LinkLuaModifier("modifier_imba_unleash", "linken/hero_marci", LUA_MODIFIER_MOTION_NONE)
function imba_marci_unleash:GetPlaybackRateOverride()
    return 0.8
end
function imba_marci_unleash:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_4
end
function imba_marci_unleash:OnSpellStart()
	local caster = self:GetCaster()		
	caster:AddNewModifier(
		caster, 
		self, 
		"modifier_imba_unleash", 
		{
			duration = 2.5,
		})
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
	AddFOWViewer(self:GetCaster():GetTeamNumber(), pos, 300, FrameTime(), false)
end
function imba_marci_unleash:OnProjectileHit_ExtraData(target, location, keys)
	local caster = self:GetCaster()
	local popup = (self:GetSpecialValueFor("bj") + caster:TG_GetTalentValue("special_bonus_imba_marci_6")) / 100
	local damage = self:GetSpecialValueFor("damage")
	--print(keys.int)	
	if target then
		--[[target:AddNewModifier(
		caster, 
		self, 
		"modifier_imba_grapple_debuff", 
		{
			duration = self.debuff_duration,
		})	]]
		if keys.int == 3 then
			local damageTable = {
					victim = target,
					attacker = caster,
					damage = caster:GetAverageTrueAttackDamage(caster) * popup,
					damage_type = DAMAGE_TYPE_PHYSICAL,
					ability = self,
					}
			self:PopupNumber_Marci(target, damageTable.damage)
			ApplyDamage(damageTable)
		end
		local damageTable = {
				victim = target,
				attacker = caster,
				damage = damage,
				damage_type = self:GetAbilityDamageType(),
				ability = self.ability,
				}
		ApplyDamage(damageTable)
		return false
	end
end
modifier_imba_unleash = class({})
function modifier_imba_unleash:IsDebuff()			return false end
function modifier_imba_unleash:IsHidden() 			return false end
function modifier_imba_unleash:IsPurgable() 			return false end
function modifier_imba_unleash:IsPurgeException() 	return false end
function modifier_imba_unleash:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
		MODIFIER_PROPERTY_DISABLE_TURNING
	}
	return funcs
end
function modifier_imba_unleash:GetModifierTurnRate_Percentage() 
	return -1000
end
function modifier_imba_unleash:GetModifierDisableTurning() 
    return self.dis_turn
end
function modifier_imba_unleash:GetStatusEffectName()
	if self.caster:TG_HasTalent("special_bonus_imba_marci_7") then
  		return "particles/status_fx/status_effect_dawnbreaker_fire_wreath_magic_immunity.vpcf"
	end
	return ""
end
function modifier_imba_unleash:StatusEffectPriority() 
	if self.caster:TG_HasTalent("special_bonus_imba_marci_7") then
		return 10001 
	end
	return 0
end
function modifier_imba_unleash:CheckState() return 
    {
    [MODIFIER_STATE_ROOTED] = true, 
	[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
	[MODIFIER_STATE_DISARMED] = true,
	[MODIFIER_STATE_FROZEN] = self.freeze,
	[MODIFIER_STATE_INVULNERABLE] = self.caster:TG_HasTalent("special_bonus_imba_marci_7"),
    } 
end
function modifier_imba_unleash:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.distance	=	self.ability:GetSpecialValueFor("distance")
	self.per_distance	=	self.ability:GetSpecialValueFor("per_distance")
	self.st_width	=	self.ability:GetSpecialValueFor("st_width")
	self.en_width	=	self.ability:GetSpecialValueFor("en_width")
	self.speed	=	self.ability:GetSpecialValueFor("speed")
	self.punch_range	=	self.ability:GetSpecialValueFor("punch_range")
	self.restitution_cd	=	self.ability:GetSpecialValueFor("restitution_cd")
	self.popup = (self.ability:GetSpecialValueFor("bj") + self.caster:TG_GetTalentValue("special_bonus_imba_marci_6")) / 100
	if not IsServer() then return end
	self.parent:AddActivityModifier("faster")
	self.parent:AddActivityModifier("flurry_pulse_attack")
	self.pfx = ParticleManager:CreateParticle( "particles/marci_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, nil )
	ParticleManager:SetParticleControl( self.pfx, 1, self.parent:GetAbsOrigin()+Vector(0,0,100))
	--self:AddParticle(self.pfx,false, false, -1, false, false )
	self.freeze = nil
	self.dis_turn = nil
	self.int = 0.4
	self.time = 0
	self.punch = false
	self.punch2 = false
	self.parent:EmitSound("Item.ForceField.Cast")
	if self.parent:HasAbility("imba_marci_grapple") then
		self.parent:FindAbilityByName("imba_marci_grapple"):SetActivated(false) 
	end	
	self:StartIntervalThink(self.int)
end
function modifier_imba_unleash:OnIntervalThink(keys)
	if self.int == FrameTime() then 	
		self.time = self.time + FrameTime()
		if self.time > 0.07 and not self.freeze then
			self.freeze = true
			self.dis_turn = 1
			self.time = 0
		end
		if self.time > 0.3 and self.freeze then
			self.freeze = nil
			local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_marci/marci_attack_normal_punch.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
			ParticleManager:SetParticleControl( pfx, 0, self.parent:GetAbsOrigin())
			ParticleManager:SetParticleControl( pfx, 2, self.parent:GetAbsOrigin())
			ParticleManager:SetParticleControl( pfx, 5, Vector(1000,0,0))
			ParticleManager:ReleaseParticleIndex(pfx)
			local sound_dummy = CreateModifierThinker(
				self.caster, 
				self.ability, 
				"modifier_dummy_thinker", 
				{
					duration = 5,
				}, 
				self.parent:GetAbsOrigin(),
				self.caster:GetTeamNumber(),
				false
			)
			local distance = self.distance
			local int = 1
			local effect = ""
			if self.caster:HasModifier("modifier_imba_swing") and self.punch2 then
				distance = self.per_distance
				effect = "particles/heros/marci.vpcf"
				EmitSoundOn( "Aegis.Timer", sound_dummy )
				EmitSoundOn( "Hero_Earthshaker.Arcana.GlobalLayer1", sound_dummy )
				int = 3
				local modifier = self.caster:FindModifierByName("modifier_imba_swing")
				modifier.int = true
				modifier.unleash = self.punch_range
				self.ability:EndCooldown()
				self.ability:StartCooldown((self.ability:GetCooldown(self.ability:GetLevel() -1 ) * self.caster:GetCooldownReduction()) - self.restitution_cd)
			elseif self.caster:HasModifier("modifier_imba_swing") and not self.punch2 then
				--EmitSoundOn( "Hero_EarthShaker.EchoSlamSmall.Arcana", sound_dummy )
				--EmitSoundOn( "Greevil.EchoSlamSmall", sound_dummy )
				effect = "particles/heros/marci.vpcf"
				EmitSoundOn( "Hero_EarthShaker.EchoSlam.Arcana", sound_dummy )
				int = 2
				--EmitSoundOn( "Hero_Dark_Seer.NormalPunch.Lv3", sound_dummy )
				local modifier = self.caster:FindModifierByName("modifier_imba_swing")
				modifier.int = true
				modifier.unleash = self.punch_range
				self.ability:EndCooldown()
				self.ability:StartCooldown((self.ability:GetCooldown(self.ability:GetLevel() -1 ) * self.caster:GetCooldownReduction()) - self.restitution_cd)
			elseif not self.caster:HasModifier("modifier_imba_swing") and not self.punch2 then
				EmitSoundOn( "Hero_EarthShaker.EchoSlamSmall.Arcana", sound_dummy )
				local enemies = FindUnitsInRadius(
					self.caster:GetTeamNumber(),
					self.caster:GetAbsOrigin()+self.caster:GetForwardVector()*150,
					nil,
					self.punch_range,
					DOTA_UNIT_TARGET_TEAM_ENEMY,
					DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
					DOTA_UNIT_TARGET_FLAG_NONE,
					FIND_CLOSEST,
					false)
				for _,enemy in pairs(enemies) do
					local damageTable = {
						victim = enemy,
						attacker = self.parent,
						damage = self.parent:GetAverageTrueAttackDamage(self.parent)*self.popup,
						damage_type = DAMAGE_TYPE_PHYSICAL,
						ability = self.ability,
						}
					self.ability:PopupNumber_Marci(enemy, damageTable.damage)
					ApplyDamage(damageTable)
				end
			end
			local info =
				{
					Ability = self.ability,
					EffectName = effect,
					vSpawnOrigin = self.caster:GetAbsOrigin(),
					fDistance = distance,
					fStartRadius = self.st_width,
					fEndRadius = self.en_width,
					Source = self.caster,
					iSourceAttachment = "attack1",
					bHasFrontalCone = false,
					bReplaceExisting = false,
					iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
					iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
					iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
					fExpireTime = GameRules:GetGameTime() + 10.0,
					bDeleteOnHit = false,
					vVelocity = self.caster:GetForwardVector() * self.speed,
					bProvidesVision = false,
					ExtraData = 
					{
						sound_dummy = sound_dummy:entindex(),
						int = int,
					}
				}
			ProjectileManager:CreateLinearProjectile(info)
			self:StartIntervalThink(-1)
			return
		end
	end
	if self.int == 0.6 then
		self.int = FrameTime()
		self:StartIntervalThink(self.int)
		self.parent:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK,1)
		if self.pfx then
			ParticleManager:DestroyParticle(self.pfx, false)
			ParticleManager:ReleaseParticleIndex(self.pfx)
		end
	end
	if self.int == 0.4 then
		--print("时间点")
		self.int = 0.6
		self:StartIntervalThink(self.int)
		if self.punch then
			EmitSoundOn( "DOTA_Item.Nullifier.Target", self.parent )
			self.punch2 = true
		end
	end
end
function modifier_imba_unleash:OnRemoved()
	if IsServer() then
		self.parent:ClearActivityModifiers()
		self.parent:FadeGesture(ACT_DOTA_ATTACK)
		if self.parent:HasAbility("imba_marci_grapple") then
			self.parent:FindAbilityByName("imba_marci_grapple"):SetActivated(true) 
		end
		if self.pfx then
			ParticleManager:DestroyParticle(self.pfx, false)
			ParticleManager:ReleaseParticleIndex(self.pfx)
		end
		if self.caster:TG_HasTalent("special_bonus_imba_marci_5") then	
			local ability = self.caster:FindAbilityByName("imba_marci_guardian")
			local stack = self.ability:GetSpecialValueFor("stack")
			if ability and ability:IsTrained() then
				local modifier = self.caster:AddNewModifier(
				self.caster, 
				ability, 
				"modifier_imba_grapple_buff1", 
				{
					duration = -1,
				})
				self.caster:SetModifierStackCount("modifier_imba_grapple_buff1", caster, stack)
			end
		end
	end
end