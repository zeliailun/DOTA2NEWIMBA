ra_flask = class({})
LinkLuaModifier("modifier_ra_flask_buff1", "ting/random_ab/ra_flask", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ra_flask_buff2", "ting/random_ab/ra_flask", LUA_MODIFIER_MOTION_NONE)
function ra_flask:IsHiddenWhenStolen() 		return false end
function ra_flask:IsRefreshable() 		return false end
function ra_flask:IsStealable() return false end
function ra_flask:OnSpellStart()
	local caster = self:GetCaster()
	local tar = self:GetCursorTarget()
	local item = caster:FindItemInInventory("item_flask")
	
	caster:EmitSound("Hero_Treant.Eyes.Cast")
	tar:AddNewModifier(caster,self,"modifier_ra_flask_buff1",{duration = self:GetSpecialValueFor("duration")})	
	if item then
		tar:AddNewModifier(caster,self,"modifier_ra_flask_buff2",{duration = self:GetSpecialValueFor("duration")})	
		item:SetCurrentCharges(item:GetCurrentCharges() - 1)
		if item:GetCurrentCharges() == 0 then
			caster:RemoveItem(item)
		end
	end
	if self.first == nil then
		local f = caster:AddItemByName("item_flask")
		f:SetCurrentCharges(f:GetCurrentCharges()+self:GetSpecialValueFor("stack")-1)		
		self.first = true
	end
	--print(tostring(self.first))
end


--
modifier_ra_flask_buff1=class({})

function modifier_ra_flask_buff1:IsPurgable() 			
    return true
end

function modifier_ra_flask_buff1:IsHidden()				
    return false 
end
function modifier_ra_flask_buff1:OnCreated(keys)
	if self:GetAbility() == nil then return end
	self.ab = self:GetAbility()
	self.parent = self:GetParent()
	self.caster = self:GetCaster()
	self.heal = self.ab:GetSpecialValueFor("re")	

	if IsServer() then
		self:StartIntervalThink(1)
	end	
end
function modifier_ra_flask_buff1:OnIntervalThink()
	if not IsServer() then return end
	self.parent:Heal(self.heal, self.caster)	
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self.parent,self.heal, nil)
end
--

modifier_ra_flask_buff2=class({})

function modifier_ra_flask_buff2:IsPurgable() 			
    return true
end

function modifier_ra_flask_buff2:IsHidden()				
    return false 
end
function modifier_ra_flask_buff2:DeclareFunctions() 
	return {
	
	MODIFIER_EVENT_ON_ATTACK_LANDED 
	} 
end
function modifier_ra_flask_buff2:OnAttackLanded(keys)
	if not IsServer() then
		return
	end
	
	if keys.target ~= self.parent or keys.target == self.caster then
		return
	end
	self:Destroy()
end
function modifier_ra_flask_buff2:OnCreated(keys)
	if self:GetAbility() == nil then return end
	self.ab = self:GetAbility()
	self.parent = self:GetParent()
	self.caster = self:GetCaster()
	self.heal = self.ab:GetSpecialValueFor("re_ex")	

	if IsServer() then
		self:StartIntervalThink(1)
	end	
end
function modifier_ra_flask_buff2:OnIntervalThink()
	if not IsServer() then return end
	local heal = self.parent:GetMaxHealth()*self.heal*0.01
	self.parent:Heal(heal, self.caster)	
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self.parent,heal, nil)
end