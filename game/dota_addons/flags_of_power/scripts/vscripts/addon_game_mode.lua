-- Generated from template

if GM == nil then
  GM = class({})
  GM.started = false
  GM.respawn = 10
  GM.stackBuff = 20 -- not used yet
  GM.heroes = {}
end

require('timers')

function Precache(context)
  PrecacheItemByNameSync("item_flag_ne", context)
  PrecacheItemByNameSync("item_flag_nw", context)
  PrecacheItemByNameSync("item_flag_se", context)
  PrecacheItemByNameSync("item_flag_sw", context)
end

-- Create the game mode when we activate
function Activate()
  GameRules.AddonTemplate = GM()
  GameRules.AddonTemplate:InitGameMode()
end

function GM:InitGameMode()
  print("Addon is loaded.")
  GameMode = GameRules:GetGameModeEntity()

  GameMode:SetRecommendedItemsDisabled(true)
  GameMode:SetFixedRespawnTime(GM.respawn)
  GameMode:SetTopBarTeamValuesVisible(true)
  GameMode:SetTopBarTeamValuesOverride(true)
  GameRules:SetPreGameTime(5.0)
  GameRules:SetPostGameTime(5.0)

  ListenToGameEvent('npc_spawned', Dynamic_Wrap(GM, 'OnNPCSpawned'), self)
  ListenToGameEvent('entity_killed', Dynamic_Wrap(GM, 'OnEntityKilled'), self)
  
  GameRules:GetGameModeEntity():SetThink("OnThink", self, "GlobalThink", 2)
end

-- Evaluate the state of the game
function GM:OnThink()
  if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    if GM.started == false then
      GM.started = true
      spawnFlagNE()
      spawnFlagNW()
      spawnFlagSE()
      spawnFlagSW()
      Timers:CreateTimer(20,
        function()
          print("This function is called 20 seconds after the game begins, and every 20 seconds thereafter")
          local i = 1
          while GM.heroes[i] and i < 11 do
            checkFlag(GM.heroes[i])
            i = i + 1
          end
          return 20
        end)
		end
  elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
    return nil
  end
  return 1
end

function checkFlag(hero)
  print("Check if "..hero:GetName().." has flag.")
  for i = 0,5 do
    local item = hero:GetItemInSlot(i)
    if item then
      print("item name:"..item:GetAbilityName())
      if item:GetAbilityName() == "item_flag_ne" or item:GetAbilityName() == "item_flag_nw" or item:GetAbilityName() == "item_flag_se" or item:GetAbilityName() == "item_flag_sw" then
        print("item lvl: "..item:GetLevel())
        hero:SetModelScale(hero.originalModelScale * (1 + (item:GetLevel() / item:GetMaxLevel())))
        if item:GetLevel() < item:GetMaxLevel() then
          item:SetLevel(item:GetLevel() + 1)
          item:ApplyDataDrivenModifier(hero, hero, "flag_buff", {duration=-1})
        end
      end
    end
  end
end

function GM:OnEntityKilled(keys)
  local hero = EntIndexToHScript(keys.entindex_killed)

  if hero:IsHero() == false then
    return
  end
  
  for i = 0,5 do
    local item = hero:GetItemInSlot(i)
    if item then
      print("item name:"..item:GetAbilityName())
      if item:GetAbilityName() == "item_flag_ne" or item:GetAbilityName() == "item_flag_nw" or item:GetAbilityName() == "item_flag_se" or item:GetAbilityName() == "item_flag_sw" then
        print("item lvl: "..item:GetLevel())
        hero:SetModelScale(hero.originalModelScale)
        if item:GetAbilityName() == "item_flag_ne" then
          spawnFlagNE()
        elseif item:GetAbilityName() == "item_flag_nw" then
          spawnFlagNW()
        elseif item:GetAbilityName() == "item_flag_se" then
          spawnFlagSE()
        else
          spawnFlagSW()
        end
        hero:RemoveItem(item)
      end
    end
  end
end

function GM:OnNPCSpawned(keys)
  local hero = EntIndexToHScript(keys.entindex)
  if hero:IsHero() and hero.FirstSpawned == nil then
    local i = 1
    while GM.heroes[i] do
      i = i + 1
    end
    print("i: "..i)
    GM.heroes[i] = hero
    hero.FirstSpawned = true
    hero.originalModelScale = hero:GetModelScale()
    local level = hero:GetLevel()
		while level < 25 do
			hero:AddExperience(20000, 0, false, false)
			level = hero:GetLevel()
		end
  end
  if hero:IsHero() then
    print("OnNPCSpawned")
  end
end

function spawnFlagNE()
  print("entrou spawnFlagNE")
  local flag = CreateItem("item_flag_ne", nil, nil)
  CreateItemOnPositionSync(Vector(100, 100, 128), flag)
  print("saiu spawnFlagNE")
end

function spawnFlagNW()
  print("entrou spawnFlagNW")
  local flag = CreateItem("item_flag_nw", nil, nil)
  CreateItemOnPositionSync(Vector(-100, 100, 128), flag)
  print("saiu spawnFlagNW")
end

function spawnFlagSE()
  print("entrou spawnFlagSE")
  local flag = CreateItem("item_flag_se", nil, nil)
  CreateItemOnPositionSync(Vector(100, -100, 128), flag)
  print("saiu spawnFlagSE")
end

function spawnFlagSW()
  print("entrou spawnFlagSW")
  local flag = CreateItem("item_flag_sw", nil, nil)
  CreateItemOnPositionSync(Vector(-100, -100, 128), flag)
  print("saiu spawnFlagSW")
end

