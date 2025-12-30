struct AIItem
    integer itemId // item type
    item itemHandle
    real baseCooldown
    real lastUseTime
    real castRange
    real effectiveRadius
    unit ownerHero
    AIHero ownerAIHero
    boolean bIsPassive
    integer castType
    integer findTargetType


    static method create takes item newItemHandle, integer newItemId, real newBaseCooldown, real newCastRange, real newEffectiveRadius, unit newOwnerHero, boolean bNewIsPassive, integer newCastType, integer newFindTargetType returns thistype
        local thistype this = thistype.allocate()
        set this.itemHandle = newItemHandle
        set this.itemId = newItemId
        set this.baseCooldown = newBaseCooldown
        set this.castRange = newCastRange
        set this.effectiveRadius = newEffectiveRadius
        set this.ownerHero = newOwnerHero
        set this.ownerAIHero = GetAIHeroFromUnit(newOwnerHero)
        set this.bIsPassive = bNewIsPassive
        set this.castType = newCastType
        set this.findTargetType = newFindTargetType
        set this.lastUseTime = 0.0
        return this
    endmethod

    method isReadyToUse takes nothing returns boolean
        local real currentTime = TimerGetElapsed(gameTimer)

        if bIsPassive then
            return false
        endif

        if this.castType == CAST_INSTANT_HEAL then
            return GetUnitLifePercent(this.ownerHero) <= SELF_HEAL_HP_PERCENTAGE_THRESHOLD
        endif

        if this.baseCooldown <= 0.0 then
            return true
        endif

        if this.lastUseTime == 0.0 then
            return true
        endif
        if currentTime - this.lastUseTime > this.baseCooldown then
            return true
        endif
        return false
    endmethod

    method tryUse takes nothing returns boolean
        local unit targetUnit = null

        if this.castType == CAST_INSTANT_HEAL then
            if GetUnitLifePercent(this.ownerHero) <= SELF_HEAL_HP_PERCENTAGE_THRESHOLD then
                call UnitUseItem(this.ownerHero, this.itemHandle)
                call this.botLog("Using instant heal item: " + GetItemName(this.itemHandle))
                set this.lastUseTime = TimerGetElapsed(gameTimer)
                return true
            else
                return false
            endif
        endif

        // TODO
        // if this.castType == CAST_INSTANT_ENEMY_CROWDED then
        //     set targetUnit = FindCrowdedEnemyTargetInRange(this.ownerHero, this.effectiveRadius)
        //     if targetUnit == null then
        //         call this.botLog("No crowded enemy target found for item: " + GetItemName(this.itemHandle))
        //         return false
        //     endif

        //     call UnitUseItemTarget( this.ownerHero, this.itemHandle, targetUnit)
        //     call this.botLog("Using item: " + GetItemName(this.itemHandle) + " on crowded enemy target: " + GetUnitName(targetUnit))
        //     set this.lastUseTime = TimerGetElapsed(gameTimer)
        //     return true
        // endif

        set targetUnit = FindTargetForItem(this.ownerAIHero, this)
        if targetUnit == null then
            call this.botLog("No valid target found for item: " + GetItemName(this.itemHandle))
            return false
        endif

        call UnitUseItemTarget( this.ownerHero, this.itemHandle, targetUnit)
        call this.botLog("Using item: " + GetItemName(this.itemHandle) + " on target: " + GetUnitName(targetUnit))
        set this.lastUseTime = TimerGetElapsed(gameTimer)
        return true
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