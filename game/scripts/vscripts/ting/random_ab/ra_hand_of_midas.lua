ra_hand_of_midas = class({})
LinkLuaModifier("modifier_ra_hand_of_midas_pa", "ting/random_ab/ra_hand_of_midas", LUA_MODIFIER_MOTION_NONE)

function ra_hand_of_midas:GetIntrinsicModifierName() return "modifier_ra_hand_of_midas_pa" end
function ra_hand_of_midas:IsHiddenWhenStolen() 		return false end
function ra_hand_of_midas:IsRefreshable() 		return false end
function ra_hand_of_midas:IsStealable() return false end
function ra_hand_of_midas:OnSpellStart()
	local caster = self:GetCaster()
	local tar = self:GetCursorTarget()
	local gold_sale = self:GetSpecialValueFor("sale_gold")*0.01
	local gold_gain = self:GetSpecialValueFor("gain_gold")*0.01
	local item_tab = {}
	for i = 0,8 do 
		if tar:GetItemInSlot(i) ~= nil then
		table.insert(item_tab,tar:GetItemInSlot(i))
		end
	end
	
	if #item_tab > 0 then
		local item = item_tab[math.random(1,#item_tab)] 
		--print(tostring(item:GetName()))
		local gold = GetItemCost(item:GetName())
		tar:RemoveItem(item)
		PlayerResource:ModifyGold(caster:GetPlayerOwnerID(),gold*gold_gain,false,DOTA_ModifyGold_Unspecified)
		SendOverheadEventMessage(caster, OVERHEAD_ALERT_GOLD, caster, gold*gold_gain, nil)

		PlayerResource:ModifyGold(tar:GetPlayerOwnerID(),gold*gold_sale,false,DOTA_ModifyGold_Unspecified)
		SendOverheadEventMessage(tar, OVERHEAD_ALERT_GOLD, tar, gold*gold_sale, nil)
		
		--print(gold)
	end
	
	caster:EmitSound("Hero_Treant.Eyes.Cast")
	
	--print(tostring(self.first))
end


--
modifier_ra_hand_of_midas_pa=class({})
function modifier_ra_hand_of_midas_pa:IsHidden() return false end
function modifier_ra_hand_of_midas_pa:IsPurgable() return false end
function modifier_ra_hand_of_midas_pa:IsPurgeException() return false end
function modifier_ra_hand_of_midas_pa:RemoveOnDeath() return false end
function modifier_ra_hand_of_midas_pa:DeclareFunctions() return {MODIFIER_EVENT_ON_ABILITY_FULLY_CAST} end
function modifier_ra_hand_of_midas_pa:OnAbilityFullyCast(keys)
	if not IsServer() then
		return
	end
	if keys.unit ~= self:GetParent() then 
		return 
	end

	if keys.ability and keys.ability:GetAbilityName() == "item_hand_of_god" then 
		local item = keys.ability
		local cd = 1-self:GetAbility():GetSpecialValueFor("cd_re")*0.01
		local cooldown_remaining = item:GetCooldownTimeRemaining()
			item:EndCooldown()
			item:StartCooldown( cooldown_remaining*cd)

	end


	
end

--