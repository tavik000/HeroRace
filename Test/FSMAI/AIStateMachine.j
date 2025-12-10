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
        
        // Combat settings
        constant real EASY_CD_MULTIPLIER = 2.0
        constant real NORMAL_CD_MULTIPLIER = 1.0
        constant real HARD_CD_MULTIPLIER = 1.0
        constant real CRAZY_CD_MULTIPLIER = 1.0
        constant real NIGHTMARE_CD_MULTIPLIER = 0.8 
        constant integer MAX_ABILITIES_PER_HERO = 7
        
        // Timer to AIHero mapping
        public hashtable udg_TimerHeroMap
        
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

        // The array to hold the waypoint regions.
        private rect array WaypointAreas
        // The actual number of waypoints initialized.
        public integer WaypointCount = 0

        // Turn time for 90 degree turns, giving turn rate 0.6
        constant real TURN_TIME = 0.2 

        constant real MAX_RANGE = 30000.0
    endglobals

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
            if currentMana >= this.manaCost then
                return true
            endif
            return false
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
                            call BJDebugMsg("Ability not available: " + heroAbil.orderString)
                        else
                            // Check if hero has enough mana
                            set currentMana = GetUnitState(hero, UNIT_STATE_MANA)
                            if not heroAbil.isManaReady(hero) then
                                call BJDebugMsg("Not enough mana for ability. Need: " + I2S(heroAbil.manaCost) + ", Have: " + R2S(currentMana))
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
                call BJDebugMsg("Error: AIHero not found for unit in getReadyComboAbility.")
                return 0
            endif


            // Check if a sequence of combo abilities are ready
            loop
                set heroAbil = this.getAbilityByComboIndex(i)
                // Reach end of combo sequence
                exitwhen heroAbil == 0
                
                // Check cooldown
                if not heroAbil.isCooldownReady(difficulty) then
                    call BJDebugMsg("Ability cooldown not ready for combo: " + heroAbil.orderString)
                    return 0
                endif
                
                // Check if ability is available
                if GetUnitAbilityLevel(hero, heroAbil.abilityId) <= 0 then
                    call BJDebugMsg("Ability not available for combo: " + heroAbil.orderString)
                    return 0
                endif
                
                if i == aiHero.currentComboIndex then
                    set resultComboAbility = heroAbil
                    call BJDebugMsg("Found ready combo ability at comboIndex " + I2S(i) + ": " + heroAbil.orderString)
                endif
                set i = i + 1
            endloop

            if not this.hasEnoughManaForCombo(hero, startingComboIndex) then
                call BJDebugMsg("Not enough mana for remaining combo abilities from index " + I2S(startingComboIndex))
                return 0
            endif

            call BJDebugMsg("Combo abilities ready, returning ability: " + resultComboAbility.orderString)
            return resultComboAbility
        endmethod

        method hasEnoughManaForCombo takes unit hero, integer currentComboIndex returns boolean
            local real currentMana = GetUnitState(hero, UNIT_STATE_MANA)
            local real requiredMana = 0.0
            local integer i = currentComboIndex
            local HeroAbility heroAbil
            
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
            call BJDebugMsg("Not enough mana for remaining combo. Need: " + R2S(requiredMana) + ", Have: " + R2S(currentMana))
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

    // Initialize hero-specific abilities (extend this function for different heroes)
    function InitializeHeroCombatData takes unit hero, integer difficulty returns HeroCombatData
        local HeroCombatData data = HeroCombatData.create()
        local integer heroTypeId = GetUnitTypeId(hero)

        
        // Example: Add abilities based on hero type
        if heroTypeId == 'H009' then  // BloodMage example
            call BJDebugMsg("Adding abilities for BloodMage")
            call data.addAbility('A00S', 22.0, CAST_POINT_ENEMY_FRONT, "flamestrike", 70, MAX_RANGE, ALLOW_TARGET_TYPE_NONE, 200, 2, 866.0)   // Flame Strike
            call data.addAbility('A00W', 22.0, CAST_UNIT, "banish", 40, MAX_RANGE, ALLOW_TARGET_TYPE_ENEMY_HERO, 0, 1, 0.0)   // Banish
            call data.addAbility('A01N', 47.0, CAST_UNIT, "bloodlust", 50, 2500, ALLOW_TARGET_TYPE_ALLY_HERO, 0, 0, 0.0) // Blood Lust
            
        elseif heroTypeId == 'Hmkg' then  // Mountain King example
            // call data.addAbility('AHtc', 6.0, CAST_UNIT, "thunderclap", 75, 250, ALLOW_TARGET_TYPE_ENEMY_UNIT, 0)      // Thunder Clap
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
            local boolean isCastOvertime = currentTime > owner.lastStartCastTime + owner.castPt + TURN_TIME // Turn Time and Pre-swing 
            local boolean isCastFailed = owner.isCasting and isCastOvertime

            if isCastFailed then
                call BJDebugMsg("Casting failed or interrupted, resetting casting state")
                set owner.isCasting = false
                set owner.castingAbility = 0
            endif

            if owner.isCasting then
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
            if not heroAbil.isManaReady(owner.hero) then
                call BJDebugMsg("Not enough mana for ability: " + heroAbil.orderString)
                return false
            endif
            
            if heroAbil.castType == CAST_INSTANT then
                call IssueImmediateOrder(owner.hero, heroAbil.orderString)
                call BJDebugMsg("Casting instant ability: " + heroAbil.orderString)
                return true
            elseif heroAbil.castType == CAST_POINT_ENEMY_FRONT then
                if IsApplyingCombo(owner.difficulty) and owner.comboTargetUnit != null and heroAbil.comboIndex > 0 then
                    set targetUnit = owner.comboTargetUnit
                else
                    // Cast at a point in front of the hero
                    if IsApplyingCombo(owner.difficulty) and heroAbil.comboIndex > 0 then
                        set targetUnit = this.findBestComboTarget(heroAbil.castRange)
                    else
                        set targetUnit = this.findRandomEnemyHeroInRange(heroAbil.castRange)
                    endif
                endif
                if targetUnit == null then
                    call BJDebugMsg("No target found for point ability: " + heroAbil.orderString)
                    return false
                endif
                if IsApplyingCombo(owner.difficulty) and owner.comboTargetUnit != targetUnit then
                    if heroAbil.comboIndex > 0 then
                        set owner.comboTargetUnit = targetUnit
                    endif
                endif
                set heroFacing = GetUnitFacing(targetUnit) * bj_DEGTORAD
                set offset = heroAbil.effectiveRadius
                set targetX = GetUnitX(targetUnit) + offset * Cos(heroFacing)
                set targetY = GetUnitY(targetUnit) + offset * Sin(heroFacing) 
                call IssuePointOrder(owner.hero, heroAbil.orderString, targetX, targetY)
                call BJDebugMsg("Casting point target ability in front: " + heroAbil.orderString)
                return true
            elseif heroAbil.castType == CAST_UNIT then
                
                // Check if we should use existing combo target
                if IsApplyingCombo(owner.difficulty) and owner.comboTargetUnit != null and heroAbil.comboIndex > 0 then
                    set targetUnit = owner.comboTargetUnit
                    call BJDebugMsg("Using existing combo target for unit, targetUnit: " + GetUnitName(targetUnit))
                else
                    // Use default target finding logic
                    if heroAbil.allowTargetType == ALLOW_TARGET_TYPE_ENEMY_HERO then
                        // Use smart combo targeting for combo abilities, random for others
                        if IsApplyingCombo(owner.difficulty) and heroAbil.comboIndex > 0 then
                            set targetUnit = this.findBestComboTarget(heroAbil.castRange)
                            call BJDebugMsg("Finding best combo target for unit ability, targetUnit: " + GetUnitName(targetUnit))
                        else
                            set targetUnit = this.findRandomEnemyHeroInRange(heroAbil.castRange)
                            call BJDebugMsg("Finding random enemy hero for unit ability, targetUnit: " + GetUnitName(targetUnit))
                        endif
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
                endif
                
                if targetUnit != null then
                    if IsApplyingCombo(owner.difficulty) and owner.comboTargetUnit != targetUnit then
                        if heroAbil.comboIndex > 0 then
                            set owner.comboTargetUnit = targetUnit
                        endif
                    endif
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

        method findBestComboTarget takes real range returns unit
            local group heroes = CreateGroup()
            local unit currentUnit = null
            local unit bestTarget = null
            local real heroX = GetUnitX(owner.hero)
            local real heroY = GetUnitY(owner.hero)
            local player heroOwner = GetOwningPlayer(owner.hero)
            local real currentHp
            local real maxHp
            local real currentHpPercent
            local real bestTargetHp = 0.0
            local boolean isKillTarget
            local boolean bestIsKillTarget = false
            local real comboExpectedDamage = owner.combatData.comboExpectedDamage
            local real comboMinThreshold = comboExpectedDamage * owner.combatData.comboOverkillThresholdPercent
            
            // Set temp variables for filter function
            set tempHeroOwner = heroOwner
            set bTempFilterForAllies = false
            set tempHeroUnit = owner.hero
            call GroupEnumUnitsInRange(heroes, heroX, heroY, range, Filter(function FilterHeroes))
            
            // Iterate through filtered enemies to find best target
            loop
                set currentUnit = FirstOfGroup(heroes)
                exitwhen currentUnit == null
                call GroupRemoveUnit(heroes, currentUnit)
                
                set currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)
                set maxHp = GetUnitState(currentUnit, UNIT_STATE_MAX_LIFE)
                
                // Skip if HP is below minimum threshold (avoid overkill)
                if currentHp >= comboMinThreshold then
                    set isKillTarget = (currentHp <= comboExpectedDamage)
                    
                    // Target selection logic:
                    // 1. Prefer kill targets over non-kill targets
                    // 2. Among kill targets, prefer higher HP (less overkill)
                    // 3. Among non-kill targets, prefer lower HP (better efficiency)
                    if bestTarget == null then
                        set bestTarget = currentUnit
                        set bestTargetHp = currentHp
                        set bestIsKillTarget = isKillTarget
                        if isKillTarget then
                            call BJDebugMsg("Initial combo target candidate: " + GetUnitName(currentUnit) + " HP:" + R2S(currentHp) + " Kill:1")
                        else
                            call BJDebugMsg("Initial combo target candidate: " + GetUnitName(currentUnit) + " HP:" + R2S(currentHp) + " Kill:0")
                        endif
                    elseif isKillTarget and not bestIsKillTarget then
                        // Kill target is better than non-kill target
                        set bestTarget = currentUnit
                        set bestTargetHp = currentHp
                        set bestIsKillTarget = isKillTarget
                        call BJDebugMsg("Better combo target (kill): " + GetUnitName(currentUnit) + " HP:" + R2S(currentHp))
                    elseif isKillTarget and bestIsKillTarget and currentHp > bestTargetHp then
                        // Among kill targets, prefer higher HP (less overkill)
                        set bestTarget = currentUnit
                        set bestTargetHp = currentHp
                        call BJDebugMsg("Better combo target (less overkill): " + GetUnitName(currentUnit) + " HP:" + R2S(currentHp))
                    elseif not isKillTarget and not bestIsKillTarget and currentHp < bestTargetHp then
                        // Among non-kill targets, prefer lower HP (better efficiency)
                        set bestTarget = currentUnit
                        set bestTargetHp = currentHp
                        call BJDebugMsg("Better combo target (efficiency): " + GetUnitName(currentUnit) + " HP:" + R2S(currentHp))
                    endif
                else
                    call BJDebugMsg("Skipping combo target (too low HP): " + GetUnitName(currentUnit) + " HP:" + R2S(currentHp) + " < " + R2S(comboMinThreshold))
                endif
            endloop
            
            // Clean up
            call DestroyGroup(heroes)
            set heroes = null
            set currentUnit = null
            
            if bestTarget != null then
                if bestIsKillTarget then
                    call BJDebugMsg("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Kill:1")
                else
                    call BJDebugMsg("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Kill:0")
                endif
            else
                call BJDebugMsg("No suitable combo target found, trying fallback to overkill targets")
                
                // Fallback: If no targets above threshold, find highest HP among all enemies (minimize overkill)
                set heroes = CreateGroup()
                call GroupEnumUnitsInRange(heroes, heroX, heroY, range, Filter(function FilterHeroes))
                
                loop
                    set currentUnit = FirstOfGroup(heroes)
                    exitwhen currentUnit == null
                    call GroupRemoveUnit(heroes, currentUnit)
                    
                    set currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)
                    
                    // Among all enemies, prefer highest HP (minimize overkill damage waste)
                    if bestTarget == null or currentHp > bestTargetHp then
                        set bestTarget = currentUnit
                        set bestTargetHp = currentHp
                        call BJDebugMsg("Fallback combo target candidate: " + GetUnitName(currentUnit) + " HP:" + R2S(currentHp))
                    endif
                endloop
                
                // Clean up fallback group
                call DestroyGroup(heroes)
                set heroes = null
                
                if bestTarget != null then
                    call BJDebugMsg("Fallback combo target selected: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " (overkill)")
                else
                    call BJDebugMsg("No combo targets found at all")
                endif
            endif
            
            return bestTarget
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
        real lastStartCastTime
        boolean isCasting
        HeroAbility castingAbility
        timer updateTimer
        integer currentComboIndex
        unit comboTargetUnit
        
        // Constructor
        static method create takes unit u, integer inDifficulty returns thistype
            local thistype this = thistype.allocate()
            set this.updateTimer = CreateTimer()
            set this.hero = u
            set this.difficulty = inDifficulty
            set this.castPt = GetHeroCastPoint(GetUnitTypeId(u))
            set this.currentState = 0
            set this.currentWaypointIndex = 1
            set this.lastStartCastTime = 0.0
            set this.isCasting = false
            set this.castingAbility = 0
            set this.currentComboIndex = 1 // only for difficulty HARD and above
            set this.comboTargetUnit = null


            // Initialize combat data
            set this.combatData = InitializeHeroCombatData(u, inDifficulty)

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
            local real currentMana
            local boolean hasReadyAbility = false

            if IsUnitStunOrSilence(this.hero) then
                call BJDebugMsg("Cannot enter combat, hero is stunned or silenced.")
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

        method onCastComplete takes nothing returns nothing
            local real currentTime = TimerGetElapsed(gameTimer)
            local integer difficulty = this.difficulty
            set this.isCasting = false
            set this.castingAbility.lastCastTime = currentTime
            // Advance combo index if casting combo ability
            if IsApplyingCombo(difficulty) and this.castingAbility.comboIndex > 0 then
                set this.currentComboIndex = this.currentComboIndex + 1
                call BJDebugMsg("Ability cast complete: " + this.castingAbility.orderString + ", advancing combo index to: " + I2S(this.currentComboIndex))
                // If no further combo ability, reset combo index
                if this.combatData.getAbilityByComboIndex(this.currentComboIndex) == 0 then
                    set this.currentComboIndex = 1
                    set this.comboTargetUnit = null
                    call BJDebugMsg("Combo sequence complete, resetting combo index to 1")
                endif
            endif

            call BJDebugMsg("Casting complete, castingAbility: " + this.castingAbility.orderString)
            set this.castingAbility = 0
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