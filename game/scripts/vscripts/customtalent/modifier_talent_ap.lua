
modifier_talent_ap=class({})
function modifier_talent_ap:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
function modifier_talent_ap:IsHidden()
	return true
end

function modifier_talent_ap:IsPurgable()
	return false
end

function modifier_talent_ap:IsPurgeException()
	return false
end

function modifier_talent_ap:RemoveOnDeath()
	return false
end

function modifier_talent_ap:IsPermanent()
	return true
end

function modifier_talent_ap:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    }
end

function modifier_talent_ap:GetModifierSpellAmplify_Percentage()
	return self.value
end

function modifier_talent_ap:OnCreated(tg)
    self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
