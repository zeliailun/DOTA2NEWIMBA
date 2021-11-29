ra_greater_crit = class({})
LinkLuaModifier("modifier_ra_greater_crit_pa", "ting/random_ab/ra_greater_crit", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ra_greater_crit_ex", "ting/random_ab/ra_greater_crit", LUA_MODIFIER_MOTION_NONE)

function ra_greater_crit:GetIntrinsicModifierName() return "modifier_ra_greater_crit_pa" end
function ra_greater_crit:IsHiddenWhenStolen() 		return false end
function ra_greater_crit:IsRefreshable() 		return false end
function ra_greater_crit:IsStealable() return false end
function ra_greater_crit:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier(caster,self,"modifier_ra_greater_crit_ex",{duration = -1})

end

modifier_ra_greater_crit_ex = class({})
function modifier_ra_greater_crit_ex:IsPurgable() return false end
function modifier_ra_greater_crit_ex:IsPurgeException() return false end
function modifier_ra_greater_crit_ex:IsHidden()
	return false
end
--
modifier_ra_greater_crit_pa = class({})
function modifier_ra_greater_crit_pa:IsPurgable() return false end
function modifier_ra_greater_crit_pa:IsPurgeException() return false end
function modifier_ra_greater_crit_pa:IsHidden()
	return true
end
function modifier_ra_greater_crit_pa:DeclareFunctions()
	return {

			MODIFIER_EVENT_ON_ATTACK_LANDED,
			}
end


function modifier_ra_greater_crit_pa:OnAttackLanded(keys)
	if IsServer() then
		if keys.attacker == self:GetParent() and keys.target then
			local att = self:GetParent():GetAverageTrueAttackDamage(self:GetParent())
			if keys.damage > att * 1.7 then 
				local ability = self:GetAbility()
				local damage = ability:GetSpecialValueFor("crit")*0.01
				local ex = self:GetParent():HasModifier("modifier_ra_greater_crit_ex")
				if ex then
					damage = ability:GetSpecialValueFor("crit_ex")*0.01
				end
				
				local hp_re = ability:GetSpecialValueFor("hp_re")
				local health = keys.target:GetMaxHealth()*hp_re*0.01
				
				local damageInfo =
					{
						victim = keys.target,
						attacker = keys.attacker,
						damage = att*damage,
						damage_type = DAMAGE_TYPE_PHYSICAL,
						ability = ability,
					}
				ApplyDamage( damageInfo )
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, keys.target, damage*att, nil)
				self:GetParent():RemoveModifierByName("modifier_ra_greater_crit_ex")
				if ex and keys.target:IsAlive() then 
					keys.target:Heal(keys.target:GetMaxHealth()*hp_re*0.01, keys.attacker)	
					SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, keys.target, health, nil)
				end
			end			
		end
	end
end

--
