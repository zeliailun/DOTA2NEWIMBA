-- Editors:
-- MysticBug, 20.09.2021
--------------------------------------------------------------------------------
------			       	Snapfire Mortimer Kisses                          ------
--------------------------------------------------------------------------------

ranger_snapfire_mortimer_kisses = class({})

LinkLuaModifier( "modifier_ranger_snapfire_mortimer_kisses", "mb/ranger/ranger_snapfire_mortimer_kisses.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ranger_snapfire_mortimer_kisses_passive", "mb/ranger/ranger_snapfire_mortimer_kisses.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ranger_snapfire_mortimer_kisses_thinker", "mb/ranger/ranger_snapfire_mortimer_kisses.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ranger_snapfire_mortimer_kisses_aura", "mb/ranger/ranger_snapfire_mortimer_kisses.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ranger_snapfire_mortimer_kisses_debuff", "mb/ranger/ranger_snapfire_mortimer_kisses.lua", LUA_MODIFIER_MOTION_NONE ) 
LinkLuaModifier( "modifier_ranger_snapfire_mortimer_kisses_cd", "mb/ranger/ranger_snapfire_mortimer_kisses.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function ranger_snapfire_mortimer_kisses:GetAOERadius() return self:GetSpecialValueFor( "impact_radius" ) end
function ranger_snapfire_mortimer_kisses:GetIntrinsicModifierName() return "modifier_ranger_snapfire_mortimer_kisses_passive" end
function ranger_snapfire_mortimer_kisses:IsHiddenWhenStolen() 	return false end
function ranger_snapfire_mortimer_kisses:IsRefreshable() 		return true end
function ranger_snapfire_mortimer_kisses:IsStealable() 			return true end
function ranger_snapfire_mortimer_kisses:IsNetherWardStealable()	return false end
--------------------------------------------------------------------------------
-- Ability Start
function ranger_snapfire_mortimer_kisses:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- load data
	local duration = self:GetDuration()

	-- add modifier
	caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_ranger_snapfire_mortimer_kisses", -- modifier name
		{
			duration = duration,
			pos_x = point.x,
			pos_y = point.y,
		} -- kv
	)
end

--------------------------------------------------------------------------------
-- Projectile
function ranger_snapfire_mortimer_kisses:OnProjectileHit( target, location )
	if not target then return end

	-- load data
	local damage = self:GetSpecialValueFor( "damage_per_impact" )
	if not self:GetCaster():HasModifier("modifier_ranger_snapfire_mortimer_kisses") then 
		damage = damage / 2
	end
	local duration = self:GetSpecialValueFor( "burn_ground_duration" )
	local impact_radius = self:GetSpecialValueFor( "impact_radius" )
	local vision = self:GetSpecialValueFor( "projectile_vision" )
	-- precache damage
	local damageTable = {
		-- victim = target,
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = self:GetAbilityDamageType(),
		ability = self, --Optional.
	}

	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		location,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		impact_radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	for _,enemy in pairs(enemies) do
		damageTable.victim = enemy
		ApplyDamage(damageTable)
	end

	-- start aura on thinker
	target:AddNewModifier(
		self:GetCaster(), -- player source
		self, -- ability source
		"modifier_ranger_snapfire_mortimer_kisses_thinker", -- modifier name
		{
			duration = duration,
			slow = 1
		} -- kv
	)

	-- destroy trees
	GridNav:DestroyTreesAroundPoint( location, impact_radius, true )

	-- create Vision
	AddFOWViewer( self:GetCaster():GetTeamNumber(), location, vision, duration, false )

	-- play effects
	self:PlayEffects( target:GetOrigin() )
end

--------------------------------------------------------------------------------
function ranger_snapfire_mortimer_kisses:PlayEffects( loc )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_impact.vpcf"
	local particle_cast2 = "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_linger.vpcf"
	local sound_cast = "Hero_Snapfire.MortimerBlob.Impact"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 3, loc )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	local effect_cast = ParticleManager:CreateParticle( particle_cast2, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, loc )
	ParticleManager:SetParticleControl( effect_cast, 1, loc )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	local sound_location = "Hero_Snapfire.MortimerBlob.Impact"
	EmitSoundOnLocationWithCaster( loc, sound_location, self:GetCaster() )
