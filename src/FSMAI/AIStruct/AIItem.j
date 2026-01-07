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

    method customFilter takes unit u returns boolean
        if this.itemId == 'I016' then  // SilenceStaff
            if IsUnitSilenced(u) then 
                call this.botLog("Skipping unit " + GetUnitName(u) + " for SilenceStaff, already silenced")
                return false
            endif
        endif
        return true
    endmethod

    method isForcedToUse takes nothing returns boolean
        return GetUnitLifePercent(this.ownerHero) <= FORCE_USE_ITEM_HP_PERCENTAGE_THRESHOLD
    endmethod

    method getUnitFrontOffsetDistance takes unit targetUnit returns real
        local real targetMoveSpeed = GetUnitMoveSpeed(targetUnit)
        local real projectileSpeed = 0.0
        local real targetDistance = DistanceBetweenUnits(this.ownerHero, targetUnit)
        local real timeToReachTarget = 0.0
        local real baseOffset = 0.0
        local real offsetDistance = 0.0

        if this.castType != CAST_POINT_ENEMY_FRONT then
            call this.botLogError("getFrontOffsetDistance called for non-front-cast item: " + GetItemName(this.itemHandle))
            return 0.0
        endif

        if this.itemId == 'I002' then  // ForceMissile
            set projectileSpeed = 1500.0
            set timeToReachTarget = targetDistance / projectileSpeed
            set baseOffset = 150.0
            set offsetDistance = targetMoveSpeed * timeToReachTarget + baseOffset
        else
            set offsetDistance = this.effectiveRadius
        endif
        return offsetDistance
    endmethod

    // For items that need target preparation before use
    method tryPrepareTarget takes nothing returns boolean
        local integer targetUnitCount

        if this.bIsPassive then
            return false
        endif

        if this.castType == CAST_NONE then
            // Cannot prepare target for CAST_NONE
            return false
        elseif this.castType == CAST_INSTANT_BACK_ENEMY then
            if this.isForcedToUse() then
                set this.readyTargetUnit = this.ownerHero
            else
                set this.readyTargetUnit = FindTargetUnitForItem(this.ownerAIHero, this)
            endif
            set this.bIsReadyToUse = this.readyTargetUnit != null
        elseif this.castType == CAST_INSTANT_ENEMY_CROWDED then
            if this.isForcedToUse() then
                set this.bIsReadyToUse = true
                return true
            endif
            set targetUnitCount = GetHeroCountAroundUnit(this.ownerHero, this.effectiveRadius, FIND_TEAM_TYPE_ENEMIES)
            set this.bIsReadyToUse = targetUnitCount >= 2
        elseif this.castType == CAST_INSTANT_HEAL then
            if this.isForcedToUse() then
                set this.bIsReadyToUse = true
            else
                set this.bIsReadyToUse = GetUnitLifePercent(this.ownerHero) <= SELF_HEAL_HP_PERCENTAGE_THRESHOLD
            endif
        elseif this.castType == CAST_POINT_ENEMY_FRONT then
            if this.isForcedToUse() then
                set this.readyTargetUnit = FindForceToUseTargetUnitForItem(this.ownerAIHero, this)
            else
                set this.readyTargetUnit = FindTargetUnitForItem(this.ownerAIHero, this)
            endif
            set this.bIsReadyToUse = this.readyTargetUnit != null
        elseif this.castType == CAST_POINT_ENEMY_CROWDED then
            // the final target point will be find again when using the item
            set tempAIItem = this 
            set readyTargetPoint = FindPointAroundCrowdedHeroes(this.ownerAIHero, this.effectiveRadius, FIND_TEAM_TYPE_ENEMIES)
            set tempAIItem = 0
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
                return false
            endif
            if this.isForcedToUse() then
                set this.readyTargetUnit = FindForceToUseTargetUnitForItem(this.ownerAIHero, this)
            else
                set this.readyTargetUnit = FindTargetUnitForItem(this.ownerAIHero, this)
            endif
            set this.bIsReadyToUse = this.readyTargetUnit != null
        else
            call this.botLogError("Item cast type not implemented for prepare target: " + I2S(this.castType) + " for item: " + GetItemName(this.itemHandle))
            set this.readyTargetUnit = null
            set this.bIsReadyToUse = false
            return false
        endif

        return this.bIsReadyToUse
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

    method isCooldownReady takes nothing returns boolean
        local real currentTime = TimerGetElapsed(gameTimer)

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
        set this.readyTargetUnit = null
    endmethod

    method useToPoint takes real targetX, real targetY returns nothing
        call UnitUseItemPoint(this.ownerHero, this.itemHandle, targetX, targetY)
        call this.botLog("Using item: " + GetItemName(this.itemHandle) + " at point: (" + R2S(targetX) + ", " + R2S(targetY) + ")")
        set this.lastUseTime = TimerGetElapsed(gameTimer)
        set this.bIsReadyToUse = false
        set this.readyTargetPointX = 0.0
        set this.readyTargetPointY = 0.0
        set this.readyTargetPoint = null
        set this.readyTargetUnit = null
    endmethod

    method tryUse takes nothing returns boolean
        local unit targetUnit = null
        local integer targetUnitCount = 0
        local real targetFacingAngle = 0.0 // for front point calculation
        local real offset = 0.0 // for front point calculation

        if this.itemHandle == null then
            call this.botLogError("Item handle is null, cannot use item: " + I2S(this.itemId))
            return false
        endif

        if not this.bIsReadyToUse then
            return false
        endif

        if this.castType == CAST_NONE then
            call this.botLogError("Item cast type is CAST_NONE, cannot use item: " + GetItemName(this.itemHandle))
            return false
        elseif this.castType == CAST_INSTANT_HEAL then
            call this.useInstant()
            return true
        elseif this.castType == CAST_INSTANT_BACK_ENEMY then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No valid target found for item, should be blocked by prepare target: " + GetItemName(this.itemHandle))
                set this.readyTargetUnit = null
                set this.bIsReadyToUse = false
                return false
            endif

            if not IsUnitValid(targetUnit) then
                set this.readyTargetUnit = null
                set this.bIsReadyToUse = false
                return false
            endif

            if targetUnit == this.ownerHero then
                // Force to use
                call this.useInstant()
                return true
            else
                if DistanceBetweenUnits(this.ownerHero, targetUnit) > this.effectiveRadius * 2.0 then
                    return false
                endif
                // Follow target unit
                if DistanceBetweenUnits(this.ownerHero, targetUnit) <= this.effectiveRadius then
                    call this.useInstant()
                    return true
                else
                    call IssueTargetOrder(this.ownerHero, "move", targetUnit)
                    return true
                endif
            endif
        elseif this.castType == CAST_INSTANT_ENEMY_CROWDED then
            call this.useInstant()
            return true
        elseif this.castType == CAST_POINT_ENEMY_FRONT then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No valid target found for item, should be blocked by prepare target: " + GetItemName(this.itemHandle))
                return false
            endif
            
            // Calculate point in front of target unit
            set targetFacingAngle = GetUnitFacing(this.readyTargetUnit)
            set offset = this.getUnitFrontOffsetDistance(this.readyTargetUnit)
            set this.readyTargetPointX = GetUnitX(this.readyTargetUnit) + offset * Cos(targetFacingAngle * bj_DEGTORAD)
            set this.readyTargetPointY = GetUnitY(this.readyTargetUnit) + offset * Sin(targetFacingAngle * bj_DEGTORAD)
            call this.useToPoint(this.readyTargetPointX, this.readyTargetPointY)
            return true
        elseif this.castType == CAST_POINT_ENEMY_CROWDED then
            set tempAIItem = this 
            set readyTargetPoint = FindPointAroundCrowdedHeroes(this.ownerAIHero, this.effectiveRadius, FIND_TEAM_TYPE_ENEMIES)
            set tempAIItem = 0
            set readyTargetPointX = GetLocationX(readyTargetPoint)
            set readyTargetPointY = GetLocationY(readyTargetPoint)
            call RemoveLocation(readyTargetPoint)
            if (IsNearlyZero(this.readyTargetPointX) and IsNearlyZero(this.readyTargetPointY)) then
                set this.bIsReadyToUse = false
                return false
            endif
            call this.useToPoint(this.readyTargetPointX, this.readyTargetPointY)
            return true
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