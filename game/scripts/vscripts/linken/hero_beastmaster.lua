--2021.09.09---by你收拾收拾准备出林肯吧
CreateTalents("npc_dota_hero_beastmaster", "linken/hero_beastmaster")
imba_beastmaster_wild_axes = class({})

--发射单个飞斧 两个斧子相撞时造成附近敌人攻击速度的比例伤害
LinkLuaModifier("modifier_imba_beastmaster_wild_axes_pfx", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_beastmaster_wild_axes_debuff", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)

--[[function imba_beastmaster_wild_axes:OnUpgrade()
	if self:GetLevel() == 1 then
		AbilityChargeController:AbilityChargeInitialize(self, self:GetCooldown(4 - 1), 2, 1, true, true)
	end
end]]
function imba_beastmaster_wild_axes:OnSpellStart(int,tar)
	self.caster = self:GetCaster()
	if int then
		self.caster = EntIndexToHScript(tar)
	end
	EmitSoundOn("Hero_Beastmaster.Wild_Axes", self.caster)
	local pos = self:GetCursorPosition()
	if TG_Distance(self.caster:GetAbsOrigin(),pos) < 450 then
		pos = self.caster:GetAbsOrigin() + self.caster:GetForwardVector() * 450
	end
	local dummy_end = CreateModifierThinker(
						self.caster, -- player source
						self, -- ability source
						"modifier_dummy_thinker", -- modifier name
						{
							duration = 20,
						}, -- kv
						pos,
						self.caster:GetTeamNumber(),
						false
					)
	--[[local dummy_pfx = CreateModifierThinker(
						self.caster, -- player source
						self, -- ability source
						"modifier_imba_beastmaster_wild_axes_pfx", -- modifier name
						{
							duration = 20,
							dummy_end = dummy_end:entindex()
						}, -- kv
						self.caster:GetAbsOrigin(),
						self.caster:GetTeamNumber(),
						false
					)]]
	local dummy_pfx = CreateUnitByName(
		"npc_linken_unit",
		self.caster:GetAbsOrigin(),
		false,
		self.caster,
		self.caster,
		self.caster:GetTeamNumber()
		)
	dummy_pfx:AddNewModifier(self.caster, self, "modifier_imba_beastmaster_wild_axes_pfx", {duration = 20,int = int})
	dummy_pfx:AddNewModifier(self.caster, self, "modifier_kill", {duration = 20})
	local info =
	{
		Target = dummy_end,
		Source = self.caster,
		EffectName = "",
		Ability = self,
		iMoveSpeed = self:GetSpecialValueFor("speed"),
		vSourceLoc = self.caster:GetAbsOrigin(),
		bDrawsOnMinimap = false,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
		bDodgeable = false,
		bIsAttack = false,
		bVisibleToEnemies = true,
		bReplaceExisting = false,
		flExpireTime = GameRules:GetGameTime() + 60,
		bProvidesVision = false,
		ExtraData = {dummy_pfx = dummy_pfx:entindex(),dummy_end = dummy_end:entindex(),go_come = 0 }
	}
	TG_CreateProjectile({id = 1, team = self.caster:GetTeamNumber(), owner = self.caster,	p = info})
end
function imba_beastmaster_wild_axes:OnProjectileThink_ExtraData(pos, keys)
	local caster = self:GetCaster()
	if keys.dummy_pfx then
		EntIndexToHScript(keys.dummy_pfx):SetOrigin(pos)
	end
end
function imba_beastmaster_wild_axes:OnProjectileHit_ExtraData(target, pos, keys)
	local caster = self:GetCaster()
	local dummy_pfx = EntIndexToHScript(keys.dummy_pfx)
	local dummy_end = EntIndexToHScript(keys.dummy_end)
	local go_come = keys.go_come
	if go_come == 0 then
		local modifier = dummy_pfx:FindModifierByName("modifier_imba_beastmaster_wild_axes_pfx")
		if modifier then
			modifier.caught_enemies = {}
			modifier.go_come = 1
		end
		local info =
		{
			Target = self.caster,
			Source = dummy_end,
			EffectName = "",
			Ability = self,
			iMoveSpeed = self:GetSpecialValueFor("speed"),
			vSourceLoc = dummy_end:GetAbsOrigin(),
			bDrawsOnMinimap = false,
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
			bDodgeable = false,
			bIsAttack = false,
			bVisibleToEnemies = true,
			bReplaceExisting = false,
			flExpireTime = GameRules:GetGameTime() + 60,
			bProvidesVision = false,
			ExtraData = {dummy_pfx = dummy_pfx:entindex(),dummy_end = dummy_end:entindex(),go_come = 1 }
		}
		--Timers:CreateTimer(1, function()
			TG_CreateProjectile({id = 1, team = caster:GetTeamNumber(), owner = caster,	p = info})
			--return nil
		--end)
	elseif go_come == 1 then
		dummy_pfx:Destroy()
		dummy_end:Destroy()
	end

end
modifier_imba_beastmaster_wild_axes_pfx = class({})

function modifier_imba_beastmaster_wild_axes_pfx:CheckState() return
	{
	[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
	[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	[MODIFIER_STATE_INVULNERABLE] = true,
	[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	[MODIFIER_STATE_OUT_OF_GAME] = true,
	[MODIFIER_STATE_UNSELECTABLE] = true,
	[MODIFIER_STATE_DISARMED] = true,
	[MODIFIER_STATE_COMMAND_RESTRICTED] = true
}
end
function modifier_imba_beastmaster_wild_axes_pfx:OnCreated(keys)
	if not self:GetAbility() then
		return
	end
	self.parent = self:GetParent()
	self.ability =self:GetAbility()
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
	self.axe_boom_rad = self.ability:GetSpecialValueFor("axe_boom_rad")
	self.axe_boom_dam = self.ability:GetSpecialValueFor("axe_boom_dam") * 0.01
	self.duration = self.ability:GetSpecialValueFor("duration")
	self.axe_damage = self.ability:GetSpecialValueFor("axe_damage")
	if IsServer() then
		self.int = keys.int
		self.caught_enemies = {}
		self.damageTable = {
		attacker = self:GetCaster(),
		damage = self.axe_damage,
		damage_type = self.ability:GetAbilityDamageType(),
		ability = self.ability,
		}
		self.go_come = 0
		self.duang = false
		self.caster = self:GetParent()
		local pfx_name = "particles/units/heroes/hero_beastmaster/beastmaster_wildaxe.vpcf"
		if self.int == 1 then
			pfx_name = "particles/econ/items/beastmaster/bm_crimson_2021/bm_crimson_2021.vpcf"
		end
		self.pfx = ParticleManager:CreateParticle(pfx_name, PATTACH_ABSORIGIN_FOLLOW, self.caster)
		ParticleManager:SetParticleControl(self.pfx, 0, self.caster:GetAbsOrigin())
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_imba_beastmaster_wild_axes_pfx:OnIntervalThink(keys)
	local enemies = FindUnitsInRadius(
		self.parent:GetTeamNumber(),
		self.parent:GetAbsOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		0,
		false
	)
	for _,enemy in pairs(enemies) do
		if not self.caught_enemies[enemy] then
			self.caught_enemies[enemy] = true
			self.damageTable.victim = enemy
			enemy:AddNewModifier(self:GetCaster(), self.ability, "modifier_imba_beastmaster_wild_axes_debuff", {duration = self.duration})
			ApplyDamage( self.damageTable )
		end
	end
	GridNav:DestroyTreesAroundPoint( self.parent:GetAbsOrigin(), 80, true )
	if self.ability:GetAutoCastState() then
		local flamebreak = Entities:FindAllInSphere(self:GetParent():GetAbsOrigin(), 100)
		for i=1, #flamebreak do
			if  string.find(flamebreak[i]:GetName(), "npc_") and flamebreak[i]:HasModifier("modifier_imba_beastmaster_wild_axes_pfx") and flamebreak[i] ~= self:GetParent() and not IsEnemy(flamebreak[i], self:GetParent())  then
				self.duang = true
				local modifier = flamebreak[i]:FindModifierByName("modifier_imba_beastmaster_wild_axes_pfx")
				if modifier then
					modifier.duang = true
					EmitSoundOn("Hero_Axe.CounterHelix_Blood_Chaser", self.parent)
				end
				break
			end
		end
	end
	if self.duang then
		local enemies = FindUnitsInRadius(
			self.parent:GetTeamNumber(),
			self.parent:GetAbsOrigin(),
			nil,
			self.axe_boom_rad,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			0,
			false
		)
		for _,enemy in pairs(enemies) do
			self.damageTable.victim = enemy
			self.damageTable.damage = enemy:GetDisplayAttackSpeed() * self.axe_boom_dam
			ApplyDamage( self.damageTable )
		end


		local dummy_pfx = ParticleManager:CreateParticle("particles/econ/items/axe/ti9_jungle_axe/ti9_jungle_axe_attack_blur_counterhelix.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(dummy_pfx, 0, self.parent:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(dummy_pfx)
		self:Destroy()
		self.parent:ForceKill(false)
	end
end
function modifier_imba_beastmaster_wild_axes_pfx:OnRemoved()
	if IsServer() then
		if self.pfx then
			ParticleManager:DestroyParticle(self.pfx, false)
			ParticleManager:ReleaseParticleIndex(self.pfx)
		end
		self.caught_enemies = {}
		self.go_come = 0
	end
end

modifier_imba_beastmaster_wild_axes_debuff = class({})
function modifier_imba_beastmaster_wild_axes_debuff:IsDebuff()			return true end
function modifier_imba_beastmaster_wild_axes_debuff:IsHidden() 			return false end
function modifier_imba_beastmaster_wild_axes_debuff:IsPurgable() 		return true end
function modifier_imba_beastmaster_wild_axes_debuff:IsPurgeException() 	return true end
function modifier_imba_beastmaster_wild_axes_debuff:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
			}
end
function modifier_imba_beastmaster_wild_axes_debuff:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.damage_amp = self.ability:GetSpecialValueFor("damage_amp")
	if IsServer() then
       	if self.pfx then
            ParticleManager:DestroyParticle(self.pfx, false)
            ParticleManager:ReleaseParticleIndex(self.pfx)
        end
		self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_wildaxe_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(self.pfx, 0, self.parent:GetAbsOrigin())
		self:AddParticle(self.pfx, false, false, 16, false, false)
	end
end
function modifier_imba_beastmaster_wild_axes_debuff:OnRefresh(keys)
	self:IncrementStackCount()
	self:OnCreated()
end
function modifier_imba_beastmaster_wild_axes_debuff:GetModifierIncomingDamage_Percentage(keys)
	--if keys.attacker == self.caster or keys.attacker:GetPlayerOwnerID() == self.caster:GetPlayerOwnerID() then
  		return self.damage_amp + self.damage_amp * self:GetStackCount()
  	--end
	--return nil
end
function modifier_imba_beastmaster_wild_axes_debuff:OnRemoved()
    if IsServer() then
        if self.pfx then
            ParticleManager:DestroyParticle(self.pfx, false)
            ParticleManager:ReleaseParticleIndex(self.pfx)
        end
    end
end
imba_beastmaster_call_of_the_wild = class({})

LinkLuaModifier("modifier_imba_call_of_the_wild_passive", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_call_of_the_wild_debuff", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
function imba_beastmaster_call_of_the_wild:GetIntrinsicModifierName() return "modifier_imba_call_of_the_wild_passive" end
function imba_beastmaster_call_of_the_wild:OnUpgrade()
	local ability = self:GetCaster():FindAbilityByName("imba_beastmaster_call_of_the_wild_hawk")
	if ability then
		ability:SetLevel(self:GetLevel())
	end
end
function imba_beastmaster_call_of_the_wild:OnSpellStart()
	self.caster = self:GetCaster()
	EmitSoundOn("Hero_Beastmaster.Call.Boar", self.caster)
	--[[if self.boar and #self.boar > 0 and not self.caster:TG_HasTalent("special_bonus_imba_beastmaster_8") then
		if #self.boar > 0 then
			for i=1, #self.boar do
				if self.boar[i] and EntIndexToHScript(self.boar[i]) and not EntIndexToHScript(self.boar[i]):IsNull() and EntIndexToHScript(self.boar[i]):IsAlive() then
					EntIndexToHScript(self.boar[i]):Kill(self, EntIndexToHScript(self.boar[i]))
					EntIndexToHScript(self.boar[i]):RemoveSelf()
				end
			end
		end
	end]]
	--self.boar = {}
	local beastmaster_boar = CreateUnitByName(
		"npc_imba_beastmaster_greater_boar",
		self.caster:GetAbsOrigin() + self.caster:GetForwardVector() * 200,
		true,
		self.caster,
		self.caster,
		self.caster:GetTeamNumber()
		)
	--table.insert(self.boar, beastmaster_boar:entindex())
	local duration = self:GetSpecialValueFor("duration")
	beastmaster_boar:AddNewModifier(self.caster, self, "modifier_imba_call_of_the_wild_passive", {duration = duration})
	beastmaster_boar:AddNewModifier(self.caster, self, "modifier_kill", {duration = duration})
	beastmaster_boar:SetControllableByPlayer(self.caster:GetPlayerOwnerID(), false)
	self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_loadout.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
	ParticleManager:SetParticleControl(self.pfx, 0, self.caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(self.pfx)
end

modifier_imba_call_of_the_wild_passive = class({})
function modifier_imba_call_of_the_wild_passive:IsDebuff()			return false end
function modifier_imba_call_of_the_wild_passive:IsHidden() 			return true end
function modifier_imba_call_of_the_wild_passive:IsPurgable() 		return false end
function modifier_imba_call_of_the_wild_passive:IsPurgeException() 	return false end
function modifier_imba_call_of_the_wild_passive:DeclareFunctions()
	return {
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			}
end
function modifier_imba_call_of_the_wild_passive:GetModifierAttackSpeedBonus_Constant()
	return self.as_bonus
end
function modifier_imba_call_of_the_wild_passive:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.as_bonus = 0
	self.boar_poison_duration = self.ability:GetSpecialValueFor("boar_poison_duration")
	self.sce_c = self.ability:GetSpecialValueFor("sce_c")
	self.boar_hp = 		self.ability:GetSpecialValueFor("boar_hp") * 0.01
	self.boar_damage = 	self.ability:GetSpecialValueFor("boar_damage") * 0.01
	if IsServer() then
		if not self.parent:IsHero() then
   			self.parent:Set_HP(self.caster:GetMaxHealth() * self.boar_hp,true)
    		self.parent:SetBaseDamageMax(self.caster:GetAttackDamage()*self.boar_damage)
    		self.parent:SetBaseDamageMin(self.caster:GetAttackDamage()*self.boar_damage)
			self.parent:SetPhysicalArmorBaseValue(self.caster:GetPhysicalArmorValue(false))
			if self.caster:TG_HasTalent("special_bonus_imba_beastmaster_4") then
				self.as_bonus = self.caster:GetDisplayAttackSpeed() * self.caster:TG_GetTalentValue("special_bonus_imba_beastmaster_4") * 0.01
			end
		end
		self.int = 1
	end
end
function modifier_imba_call_of_the_wild_passive:OnRefresh(keys)
	self:OnCreated()
end

function modifier_imba_call_of_the_wild_passive:OnAttackLanded(keys)
	if not IsServer() then
		return
	end
	if keys.attacker ~= self.parent or self.parent:PassivesDisabled() or not keys.target:IsAlive() or not keys.target:IsUnit() then
		return
	end
	keys.target:AddNewModifier(self.caster, self.ability, "modifier_imba_call_of_the_wild_debuff", {duration = self.boar_poison_duration})
	local ability = self.caster:FindAbilityByName("imba_beastmaster_wild_axes")
	if ability and ability:IsTrained() and  self.caster:HasScepter() and PseudoRandom:RollPseudoRandom(self.ability, self.sce_c) then
		self.caster:SetCursorPosition(keys.attacker:GetAbsOrigin() + TG_Direction(keys.target:GetAbsOrigin(),keys.attacker:GetAbsOrigin())*1500)
		ability:OnSpellStart(true,keys.attacker:entindex())
	end

end
modifier_imba_call_of_the_wild_debuff = class({})
function modifier_imba_call_of_the_wild_debuff:IsDebuff()			return true end
function modifier_imba_call_of_the_wild_debuff:IsHidden() 			return false end
function modifier_imba_call_of_the_wild_debuff:IsPurgable() 		return true end
function modifier_imba_call_of_the_wild_debuff:IsPurgeException() 	return true end
function modifier_imba_call_of_the_wild_debuff:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			}
end
function modifier_imba_call_of_the_wild_debuff:OnCreated(keys)
		self.parent 	= 	self:GetParent()
		self.caster 	= 	self:GetCaster()
		self.ability 	= 	self:GetAbility()
		self.boar_moveslow = self.ability:GetSpecialValueFor("boar_moveslow")
		self.att_sp_dam = self.ability:GetSpecialValueFor("att_sp_dam")	* 0.01
	if IsServer() then
		self:IncrementStackCount()
		self:OnIntervalThink()
		self:StartIntervalThink(1)
	end
end
function modifier_imba_call_of_the_wild_debuff:OnRefresh(keys)
	self:OnCreated()
end
function modifier_imba_call_of_the_wild_debuff:OnIntervalThink(keys)
	local damage = math.floor(self.att_sp_dam * self.parent:GetDisplayAttackSpeed()* self:GetStackCount())
	local damageTable = {
						victim = self.parent,
						attacker = self.caster,
						damage = damage,
						damage_type = self.ability:GetAbilityDamageType(),
						ability = self.ability,
						damage_flags = DOTA_DAMAGE_FLAG_NONE,
						}
	--print(damage)
	ApplyDamage(damageTable)
end
function modifier_imba_call_of_the_wild_debuff:GetModifierMoveSpeedBonus_Percentage()
	return (0 - self.boar_moveslow)
end

imba_beastmaster_call_of_the_wild_hawk = class({})

LinkLuaModifier("modifier_imba_beastmaster_call_of_the_wild_hawk_passive", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_call_of_the_wild_hawk_kill_move", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_call_of_the_wild_hawk_wild_hawk_move", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_call_of_the_wild_hawk_thinker", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
function imba_beastmaster_call_of_the_wild_hawk:CastFilterResultTarget( hTarget )
	if self:GetCaster() == hTarget then
		return UF_FAIL_CUSTOM
	end
end
function imba_beastmaster_call_of_the_wild_hawk:GetCustomCastErrorTarget( hTarget )
	if self:GetCaster() == hTarget then
		return "#dota_hud_error_cant_cast_on_self"
	end
end
function  imba_beastmaster_call_of_the_wild_hawk:GetAOERadius()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("hawk_vision_tooltip") + caster:TG_GetTalentValue("special_bonus_imba_beastmaster_2")
	return radius
end
function imba_beastmaster_call_of_the_wild_hawk:OnSpellStart()
	self.caster = self:GetCaster()
	EmitSoundOn("Hero_Beastmaster.Hawk.Reveal", self.caster)
	local pos = self.caster:GetCursorPosition()
	local target = self:GetCursorTarget()
	--[[if target == self.caster then
		self:ToggleAutoCast()
		self:EndCooldown()
		return
	end]]
	local target_ent = nil
	if target and target:IsAlive() then
		target_ent = target:entindex()
	end


	--[[if self.hawk and #self.hawk > 0 and not self.caster:TG_HasTalent("special_bonus_imba_beastmaster_8") then
		if #self.hawk > 0 then
			for i=1, #self.hawk do
				if self.hawk[i] and EntIndexToHScript(self.hawk[i]) and not EntIndexToHScript(self.hawk[i]):IsNull() and EntIndexToHScript(self.hawk[i]):IsAlive() then
					EntIndexToHScript(self.hawk[i]):Kill(self, EntIndexToHScript(self.hawk[i]))
					EntIndexToHScript(self.hawk[i]):RemoveSelf()
				end
			end
		end
	end]]
	--self.hawk = {}
	local beastmaster_boar_hawk = CreateUnitByName(
		"npc_imba_beastmaster_hawk",
		self.caster:GetAbsOrigin() + self.caster:GetForwardVector() * 200,
		true,
		self.caster,
		self.caster,
		self.caster:GetTeamNumber()
		)
	--table.insert(self.hawk,beastmaster_boar_hawk:entindex())

	local duration = self:GetSpecialValueFor("duration")
	beastmaster_boar_hawk:AddNewModifier(
		self.caster,
		self,
		"modifier_imba_beastmaster_call_of_the_wild_hawk_passive",
		{
			duration = duration ,
			pos = pos,
			target = target_ent,
		}
		)
	beastmaster_boar_hawk:AddNewModifier(self.caster, self, "modifier_kill", {duration = duration})
	beastmaster_boar_hawk:SetControllableByPlayer(self.caster:GetPlayerOwnerID(), false)
	--print(beastmaster_boar_hawk:IsSummoned())
	self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_call_bird.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
	ParticleManager:SetParticleControl(self.pfx, 0, self.caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(self.pfx)
	Timers:CreateTimer(0.1, function ()
		beastmaster_boar_hawk:MoveToPosition(pos)
		return nil
	end)
end

modifier_imba_beastmaster_call_of_the_wild_hawk_passive = class({})
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:IsDebuff()			return false end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:IsHidden() 			return true end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:IsPurgable() 		return false end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:IsPurgeException() 	return false end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_PROPERTY_DISABLE_HEALING,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
		MODIFIER_PROPERTY_DISABLE_AUTOATTACK,
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
	}
end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:GetModifierMoveSpeed_Absolute()
	return self:GetStackCount()
end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:GetDisableHealing() return 1 end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:GetAbsoluteNoDamageMagical() return 1 end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:GetAbsoluteNoDamagePure() return 1 end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:GetDisableAutoAttack() return true end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:GetModifierIgnoreMovespeedLimit() return 1 end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:CheckState()
return {
        [MODIFIER_STATE_INVISIBLE] = self.mc,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED]	= self.mc,
		[MODIFIER_STATE_MAGIC_IMMUNE]	= true,
		--[MODIFIER_STATE_OUT_OF_GAME]	= true,
        }
end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:GetModifierInvisibilityLevel()
	if not self.mc then
		return 1
	end
	return 0
end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.boar_hp = 	self.ability:GetSpecialValueFor("hawk_hp_tooltip") * 2
	self.vision = 	self.ability:GetSpecialValueFor("hawk_vision_tooltip") + self.caster:TG_GetTalentValue("special_bonus_imba_beastmaster_2")
	self.agh_hp = 	self.ability:GetSpecialValueFor("agh_hp") * 0.01
	self.agh_cd = 	self.ability:GetSpecialValueFor("agh_cd")
	if IsServer() then
		self.mov = 	self.ability:GetSpecialValueFor("mov")
		self:SetStackCount(self.mov)
		self.mc = true
		self.pos = StringToVector(keys.pos)
		self.parent:Set_HP(self.boar_hp,true)
		self.int = 0.1
		self.auto = false
		self:SetHasCustomTransmitterData(true)
		if keys.target  then
			self.target = EntIndexToHScript(keys.target)
			self.pos = self.target:GetAbsOrigin()
			if self.target:GetName() ~= "npc_dota_beastmaster_boar" then
				self.dummy = CreateModifierThinker(
									self.caster, -- player source
									self.ability, -- ability source
									"modifier_dummy_thinker", -- modifier name
									{
										duration = self:GetDuration(),
									}, -- kv
									self.pos+TG_Direction2(self.pos,self.parent:GetAbsOrigin()) * self.vision,
									self.caster:GetTeamNumber(),
									false
								)

				self:StartIntervalThink(self.int)
			else
				self:StartIntervalThink(self.int)
			end
		else
			self.dummy = CreateModifierThinker(
				self.caster, -- player source
				self.ability, -- ability source
				"modifier_dummy_thinker", -- modifier name
				{
					duration = self:GetDuration()+0.2,
				}, -- kv
				self.pos+TG_Direction2(self.pos,self.parent:GetAbsOrigin()) * self.vision,
				self.caster:GetTeamNumber(),
				false
				)
			self:StartIntervalThink(self.int)
		end
	end
end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:OnRefresh(keys)
	self:OnCreated()
end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:OnIntervalThink(keys)
	AddFOWViewer(self.caster:GetTeamNumber(), self.parent:GetAbsOrigin(), self.vision, self.int, false)
	--self.mc = true
	if self.mc and self.target and self.target:GetName() == "npc_dota_beastmaster_boar" and self.target:IsAlive() then
		self.mc = false
		self.mov = self.mov - 200
		self:SetStackCount(self.mov)
		--self:AddCustomTransmitterData()
		--self:StartIntervalThink(-1)
	end
	if not self.target or (self.target:GetName() ~= "npc_dota_beastmaster_boar" and self.target:IsAlive()) then
		if self.target and self.target:IsAlive() then
			self.pos = self.target:GetAbsOrigin()
		end
		if self.ability:GetAutoCastState() then
			local next_pos = RotatePosition(self.pos, QAngle(0,5,0), self.pos+TG_Direction2(self.dummy:GetAbsOrigin(),self.pos) * self.vision)
			self.dummy:SetOrigin(next_pos)
			self.parent:MoveToPosition(self.dummy:GetAbsOrigin())
			self.auto = true
		elseif not self.ability:GetAutoCastState() and self.auto then
			self.parent:Stop()
			self.auto = false
		end
		if self.caster:Has_Aghanims_Shard() and self.ability:GetAutoCastState() then
			local enemies = FindUnitsInRadius(
				self.parent:GetTeamNumber(),
				self.parent:GetAbsOrigin(),
				nil,
				self.vision,
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO,
				DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
				0,
				false
			)
			for _,enemy in pairs(enemies) do
				if enemy:GetHealth() / enemy:GetMaxHealth() <= self.agh_hp and not self.parent:HasModifier("modifier_imba_beastmaster_inner_beast_tooltip") then

					local dummy_pfx = CreateModifierThinker(
							self.caster,
							self.ability,
							"modifier_imba_call_of_the_wild_hawk_thinker",
							{
								duration = 10,
							},
							self.parent:GetAbsOrigin(),
							self.parent:GetTeamNumber(),
							false
							)
					dummy_pfx:AddNewModifier(
						self.caster,
						self.ability,
						"modifier_imba_call_of_the_wild_hawk_kill_move",
						{
							duration = 5,
							enemy = enemy:entindex(),
						})
					self.parent:AddNewModifier(
						self.caster,
						self.ability,
						"modifier_imba_beastmaster_inner_beast_tooltip",
						{
							duration = self.agh_cd,
						})

					--self:StartIntervalThink(-1)
					--self:Destroy()
					--self.dummy:Destroy()
					break
				end
			end
		end
	elseif self.target and self.target:GetName() == "npc_dota_beastmaster_boar" and self.target:IsAlive() then
		if TG_Distance(self.target:GetAbsOrigin(),self.parent:GetAbsOrigin()) >= 20 then
			self.parent:MoveToPosition(self.target:GetAbsOrigin())
		else
			self.target:AddNewModifier(
			self.parent,
			self.ability,
			"modifier_imba_call_of_the_wild_hawk_wild_hawk_move",
			{
				duration = -1 ,
			}
			)
			self:StartIntervalThink(-1)
			--self:Destroy()
		end
	end
end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:OnAttackLanded(keys)
	if not IsServer() or keys.target ~= self:GetParent() then
		return
	end
	local dmg = (keys.attacker:IsHero() or keys.attacker:IsTower()) and 2 or 1
	if self.enemy == 0 then
		dmg = self.parent:GetMaxHealth()
	end
	if dmg > self.parent:GetHealth() then
		self.parent:Kill(self:GetAbility(), keys.attacker)
		return
	end
	self.parent:SetHealth(self.parent:GetHealth() - dmg)
end
function modifier_imba_beastmaster_call_of_the_wild_hawk_passive:OnRemoved()
	if IsServer() then
		if self.dummy and not self.dummy:IsNull() and self.dummy:IsAlive() then
			self.dummy:Destroy()
		end
	end
end
modifier_imba_call_of_the_wild_hawk_wild_hawk_move = class({})
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:IsDebuff()			return true end
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:IsHidden() 			return false end
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:IsPurgable() 		return true end
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:IsPurgeException() 	return true end
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
		MODIFIER_EVENT_ON_ORDER,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT
	}
end
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:CheckState()
return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_ROOTED] = true,
        }
end
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:OnOrder(keys)
	if keys.unit == self:GetCaster() then
		if keys.order_type == DOTA_UNIT_ORDER_ATTACK_MOVE then
			self:GetParent():MoveToPositionAggressive(keys.new_pos)
		end
		if keys.order_type == DOTA_UNIT_ORDER_ATTACK_TARGET then
			self:GetParent():MoveToTargetToAttack(keys.target)
		end
	end
end
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:GetModifierMoveSpeed_Absolute() if IsServer() then return 1 end end
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:GetModifierMoveSpeed_Limit() if IsServer() then return 1 end end
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:OnCreated(keys)
		self.parent 	= 	self:GetParent()
		self.caster 	= 	self:GetCaster()
		self.ability 	= 	self:GetAbility()
	if IsServer() then
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:OnRefresh(keys)
	self:OnCreated()
end
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:OnIntervalThink(keys)
    if self.caster:IsAlive() and self.parent:IsAlive() and not self.parent:IsNull() and not self.caster:IsNull() then
        self.parent:SetOrigin(self.caster:GetOrigin()+Vector(0,0,150))
    end
    if not self.caster:IsAlive() or self.caster:IsNull() then
        self:Destroy()
    end
    if not self.parent:IsAlive() or self.parent:IsNull() then
        self:Destroy()
    end
end
function modifier_imba_call_of_the_wild_hawk_wild_hawk_move:OnRemoved()
	if IsServer() then
	end
end
modifier_imba_call_of_the_wild_hawk_thinker  = class({})
function modifier_imba_call_of_the_wild_hawk_thinker:CheckState() return
    {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end
function modifier_imba_call_of_the_wild_hawk_thinker:OnCreated(keys)
	if not self:GetAbility() then
		return
	end
	self.parent = self:GetParent()
	self.ability =self:GetAbility()
    self.caster = self:GetCaster()
	if IsServer() then
		local pfx_name = "particles/econ/items/beastmaster/bm_crimson_2021/bm_crimson_2021.vpcf"
		self.pfx = ParticleManager:CreateParticle(pfx_name, PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(self.pfx, 0, self.parent:GetAbsOrigin())
		--self:StartIntervalThink( self.delay_int )
	end
end
--function modifier_imba_call_of_the_wild_hawk_thinker:OnIntervalThink()

--end
function modifier_imba_call_of_the_wild_hawk_thinker:OnDestroy()
	if not IsServer() then return end
	if self.pfx then
		ParticleManager:DestroyParticle( self.pfx, false )
		ParticleManager:ReleaseParticleIndex( self.pfx )
	end
	self:GetParent():RemoveSelf()
end
modifier_imba_call_of_the_wild_hawk_kill_move = class({})
function modifier_imba_call_of_the_wild_hawk_kill_move:IsDebuff()			return true end
function modifier_imba_call_of_the_wild_hawk_kill_move:IsHidden() 			return false end
function modifier_imba_call_of_the_wild_hawk_kill_move:IsPurgable() 		return true end
function modifier_imba_call_of_the_wild_hawk_kill_move:IsPurgeException() 	return true end
function modifier_imba_call_of_the_wild_hawk_kill_move:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT
	}
end
function modifier_imba_call_of_the_wild_hawk_kill_move:CheckState()
return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVULNERABLE]	= true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED]	= true,
        }
