struct AIItem
    integer itemId // item type
    item itemHandle
    real baseCooldown
    real lastUseTime
    real castRange
    unit ownerHero
    boolean bIsPassive



    static method create takes item newItemHandle, integer newItemId, real newBaseCooldown, real newCastRange, unit newOwnerHero, boolean bNewIsPassive returns thistype
        local thistype this = thistype.allocate()
        set this.itemHandle = newItemHandle
        set this.itemId = newItemId
        set this.baseCooldown = newBaseCooldown
        set this.castRange = newCastRange
        set this.ownerHero = newOwnerHero
        set this.bIsPassive = bNewIsPassive
        set this.lastUseTime = 0.0
        return this
    endmethod

    method isReadyToUse takes nothing returns boolean
        return not bIsPassive
    endmethod

    method tryUse takes nothing returns nothing
        // local integer itemSlot = GetInventoryIndexOfItemTypeBJ(this.ownerHero, this.itemId)
        call UnitUseItemTarget( this.ownerHero, this.itemHandle, this.ownerHero)
        call this.botLog("Using item: " + GetItemName(this.itemHandle))
        // TODO
    endmethod

    method destroy takes nothing returns nothing
        call this.deallocate()
    endmethod

    method botLog takes string msg returns nothing
        call BotLogWithPlayer(GetOwningPlayer(this.ownerHero), msg)
    endmethod

    method botLogError takes string msg returns nothing
        call BotLogErrorWithPlayer(GetOwningPlayer(this.ownerHero), msg)
    endmethod
endstruct