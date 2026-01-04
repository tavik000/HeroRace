struct AIItem
    integer itemId // item type
    item itemHandle
    real baseCooldown
    real lastUseTime
    real castRange
    real effectiveRadius
    real requiredCastTime
    unit ownerHero
    AIHero ownerAIHero
    boolean bIsPassive
    integer castType
    integer findTargetType
    boolean bIsReadyToUse
    real readyTargetPointX
    real readyTargetPointY
    unit readyTargetUnit
    location readyTargetPoint

    static method create takes item newItemHandle, integer newItemId, real newBaseCooldown, real newCastRange, real newEffectiveRadius, real requiredCastTime, unit newOwnerHero, boolean bNewIsPassive, integer newCastType, integer newFindTargetType returns thistype
        local thistype this = thistype.allocate()
        set this.itemHandle = newItemHandle
        set this.itemId = newItemId
        set this.baseCooldown = newBaseCooldown
        set this.castRange = newCastRange
        set this.effectiveRadius = newEffectiveRadius
        set this.requiredCastTime = requiredCastTime
        set this.ownerHero = newOwnerHero
        set this.ownerAIHero = GetAIHeroFromUnit(newOwnerHero)
        set this.bIsPassive = bNewIsPassive
        set this.castType = newCastType
        set this.findTargetType = newFindTargetType
        set this.lastUseTime = 0.0
        set this.bIsReadyToUse = false
        set this.readyTargetPointX = 0.0
        set this.readyTargetPointY = 0.0
        set this.readyTargetUnit = null
        return this
    endmethod

    method isForcedToUse takes nothing returns boolean
        return GetUnitLifePercent(this.ownerHero) <= FORCE_USE_ITEM_HP_PERCENTAGE_THRESHOLD
    endmethod

    // For items that need target preparation before use
    method tryPrepareTarget takes nothing returns nothing
        local integer targetUnitCount

        if this.bIsPassive then
            return
        endif

        if this.castType == CAST_NONE then
            // Cannot prepare target for CAST_NONE
            return
        elseif this.castType == CAST_INSTANT_HEAL then
            if this.isForcedToUse() then
                set this.bIsReadyToUse = true
            else
                set this.bIsReadyToUse = GetUnitLifePercent(this.ownerHero) <= SELF_HEAL_HP_PERCENTAGE_THRESHOLD
            endif
        elseif this.castType == CAST_INSTANT_ENEMY_CROWDED then
            if this.isForcedToUse() then
                set this.bIsReadyToUse = true
                return
            endif
            set targetUnitCount = GetHeroCountAroundUnit(this.ownerHero, this.effectiveRadius, FIND_TEAM_TYPE_ENEMIES)
            set this.bIsReadyToUse = targetUnitCount >= 2
        elseif this.castType == CAST_POINT_ENEMY_CROWDED then
            set readyTargetPoint = FindPointAroundCrowdedHeroes(this.ownerAIHero, this.effectiveRadius, FIND_TEAM_TYPE_ENEMIES)
            set readyTargetPointX = GetLocationX(readyTargetPoint)
            set readyTargetPointY = GetLocationY(readyTargetPoint)
            call RemoveLocation(readyTargetPoint)
            if this.isForcedToUse() then
                set this.bIsReadyToUse = true
            else
                set this.bIsReadyToUse = (not IsNearlyZero(this.readyTargetPointX) and not IsNearlyZero(this.readyTargetPointY))
            endif
        elseif this.castType == CAST_UNIT then
            if this.findTargetType == FIND_TARGET_TYPE_NONE then
                call this.botLogError("Item find target type is FIND_TARGET_TYPE_NONE, cannot prepare item: " + GetItemName(this.itemHandle))
                return
            endif
            if this.isForcedToUse() then
                set this.readyTargetUnit = FindForceToUseTargetUnitForItem(this.ownerAIHero, this)
            else
                set this.readyTargetUnit = FindTargetUnitForItem(this.ownerAIHero, this)
            endif
            set this.bIsReadyToUse = this.readyTargetUnit != null
        else
            call this.botLogError("Item cast type not implemented for prepare target: " + I2S(this.castType) + " for item: " + GetItemName(this.itemHandle))
            return
            set this.readyTargetUnit = null
            set this.bIsReadyToUse = false
        endif

    endmethod

    method isCooldownAndReadyToUse takes nothing returns boolean
        local real currentTime = TimerGetElapsed(gameTimer)

        if this.baseCooldown <= 0.0 then
            return this.bIsReadyToUse
        endif
        if this.lastUseTime == 0.0 then
            return this.bIsReadyToUse
        endif
        if currentTime - this.lastUseTime > this.baseCooldown then
            return this.bIsReadyToUse
        endif
        return false
    endmethod

    method useInstant takes nothing returns nothing
        call UnitUseItem(this.ownerHero, this.itemHandle)
        call this.botLog("Using item: " + GetItemName(this.itemHandle))
        set this.lastUseTime = TimerGetElapsed(gameTimer)
        set this.bIsReadyToUse = false
    endmethod

    method useToTargetUnit takes unit targetUnit returns nothing
        call UnitUseItemTarget( this.ownerHero, this.itemHandle, targetUnit)
        call this.botLog("Using item: " + GetItemName(this.itemHandle) + " on target: " + GetUnitName(targetUnit))
        set this.lastUseTime = TimerGetElapsed(gameTimer)
        set this.bIsReadyToUse = false
    endmethod

    method useToPoint takes real targetX, real targetY returns nothing
        call UnitUseItemPoint(this.ownerHero, this.itemHandle, targetX, targetY)
        call this.botLog("Using item: " + GetItemName(this.itemHandle) + " at point: (" + R2S(targetX) + ", " + R2S(targetY) + ")")
        set this.lastUseTime = TimerGetElapsed(gameTimer)
        set this.bIsReadyToUse = false
    endmethod

    method tryUse takes nothing returns boolean
        local unit targetUnit = null
        local integer targetUnitCount = 0

        if this.castType == CAST_NONE then
            call this.botLogError("Item cast type is CAST_NONE, cannot use item: " + GetItemName(this.itemHandle))
            return false
        elseif this.castType == CAST_INSTANT_HEAL then
            if this.bIsReadyToUse then
                call this.useInstant()
                return true
            else
                return false
            endif
        elseif this.castType == CAST_INSTANT_ENEMY_CROWDED then
            if this.bIsReadyToUse then
                call this.useInstant()
                return true
            else
                return false
            endif
        elseif this.castType == CAST_POINT_ENEMY_CROWDED then
            if this.bIsReadyToUse then
                call this.useToPoint(this.readyTargetPointX, this.readyTargetPointY)
                return true
            else
                return false
            endif
        elseif this.castType == CAST_UNIT then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No valid target found for item, should be blocked by prepare target: " + GetItemName(this.itemHandle))
                return false
            endif

            call this.useToTargetUnit(targetUnit)
            return true
        else
            call this.botLogError("Item cast type not implemented: " + I2S(this.castType) + " for item: " + GetItemName(this.itemHandle))
            return false
        endif
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