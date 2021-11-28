
modifier_talent_armor=class({})
function modifier_talent_armor:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
function modifier_talent_armor:IsHidden()
	return true
end

function modifier_talent_armor:IsPurgable()
	return false
end

function modifier_talent_armor:IsPurgeException()
	return false
end

function modifier_talent_armor:RemoveOnDeath()
	return false
end

function modifier_talent_armor:IsPermanent()
	return true
end

function modifier_talent_armor:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function modifier_talent_armor:GetModifierPhysicalArmorBonus()
	return self.value
end

function modifier_talent_armor:OnCreated(tg)
    self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
