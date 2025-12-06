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
        
        // Settings
        constant real HEAL_THRESHOLD = 0.40 // 40% HP
        constant real UPDATE_PERIOD = 0.30
        
        // Combat settings
        // constant real EASY_CD_MULTIPLIER = 2.0
        constant real EASY_CD_MULTIPLIER = 1.0
        constant real NORMAL_CD_MULTIPLIER = 1.0
        constant real HARD_CD_MULTIPLIER = 1.0
        constant integer MAX_ABILITIES_PER_HERO = 7
        
        // Timer to AIHero mapping
        public hashtable udg_TimerHeroMap
        
        // Unit to AIHero mapping
        public hashtable udg_UnitAIHeroMap
        
        // Global timer for tracking game time
        public timer gameTimer
        
        // Hero cast point mapping by unit type
        public hashtable heroCastPointMap
        
        // Temporary variables for filtering heroes
        private player tempHeroOwner
        private boolean bTempFilterForAllies
        private unit tempHeroUnit

        // The array to hold the waypoint regions.
        private rect array WaypointAreas
        // The actual number of waypoints initialized.
        public integer WaypointCount = 0

        // Turn time for 90 degree turns, giving turn rate 0.6
        constant real TURN_TIME = 0.2 

        constant real MAX_RANGE = 30000.0
    endglobals

    // Initialize hero cast points by unit type
    private function InitializeHeroCastPoints takes nothing returns nothing
        // Configure cast points for different hero types
        call SaveReal(heroCastPointMap, 'H009', 0, 0.2)  // BloodMage
        // call SaveReal(heroCastPointMap, 'Hmkg', 0, 0.3)  // Mountain King  
        // TODO: Add more hero types as needed
    endfunction

    function GetHeroCastPoint takes integer heroTypeId returns real
        if HaveSavedReal(heroCastPointMap, heroTypeId, 0) then
            return LoadReal(heroCastPointMap, heroTypeId, 0)
        else
            call BJDebugMsg("Unknown hero type for GetHeroCastPoint: " + I2S(heroTypeId))
            return 0.5  // Default cast point for unknown hero types
        endif
    endfunction

    // Generic filter function for heroes (enemies or allies)
    function FilterHeroes takes nothing returns boolean
        local unit filterUnit = GetFilterUnit()
        
        // Check if unit is alive
        if not IsUnitAliveBJ(filterUnit) then
            set filterUnit = null
            return false
        endif
        
        // Check if unit is hero
        if not IsUnitType(filterUnit, UNIT_TYPE_HERO) then
            set filterUnit = null
            return false
        endif

        if not IsUnitVisible(filterUnit, tempHeroOwner) then
            set filterUnit = null
            return false
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
        set WaypointAreas[7] = gg_rct_AIWayPointArea07 // Before Slow Knife Hazard
        set WaypointAreas[8] = gg_rct_AIWayPointArea08 // After Slow Knife Hazard
        set WaypointAreas[9] = gg_rct_AIWayPointArea09 // Before Fast Knife Hazard
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

        static method create takes integer aid, real cd, integer inCastType, string order, integer mana, real inCastRange, integer inAllowTargetType, real inEffectiveRadius returns thistype
            local thistype this = thistype.allocate()
            set this.abilityId = aid
            set this.baseCooldown = cd
            set this.castType = inCastType
            set this.lastCastTime = 0.0
            set this.comboIndex = 0
            set this.orderString = order
            set this.manaCost = mana
            set this.castRange = inCastRange
            set this.allowTargetType = inAllowTargetType
            set this.effectiveRadius = inEffectiveRadius
            return this
        endmethod
        
        method destroy takes nothing returns nothing
            call this.deallocate()
        endmethod
    endstruct

    struct HeroCombatData
        HeroAbility array abilities[MAX_ABILITIES_PER_HERO]
        integer abilityCount
        real nextCombatTime
        
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.abilityCount = 0
            set this.nextCombatTime = 0.0
            return this
        endmethod
        
        method addAbility takes integer abilityId, real cooldown, integer castType, string orderString, integer manaCost, real castRange, integer allowTargetType, real effectiveRadius returns nothing
            if this.abilityCount < MAX_ABILITIES_PER_HERO then
                set this.abilities[this.abilityCount] = HeroAbility.create(abilityId, cooldown, castType, orderString, manaCost, castRange, allowTargetType, effectiveRadius)
                set this.abilityCount = this.abilityCount + 1
            else
                // Exceeded max abilities - handle error as needed
                call BJDebugMsg("Error: Exceeded max abilities for hero combat data.")
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
    endstruct

    // Helper function to get cooldown multiplier based on difficulty
    function GetCooldownMultiplier takes integer difficulty returns real
        if difficulty == DIFF_EASY then
            return EASY_CD_MULTIPLIER
        elseif difficulty == DIFF_NORMAL then
            return NORMAL_CD_MULTIPLIER
        else
            return HARD_CD_MULTIPLIER
        endif
    endfunction

    // Initialize hero-specific abilities (extend this function for different heroes)
    function InitializeHeroCombatData takes unit hero, integer difficulty returns HeroCombatData
        local HeroCombatData data = HeroCombatData.create()
        local integer heroTypeId = GetUnitTypeId(hero)

        
        // Example: Add abilities based on hero type
        if heroTypeId == 'H009' then  // BloodMage example
            call BJDebugMsg("Adding abilities for BloodMage")
            call data.addAbility('A00S', 22.0, CAST_POINT_ENEMY_FRONT, "flamestrike", 70, MAX_RANGE, ALLOW_TARGET_TYPE_NONE, 200)   // Flame Strike
            call data.addAbility('A00W', 22.0, CAST_UNIT, "banish", 40, MAX_RANGE, ALLOW_TARGET_TYPE_ENEMY_HERO, 0)   // Banish
            call data.addAbility('A01N', 47.0, CAST_UNIT, "bloodlust", 50, 2500, ALLOW_TARGET_TYPE_ALLY_HERO, 0)       // Blood Lust
        elseif heroTypeId == 'Hmkg' then  // Mountain King example
            call data.addAbility('AHtc', 6.0, CAST_UNIT, "thunderclap", 75, 250, ALLOW_TARGET_TYPE_ENEMY_UNIT, 0)      // Thunder Clap
            call data.addAbility('AHbh', 10.0, CAST_INSTANT, "bash", 0, 0, ALLOW_TARGET_TYPE_NONE, 0)          // Bash (passive)
            // Add more hero types as needed...
        endif
        
        return data
    endfunction

    struct AIState 
        integer stateID
        AIHero owner
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

            call BJDebugMsg("Entering Run State")
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
            
            call BJDebugMsg("Updating Run State, waypoint index: " + I2S(owner.currentWaypointIndex))
            
            
            set currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
            set heroX = GetUnitX(owner.hero)
            set heroY = GetUnitY(owner.hero)
            set currentOrder = GetUnitCurrentOrder(owner.hero)
            
            // Check if hero has reached the current waypoint area
            if RectContainsCoords(currentWaypointArea, heroX, heroY) then
                call BJDebugMsg("Reached waypoint " + I2S(owner.currentWaypointIndex))
                if owner.currentWaypointIndex >= WaypointCount then
                    call BJDebugMsg("Reached final waypoint")
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
                call BJDebugMsg("Hero is idle, reissuing move command")
                set targetX = GetRandomReal(GetRectMinX(currentWaypointArea), GetRectMaxX(currentWaypointArea))
                set targetY = GetRandomReal(GetRectMinY(currentWaypointArea), GetRectMaxY(currentWaypointArea))
                call IssuePointOrder(owner.hero, "move", targetX, targetY)
            endif
            
            // Check if we should enter combat state
            if owner.shouldEnterCombat() then
                call BJDebugMsg("Entering combat - abilities ready")
                call owner.changeState(CombatState.create())
                return
            endif

            set currentWaypointArea = null
        endmethod

        method onExit takes nothing returns nothing
            call BJDebugMsg("Exiting Run State")
        endmethod
    endstruct

    struct DeadState extends AIState
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.stateID = STATE_DEAD
            return this
        endmethod

        method onEnter takes nothing returns nothing
            call BJDebugMsg("Hero died - Entering Dead State")
            call IssueImmediateOrder(owner.hero, "stop")
        endmethod

        method onUpdate takes nothing returns nothing
            if not IsUnitAliveBJ(owner.hero) then
                return
            endif
            
            call BJDebugMsg("Hero revived - Returning to Run State")
            call owner.changeState(RunState.create())
        endmethod

        method onExit takes nothing returns nothing
            call BJDebugMsg("Exiting Dead State")
        endmethod
    endstruct

    struct CombatState extends AIState
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.stateID = STATE_COMBAT
            return this
        endmethod

        method onEnter takes nothing returns nothing
            call BJDebugMsg("Entering Combat State")
        endmethod

        method onUpdate takes nothing returns nothing
            local real currentTime = TimerGetElapsed(gameTimer)
            local integer difficulty = owner.difficulty
            local boolean isCasting = currentTime <= owner.lastCastTime + owner.castPt + TURN_TIME

            if isCasting then
                call BJDebugMsg("Currently casting an ability, skipping update")
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
                call this.executeNormalCombat()
            else // HARD
                call this.executeHardCombat()
            endif
            
            // Return to run state after combat
            call owner.changeState(RunState.create())
        endmethod

        method tryExecuteEasyCombat takes nothing returns boolean
            local integer i = 0
            local HeroAbility heroAbil
            local real currentTime = TimerGetElapsed(gameTimer)
            local real requiredCooldown
            
            // Cast first available ability with 2x cooldown spacing
            loop
                exitwhen i >= owner.combatData.abilityCount
                set heroAbil = owner.combatData.abilities[i]
                set requiredCooldown = heroAbil.baseCooldown * EASY_CD_MULTIPLIER
                
                // Check cooldown (skip for first-time cast)
                if heroAbil.lastCastTime == 0.0 or currentTime >= heroAbil.lastCastTime + requiredCooldown then
                    if this.tryCastAbility(heroAbil) then
                        set heroAbil.lastCastTime = currentTime
                        set owner.lastCastTime = currentTime
                        return true
                    endif
                endif
                set i = i + 1
            endloop
            return false
        endmethod

        method executeNormalCombat takes nothing returns nothing
            local integer i = 0
            local HeroAbility heroAbil
            local real currentTime = TimerGetElapsed(gameTimer)
            
            // Execute combo sequence - cast all available abilities
            loop
                exitwhen i >= owner.combatData.abilityCount
                set heroAbil = owner.combatData.abilities[i]

                call BJDebugMsg("Checking ability: " + heroAbil.orderString + " Last Cast Time: " + R2S(heroAbil.lastCastTime) + " Current Time: " + R2S(currentTime) + " Cooldown: " + R2S(heroAbil.baseCooldown))
                
                if heroAbil.lastCastTime == 0.0 or currentTime >= heroAbil.lastCastTime + heroAbil.baseCooldown then
                    if this.tryCastAbility(heroAbil) then
                        set heroAbil.lastCastTime = currentTime
                        set owner.lastCastTime = currentTime
                    endif
                endif
                set i = i + 1
            endloop
        endmethod

        method executeHardCombat takes nothing returns nothing
            // Advanced combat with countering - implement specific logic as needed
            call this.executeNormalCombat()  // For now, use normal combat
            // TODO: Add counter-casting logic based on enemy states
        endmethod

        method tryCastAbility takes HeroAbility heroAbil returns boolean
            local real heroX = GetUnitX(owner.hero)
            local real heroY = GetUnitY(owner.hero)
            local unit targetUnit
            local real currentMana
            local real heroFacing
            local real offset
            local real targetX
            local real targetY
            
            call BJDebugMsg("Attempting to cast ability: " + heroAbil.orderString)

            if IsUnitStunOrSilence(owner.hero) then
                call BJDebugMsg("Cannot cast ability, hero is stunned or silenced.")
                return false
            endif

            // Check if ability is available
            if GetUnitAbilityLevel(owner.hero, heroAbil.abilityId) <= 0 then
                call BJDebugMsg("Ability not available: " + heroAbil.orderString)
                return false
            endif
            
            // Check if hero has enough mana
            set currentMana = GetUnitState(owner.hero, UNIT_STATE_MANA)
            if currentMana < heroAbil.manaCost then
                call BJDebugMsg("Not enough mana for ability. Need: " + I2S(heroAbil.manaCost) + ", Have: " + R2S(currentMana))
                return false
            endif
            
            if heroAbil.castType == CAST_INSTANT then
                call IssueImmediateOrder(owner.hero, heroAbil.orderString)
                call BJDebugMsg("Casting instant ability: " + heroAbil.orderString)
                return true
            elseif heroAbil.castType == CAST_POINT_ENEMY_FRONT then
                // Cast at a point in front of the hero
                set targetUnit = this.findRandomEnemyHeroInRange(heroAbil.castRange)
                if targetUnit == null then
                    call BJDebugMsg("No target found for point ability: " + heroAbil.orderString)
                    return false
                endif
                set heroFacing = GetUnitFacing(targetUnit) * bj_DEGTORAD
                set offset = heroAbil.effectiveRadius
                set targetX = GetUnitX(targetUnit) + offset * Cos(heroFacing)
                set targetY = GetUnitY(targetUnit) + offset * Sin(heroFacing) 
                call IssuePointOrder(owner.hero, heroAbil.orderString, targetX, targetY)
                call BJDebugMsg("Casting point target ability in front: " + heroAbil.orderString)
                return true
            elseif heroAbil.castType == CAST_UNIT then
                
                if heroAbil.allowTargetType == ALLOW_TARGET_TYPE_ENEMY_HERO then
                    set targetUnit = this.findRandomEnemyHeroInRange(heroAbil.castRange)
                elseif heroAbil.allowTargetType == ALLOW_TARGET_TYPE_ALLY_HERO then
                    set targetUnit = this.findRandomAllyHeroInRange(heroAbil.castRange)
                elseif heroAbil.allowTargetType == ALLOW_TARGET_TYPE_ENEMY_UNIT then
                    // For simplicity, use enemy hero targeting for enemy units for now
                    set targetUnit = this.findRandomEnemyHeroInRange(heroAbil.castRange)
                elseif heroAbil.allowTargetType == ALLOW_TARGET_TYPE_ALLY_UNIT then
                    // For simplicity, use ally hero targeting for ally units for now
                    set targetUnit = this.findRandomAllyHeroInRange(heroAbil.castRange)
                else
                    // For simplicity, only implement hero targeting for now
                    set targetUnit = null
                endif
                
                if targetUnit != null then
                    call IssueTargetOrder(owner.hero, heroAbil.orderString, targetUnit)
                    call BJDebugMsg("Casting unit target ability: " + heroAbil.orderString)
                    return true
                else
                    call BJDebugMsg("No target found for unit ability: " + heroAbil.orderString)
                endif
            else
                call BJDebugMsg("Unsupported cast type for ability: " + heroAbil.orderString)
            endif
            
            return false
        endmethod

        method findNearestEnemy takes nothing returns unit
            // Simple implementation - find first enemy in range
            // TODO: Implement proper enemy detection based on your map's enemy system
            return null  // Placeholder - replace with actual enemy finding logic
        endmethod

        method findRandomHeroInRange takes real range, boolean isForAllies returns unit
            local group heroes = CreateGroup()
            local unit randomHero
            local real heroX = GetUnitX(owner.hero)
            local real heroY = GetUnitY(owner.hero)
            local player heroOwner = GetOwningPlayer(owner.hero)
            
            // Set temp variables for filter function
            set tempHeroOwner = heroOwner
            set bTempFilterForAllies = isForAllies
            set tempHeroUnit = owner.hero
            call GroupEnumUnitsInRange(heroes, heroX, heroY, range, Filter(function FilterHeroes))
            
            // Get random hero from filtered group
            set randomHero = GroupPickRandomUnit(heroes)
            
            // Clean up
            call DestroyGroup(heroes)
            set heroes = null
            
            return randomHero
        endmethod

        method findRandomEnemyHeroInRange takes real range returns unit
            return this.findRandomHeroInRange(range, false)
        endmethod
        
        method findRandomAllyHeroInRange takes real range returns unit
            return this.findRandomHeroInRange(range, true)
        endmethod

        method onExit takes nothing returns nothing
            call BJDebugMsg("Exiting Combat State")
        endmethod
    endstruct


    struct AIHero
        unit hero
        integer difficulty
        real castPt
        AIState currentState
        integer currentWaypointIndex
        HeroCombatData combatData
        real lastCastTime
        timer updateTimer
        
        // Constructor
        static method create takes unit u, integer diff returns thistype
            local thistype this = thistype.allocate()
            set this.updateTimer = CreateTimer()
            set this.hero = u
            set this.difficulty = diff
            set this.castPt = GetHeroCastPoint(GetUnitTypeId(u))
            set this.currentState = 0
            set this.currentWaypointIndex = 1

            // Initialize combat data
            set this.combatData = InitializeHeroCombatData(u, diff)

            call this.changeState(RunState.create())

            
            // Start the loop
            call SaveInteger(udg_TimerHeroMap, GetHandleId(this.updateTimer), 0, this)
            call TimerStart(this.updateTimer, UPDATE_PERIOD, true, function thistype.onUpdate)
            
            // Store unit to AIHero mapping
            call SaveInteger(udg_UnitAIHeroMap, GetHandleId(this.hero), 0, this)
            return this
        endmethod

        method shouldEnterCombat takes nothing returns boolean
            local integer i = 0
            local HeroAbility heroAbil
            local real currentTime = TimerGetElapsed(gameTimer)
            local real cooldownMultiplier = GetCooldownMultiplier(this.difficulty)
            local real currentMana

            if IsUnitStunOrSilence(this.hero) then
                call BJDebugMsg("Cannot enter combat, hero is stunned or silenced.")
                return false
            endif

            
            // Check if any ability is ready for combat based on difficulty
            loop
                exitwhen i >= this.combatData.abilityCount
                set heroAbil = this.combatData.abilities[i]
                
                // Check cooldown (skip for first-time cast)
                if heroAbil.lastCastTime == 0.0 or currentTime >= heroAbil.lastCastTime + (heroAbil.baseCooldown * cooldownMultiplier) then
                    // Check if ability is available
                    if GetUnitAbilityLevel(this.hero, heroAbil.abilityId) <= 0 then
                        call BJDebugMsg("Ability not available: " + heroAbil.orderString)
                    else
                        // Check if hero has enough mana
                        set currentMana = GetUnitState(this.hero, UNIT_STATE_MANA)
                        if currentMana < heroAbil.manaCost then
                            call BJDebugMsg("Not enough mana for ability. Need: " + I2S(heroAbil.manaCost) + ", Have: " + R2S(currentMana))
                        else
                            // All conditions met - ability is ready to cast
                            if heroAbil.lastCastTime == 0.0 then
                                call BJDebugMsg("First-time ability ready for combat: " + heroAbil.orderString)
                            else
                                call BJDebugMsg("Ability ready for combat: " + heroAbil.orderString)
                            endif
                            return true
                        endif
                    endif
                endif
                set i = i + 1
            endloop
            
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
    endstruct

    // This module ensures our initialization functions are called when the map loads.
    private module Initializer
        private static method onInit takes nothing returns nothing
            set udg_TimerHeroMap = InitHashtable()
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