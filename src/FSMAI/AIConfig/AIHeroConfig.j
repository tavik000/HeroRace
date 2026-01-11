library AIHeroConfig
    globals
        hashtable HeroConfigTable
        
        // Keys for hero config data
        constant integer HERO_ABILITY_COUNT_KEY = 0
        constant integer HERO_ABILITY_ID_BASE_KEY = 100  // Base key for ability IDs (100, 101, 102, ...)
    endglobals

    function InitHeroConfig takes nothing returns nothing
        local integer heroTypeId = 0
        local integer abilityIndex = 0
        
        set HeroConfigTable = InitHashtable()
        
        // BloodMage ('H009') Configuration
        set heroTypeId = 'H009'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A00W')  // Banish
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A00S')  // Flame Strike
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A01N')  // Blood Lust
        
        // Mountain King ('Hmkg') Configuration - Example
        set heroTypeId = 'Hmkg'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 1)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'AHtc')  // Thunder Clap
        
        // Add more hero configurations here...
        // Template:
        // set heroTypeId = 'H0XX'
        // call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, X)
        // call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'AXXX')
        // call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'AYYY')
    endfunction

    function GetHeroAbilityCount takes integer heroTypeId returns integer
        return LoadInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY)
    endfunction

    function GetHeroAbilityId takes integer heroTypeId, integer index returns integer
        return LoadInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + index)
    endfunction

    function HeroHasConfig takes integer heroTypeId returns boolean
        return LoadInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY) > 0
    endfunction

endlibrary
