item_rd_book=class({})

function item_rd_book:OnSpellStart()
      local caster=self:GetCaster()
      if caster.Random_Skill then
                  caster:EmitSound("DOTA_Item.Tango.Activate")
                  local name=caster.Random_Skill:GetName()
                  local lv=caster.Random_Skill:GetLevel()
                  caster:RemoveAbility(name)
                  local ab=caster:AddAbility(TG_Ability_Get(caster))
                  ab:SetLevel(lv)
                  caster.Random_Skill=ab
                  CDOTA_PlayerResource.RD_SK[caster:GetPlayerOwnerID()]=ab:GetName()
		      CustomNetTables:SetTableValue("rd_skills", "RDSK", CDOTA_PlayerResource.RD_SK)
      end
      self:SpendCharge()
end