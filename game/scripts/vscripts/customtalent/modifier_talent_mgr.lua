
modifier_talent_mgr=class({})
function modifier_talent_mgr:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
function modifier_talent_mgr:IsHidden()
	return true
end

function modifier_talent_mgr:IsPurgable()
	return false
end

function modifier_talent_mgr:IsPurgeException()
	return false
end

function modifier_talent_mgr:RemoveOnDeath()
	return false
end

function modifier_talent_mgr:IsPermanent()
	return true
end

function modifier_talent_mgr:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    }
end

function modifier_talent_mgr:GetModifierMagicalResistanceBonus()
	return self.value
end

function modifier_talent_mgr:OnCreated(tg)
    self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
