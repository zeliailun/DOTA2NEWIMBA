
modifier_talent_asp=class({})
function modifier_talent_asp:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
function modifier_talent_asp:IsHidden()
	return true
end

function modifier_talent_asp:IsPurgable()
	return false
end

function modifier_talent_asp:IsPurgeException()
	return false
end

function modifier_talent_asp:RemoveOnDeath()
	return false
end

function modifier_talent_asp:IsPermanent()
	return true
end

function modifier_talent_asp:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end

function modifier_talent_asp:GetModifierAttackSpeedBonus_Constant()
	return self.value
end

function modifier_talent_asp:OnCreated(tg)
    self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
