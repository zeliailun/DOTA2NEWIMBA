ra_clarity = class({})
LinkLuaModifier("modifier_ra_clarity_pa", "ting/random_ab/ra_clarity", LUA_MODIFIER_MOTION_NONE)
function ra_clarity:GetIntrinsicModifierName() return "modifier_ra_clarity_pa" end
function ra_clarity:IsHiddenWhenStolen() 		return false end
function ra_clarity:IsStealable() return false end
function ra_clarity:OnSpellStart()
	local caster = self:GetCaster()
	local tar = self:GetCursorTarget()
	local gold = self:GetSpecialValueFor("gold")
	local dur = self:GetSpecialValueFor("duration")
	local item = caster:FindItemInInventory("item_clarity")
		caster:EmitSound("Hero_Treant.Eyes.Cast")
	if item then
		item:SetCurrentCharges(item:GetCurrentCharges()-1)	
		if item:GetCurrentCharges() == 0 then
			caster:RemoveItem(item)
		end
		
		if Is_Chinese_TG(caster,tar) then
			tar:AddNewModifier(caster,self,"modifier_ra_clarity_pa",{duration = dur})
			else
			caster:EmitSound( "DOTA_Item.Hand_Of_Midas" )
			tar:AddItemByName("item_clarity")
		
		
			PlayerResource:ModifyGold(caster:GetPlayerOwnerID(),gold,false,DOTA_ModifyGold_Unspecified)
			SendOverheadEventMessage(caster, OVERHEAD_ALERT_GOLD, caster, gold, nil)

			PlayerResource:ModifyGold(tar:GetPlayerOwnerID(), (0 - gold), false, DOTA_ModifyGold_Unspecified)
			PopupNumbers(tar, "gold", Vector(255, 200, 33), 1.0,gold, 1)
			
		end
	end
	

end


--被动回蓝
modifier_ra_clarity_pa=class({})
function modifier_ra_clarity_pa:IsHidden() return false end
function modifier_ra_clarity_pa:IsPurgable() return false end
function modifier_ra_clarity_pa:IsPurgeException() return false end
function modifier_ra_clarity_pa:RemoveOnDeath() return false end
function modifier_ra_clarity_pa:GetAttributes() 
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end
function modifier_ra_clarity_pa:OnCreated()
	if self:GetAbility() == nil then return end
	self.ab = self:GetAbility()
	self.parent = self:GetParent()
    if IsServer() then 
        self:StartIntervalThink(1)
   end
end

function modifier_ra_clarity_pa:OnIntervalThink()
	if not IsServer() then return end
	if self.parent:IsAlive() and not self.parent:IsIllusion() then
		local mana = self.parent:GetMaxMana()*self.ab:GetSpecialValueFor("mana_re")*0.01
		self.parent:GiveMana(mana)
	end
end