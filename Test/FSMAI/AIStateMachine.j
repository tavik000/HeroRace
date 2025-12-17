library AIStateMachine requires optional KeyUtils
    
    // --- CONFIGURATION ---
    globals
        // States
        constant integer STATE_NONE = 0
        constant integer STATE_RUN = 1
        constant integer STATE_COMBAT = 2
        constant integer STATE_HAZARD = 3
        constant integer STATE_HEALING = 4
        constant integer STATE_DEAD = 5
        
        // Difficulty Levels
        constant integer DIFF_EASY = 0
        constant integer DIFF_NORMAL = 1
        constant integer DIFF_HARD = 2
        constant integer DIFF_CRAZY = 3
        constant integer DIFF_NIGHTMARE = 4
        
        // Settings
        constant real HEAL_THRESHOLD = 0.40 // 40% HP
        constant real UPDATE_PERIOD = 0.30

        // Hazard Types
        constant integer HAZARD_TYPE_NONE = 0
        constant integer HAZARD_TYPE_SLOW_SPIKE = 1
        constant integer HAZARD_TYPE_NET = 2
        
        // Spike Hazard Settings 
        constant real SLOW_SPIKE_AVOIDANCE_RADIUS = 150.0
        constant real SLOW_SPIKE_SPEED = 155.0
        constant real SLOW_SPIKE_RADIUS = 110.0
        
        // Combat settings
        constant real EASY_CD_MULTIPLIER = 2.0
        constant real NORMAL_CD_MULTIPLIER = 1.0
        constant real HARD_CD_MULTIPLIER = 1.0
        constant real CRAZY_CD_MULTIPLIER = 1.0
        constant real NIGHTMARE_CD_MULTIPLIER = 0.8 
        constant integer MAX_ABILITIES_PER_HERO = 7
        
        // Timer to AIHero mapping
        public hashtable udg_TimerHeroMap
        public hashtable udg_DebugTextTagTimerHeroMap
        
        // Unit to AIHero mapping
        public hashtable udg_UnitAIHeroMap
        
        // Global timer for tracking game time
        public timer gameTimer
        
        // Hero cast point (pre-swing) mapping by unit type
        public hashtable heroCastPointMap
        
        // Temporary variables for filtering heroes
        private player tempHeroOwner
        private boolean bTempFilterForAllies
        private unit tempHeroUnit
        private HeroAbility tempHeroAbility

        // The array to hold the waypoint regions.
        private rect array WaypointAreas
        // The actual number of waypoints initialized.
        public integer WaypointCount = 0

        // Turn time for 90 degree turns, giving turn rate 0.6
        constant real TURN_TIME = 0.2 

        constant real MAX_RANGE = 30000.0

        // Debug Text Tag Color Presets (RGB 0-100 format)
        constant real COLOR_WHITE_R = 100.0
        constant real COLOR_WHITE_G = 100.0
        constant real COLOR_WHITE_B = 100.0
        constant real COLOR_RED_R = 100.0
        constant real COLOR_RED_G = 0.0
        constant real COLOR_RED_B = 0.0
        constant real COLOR_GREEN_R = 0.0
        constant real COLOR_GREEN_G = 100.0
        constant real COLOR_GREEN_B = 0.0
        constant real COLOR_BLUE_R = 0.0
        constant real COLOR_BLUE_G = 0.0
        constant real COLOR_BLUE_B = 100.0
        constant real COLOR_YELLOW_R = 100.0
        constant real COLOR_YELLOW_G = 100.0
        constant real COLOR_YELLOW_B = 0.0
        constant real COLOR_ORANGE_R = 100.0
        constant real COLOR_ORANGE_G = 64.7
        constant real COLOR_ORANGE_B = 0.0
        constant real COLOR_PURPLE_R = 50.2
        constant real COLOR_PURPLE_G = 0.0
        constant real COLOR_PURPLE_B = 50.2
        constant real COLOR_CYAN_R = 0.0
        constant real COLOR_CYAN_G = 100.0
        constant real COLOR_CYAN_B = 100.0
        constant real COLOR_PINK_R = 100.0
        constant real COLOR_PINK_G = 75.3
        constant real COLOR_PINK_B = 79.6
        constant real COLOR_GRAY_R = 36.5
        constant real COLOR_GRAY_G = 36.5
        constant real COLOR_GRAY_B = 36.5
    endglobals

    function BotLog takes string msg returns nothing
        if udg_bEnableLogBot then
            call BJDebugMsg("[AI Bot] " + msg)
        endif
    endfunction

    function BotLogWithPlayer takes player p, string msg returns nothing
        local integer playerIndex = GetPlayerId(p) + 1
        local string playerName = ""
        if udg_bEnableLogBot then
            if playerIndex >= 0 and playerIndex <= 12 then
                set playerName = udg_PlayerNameWithHero[playerIndex]
                if playerName != null and playerName != "" then
                    call BJDebugMsg("[AI Bot] " + playerName + " " + msg)
                else
                    call BJDebugMsg("[AI Bot] Player " + I2S(playerIndex) + " " + msg)
                endif
            else
                call BJDebugMsg("[AI Bot] " + msg)
            endif
        endif
    endfunction

    function BotLogError takes string msg returns nothing
        call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r " + msg)
    endfunction

    function BotLogErrorWithPlayer takes player p, string msg returns nothing
        local integer playerIndex = GetPlayerId(p) + 1
        local string playerName = ""
        if playerIndex >= 0 and playerIndex <= 12 then
            set playerName = udg_PlayerNameWithHero[playerIndex]
            if playerName != null and playerName != "" then
                call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r " + playerName + " " + msg)
            else
                call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r Player " + I2S(playerIndex) + " " + msg)
            endif
        else
            call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r " + msg)
        endif
    endfunction

    // Helper function to get cooldown multiplier based on difficulty
    function GetCooldownMultiplier takes integer difficulty returns real
        if difficulty == DIFF_EASY then
            return EASY_CD_MULTIPLIER
        elseif difficulty == DIFF_NORMAL then
            return NORMAL_CD_MULTIPLIER
        elseif difficulty == DIFF_HARD then
            return HARD_CD_MULTIPLIER
        elseif difficulty == DIFF_CRAZY then
            return CRAZY_CD_MULTIPLIER
        elseif difficulty == DIFF_NIGHTMARE then
            return NIGHTMARE_CD_MULTIPLIER
        else
            return 1.0
        endif
    endfunction

    function IsApplyingCombo takes integer difficulty returns boolean
        if difficulty == DIFF_HARD or difficulty == DIFF_CRAZY or difficulty == DIFF_NIGHTMARE then
            return true
        else
            return false
        endif
    endfunction

    // Initialize hero cast points (Pre-swing) by unit type
    private function InitializeHeroCastPoints takes nothing returns nothing
        // Configure cast points for different hero types
        call SaveReal(heroCastPointMap, 'H009', 0, 0.2)  // BloodMage
        // call SaveReal(heroCastPointMap, 'Hmkg', 0, 0.3)  // Mountain King  
        // TODO: Add more hero types as needed
    endfunction

    // Initialize hero-specific abilities (extend this function for different heroes)
    function InitializeHeroCombatData takes unit hero, integer difficulty returns HeroCombatData
        local HeroCombatData data = HeroCombatData.create()
        local integer heroTypeId = GetUnitTypeId(hero)

        
        // Example: Add abilities based on hero type
        if heroTypeId == 'H009' then  // BloodMage example
            call BotLog("Adding abilities for BloodMage")
            call data.addAbility('A00S', 22.0, CAST_POINT_ENEMY_FRONT, "flamestrike", 70, MAX_RANGE, ALLOW_TARGET_TYPE_ENEMY_HERO, 200, 2, 866.0)   // Flame Strike
            call data.addAbility('A00W', 22.0, CAST_UNIT, "banish", 40, MAX_RANGE, ALLOW_TARGET_TYPE_ENEMY_HERO, 0, 1, 0.0)   // Banish
            call data.addAbility('A01N', 47.0, CAST_UNIT, "bloodlust", 50, 2500, ALLOW_TARGET_TYPE_ALLY_HERO, 0, 0, 0.0) // Blood Lust
            
        elseif heroTypeId == 'Hmkg' then  // Mountain King example
            // call data.addAbility('AHtc', 6.0, CAST_UNIT, "thunderclap", 75, 250, ALLOW_TARGET_TYPE_ENEMY_UNIT, 0)      // Thunder Clap
            // Add more hero types as needed...
        endif
        
        return data
    endfunction

    function GetHeroCastPoint takes integer heroTypeId returns real
        if HaveSavedReal(heroCastPointMap, heroTypeId, 0) then
            return LoadReal(heroCastPointMap, heroTypeId, 0)
        else
            call BotLogError("Unknown hero type for GetHeroCastPoint: " + I2S(heroTypeId))
            return 0.5  // Default cast point for unknown hero types
        endif
    endfunction

    // Helper function for basic unit validation
    function IsValidHeroTarget takes unit filterUnit returns boolean
        if not IsUnitAliveBJ(filterUnit) then
            return false
        endif
        if not IsUnitType(filterUnit, UNIT_TYPE_HERO) then
            return false
        endif
        if not IsUnitVisible(filterUnit, tempHeroOwner) then
            return false
        endif
        return true
    endfunction

    // Generic filter function for heroes (enemies or allies)
    function FilterHeroes takes nothing returns boolean
        local unit filterUnit = GetFilterUnit()
        
        if not IsValidHeroTarget(filterUnit) then
            set filterUnit = null
            return false
        endif

        if tempHeroAbility != 0 then
            if not tempHeroAbility.customFilter(filterUnit) then
                set filterUnit = null
                return false
            endif
        endif

        // Check if we want allies or enemies
        if bTempFilterForAllies then
            // Filter for allies (same team, but not the same unit)
            if IsUnitEnemy(filterUnit, tempHeroOwner) then
                set filterUnit = null
                return false
            endif
        else
            // Filter for enemies
            if not IsUnitEnemy(filterUnit, tempHeroOwner) then
                set filterUnit = null
                return false
            endif
            if IsUnitInvulnerableOrMagicImmune(filterUnit) then
                set filterUnit = null
                return false
            endif
        endif
        
        set filterUnit = null
        return true
    endfunction

    function GetAIHeroFromUnit takes unit u returns AIHero
        if u == null then
            return 0
        endif
        return LoadInteger(udg_UnitAIHeroMap, GetHandleId(u), 0)
    endfunction

    function DestroyAIHero takes unit u returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.destroy()
        endif
    endfunction

    function OnAIHeroCastComplete takes unit u returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.onCastComplete()
        endif
    endfunction

    // This function will run once at map initialization to set up the waypoints.
    private function InitializeWaypoints takes nothing returns nothing
        // IMPORTANT: Create regions in the World Editor and replace these
        set WaypointAreas[0] = gg_rct_AIWayPointArea01
        set WaypointAreas[1] = gg_rct_AIWayPointArea01 // After Start Area
        set WaypointAreas[2] = gg_rct_AIWayPointArea02
        set WaypointAreas[3] = gg_rct_AIWayPointArea03 // Left of Upper Strait
        set WaypointAreas[4] = gg_rct_AIWayPointArea04
        set WaypointAreas[5] = gg_rct_AIWayPointArea05 // Upper of 3 Fishes
        set WaypointAreas[6] = gg_rct_AIWayPointArea06 // Left of 3 Fishes 
        set WaypointAreas[7] = gg_rct_AIWayPointArea07 // Before Slow Spike Hazard
        set WaypointAreas[8] = gg_rct_AIWayPointArea08 // After Slow Spike Hazard
        set WaypointAreas[9] = gg_rct_AIWayPointArea09 // Before Fast Spike Hazard
        set WaypointAreas[10] = gg_rct_AIWayPointArea10 // Before Net Hazard
        set WaypointAreas[11] = gg_rct_AIWayPointArea11 // After Net Hazard
        set WaypointAreas[12] = gg_rct_AIWayPointArea12
        set WaypointAreas[13] = gg_rct_Finish
        set WaypointCount = 13 // Update this to match the number of waypoints you added.
    endfunction

    // Ability cast types
    globals
        constant integer CAST_INSTANT = 0
        constant integer CAST_POINT_ENEMY_FRONT = 1
        constant integer CAST_POINT_ENEMY_BEHIND = 2
        constant integer CAST_POINT_SELF_BEHIND = 3
        constant integer CAST_POINT_TREE = 4
        constant integer CAST_POINT_BLINK = 5
        constant integer CAST_UNIT = 6

        constant integer ALLOW_TARGET_TYPE_NONE = 0
        constant integer ALLOW_TARGET_TYPE_ENEMY_HERO = 1
        constant integer ALLOW_TARGET_TYPE_ENEMY_UNIT = 2
        constant integer ALLOW_TARGET_TYPE_ALLY_HERO = 3
        constant integer ALLOW_TARGET_TYPE_ALLY_UNIT = 4
        constant integer ALLOW_TARGET_TYPE_ALL = 5
        constant integer ALLOW_TARGET_TYPE_SELF = 6
    endglobals

    struct HeroAbility
        integer abilityId
        real baseCooldown
        integer castType
        real lastCastTime
        integer comboIndex  // For chaining abilities in sequence
        string orderString  
        integer manaCost    
        real castRange
        integer allowTargetType
        real effectiveRadius
        real expectedDamage  // For combo targeting logic

        static method create takes integer aid, real cd, integer inCastType, string order, integer mana, real inCastRange, integer inAllowTargetType, real inEffectiveRadius, integer inComboIndex, real inExpectedDamage returns thistype
            local thistype this = thistype.allocate()
            set this.abilityId = aid
            set this.baseCooldown = cd
            set this.castType = inCastType
            set this.lastCastTime = 0.0
            set this.comboIndex = inComboIndex
            set this.orderString = order
            set this.manaCost = mana
            set this.castRange = inCastRange
            set this.allowTargetType = inAllowTargetType
            set this.effectiveRadius = inEffectiveRadius
            set this.expectedDamage = inExpectedDamage
            return this
        endmethod

        method isCooldownReady takes integer difficulty returns boolean
            local real currentTime = TimerGetElapsed(gameTimer)
            local real requiredCooldown 
            local real cooldownMultiplier = GetCooldownMultiplier(difficulty)
            if this.lastCastTime == 0.0 then
                return true
            endif
            set requiredCooldown = this.baseCooldown * cooldownMultiplier
            if currentTime >= this.lastCastTime + requiredCooldown then
                return true
            endif
            return false
        endmethod


        method isManaReady takes unit caster returns boolean
            local real currentMana = GetUnitState(caster, UNIT_STATE_MANA)
            if currentMana >= I2R(this.manaCost) then
                return true
            endif
            return false
        endmethod

        method customFilter takes unit u returns boolean
            // Custom filtering logic for specific abilities
            if this.abilityId == 'A00W' then  // Banish ability
                if UnitHasBuffBJ(u, 'BHbn') then
                    call BotLog("Skipping banish target, already banished, unit: " + GetUnitName(u))
                    return false
                endif
            endif
            return true
        endmethod

        
        method destroy takes nothing returns nothing
            call this.deallocate()
        endmethod
    endstruct

    struct HeroCombatData
        HeroAbility array abilities[MAX_ABILITIES_PER_HERO]
        integer abilityCount
        real comboExpectedDamage
        real comboOverkillThresholdPercent
        
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.abilityCount = 0
            set this.comboExpectedDamage = 0.0
            set this.comboOverkillThresholdPercent = 0.3 // Default to 30% of combo damage
            return this
        endmethod
        
        method addAbility takes integer abilityId, real cooldown, integer castType, string orderString, integer manaCost, real castRange, integer allowTargetType, real effectiveRadius, integer comboIndex, real expectedDamage returns nothing
            if this.abilityCount < MAX_ABILITIES_PER_HERO then
                set this.abilities[this.abilityCount] = HeroAbility.create(abilityId, cooldown, castType, orderString, manaCost, castRange, allowTargetType, effectiveRadius, comboIndex, expectedDamage)
                if comboIndex > 0 then
                    set this.comboExpectedDamage = this.comboExpectedDamage + this.abilities[this.abilityCount].expectedDamage
                endif
                set this.abilityCount = this.abilityCount + 1
            else
                // Exceeded max abilities - handle error as needed
                call BotLogError("Exceeded max abilities for hero combat data.")
            endif
        endmethod
        
        method destroy takes nothing returns nothing
            local integer i = 0
            loop
                exitwhen i >= this.abilityCount
                call this.abilities[i].destroy()
                set i = i + 1
            endloop
            call this.deallocate()
        endmethod

        method getAbilityByComboIndex takes integer comboIndex returns HeroAbility
            local integer i = 0
            loop
                exitwhen i >= this.abilityCount
                if this.abilities[i].comboIndex == comboIndex then
                    return this.abilities[i]
                endif
                set i = i + 1
            endloop
            return 0
        endmethod

        method hasReadyAbility takes unit hero, integer difficulty returns boolean
            local HeroAbility heroAbil = this.getReadyAbility(hero, difficulty)
            if heroAbil != 0 then
                return true
            endif
            return false
        endmethod

        method getReadyAbility takes unit hero, integer difficulty returns HeroAbility
            local integer i = 0
            local HeroAbility heroAbil
            local real currentMana
            local boolean bCheckCombo = IsApplyingCombo(difficulty)
            local AIHero aiHero = GetAIHeroFromUnit(hero)

            if bCheckCombo then
                // Check for combo abilities starting from index 1
                set heroAbil = this.getAbilityByComboIndex(1)
                if heroAbil != 0 then
                    // Exist any combo ability
                    // If combo ability cooldown are ready, prioritize them
                    if this.areComboAbilityCooldownReady(hero, difficulty, aiHero.currentComboIndex) then
                        // Check if we have enough mana for combo
                        if this.hasEnoughManaForCombo(hero, aiHero.currentComboIndex) then
                            // Cooldown ready and enough mana - proceed with combo
                            set heroAbil = this.getReadyComboAbility(hero, difficulty, aiHero.currentComboIndex)
                            if heroAbil != 0 then
                                return heroAbil
                            endif
                        else
                            // Cooldown ready but not enough mana - don't fallback to non-combo abilities, prioritize mana waiting
                            return 0
                        endif
                    endif
                    // If combo cooldown are not ready, continue to check non-combo abilities
                endif
            endif

            // Check if any ability is ready for combat based on difficulty
            loop
                exitwhen i >= this.abilityCount
                set heroAbil = this.abilities[i]
                
                if bCheckCombo and heroAbil.comboIndex > 0 then
                    // Skip combo abilities if not checking for combos
                else
                    // Check cooldown (skip for first-time cast)
                    if heroAbil.isCooldownReady(difficulty) then
                        // Check if ability is available
                        if GetUnitAbilityLevel(hero, heroAbil.abilityId) <= 0 then
                            call BotLogError("Ability not available: " + heroAbil.orderString)
                        else
                            // Check if hero has enough mana
                            set currentMana = GetUnitState(hero, UNIT_STATE_MANA)
                            if not heroAbil.isManaReady(hero) then
                                call BotLog("Not enough mana for ability. Need: " + I2S(heroAbil.manaCost) + ", Have: " + I2S(R2I(currentMana)))
                                call aiHero.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - No Mana" + "(" + I2S(heroAbil.manaCost) + "/" + I2S(R2I(currentMana)) + ")")
                                call aiHero.setDebugTextTagColorPreset("RED")
                            else
                                return heroAbil
                            endif
                        endif
                    endif
                endif
                set i = i + 1
            endloop

            return 0
        endmethod

        method getReadyComboAbility takes unit hero, integer difficulty, integer startingComboIndex returns HeroAbility
            local integer i = startingComboIndex
            local HeroAbility heroAbil
            local HeroAbility resultComboAbility = 0
            local AIHero aiHero = GetAIHeroFromUnit(hero)
            if aiHero == 0 then
                call BotLogError("AIHero not found for unit in getReadyComboAbility.")
                return 0
            endif


            // Check if a sequence of combo abilities are ready
            loop
                set heroAbil = this.getAbilityByComboIndex(i)
                // Reach end of combo sequence
                exitwhen heroAbil == 0
                
                // Check cooldown
                if not heroAbil.isCooldownReady(difficulty) then
                    call BotLog("Ability cooldown not ready for combo: " + heroAbil.orderString)
                    call aiHero.setDebugTextTagContent("Combat: Combo CD Not Ready " + heroAbil.orderString)
                    call aiHero.setDebugTextTagColorPreset("RED")
                    return 0
                endif
                
                // Check if ability is available
                if GetUnitAbilityLevel(hero, heroAbil.abilityId) <= 0 then
                    call BotLogError("Ability not available for combo: " + heroAbil.orderString)
                    return 0
                endif
                
                if i == aiHero.currentComboIndex then
                    set resultComboAbility = heroAbil
                    call BotLog("Found ready combo ability at comboIndex " + I2S(i) + ": " + heroAbil.orderString)
                    call aiHero.setDebugTextTagContent("Combat: Found Combo Ability " + heroAbil.orderString)
                    call aiHero.setDebugTextTagColorPreset("RED")
                endif
                set i = i + 1
            endloop

            if not this.hasEnoughManaForCombo(hero, startingComboIndex) then
                call BotLog("Not enough mana for remaining combo abilities from index " + I2S(startingComboIndex))
                return 0
            endif

            call BotLog("Combo abilities ready, returning ability: " + resultComboAbility.orderString)
            call aiHero.setDebugTextTagContent("Combat: Combo Ability Ready " + resultComboAbility.orderString)
            call aiHero.setDebugTextTagColorPreset("RED")

            return resultComboAbility
        endmethod

        method hasEnoughManaForCombo takes unit hero, integer currentComboIndex returns boolean
            local real currentMana = GetUnitState(hero, UNIT_STATE_MANA)
            local real requiredMana = 0.0
            local integer i = currentComboIndex
            local HeroAbility heroAbil
            local AIHero aiHero = GetAIHeroFromUnit(hero)
            
            // Calculate mana cost for remaining combo abilities from currentComboIndex
            loop
                set heroAbil = this.getAbilityByComboIndex(i)
                // Reach end of combo sequence
                exitwhen heroAbil == 0
                
                set requiredMana = requiredMana + heroAbil.manaCost
                set i = i + 1
            endloop
            
            if currentMana >= requiredMana then
                return true
            endif
            call BotLog("Not enough mana for remaining combo. (" + I2S(R2I(currentMana)) + "/" + I2S(R2I(requiredMana)) + ")")
            call aiHero.setDebugTextTagContent("Combat: No Mana, (" + I2S(R2I(currentMana)) + "/" + I2S(R2I(requiredMana)) + ")")
            call aiHero.setDebugTextTagColorPreset("RED")
            return false
        endmethod

        method areComboAbilityCooldownReady takes unit hero, integer difficulty, integer currentComboIndex returns boolean
            local integer i = currentComboIndex
            local HeroAbility heroAbil
            
            // Check if combo abilities have their cooldowns ready (starting from currentComboIndex)
            loop
                set heroAbil = this.getAbilityByComboIndex(i)
                // Reach end of combo sequence
                exitwhen heroAbil == 0
                
                // Check cooldown
                if not heroAbil.isCooldownReady(difficulty) then
                    return false
                endif
                
                // Check if ability is available
                if GetUnitAbilityLevel(hero, heroAbil.abilityId) <= 0 then
                    return false
                endif
                
                set i = i + 1
            endloop
            
            // All remaining combo abilities have cooldowns ready
            return true
        endmethod

    endstruct


    struct AIState 
        integer stateID
        AIHero owner
        
        method botLog takes string msg returns nothing
            call BotLogWithPlayer(GetOwningPlayer(owner.hero), msg)
        endmethod
        
        method botLogError takes string msg returns nothing
            call BotLogErrorWithPlayer(GetOwningPlayer(owner.hero), msg)
        endmethod
        
        stub method onEnter takes nothing returns nothing
            // Placeholder for state entry logic
        endmethod
        stub method onUpdate takes nothing returns nothing
            // Placeholder for timer callbackj
        endmethod
        stub method onExit takes nothing returns nothing
            // Placeholder for state exit logic
        endmethod

        stub method destroy takes nothing returns nothing
            call this.deallocate()
        endmethod
    endstruct

    struct RunState extends AIState
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.stateID = STATE_RUN
            return this
        endmethod

        method onEnter takes nothing returns nothing
            local rect currentWaypointArea
            local real x
            local real y

            call this.botLog("Entering Run State")
            call owner.setDebugTextTagContent("Run: Entering")
            call owner.setDebugTextTagColorPreset("GREEN")

            set currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
            set x = GetRandomReal(GetRectMinX(currentWaypointArea), GetRectMaxX(currentWaypointArea))
            set y = GetRandomReal(GetRectMinY(currentWaypointArea), GetRectMaxY(currentWaypointArea))
            call IssuePointOrder(owner.hero, "move", x, y)
            
            set currentWaypointArea = null
        endmethod

        method onUpdate takes nothing returns nothing
            local rect currentWaypointArea 
            local real heroX 
            local real heroY 
            local real targetX
            local real targetY
            local integer currentOrder
            
            // Safety check - ensure hero is alive
            if not IsUnitAliveBJ(owner.hero) then
                return
            endif
            
            call this.botLog("Updating Run State, waypoint index: " + I2S(owner.currentWaypointIndex))
            call owner.setDebugTextTagContent("Run: Updating, WPI " + I2S(owner.currentWaypointIndex))
            call owner.setDebugTextTagColorPreset("GREEN")
            
            
            set currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
            set heroX = GetUnitX(owner.hero)
            set heroY = GetUnitY(owner.hero)
            set currentOrder = GetUnitCurrentOrder(owner.hero)
            
            // Check if hero has reached the current waypoint area
            if RectContainsCoords(currentWaypointArea, heroX, heroY) then
                call this.botLog("Reached waypoint " + I2S(owner.currentWaypointIndex))
                call owner.setDebugTextTagContent("Run: Reached Waypoint " + I2S(owner.currentWaypointIndex))
                call owner.setDebugTextTagColorPreset("GREEN")
                if owner.currentWaypointIndex >= WaypointCount then
                    call this.botLog("Reached final waypoint")
                    call owner.setDebugTextTagContent("Run: Reached Final Waypoint")
                    call owner.setDebugTextTagColorPreset("GREEN")
                    // TODO Goaled State
                else
                    // Move to next waypoint
                    set owner.currentWaypointIndex = (owner.currentWaypointIndex + 1)
                endif
                
                // Move to the new waypoint
                set currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
                set targetX = GetRandomReal(GetRectMinX(currentWaypointArea), GetRectMaxX(currentWaypointArea))
                set targetY = GetRandomReal(GetRectMinY(currentWaypointArea), GetRectMaxY(currentWaypointArea))
                call IssuePointOrder(owner.hero, "move", targetX, targetY)
            elseif currentOrder == 0 then
                // Hero is idle (no current order) - reissue move command to current waypoint
                call this.botLog("Hero is idle, reissuing move command")
                call owner.setDebugTextTagContent("Run: Reissuing Move Command")
                call owner.setDebugTextTagColorPreset("GREEN")
                set targetX = GetRandomReal(GetRectMinX(currentWaypointArea), GetRectMaxX(currentWaypointArea))
                set targetY = GetRandomReal(GetRectMinY(currentWaypointArea), GetRectMaxY(currentWaypointArea))
                call IssuePointOrder(owner.hero, "move", targetX, targetY)
            endif
            
            // Check for spike hazards first (highest priority, only between waypoints 7-8)
            if owner.shouldEnterHazardState() then
                call this.botLog("Spike hazard detected - entering spike dodge state")
                call owner.changeState(HazardState.create())
                return
            endif
            
            // Check if we should enter combat state
            if owner.shouldEnterCombat() then
                call this.botLog("Entering combat - abilities ready")
                call owner.setDebugTextTagContent("Run: Entering Combat")
                call owner.setDebugTextTagColorPreset("GREEN")
                call owner.changeState(CombatState.create())
                return
            endif

            set currentWaypointArea = null
        endmethod

        method onExit takes nothing returns nothing
            call this.botLog("Exiting Run State")
            call owner.setDebugTextTagContent("Run: Exiting")
            call owner.setDebugTextTagColorPreset("GREEN")
        endmethod
    endstruct

    struct DeadState extends AIState
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.stateID = STATE_DEAD
            return this
        endmethod

        method onEnter takes nothing returns nothing
            call this.botLog("Hero died - Entering Dead State")
            call owner.setDebugTextTagContent("Dead: Entering")
            call owner.setDebugTextTagColorPreset("GRAY")
            call IssueImmediateOrder(owner.hero, "stop")
        endmethod

        method onUpdate takes nothing returns nothing
            if not IsUnitAliveBJ(owner.hero) then
                return
            endif
            
            call this.botLog("Hero revived - Returning to Run State")
            call owner.setDebugTextTagContent("Dead: Revived")
            call owner.setDebugTextTagColorPreset("GRAY")
            call owner.changeState(RunState.create())
        endmethod

        method onExit takes nothing returns nothing
            call this.botLog("Exiting Dead State")
            call owner.setDebugTextTagContent("Dead: Exiting")
            call owner.setDebugTextTagColorPreset("GRAY")
        endmethod
    endstruct

    struct HazardState extends AIState
        integer hazardType  // 0 = Spike, 1 = Net, etc.

        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.stateID = STATE_HAZARD
            return this
        endmethod

        method onEnter takes nothing returns nothing
            if isInSlowSpikeHazardZone(owner) then
                set this.hazardType = HAZARD_TYPE_SLOW_SPIKE
                call this.botLog("Detected Slow Spike Hazard Zone")
                call owner.setDebugTextTagContent("Hazard: Slow Spike Detected")
                call owner.setDebugTextTagColorPreset("ORANGE")
            else
                // Other hazard types can be added here
                call this.botLogError("Unknown hazard type detected!")
            endif
        endmethod
        
        method onUpdate takes nothing returns nothing
            if not IsUnitAliveBJ(owner.hero) then
                return
            endif
            if this.hazardType == HAZARD_TYPE_SLOW_SPIKE then
                call this.onSlowSpikeHazardZoneUpdate()
            endif
        endmethod
        
        method onSlowSpikeHazardZoneUpdate takes nothing returns nothing
            local real heroX = GetUnitX(owner.hero)
            local real heroY = GetUnitY(owner.hero)
            call this.botLog("onSlowSpikeHazardZoneUpdate - Hero Position: (" + R2S(heroX) + ", " + R2S(heroY) + ")")
        endmethod

        method onExit takes nothing returns nothing
            call this.botLog("Exiting Slow Spike Hazard State")
            call owner.setDebugTextTagContent("Hazard: Slow Spike Exiting")
            call owner.setDebugTextTagColorPreset("ORANGE")
        endmethod

        method isInSlowSpikeHazardZone takes AIHero aiHero returns boolean
            local integer wpi = aiHero.currentWaypointIndex
            if wpi == 8 then
                return true
            endif
            return false
        endmethod

    endstruct

    struct CombatState extends AIState
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.stateID = STATE_COMBAT
            return this
        endmethod

        method onEnter takes nothing returns nothing
            call this.botLog("Entering Combat State")
            call owner.setDebugTextTagContent("Combat: Entering")
            call owner.setDebugTextTagColorPreset("RED")
        endmethod

        method onUpdate takes nothing returns nothing
            local real currentTime = TimerGetElapsed(gameTimer)
            local integer difficulty = owner.difficulty
            local boolean isCastOvertime = currentTime > owner.lastStartCastTime + owner.castPt + TURN_TIME // Turn Time and Pre-swing 
            local boolean isCastFailed = owner.isCasting and isCastOvertime

            if isCastFailed then
                call this.botLog("Casting failed or interrupted, resetting casting state")
                call owner.setDebugTextTagContent("Combat: Cast Failed " + owner.castingAbility.orderString)
                call owner.setDebugTextTagColorPreset("RED")
                set owner.isCasting = false
                set owner.castingAbility = 0
            endif

            if owner.isCasting then
                call this.botLog("Currently casting an ability, skipping update")
                call owner.setDebugTextTagContent("Combat: Casting " + owner.castingAbility.orderString)
                call owner.setDebugTextTagColorPreset("RED")
                return
            endif

            // Safety check - ensure hero is alive
            if not IsUnitAliveBJ(owner.hero) then
                return
            endif
            
            if difficulty == DIFF_EASY then
                if this.tryExecuteEasyCombat() then
                    // Successfully cast an ability
                    return
                endif
            elseif difficulty == DIFF_NORMAL then
                if this.tryExecuteNormalCombat() then
                    // Successfully cast an ability
                    return
                endif
            else // HARD
                if this.tryExecuteHardCombat() then
                    // Successfully cast an ability
                    return
                endif
            endif
            
            // Return to run state after combat
            call owner.changeState(RunState.create())
        endmethod

        method tryExecuteEasyCombat takes nothing returns boolean
            local integer i = 0
            local HeroAbility heroAbil
            local real currentTime = TimerGetElapsed(gameTimer)
            local integer difficulty = owner.difficulty
            
            // Cast first available ability with 2x cooldown spacing
            set heroAbil = owner.combatData.getReadyAbility(owner.hero, difficulty)
            if heroAbil != null then
                if this.tryCastAbility(heroAbil) then
                    set owner.isCasting = true
                    set owner.castingAbility = heroAbil
                    set owner.lastStartCastTime = currentTime
                    return true
                endif
            endif
            return false
        endmethod

        method tryExecuteNormalCombat takes nothing returns boolean
            return this.tryExecuteEasyCombat()
        endmethod

        method tryExecuteHardCombat takes nothing returns boolean
            // Advanced combat with countering - implement specific logic as needed
            return this.tryExecuteNormalCombat()  // For now, use normal combat
            // TODO: Add counter-casting logic based on enemy states
        endmethod

        method canCastAbility takes HeroAbility heroAbil returns boolean
            // Check if hero is stunned or silenced
            if IsUnitStunOrSilence(owner.hero) then
                call BotLog("Cannot cast ability, hero is stunned or silenced.")
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Stunned/Silenced")
                call owner.setDebugTextTagColorPreset("YELLOW")
                return false
            endif

            // Check if ability is available
            if GetUnitAbilityLevel(owner.hero, heroAbil.abilityId) <= 0 then
                call BotLogError("Ability not available: " + heroAbil.orderString)
                return false
            endif
            
            // Check if hero has enough mana
            if not heroAbil.isManaReady(owner.hero) then
                call BotLog("Not enough mana for ability: " + heroAbil.orderString)
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Not Enough Mana")
                call owner.setDebugTextTagColorPreset("RED")
                return false
            endif
            
            return true
        endmethod

        method shouldUpdateComboTarget takes HeroAbility heroAbil, unit targetUnit returns boolean
            if not IsApplyingCombo(owner.difficulty) then
                return false
            endif
            
            if heroAbil.comboIndex <= 0 then
                return false
            endif
            
            if owner.comboTargetUnit == targetUnit then
                return false
            endif
            
            return true
        endmethod

        method findTargetForAbility takes HeroAbility heroAbil returns unit
            local unit targetUnit = null
            
            // Check if we should use existing combo target
            if IsApplyingCombo(owner.difficulty) and owner.comboTargetUnit != null and heroAbil.comboIndex > 0 then
                set targetUnit = owner.comboTargetUnit
                call BotLog("Using existing combo target: " + GetUnitName(targetUnit))
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Using Combo Target " + GetUnitName(targetUnit))
                call owner.setDebugTextTagColorPreset("RED")
                return targetUnit
            endif
            
            // Find new target based on ability type
            if heroAbil.allowTargetType == ALLOW_TARGET_TYPE_ENEMY_HERO then
                // Use smart combo targeting for combo abilities, random for others
                if IsApplyingCombo(owner.difficulty) and heroAbil.comboIndex > 0 then
                    set targetUnit = this.findBestComboTarget(heroAbil.castRange, heroAbil)
                    call BotLog("Finding best combo target, result: " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Combo Target " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagColorPreset("RED")
                else
                    set targetUnit = this.findRandomEnemyHeroInRange(heroAbil.castRange, heroAbil)
                    call BotLog("Finding random enemy hero, result: " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Enemy Hero Target " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagColorPreset("RED")
                endif
            elseif heroAbil.allowTargetType == ALLOW_TARGET_TYPE_ALLY_HERO then
                set targetUnit = this.findRandomAllyHeroInRange(heroAbil.castRange, heroAbil)
                call BotLog("Finding ally hero target, result: " + GetUnitName(targetUnit))
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Ally Hero Target " + GetUnitName(targetUnit))
                call owner.setDebugTextTagColorPreset("RED")

            elseif heroAbil.allowTargetType == ALLOW_TARGET_TYPE_ENEMY_UNIT then
                // For simplicity, use enemy hero targeting for enemy units for now
                set targetUnit = this.findRandomEnemyHeroInRange(heroAbil.castRange, heroAbil)
                call BotLog("Finding enemy unit target, result: " + GetUnitName(targetUnit))
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Enemy Unit Target" + GetUnitName(targetUnit))
                call owner.setDebugTextTagColorPreset("RED")
            elseif heroAbil.allowTargetType == ALLOW_TARGET_TYPE_ALLY_UNIT then
                // For simplicity, use ally hero targeting for ally units for now
                set targetUnit = this.findRandomAllyHeroInRange(heroAbil.castRange, heroAbil)
                call BotLog("Finding ally unit target, result: " + GetUnitName(targetUnit))
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Ally Unit Target " + GetUnitName(targetUnit))
                call owner.setDebugTextTagColorPreset("RED")
            else
                call BotLogError("Unsupported target type for ability: " + heroAbil.orderString)
                set targetUnit = null
            endif
            
            return targetUnit
        endmethod

        method castInstantAbility takes HeroAbility heroAbil returns boolean
            call IssueImmediateOrder(owner.hero, heroAbil.orderString)
            call this.botLog("Casting instant ability: " + heroAbil.orderString)
            return true
        endmethod

        method castPointAbility takes HeroAbility heroAbil, unit targetUnit returns boolean
            local real heroFacing
            local real offset
            local real targetX
            local real targetY
            
            if targetUnit == null then
                call BotLog("No target found for point ability: " + heroAbil.orderString)
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - No Target")
                call owner.setDebugTextTagColorPreset("RED")
                return false
            endif
            
            set heroFacing = GetUnitFacing(targetUnit) * bj_DEGTORAD
            set offset = heroAbil.effectiveRadius
            set targetX = GetUnitX(targetUnit) + offset * Cos(heroFacing)
            set targetY = GetUnitY(targetUnit) + offset * Sin(heroFacing) 
            call IssuePointOrder(owner.hero, heroAbil.orderString, targetX, targetY)
            call this.botLog("Casting point target ability in front: " + heroAbil.orderString)
            return true
        endmethod

        method castUnitAbility takes HeroAbility heroAbil, unit targetUnit returns boolean
            if targetUnit != null then
                call IssueTargetOrder(owner.hero, heroAbil.orderString, targetUnit)
                call this.botLog("Casting unit target ability: " + heroAbil.orderString)
                return true
            else
                call BotLog("No target found for unit ability: " + heroAbil.orderString)
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - No Target")
                call owner.setDebugTextTagColorPreset("RED")
                return false
            endif
        endmethod

        method tryCastAbility takes HeroAbility heroAbil returns boolean
            local unit targetUnit
            
            call BotLog("Attempting to cast ability: " + heroAbil.orderString)
            call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString)
            call owner.setDebugTextTagColorPreset("RED")
            
            if not this.canCastAbility(heroAbil) then
                return false
            endif
            
            // Handle instant abilities (no target needed)
            if heroAbil.castType == CAST_INSTANT then
                return this.castInstantAbility(heroAbil)
            endif
            
            // Find target for targeted abilities
            set targetUnit = this.findTargetForAbility(heroAbil)
            
            // Update combo target if needed
            if this.shouldUpdateComboTarget(heroAbil, targetUnit) then
                set owner.comboTargetUnit = targetUnit
            endif
            
            // Execute cast based on type
            if heroAbil.castType == CAST_POINT_ENEMY_FRONT then
                return this.castPointAbility(heroAbil, targetUnit)
            elseif heroAbil.castType == CAST_UNIT then
                return this.castUnitAbility(heroAbil, targetUnit)
            else
                call BotLogError("Unsupported cast type for ability: " + heroAbil.orderString)
                return false
            endif
        endmethod

        method findNearestEnemy takes nothing returns unit
            // Simple implementation - find first enemy in range
            // TODO: Implement proper enemy detection based on your map's enemy system
            return null  // Placeholder - replace with actual enemy finding logic
        endmethod

        method findRandomHeroInRange takes real range, boolean isForAllies, HeroAbility heroAbil returns unit
            local group heroes = CreateGroup()
            local unit randomHero
            
            // Set temp variables for filter function
            set tempHeroOwner = GetOwningPlayer(owner.hero)
            set bTempFilterForAllies = isForAllies
            set tempHeroUnit = owner.hero
            set tempHeroAbility = heroAbil
            
            call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterHeroes))
            set randomHero = GroupPickRandomUnit(heroes)
            
            // Clean up
            set tempHeroAbility = 0
            call DestroyGroup(heroes)
            set heroes = null
            
            return randomHero
        endmethod

        method findRandomEnemyHeroInRange takes real range, HeroAbility heroAbil returns unit
            return this.findRandomHeroInRange(range, false, heroAbil)
        endmethod
        
        method findRandomAllyHeroInRange takes real range, HeroAbility heroAbil returns unit
            return this.findRandomHeroInRange(range, true, heroAbil)
        endmethod

        method evaluateComboTarget takes unit currentUnit, unit bestTarget, real bestTargetHp, boolean bestIsKillableTarget, boolean bestIsStunOrSlow, real comboExpectedDamage, real comboMinThreshold returns unit
            local real currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)
            local boolean isKillableTarget
            local boolean isStunOrSlow
            
            if currentHp >= comboMinThreshold then
                set isKillableTarget = (currentHp <= comboExpectedDamage)
                set isStunOrSlow = IsUnitStunOrSlow(currentUnit)
            
                if bestTarget == null then
                    return currentUnit
                elseif isStunOrSlow and not bestIsStunOrSlow then
                    return currentUnit
                elseif (isStunOrSlow == bestIsStunOrSlow) then
                    if isKillableTarget and not bestIsKillableTarget then
                        return currentUnit
                    elseif isKillableTarget and bestIsKillableTarget and currentHp > bestTargetHp then
                        return currentUnit
                    elseif not isKillableTarget and not bestIsKillableTarget and currentHp < bestTargetHp then
                        return currentUnit
                    endif
                endif
            endif
            return bestTarget
        endmethod

        method findBestComboTarget takes real range, HeroAbility heroAbil returns unit
            local group heroes = CreateGroup()
            local unit currentUnit = null
            local unit bestTarget = null
            local real currentHp
            local real maxHp
            local real bestTargetHp = 0.0
            local boolean bestIsKillableTarget = false
            local boolean bestIsStunOrSlow = false
            local real comboExpectedDamage = owner.combatData.comboExpectedDamage
            local real comboMinThreshold = comboExpectedDamage * owner.combatData.comboOverkillThresholdPercent
            
            // Set temp variables for filter function
            set tempHeroOwner = GetOwningPlayer(owner.hero)
            set bTempFilterForAllies = false
            set tempHeroUnit = owner.hero
            set tempHeroAbility = heroAbil
            call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterHeroes))
            
            // Iterate through filtered enemies to find best target
            loop
                set currentUnit = FirstOfGroup(heroes)
                exitwhen currentUnit == null
                call GroupRemoveUnit(heroes, currentUnit)
                
                set currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)
                set maxHp = GetUnitState(currentUnit, UNIT_STATE_MAX_LIFE)
                
                //  Current Priority Order:                                                                                     
                // 1. Avoid Overkill 
                // 2. Prioritize Stunned/Slowed
                // 3. Secure Kills
                // 4. Minimize Overkill Among Kills
                // 5. Damage Efficiency
                // 6. Fallback to Overkill

                set bestTarget = this.evaluateComboTarget(currentUnit, bestTarget, bestTargetHp, bestIsKillableTarget, bestIsStunOrSlow, comboExpectedDamage, comboMinThreshold)
                if bestTarget == currentUnit then
                    set bestTargetHp = currentHp
                    set bestIsKillableTarget = (currentHp <= comboExpectedDamage)
                    set bestIsStunOrSlow = IsUnitStunOrSlow(currentUnit)
                endif

            endloop
            
            // Clean up
            call DestroyGroup(heroes)
            set heroes = null
            set currentUnit = null
            
            if bestTarget != null then
                // Log selected target details
                if bestIsKillableTarget then
                    if bestIsStunOrSlow then
                        call BotLog("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Killable:1 Stun/Slow:1")
                        call owner.setDebugTextTagContent("Combat: Combo Target: " + GetUnitName(bestTarget) + "(HP:" + R2S(bestTargetHp) + " Killable:1 Stun/Slow:1)")
                        call owner.setDebugTextTagColorPreset("RED")
                    else
                        call BotLog("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Killable:1 Stun/Slow:0")
                        call owner.setDebugTextTagContent("Combat: Combo Target: " + GetUnitName(bestTarget) + "(HP:" + R2S(bestTargetHp) + " Killable:1 Stun/Slow:0)")
                        call owner.setDebugTextTagColorPreset("RED")
                    endif
                else
                    if bestIsStunOrSlow then
                        call BotLog("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Killable:0 Stun/Slow:1")
                        call owner.setDebugTextTagContent("Combat: Combo Target: " + GetUnitName(bestTarget) + "(HP:" + R2S(bestTargetHp) + " Killable:0 Stun/Slow:1)")
                        call owner.setDebugTextTagColorPreset("RED")
                    else
                        call BotLog("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Killable:0 Stun/Slow:0")
                        call owner.setDebugTextTagContent("Combat: Combo Target: " + GetUnitName(bestTarget) + "(HP:" + R2S(bestTargetHp) + " Killable:0 Stun/Slow:0)")
                    endif
                endif
            else
                set bestTarget = this.findFallbackComboTarget(range, heroAbil)
            endif
            
            set tempHeroAbility = 0            
            return bestTarget
        endmethod

        method findFallbackComboTarget takes real range, HeroAbility heroAbil returns unit
            local group heroes = CreateGroup()
            local unit currentUnit = null
            local unit bestTarget = null
            local real bestTargetHp = 0.0
            local real currentHp
            
            call BotLog("No suitable combo target found, trying fallback to overkill targets")
            
            set tempHeroOwner = GetOwningPlayer(owner.hero)
            set bTempFilterForAllies = false
            set tempHeroUnit = owner.hero
            set tempHeroAbility = heroAbil
            call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterHeroes))
            
            loop
                set currentUnit = FirstOfGroup(heroes)
                exitwhen currentUnit == null
                call GroupRemoveUnit(heroes, currentUnit)
                
                set currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)
                
                if bestTarget == null or currentHp > bestTargetHp then
                    set bestTarget = currentUnit
                    set bestTargetHp = currentHp
                endif
            endloop
            
            call DestroyGroup(heroes)
            set heroes = null
            set tempHeroAbility = 0
            
            if bestTarget != null then
                call BotLog("Fallback combo target selected: " + GetUnitName(bestTarget))
                call owner.setDebugTextTagContent("Combat: Combo Target (Overkill): " + GetUnitName(bestTarget))
                call owner.setDebugTextTagColorPreset("RED")
            else
                call BotLog("No combo targets found at all")
                call owner.setDebugTextTagContent("Combat: No Combo Target")
                call owner.setDebugTextTagColorPreset("RED")
            endif
            
            return bestTarget
        endmethod

        method onExit takes nothing returns nothing
            call this.botLog("Exiting Combat State")
            call owner.setDebugTextTagContent("Combat: Exit")
            call owner.setDebugTextTagColorPreset("RED")
        endmethod
    endstruct


    struct AIHero
        unit hero
        integer difficulty
        real castPt
        AIState currentState
        integer currentWaypointIndex
        HeroCombatData combatData
        real lastStartCastTime
        boolean isCasting
        HeroAbility castingAbility
        timer updateTimer
        integer currentComboIndex
        unit comboTargetUnit
        texttag debugTextTag
        string debugTextTagContent
        timer debugTextTagTimer
        
        // Constructor
        static method create takes unit u, integer inDifficulty returns thistype
            local thistype this = thistype.allocate()
            set this.updateTimer = CreateTimer()
            set this.hero = u
            set this.difficulty = inDifficulty
            set this.castPt = GetHeroCastPoint(GetUnitTypeId(u))
            set this.currentState = 0
            set this.currentWaypointIndex = 7
            set this.lastStartCastTime = 0.0
            set this.isCasting = false
            set this.castingAbility = 0
            set this.currentComboIndex = 1 // only for difficulty HARD and above
            set this.comboTargetUnit = null
            set this.debugTextTag = null
            set this.debugTextTagContent = ""


            // Initialize combat data
            set this.combatData = InitializeHeroCombatData(u, inDifficulty)

            call this.changeState(RunState.create())

            
            // Start the loop
            call SaveInteger(udg_TimerHeroMap, GetHandleId(this.updateTimer), 0, this)
            call TimerStart(this.updateTimer, UPDATE_PERIOD, true, function thistype.onUpdate)
            
            // Store unit to AIHero mapping
            call SaveInteger(udg_UnitAIHeroMap, GetHandleId(this.hero), 0, this)
            if udg_bEnableBotTextTag then
                call this.createDebugTextTag()
            endif

            return this
        endmethod

        method shouldEnterCombat takes nothing returns boolean
            local integer i = 0
            local HeroAbility heroAbil
            local real currentMana
            local boolean hasReadyAbility = false

            if IsUnitStunOrSilence(this.hero) then
                call BotLog("Cannot enter combat, hero is stunned or silenced.")
                call this.setDebugTextTagContent("Run: Stunned/Silenced")
                call this.setDebugTextTagColorPreset("YELLOW")
                return false
            endif

            set hasReadyAbility = this.combatData.hasReadyAbility(this.hero, this.difficulty)
            if hasReadyAbility then
                return true
            endif
            return false
        endmethod

        method changeState takes AIState newState returns nothing
            if this.currentState != null then
                call this.currentState.onExit()
                call this.currentState.destroy()
            endif
            set this.currentState = newState
            set this.currentState.owner = this
            call this.currentState.onEnter()
        endmethod

        method botLog takes string msg returns nothing
            call BotLogWithPlayer(GetOwningPlayer(this.hero), msg)
        endmethod
        
        method botLogError takes string msg returns nothing
            call BotLogErrorWithPlayer(GetOwningPlayer(this.hero), msg)
        endmethod
        
        method shouldEnterHazardState takes nothing returns boolean
            // Only check for slow spikes waypoints  8
            if this.currentWaypointIndex != 8 then
                return false
            endif
            
            return true
        endmethod

        method destroy takes nothing returns nothing
            // Clean up combat data
            if this.combatData != null then
                call this.combatData.destroy()
                set this.combatData = 0
            endif
            
            // Clean up current state
            if this.currentState != null then
                call this.currentState.destroy()
                set this.currentState = 0
            endif
            
            // Clean up timer
            if this.updateTimer != null then
                call RemoveSavedInteger(udg_TimerHeroMap, GetHandleId(this.updateTimer), 0)
                call PauseTimer(this.updateTimer)
                call DestroyTimer(this.updateTimer)
                set this.updateTimer = null
            endif

            if this.debugTextTag != null then
                call this.destroyDebugTextTag()
            endif
            
            // Remove unit to AIHero mapping
            if this.hero != null then
                call RemoveSavedInteger(udg_UnitAIHeroMap, GetHandleId(this.hero), 0)
                call RemoveUnit(this.hero)
            endif

            // Nullify unit handle
            set this.hero = null
            
            call this.deallocate()
        endmethod

        static method onUpdate takes nothing returns nothing
            local thistype this = LoadInteger(udg_TimerHeroMap, GetHandleId(GetExpiredTimer()), 0)
            if this != null and this.currentState != null then
                // Check if hero died and transition to dead state if needed
                if not IsUnitAliveBJ(this.hero) and this.currentState.stateID != STATE_DEAD then
                    call this.changeState(DeadState.create())
                else
                    call this.currentState.onUpdate()
                endif
            endif

        endmethod

        method onCastComplete takes nothing returns nothing
            local real currentTime = TimerGetElapsed(gameTimer)
            local integer difficulty = this.difficulty
            set this.isCasting = false
            set this.castingAbility.lastCastTime = currentTime
            // Advance combo index if casting combo ability
            if IsApplyingCombo(difficulty) and this.castingAbility.comboIndex > 0 then
                set this.currentComboIndex = this.currentComboIndex + 1
                call this.botLog("Advancing combo index to: " + I2S(this.currentComboIndex))
                // If no further combo ability, reset combo index
                if this.combatData.getAbilityByComboIndex(this.currentComboIndex) == 0 then
                    set this.currentComboIndex = 1
                    set this.comboTargetUnit = null
                    call this.botLog("Combo sequence complete, resetting combo index to 1")
                endif
            endif

            call this.botLog("Casting complete for ability: " + this.castingAbility.orderString + ", current combo index: " + I2S(this.currentComboIndex))
            call this.setDebugTextTagContent("Combat: " + this.castingAbility.orderString + " done, CCI: " + I2S(this.currentComboIndex))
            call this.setDebugTextTagColorPreset("RED")
            set this.castingAbility = 0
        endmethod

        method createDebugTextTag takes nothing returns nothing
            set this.debugTextTag = CreateTextTag()
            set this.debugTextTagContent = "Bot"
            call setDebugTextTagContent(this.debugTextTagContent)
            call SetTextTagColorBJ(this.debugTextTag, 255, 255, 255, 0)
            call SetTextTagPos (this.debugTextTag, GetUnitX(this.hero) + this.calculateTextCenterOffset(), GetUnitY(this.hero) - 80.0, 0.0)
            call SetTextTagPermanent(this.debugTextTag, true)
            call SetTextTagSuspended(this.debugTextTag, true)
            call SetTextTagVisibility(this.debugTextTag, true)
            call SetTextTagFadepoint(this.debugTextTag, -1.0)

            set this.debugTextTagTimer = CreateTimer()
            call TimerStart(this.debugTextTagTimer, 0.03, true, function thistype.updateDebugTextTagPosition)
            call SaveInteger(udg_DebugTextTagTimerHeroMap, GetHandleId(this.debugTextTagTimer), 0, this)
        endmethod

        static method updateDebugTextTagPosition takes nothing returns nothing
            local thistype this = LoadInteger(udg_DebugTextTagTimerHeroMap, GetHandleId(GetExpiredTimer()), 0)
            if this.debugTextTag != null then
                call SetTextTagPos(this.debugTextTag, GetUnitX(this.hero) + this.calculateTextCenterOffset(), GetUnitY(this.hero) - 80.0, 0.0)
            endif
        endmethod

        method setDebugTextTagContent takes string content returns nothing
            set this.debugTextTagContent = content
            if this.debugTextTag != null then
                call SetTextTagTextBJ(this.debugTextTag, this.debugTextTagContent, 8.0)
            endif
        endmethod

        method calculateTextCenterOffset takes nothing returns real
            local integer stringLength = StringLength(this.debugTextTagContent)
            local real characterWidth = 65.0  // Approximate character width in Warcraft III units
            return - (stringLength * characterWidth) / 5.3
        endmethod

        method setDebugTextTagColor takes real r, real g, real b, real a returns nothing
            if this.debugTextTag != null then
                call SetTextTagColorBJ(this.debugTextTag, r, g, b, a)
            endif
        endmethod

        method setDebugTextTagColorPreset takes string colorName returns nothing
            local integer alpha = 0
            if colorName == "WHITE" then
                call this.setDebugTextTagColor(COLOR_WHITE_R, COLOR_WHITE_G, COLOR_WHITE_B, alpha)
            elseif colorName == "RED" then
                call this.setDebugTextTagColor(COLOR_RED_R, COLOR_RED_G, COLOR_RED_B, alpha)
            elseif colorName == "GREEN" then
                call this.setDebugTextTagColor(COLOR_GREEN_R, COLOR_GREEN_G, COLOR_GREEN_B, alpha)
            elseif colorName == "BLUE" then
                call this.setDebugTextTagColor(COLOR_BLUE_R, COLOR_BLUE_G, COLOR_BLUE_B, alpha)
            elseif colorName == "YELLOW" then
                call this.setDebugTextTagColor(COLOR_YELLOW_R, COLOR_YELLOW_G, COLOR_YELLOW_B, alpha)
            elseif colorName == "ORANGE" then
                call this.setDebugTextTagColor(COLOR_ORANGE_R, COLOR_ORANGE_G, COLOR_ORANGE_B, alpha)
            elseif colorName == "PURPLE" then
                call this.setDebugTextTagColor(COLOR_PURPLE_R, COLOR_PURPLE_G, COLOR_PURPLE_B, alpha)
            elseif colorName == "CYAN" then
                call this.setDebugTextTagColor(COLOR_CYAN_R, COLOR_CYAN_G, COLOR_CYAN_B, alpha)
            elseif colorName == "PINK" then
                call this.setDebugTextTagColor(COLOR_PINK_R, COLOR_PINK_G, COLOR_PINK_B, alpha)
            elseif colorName == "GRAY" then
                call this.setDebugTextTagColor(COLOR_GRAY_R, COLOR_GRAY_G, COLOR_GRAY_B, alpha)
            else
                call BotLogError("Unknown color preset: " + colorName)
                call this.setDebugTextTagColor(COLOR_WHITE_R, COLOR_WHITE_G, COLOR_WHITE_B, alpha)
            endif
        endmethod

        method destroyDebugTextTag takes nothing returns nothing
            if this.debugTextTag != null then
                call SetTextTagVisibility(this.debugTextTag, false)
                set this.debugTextTag = null
            endif
        endmethod
    endstruct

    // This module ensures our initialization functions are called when the map loads.
    private module Initializer
        private static method onInit takes nothing returns nothing
            set udg_TimerHeroMap = InitHashtable()
            set udg_DebugTextTagTimerHeroMap = InitHashtable()
            set udg_UnitAIHeroMap = InitHashtable()
            set heroCastPointMap = InitHashtable()
            set gameTimer = CreateTimer()
            call TimerStart(gameTimer, 999999.0, false, null)
            call InitializeHeroCastPoints()
            call InitializeWaypoints()
        endmethod
    endmodule

    // We use a dummy struct to attach the initializer module to the library.
    private struct Init extends array
        implement Initializer
    endstruct
  
endlibrary