end
--------------------------------------------------------------------------------
-- Projectile
function CastSingleMortimerKisses( caster, ability, target, location )
	if not target then return end

	-- load data
	local damage = ability:GetSpecialValueFor( "damage_per_impact" )
	local duration = ability:GetSpecialValueFor( "burn_ground_duration" )
	local impact_radius = ability:GetSpecialValueFor( "impact_radius" )
	local projectile_vision = ability:GetSpecialValueFor( "projectile_vision" )

	local projectile_speed = ability:GetSpecialValueFor( "projectile_speed" )
	local projectile_name = "particles/units/heroes/hero_snapfire/snapfire_lizard_blobs_arced.vpcf"

	--thinker
	local thinker = CreateModifierThinker(
		caster, -- player source
		ability, -- ability source
		"modifier_ranger_snapfire_mortimer_kisses_thinker", -- modifier name
		{ travel_time = 0.3 }, -- kv
		location,
		caster:GetTeamNumber(),
		false
	)

	-- precache projectile
	local info = {
		Target = thinker,
		Source = caster,
		Ability = ability,	
		
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		bDodgeable = false,                           -- Optional
	
		vSourceLoc = caster:GetOrigin(),                -- Optional (HOW)
		
		bDrawsOnMinimap = false,                          -- Optional
		bVisibleToEnemies = true,                         -- Optional
		bProvidesVision = true,                           -- Optional
		iVisionRadius = projectile_vision,                              -- Optional
		iVisionTeamNumber = caster:GetTeamNumber()        -- Optional
	}
	-- launch projectile
	ProjectileManager:CreateTrackingProjectile( info )

	-- create FOW
	AddFOWViewer( caster:GetTeamNumber(), thinker:GetOrigin(), 100, 1, false )

	-- play sound
	local sound_cast = "Hero_Snapfire.MortimerBlob.Launch"
	EmitSoundOn( sound_cast, thinker )
end

--IMBA 
--------------------------------------------------------------------------------
modifier_ranger_snapfire_mortimer_kisses_passive = class({})
--------------------------------------------------------------------------------
function modifier_ranger_snapfire_mortimer_kisses_passive:IsPassive()			return true end
function modifier_ranger_snapfire_mortimer_kisses_passive:IsDebuff()			return false end
function modifier_ranger_snapfire_mortimer_kisses_passive:IsBuff()			return true end
function modifier_ranger_snapfire_mortimer_kisses_passive:IsHidden() 			return true end
function modifier_ranger_snapfire_mortimer_kisses_passive:IsPurgable() 		return false end
function modifier_ranger_snapfire_mortimer_kisses_passive:IsPurgeException() 	return false end
function modifier_ranger_snapfire_mortimer_kisses_passive:AllowIllusionDuplicate() return false end
function modifier_ranger_snapfire_mortimer_kisses_passive:DeclareFunctions() return {MODIFIER_EVENT_ON_ATTACK_LANDED,MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT} end
function modifier_ranger_snapfire_mortimer_kisses_passive:OnAttackLanded(keys)
	if not IsServer() then
		return
	end
	if keys.attacker ~= self:GetParent() or self:GetParent():IsIllusion() or self:GetParent():PassivesDisabled() or not keys.target:IsAlive() then
		return
	end
	--触发
	if PseudoRandom:RollPseudoRandom(self:GetAbility(), self:GetAbility():GetSpecialValueFor("kisses_chance")) and not self:GetParent():HasModifier("modifier_ranger_snapfire_mortimer_kisses_cd") then
		--施法火团
		CastSingleMortimerKisses(self:GetCaster(),self:GetAbility(),keys.target,keys.target:GetAbsOrigin())
		self:GetParent():AddNewModifier(
			self:GetParent(), -- player source
			self:GetAbility(), -- ability source
			"modifier_ranger_snapfire_mortimer_kisses_cd", -- modifier name
			{
				duration = 0.3
			} -- kv
		)		
	end
