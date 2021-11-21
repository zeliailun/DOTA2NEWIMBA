
-- Editors:
-- MysticBug, 20.09.2021
----------------------------------------------------------
--		   		 RANGER_FIRE_COVER               	    --
----------------------------------------------------------

ranger_fire_cover = class({})
LinkLuaModifier( "modifier_ranger_fire_cover", "mb/ranger/ranger_fire_cover", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ranger_fire_cover_thinker", "mb/ranger/ranger_fire_cover", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ranger_fire_cover_buff", "mb/ranger/ranger_fire_cover", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function ranger_fire_cover:GetAOERadius() return self:GetSpecialValueFor( "radius" ) end
--------------------------------------------------------------------------------
-- Ability Start
function ranger_fire_cover:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- logic
	CreateModifierThinker(
		caster,
		self,
		"modifier_ranger_fire_cover_thinker",
		{},
		point,
		caster:GetTeamNumber(),
		false
	)

	-- effects
	self:PlayEffects( point )
end

--------------------------------------------------------------------------------
function ranger_fire_cover:PlayEffects( point )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_sniper/sniper_shrapnel_launch.vpcf"
	local sound_cast = "Hero_Sniper.ShrapnelShoot"

	-- Get Data
	local height = 2000

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		self:GetCaster():GetOrigin(), -- unknown
		false -- unknown, true
	)
	ParticleManager:SetParticleControl( effect_cast, 1, point + Vector( 0, 0, height ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
end

----------------------------------------------------------
--      MODIFIER_RANGER_FIRE_COVER_THINKER              --
----------------------------------------------------------
modifier_ranger_fire_cover_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ranger_fire_cover_thinker:IsHidden() return true end
function modifier_ranger_fire_cover_thinker:IsPurgable() return false end
--------------------------------------------------------------------------------
-- Aura
function modifier_ranger_fire_cover_thinker:IsAura() return self.start end
function modifier_ranger_fire_cover_thinker:GetModifierAura() return "modifier_ranger_fire_cover" end
function modifier_ranger_fire_cover_thinker:GetAuraRadius() return self.radius end
function modifier_ranger_fire_cover_thinker:GetAuraDuration() return 0.5 end
function modifier_ranger_fire_cover_thinker:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_ranger_fire_cover_thinker:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
--------------------------------------------------------------------------------
-- Initializations
function modifier_ranger_fire_cover_thinker:OnCreated( kv )
	-- references
	self.delay      = self:GetAbility():GetSpecialValueFor( "damage_delay" ) -- special value
	self.radius     = self:GetAbility():GetSpecialValueFor( "radius" ) -- special value
	self.aura_stick = self:GetAbility():GetSpecialValueFor( "slow_duration" ) -- special value
	self.duration   = self:GetAbility():GetSpecialValueFor( "duration" ) -- special value

	self.start = false

	if IsServer() then
		self.direction = (self:GetParent():GetOrigin()-self:GetCaster():GetOrigin()):Normalized()

		-- Start interval
		self:StartIntervalThink( self.delay )

		-- effects
		self.sound_cast = "Hero_Sniper.ShrapnelShatter"
		EmitSoundOn( self.sound_cast, self:GetParent() )		
	end
end

function modifier_ranger_fire_cover_thinker:OnDestroy( kv )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_ranger_fire_cover_thinker:OnIntervalThink()
	if not self.start then
		self.start = true
		--self:StartIntervalThink( self.duration )
		AddFOWViewer( self:GetCaster():GetTeamNumber(), self:GetParent():GetOrigin(), self.radius, self.duration, false )
		-- effects
		self:PlayEffects()
	else
		--Add ally movespeed and inv
		local allies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_DAMAGE_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, ally in pairs(allies) do
			if not ally:HasModifier("modifier_ranger_fire_cover_buff") then 
				ally:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_ranger_fire_cover_buff", { duration = self.delay})
			end
		end
		--End Thinker
		if self:GetElapsedTime() >= self.duration then
			self:StopEffects()
			UTIL_Remove( self:GetParent() )
		end
	end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ranger_fire_cover_thinker:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_sniper/sniper_shrapnel.vpcf"

	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( self.radius, 1, 1 ) )
	ParticleManager:SetParticleControlForward( self.effect_cast, 2, self.direction + Vector(0, 0, 0.1) )
end

function modifier_ranger_fire_cover_thinker:StopEffects()
	ParticleManager:DestroyParticle( self.effect_cast, false )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )

	StopSoundOn( self.sound_cast, self:GetParent() )
end

-------------------------------------------------
--      MODIFIER_RANGER_FIRE_COVER             --
-------------------------------------------------

modifier_ranger_fire_cover = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ranger_fire_cover:IsHidden() return false end
function modifier_ranger_fire_cover:IsDebuff() return true end
function modifier_ranger_fire_cover:IsPurgable() return false end
--------------------------------------------------------------------------------
-- Initializations
function modifier_ranger_fire_cover:OnCreated( kv )
	-- references
	self.damage = self:GetAbility():GetSpecialValueFor( "fire_damage" ) -- special value
	self.ms_slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed" ) -- special value

	local interval = 1
	self.caster = self:GetAbility():GetCaster()

	if IsServer() then
		-- precache damage
		self.damageTable = {
			victim = self:GetParent(),
			attacker = self.caster,
			damage = self.damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(), --Optional.
		}

		-- start interval
		self:StartIntervalThink( interval )
		self:OnIntervalThink()
	end
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ranger_fire_cover:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end
function modifier_ranger_fire_cover:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_slow
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_ranger_fire_cover:OnIntervalThink()
	-- if self.caster:IsAlive() then
		ApplyDamage(self.damageTable)
	-- end
end

-------------------------------------------------
--      MODIFIER_RANGER_FIRE_COVER_BUFF        --
-------------------------------------------------

modifier_ranger_fire_cover_buff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ranger_fire_cover_buff:IsPurgable() return false end
function modifier_ranger_fire_cover_buff:IsDebuff() return false end
function modifier_ranger_fire_cover_buff:IsHidden()	return false end
--------------------------------------------------------------------------------
-- Initializations
function modifier_ranger_fire_cover_buff:OnCreated()
	self.ms_slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed" ) -- special value
	local particle = ParticleManager:CreateParticle("particles/generic_hero_status/status_invisibility_start.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_ranger_fire_cover_buff:DeclareFunctions() return {MODIFIER_PROPERTY_INVISIBILITY_LEVEL,MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE} end

function modifier_ranger_fire_cover_buff:GetModifierInvisibilityLevel()	
	if IsClient() then
		return 1
	end
end

function modifier_ranger_fire_cover_buff:GetModifierMoveSpeedBonus_Percentage()
	return math.abs(self.ms_slow)
end

function modifier_ranger_fire_cover_buff:CheckState()	
	if IsServer() then
		local state = { [MODIFIER_STATE_INVISIBLE] = true}
		return state
	end
end
