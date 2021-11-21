-- Editors:
-- MysticBug, 20.09.2021
ranger_shooter_star = class({})

ranger_shooter_star.shooter = {
	"shooter_dr",
	"shooter_wr",
	"shooter_snapfire",
}

LinkLuaModifier("modifier_ranger_shooter_star_caster","mb/ranger/ranger_shooter_star", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ranger_shooter_star_controller","mb/ranger/ranger_shooter_star", LUA_MODIFIER_MOTION_NONE)

function ranger_shooter_star:IsHiddenWhenStolen() 			return false end
function ranger_shooter_star:IsRefreshable() 				return true end
function ranger_shooter_star:IsStealable() 					return false end

function ranger_shooter_star:OnSpellStart()
	local caster            = self:GetCaster()
	local familiars_count   = 3
	local duration = self:GetSpecialValueFor("duration")
	local pos = caster:GetAbsOrigin() + (caster:GetForwardVector() * RandomInt(150, 300))
	local caster_attackrange = caster:Script_GetAttackRange()
	--解除射手 召唤新射手
	if caster:HasModifier("modifier_ranger_shooter_star_controller") then 
		caster:RemoveModifierByName("modifier_ranger_shooter_star_controller")
	end 
	if self.familiars_table then
		for i = 1, #self.familiars_table do
			if self.familiars_table[i] and EntIndexToHScript(self.familiars_table[i]) and not EntIndexToHScript(self.familiars_table[i]):IsNull() and EntIndexToHScript(self.familiars_table[i]):IsAlive() then
				EntIndexToHScript(self.familiars_table[i]):RemoveSelf()
			end
		end
	end
	--清空
	self.familiars_table = {}
	--召唤
	for i = 1, familiars_count do
		local unit = CreateUnitByName(self.shooter[i]..math.min(self:GetLevel(), 3), pos, true, caster, caster, caster:GetTeamNumber())
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin() + (unit:GetForwardVector() * RandomInt(150, 300)), true)
		--设置属性
		--SetCreatureHealth(unit, self:GetSpecialValueFor("familiar_hp"), true)
		--unit:SetPhysicalArmorBaseValue(1 + self:GetSpecialValueFor("familiar_armor"))
		--unit:SetBaseMoveSpeed(self:GetSpecialValueFor("familiar_speed"))
		--unit:SetBaseDamageMin(self:GetSpecialValueFor("familiar_attack_damage"))
		--unit:SetBaseDamageMax(self:GetSpecialValueFor("familiar_attack_damage"))
		--设置技能等级
		for j = 0, 6 do
			local current_ability = unit:GetAbilityByIndex(j)
			if current_ability then
				current_ability:SetLevel(self:GetLevel())
				current_ability:EndCooldown()
			end
		end
		unit:SetOwner(self:GetCaster())
		unit:SetTeam(self:GetCaster():GetTeam())
		--设置控制权
		unit:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
		--射手状态 飞行 穿越单位
		unit:AddNewModifier(caster, self, "modifier_ranger_shooter_star_caster", {duration = duration + 1.0, familiars_patrol = 0 , attack_range = caster_attackrange})
		--跟随
		unit:MoveToNPC(caster)
		--入列
		table.insert(self.familiars_table,unit:entindex())
	end
	-------------------------------------------------------------------
	--Sound
	caster:EmitSound("Hero_Medusa.Taunt.TI10")
	--Effect
	local particle = ParticleManager:CreateParticle("particles/econ/items/mars/mars_ti10_taunt/mars_ti10_taunt.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	--被动控制射手	
	caster:AddNewModifier(caster, self, "modifier_ranger_shooter_star_controller", { duration = duration})
end

--射手状态
modifier_ranger_shooter_star_caster = class({})

function modifier_ranger_shooter_star_caster:IsDebuff()				return false end
function modifier_ranger_shooter_star_caster:IsHidden() 			return true end
function modifier_ranger_shooter_star_caster:IsPurgable() 			return false end
function modifier_ranger_shooter_star_caster:IsPurgeException() 	return false end
function modifier_ranger_shooter_star_caster:RemoveOnDeath() 		return true end
function modifier_ranger_shooter_star_caster:OnCreated(keys)
	if not IsServer() then return end
		self.patrol = keys.familiars_patrol
		self.attack_range = keys.attack_range
		self:StartIntervalThink(0.4)
end

function modifier_ranger_shooter_star_caster:OnIntervalThink()
	if not IsServer() then return end
	-- 离卡德尔太远就传送
	if (self:GetParent():GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Length2D() >= 800 then
		self:GetParent():SetAbsOrigin(GetGroundPosition(self:GetCaster():GetAbsOrigin() + (self:GetCaster():GetForwardVector() * RandomInt(150, 300)), self:GetParent()))
	end
end

--飞行 穿越单位 无法选中 移除生命血条 无敌
function modifier_ranger_shooter_star_caster:CheckState()
	local state = {
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true, --拥有飞机穿越地形的能力，但是算作地面单位  
		[MODIFIER_STATE_FLYING] = false,	-- 飞行
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true, --穿越单位
	}
	return state
end

function modifier_ranger_shooter_star_caster:DeclareFunctions() return {MODIFIER_PROPERTY_ATTACK_RANGE_BONUS} end
function modifier_ranger_shooter_star_caster:GetModifierAttackRangeBonus() 
	if not IsServer() then return end 
	return (self.attack_range <= self:GetParent():GetBaseAttackRange()) and 0 or (self.attack_range - self:GetParent():GetBaseAttackRange())
end

------------------------------------------------------------------------------------
modifier_ranger_shooter_star_controller = class({})

function modifier_ranger_shooter_star_controller:IsHidden() return false end
function modifier_ranger_shooter_star_controller:IsDebuff() return false end
function modifier_ranger_shooter_star_controller:IsPurgable() return false end
function modifier_ranger_shooter_star_controller:RemoveOnDeath() return true end
function modifier_ranger_shooter_star_controller:OnCreated( keys )
	if not IsServer() then return end
		self:StartIntervalThink(0.3)
end
function modifier_ranger_shooter_star_controller:OnIntervalThink()
	if not IsServer() then return end
	--如果不能攻击就停止射手
	if self:GetParent():IsStunned() or self:GetParent():HasModifier("modifier_imba_heavens_halberd_active") or self:GetParent():HasModifier("modifier_imba_sheepstick_debuff") or self:GetParent():HasModifier("modifier_imba_lion_hex") or self:GetParent():HasModifier("modifier_tg_ss_magica_ani") then
		local familiars_table = self:GetAbility().familiars_table
		for i = 1, #familiars_table do
			if familiars_table[i] and EntIndexToHScript(familiars_table[i]) and not EntIndexToHScript(familiars_table[i]):IsNull() and EntIndexToHScript(familiars_table[i]):IsAlive() then
				EntIndexToHScript(familiars_table[i]):Stop()
				EntIndexToHScript(familiars_table[i]):MoveToNPC(self:GetParent())
			end
		end
	end 
end

function modifier_ranger_shooter_star_controller:OnRemoved()
	self:Destroy()
end
function modifier_ranger_shooter_star_controller:OnDestroy()
	if not IsServer() then return end
	--when death 
	local familiars_table = self:GetAbility().familiars_table
	if familiars_table then
		for i = 1, #familiars_table do
			if familiars_table[i] and EntIndexToHScript(familiars_table[i]) and not EntIndexToHScript(familiars_table[i]):IsNull() and EntIndexToHScript(familiars_table[i]):IsAlive() then
				--EntIndexToHScript(familiars_table[i]):ForceKill(false)
				EntIndexToHScript(familiars_table[i]):RemoveSelf()
			end
		end
	end
end