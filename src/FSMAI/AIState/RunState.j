struct RunState extends AIState
    static method create takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.stateID = STATE_RUN
        return this
    endmethod

    method onEnter takes nothing returns nothing
        call this.botLog("Entering Run State")
        call owner.setDebugTextTagContent("Run: Entering")
        call owner.setDebugTextTagColorPreset("GREEN")
        call owner.moveToNextWaypoint()
    endmethod


    method onUpdate takes nothing returns nothing
        local rect currentWaypointArea 
        local real heroX 
        local real heroY 
        local real targetX
        local real targetY
        local integer currentOrder
        local unit blockingUnit
        local boolean hasBlockingUnitAhead
        local boolean hasBlockingUnitBehind
        local real blockDetectRadius = 100.0
            
        // Safety check - ensure hero is alive
        if not IsUnitAliveBJ(owner.hero) then
            return
        endif
            
        // call this.botLog("Updating Run State, waypoint index: " + I2S(owner.currentWaypointIndex))
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
            call owner.moveToNextWaypoint()
            return
        elseif currentOrder == 0 then
            // Hero is idle (no current order) - reissue move command to current waypoint
            call this.botLog("Hero is idle, reissuing move command")
            call owner.setDebugTextTagContent("Run: Reissuing Move Command")
            call owner.setDebugTextTagColorPreset("GREEN")
            call owner.moveToNextWaypoint()
        endif
            
        // Check for spike hazards first (highest priority, only between waypoints 7-8)
        if owner.shouldEnterHazardState() then
            call this.botLog("Spike hazard detected - entering spike dodge state")
            call owner.changeState(HazardState.create())
            return
        endif

        call owner.searchPickupItemAround()
        if owner.shouldEnterPickupItemState() then
            call this.botLog("Pickup item detected - entering pickup item state")
            call owner.setDebugTextTagContent("Run: Entering Pickup Item")
            call owner.setDebugTextTagColorPreset("CYAN")
            call owner.changeState(PickUpItemState.create())
            return
        endif
            
        call owner.combatData.prepareTargetForItems()
        // Check if we should enter combat state
        if owner.shouldEnterCombat() then
            call this.botLog("Entering combat - abilities ready")
            call owner.setDebugTextTagContent("Run: Entering Combat")
            call owner.setDebugTextTagColorPreset("GREEN")
            call owner.changeState(CombatState.create())
            return
        endif

        // Check for blocking units ahead
        set blockingUnit = this.getBlockingUnitAround(blockDetectRadius, false)
        set hasBlockingUnitAhead = blockingUnit != null
        if hasBlockingUnitAhead then
            call this.botLog("Blocking unit detected ahead, dodging")
            call owner.setDebugTextTagContent("Run: Dodging Blocking Unit Ahead")
            call owner.setDebugTextTagColorPreset("YELLOW")
            call owner.avoidTargetUnitAhead(blockingUnit, GetUnitMoveSpeed(blockingUnit) * 0.1, 2.0, true)
            return
        endif
        // Check for blocking units behind
        set blockingUnit = this.getBlockingUnitAround(blockDetectRadius, true)
        set hasBlockingUnitBehind = blockingUnit != null
        if hasBlockingUnitBehind then
            call this.botLog("Blocking unit detected behind, dodging")
            call owner.setDebugTextTagContent("Run: Dodging Blocking Unit Behind")
            call owner.setDebugTextTagColorPreset("YELLOW")
            call owner.avoidTargetUnitBehind(blockingUnit, false, 2.0, true)
            return
        endif

        set currentWaypointArea = null
    endmethod

    method onExit takes nothing returns nothing
        call this.botLog("Exiting Run State")
        call owner.setDebugTextTagContent("Run: Exiting")
        call owner.setDebugTextTagColorPreset("GREEN")
    endmethod

    method getBlockingUnitAround takes real detectRadius, boolean bCheckBehind returns unit
        local group blockingUnitGroup = CreateGroup()
        local unit u // for enumerating units
        local real heroX = GetUnitX(owner.hero)
        local real heroY = GetUnitY(owner.hero)
        local unit resultUnit = null
        local boolexpr filter = Filter(function AntiLeak)
        local real closestDistance = 99999.0
        local real currentTargetDistance
            
        call GroupEnumUnitsInRange(blockingUnitGroup, heroX, heroY, detectRadius, filter)
        loop
            set u = FirstOfGroup(blockingUnitGroup)
            exitwhen u == null

            call GroupRemoveUnit(blockingUnitGroup, u)
            if this.checkBlockingUnit(u, bCheckBehind) then
                set currentTargetDistance = DistanceBetweenXY(heroX, heroY, GetUnitX(u), GetUnitY(u))
                if currentTargetDistance < closestDistance then
                    set closestDistance = currentTargetDistance
                    set resultUnit = u
                endif
            endif
        endloop
        call DestroyGroup(blockingUnitGroup)
            
        return resultUnit
    endmethod

    method checkBlockingUnit takes unit u, boolean bCheckBehind returns boolean
        if u == owner.hero then
            return false
        endif
        if not IsUnitValid(u) then
            return false
        endif
        if bCheckBehind then
            if IsUnitInFrontOfUnit(u, owner.hero) then
                return false
            endif
        else
            if not IsUnitInFrontOfUnit(u, owner.hero) then
                return false
            endif
        endif
        call owner.botLog("Blocking unit found: " + GetUnitName(u))
        return true
    endmethod

endstruct

