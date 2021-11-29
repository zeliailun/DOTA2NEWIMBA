ra_mango_tree = class({})
LinkLuaModifier("modifier_ra_greate_mango", "ting/random_ab/ra_mango_tree", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("ra_mango_tree_vision", "ting/random_ab/ra_mango_tree", LUA_MODIFIER_MOTION_NONE)
function ra_mango_tree:IsHiddenWhenStolen() 		return false end
function ra_mango_tree:IsRefreshable() 		return false end
function ra_mango_tree:IsStealable() return false end
function ra_mango_tree:OnSpellStart()
	local caster = self:GetCaster()
	local pos = self:GetCursorPosition()
	caster:EmitSound("Hero_Treant.Eyes.Cast")
	local tree = CreateTempTreeWithModel(pos, 36000,"models/props_tree/mango_tree.vmdl")
	CreateModifierThinker(caster, self, "ra_mango_tree_vision", {duration = -1,tree = tree:entindex()}, pos, caster:GetTeamNumber(), false)
	if self.greater_mango == nil then
		caster:AddNewModifier(caster,self,"modifier_ra_greate_mango",{duration = self:GetSpecialValueFor("greater_mango_cd")})	
		self.greater_mango = true
	end
end


--
ra_mango_tree_vision=class({})

function ra_mango_tree_vision:IsPurgable() 			
    return false
end

function ra_mango_tree_vision:IsPurgeException() 		
    return false 
end

function ra_mango_tree_vision:IsHidden()				
    return true 
end
function ra_mango_tree_vision:OnCreated(keys)
	if self:GetAbility() == nil then return end
	self.ab = self:GetAbility()
	self.vision = self.ab:GetSpecialValueFor("vision")	
	self.pos = self:GetParent():GetAbsOrigin()
	self.t = false
	if IsServer() then
		self.tree = EntIndexToHScript(keys.tree)
		self:StartIntervalThink(5)
		self:OnIntervalThink()
	end	
end
function ra_mango_tree_vision:OnIntervalThink()
	if not IsServer() then return end
	local trees = GridNav:GetAllTreesAroundPoint(self.pos,1,true)
	for _,tree in pairs(trees) do
		if self.tree == tree then
			self.t = true
		end
	end
	if self.t then
		AddFOWViewer(self:GetCaster():GetTeamNumber(), self.pos, self.vision , 5, false)
		self.t = false
	else
		self:Destroy()
	end
end
--

modifier_ra_greate_mango=class({})
function modifier_ra_greate_mango:IsDebuff() return false end
function modifier_ra_greate_mango:IsHidden() return false end
function modifier_ra_greate_mango:RemoveOnDeath() return false end
function modifier_ra_greate_mango:IsPurgable() return false end
function modifier_ra_greate_mango:IsPurgeException() return false end


function modifier_ra_greate_mango:OnDestroy()
	if IsServer() then
		self:GetParent():AddItemByName("item_greater_mango")
	end		
end