-- Generated from template

if GM == nil then
  GM = class({})
  GM.started = false
  GM.respawn = 10
  GM.stackBuff = 20 -- not used yet
  GM.heroes = {}
  GM.scoreBad = 0
  GM.scoreGood = 0
end

if CONSTANTS == nil then
  CONSTANTS = class({})
  CONSTANTS.scoreToWin = 800
  CONSTANTS.pointForKill = 5
  CONSTANTS.poins = {2, 6, 13, 25}
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
  GM:updateScore()
  
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
      CONSTANTS.poins[0] = 0
      Timers:CreateTimer(20,
        function()
          print("This function is called 20 seconds after the game begins, and every 20 seconds thereafter")
          local i = 1
          while GM.heroes[i] and i < 11 do
            buffHeroWithFlag(GM.heroes[i])
            i = i + 1
          end
          return 20
        end)
      Timers:CreateTimer(5,
        function()
          scoreByFlags()
          return 5
        end)
		end
  elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
    return nil
  end
  return 1
end

function scoreByFlags()
  local flagsWithGood = 0
  local flagsWithBad = 0
  
  local i = 1
  while GM.heroes[i] and i < 11 do
    if hasFlag(GM.heroes[i]) then
      if GM.heroes[i]:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
        flagsWithGood = flagsWithGood + 1
      elseif GM.heroes[i]:GetTeamNumber() == DOTA_TEAM_BADGUYS then
        flagsWithBad = flagsWithBad + 1
      end
    end
    i = i + 1
  end
  GM.scoreGood = GM.scoreGood + CONSTANTS.poins[flagsWithGood]
  GM.scoreBad = GM.scoreBad + CONSTANTS.poins[flagsWithBad]
  GM:updateScore()
end

function hasFlag(hero)
  for i = 0,5 do
    local item = hero:GetItemInSlot(i)
    if item then
      if item:GetAbilityName() == "item_flag_ne" or item:GetAbilityName() == "item_flag_nw" or item:GetAbilityName() == "item_flag_se" or item:GetAbilityName() == "item_flag_sw" then
        return true
      end
    end
  end
  return false
end

function buffHeroWithFlag(hero)
  print("Buff "..hero:GetName().." if he has flag.")
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

function spawnFlag(flagName)
  if flagName == "item_flag_ne" then
    spawnFlagNE()
  elseif flagName == "item_flag_nw" then
    spawnFlagNW()
  elseif flagName == "item_flag_se" then
    spawnFlagSE()
  elseif flagName == "item_flag_sw" then
    spawnFlagSW()
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
        spawnFlag(item:GetAbilityName())
        hero:RemoveItem(item)
      end
    end
  end
  if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
    GM.scoreBad = GM.scoreBad + CONSTANTS.pointForKill
  elseif hero:GetTeamNumber() == DOTA_TEAM_BADGUYS then
    GM.scoreGood = GM.scoreGood + CONSTANTS.pointForKill
  end
  GM.updateScore()
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
    for i=0,15 do
      local ability = hero:GetAbilityByIndex(i)
      print("antes i: "..i)
      if ability then
        print("setando para: "..ability:GetMaxLevel())
        ability:SetLevel(ability:GetMaxLevel())
      end
    end
    hero:SetAbilityPoints(0)
  end
  if hero:IsHero() then
    print("OnNPCSpawned")
  end
end

function spawnFlagNE()
  print("entrou spawnFlagNE")
  local flag = CreateItem("item_flag_ne", nil, nil)
  CreateItemOnPositionSync(Vector(100, 100, 128), flag)
end

function spawnFlagNW()
  print("entrou spawnFlagNW")
  local flag = CreateItem("item_flag_nw", nil, nil)
  CreateItemOnPositionSync(Vector(-100, 100, 128), flag)
end

function spawnFlagSE()
  print("entrou spawnFlagSE")
  local flag = CreateItem("item_flag_se", nil, nil)
  CreateItemOnPositionSync(Vector(100, -100, 128), flag)
end

function spawnFlagSW()
  print("entrou spawnFlagSW")
  local flag = CreateItem("item_flag_sw", nil, nil)
  CreateItemOnPositionSync(Vector(-100, -100, 128), flag)
end

function GM:updateScore()
  print("Updating score: " .. GM.scoreGood .. " x " .. GM.scoreBad)

  local GameMode = GameRules:GetGameModeEntity()
  GameMode:SetTopBarTeamValue(DOTA_TEAM_GOODGUYS, GM.scoreGood)
  GameMode:SetTopBarTeamValue(DOTA_TEAM_BADGUYS, GM.scoreBad)

  -- If any team reaches scoreToWin, the game ends and that team is considered winner.
  if GM.scoreGood >= CONSTANTS.scoreToWin then
    print("Team GOOD GUYS victory!")
    GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
  end
  if GM.scoreBad >= CONSTANTS.scoreToWin then
    print("Team BAD GUYS victory!")
    GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
  end
end

function pickupFlag(event)
  local unit = EntIndexToHScript(event.caster_entindex)
  local itemName = event.ability:GetAbilityName()
  local flags = 0
  local dropItem = nil
  for i = 0,5 do
    local item = unit:GetItemInSlot(i)
    if item then
      if item:GetAbilityName() == "item_flag_ne" or item:GetAbilityName() == "item_flag_nw" or item:GetAbilityName() == "item_flag_se" or item:GetAbilityName() == "item_flag_sw" then
        if item:GetAbilityName() == itemName then
          dropItem = item
        end
        flags = flags + 1
      end
    end
  end
  if flags > 1 then
    unit:RemoveItem(dropItem)
    spawnFlag(itemName)
  end
end