end

function modifier_ranger_snapfire_mortimer_kisses_passive:GetModifierAttackSpeedBonus_Constant()
	if not self:GetParent():PassivesDisabled() then
		return self:GetAbility():GetSpecialValueFor( "bonus_attack_speed" )
   	end
end

modifier_ranger_snapfire_mortimer_kisses_cd = class({}) 

function modifier_ranger_snapfire_mortimer_kisses_cd:IsDebuff()			return true end
function modifier_ranger_snapfire_mortimer_kisses_cd:IsHidden() 			return false end
function modifier_ranger_snapfire_mortimer_kisses_cd:IsPurgable() 		return false end
function modifier_ranger_snapfire_mortimer_kisses_cd:IsPurgeException() 	return false end

--------------------------------------------------------------------------------
modifier_ranger_snapfire_mortimer_kisses = class({})
--------------------------------------------------------------------------------
-- Classifications
function modifier_ranger_snapfire_mortimer_kisses:IsHidden() return false end
function modifier_ranger_snapfire_mortimer_kisses:IsDebuff() return false end
function modifier_ranger_snapfire_mortimer_kisses:IsBuff() return true end
function modifier_ranger_snapfire_mortimer_kisses:IsStunDebuff() return false end
function modifier_ranger_snapfire_mortimer_kisses:IsPurgable() return false end
--------------------------------------------------------------------------------
-- Initializations
function modifier_ranger_snapfire_mortimer_kisses:OnCreated( kv )
	-- references
	self.min_range = self:GetAbility():GetSpecialValueFor( "min_range" )
	self.max_range = self:GetAbility():GetCastRange( Vector(0,0,0), nil )
	self.range = self.max_range-self.min_range
	
	self.min_travel = self:GetAbility():GetSpecialValueFor( "min_lob_travel_time" )
	self.max_travel = self:GetAbility():GetSpecialValueFor( "max_lob_travel_time" )
	self.travel_range = self.max_travel-self.min_travel
	
	self.projectile_speed = self:GetAbility():GetSpecialValueFor( "projectile_speed" )
	local projectile_vision = self:GetAbility():GetSpecialValueFor( "projectile_vision" )
	
	self.turn_rate = self:GetAbility():GetSpecialValueFor( "turn_rate" )

	if not IsServer() then return end
	-- load data
	local interval = self:GetAbility():GetDuration()/(self:GetAbility():GetSpecialValueFor( "projectile_count" ) + self:GetCaster():TG_GetTalentValue("special_bonus_imba_snapfire_1")) + 0.01 -- so it only have 8 projectiles instead of 9
	self:SetValidTarget( Vector( kv.pos_x, kv.pos_y, 0 ) )
	local projectile_name = "particles/units/heroes/hero_snapfire/snapfire_lizard_blobs_arced.vpcf"
	local projectile_start_radius = 0
	local projectile_end_radius = 0

	-- precache projectile
	self.info = {
		-- Target = target,
		Source = self:GetCaster(),
		Ability = self:GetAbility(),	
		
		EffectName = projectile_name,
		iMoveSpeed = self.projectile_speed,
		bDodgeable = false,                           -- Optional
	
		vSourceLoc = self:GetCaster():GetOrigin(),                -- Optional (HOW)
		
		bDrawsOnMinimap = false,                          -- Optional
		bVisibleToEnemies = true,                         -- Optional
		bProvidesVision = true,                           -- Optional
		iVisionRadius = projectile_vision,                              -- Optional
		iVisionTeamNumber = self:GetCaster():GetTeamNumber()        -- Optional
	}

	-- Start interval
	self:StartIntervalThink( interval )
	self:OnIntervalThink()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ranger_snapfire_mortimer_kisses:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ORDER,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
	}
	return funcs
end

