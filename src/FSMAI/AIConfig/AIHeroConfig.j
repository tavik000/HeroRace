library AIHeroConfig
    globals
        hashtable HeroConfigTable
        
        // Keys for hero config data
        constant integer HERO_ABILITY_COUNT_KEY = 0
        constant integer HERO_CAST_POINT_KEY = 1 // Pre-swing duration
        constant integer HERO_ABILITY_ID_BASE_KEY = 100  // Base key for ability IDs (100, 101, 102, ...)
    endglobals

    function InitHeroConfig takes nothing returns nothing
        local integer heroTypeId = 0
        local integer abilityIndex = 0
        
        set HeroConfigTable = InitHashtable()
        
        // BloodMage 
        set heroTypeId = 'H009'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A00W')  // Banish
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A00S')  // FlameStrike
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A01N')  // BloodLust
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.2)
        
        // Mountain King 
        set heroTypeId = 'H008'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A00C')  // StormBolt
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A00R')  // ThunderClap
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A014')  // Avatar
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.4)
        
        // Archmage
        set heroTypeId = 'H007'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A01K')  // ThunderFireball
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A001')  // Blizzard
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A019')  // MassTeleport
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.3)

        // Arthas
        set heroTypeId = 'H006'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A00P')  // HammerBash
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A00J')  // GoldenConvergence
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A01G')  // GoldenDefense
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.5)

        // Paladin
        set heroTypeId = 'H005'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A01O')  // InnerFire
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A01M')  // HolyCleanse
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A00Q')  // SolarIgnition
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.7)

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

    function GetHeroCastPoint takes integer heroTypeId returns real
        return LoadReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY)
    endfunction

endlibrary
