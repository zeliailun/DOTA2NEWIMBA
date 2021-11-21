bot_config = class({})

local heros=
{
      "npc_dota_hero_sven",
      "npc_dota_hero_silencer",
      "npc_dota_hero_techies",
      "npc_dota_hero_earth_spirit",
      "npc_dota_hero_troll_warlord",
      "npc_dota_hero_furion",
      "npc_dota_hero_tinker" ,
}

local pos=
{
      "top","mid","bot"
}

function bot_config:Start()
      local num=PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)
      for a=1,#heros do
            Tutorial:AddBot(heros[a], bot_config:RandomLoc(), "positive ", true)
      end
      ------------------------------------------------------------
      Tutorial:AddBot("npc_dota_hero_viper", bot_config:RandomLoc(), "positive ", false)
      Tutorial:AddBot("npc_dota_hero_jakiro", bot_config:RandomLoc(), "positive ", false)
      Tutorial:AddBot("npc_dota_hero_tusk", bot_config:RandomLoc(), "positive ", false)
      Tutorial:AddBot("npc_dota_hero_skeleton_king", bot_config:RandomLoc(), "positive ", false)
      Tutorial:AddBot("npc_dota_hero_windrunner", bot_config:RandomLoc(), "positive ", false)
      Tutorial:AddBot("npc_dota_hero_sand_king", bot_config:RandomLoc(), "positive ", false)
      Tutorial:AddBot("npc_dota_hero_drow_ranger", bot_config:RandomLoc(), "positive ", false)
      Tutorial:AddBot("npc_dota_hero_lina", bot_config:RandomLoc(), "positive ", false)
end

function bot_config:RandomLoc()
      return pos[RandomInt(1, #pos)]
end
