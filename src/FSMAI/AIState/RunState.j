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
        set owner.idleReissueCount = 0
        if owner.isCasting then
            call this.botLogError("Hero is casting when entering Run State, resetting casting state")
            set owner.isCasting = false
            return
        endif
        call owner.moveToNextWaypoint()
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

        if IsHeroGoaled(owner.hero) then
            call owner.changeState(GoaledState.create())
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
        if owner.currentWaypointIndex <= GoalWaypointIndex then
            if RectContainsCoords(currentWaypointArea, heroX, heroY) then
                call this.botLog("Reached waypoint " + I2S(owner.currentWaypointIndex))
                call owner.setDebugTextTagContent("Run: Reached Waypoint " + I2S(owner.currentWaypointIndex))
                call owner.setDebugTextTagColorPreset("GREEN")

                // Special handling for crossing sea at waypoint 3: Left of Upper Strait
                if owner.currentWaypointIndex == 3 then
                    if owner.shouldCrossSeaOrTree() then
                        // Upper strait - crossing sea
                        call this.botLog("Going to crossing sea area after waypoint 3")
                        call owner.setDebugTextTagContent("Run: Crossing Sea Area")
                        call owner.setDebugTextTagColorPreset("GREEN")

                        call owner.setWaypointIndex(31) // Cross Sea Area
                        call owner.moveToNextWaypoint()
                        return
                    endif
                endif

                if owner.currentWaypointIndex == 13 then
                    // Before final waypoint 
                    if owner.shouldCrossSeaOrTree() then
                        call owner.setWaypointIndex(131) // Cross Tree Area
                        call owner.moveToNextWaypoint()
                        return
                    endif
                endif

                if owner.currentWaypointIndex == GoalWaypointIndex then
                    call this.botLog("Reached final waypoint")
                    call owner.changeState(GoaledState.create())
                    return
                else
                    // Move to next waypoint
                    call owner.setWaypointIndex(owner.currentWaypointIndex + 1)
                endif
                
                // Move to the new waypoint
                call owner.moveToNextWaypoint()
                return

            endif
        endif

        if owner.currentWaypointIndex == 31 then
            // Crossing sea area
            if not owner.shouldCrossSeaOrTree() then
                call owner.setWaypointIndex(4) // Reset to normal run if cannot cross sea
                call owner.moveToNextWaypoint()
                return
            endif
        endif
        if owner.currentWaypointIndex == 131 then
            // Crossing tree area
            if not owner.shouldCrossSeaOrTree() then
                call owner.setWaypointIndex(14) // Reset to normal run if cannot cross tree
                call owner.moveToNextWaypoint()
                return
            endif
        endif
        if RectContainsCoords(gg_rct_AIWayPointAreaAfterCrossSea, heroX, heroY) then
            call owner.setWaypointIndex(4) // After Cross Sea Area
            call owner.moveToNextWaypoint()
            return
        endif
        if RectContainsCoords(gg_rct_AIWayPointAreaAfterCrossTree, heroX, heroY) then
            call owner.setWaypointIndex(14) // After Cross Tree Area
            call owner.moveToNextWaypoint()
            return
        endif

        if currentOrder == 0 then
            // Hero is idle (no current order) - reissue move command to current waypoint

            // Check if reissuing frequently (within 5 seconds) - might be stuck
            if owner.lastIdleReissueTime > 0.0 and (TimerGetElapsed(gameTimer) - owner.lastIdleReissueTime) < 5.0 then
                set owner.idleReissueCount = owner.idleReissueCount + 1
                if owner.idleReissueCount >= 15 then
                    // Unstuck logic
                    set udg_Stuck_Unit = owner.hero
                    call TriggerExecute( gg_trg_Stuck_in_tree)

                    set owner.idleReissueCount = 0
                    set owner.lastIdleReissueTime = TimerGetElapsed(gameTimer)

                    call this.botLog("Hero is stuck! Reissued move command 15 times. Calling UnstuckUnit()")
                    call owner.setDebugTextTagContent("Run: STUCK - Recovering")
                    call owner.setDebugTextTagColorPreset("YELLOW")
                    return
                endif
            else
                // Been a while since last reissue, reset counter
                set owner.idleReissueCount = 1
            endif
            
            set owner.lastIdleReissueTime = TimerGetElapsed(gameTimer)
            call this.botLog("Hero is idle, issuing move command (reissue #" + I2S(owner.idleReissueCount) + ")")
            call owner.setDebugTextTagContent("Run: Reissuing Move Command #" + I2S(owner.idleReissueCount))
            call owner.setDebugTextTagColorPreset("GREEN")
            call owner.moveToNextWaypoint()
        endif
            
        if owner.tryEnterHazardState() then
            return
        endif

        if owner.TryEnterGiveItemState() then
            return 
        endif

        if owner.TryEnterPickupItemState() then
            return
        endif
            
        if owner.tryEnterCombat() then
            return
        endif

        if owner.tryAvoidBlockingUnit() then
            return
        endif

        if owner.currentWaypointIndex == 6 and owner.shouldGoThroughThreeFish() then
            // Special case: go through 3 fishes hazard
            call owner.setWaypointIndex(7)  
            call owner.moveToNextWaypoint()

            call this.botLog("Going through 3 Fishes Hazard at waypoint 6")
            call owner.setDebugTextTagContent("Run: Through 3 Fishes Hazard")
            call owner.setDebugTextTagColorPreset("GREEN")
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