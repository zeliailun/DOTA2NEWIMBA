--2021.10.30---by你收拾收拾准备出林肯吧
CreateTalents("npc_dota_hero_marci_lin", "linken/hero_marci/hero_marci")
imba_marci_swing = class({})

--俯冲到目标地点
LinkLuaModifier("modifier_imba_swing", "linken/hero_marci/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_swing_silence", "linken/hero_marci/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_marci_armor", "linken/hero_marci/hero_marci", LUA_MODIFIER_MOTION_NONE)
function imba_marci_swing:Set_InitialUpgrade(tg)
    return {LV=1}
end
function imba_marci_swing:CastFilterResultLocation()
	if self:GetCaster():IsHexed() then
		return UF_FAIL_CUSTOM
	end
end
function imba_marci_swing:GetCustomCastErrorLocation()
	if self:GetCaster():IsHexed() then
		return "#dota_hud_error_ability_inactive"
	end
end
function imba_marci_swing:GetIntrinsicModifierName() return "modifier_imba_swing_silence" end
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
	
	caster:AddNewModifier(
		caster, 
		self, 
		"modifier_imba_swing", 
		{
			duration = 1,
			pos = pos,
			--suc = suc
		})
	caster:EmitSound("marci_marci_move_2")
end	
modifier_imba_swing_silence = class({})
function modifier_imba_swing_silence:IsDebuff()				return false end
function modifier_imba_swing_silence:IsHidden() 			return true end
function modifier_imba_swing_silence:IsPurgable() 			return false end
function modifier_imba_swing_silence:IsPurgeException() 	return false end
function modifier_imba_swing_silence:CheckState() return 
    {
    [MODIFIER_STATE_SILENCED] = true, 
    } 
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
	--[MODIFIER_STATE_INVULNERABLE] = true,
	[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	--[MODIFIER_STATE_DISARMED] = true,
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
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_AVOID_DAMAGE,
    }
end
function modifier_imba_swing:GetModifierAvoidDamage(keys)
	return 1
end
function modifier_imba_swing:OnTakeDamage(keys)
	if not IsServer() then
		return
	end
	if keys.unit == self.parent and bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION and bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) ~= DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL then
		if self.pfx_bool and keys.original_damage then
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_MISS, self.parent, 0, nil)
			self.ability:SetCurrentAbilityCharges(self.ability:GetCurrentAbilityCharges()+1)
			self.pfx_bool = false
		end
	end
