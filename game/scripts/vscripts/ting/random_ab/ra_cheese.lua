ra_cheese = class({})

function ra_cheese:IsHiddenWhenStolen() 		return false end
function ra_cheese:IsStealable() return false end
function ra_cheese:IsRefreshable() 		return false end
function ra_cheese:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("DOTA_Item.Cheese.Activate")
	caster:AddItemByName("item_cheese")
end