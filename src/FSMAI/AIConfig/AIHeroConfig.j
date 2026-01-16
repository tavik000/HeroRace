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

        // CrystalMaiden
        set heroTypeId = 'H000'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A006')  // Frostbite
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A008')  // CrystalNova
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A005')  // CrystalScatter
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.3)

        // LightKnight
        set heroTypeId = 'H003'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A012')  // HolyLight
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A011')  // DivineShield
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A0DW')  // RadiantStrike
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.5)

        // Lina
        set heroTypeId = 'O000'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A00T')  // DragonSlave
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A00F')  // LightStrikeArray
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A010')  // LagunaBlade
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.45)

        // BeastMaster
        set heroTypeId = 'N007'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A038')  // SummonGrizzly
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A037')  // SummonQuillBeast
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A02G')  // Stampede
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.5)

        // Guldan
        set heroTypeId = 'H00B'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A01X')  // Infernal(small)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A03L')  // Purge
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A053')  // HolyLight(Guldan)
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.5)

        // Lion
        set heroTypeId = 'O00I'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 4)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A083')  // EarthImpale
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A09D')  // Hex
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A089')  // ManaDrain
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 3, 'A0A4')  // FingerOfDeath
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.35)

        // ChaosBladeMaster
        set heroTypeId = 'O003'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A03G')  // HealingWard
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A03B')  // CriticalStrike
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A02Y')  // Omnislash
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.3)

        // Farseer
        set heroTypeId = 'O007'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A02P')  // ChainLightning
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A032')  // SpiritWolf
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A01Z')  // Earthquake
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.3)

        // TaurenChieftain
        set heroTypeId = 'O008'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 2)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A03A')  // Shockwave
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A036')  // WarStomp
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.47)

        // ShadowHunter
        set heroTypeId = 'O009'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 4)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A033')  // HealingWave
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A031')  // Hex
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A021')  // SerpentWard
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 3, 'A0J0')  // BigBadVoodoo
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.3)

        // Eredar
        set heroTypeId = 'N00A'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A04A')  // DemonParasite
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A05S')  // TerrorDecay
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A049')  // DemonShockwave
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.4)

        // Banshee
        set heroTypeId = 'N00C'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 5)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A056')  // CarrionSwarm
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A05L')  // Curse
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A05H')  // OutOfBody
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 3, 'A05Q')  // ChaosSorcery
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 4, 'A050')  // LocustSwarm
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.5)

        // PitLord
        set heroTypeId = 'N00D'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A04O')  // RainOfFire
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A04R')  // HowlOfTerror
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A04Z')  // Doom
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.5)

        // PlagueCaster
        set heroTypeId = 'E011'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A0H5')  // DeathPulse
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A0H3')  // GhostShroud
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A0H8')  // ReaperScythe
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.3)

        // SkeletonGrunt
        set heroTypeId = 'O00F'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A04Q')  // HeavyAxeStrike
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A05M')  // HadesShield
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A0HQ')  // AshenState
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.5)

        // DeadKnight
        set heroTypeId = 'U002'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A05B')  // DeathCoil
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A0GK')  // AphoticShield
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A045')  // AnimateDead
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.452)

        // Lich
        set heroTypeId = 'U003'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A058')  // FrostNova
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A057')  // FrostArmor
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A04S')  // ChainFrost
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.4)

        // DreadLord
        set heroTypeId = 'U004'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A04E')  // CarrionSwarm
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A05A')  // Sleep
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A048')  // Inferno
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.3)

        // CryptLord
        set heroTypeId = 'U005'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 4)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A047')  // Impale
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A04F')  // CarrionBeetles
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A0ET')  // SpikedCarapace
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 3, 'A04I')  // LocustSwarm
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.4)

        // DruidOfTheClaw
        set heroTypeId = 'N00K'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A07M')  // Cyclone
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A066')  // StormSwarm
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A06T')  // TempestAssault
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.25)

        // Chimera
        set heroTypeId = 'N02N'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A0HU')  // DualBreath
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A0HV')  // IcePath
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A0HY')  // Macropyre
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.7)

        // KeeperOfTheGrove
        set heroTypeId = 'E004'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A06F')  // EntanglingRoots
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A07D')  // ForceOfNature
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A06Q')  // Tranquility
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.5)

        // PriestessOfTheMoon
        set heroTypeId = 'E005'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 3)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A074')  // Jump
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A06Y')  // SacredArrow
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A06L')  // Starfall
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.0)

        // Luna
        set heroTypeId = 'E00J'
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_COUNT_KEY, 4)
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 0, 'A02K')  // LucentBeam
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 1, 'A02L')  // MoonGlaive
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 2, 'A0I0')  // MoonlightShadow
        call SaveInteger(HeroConfigTable, heroTypeId, HERO_ABILITY_ID_BASE_KEY + 3, 'A04U')  // Eclipse
        call SaveReal(HeroConfigTable, heroTypeId, HERO_CAST_POINT_KEY, 0.6)

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
