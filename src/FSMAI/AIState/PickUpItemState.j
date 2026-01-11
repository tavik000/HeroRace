struct PickUpItemState extends AIState
    static method create takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.stateID = STATE_PICKUP_ITEM
        return this
    endmethod

    method onEnter takes nothing returns nothing
        call this.botLog("Entering Pick Up Item State")
        call owner.setDebugTextTagContent("Item: Picking Up")
        call owner.setDebugTextTagColorPreset("CYAN")

        // Pick up the item
        if owner.pickingUpItem != null then
            call IssueTargetOrder(owner.hero, "smart", owner.pickingUpItem) 
            call this.botLog("Picking up item: " + GetItemName(owner.pickingUpItem))
        else
            call this.botLog("No item to pick up")
            call owner.setDebugTextTagContent("Item: No Item Found")
            call owner.setDebugTextTagColorPreset("CYAN")
            // Transition back to RunState if no item found
            call owner.changeState(RunState.create())
        endif
    endmethod

    method onUpdate takes nothing returns nothing
        local integer currentOrder

        // check if item has been picked up
        if owner.pickingUpItem == null or IsItemOwned(owner.pickingUpItem) or IsUnitInventoryFull(owner.hero) or GetItemLifeBJ(owner.pickingUpItem) <= 0.0 then
            call this.botLog("Item picked up or no item to pick up, transitioning to Run State")
            call owner.setDebugTextTagContent("Item: Picked Up")
            call owner.setDebugTextTagColorPreset("CYAN")
            call owner.changeState(RunState.create())
        endif

        set currentOrder = GetUnitCurrentOrder(owner.hero)
        if currentOrder == 0 then
            call IssueTargetOrder(owner.hero, "smart", owner.pickingUpItem) 
            call this.botLog("Re-issuing pick up order for item: " + GetItemName(owner.pickingUpItem))
        endif

        if owner.tryEnterCombat() then
            return
        endif

    endmethod

    method onExit takes nothing returns nothing
        call this.botLog("Exiting Pick Up Item State")
        call owner.setDebugTextTagContent("Item: Exit")
        call owner.setDebugTextTagColorPreset("CYAN")
    endmethod
endstruct