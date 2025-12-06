library AIStateMachine requires optional KeyUtils
    
    // --- CONFIGURATION ---
    globals
        // States
        constant integer STATE_PRE_GAME = 0
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
        constant real CAST_RANGE = 700.00
        constant real UPDATE_PERIOD = 0.30
        
        // Combat settings
        constant real EASY_CD_MULTIPLIER = 2.0
        constant real NORMAL_CD_MULTIPLIER = 1.0
        constant real HARD_CD_MULTIPLIER = 1.0
        constant integer MAX_ABILITIES_PER_HERO = 7
        
        // Timer to AIHero mapping
        public hashtable udg_TimerHeroMap

        // The array to hold the waypoint regions.
        private rect array WaypointAreas
        // The actual number of waypoints initialized.
        public integer WaypointCount = 0
    endglobals

    // This function will run once at map initialization to set up the waypoints.
    private function InitializeWaypoints takes nothing returns nothing
        // IMPORTANT: Create regions in the World Editor and replace these
        // variable names (e.g., gg_rct_Waypoint_001) with your actual region variables.
        set WaypointAreas[0] = gg_rct_AIWayPointArea01
        set WaypointAreas[1] = gg_rct_AIWayPointArea01 // After Start Area
        set WaypointAreas[2] = gg_rct_AIWayPointArea02
        set WaypointAreas[3] = gg_rct_AIWayPointArea03 // Left of Upper Strait
        set WaypointAreas[4] = gg_rct_AIWayPointArea04
        set WaypointAreas[5] = gg_rct_AIWayPointArea05
        set WaypointAreas[6] = gg_rct_AIWayPointArea06 // Left of 3 Fishes 
        set WaypointAreas[7] = gg_rct_AIWayPointArea07 // Before Slow Knife Hazard
        set WaypointAreas[8] = gg_rct_AIWayPointArea08 // After Slow Knife Hazard
        set WaypointAreas[9] = gg_rct_AIWayPointArea09 // Before Fast Knife Hazard
        set WaypointAreas[10] = gg_rct_AIWayPointArea10 // Before Net Hazard
        set WaypointAreas[11] = gg_rct_AIWayPointArea11 // After Net Hazard
        set WaypointAreas[12] = gg_rct_AIWayPointArea12
        set WaypointAreas[13] = gg_rct_Finish
        set WaypointCount = 14 // Update this to match the number of waypoints you added.
    endfunction

    // Ability cast types
    globals
        constant integer CAST_INSTANT = 0
        constant integer CAST_POINT = 1
        constant integer CAST_UNIT = 2
    endglobals

    struct HeroAbility
        integer abilityId
        real baseCooldown
        integer castType
        real lastCastTime
        integer comboIndex  // For chaining abilities in sequence
        
        static method create takes integer aid, real cd, integer ctype returns thistype
            local thistype this = thistype.allocate()
            set this.abilityId = aid
            set this.baseCooldown = cd
            set this.castType = ctype
            set this.lastCastTime = 0.0
            set this.comboIndex = 0
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
        
        method addAbility takes integer abilityId, real cooldown, integer castType returns nothing
            if this.abilityCount < MAX_ABILITIES_PER_HERO then
                set this.abilities[this.abilityCount] = HeroAbility.create(abilityId, cooldown, castType)
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

        call BJDebugMsg("Initializing combat data for hero type ID: " + I2S(heroTypeId))
        
        // Example: Add abilities based on hero type
        if heroTypeId == 'H009' then  // Archmage example
            call BJDebugMsg("Adding abilities for BloodMage")
            // call data.addAbility('AHbz', 8.0, CAST_POINT)   // Blizzard
            // call data.addAbility('AHwe', 12.0, CAST_UNIT)   // Water Elemental
            // call data.addAbility('AHab', 5.0, CAST_INSTANT) // Brilliance Aura
        elseif heroTypeId == 'Hmkg' then  // Mountain King example
            call data.addAbility('AHtc', 6.0, CAST_UNIT)    // Thunder Clap
            call data.addAbility('AHbh', 10.0, CAST_INSTANT)// Bash
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
            // Increment waypoint index, wrapping around if it reaches the end
            set owner.currentWaypointIndex = owner.currentWaypointIndex + 1
            set currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
            set x = GetRandomReal(GetRectMinX(currentWaypointArea), GetRectMaxX(currentWaypointArea))
            set y = GetRandomReal(GetRectMinY(currentWaypointArea), GetRectMaxY(currentWaypointArea))
            call IssuePointOrder(owner.hero, "move", x, y)      
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
            
            call BJDebugMsg("Updating Run State")
            
            // Check if we should enter combat state
            if owner.shouldEnterCombat() then
                call BJDebugMsg("Entering combat - abilities ready")
                call owner.changeState(CombatState.create())
                return
            endif
            
            set currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
            set heroX = GetUnitX(owner.hero)
            set heroY = GetUnitY(owner.hero)
            set currentOrder = GetUnitCurrentOrder(owner.hero)
            
            // Check if hero has reached the current waypoint area
            if RectContainsCoords(currentWaypointArea, heroX, heroY) then
                call BJDebugMsg("Reached waypoint " + I2S(owner.currentWaypointIndex))
                // Move to next waypoint
                set owner.currentWaypointIndex = (owner.currentWaypointIndex + 1)
                if owner.currentWaypointIndex >= WaypointCount then
                    call BJDebugMsg("Reached final waypoint")
                    // TODO Goaled State
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
            call IssueImmediateOrder(owner.hero, "stop")
        endmethod

        method onUpdate takes nothing returns nothing
            local real currentTime = TimerGetElapsed(GetExpiredTimer())
            local integer difficulty = owner.difficulty
            
            // Safety check - ensure hero is alive
            if not IsUnitAliveBJ(owner.hero) then
                return
            endif
            
            call BJDebugMsg("Updating Combat State")
            
            if difficulty == DIFF_EASY then
                call this.executeEasyCombat()
            elseif difficulty == DIFF_NORMAL then
                call this.executeNormalCombat()
            else // HARD
                call this.executeHardCombat()
            endif
            
            // Return to run state after combat
            call owner.changeState(RunState.create())
        endmethod

        method executeEasyCombat takes nothing returns nothing
            local integer i = 0
            local HeroAbility heroAbil
            local real currentTime = TimerGetElapsed(GetExpiredTimer())
            local real requiredCooldown
            
            // Cast first available ability with 2x cooldown spacing
            loop
                exitwhen i >= owner.combatData.abilityCount
                set heroAbil = owner.combatData.abilities[i]
                set requiredCooldown = heroAbil.baseCooldown * EASY_CD_MULTIPLIER
                
                if currentTime >= heroAbil.lastCastTime + requiredCooldown then
                    if this.castAbility(heroAbil) then
                        set heroAbil.lastCastTime = currentTime
                        exitwhen true  // Cast one ability then exit
                    endif
                endif
                set i = i + 1
            endloop
        endmethod

        method executeNormalCombat takes nothing returns nothing
            local integer i = 0
            local HeroAbility heroAbil
            local real currentTime = TimerGetElapsed(GetExpiredTimer())
            
            // Execute combo sequence - cast all available abilities
            loop
                exitwhen i >= owner.combatData.abilityCount
                set heroAbil = owner.combatData.abilities[i]
                
                if currentTime >= heroAbil.lastCastTime + heroAbil.baseCooldown then
                    if this.castAbility(heroAbil) then
                        set heroAbil.lastCastTime = currentTime
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

        method castAbility takes HeroAbility heroAbil returns boolean
            local real heroX = GetUnitX(owner.hero)
            local real heroY = GetUnitY(owner.hero)
            local unit target
            
            // Check if ability is available and hero has mana
            if GetUnitAbilityLevel(owner.hero, heroAbil.abilityId) <= 0 then
                return false
            endif
            
            if heroAbil.castType == CAST_INSTANT then
                call IssueImmediateOrderById(owner.hero, heroAbil.abilityId)
                return true
            elseif heroAbil.castType == CAST_POINT then
                // Cast at hero's current location or nearby
                call IssuePointOrderById(owner.hero, heroAbil.abilityId, heroX + GetRandomReal(-200, 200), heroY + GetRandomReal(-200, 200))
                return true
            elseif heroAbil.castType == CAST_UNIT then
                // Find nearest enemy unit to cast on
                set target = this.findNearestEnemy()
                if target != null then
                    call IssueTargetOrderById(owner.hero, heroAbil.abilityId, target)
                    return true
                endif
            endif
            
            return false
        endmethod

        method findNearestEnemy takes nothing returns unit
            // Simple implementation - find first enemy in range
            // TODO: Implement proper enemy detection based on your map's enemy system
            return null  // Placeholder - replace with actual enemy finding logic
        endmethod

        method onExit takes nothing returns nothing
            call BJDebugMsg("Exiting Combat State")
        endmethod
    endstruct



    struct AIHero
        unit hero
        integer difficulty
        AIState currentState
        integer currentWaypointIndex
        HeroCombatData combatData
        
        // Constructor
        static method create takes unit u, integer diff returns thistype
            local thistype this = thistype.allocate()
            local timer t = CreateTimer()
            set this.hero = u
            set this.difficulty = diff
            set this.currentState = 0
            set this.currentWaypointIndex = 1
            //test 
            set this.currentWaypointIndex = 7

            // Initialize combat data
            set this.combatData = InitializeHeroCombatData(u, diff)

            call this.changeState(RunState.create())

            
            // Start the loop
            call SaveInteger(udg_TimerHeroMap, GetHandleId(t), 0, this)
            call TimerStart(t, UPDATE_PERIOD, true, function thistype.onUpdate)
            return this
        endmethod

        method shouldEnterCombat takes nothing returns boolean
            local integer i = 0
            local HeroAbility heroAbil
            local real currentTime = TimerGetElapsed(GetExpiredTimer())
            local real cooldownMultiplier = GetCooldownMultiplier(this.difficulty)
            
            // Check if any ability is ready for combat based on difficulty
            loop
                exitwhen i >= this.combatData.abilityCount
                set heroAbil = this.combatData.abilities[i]
                
                if currentTime >= heroAbil.lastCastTime + (heroAbil.baseCooldown * cooldownMultiplier) then
                    return true
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
            call BJDebugMsg("AIStateMachine initializing...")
            set udg_TimerHeroMap = InitHashtable()
            call InitializeWaypoints()
        endmethod
    endmodule

    // We use a dummy struct to attach the initializer module to the library.
    private struct Init extends array
        implement Initializer
    endstruct
  
endlibrary