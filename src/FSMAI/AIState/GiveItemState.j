struct GiveItemState extends AIState
    unit targetUnit = null

    static method create takes unit inTargetUnit returns thistype
        local thistype this = thistype.allocate()
        set this.stateID = STATE_GIVE_ITEM
        set this.targetUnit = inTargetUnit
        return this
    endmethod

    method onEnter takes nothing returns nothing
        call this.botLog("Entering Give Item State")
        call owner.setDebugTextTagContent("Give Item: Entering")
        call owner.setDebugTextTagColorPreset("PURPLE")

        if not IsUnitValid(this.targetUnit) then
            call this.botLogError("Target unit is not valid when entering Give Item State, transitioning to Run State")
            call owner.changeState(RunState.create())
            return
        endif

        // Got ThunderAxe become neutral passive
        if IsUnitOwnedByPlayer(owner.hero, Player(PLAYER_NEUTRAL_PASSIVE)) then
            call this.botLog("Hero is owned by Neutral Passive when entering Give Item State, transitioning to Run State")
            return
        endif

        // Give the item
        if this.isOwningItem(owner.givingItem) then
            call UnitDropItemTarget(owner.hero, owner.givingItem, this.targetUnit)
            call this.botLog("Giving item: " + GetItemName(owner.givingItem) + " to unit: " + GetUnitName(this.targetUnit))
            return
        endif

        call owner.combatData.removeItem(owner.givingItem)
        call this.botLog("No item to give")
        call owner.setDebugTextTagContent("Give Item: No Item Found")
        call owner.setDebugTextTagColorPreset("PURPLE")
        call owner.changeState(RunState.create())
    endmethod

    method onUpdate takes nothing returns nothing
        local integer currentOrder
        local item newItemToGive

        if not IsUnitValid(this.targetUnit) then
            call this.botLog("Target unit: " + GetUnitName(this.targetUnit) + " is no longer valid, transitioning to Run State")
            call owner.changeState(RunState.create())
            return
        endif

        // Got ThunderAxe become neutral passive
        if IsUnitOwnedByPlayer(owner.hero, Player(PLAYER_NEUTRAL_PASSIVE)) then
            call this.botLog("Hero is owned by Neutral Passive when entering Give Item State, transitioning to Run State")
            return
        endif

        if IsUnitEnemy(this.targetUnit, GetOwningPlayer(owner.hero)) then
            call this.botLog("Target unit: " + GetUnitName(this.targetUnit) + " is an enemy, transitioning to Run State")
            call owner.changeState(RunState.create())
            return
        endif

        // check if item has been given
        if not this.isOwningItem(owner.givingItem) then
            call owner.combatData.removeItem(owner.givingItem)

            // Search for give item again
            set newItemToGive = owner.combatData.getAnyItemToGive()
            if newItemToGive != null and not IsUnitInventoryFull(this.targetUnit) then
                set owner.givingItem = newItemToGive
                call UnitDropItemTarget(owner.hero, owner.givingItem, this.targetUnit)
                call this.botLog("Giving item: " + GetItemName(owner.givingItem) + " to unit: " + GetUnitName(this.targetUnit))
                return
            else
                call this.botLog("Item given or no item to give, transitioning to Run State")
                call owner.changeState(RunState.create())
                return
            endif
        endif

        set currentOrder = GetUnitCurrentOrder(owner.hero)
        if currentOrder == 0 then
            call UnitDropItemTarget(owner.hero, owner.givingItem, this.targetUnit)
            call this.botLog("Re-issuing give order for item: " + GetItemName(owner.givingItem) + " to unit: " + GetUnitName(this.targetUnit))
            return
        endif

        if owner.tryEnterCombat() then
            return
        endif

    endmethod

    method isOwningItem takes item itm returns boolean
        if itm == null or GetItemLifeBJ(itm) <= 0.0 or not UnitHasItem(owner.hero, itm) then
            return false
        endif
        return true
    endmethod

    method onExit takes nothing returns nothing
        call this.botLog("Exiting Give Item State")
        call owner.setDebugTextTagContent("Give Item: Exit")
        call owner.setDebugTextTagColorPreset("PURPLE")
    endmethod
endstruct