end

function modifier_imba_call_of_the_wild_hawk_kill_move:GetModifierMoveSpeed_Absolute() if IsServer() then return 1 end end
function modifier_imba_call_of_the_wild_hawk_kill_move:GetModifierMoveSpeed_Limit() if IsServer() then return 1 end end
function modifier_imba_call_of_the_wild_hawk_kill_move:OnCreated(keys)
		self.parent 	= 	self:GetParent()
		self.caster 	= 	self:GetCaster()
		self.ability 	= 	self:GetAbility()
		self.agh_da = self.ability:GetSpecialValueFor("agh_da") * 0.01
		self.agh_st = self.ability:GetSpecialValueFor("agh_st")
	if IsServer() then

		self.enemy = EntIndexToHScript(keys.enemy)
		self.parent:Stop()
		--self.parent:StartGestureWithPlaybackRate(ACT_DOTA_CHANNEL_ABILITY_5,1.8)
		self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_shard_dive_blur.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(self.pfx, 0, self.parent:GetAbsOrigin())
		--ParticleManager:SetParticleControl(self.pfx, 2, self.parent:GetAbsOrigin())
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_imba_call_of_the_wild_hawk_kill_move:OnRefresh(keys)
	self:OnCreated()
end
function modifier_imba_call_of_the_wild_hawk_kill_move:OnIntervalThink(keys)
	--[[if not self.enemy:IsAlive() then
		self:Destroy()
		self:StartIntervalThink(-1)
		return
	end]]
	if 	self.enemy and self.enemy:IsAlive() then
		local speed = 1200 / (1 / FrameTime())

		local direction = TG_Direction2(self.enemy:GetAbsOrigin(),self.parent:GetAbsOrigin())
		local next_pos = GetGroundPosition(self.parent:GetAbsOrigin() + direction * speed,nil)
		self.parent:SetForwardVector(direction)
		self.parent:SetOrigin(next_pos)
	elseif not self.enemy or not self.enemy:IsAlive() then
		self:Destroy()
		self:StartIntervalThink(-1)
		return
	end
	if TG_Distance(self.enemy:GetAbsOrigin(),self.parent:GetAbsOrigin()) <= 20 then
		self.parent:FadeGesture(ACT_DOTA_CHANNEL_ABILITY_5)
		self:Destroy()
		self:StartIntervalThink(-1)
		return
	end
