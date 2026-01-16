struct AIItem
    integer itemId // item type
    item itemHandle
    real baseCooldown
    real lastUseTime
    real castRange
    real effectiveRadius
    real requiredCastTime
    integer manaCost
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
    destructable readyTargetTree


    static method create takes item newItemHandle, integer newItemId, real newBaseCooldown, real newCastRange, real newEffectiveRadius, real requiredCastTime, integer newManaCost, unit newOwnerHero, boolean bNewIsPassive, integer newCastType, integer newFindTargetType returns thistype
        local thistype this = thistype.allocate()
        set this.itemHandle = newItemHandle
        set this.itemId = newItemId
        set this.baseCooldown = newBaseCooldown
        set this.castRange = newCastRange
        set this.effectiveRadius = newEffectiveRadius
        set this.requiredCastTime = requiredCastTime
        set this.manaCost = newManaCost
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
        if this.itemId == 'I01U' then // Banish
            if UnitHasBuffBJ(u, 'BHbn') then
                call this.botLog("Skipping banish target, already banished, unit: " + GetUnitName(u))
                return false
            endif
        endif
        return true
    endmethod

    method isForcedToUse takes nothing returns boolean
        return GetUnitLifePercent(this.ownerHero) <= FORCE_USE_ITEM_HP_PERCENTAGE_THRESHOLD
    endmethod

    method isManaReady takes nothing returns boolean
        local real currentMana = GetUnitState(ownerHero, UNIT_STATE_MANA)
        if currentMana >= I2R(this.manaCost) then
            return true
        endif
        return false
    endmethod

    method isIgnoreMagicImmune takes nothing returns boolean
        if this.itemId == 'I01J' then  // HookShot
            return true 
        endif
        if this.itemId == 'I003' then  // MeatHook
            return true
        endif
        return false
    endmethod

    method mustHaveBuffCodeWhenFollowing takes nothing returns integer
        if this.itemId == 'I008' then  // LightingShield
            return 'Blsh'  // Lighting Shield Buff
        endif
        return 0
    endmethod

    method shouldCheckOtherUnitBlockingTargetUnit takes nothing returns boolean
        if this.itemId == 'I01J' then  // HookShot
            return true 
        endif
        if this.itemId == 'I003' then  // MeatHook
            return true
        endif
        return false
    endmethod

    method getMinTargetDistance takes nothing returns real
        if this.itemId == 'I01J' then  // HookShot
            return this.castRange / 2.0
        endif
        if this.itemId == 'I003' then  // MeatHook
            return this.castRange / 2.0
        endif
        if this.itemId == 'I00E' then  // NetherSwap
            return this.castRange / 2.0
        endif
        return 0.0
    endmethod

    method getFollowTargetDuration takes nothing returns real
        if this.itemId == 'I008' then  // LightingShield
            return 12.0
        endif
        return 0.0
    endmethod

    method getUnitFrontOffsetDistance takes unit targetUnit returns real
        local real targetMoveSpeed = GetUnitMoveSpeed(targetUnit)
        local real projectileSpeed = 0.0
        local real targetDistance = DistanceBetweenUnits(this.ownerHero, targetUnit)
        local real timeToReachTarget = 0.0
        local real baseOffset = 0.0
        local real baseDelay = 0.0
        local real offsetDistance = 0.0
        local integer ownerUnitTypeId = GetUnitTypeId(this.ownerHero)
        local real ownerCastPoint = ownerAIHero.getCastPoint()
        local integer currentOrder

        if this.castType != CAST_POINT_ENEMY_FRONT and this.castType != CAST_POINT_ALL_FRONT and this.castType != CAST_POINT_ALLY_FRONT then
            call this.botLogError("getFrontOffsetDistance called for non-front-cast item: " + GetItemName(this.itemHandle))
            return 0.0
        endif

        set currentOrder = GetUnitCurrentOrder(targetUnit)
        if currentOrder == 0 then
            // Not moving
            set targetMoveSpeed = 0.0
        endif

        if IsUnitStun(targetUnit) then
            // Cannot move
            set targetMoveSpeed = 0.0
        endif

        if this.itemId == 'I002' then  // ForceMissile
            set projectileSpeed = 1500.0
            set timeToReachTarget = targetDistance / projectileSpeed
            set baseOffset = 50.0
            set offsetDistance = targetMoveSpeed * (ownerCastPoint + timeToReachTarget) + baseOffset
        elseif this.itemId == 'I02I' then  // Fissure
            // Instant cast, no projectile
            set baseOffset = 50.0
            set offsetDistance = targetMoveSpeed * ownerCastPoint + baseOffset
        elseif this.itemId == 'I021' then  // Torrent
            // Instant cast, no projectile
            set baseOffset = 0.0
            set baseDelay = 2.0
            // delay 2 seconds before the torrent erupts
            set offsetDistance = targetMoveSpeed * (baseDelay + ownerCastPoint) + baseOffset
        elseif this.itemId == 'I01J' then  // HookShot
            set projectileSpeed = 5000.0
            set timeToReachTarget = targetDistance / projectileSpeed
            set baseOffset = 0.0
            set offsetDistance = targetMoveSpeed * (ownerCastPoint + timeToReachTarget) + baseOffset
        elseif this.itemId == 'I003' then  // MeatHook
            set projectileSpeed = 1333.33
            set timeToReachTarget = targetDistance / projectileSpeed
            set baseOffset = 0.0
            set offsetDistance = targetMoveSpeed * (ownerCastPoint + timeToReachTarget) + baseOffset
        elseif this.itemId == 'I006' then  // StasisTrap
            // Instant cast, no projectile
            set baseOffset = 50.0
            set baseDelay = 0.5
            // delay 2 seconds before the stasis trap activates
            set offsetDistance = targetMoveSpeed * (baseDelay + ownerCastPoint) + baseOffset
        else
            // Default offset distance
            set offsetDistance = this.effectiveRadius
        endif
        return offsetDistance
    endmethod

    // called by AIHero to mark the item as ready to use on being targeted or damaged
    method markAsReadyToUse takes nothing returns nothing
        set this.bIsReadyToUse = true
        set this.readyTargetUnit = this.ownerHero
    endmethod

    // For items that need target preparation before use
    method tryPrepareTarget takes nothing returns boolean
        local integer targetUnitCount
        local real heroX = GetUnitX(this.ownerHero)
        local real heroY = GetUnitY(this.ownerHero)

        if this.bIsPassive then
            return false
        endif

        if this.castType == CAST_NONE then
            // Cannot prepare target for CAST_NONE
            return false
        elseif this.castType == CAST_INSTANT then
            set this.bIsReadyToUse = true
        elseif this.castType == CAST_INSTANT_BACK_ENEMY then
            if this.isForcedToUse() then
                set this.readyTargetUnit = this.ownerHero
            else
                set this.readyTargetUnit = FindTargetUnitForItem(this.ownerAIHero, this)
            endif
            set this.bIsReadyToUse = this.readyTargetUnit != null
        elseif this.castType == CAST_INSTANT_BACK_ENEMY_FOLLOW then
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
                set this.bIsReadyToUse = GetUnitLifePercent(this.ownerHero) <= HEAL_HP_PERCENTAGE_THRESHOLD
            endif
        elseif this.castType == CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE then
            if this.isForcedToUse() then
                set this.bIsReadyToUse = true
            else
                // when being targeted by other ability, or taken damage
            endif
        elseif this.castType == CAST_INSTANT_ALLY_CROWDED then
            if this.isForcedToUse() then
                set this.bIsReadyToUse = true
                return true
            endif
            set targetUnitCount = GetHeroCountAroundUnit(this.ownerHero, this.effectiveRadius, FIND_TEAM_TYPE_ALLIES)
            call this.botLog("Found " + I2S(targetUnitCount) + " allied heroes around for item: " + GetItemName(this.itemHandle))
            set this.bIsReadyToUse = targetUnitCount >= 2
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
        elseif this.castType == CAST_POINT_ALLY_FRONT then
            if this.isForcedToUse() then
                set this.readyTargetUnit = FindForceToUseTargetUnitForItem(this.ownerAIHero, this)
            else
                set this.readyTargetUnit = FindTargetUnitForItem(this.ownerAIHero, this)
            endif
            set this.bIsReadyToUse = this.readyTargetUnit != null
        elseif this.castType == CAST_POINT_SELF_FRONT then
            if this.isForcedToUse() then
                set this.readyTargetUnit = this.ownerHero
            else
                if IsUnitFacingAlongTrack(this.ownerHero) then
                    set this.readyTargetUnit = this.ownerHero
                else
                    set this.readyTargetUnit = null
                endif
            endif
            set this.bIsReadyToUse = this.readyTargetUnit != null
        elseif this.castType == CAST_POINT_SELF_FRONT_HEAL then
            if this.isForcedToUse() then
                set this.readyTargetUnit = this.ownerHero
            else
                if GetUnitLifePercent(this.ownerHero) <= HEAL_HP_PERCENTAGE_THRESHOLD then
                    set this.readyTargetUnit = this.ownerHero
                else
                    set this.readyTargetUnit = null
                endif
            endif
            set this.bIsReadyToUse = this.readyTargetUnit != null
        elseif this.castType == CAST_POINT_SELF_FRONT_DEFENSE_AND_CLEANSE then
            if this.isForcedToUse() then
                set this.readyTargetUnit = this.ownerHero
            else
                // when being targeted by other ability, or taken damage
            endif
            set this.bIsReadyToUse = this.readyTargetUnit != null
        elseif this.castType == CAST_POINT_ALL_FRONT then
            if this.isForcedToUse() then
                set this.readyTargetUnit = FindForceToUseTargetUnitForItem(this.ownerAIHero, this)
            else
                set this.readyTargetUnit = FindTargetUnitForItem(this.ownerAIHero, this)
            endif
            if this.readyTargetUnit != null then
                call this.botLog("Prepared meat hook front point target unit: " + GetUnitName(this.readyTargetUnit))
            endif
            set this.bIsReadyToUse = this.readyTargetUnit != null
        elseif this.castType == CAST_POINT_BLINK then
            if this.isForcedToUse() then
                if IsUnitFacingAlongTrack(this.ownerHero) then
                    set this.readyTargetUnit = this.ownerHero
                else
                    set this.readyTargetUnit = null
                endif
            else
                if RectContainsCoords(gg_rct_AIWayPointAreaCrossSea, heroX, heroY) then
                    if not IsUnitFacingEastNarrow(this.ownerHero) then
                        // issue move right to face east
                        call IssuePointOrder(this.ownerHero, "move", heroX + 10.0, heroY)
                        call this.ownerAIHero.botLog("Adjusting facing direction to east for Force Staff self-use.")
                        return false
                    endif
                    call IssueImmediateOrder(this.ownerHero, "stop")
                    set this.readyTargetUnit = this.ownerHero
                endif
                if RectContainsCoords(gg_rct_AIWayPointAreaCrossTree, heroX, heroY) then
                    if not IsUnitFacingWestNarrow(this.ownerHero) then
                        // issue move up to face west
                        call IssuePointOrder(this.ownerHero, "move", heroX - 10.0, heroY)
                        call this.ownerAIHero.botLog("Adjusting facing direction to west for Force Staff self-use.")
                        return false
                    endif
                    // stop moving before using item
                    call IssueImmediateOrder(this.ownerHero, "stop")
                    set this.readyTargetUnit = this.ownerHero
                endif
            endif
            set this.bIsReadyToUse = this.readyTargetUnit != null
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
        elseif this.castType == CAST_UNIT_SELF_THEN_FOLLOW_TARGET then
            if this.findTargetType == FIND_TARGET_TYPE_NONE then
                call this.botLogError("Item find target type is FIND_TARGET_TYPE_NONE, cannot prepare item: " + GetItemName(this.itemHandle))
                return false
            endif
            if IsUnitInvulnerableOrMagicImmune(this.ownerHero) then
                set this.readyTargetUnit = null
                set this.bIsReadyToUse = false
                return false
            endif
            if this.isForcedToUse() then
                set this.readyTargetUnit = this.ownerHero
            else
                set this.readyTargetUnit = FindTargetUnitForItem(this.ownerAIHero, this)
            endif
            set this.bIsReadyToUse = this.readyTargetUnit != null
        elseif this.castType == CAST_TREE_FRONT then
            if this.isForcedToUse() then
                set this.readyTargetTree = FindNearestTreeInRange(this.ownerHero, 1000.0)
                set this.bIsReadyToUse = this.readyTargetTree != null
                return this.bIsReadyToUse
            endif
            if GetUnitLifePercent(this.ownerHero) <= HEAL_HP_PERCENTAGE_THRESHOLD then
                set this.readyTargetTree = FindNearestTreeInFrontOfUnit(this.ownerHero, 1000.0)
                set this.bIsReadyToUse = this.readyTargetTree != null
            else
                set this.readyTargetTree = null
                set this.bIsReadyToUse = false
            endif
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
        call this.ownerAIHero.moveToNextWaypoint()
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

    method useToTargetTree takes destructable targetTree returns nothing
        call UnitUseItemTarget( this.ownerHero, this.itemHandle, targetTree)
        call this.botLog("Using item: " + GetItemName(this.itemHandle) + " on target tree at point: (" + R2S(GetDestructableX(targetTree)) + ", " + R2S(GetDestructableY(targetTree)) + ")")
        set this.lastUseTime = TimerGetElapsed(gameTimer)
        set this.bIsReadyToUse = false
        set this.readyTargetTree = null
        set this.ownerAIHero.eatingTree = targetTree
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
        elseif this.castType == CAST_INSTANT then
            call this.useInstant()
            return true
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
                    set this.readyTargetUnit = null
                    set this.bIsReadyToUse = false
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
        elseif this.castType == CAST_INSTANT_ALLY_CROWDED then
            call this.useInstant()
            return true
        elseif this.castType == CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE then
            call this.useInstant()
            return true
        elseif this.castType == CAST_POINT_ENEMY_FRONT then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No valid target found for item, should be blocked by prepare target: " + GetItemName(this.itemHandle))
                return false
            endif
            
            if not IsUnitValid(targetUnit) then
                set this.readyTargetUnit = null
                set this.bIsReadyToUse = false
                return false
            endif

            // Calculate point in front of target unit
            set targetFacingAngle = GetUnitFacing(this.readyTargetUnit)
            set offset = this.getUnitFrontOffsetDistance(this.readyTargetUnit)
            set this.readyTargetPointX = GetUnitX(this.readyTargetUnit) + offset * Cos(targetFacingAngle * bj_DEGTORAD)
            set this.readyTargetPointY = GetUnitY(this.readyTargetUnit) + offset * Sin(targetFacingAngle * bj_DEGTORAD)
            call this.useToPoint(this.readyTargetPointX, this.readyTargetPointY)
            return true
        elseif this.castType == CAST_POINT_ALLY_FRONT then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No valid target found for item, should be blocked by prepare target: " + GetItemName(this.itemHandle))
                return false
            endif
            
            if not IsUnitValid(targetUnit) then
                set this.readyTargetUnit = null
                set this.bIsReadyToUse = false
                return false
            endif

            // Calculate point in front of target unit
            set targetFacingAngle = GetUnitFacing(targetUnit)
            set offset = this.getUnitFrontOffsetDistance(targetUnit)
            set this.readyTargetPointX = GetUnitX(targetUnit) + offset * Cos(targetFacingAngle * bj_DEGTORAD)
            set this.readyTargetPointY = GetUnitY(targetUnit) + offset * Sin(targetFacingAngle * bj_DEGTORAD)

            call this.useToPoint(this.readyTargetPointX, this.readyTargetPointY)
            return true
        elseif this.castType == CAST_POINT_SELF_FRONT then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No valid target found for item, should be blocked by prepare target: " + GetItemName(this.itemHandle))
                return false
            endif
            
            if not IsUnitValid(targetUnit) then
                set this.readyTargetUnit = null
                set this.bIsReadyToUse = false
                return false
            endif

            // Calculate point in front of self
            set targetFacingAngle = GetUnitFacing(this.ownerHero)
            set offset = this.castRange
            set this.readyTargetPointX = GetUnitX(this.ownerHero) + offset * Cos(targetFacingAngle * bj_DEGTORAD)
            set this.readyTargetPointY = GetUnitY(this.ownerHero) + offset * Sin(targetFacingAngle * bj_DEGTORAD)
            call this.useToPoint(this.readyTargetPointX, this.readyTargetPointY)
            return true
        elseif this.castType == CAST_POINT_SELF_FRONT_HEAL then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No valid target found for item, should be blocked by prepare target: " + GetItemName(this.itemHandle))
                return false
            endif
            
            if not IsUnitValid(targetUnit) then
                set this.readyTargetUnit = null
                set this.bIsReadyToUse = false
                return false
            endif

            // Calculate point in front of self
            set targetFacingAngle = GetUnitFacing(this.ownerHero)
            set offset = this.castRange
            set this.readyTargetPointX = GetUnitX(this.ownerHero) + offset * Cos(targetFacingAngle * bj_DEGTORAD)
            set this.readyTargetPointY = GetUnitY(this.ownerHero) + offset * Sin(targetFacingAngle * bj_DEGTORAD)
            call this.useToPoint(this.readyTargetPointX, this.readyTargetPointY)
            return true
        elseif this.castType == CAST_POINT_SELF_FRONT_DEFENSE_AND_CLEANSE then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No valid target found for item, should be blocked by prepare target: " + GetItemName(this.itemHandle))
                return false
            endif
            
            if not IsUnitValid(targetUnit) then
                set this.readyTargetUnit = null
                set this.bIsReadyToUse = false
                return false
            endif

            // Calculate point in front of self
            set targetFacingAngle = GetUnitFacing(this.ownerHero)
            set offset = this.castRange
            set this.readyTargetPointX = GetUnitX(this.ownerHero) + offset * Cos(targetFacingAngle * bj_DEGTORAD)
            set this.readyTargetPointY = GetUnitY(this.ownerHero) + offset * Sin(targetFacingAngle * bj_DEGTORAD)
            call this.useToPoint(this.readyTargetPointX, this.readyTargetPointY)
            return true
        elseif this.castType == CAST_POINT_ALL_FRONT then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No valid target found for item, should be blocked by prepare target: " + GetItemName(this.itemHandle))
                return false
            endif

            if not IsUnitValid(targetUnit) then
                set this.readyTargetUnit = null
                set this.bIsReadyToUse = false
                return false
            endif

            if this.itemId == 'I003' then  // MeatHook
                if targetUnit == this.ownerHero then
                    // Force to use on side left / right, randomly
                    if GetRandomReal(0.0, 1.0) < 0.5 then
                        set targetFacingAngle = GetUnitFacing(this.ownerHero) + - 90.0
                    else
                        set targetFacingAngle = GetUnitFacing(this.ownerHero) + 90.0
                    endif
                    set offset = this.effectiveRadius
                    set this.readyTargetPointX = GetUnitX(this.ownerHero) + offset * Cos(targetFacingAngle * bj_DEGTORAD)
                    set this.readyTargetPointY = GetUnitY(this.ownerHero) + offset * Sin(targetFacingAngle * bj_DEGTORAD)

                    if this.shouldCheckOtherUnitBlockingTargetUnit() then
                        if IsThereOtherUnitBlockingBetweenXY(this.ownerHero, FIND_TEAM_TYPE_ALL, GetUnitX(this.ownerHero), GetUnitY(this.ownerHero), this.readyTargetPointX, this.readyTargetPointY, this.effectiveRadius) then
                            set this.readyTargetUnit = null
                            set this.bIsReadyToUse = false
                            call this.botLog("Another unit is blocking the target point for item: " + GetItemName(this.itemHandle) + ", cannot use now.")
                            return false
                        endif
                    endif

                    call this.useToPoint(this.readyTargetPointX, this.readyTargetPointY)
                    return true
                endif
            endif
            
            // Calculate point in front of target unit
            set targetFacingAngle = GetUnitFacing(targetUnit)
            set offset = this.getUnitFrontOffsetDistance(targetUnit)
            set this.readyTargetPointX = GetUnitX(targetUnit) + offset * Cos(targetFacingAngle * bj_DEGTORAD)
            set this.readyTargetPointY = GetUnitY(targetUnit) + offset * Sin(targetFacingAngle * bj_DEGTORAD)
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
        elseif this.castType == CAST_POINT_BLINK then
            set targetUnit = this.readyTargetUnit
            if not IsUnitValid(targetUnit) then
                set this.readyTargetUnit = null
                set this.bIsReadyToUse = false
                return false
            endif

            // Calculate blink target point
            set targetFacingAngle = GetUnitFacing(this.ownerHero)
            set this.readyTargetPointX = GetUnitX(this.ownerHero) + this.castRange * Cos(targetFacingAngle * bj_DEGTORAD)
            set this.readyTargetPointY = GetUnitY(this.ownerHero) + this.castRange * Sin(targetFacingAngle * bj_DEGTORAD)
            call this.useToPoint(this.readyTargetPointX, this.readyTargetPointY)
            return true
        elseif this.castType == CAST_UNIT then
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

            call this.useToTargetUnit(targetUnit)
            return true
        elseif this.castType == CAST_UNIT_SELF_THEN_FOLLOW_TARGET then
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
                call this.useToTargetUnit(targetUnit)
                return true
            else
                if DistanceBetweenUnits(this.ownerHero, targetUnit) > this.effectiveRadius * 2.0 then
                    return false
                endif
                // Follow target unit
                if DistanceBetweenUnits(this.ownerHero, targetUnit) <= this.effectiveRadius then
                    call this.useToTargetUnit(this.ownerHero)
                    call this.ownerAIHero.changeState(FollowState.create(targetUnit, this.getFollowTargetDuration(), this.mustHaveBuffCodeWhenFollowing(), true))
                    return true
                else
                    call IssueTargetOrder(this.ownerHero, "move", targetUnit)
                    return true
                endif
            endif
        elseif this.castType == CAST_TREE_FRONT then
            if this.readyTargetTree == null then
                call this.botLogError("No valid target tree found for item, should be blocked by prepare target: " + GetItemName(this.itemHandle))
                set this.bIsReadyToUse = false
                return false
            endif

            call this.useToTargetTree(this.readyTargetTree)
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