function modifier_ranger_snapfire_mortimer_kisses:OnOrder( params )
	if params.unit~=self:GetParent() then return end

	-- right click, switch position
	if 	params.order_type==DOTA_UNIT_ORDER_MOVE_TO_POSITION then
		self:SetValidTarget( params.new_pos )
	elseif 
		params.order_type==DOTA_UNIT_ORDER_MOVE_TO_TARGET or
		params.order_type==DOTA_UNIT_ORDER_ATTACK_TARGET
	then
		self:SetValidTarget( params.target:GetOrigin() )

	-- stop or hold
	elseif 
		params.order_type==DOTA_UNIT_ORDER_STOP or
		params.order_type==DOTA_UNIT_ORDER_HOLD_POSITION
	then
		self:Destroy()
	end
end

function modifier_ranger_snapfire_mortimer_kisses:GetModifierMoveSpeed_Limit() return 0.1 end
function modifier_ranger_snapfire_mortimer_kisses:GetModifierTurnRate_Percentage() return -self.turn_rate end
--------------------------------------------------------------------------------
-- Status Effects
function modifier_ranger_snapfire_mortimer_kisses:CheckState()
	local state = {
		[MODIFIER_STATE_DISARMED] = true,
	}
	return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_ranger_snapfire_mortimer_kisses:OnIntervalThink()
	-- create target thinker
	local thinker = CreateModifierThinker(
		self:GetParent(), -- player source
		self:GetAbility(), -- ability source
		"modifier_ranger_snapfire_mortimer_kisses_thinker", -- modifier name
		{ travel_time = self.travel_time }, -- kv
		self.target_pos,
		self:GetParent():GetTeamNumber(),
		false
	)
	-- keep gesture
	self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_4)
	-- set projectile
	self.info.iMoveSpeed = self.vector:Length2D()/self.travel_time
	self.info.Target = thinker

	-- launch projectile
	ProjectileManager:CreateTrackingProjectile( self.info )

	-- create FOW
	AddFOWViewer( self:GetParent():GetTeamNumber(), thinker:GetOrigin(), 100, 1, false )

	-- play sound
	local sound_cast = "Hero_Snapfire.MortimerBlob.Launch"
	EmitSoundOn( sound_cast, self:GetParent() )
end

--------------------------------------------------------------------------------
-- Helper
function modifier_ranger_snapfire_mortimer_kisses:SetValidTarget( location )
	local origin = self:GetParent():GetOrigin()
	local vec = location-origin
	local direction = vec
	direction.z = 0
	direction = direction:Normalized()

	if vec:Length2D()<self.min_range then
		vec = direction * self.min_range
	elseif vec:Length2D()>self.max_range then
		vec = direction * self.max_range
	end

	self.target_pos = GetGroundPosition( origin + vec, nil )
	self.vector = vec
	self.travel_time = (vec:Length2D()-self.min_range)/self.range * self.travel_range + self.min_travel
end

--------------------------------------------------------------------------------
modifier_ranger_snapfire_mortimer_kisses_debuff = class({})
--------------------------------------------------------------------------------
-- Classifications
function modifier_ranger_snapfire_mortimer_kisses_debuff:IsHidden() return false end
function modifier_ranger_snapfire_mortimer_kisses_debuff:IsDebuff() return true end
function modifier_ranger_snapfire_mortimer_kisses_debuff:IsBuff()	return false end
function modifier_ranger_snapfire_mortimer_kisses_debuff:IsStunDebuff() return false end
function modifier_ranger_snapfire_mortimer_kisses_debuff:IsPurgable() return true end
--------------------------------------------------------------------------------
-- Initializations
function modifier_ranger_snapfire_mortimer_kisses_debuff:OnCreated( kv )
	-- references
	self.slow = - (self:GetAbility():GetSpecialValueFor( "move_slow_pct" ) + self:GetCaster():TG_GetTalentValue("special_bonus_imba_snapfire_4"))
	self.dps = self:GetAbility():GetSpecialValueFor( "burn_damage" )
	local interval = self:GetAbility():GetSpecialValueFor( "burn_interval" )

	if not IsServer() then return end

	-- precache damage
	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self.dps*interval,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(), --Optional.
	}

	-- Start interval
	self:StartIntervalThink( interval )
	self:OnIntervalThink()