end
function modifier_imba_swing:OnCreated(keys)
	if not self:GetAbility() then
		return
	end
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.distance = self.ability:GetSpecialValueFor("distance")
	if not IsServer() then
		return
	end
	self.pfx_bool = true
	self.int = keys.int and true
	self.unleash = 200
	self.hitted = {}
	self.pos = StringToVector(keys.pos)
	self.parent:MoveToPositionAggressive(self.pos)
	self.speed = 1500
	self.parent:SetForwardVector(GetDirection2D(self.pos, self.parent:GetAbsOrigin()))
	self.fv = self.parent:GetForwardVector()
	self.rv = self.parent:GetRightVector()
	self.uv = self.parent:GetUpVector()
	
	if CalculateDistance(self.pos, self.caster:GetAbsOrigin()) < 30 then
		self.pos = self.caster:GetAbsOrigin() + self.caster:GetForwardVector() * self.distance
	end
	if CalculateDistance(self.pos, self.caster:GetAbsOrigin()) > self.distance then
		self.pos = self.caster:GetAbsOrigin() + GetDirection2D(self.pos, self.caster:GetAbsOrigin()) * self.distance
	end
	local swap_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_vengeful/vengeful_nether_swap.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlEnt(swap_pfx, 0, self.parent, PATTACH_POINT, "attach_hitloc", self.parent:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(swap_pfx, 1, nil, PATTACH_POINT, "attach_hitloc", self.pos, true)	
	
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
						--damage_flags = DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR,
						ability = self.ability,
						}
					ability:PopupNumber_Marci(enemy, damageTable.damage)
					enemy:AddNewModifier(self.caster, self.ability, "modifier_imba_marci_armor", {})
					ApplyDamage(damageTable)
					TG_Remove_Modifier(enemy,"modifier_imba_marci_armor",0)
					self.hitted[#self.hitted+1] = enemy	
				end
			end	
		end
end
function modifier_imba_swing:OnRemoved()
    if IsServer() then
		self.popup = nil
		self.pfx_bool = true
		self.int = false
		local pfx = ParticleManager:CreateParticle("particles/econ/items/windrunner/windranger_arcana/windranger_arcana_powershot_channel_v2_endcap_model.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(pfx, 0, GetGroundPosition(self.parent:GetAbsOrigin(), self.parent)) 
		ParticleManager:SetParticleControl(pfx, 1, GetGroundPosition(self.pos, self.parent))
		ParticleManager:SetParticleControlOrientation(pfx, 1, self.fv, self.rv, self.uv)
		ParticleManager:ReleaseParticleIndex(pfx)
    end
end
modifier_imba_marci_armor = class({})
function modifier_imba_marci_armor:IsDebuff()				return true end
function modifier_imba_marci_armor:IsHidden() 			return false end
function modifier_imba_marci_armor:IsPurgable() 			return false end
function modifier_imba_marci_armor:IsPurgeException() 	return false end
function modifier_imba_marci_armor:DeclareFunctions() return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS} end
function modifier_imba_marci_armor:OnCreated(keys)
	if IsServer() then
		self.armor_int = math.abs(self:GetParent():GetPhysicalArmorValue(false)*0.8)
		self:SetStackCount(self.armor_int)
	end 
end
function modifier_imba_marci_armor:GetModifierPhysicalArmorBonus(keys)
	return 0 - self:GetStackCount()
end
imba_marci_grapple = class({})

--抓取一圈敌人 背摔

LinkLuaModifier("modifier_imba_grapple_move", "linken/hero_marci/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_grapple_damage", "linken/hero_marci/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_grapple_self", "linken/hero_marci/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_knockback_lua", "linken/modifier_generic_knockback_lua.lua", LUA_MODIFIER_MOTION_BOTH)
function imba_marci_grapple:Precache( context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_marci.vsndevts", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_marci/marci_dispose_aoe_damage.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_marci/marci_dispose_debuff.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_marci/marci_dispose_land_aoe.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_marci/marci_grapple.vpcf", context )
end
function imba_marci_grapple:CastFilterResult()
	if self:GetCaster():IsHexed() then
		return UF_FAIL_CUSTOM
	end
end
function imba_marci_grapple:GetCustomCastError()
	if self:GetCaster():IsHexed() then
		return "#dota_hud_error_ability_inactive"
	end
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
	[MODIFIER_STATE_INVULNERABLE] = self.caster:Has_Aghanims_Shard(),
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
				--self.ability:StartCooldown((self.ability:GetCooldown(self.ability:GetLevel() -1 ) * self.caster:GetCooldownReduction()) - self.caster:TG_GetTalentValue("special_bonus_imba_marci_8"))
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
	if self.caster:Has_Aghanims_Shard() then
		self.stun_duration = self.ability:GetSpecialValueFor("stun_duration") + self.ability:GetSpecialValueFor("agh_stun")
	end
end
function modifier_imba_grapple_self:OnRemoved()
    if IsServer() then
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_marci/marci_dispose_land_aoe.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(pfx, 0, GetGroundPosition(self.parent:GetAbsOrigin(), self.parent)) 
		ParticleManager:SetParticleControl(pfx, 1, Vector(self.impact_radius,0,0))
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
				--print(self.stun_duration)
				enemy:AddNewModifier_RS(self.parent, self.ability, "modifier_stunned", {duration = self.stun_duration})
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

imba_marci_guardian = class({})
LinkLuaModifier("modifier_imba_grapple_passive", "linken/hero_marci/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_grapple_buff1", "linken/hero_marci/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_grapple_buff2", "linken/hero_marci/hero_marci", LUA_MODIFIER_MOTION_NONE)
function imba_marci_guardian:GetCooldown(level)
	local cooldown = self.BaseClass.GetCooldown(self, level)
	local caster = self:GetCaster()
		if caster:TG_HasTalent("special_bonus_imba_marci_3") then 
			return (cooldown - caster:TG_GetTalentValue("special_bonus_imba_marci_3"))
		end
	return cooldown
end
function imba_marci_guardian:CastFilterResult()
	if self:GetCaster():IsHexed() then
		return UF_FAIL_CUSTOM
	end
end
function imba_marci_guardian:GetCustomCastError()
	if self:GetCaster():IsHexed() then
		return "#dota_hud_error_ability_inactive"
	end
end
function imba_marci_guardian:GetIntrinsicModifierName() return "modifier_imba_grapple_passive" end
function imba_marci_guardian:OnUpgrade()
	local caster = self:GetCaster()		
	if self:GetLevel() == 1 then
		self.Mirana = nil
		if not self.Mirana then
			local heros = FindUnitsInRadius(
			caster:GetTeamNumber(),
			caster:GetAbsOrigin(),
			nil,
			25000, 
			DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 
			FIND_ANY_ORDER,false)
			if #heros>0 then
				for _, hero in pairs(heros) do
					if hero:GetName()=="npc_dota_hero_mirana" then 
						self.Mirana = hero
						break
					end
				end
			end
		end		
	end
end

modifier_imba_grapple_passive = class({})
function modifier_imba_grapple_passive:IsDebuff()			return false end
function modifier_imba_grapple_passive:IsHidden() 			return true end
function modifier_imba_grapple_passive:IsPurgable() 			return false end
function modifier_imba_grapple_passive:IsPurgeException() 	return false end
function modifier_imba_grapple_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
	return funcs
end

function modifier_imba_grapple_passive:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.duration	= 	-1
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
	if not self.ability:IsCooldownReady() then
		return
	end
	if not self.ability:IsTrained() then
		return
	end
	if PseudoRandom:RollPseudoRandom(self.ability, self.ability:GetSpecialValueFor("chance_pct")) then
		self.parent:AddNewModifier(self.parent, self.ability, "modifier_imba_grapple_buff1", {duration = self.duration})
		self.ability:UseResources(true, true, true)
		EmitSoundOn( "Hero_Marci.Unleash.Charged", self.parent )
		--EmitSoundOn( "Hero_Marci.Unleash.Charged.2D", self.parent )	
	end
end
function modifier_imba_grapple_passive:OnAbilityFullyCast(keys)
	if IsServer() and not self.parent:PassivesDisabled() then
		if self.ability:GetLevel() == 0 then return end
		if keys.unit ~= self.parent or keys.ability:IsItem() then 
			return 
		end
		if not self.ability:IsCooldownReady() then
			return
		end
		self.parent:AddNewModifier(self.parent, self.ability, "modifier_imba_grapple_buff1", {duration = self.duration})
		self.ability:UseResources(true, true, true)
		local pfx_name = "particles/units/heroes/hero_marci/marci_unleash_cast.vpcf"
		local pfx = ParticleManager:CreateParticle( pfx_name, PATTACH_ABSORIGIN_FOLLOW, self.parent )
		ParticleManager:ReleaseParticleIndex( pfx )
		EmitSoundOn( "Hero_Marci.Unleash.Charged", self.parent )
		--EmitSoundOn( "Hero_Marci.Unleash.Charged.2D", self.parent )
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
		--MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,

		MODIFIER_PROPERTY_IGNORE_ATTACKSPEED_LIMIT,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,

	}
	return funcs
