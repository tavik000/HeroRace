struct GoaledState extends AIState

    static method create takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.stateID = STATE_GOALED
        return this
    endmethod

    method onEnter takes nothing returns nothing
        call this.botLog("Entering Goaled State")
        call owner.setDebugTextTagContent("Goaled: Entering")
        call owner.setDebugTextTagColorPreset("PINK")
        call IssueImmediateOrder(owner.hero, "stop")
    endmethod

    method onUpdate takes nothing returns nothing
        local integer currentWaypointIndex = owner.currentWaypointIndex
        local integer safeAreaWaypointIndex = 20
        local integer dangerAreaWaypointIndex = 21
        local integer currentOrder = GetUnitCurrentOrder(owner.hero)

        if not IsUnitAliveBJ(owner.hero) then
            return
        endif
            
        call owner.setDebugTextTagContent("Goaled: Updating")
        call owner.setDebugTextTagColorPreset("PINK")

        if owner.TryEnterPickupItemState() then
            return
        endif

        call owner.tryAvoidBlockingUnit() 

        if owner.tryEnterCombat() then
            return
        endif

        if isHealthy() then
            if currentWaypointIndex != dangerAreaWaypointIndex then
                call owner.setWaypointIndex(dangerAreaWaypointIndex) // Goaled Danger Area
                call owner.moveToNextWaypoint()
                return
            endif 
        else
            if currentWaypointIndex != safeAreaWaypointIndex then
                call owner.setWaypointIndex(safeAreaWaypointIndex) // Goaled Safe Area
                call owner.moveToNextWaypoint()
                return
            endif
        endif


        if owner.shouldEnterHazardState() then
            call this.botLog("Spike hazard detected - entering spike dodge state")
            call owner.changeState(HazardState.create())
            return
        endif

        if currentOrder == 0 then
            // Hero is idle (no current order) - reissue move command to current waypoint
            call this.botLog("Goaled Hero is idle, issuing move command")
            call owner.setDebugTextTagContent("Goaled: Reissuing Move Command")
            call owner.setDebugTextTagColorPreset("PINK")
            call owner.moveToNextWaypoint()
            return
        endif

    endmethod

    method isHealthy takes nothing returns boolean
        return GetUnitLifePercent(owner.hero) >= 40.0
    endmethod

    method onExit takes nothing returns nothing
        call this.botLog("Exiting Goaled State")
        call owner.setDebugTextTagContent("Goaled: Exiting")
        call owner.setDebugTextTagColorPreset("PINK")
    endmethod
endstruct