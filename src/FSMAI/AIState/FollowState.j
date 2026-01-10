struct FollowState extends AIState
    // Follow target unit
    unit targetUnit
    real followDuration
    real startTime = 0.0
    integer mustHaveBuffCode = 0

    static method create takes unit target, real duration, integer inMustHaveBuffCode returns thistype
        local thistype this = thistype.allocate()
        set this.stateID = STATE_FOLLOW
        set this.targetUnit = target
        set this.followDuration = duration
        set this.startTime = TimerGetElapsed(gameTimer)
        set this.mustHaveBuffCode = inMustHaveBuffCode
        return this
    endmethod

    method onEnter takes nothing returns nothing
        call IssueTargetOrder(owner.hero, "move", this.targetUnit)
        call this.botLog("Entering Follow State")
        call owner.setDebugTextTagContent("Follow: Entering")
        call owner.setDebugTextTagColorPreset("BLUE")
    endmethod

    method onUpdate takes nothing returns nothing
        local integer currentOrder = GetUnitCurrentOrder(owner.hero)

        call owner.setDebugTextTagContent("Follow: Following Target")
        call owner.setDebugTextTagColorPreset("BLUE")

        if this.mustHaveBuffCode != 0 then
            if not UnitHasBuffBJ(this.targetUnit, this.mustHaveBuffCode) then
                call this.botLog("Follow target lost required buff - Returning to Run State")
                call owner.setDebugTextTagContent("Follow: Target Lost Buff")
                call owner.setDebugTextTagColorPreset("BLUE")
                call owner.changeState(RunState.create())
                return
            endif
        endif

        if this.isExpired() then
            call this.botLog("Follow duration expired - Returning to Run State")
            call owner.setDebugTextTagContent("Follow: Duration Expired")
            call owner.setDebugTextTagColorPreset("BLUE")
            call owner.changeState(RunState.create())
            return
        endif
        if not IsUnitValid(targetUnit) then
            call this.botLog("Follow target lost or dead - Returning to Run State")
            call owner.setDebugTextTagContent("Follow: Target Lost")
            call owner.setDebugTextTagColorPreset("BLUE")
            call owner.changeState(RunState.create())
            return
        endif
        if IsUnitStun(owner.hero) then
            call this.botLog("Owner hero is stunned - cannot follow, Returning to Run State")
            call owner.setDebugTextTagContent("Follow: Stunned")
            call owner.setDebugTextTagColorPreset("BLUE")
            call owner.changeState(RunState.create())
            return
        endif
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

        if currentOrder == 0 then
            call IssueTargetOrder(owner.hero, "move", this.targetUnit)
            call this.botLog("Reissuing move order to follow target unit: " + GetUnitName(this.targetUnit) + " owner: " + GetUnitName(owner.hero))
        endif
        
    endmethod

    method isExpired takes nothing returns boolean
        local real currentTime = TimerGetElapsed(gameTimer)
        return (currentTime - this.startTime) >= this.followDuration
    endmethod

    method onExit takes nothing returns nothing
        call owner.resetIsCasting()
        call this.botLog("Exiting Dead State")
        call owner.setDebugTextTagContent("Dead: Exiting")
        call owner.setDebugTextTagColorPreset("GRAY")
    endmethod

endstruct