end
function modifier_imba_grapple_buff1:GetModifierAttackSpeed_Limit()
	return 0.7
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
	self.range = self.ability:GetSpecialValueFor("nearest_ally_search_range")
	self.aoe_damage = self.ability:GetSpecialValueFor("aoe_damage")
	if not IsServer() then return end
	if not self.parent:HasModifier("modifier_marci_guardian_buff") then
		self.parent:AddNewModifier(
				self.caster, 
				self.ability, 
				"modifier_marci_guardian_buff", 
				{
					duration = -1,
				})
	end
	if not self.effect_cast then
		local particle_cast = "particles/units/heroes/hero_marci/marci_unleash_buff.vpcf"
		self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, self.parent )
		ParticleManager:SetParticleControlEnt(self.effect_cast,1,self.parent,PATTACH_POINT_FOLLOW,"eye_l",Vector(0,0,0), true )
		ParticleManager:SetParticleControlEnt(self.effect_cast,2,self.parent,PATTACH_POINT_FOLLOW,"eye_r",Vector(0,0,0), true )
		ParticleManager:SetParticleControlEnt(self.effect_cast,3,self.parent,PATTACH_POINT_FOLLOW,"attach_attack1",Vector(0,0,0),true )
		ParticleManager:SetParticleControlEnt(self.effect_cast,4,self.parent,PATTACH_POINT_FOLLOW,"attach_attack2",Vector(0,0,0), true )
		ParticleManager:SetParticleControlEnt(self.effect_cast,5,self.parent,PATTACH_POINT_FOLLOW,"attach_attack1",Vector(0,0,0), true )
		ParticleManager:SetParticleControlEnt(self.effect_cast,6,self.parent,PATTACH_POINT_FOLLOW,"attach_attack2",Vector(0,0,0), true )
		self:AddParticle(self.effect_cast,false, false, -1, false, false )
	end
	if self:GetStackCount() < self.stack and not keys.boll then
		self:SetStackCount(self.stack)
	end
	if not self.pfx then
		local pfx_name = "particles/units/heroes/hero_marci/marci_unleash_stack.vpcf"
		self.pfx = ParticleManager:CreateParticle( pfx_name, PATTACH_OVERHEAD_FOLLOW, self.parent )
		ParticleManager:SetParticleControl( self.pfx, 1, Vector( 0, self:GetStackCount(), 0 ) )
		self:AddParticle(self.pfx,false, false, -1, false, false )
	end

	if self.Mirana and self.Mirana:IsAlive() then
		self.Mirana:AddNewModifier(
			self.caster, 
			self.ability, 
			"modifier_marci_guardian_buff", 
			{
				duration = -1,
			})
	end
	if not keys.int then
		local enemies = FindUnitsInRadius(
			self.caster:GetTeamNumber(),
			self.caster:GetAbsOrigin(),
			nil,
			self.range ,
			DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_CLOSEST,
			false)
		for _,enemy in pairs(enemies) do
			if enemy ~= self.caster and not enemy:IsRangedAttacker() then
				enemy:AddNewModifier(
				self.caster, 
				self.ability, 
				"modifier_imba_grapple_buff1", 
				{
					duration = -1,
					int = true
				})
				break
			end
		end
		if self.ability.Mirana and self.ability.Mirana:IsAlive() then
			self.ability.Mirana:AddNewModifier(self.parent, self.ability, "modifier_imba_grapple_buff1", {duration = self.duration})
		end
	end
end
function modifier_imba_grapple_buff1:OnRefresh(keys)
	--if not IsServer() then return end
	self:OnCreated(keys)
end
function modifier_imba_grapple_buff1:OnAttack( keys )
	if not IsServer() then
		return
	end
	if keys.attacker ~= self.parent then
		return
	end	
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
	if self.pfx then
		ParticleManager:SetParticleControl(self.pfx, 1, Vector(0, self:GetStackCount(), 0))
	end
end
function modifier_imba_grapple_buff1:OnIntervalThink(keys)
	self:Destroy()
end

function modifier_imba_grapple_buff1:OnRemoved()
	if IsServer() then
		TG_Remove_Modifier(self.parent,"modifier_marci_guardian_buff",0)
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
			"modifier_paralyzed", 
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