end
--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ranger_snapfire_mortimer_kisses_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
	return funcs
end

function modifier_ranger_snapfire_mortimer_kisses_debuff:GetModifierMoveSpeedBonus_Percentage() return self.slow end
--------------------------------------------------------------------------------
-- Interval Effects
function modifier_ranger_snapfire_mortimer_kisses_debuff:OnIntervalThink()
	-- apply damage
	ApplyDamage( self.damageTable )
	-- play overhead
end
--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ranger_snapfire_mortimer_kisses_debuff:GetEffectName() return "particles/units/heroes/hero_snapfire/hero_snapfire_burn_debuff.vpcf" end
function modifier_ranger_snapfire_mortimer_kisses_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_ranger_snapfire_mortimer_kisses_debuff:GetStatusEffectName() return "particles/status_fx/status_effect_snapfire_magma.vpcf" end
function modifier_ranger_snapfire_mortimer_kisses_debuff:StatusEffectPriority() return MODIFIER_PRIORITY_NORMAL end

--------------------------------------------------------------------------------
modifier_ranger_snapfire_mortimer_kisses_thinker = class({})
--------------------------------------------------------------------------------
-- Classifications
--------------------------------------------------------------------------------
-- Initializations
function modifier_ranger_snapfire_mortimer_kisses_thinker:OnCreated( kv )
	-- references
	self.max_travel = self:GetAbility():GetSpecialValueFor( "max_lob_travel_time" )
	self.radius = self:GetAbility():GetSpecialValueFor( "impact_radius" )
	self.linger = self:GetAbility():GetSpecialValueFor( "burn_linger_duration" )

	if not IsServer() then return end

	-- dont start aura right off
	self.start = false

	-- create aoe finder particle
	self:PlayEffects( kv.travel_time )
end

function modifier_ranger_snapfire_mortimer_kisses_thinker:OnRefresh( kv )
	-- references
	self.max_travel = self:GetAbility():GetSpecialValueFor( "max_lob_travel_time" )
	self.radius = self:GetAbility():GetSpecialValueFor( "impact_radius" )
	self.linger = self:GetAbility():GetSpecialValueFor( "burn_linger_duration" )

	if not IsServer() then return end

	-- start aura
	self.start = true

	-- stop aoe finder particle
	self:StopEffects()
end

function modifier_ranger_snapfire_mortimer_kisses_thinker:OnRemoved()
end

function modifier_ranger_snapfire_mortimer_kisses_thinker:OnDestroy()
	if not IsServer() then return end
	self:StopEffects()
	self:GetParent():RemoveSelf()
end

--------------------------------------------------------------------------------
-- Aura Effects
function modifier_ranger_snapfire_mortimer_kisses_thinker:IsAura() return self.start end
function modifier_ranger_snapfire_mortimer_kisses_thinker:GetModifierAura()
	return "modifier_ranger_snapfire_mortimer_kisses_debuff"
end

function modifier_ranger_snapfire_mortimer_kisses_thinker:GetAuraRadius() return self.radius end
function modifier_ranger_snapfire_mortimer_kisses_thinker:GetAuraDuration() return self.linger end
function modifier_ranger_snapfire_mortimer_kisses_thinker:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_ranger_snapfire_mortimer_kisses_thinker:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_ranger_snapfire_mortimer_kisses_thinker:PlayEffects( time )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_calldown.vpcf"
	--if not time or time == nil then  time = 0.3 end
	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticleForTeam( particle_cast, PATTACH_CUSTOMORIGIN, self:GetCaster(), self:GetCaster():GetTeamNumber() )
	ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( self.radius, 0, -self.radius*(self.max_travel/time) ) )
	ParticleManager:SetParticleControl( self.effect_cast, 2, Vector( time , 0, 0 ) )
end

function modifier_ranger_snapfire_mortimer_kisses_thinker:StopEffects()
	ParticleManager:DestroyParticle( self.effect_cast, true )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )
end