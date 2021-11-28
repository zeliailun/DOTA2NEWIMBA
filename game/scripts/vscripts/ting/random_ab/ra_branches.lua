ra_branches = class({})
LinkLuaModifier("modifier_ra_branches_pa", "ting/random_ab/ra_branches", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ra_branches_buff", "ting/random_ab/ra_branches", LUA_MODIFIER_MOTION_NONE)
function ra_branches:GetIntrinsicModifierName() return "modifier_ra_branches_pa" end
function ra_branches:IsHiddenWhenStolen() 		return false end


--自动刺
modifier_ra_branches_pa=class({})
function modifier_ra_branches_pa:IsHidden() return false end
function modifier_ra_branches_pa:IsPurgable() return false end
function modifier_ra_branches_pa:IsPurgeException() return false end
function modifier_ra_branches_pa:DeclareFunctions()
    return 
    {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    }
end

function modifier_ra_branches_pa:GetModifierBonusStats_Agility()
	return self:GetStackCount()
end
function modifier_ra_branches_pa:GetModifierBonusStats_Intellect()
	return self:GetStackCount()
end
function modifier_ra_branches_pa:GetModifierBonusStats_Strength()
	return self:GetStackCount()
end


function modifier_ra_branches_pa:OnCreated()
	if self:GetAbility() == nil then return end
	self.ab = self:GetAbility()
	self.parent = self:GetParent()
	self.lv = 0
	self.count = 0
    if IsServer() then 
		self:SetStackCount(self.lv)
        self:StartIntervalThink(5)
   end
end

function modifier_ra_branches_pa:OnIntervalThink()
		if not IsServer() then return end
		local item = self.parent:FindItemInInventory("item_branches")
		local stat = self.ab:GetSpecialValueFor("stat")
		local stat_ex = self.ab:GetSpecialValueFor("stat_stack")
		if item and not item:IsInBackpack() then
			self.count = self.count+1
			if self.count > 12 then
			--print(self.count)
				self.count = self.count - 12
				self.lv = self.lv + stat_ex
			end
			self:SetStackCount(self.lv + stat)
		else
			self:SetStackCount(stat)
		
		end
		self.parent:CalculateStatBonus(true)
end