end
function modifier_imba_call_of_the_wild_hawk_kill_move:OnRemoved()
	if IsServer() then
		if self.pfx then
			ParticleManager:DestroyParticle(self.pfx, false)
			ParticleManager:ReleaseParticleIndex(self.pfx)
		end
		if self.enemy and self.enemy:IsAlive() then
			local damageTable = {
			attacker = self.caster,
			victim = self.enemy,
			damage = self.enemy:GetMaxHealth() * self.agh_da,
			ability = self.ability,
			damage_type = DAMAGE_TYPE_PURE
			}
			ApplyDamage(damageTable)
			self.enemy:AddNewModifier(
				self.caster,
				self.ability,
				"modifier_stunned",
				{
					duration = self.agh_st ,
				}
				)
		end
		if self.parent then
			--self.parent:Kill(self.ability, self.parent)
			self.parent:Destroy()
		end
		EmitSoundOn("Hero_Beastmaster.Hawk.Target", self.parent)
	end
end
--兽王光环 增加友军攻击速度 降低敌人攻击速度 主动使用持续xx秒  所承受伤害由范围内中立单位同时承受，同时中立单位攻击速度攻击力移动速度提升至极限，友军免疫中立单位伤害。
imba_beastmaster_inner_beast = class({})

LinkLuaModifier("modifier_imba_beastmaster_inner_beast_passive", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_beastmaster_inner_beast_buff", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_beastmaster_inner_beast_tooltip", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_beastmaster_inner_beast_pfx", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
function imba_beastmaster_inner_beast:GetCastRange() return self:GetSpecialValueFor("radius") end
function imba_beastmaster_inner_beast:GetIntrinsicModifierName() return "modifier_imba_beastmaster_inner_beast_passive" end
--[[function imba_beastmaster_inner_beast:OnAbilityPhaseStart()
    if IsServer() then
		self:GetCaster():AddActivityModifier("drum_beat")
    end
    return true
end
function imba_beastmaster_inner_beast:GetPlaybackRateOverride()
    return 1
end
function imba_beastmaster_inner_beast:GetCastPoint()
    return 2
end
function imba_beastmaster_inner_beast:GetCastAnimation()
    return ACT_DOTA_TAUNT
end]]
function imba_beastmaster_inner_beast:GetCooldown(level)
	local cooldown = self.BaseClass.GetCooldown(self, level)
	local caster = self:GetCaster()
	if caster:TG_HasTalent("special_bonus_imba_beastmaster_6") then
		return (cooldown - caster:TG_GetTalentValue("special_bonus_imba_beastmaster_6"))
	end
	return cooldown
end
function imba_beastmaster_inner_beast:OnSpellStart()
	local caster = self:GetCaster()
	EmitSoundOn("Hero_Beastmaster.Primal_Roar.ti7_layer", caster)
	EmitSoundOn("Greevil.Bloodlust.Target", caster)
	caster:ClearActivityModifiers()
	--[[caster:RemoveModifierByName("modifier_imba_beastmaster_inner_beast_passive")
	caster:AddNewModifier(
		caster,
		self,
		"modifier_imba_beastmaster_inner_beast_passive",
		{
			duration = -1 ,
		}
		)]]
	local duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(
		caster,
		self,
		"modifier_imba_beastmaster_inner_beast_tooltip",
		{
			duration = duration ,
		}
		)
	self.pfx = ParticleManager:CreateParticle("particles/econ/items/beastmaster/bm_shoulder_ti7/bm_shoulder_ti7_roar.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
	ParticleManager:SetParticleControl(self.pfx, 1, caster:GetAbsOrigin()+caster:GetForwardVector()*300)
	--ParticleManager:SetParticleControlOrientation(self.pfx, 0, caster:GetForwardVector(), caster:GetRightVector(), caster:GetUpVector())
	--ParticleManager:SetParticleControl(self.pfx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControlEnt(self.pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(self.pfx)
end
function imba_beastmaster_inner_beast:Hasmodif()
	return self:GetCaster():HasModifier("modifier_imba_beastmaster_inner_beast_tooltip")
end
modifier_imba_beastmaster_inner_beast_passive = class({})
function modifier_imba_beastmaster_inner_beast_passive:IsDebuff()			return false end
function modifier_imba_beastmaster_inner_beast_passive:IsHidden() 			return true end
function modifier_imba_beastmaster_inner_beast_passive:IsPurgable() 		return false end
function modifier_imba_beastmaster_inner_beast_passive:IsPurgeException() 	return false end
function modifier_imba_beastmaster_inner_beast_passive:IsAura()				return true end
function modifier_imba_beastmaster_inner_beast_passive:GetAuraDuration() 	return 0.1 end
function modifier_imba_beastmaster_inner_beast_passive:GetModifierAura() 	return "modifier_imba_beastmaster_inner_beast_buff" end
function modifier_imba_beastmaster_inner_beast_passive:IsAuraActiveOnDeath() return false end
function modifier_imba_beastmaster_inner_beast_passive:GetAuraRadius() 		return self.radius end
function modifier_imba_beastmaster_inner_beast_passive:GetAuraSearchFlags() 	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES end
function modifier_imba_beastmaster_inner_beast_passive:GetAuraSearchTeam() 	return DOTA_UNIT_TARGET_TEAM_BOTH end
function modifier_imba_beastmaster_inner_beast_passive:GetAuraSearchType() 	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_imba_beastmaster_inner_beast_passive:GetAuraEntityReject(hTarget)
	if not self:GetParent():IsAlive() or not self:GetAbility():IsTrained() or self:GetParent():PassivesDisabled() or self:GetParent():IsIllusion() or not hTarget or hTarget:IsBoss() then
	    return true
    else
		return false
	end
end
function modifier_imba_beastmaster_inner_beast_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end
function modifier_imba_beastmaster_inner_beast_passive:GetModifierIncomingDamage_Percentage(keys)
	if keys.attacker:IsAlive() then
		if ((self.nu ~= 0 and self:GetAbility():Hasmodif()) or keys.attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS or keys.attacker:IsSummoned()) and not keys.attacker:IsBoss() then
			return -100
		end
	end
end
function modifier_imba_beastmaster_inner_beast_passive:OnCreated(keys)
	self.parent 	= 	self:GetParent()
	self.caster 	= 	self:GetCaster()
	self.ability 	= 	self:GetAbility()
	self.radius = self.ability:GetSpecialValueFor("radius")
	if IsServer() then
		self.nu = 0
		self:StartIntervalThink(0.1)
	end
end
function modifier_imba_beastmaster_inner_beast_passive:OnIntervalThink(keys)
	self.nu = 0
	local enemies = FindUnitsInRadius(
		self:GetParent():GetTeamNumber(),
		self:GetParent():GetAbsOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		0,
		false
	)
	for _,enemy in pairs(enemies) do
		if (enemy:GetTeamNumber() == DOTA_TEAM_NEUTRALS or (enemy:IsSummoned() and enemy:GetPlayerOwnerID() == self.caster:GetPlayerOwnerID()) ) and not enemy:IsBoss() then
			if enemy:GetName() ~= "npc_dota_beastmaster_hawk" then
				--print(enemy:GetName())
				self.nu = self.nu + 1
			end
		end
	end
	--print(self.nu)
end
function modifier_imba_beastmaster_inner_beast_passive:OnTakeDamage(keys)
	if not IsServer() then
		return
	end
	if keys.unit ~= self:GetParent() then
		return
	end
	if not self:GetAbility():Hasmodif() then
		return
	end
	if keys.attacker:IsHero() and not keys.attacker:IsIllusion() then
		self.attacker = keys.attacker
	end
	if keys.attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS then return end
	if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then	return end
	local enemies = FindUnitsInRadius(
		self:GetParent():GetTeamNumber(),
		self:GetParent():GetAbsOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		0,
		false
	)
	for _,enemy in pairs(enemies) do
		if (enemy:GetTeamNumber() == DOTA_TEAM_NEUTRALS or (enemy:IsSummoned() and enemy:GetPlayerOwnerID() == self.caster:GetPlayerOwnerID()) ) and not enemy:IsBoss() and self.nu > 0 then
			local damageTable = {
								victim = enemy,
								attacker = self.attacker,
								damage = keys.original_damage/self.nu,
								damage_type = keys.damage_type,
								ability = self:GetAbility(),
								damage_flags = DOTA_DAMAGE_FLAG_NONE,
								}
			ApplyDamage(damageTable)
			if keys.original_damage/self.nu > 50 then
				self.pfx = ParticleManager:CreateParticle("particles/econ/items/undying/fall20_undying_head/fall20_undying_soul_rip_damage.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
				ParticleManager:SetParticleControl(self.pfx, 1, enemy:GetAbsOrigin())
				ParticleManager:SetParticleControl(self.pfx, 0, self:GetCaster():GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(self.pfx)
			end
		end
	end

end
modifier_imba_beastmaster_inner_beast_buff = class({})
function modifier_imba_beastmaster_inner_beast_buff:IsDebuff()			return (IsEnemy(self:GetParent(),self:GetCaster()) and not self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS) or (IsEnemy(self:GetParent(),self:GetCaster()) and self:GetParent():GetTeamNumber() ~= DOTA_TEAM_NEUTRALS) end
function modifier_imba_beastmaster_inner_beast_buff:IsHidden() 			return self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and not self:GetAbility():Hasmodif() end
function modifier_imba_beastmaster_inner_beast_buff:IsPurgable() 		return false end
function modifier_imba_beastmaster_inner_beast_buff:IsPurgeException() 	return false end
function modifier_imba_beastmaster_inner_beast_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,

	}
end
function modifier_imba_beastmaster_inner_beast_buff:OnCreated(keys)
		self.parent 	= 	self:GetParent()
		self.caster 	= 	self:GetCaster()
		self.ability 	= 	self:GetAbility()
		self.as_bonus = self.ability:GetSpecialValueFor("bonus_attack_speed")
		self.inner_beast = self.ability:GetSpecialValueFor("inner_beast")
		self.mk_beast = self.ability:GetSpecialValueFor("mk_beast")
	if IsServer() then
		if self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and self:GetAbility():Hasmodif() then
			self:StartIntervalThink(0.2)
		end
	end
end
function modifier_imba_beastmaster_inner_beast_buff:OnIntervalThink(keys)
	if self.parent:GetTeamNumber() == DOTA_TEAM_NEUTRALS and self:GetAbility():Hasmodif() and not self.parent:HasModifier("modifier_imba_beastmaster_inner_beast_pfx") then
		self.parent:AddNewModifier(
			self.caster,
			self.ability,
			"modifier_imba_beastmaster_inner_beast_pfx",
			{
				duration = 3 ,
			}
			)
	elseif self.parent:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not self:GetAbility():Hasmodif() and self.parent:HasModifier("modifier_imba_beastmaster_inner_beast_pfx") then
		self.parent:RemoveModifierByName("modifier_imba_beastmaster_inner_beast_pfx")
	end
end
function modifier_imba_beastmaster_inner_beast_buff:OnAttackLanded(keys)
	if not IsServer() then
		return
	end
	if keys.attacker ~= self.parent then
		return
	end
	if self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and self:GetAbility():Hasmodif() and keys.target:IsAlive() and keys.target:IsUnit() and IsEnemy(keys.target,self:GetCaster()) then
		local dmg = ApplyDamage({victim = keys.target, attacker = self:GetCaster(), damage = keys.target:GetMaxHealth()*0.1, damage_type = self:GetAbility():GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, keys.target, dmg, nil)
	end
end
function modifier_imba_beastmaster_inner_beast_buff:GetModifierAttackSpeedBonus_Constant()
	if self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and self:GetAbility():Hasmodif() then
		return self.as_bonus * self.inner_beast
	elseif IsEnemy(self:GetParent(),self:GetCaster()) then
		return -self.as_bonus
	elseif self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and not self:GetAbility():Hasmodif() then
		return nil
	end
	return self.as_bonus
end
function modifier_imba_beastmaster_inner_beast_buff:GetModifierPhysicalArmorBonus()
	if self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and self:GetAbility():Hasmodif() then
		return self.caster:GetPhysicalArmorValue(false)
	elseif self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and not self:GetAbility():Hasmodif() then
		return nil
	end
	return nil
end
function modifier_imba_beastmaster_inner_beast_buff:GetModifierMagicalResistanceBonus()
	if self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and self:GetAbility():Hasmodif() then
		return self.mk_beast
	elseif self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and not self:GetAbility():Hasmodif() then
		return nil
	end
	return nil
end
function modifier_imba_beastmaster_inner_beast_buff:GetModifierIgnoreMovespeedLimit()
	if self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and self:GetAbility():Hasmodif() then
		return 1
	elseif self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and not self:GetAbility():Hasmodif() then
		return nil
	end
	return nil
end
function modifier_imba_beastmaster_inner_beast_buff:GetModifierMoveSpeedBonus_Percentage()
	if self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and self:GetAbility():Hasmodif() then
		return self.as_bonus * self.inner_beast
	elseif self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and not self:GetAbility():Hasmodif() then
		return nil
	end
	return nil
end
function modifier_imba_beastmaster_inner_beast_buff:GetModifierIncomingDamage_Percentage(keys)
	if keys.attacker:IsAlive() then
		if not IsEnemy(self:GetParent(),self:GetCaster()) and (keys.attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not keys.attacker:IsBoss()) and self:GetAbility():Hasmodif() then
			return -100
		elseif not IsEnemy(self:GetParent(),self:GetCaster()) and (keys.attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not keys.attacker:IsBoss()) and not self:GetAbility():Hasmodif() then
			return nil
		elseif IsEnemy(keys.attacker,self:GetCaster()) and  (self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and not self:GetParent():IsBoss())then
			--print(self.parent:GetName())
			return -50
		end
	end
end
function modifier_imba_beastmaster_inner_beast_buff:CheckState()
	return
		{
        [MODIFIER_STATE_NO_UNIT_COLLISION] = self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and self:GetAbility():Hasmodif() or nil,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS and self:GetAbility():Hasmodif() or nil ,
        }
end

function modifier_imba_beastmaster_inner_beast_buff:OnRemoved()
	if IsServer() then
	end
end
modifier_imba_beastmaster_inner_beast_pfx = class({})
function modifier_imba_beastmaster_inner_beast_pfx:IsDebuff()			return false end
function modifier_imba_beastmaster_inner_beast_pfx:IsHidden() 			return false end
function modifier_imba_beastmaster_inner_beast_pfx:IsPurgable() 		return false end
function modifier_imba_beastmaster_inner_beast_pfx:IsPurgeException() 	return false end
function modifier_imba_beastmaster_inner_beast_pfx:GetStatusEffectName()
  return "particles/units/heroes/hero_troll_warlord/troll_warlord_rampage_resistance_buff.vpcf"
end
modifier_imba_beastmaster_inner_beast_tooltip = class({})
function modifier_imba_beastmaster_inner_beast_tooltip:IsDebuff()			return false end
function modifier_imba_beastmaster_inner_beast_tooltip:IsHidden() 			return false end
function modifier_imba_beastmaster_inner_beast_tooltip:IsPurgable() 		return false end
function modifier_imba_beastmaster_inner_beast_tooltip:IsPurgeException() 	return false end
function modifier_imba_beastmaster_inner_beast_tooltip:OnCreated(keys)
		self.parent 	= 	self:GetParent()
		self.caster 	= 	self:GetCaster()
		self.ability 	= 	self:GetAbility()
	if IsServer() and self.parent == self.caster then
		local ability = self.caster:FindAbilityByName("imba_beastmaster_wild_axes")
		if ability and ability:IsTrained() and self.caster:TG_HasTalent("special_bonus_imba_beastmaster_8") then
			ability:SetCurrentAbilityCharges(999)
		end
		local neu_nu 			= self.caster:TG_GetTalentValue("special_bonus_imba_beastmaster_1")
		local neu				= {
								"npc_dota_neutral_wildkin",
								"npc_dota_neutral_enraged_wildkin",
								"npc_dota_neutral_satyr_soulstealer",
								"npc_dota_neutral_satyr_hellcaller",
								"npc_dota_neutral_jungle_stalker",
								"npc_dota_neutral_elder_jungle_stalker",
								"npc_dota_neutral_prowler_shaman",
								"npc_dota_neutral_rock_golem",

									}
		local target = self.caster
		if self.caster:TG_HasTalent("special_bonus_imba_beastmaster_1") then
			for i=1, neu_nu do
				CreateUnitByName(
					neu[RandomInt(1, #neu)],
					RotatePosition(target:GetAbsOrigin(), QAngle(0,30*i,0), target:GetAbsOrigin() + target:GetForwardVector() * 600),
					true,
					nil,
					nil,
					DOTA_TEAM_NEUTRALS
					)
			end
		end
	end
end
function modifier_imba_beastmaster_inner_beast_tooltip:OnRefresh(keys)
	self:OnCreated()
end
function modifier_imba_beastmaster_inner_beast_tooltip:OnRemoved(keys)
	if IsServer() then
		local ability = self.caster:FindAbilityByName("imba_beastmaster_wild_axes")
		if ability and ability:IsTrained() and self.caster:TG_HasTalent("special_bonus_imba_beastmaster_8") then
			ability:SetCurrentAbilityCharges(0)
			ability:StartCooldown((ability:GetCooldown(ability:GetLevel() -1 ) * self.caster:GetCooldownReduction()))
		end
	end
end
--原始咆哮
imba_beastmaster_primal_roar = class({})

LinkLuaModifier("modifier_imba_beastmaster_primal_roar_move", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_beastmaster_primal_roar_move_come", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_beastmaster_primal_roar_debuff", "linken/hero_beastmaster", LUA_MODIFIER_MOTION_NONE)
--function imba_beastmaster_primal_roar:GetIntrinsicModifierName() return "modifier_imba_call_of_the_wild_passive" end
function imba_beastmaster_primal_roar:GetCastRange(pos, target)
	if not self.range_porcupine then
		self.range_porcupine = 0
	end
	if IsClient() then
		return self.BaseClass.GetCastRange(self, pos, target)
	else
		return self.BaseClass.GetCastRange(self, pos, target) + self.range_porcupine
	end
end
function imba_beastmaster_primal_roar:GetCooldown(level)
	local cooldown = self.BaseClass.GetCooldown(self, level)
	local caster = self:GetCaster()
	if caster:TG_HasTalent("special_bonus_imba_beastmaster_5") then
		return (cooldown - caster:TG_GetTalentValue("special_bonus_imba_beastmaster_5"))
	end
	return cooldown
end
function imba_beastmaster_primal_roar:OnSpellStart()
	local caster		 	= self:GetCaster()
	local target 			= self:GetCursorTarget()
	if target:TG_TriggerSpellAbsorb(self) then
		return
	end	
	local stun_duration 	= self:GetSpecialValueFor("duration")
	local search_range 		= self:GetSpecialValueFor("search_range")
	local search_angle 		= self:GetSpecialValueFor("search_angle")
	local hawk			 	= nil
	self.beastmaster_boar = nil
	local ability 	=	caster:FindAbilityByName("imba_beastmaster_inner_beast")
	if ability and caster:TG_HasTalent("special_bonus_imba_beastmaster_3") then
		local duration 	=	caster:TG_GetTalentValue("special_bonus_imba_beastmaster_3")
		caster:AddNewModifier(
			caster,
			ability,
			"modifier_imba_beastmaster_inner_beast_tooltip",
			{
				duration = duration ,
			}
			)
	end
	local damageTable = {
						victim = target,
						attacker = self:GetCaster(),
						damage = self:GetSpecialValueFor("damage") ,
						damage_type = self:GetAbilityDamageType(),
						ability = self,
						damage_flags = DOTA_DAMAGE_FLAG_NONE,
						}
	ApplyDamage(damageTable)

	if self.range_porcupine > 0 then
		local ability = caster:FindAbilityByName("imba_beastmaster_call_of_the_wild")
		if ability.beastmaster_boar and ability.beastmaster_boar:IsAlive() then
			if TG_Distance(target:GetAbsOrigin(),ability.beastmaster_boar:GetAbsOrigin()) <= search_range then
				self.beastmaster_boar = ability.beastmaster_boar
				caster	= self.beastmaster_boar
			end
		end
	end
	EmitSoundOn("Hero_Beastmaster.Primal_Roar", caster)
	self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_primal_roar.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(self.pfx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControlEnt(self.pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.pfx, 1, target:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(self.pfx)

	--[[self.pfx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_primal_target.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(self.pfx1, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(self.pfx1, 1, target:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(self.pfx1)]]

	target:AddNewModifier_RS(caster, self, "modifier_stunned", {duration = stun_duration})
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		target:GetAbsOrigin(),
		nil,
		search_range,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		0,
		false
	)


	for _,enemy in pairs(enemies) do
		local st_direction 	= VectorToAngles(caster:GetAbsOrigin()-target:GetAbsOrigin()).y
		local end_direction = VectorToAngles(target:GetAbsOrigin()-enemy:GetAbsOrigin()).y
		local suc 			= math.abs( AngleDiff(st_direction,end_direction)) < search_angle
		if enemy:GetName() == "npc_dota_beastmaster_hawk" and enemy:GetPlayerOwnerID() == caster:GetPlayerOwnerID() and (suc or caster:TG_HasTalent("special_bonus_imba_beastmaster_7")) then
			hawk = enemy
			hawk:AddNewModifier(
				caster,
				self,
				"modifier_imba_beastmaster_primal_roar_move",
				{
					duration = 3,
					target = target:entindex()
				}
			)
		elseif enemy:GetTeamNumber() == DOTA_TEAM_NEUTRALS and enemy ~= target and not enemy:IsBoss() then
			enemy:AddNewModifier(
				caster,
				self,
				"modifier_imba_beastmaster_primal_roar_move",
				{
					duration = 3,
					target = target:entindex()
				}
			)
		end
	end

end
modifier_imba_beastmaster_primal_roar_move = class({})
function modifier_imba_beastmaster_primal_roar_move:IsDebuff()			return true end
function modifier_imba_beastmaster_primal_roar_move:IsHidden() 			return false end
function modifier_imba_beastmaster_primal_roar_move:IsPurgable() 		return false end
function modifier_imba_beastmaster_primal_roar_move:IsPurgeException() 	return false end
function modifier_imba_beastmaster_primal_roar_move:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT
	}
end
function modifier_imba_beastmaster_primal_roar_move:CheckState()
return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVULNERABLE]	= true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED]	= true,
        }
end
function modifier_imba_beastmaster_primal_roar_move:GetModifierMoveSpeed_Absolute() if IsServer() then return 1 end end
function modifier_imba_beastmaster_primal_roar_move:GetModifierMoveSpeed_Limit() if IsServer() then return 1 end end
function modifier_imba_beastmaster_primal_roar_move:OnCreated(keys)
		self.parent 	= 	self:GetParent()
		self.caster 	= 	self:GetCaster()
		self.ability 	= 	self:GetAbility()
	if IsServer() then
		self.enemy = EntIndexToHScript(keys.target)
		self.pos = self.caster:GetAbsOrigin()
		self.parent:Stop()
		self.parent:StartGestureWithPlaybackRate(ACT_DOTA_CHANNEL_ABILITY_5,1.8)
		self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_shard_dive_blur.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(self.pfx, 0, self.parent:GetAbsOrigin())
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_imba_beastmaster_primal_roar_move:OnRefresh(keys)
	self:OnCreated()
end
function modifier_imba_beastmaster_primal_roar_move:OnIntervalThink(keys)
	if 	self.enemy and self.enemy:IsAlive() then
		local speed = 1200 / (1 / FrameTime())

		local direction = TG_Direction2(self.enemy:GetAbsOrigin(),self.parent:GetAbsOrigin())
		local next_pos = GetGroundPosition(self.parent:GetAbsOrigin() + direction * speed,nil)
		self.parent:SetForwardVector(direction)
		self.parent:SetOrigin(next_pos)
	elseif not self.enemy or not self.enemy:IsAlive() then
		self:Destroy()
	end
	if TG_Distance(self.enemy:GetAbsOrigin(),self.parent:GetAbsOrigin()) <= 20 then
		self.parent:FadeGesture(ACT_DOTA_CHANNEL_ABILITY_5)
		self:Destroy()
	end
end
function modifier_imba_beastmaster_primal_roar_move:OnRemoved()
	if IsServer() then
		if self.pfx then
			ParticleManager:DestroyParticle(self.pfx, false)
			ParticleManager:ReleaseParticleIndex(self.pfx)
		end
		EmitSoundOn("Hero_Beastmaster.Hawk.Target", self.parent)
		if self.parent:IsAlive() and self.parent:GetName() == "npc_dota_beastmaster_hawk" and self.parent:GetPlayerOwnerID() == self.caster:GetPlayerOwnerID()then
			self.parent:Kill(self.ability, self.parent)
		end
		if self.parent:IsAlive() and self.enemy:IsAlive() then
			self.parent:SetForceAttackTarget(self.enemy)
		end
		if 	self.enemy and self.enemy:IsAlive() and self.parent:GetName() == "npc_dota_beastmaster_hawk" and self.parent:GetPlayerOwnerID() == self.caster:GetPlayerOwnerID() then
			self.enemy:AddNewModifier(
				self.caster,
				self.ability,
				"modifier_imba_beastmaster_primal_roar_move_come",
				{
					duration = 3,
					pos = self.pos
				}
			)
		end
	end
end
modifier_imba_beastmaster_primal_roar_move_come = class({})
function modifier_imba_beastmaster_primal_roar_move_come:IsDebuff()			return true end
function modifier_imba_beastmaster_primal_roar_move_come:IsHidden() 			return false end
function modifier_imba_beastmaster_primal_roar_move_come:IsPurgable() 		return false end
function modifier_imba_beastmaster_primal_roar_move_come:IsPurgeException() 	return false end
function modifier_imba_beastmaster_primal_roar_move_come:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT
	}
end
function modifier_imba_beastmaster_primal_roar_move_come:CheckState()
return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVULNERABLE]	= true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED]	= true,
        }
end
function modifier_imba_beastmaster_primal_roar_move_come:GetModifierMoveSpeed_Absolute() if IsServer() then return 1 end end
function modifier_imba_beastmaster_primal_roar_move_come:GetModifierMoveSpeed_Limit() if IsServer() then return 1 end end
function modifier_imba_beastmaster_primal_roar_move_come:OnCreated(keys)
		self.parent 	= 	self:GetParent()
		self.caster 	= 	self:GetCaster()
		self.ability 	= 	self:GetAbility()
	if IsServer() then
		self.enemy = self.parent
		self.st_pos = self.enemy:GetAbsOrigin()
		self.pos = StringToVector(keys.pos)
		self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_shard_dive_blur.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(self.pfx, 0, self.parent:GetAbsOrigin())
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_imba_beastmaster_primal_roar_move_come:OnRefresh(keys)
	self:OnCreated()
end
function modifier_imba_beastmaster_primal_roar_move_come:OnIntervalThink(keys)
	if 	self.enemy and self.enemy:IsAlive() then
		local speed = 1200 / (1 / FrameTime())

		local direction = TG_Direction2(self.pos,self.parent:GetAbsOrigin())
		local next_pos = GetGroundPosition(self.parent:GetAbsOrigin() + direction * speed,nil)
		self.parent:SetForwardVector(direction)
		self.parent:SetOrigin(next_pos)
	elseif not self.enemy or not self.enemy:IsAlive() then
		self:Destroy()
	end
	if TG_Distance(self.pos,self.parent:GetAbsOrigin()) <= 20 then
		self:Destroy()
	end
	if TG_Distance(self.st_pos,self.parent:GetAbsOrigin()) > 1000 then
		self:Destroy()
	end
end
function modifier_imba_beastmaster_primal_roar_move_come:OnRemoved()
	if IsServer() then
		if self.pfx then
			ParticleManager:DestroyParticle(self.pfx, false)
			ParticleManager:ReleaseParticleIndex(self.pfx)
		end
		EmitSoundOn("Hero_Beastmaster.Hawk.Target", self.parent)
		GridNav:DestroyTreesAroundPoint( self.parent:GetAbsOrigin(), 400, true )
	end
end
-- imba_beastmaster_wild_axes_sce = class({})

-- function imba_beastmaster_wild_axes_sce:OnSpellStart()
-- 	self.caster = self:GetCaster()
-- 	EmitSoundOn("Hero_Beastmaster.Wild_Axes", self.caster)
-- 	local pos = self:GetCursorPosition()


--     local ran_pos_st = pos + self:GetCaster():GetForwardVector() * 1000
--     for i=1 , 6 do
--         Timers:CreateTimer(0.1*i, function ()
--             local ran_pos_en = RotatePosition(pos, QAngle(0,60*i,0), ran_pos_st)
-- 			local dummy_end = CreateModifierThinker(
-- 								self.caster, -- player source
-- 								self, -- ability source
-- 								"modifier_dummy_thinker", -- modifier name
-- 								{
-- 									duration = 20,
-- 								}, -- kv
-- 								pos,
-- 								self.caster:GetTeamNumber(),
-- 								false
-- 							)
-- 			local dummy_come = CreateModifierThinker(
-- 								self.caster, -- player source
-- 								self, -- ability source
-- 								"modifier_dummy_thinker", -- modifier name
-- 								{
-- 									duration = 20,
-- 								}, -- kv
-- 								ran_pos_en,
-- 								self.caster:GetTeamNumber(),
-- 								false
-- 							)
-- 			local dummy_pfx = CreateUnitByName(
-- 				"npc_linken_unit",
-- 				ran_pos_en,
-- 				false,
-- 				self.caster,
-- 				self.caster,
-- 				self.caster:GetTeamNumber()
-- 				)
-- 			dummy_pfx:AddNewModifier(self.caster, self, "modifier_imba_beastmaster_wild_axes_pfx", {duration = 20})
-- 			dummy_pfx:AddNewModifier(self.caster, self, "modifier_kill", {duration = 20})
--             local info =
--             {
--                 Target = dummy_end,
--                 Source = dummy_pfx,
--                 EffectName = "",
--                 Ability = self,
--                 iMoveSpeed = 1500,
--                 vSourceLoc = ran_pos_en,
--                 bDrawsOnMinimap = false,
--                 iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
--                 bDodgeable = false,
--                 bIsAttack = false,
--                 bVisibleToEnemies = true,
--                 bReplaceExisting = false,
--                 flExpireTime = GameRules:GetGameTime() + 60,
--                 bProvidesVision = false,

--                 ExtraData = {
-- 					dummy_pfx = dummy_pfx:entindex(),
-- 					dummy_end = dummy_end:entindex(),
-- 					go_come = 0,
-- 					--dummy_come = dummy_come:entindex()
-- 					}
--             }
--             TG_CreateProjectile({id = 1, team = self.caster:GetTeamNumber(), owner = self.caster,	p = info})
--         return nil
--         end)
--     end

-- end
-- function imba_beastmaster_wild_axes_sce:OnProjectileThink_ExtraData(pos, keys)
-- 	local caster = self:GetCaster()
-- 	if keys.dummy_pfx then
-- 		EntIndexToHScript(keys.dummy_pfx):SetOrigin(pos)
-- 	end
-- end
-- function imba_beastmaster_wild_axes_sce:OnProjectileHit_ExtraData(target, pos, keys)
-- 	local caster = self:GetCaster()
-- 	local dummy_pfx = EntIndexToHScript(keys.dummy_pfx)
-- 	local dummy_end = EntIndexToHScript(keys.dummy_end)
-- 	--local dummy_come = EntIndexToHScript(keys.dummy_come)
-- 	local go_come = keys.go_come
-- 	if go_come == 0 then
-- 		local modifier = dummy_pfx:FindModifierByName("modifier_imba_beastmaster_wild_axes_sce_pfx")
-- 		if modifier then
-- 			modifier.caught_enemies = {}
-- 			modifier.go_come = 1
-- 		end
-- 		local info =
-- 		{
-- 			Target = caster,
-- 			Source = dummy_end,
-- 			EffectName = "",
-- 			Ability = self,
-- 			iMoveSpeed = 1500,
-- 			vSourceLoc = caster:GetAbsOrigin(),
-- 			bDrawsOnMinimap = false,
-- 			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
-- 			bDodgeable = false,
-- 			bIsAttack = false,
-- 			bVisibleToEnemies = true,
-- 			bReplaceExisting = false,
-- 			flExpireTime = GameRules:GetGameTime() + 60,
-- 			bProvidesVision = false,
-- 			ExtraData = {
-- 				dummy_pfx = dummy_pfx:entindex(),
-- 				dummy_end = dummy_end:entindex(),
-- 				go_come = 1 ,
-- 				--dummy_come = dummy_come:entindex()
-- 				}
-- 		}

-- 		TG_CreateProjectile({id = 1, team = caster:GetTeamNumber(), owner = caster,	p = info})

-- 	elseif go_come == 1 then
-- 		dummy_pfx:Destroy()
-- 		dummy_end:Destroy()
-- 		--dummy_come:Destroy()

-- 	end

-- end