library AIUtils requires KeyUtils
    function BotLog takes string msg returns nothing
        if udg_bEnableLogBot then
            call BJDebugMsg("[AI Bot] " + msg)
        endif
    endfunction

    function BotLogWithPlayer takes player p, string msg returns nothing
        local integer playerIndex = GetPlayerId(p) + 1
        local string playerName = ""
        if udg_bEnableLogBot then   
            if playerIndex >= 0 and playerIndex <= 12 then
                set playerName = udg_PlayerNameWithHero[playerIndex]
                if playerName != null and playerName != "" then
                    call BJDebugMsg("[AI Bot] " + playerName + " " + msg)
                else
                    call BJDebugMsg("[AI Bot] Player " + I2S(playerIndex) + " " + msg)
                endif
            else
                call BJDebugMsg("[AI Bot] " + msg)
            endif
        endif
    endfunction

    function BotLogError takes string msg returns nothing
        call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r " + msg)
    endfunction

    function BotLogErrorWithPlayer takes player p, string msg returns nothing
        local integer playerIndex = GetPlayerId(p) + 1
        local string playerName = ""
        if playerIndex >= 0 and playerIndex <= 12 then
            set playerName = udg_PlayerNameWithHero[playerIndex]
            if playerName != null and playerName != "" then
                call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r " + playerName + " " + msg)
            else
                call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r Player " + I2S(playerIndex) + " " + msg)
            endif
        else
            call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r " + msg)
        endif
    endfunction

    function IsPlayerBot takes player p returns boolean
        return IsPlayerInForce(p, udg_BotPlayerGroup)
    endfunction

    // Helper function to get cooldown multiplier based on difficulty
    function GetCooldownMultiplier takes integer difficulty returns real
        if difficulty == DIFF_EASY then
            return EASY_CD_MULTIPLIER
        elseif difficulty == DIFF_NORMAL then
            return NORMAL_CD_MULTIPLIER
        elseif difficulty == DIFF_HARD then
            return HARD_CD_MULTIPLIER
        elseif difficulty == DIFF_CRAZY then
            return CRAZY_CD_MULTIPLIER
        elseif difficulty == DIFF_NIGHTMARE then
            return NIGHTMARE_CD_MULTIPLIER
        else
            return 1.0
        endif
    endfunction

    function IsAIHardOrAbove takes integer difficulty returns boolean
        if difficulty == DIFF_HARD or difficulty == DIFF_CRAZY or difficulty == DIFF_NIGHTMARE then
            return true
        else
            return false
        endif
    endfunction

    function IsDifficultyApplyingCombo takes integer difficulty returns boolean
        return IsAIHardOrAbove(difficulty)
    endfunction

    function IsSmartFindingTargetUnit takes integer difficulty returns boolean
        return IsAIHardOrAbove(difficulty)
    endfunction

    function IsUnitInAnyHazardZone takes unit u returns boolean
        local real ux = GetUnitX(u)
        local real uy = GetUnitY(u)
        if RectContainsCoords(gg_rct_HazardSlowSpikeArea, ux, uy) then
            return true
        endif
        if RectContainsCoords(gg_rct_HazardFastSpikeArea, ux, uy) then
            return true
        endif
        if RectContainsCoords(gg_rct_HazardNetArea, ux, uy) then
            return true
        endif
        if RectContainsCoords(gg_rct_HazardSpiderNetArea, ux, uy) then
            return true
        endif
        return false
    endfunction

    // Get the closest hazard unit around a reference unit
    // Checks for slow spike, net, and spider net hazards
    // Returns the unit if found, null otherwise
    function GetHazardAroundUnit takes unit refUnit, real detectRadius returns unit
        local group hazardGroup = CreateGroup()
        local unit u
        local integer unitTypeId
        local real heroX = GetUnitX(refUnit)
        local real heroY = GetUnitY(refUnit)
        local unit resultUnit = null
        local boolexpr filter = Filter(function AntiLeak)
        local real closestDistance = 99999.0
        local real currentTargetDistance
            
        // Detect locus unit must use GroupEnumUnitsOfPlayer for Player(11)
        call GroupEnumUnitsOfPlayer(hazardGroup, Player(11), filter) 
        loop
            set u = FirstOfGroup(hazardGroup)
            exitwhen u == null

            call GroupRemoveUnit(hazardGroup, u)
            if IsUnitInRangeXY(u, heroX, heroY, detectRadius) then
                set unitTypeId = GetUnitTypeId(u)
                // Check if it's a hazard unit (Aloc is Locus ability)
                if GetUnitAbilityLevel(u, 'Aloc') > 0 then
                    if unitTypeId == SLOW_SPIKE_UNIT_TYPE_ID or unitTypeId == NET_UNIT_TYPE_ID or unitTypeId == SPIDER_NET_UNIT_TYPE_ID then
                        set currentTargetDistance = DistanceBetweenXY(heroX, heroY, GetUnitX(u), GetUnitY(u))
                        if currentTargetDistance < closestDistance then
                            set closestDistance = currentTargetDistance
                            set resultUnit = u
                        endif
                    endif
                endif
            endif
        endloop
        call DestroyGroup(hazardGroup)
        set hazardGroup = null
            
        return resultUnit
    endfunction

    function FilterSuitablePickUpItem takes nothing returns nothing
        local item itm = GetEnumItem()
        local real dist = DistanceBetweenXY(tempFoundItemX, tempFoundItemY, GetItemX(itm), GetItemY(itm))
        local real itemAngle = AngleBetweenXY(tempFoundItemX, tempFoundItemY, GetItemX(itm), GetItemY(itm))
        local boolean bIsInFrontArc = IsWithinForwardArc(itemAngle, tempFoundItemUnitFacingAngle)
        // if IsItemPowerup(itm) then
        //     return
        // endif
        if itm == null then
            call BotLog("FilterSuitablePickUpItem: null item encountered")
            return
        endif
        if GetItemLifeBJ(itm) <= 0.0 then
            return
        endif
        if GetItemTypeId(itm) == 'I01D' then // CompetitionBoots Powerup majia
            return
        endif
        if GetItemTypeId(itm) == 'I02G' then // RingOfSelfDeprecation
            return
        endif
        if not bIsInFrontArc then
            set tempFoundItemRange = tempFoundItemRange * 0.65
        endif
        if dist < tempFoundItemMinDist and dist <= tempFoundItemRange then
            set tempFoundItemMinDist = dist
            set tempFoundItem = itm
        endif
    endfunction

    function GetSuitablePickupItemInRange takes unit u, real range returns item
        local item foundItem = null
        local real ux = GetUnitX(u)
        local real uy = GetUnitY(u)
        local rect rec = Rect(ux - range, uy - range, ux + range, uy + range)

        set tempFoundItem = null
        set tempFoundItemX = ux
        set tempFoundItemY = uy
        set tempFoundItemRange = range
        set tempFoundItemMinDist = 999999.0
        set tempFoundItemUnitFacingAngle = GetUnitFacing(u)

        call EnumItemsInRectBJ(rec, function FilterSuitablePickUpItem)
        call RemoveRect(rec)
        set foundItem = tempFoundItem

        return foundItem
    endfunction

    // Helper function for basic unit validation
    function IsValidHeroTarget takes unit filterUnit returns boolean
        if not IsUnitAliveBJ(filterUnit) then
            return false
        endif
        if not IsUnitType(filterUnit, UNIT_TYPE_HERO) then
            return false
        endif
        if not IsUnitVisible(filterUnit, tempHeroOwner) then
            return false
        endif
        return true
    endfunction

    function IsValidGroundUnitTarget takes unit filterUnit returns boolean
        if not IsUnitAliveBJ(filterUnit) then
            return false
        endif
        if not IsUnitVisible(filterUnit, tempHeroOwner) then
            return false
        endif
        if IsUnitType(filterUnit, UNIT_TYPE_STRUCTURE) then
            return false
        endif
        if IsUnitType(filterUnit, UNIT_TYPE_FLYING) then
            return false
        endif
        return true
    endfunction

    function FilterValidVisibleTeamUnits takes nothing returns boolean
        local unit filterUnit = GetFilterUnit()
        
        if not IsValidGroundUnitTarget(filterUnit) then
            set filterUnit = null
            return false
        endif

        // Check if we want allies or enemies
        if tempFindTeamType == FIND_TEAM_TYPE_ALLIES then
            // Filter for allies (same team, but not the same unit)
            if IsUnitEnemy(filterUnit, tempHeroOwner) then
                set filterUnit = null
                return false
            endif
        elseif tempFindTeamType == FIND_TEAM_TYPE_ENEMIES then
            // Filter for enemies
            if not IsUnitEnemy(filterUnit, tempHeroOwner) then
                set filterUnit = null
                return false
            endif
        elseif tempFindTeamType == FIND_TEAM_TYPE_NONE then
            // No team filtering
        elseif tempFindTeamType == FIND_TEAM_TYPE_ALL then
            // FIND_TEAM_TYPE_ALL - no filtering needed
        endif
        
        set filterUnit = null
        return true
    endfunction

    // Generic filter function for heroes (enemies or allies)
    function FilterValidVisibleTeamHeroes takes nothing returns boolean
        local unit filterUnit = GetFilterUnit()
        
        if not IsValidHeroTarget(filterUnit) then
            set filterUnit = null
            return false
        endif

        // Check if we want allies or enemies
        if tempFindTeamType == FIND_TEAM_TYPE_ALLIES then
            // Filter for allies (same team, but not the same unit)
            if IsUnitEnemy(filterUnit, tempHeroOwner) then
                set filterUnit = null
                return false
            endif
        elseif tempFindTeamType == FIND_TEAM_TYPE_ENEMIES then
            // Filter for enemies
            if not IsUnitEnemy(filterUnit, tempHeroOwner) then
                set filterUnit = null
                return false
            endif
        elseif tempFindTeamType == FIND_TEAM_TYPE_NONE then
            // No team filtering
        elseif tempFindTeamType == FIND_TEAM_TYPE_ALL then
            // FIND_TEAM_TYPE_ALL - no filtering needed
        endif
        
        set filterUnit = null
        return true
    endfunction

    function GetAIHeroFromUnit takes unit u returns AIHero
        if u == null then
            call BotLogError("GetAIHeroFromUnit: null unit provided")
            return 0
        endif
        return LoadInteger(udg_UnitAIHeroMap, GetHandleId(u), 0)
    endfunction

    function GetAIHeroByUnit takes unit u returns AIHero
        return GetAIHeroFromUnit(u)
    endfunction

    function GetAIHeroByPlayer takes player p returns AIHero
        local group playerHeroes = CreateGroup()
        local unit heroUnit
        local AIHero aiHero = 0
        local unit currentUnit

        // Find the hero unit of the player
        call GroupEnumUnitsOfPlayer(playerHeroes, p, Filter(function AntiLeak))
        loop
            set currentUnit = FirstOfGroup(playerHeroes)
            exitwhen currentUnit == null
            call GroupRemoveUnit(playerHeroes, currentUnit)
            if IsUnitType(currentUnit, UNIT_TYPE_HERO) then
                set heroUnit = currentUnit
                exitwhen true
            endif
        endloop
        return GetAIHeroFromUnit(heroUnit)
    endfunction

    function DestroyAIHero takes unit u returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.destroy()
        endif
    endfunction

    function IsHeroGoaled takes unit u returns boolean
        return IsUnitInGroup(u, udg_GoaledHeroes) 
    endfunction

    function IsUnitFacingAlongTrack takes unit u returns boolean
        local real ux = GetUnitX(u)
        local real uy = GetUnitY(u)
        local real nextTrackProgressPointX = 0.0
        local real nextTrackProgressPointY = 0.0
        local real unitFacingAngle = GetUnitFacing(u)
        local real angleToGoal
        local real angleDiff
        local integer TrackProgress = 0

        set TrackProgress = LoadInteger(udg_HeroTrackProgressionMap, GetHandleId(u), S2I( "trackProgress"))

        if TrackProgress == 0 then
            set nextTrackProgressPointX = TopRightAreaCenterX
            set nextTrackProgressPointY = TopRightAreaCenterY
        elseif TrackProgress == 1 then
            set nextTrackProgressPointX = BotRightAreaCenterX
            set nextTrackProgressPointY = BotRightAreaCenterY
        elseif TrackProgress == 2 then
            set nextTrackProgressPointX = GoalX
            set nextTrackProgressPointY = GoalY
        else
            call BotLogError("Unknown Track Progress value: " + I2S(TrackProgress))
            return false
        endif

        set angleToGoal = AngleBetweenXY(ux, uy, nextTrackProgressPointX, nextTrackProgressPointY)
        set angleDiff = Abs(NormalizeAngle(unitFacingAngle) - angleToGoal)
        if angleDiff > 180.0 then
            set angleDiff = 360.0 - angleDiff
        endif
        if angleDiff <= 60.0 then
            return true
        else
            return false
        endif

    endfunction

    // Check Race Position
    function IsUnitLeadingUnit takes unit leadingUnit, unit followingUnit returns boolean
        local real leadingX = GetUnitX(leadingUnit)
        local real leadingY = GetUnitY(leadingUnit)
        local real followingX = GetUnitX(followingUnit)
        local real followingY = GetUnitY(followingUnit)
        local real goalX = GoalX
        local real goalY = GoalY
        local integer TrackProgress = 0
        // Crossing mid track line
        set TrackProgress = MaxI(LoadInteger(udg_HeroTrackProgressionMap, GetHandleId(leadingUnit), S2I("trackProgress")), LoadInteger(udg_HeroTrackProgressionMap, GetHandleId(followingUnit), S2I("trackProgress")))
        if IsHeroGoaled(leadingUnit) or IsHeroGoaled(followingUnit) then
            set TrackProgress = 2
        endif

        if TrackProgress == 0 then
            if DistanceBetweenXY(leadingX, leadingY, TopRightAreaCenterX, TopRightAreaCenterY) < DistanceBetweenXY(followingX, followingY, TopRightAreaCenterX, TopRightAreaCenterY) then
                return true
            else
                return false
            endif
        elseif TrackProgress == 1 then
            if DistanceBetweenXY(leadingX, leadingY, BotRightAreaCenterX, BotRightAreaCenterY) < DistanceBetweenXY(followingX, followingY, BotRightAreaCenterX, BotRightAreaCenterY) then
                return true
            else
                return false
            endif
        elseif TrackProgress == 2 then
            if DistanceBetweenXY(leadingX, leadingY, goalX, goalY) < DistanceBetweenXY(followingX, followingY, goalX, goalY) then
                return true
            else
                return false
            endif
        else
            call BotLogError("Unknown Track Progress value: " + I2S(TrackProgress))
            return false
        endif

        return false
    endfunction

    function IsUnitCarryMoreThanTwoItem takes unit u returns boolean
        local integer itemCount = 0
        local integer i = 0

        loop
            if i == bj_MAX_INVENTORY then
                exitwhen true
            endif
            if UnitItemInSlot(u, i) != null then
                set itemCount = itemCount + 1
            endif
            set i = i + 1
        endloop

        if itemCount >= 2 then
            return true
        endif

        return false
    endfunction


    function IsInSlowSpikeHazardZone takes AIHero aiHero returns boolean
        local integer wpi = aiHero.currentWaypointIndex
        if wpi == 8 then
            return true
        endif
        return false
    endfunction

    function IsInFastSpikeHazardZone takes AIHero aiHero returns boolean
        local integer wpi = aiHero.currentWaypointIndex
        if IsTriggerEnabled(gg_trg_FastSpike) then
            if wpi == 10 then
                return true
            endif
        endif
        return false
    endfunction

    function IsInNetHazardZone takes AIHero aiHero returns boolean
        local integer wpi = aiHero.currentWaypointIndex
        if IsTriggerEnabled(gg_trg_Net01) then
            if wpi == 12 then
                return true
            endif
        endif
        return false
    endfunction

    function IsInSpiderNetHazardZone takes AIHero aiHero returns boolean
        local real heroX = GetUnitX(aiHero.hero)
        local real heroY = GetUnitY(aiHero.hero)
        local integer wpi = aiHero.currentWaypointIndex
        if RectContainsCoords(gg_rct_HazardSpiderNetArea, heroX, heroY) then
            // before finish area
            if wpi == 14 then
                return true
            endif
            // going to crossing tree area
            if wpi == 131 then
                return true
            endif
            if IsHeroGoaled(aiHero.hero) then
                return true
            endif
        endif
        return false
    endfunction

    function IsCurrentGoalWaypoint takes AIHero aiHero returns boolean
        if aiHero.currentWaypointIndex == GoalWaypointIndex then
            return true
        endif
        return false
    endfunction

    function FindIllusionTargetInRange takes unit ownerHero, real range returns unit
        local group targets = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)
        local real currentUnitAttackDamage = 0.0
        local real bestAttackDamage = 0.0
        local real currentDist = 0.0
        local real bestDist = 0.0
        local real closeRange = 3000.0

        // Not Allowed Target: MagicImmune, Building, Flying Unit, Not Alive, Non-hero-no-Attack unit
        // Priority Order:
        // 1. within range 3000
        // 2. Highest Attack Damage
        // 3. Highest Health
        // 4. Hero Unit

        call GroupEnumUnitsInRange(targets, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function AntiLeak))
        call BotLogWithPlayer(heroOwner, "Found " + I2S(CountUnitsInGroup(targets)) + " potential illusion targets")    

        loop
            set currentUnit = FirstOfGroup(targets)
            exitwhen currentUnit == null
            call GroupRemoveUnit(targets, currentUnit)
            call BotLogWithPlayer(heroOwner, "Evaluating illusion target: " + GetUnitName(currentUnit))
            set currentUnitAttackDamage = GetUnitMaxAttackDamage(currentUnit)
            call BotLogWithPlayer(heroOwner, "Current unit attack damage: " + R2S(currentUnitAttackDamage))

            // --- VALIDATION LAYER ---
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
            elseif IsUnitType(currentUnit, UNIT_TYPE_STRUCTURE) then
            elseif IsUnitType(currentUnit, UNIT_TYPE_FLYING) then
            elseif not IsUnitAliveBJ(currentUnit) then
            elseif IsUnitType(currentUnit, UNIT_TYPE_HERO) == false and currentUnitAttackDamage <= 0 then
            elseif bestTarget == null then
                call BotLogWithPlayer(heroOwner, "Selected illusion target: " + GetUnitName(currentUnit))
                set bestTarget = currentUnit
            else
                set currentDist = DistanceBetweenUnits(ownerHero, currentUnit)
                set bestDist = DistanceBetweenUnits(ownerHero, bestTarget)
                set bestAttackDamage = GetUnitStateSwap(ConvertUnitState(0x15), bestTarget)
                
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. within close range priority
                if currentDist <= closeRange then
                    if bestDist > closeRange then
                        set bestTarget = currentUnit
                    else
                        // 2. Highest Attack Damage
                        if currentUnitAttackDamage > bestAttackDamage then
                            set bestTarget = currentUnit
                        elseif currentUnitAttackDamage == bestAttackDamage then
                            // 3. Highest Health
                            if GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) > GetUnitStateSwap(UNIT_STATE_LIFE, bestTarget) then
                                set bestTarget = currentUnit
                            endif
                        endif
                    endif
                elseif bestDist > closeRange then
                    if currentUnitAttackDamage > bestAttackDamage then
                        set bestTarget = currentUnit
                    elseif currentUnitAttackDamage == bestAttackDamage then
                        if GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) > GetUnitStateSwap(UNIT_STATE_LIFE, bestTarget) then
                            set bestTarget = currentUnit
                        endif
                    endif
                endif
            endif
        endloop

        // Clean up
        call DestroyGroup(targets)
        set targets = null
        return bestTarget

    endfunction

    function FindControlUnitEnemyTargetInRange takes unit ownerHero, real range, AIAbility abil, AIItem itm returns unit
        local group enemies = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)
    
        set enemies = GetUnitsOfTypeIdAll( 'n00P') // Tower
        if CountUnitsInGroup(enemies) > 0 then
            loop 
                set currentUnit = FirstOfGroup(enemies)
                exitwhen currentUnit == null
                call GroupRemoveUnit(enemies, currentUnit)
                if IsUnitAliveBJ(currentUnit) and IsUnitEnemy(currentUnit, heroOwner) then
                    set bestTarget = currentUnit
                    exitwhen true
                endif
            endloop
            if bestTarget != null then
                call DestroyGroup(enemies)
                return bestTarget
            endif
        endif
        set enemies = GetUnitsOfTypeIdAll( 'nzlc') // Lich King
        if CountUnitsInGroup(enemies) > 0 then
            loop 
                set currentUnit = FirstOfGroup(enemies)
                exitwhen currentUnit == null
                call GroupRemoveUnit(enemies, currentUnit)
                if IsUnitAliveBJ(currentUnit) and not IsUnitOwnedByPlayer(currentUnit, heroOwner) then
                    set bestTarget = currentUnit
                    exitwhen true
                endif
            endloop
            if bestTarget != null then
                call DestroyGroup(enemies)
                return bestTarget
            endif
        endif
        set enemies = GetUnitsOfTypeIdAll( 'n00U') // Purple Fish
        if CountUnitsInGroup(enemies) > 0 then
            loop 
                set currentUnit = FirstOfGroup(enemies)
                exitwhen currentUnit == null
                call GroupRemoveUnit(enemies, currentUnit)
                if IsUnitAliveBJ(currentUnit) and IsUnitEnemy(currentUnit, heroOwner) then
                    set bestTarget = currentUnit
                    exitwhen true
                endif
            endloop
            if bestTarget != null then
                call DestroyGroup(enemies)
                return bestTarget
            endif
        endif

        // Not Allowed Target: MagicImmune, customFilter, ally unit, hero unit, unit level > 10, Building, Flying Unit, Not Alive
        // Priority Order:
        // 1. Closest to Hero Priority

        // get random non-hero enemy unit close to ownerHero
        call GroupEnumUnitsInRange(enemies, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function AntiLeak))
        call BotLogWithPlayer(heroOwner, "Found " + I2S(CountUnitsInGroup(enemies)) + " potential control unit targets")    

        loop
            set currentUnit = FirstOfGroup(enemies)
            exitwhen currentUnit == null
            call GroupRemoveUnit(enemies, currentUnit)
            call BotLogWithPlayer(heroOwner, "Evaluating control unit target: " + GetUnitName(currentUnit))

            // --- VALIDATION LAYER ---
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
            elseif tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
            elseif tempAIItem != 0 and not tempAIItem.customFilter(currentUnit) then
            elseif not IsUnitEnemy(currentUnit, heroOwner) then
            elseif IsUnitType(currentUnit, UNIT_TYPE_HERO) then
            elseif IsUnitType(currentUnit, UNIT_TYPE_STRUCTURE) then
            elseif IsUnitType(currentUnit, UNIT_TYPE_FLYING) then
            elseif not IsUnitAliveBJ(currentUnit) then
            elseif GetUnitLevel(currentUnit) > 10 then
            elseif bestTarget == null then
                call BotLogWithPlayer(heroOwner, "Selected control unit target: " + GetUnitName(currentUnit))
                set bestTarget = currentUnit
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. Closest to Hero Priority
                if DistanceBetweenUnits(ownerHero, currentUnit) < DistanceBetweenUnits(ownerHero, bestTarget) then
                    call BotLogWithPlayer(heroOwner, "Switched control unit target to: " + GetUnitName(currentUnit))
                    set bestTarget = currentUnit
                endif
            endif
        endloop

        // Clean up
        call DestroyGroup(enemies)
        set enemies = null

        return bestTarget
    endfunction

    function IsPointOnLineSegment takes real x1, real y1, real x2, real y2, real px, real py, real tolerance returns boolean
        local real lineMag = DistanceBetweenXY(x1, y1, x2, y2)
        local real u
        local real ix
        local real iy
        local real dist
        local real buffer = 0.0
        if IsNearlyZero(lineMag) then
            return false // Line segment is too short
        endif

        set buffer = 300.0 / lineMag

        // Calculate the projection of point P onto the line defined by points (x1, y1) and (x2, y2)
        // u is the normalized distance from (x1, y1) to the projection point
        set u = ((px - x1) * (x2 - x1) + (py - y1) * (y2 - y1)) / (lineMag * lineMag) 
        if u < (0.0 - buffer) or u > (1.0 + buffer) then
            call BotLog("Point is outside the line segment with buffer: u=" + R2S(u))
            return false // Point is outside the line segment
        endif

        // Find the closest point on the line segment
        set ix = x1 + u * (x2 - x1)
        set iy = y1 + u * (y2 - y1)
        set dist = DistanceBetweenXY(px, py, ix, iy)

        if dist <= tolerance then
            return true
        else
            return false
        endif
    endfunction

    function IsThereOtherUnitBlockingBetweenUnits takes unit sourceUnit, unit targetUnit, real tolerance returns boolean
        local group unitsBetween = CreateGroup()
        local unit currentUnit = null
        local real sx = GetUnitX(sourceUnit)
        local real sy = GetUnitY(sourceUnit)
        local real tx = GetUnitX(targetUnit)
        local real ty = GetUnitY(targetUnit)
        local real midX = (sx + tx) / 2.0
        local real midY = (sy + ty) / 2.0
        local real range = DistanceBetweenXY(sx, sy, tx, ty) / 2.0 + 300.0 // extra buffer

        set tempHeroOwner = GetOwningPlayer(sourceUnit)
        set tempHeroUnit = sourceUnit
        set tempFindTeamType = FIND_TEAM_TYPE_ALL
        set tempAIAbility = 0
        set tempAIItem = 0

        call GroupEnumUnitsInRange(unitsBetween, midX, midY, range, Filter(function FilterValidVisibleTeamUnits))

        // Exclude Flying and Structures

        loop
            set currentUnit = FirstOfGroup(unitsBetween)
            exitwhen currentUnit == null
            call GroupRemoveUnit(unitsBetween, currentUnit)

            call BotLogWithPlayer(GetOwningPlayer(sourceUnit), "Checking unit in between: " + GetUnitName(currentUnit))

            if IsUnitType(currentUnit, UNIT_TYPE_FLYING) then
            elseif IsUnitType(currentUnit, UNIT_TYPE_STRUCTURE) then
            elseif currentUnit != sourceUnit and currentUnit != targetUnit then
                if IsPointOnLineSegment(sx, sy, tx, ty, GetUnitX(currentUnit), GetUnitY(currentUnit), tolerance) then
                    // Found blocking unit
                    call DestroyGroup(unitsBetween)
                    return true
                endif
            endif
        endloop

        // Clean up
        call DestroyGroup(unitsBetween)
        set unitsBetween = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempAIItem = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE

        return false
    endfunction
    
    function FindTrailingAllyTargetInRange takes unit ownerHero, real range, real minDistance, AIAbility abil, AIItem itm returns unit
        local group allies = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)
        local boolean bShouldCheckOtherUnitBlockingTargetUnit = false
        local real tolerance = 50.0
    
        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = FIND_TEAM_TYPE_ALLIES
        set tempHeroUnit = ownerHero
        set tempAIAbility = abil
        set tempAIItem = itm
        call GroupEnumUnitsInRange(allies, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamHeroes))

        if itm != 0 then
            set bShouldCheckOtherUnitBlockingTargetUnit = itm.shouldCheckOtherUnitBlockingTargetUnit()
            set tolerance = itm.effectiveRadius
        endif

        // Not Allowed Target: customFilter, not trailing, goaled hero, within min distance, blocked by other unit if applicable
        // Priority Order:
        // 1 furthest

        loop
            set currentUnit = FirstOfGroup(allies)
            exitwhen currentUnit == null
            call GroupRemoveUnit(allies, currentUnit)

            call BotLogWithPlayer(heroOwner, "Evaluating Trailing Ally target: " + GetUnitName(currentUnit))

            // --- VALIDATION LAYER ---
            if tempAIItem != 0 and not tempAIItem.customFilter(currentUnit) then
            elseif tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
            elseif IsHeroGoaled(currentUnit) then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is goaled")
            elseif IsUnitLeadingUnit(currentUnit, ownerHero) then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is not trailing in race position")
            elseif bShouldCheckOtherUnitBlockingTargetUnit and IsThereOtherUnitBlockingBetweenUnits(ownerHero, currentUnit, tolerance) then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is blocked by another unit")
            elseif DistanceBetweenUnits(ownerHero, currentUnit) < minDistance then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is within min distance") 
            elseif bestTarget == null then
                set bestTarget = currentUnit
                call BotLogWithPlayer(heroOwner, "Selected trailing ally target: " + GetUnitName(currentUnit))
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. Furthest from Front Priority
                if DistanceBetweenUnits(ownerHero, currentUnit) > DistanceBetweenUnits(ownerHero, bestTarget) then
                    set bestTarget = currentUnit
                    call BotLogWithPlayer(heroOwner, "Switched trailing ally target to: " + GetUnitName(currentUnit))
                endif
            endif
        endloop
        // Clean up
        call DestroyGroup(allies)
        set allies = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempAIItem = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE
        return bestTarget
    endfunction

    function FindLeadingEnemyTargetInRange takes unit ownerHero, real range, real minDistance, AIAbility abil, AIItem itm returns unit
        local group enemies = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)
        local boolean bShouldCheckOtherUnitBlockingTargetUnit = false
        local real tolerance = 50.0
    
        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = FIND_TEAM_TYPE_ENEMIES
        set tempHeroUnit = ownerHero
        set tempAIAbility = abil
        set tempAIItem = itm
        call GroupEnumUnitsInRange(enemies, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamHeroes))

        if itm != 0 then
            set bShouldCheckOtherUnitBlockingTargetUnit = itm.shouldCheckOtherUnitBlockingTargetUnit()
            set tolerance = itm.effectiveRadius
        endif


        // Not Allowed Target: customFilter, not leading, goaled hero, within min distance, blocked by other unit if applicable
        // Priority Order:
        // 1 furthest
        loop
            set currentUnit = FirstOfGroup(enemies)
            exitwhen currentUnit == null
            call GroupRemoveUnit(enemies, currentUnit)
            call BotLogWithPlayer(heroOwner, "Evaluating Leading enemy target: " + GetUnitName(currentUnit))

            // --- VALIDATION LAYER ---
            if tempAIItem != 0 and not tempAIItem.customFilter(currentUnit) then
            elseif tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
            elseif IsHeroGoaled(currentUnit) then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is goaled")
            elseif not IsUnitLeadingUnit(currentUnit, ownerHero) then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is not leading in race position")
            elseif DistanceBetweenUnits(ownerHero, currentUnit) < minDistance then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is within min distance")
            elseif bShouldCheckOtherUnitBlockingTargetUnit and IsThereOtherUnitBlockingBetweenUnits(ownerHero, currentUnit, tolerance) then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is blocked by another unit")
            elseif bestTarget == null then
                set bestTarget = currentUnit
                call BotLogWithPlayer(heroOwner, "Selected enemy target: " + GetUnitName(currentUnit))
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. Furthest from Front Priority
                if DistanceBetweenUnits(ownerHero, currentUnit) > DistanceBetweenUnits(ownerHero, bestTarget) then
                    set bestTarget = currentUnit
                    call BotLogWithPlayer(heroOwner, "Switched enemy target to: " + GetUnitName(currentUnit))
                endif
            endif
        endloop

        // Clean up
        call DestroyGroup(enemies)
        set enemies = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempAIItem = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE

        return bestTarget
    endfunction

    function FindFrontTargetInRange takes unit ownerHero, real range, integer findTeamType, real minDistance, boolean bHeroOnly, AIAbility abil, AIItem itm returns unit
        local group enemies = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)
        local boolean bShouldCheckOtherUnitBlockingTargetUnit = false
        local real tolerance = 50.0
        local boolean bIgnoreMagicImmune = false
    
        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = findTeamType
        set tempHeroUnit = ownerHero
        set tempAIAbility = abil
        set tempAIItem = itm
        call BotLogWithPlayer(heroOwner, "bHeroOnly: " + B2S(bHeroOnly))
        if bHeroOnly then
            call GroupEnumUnitsInRange(enemies, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamHeroes))
        else
            call BotLogWithPlayer(heroOwner, "Finding front target in range " + R2S(range) + " (All Units)")
            call GroupEnumUnitsInRange(enemies, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamUnits))
        endif

        // Not Allowed Target: MagicImmune, customFilter, back of hero, within min distance, blocked by other unit if applicable, not leading (Race Position)
        // Priority Order:
        // 1. furthest

        if itm != 0 then
            set bShouldCheckOtherUnitBlockingTargetUnit = itm.shouldCheckOtherUnitBlockingTargetUnit()
            set tolerance = itm.effectiveRadius
            set bIgnoreMagicImmune = itm.isIgnoreMagicImmune()
        endif

        loop
            set currentUnit = FirstOfGroup(enemies)
            exitwhen currentUnit == null
            call GroupRemoveUnit(enemies, currentUnit)
            call BotLogWithPlayer(heroOwner, "Evaluating Front target: " + GetUnitName(currentUnit))
            // --- VALIDATION LAYER ---
            if IsUnitInvulnerableOrMagicImmune(currentUnit) and not bIgnoreMagicImmune then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is invulnerable or magic immune")
            elseif tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
            elseif tempAIItem != 0 and not tempAIItem.customFilter(currentUnit) then
            elseif not IsHeroGoaled(ownerHero) and IsUnitBehindUnit(currentUnit, ownerHero) then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is behind the owner hero")
            elseif DistanceBetweenUnits(ownerHero, currentUnit) < minDistance then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is within min distance")
            elseif bShouldCheckOtherUnitBlockingTargetUnit and IsThereOtherUnitBlockingBetweenUnits(ownerHero, currentUnit, tolerance) then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is blocked by another unit")
            elseif not IsUnitLeadingUnit(currentUnit, ownerHero) then
                call BotLogWithPlayer(heroOwner, "Target " + GetUnitName(currentUnit) + " is not leading in race position")
            elseif bestTarget == null then
                set bestTarget = currentUnit
                call BotLogWithPlayer(heroOwner, "Selected front target: " + GetUnitName(currentUnit))
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. Furthest from Front Priority
                if DistanceBetweenUnits(ownerHero, currentUnit) > DistanceBetweenUnits(ownerHero, bestTarget) then
                    set bestTarget = currentUnit
                    call BotLogWithPlayer(heroOwner, "Switched front target to: " + GetUnitName(currentUnit))
                endif
            endif
        endloop

        // Clean up
        call DestroyGroup(enemies)
        set enemies = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE

        return bestTarget
    endfunction

    function FindBackOrCloseEnemyTargetInRange takes unit ownerHero, real backRange, real closeRange, boolean bExcludeClose, AIAbility abil, AIItem itm returns unit
        local group enemies = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)

        if closeRange > backRange then
            call BotLogErrorWithPlayer(heroOwner, "FindBackOrCloseEnemyTargetInRange: closeRange: " + R2S(closeRange) + " > backRange: " + R2S(backRange))
            return null
        endif
    
        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = FIND_TEAM_TYPE_ENEMIES
        set tempHeroUnit = ownerHero
        set tempAIAbility = abil
        set tempAIItem = itm
        call GroupEnumUnitsInRange(enemies, GetUnitX(ownerHero), GetUnitY(ownerHero), backRange, Filter(function FilterValidVisibleTeamHeroes))

        // Not Allowed Target: MagicImmune, customFilter, front of hero if bExcludeClose is true, leading hero
        // Priority Order:
        // 1. closest to back of hero

        loop
            set currentUnit = FirstOfGroup(enemies)
            exitwhen currentUnit == null
            call GroupRemoveUnit(enemies, currentUnit)

            // --- VALIDATION LAYER ---
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
            elseif tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
            elseif tempAIItem != 0 and not tempAIItem.customFilter(currentUnit) then
            elseif not IsHeroGoaled(ownerHero) and IsUnitInFrontOfUnit(currentUnit, ownerHero) and bExcludeClose then
            elseif IsUnitLeadingUnit(currentUnit, ownerHero) and bExcludeClose then
            elseif DistanceBetweenUnits(ownerHero, currentUnit) > closeRange and not bExcludeClose and IsUnitInFrontOfUnit(currentUnit, ownerHero) and IsUnitLeadingUnit(currentUnit, ownerHero) then
                // Exclude units that are not close and also in front and leading
            elseif bestTarget == null then
                set bestTarget = currentUnit
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. Closest to Back Priority
                if DistanceBetweenUnits(ownerHero, currentUnit) < DistanceBetweenUnits(ownerHero, bestTarget) then
                    set bestTarget = currentUnit
                endif
            endif
        endloop

        // Clean up
        call DestroyGroup(enemies)
        set enemies = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE

        return bestTarget
    endfunction

    // Not For Enemy because not good for killing
    function FindLowHealthTargetInRange takes unit ownerHero, real range, integer findTeamType, AIAbility abil, AIItem itm returns unit
        local group units = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)
        local real lowestHealthPercent = 30.0
    
        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = findTeamType
        set tempHeroUnit = ownerHero
        set tempAIAbility = abil
        set tempAIItem = itm
        call GroupEnumUnitsInRange(units, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamHeroes))

        // Not Allowed Target: MagicImmune if findTeamType == FIND_TEAM_TYPE_ENEMIES, customFilter, Hp above certain threshold
        // Priority Order:
        // 1. Lowest Health

        loop
            set currentUnit = FirstOfGroup(units)
            exitwhen currentUnit == null
            call GroupRemoveUnit(units, currentUnit)

            // --- VALIDATION LAYER ---
            if IsUnitInvulnerableOrMagicImmune(currentUnit) and tempFindTeamType == FIND_TEAM_TYPE_ENEMIES then
            elseif tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
            elseif tempAIItem != 0 and not tempAIItem.customFilter(currentUnit) then
            elseif GetUnitLifePercent(currentUnit) > lowestHealthPercent then
            elseif bestTarget == null then
                set bestTarget = currentUnit
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. Lowest Health Priority
                if GetUnitLifePercent(currentUnit) < GetUnitLifePercent(bestTarget) then
                    set bestTarget = currentUnit
                endif
            endif
        endloop

        // Clean up
        call DestroyGroup(units)
        set units = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempAIItem = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE

        return bestTarget
    endfunction

    function FindCCedTargetInRange takes unit ownerHero, real range, integer findTeamType, boolean bExcludeSelf, AIAbility abil, AIItem itm returns unit
        local group units = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)
    
        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = findTeamType
        set tempHeroUnit = ownerHero
        set tempAIAbility = abil
        set tempAIItem = itm
        call GroupEnumUnitsInRange(units, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamHeroes))

        // Not Allowed Target: MagicImmune, customFilter, not CCed, self if bExcludeSelf
        // Priority Order: 
        // 1. Ungoaled

        loop
            set currentUnit = FirstOfGroup(units)
            exitwhen currentUnit == null
            call GroupRemoveUnit(units, currentUnit)

            // --- VALIDATION LAYER ---
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
            elseif tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
            elseif tempAIItem != 0 and not tempAIItem.customFilter(currentUnit) then
            elseif not IsUnitStunOrSlow(currentUnit) then
            elseif bExcludeSelf and currentUnit == ownerHero then
            elseif bestTarget == null then
                set bestTarget = currentUnit
                exitwhen true
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. Ungoaled Priority
                if not IsHeroGoaled(currentUnit) and IsHeroGoaled(bestTarget) then
                    set bestTarget = currentUnit
                elseif IsHeroGoaled(currentUnit) and not IsHeroGoaled(bestTarget) then
                    // Keep bestTarget
                endif
            endif
        endloop

        // Clean up
        call DestroyGroup(units)
        set units = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempAIItem = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE

        return bestTarget
    endfunction

    function FindDeathCoilAllyTargetInRange takes unit ownerHero, real range, real expectedDamage returns unit
        local group targets = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)
    
        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = FIND_TEAM_TYPE_ALL
        set tempHeroUnit = ownerHero
        set tempAIAbility = 0
        set tempAIItem = 0
        call GroupEnumUnitsInRange(targets, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamHeroes))

        // Not Allowed Target: magic immune, Ally HP above heal threshold, Undead enemy, Non-undead ally
        // Priority Order:
        // 1. Allies
        // 2. Lowest Health
        // 2. Killable enemy
        // 3. Highest Health enemy (avoid overkill)

        loop
            set currentUnit = FirstOfGroup(targets)
            exitwhen currentUnit == null
            call GroupRemoveUnit(targets, currentUnit)

            // --- VALIDATION LAYER ---
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
            elseif IsUnitUndead(currentUnit) and IsUnitEnemy(currentUnit, heroOwner) then
            elseif not IsUnitUndead(currentUnit) and IsUnitAlly(currentUnit, heroOwner) then
            elseif GetUnitLifePercent(currentUnit) > HEAL_HP_PERCENTAGE_THRESHOLD and not IsUnitEnemy(currentUnit, heroOwner) then
            elseif bestTarget == null then
                set bestTarget = currentUnit
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. Allies Priority
                if IsUnitAlly(currentUnit, heroOwner) and not IsUnitAlly(bestTarget, heroOwner) then
                    set bestTarget = currentUnit
                elseif not IsUnitAlly(currentUnit, heroOwner) and IsUnitAlly(bestTarget, heroOwner) then
                    // Keep bestTarget
                else
                    // TIE on Ally Status (Both Ally or Both Enemy)
                    if IsUnitAlly(currentUnit, heroOwner) then
                        // 2. Lowest Health Priority (Ally)
                        if GetUnitLifePercent(currentUnit) < GetUnitLifePercent(bestTarget) then
                            set bestTarget = currentUnit
                        endif
                    else
                        // Enemy Target
                        // 2. Killable Enemy Priority
                        if GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) <= expectedDamage and GetUnitStateSwap(UNIT_STATE_LIFE, bestTarget) > expectedDamage then
                            set bestTarget = currentUnit
                        elseif GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) > expectedDamage and GetUnitStateSwap(UNIT_STATE_LIFE, bestTarget) <= expectedDamage then
                            // Keep bestTarget
                        else
                            // TIE on Killable Status
                            if GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) <= expectedDamage and GetUnitStateSwap(UNIT_STATE_LIFE, bestTarget) <= expectedDamage then
                                // Both Killable - Choose Highest HP
                                if GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) > GetUnitStateSwap(UNIT_STATE_LIFE, bestTarget) then
                                    set bestTarget = currentUnit
                                endif
                            else
                                // Both Not Killable - Choose Lowest HP
                                if GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) < GetUnitStateSwap(UNIT_STATE_LIFE, bestTarget) then
                                    set bestTarget = currentUnit
                                endif
                            endif
                        endif
                    endif
                endif
            endif   
        endloop

        // Clean up
        call DestroyGroup(targets)
        set targets = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempAIItem = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE
        return bestTarget
    endfunction

    function FindHolyLightAllyTargetInRange takes unit ownerHero, real range, real expectedDamage returns unit
        local group targets = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)
        local real lowHpPercent = HEAL_HP_PERCENTAGE_THRESHOLD

        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = FIND_TEAM_TYPE_ALL
        set tempHeroUnit = ownerHero
        set tempAIAbility = 0
        set tempAIItem = 0
        call GroupEnumUnitsInRange(targets, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamHeroes))

        // Not Allowed Target: magic immune, Ally HP above heal threshold, Undead Ally, Non-undead enemy
        // Priority Order:
        // 1. Allies
        // 2. Lowest Health
        // 2. Killable enemy
        // 3. Highest Health enemy (avoid overkill)

        loop
            set currentUnit = FirstOfGroup(targets)
            exitwhen currentUnit == null
            call GroupRemoveUnit(targets, currentUnit)

            // --- VALIDATION LAYER ---
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
            elseif GetUnitLifePercent(currentUnit) > lowHpPercent then
            elseif IsUnitUndead(currentUnit) and IsUnitAlly(currentUnit, heroOwner) then
            elseif not IsUnitUndead(currentUnit) and IsUnitEnemy(currentUnit, heroOwner) then
            elseif bestTarget == null then
                set bestTarget = currentUnit
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. Allies Priority
                if IsUnitAlly(currentUnit, heroOwner) and not IsUnitAlly(bestTarget, heroOwner) then
                    set bestTarget = currentUnit
                elseif not IsUnitAlly(currentUnit, heroOwner) and IsUnitAlly(bestTarget, heroOwner) then
                    // Keep bestTarget
                else
                    // TIE on Ally Status (Both Ally or Both Enemy)
                    if IsUnitAlly(currentUnit, heroOwner) then
                        // 2. Lowest Health Priority (Ally)
                        if GetUnitLifePercent(currentUnit) < GetUnitLifePercent(bestTarget) then
                            set bestTarget = currentUnit
                        endif
                    else
                        // Enemy Target
                        // 2. Killable Enemy Priority
                        if GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) <= expectedDamage and GetUnitStateSwap(UNIT_STATE_LIFE, bestTarget) > expectedDamage then
                            set bestTarget = currentUnit
                        elseif GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) > expectedDamage and GetUnitStateSwap(UNIT_STATE_LIFE, bestTarget) <= expectedDamage then
                            // Keep bestTarget
                        else
                            // TIE on Killable Status
                            if GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) <= expectedDamage and GetUnitStateSwap(UNIT_STATE_LIFE, bestTarget) <= expectedDamage then
                                // Both Killable - Choose Highest HP
                                if GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) > GetUnitStateSwap(UNIT_STATE_LIFE, bestTarget) then
                                    set bestTarget = currentUnit
                                endif
                            else
                                // Both Not Killable - Choose Lowest HP
                                if GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) < GetUnitStateSwap(UNIT_STATE_LIFE, bestTarget) then
                                    set bestTarget = currentUnit
                                endif
                            endif
                        endif
                    endif
                endif
            endif   
        endloop

        // Clean up
        call DestroyGroup(targets)
        set targets = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempAIItem = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE
        return bestTarget
    endfunction

    function FindHealAllyTargetInRange takes unit ownerHero, real range, AIAbility abil, AIItem itm returns unit
        local group allies = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)
        local real lowHpPercent = HEAL_HP_PERCENTAGE_THRESHOLD
    
        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = FIND_TEAM_TYPE_ALLIES
        set tempHeroUnit = ownerHero
        set tempAIAbility = abil
        set tempAIItem = itm
        call GroupEnumUnitsInRange(allies, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamHeroes))

        // Not Allowed Target: magic immune, customFilter, HP above certain threshold, CCed
        // Priority Order:
        // 1. Ungoaled
        // 2. Lowest Health

        loop
            set currentUnit = FirstOfGroup(allies)
            exitwhen currentUnit == null
            call GroupRemoveUnit(allies, currentUnit)

            // --- VALIDATION LAYER ---
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
            elseif tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
            elseif tempAIItem != 0 and not tempAIItem.customFilter(currentUnit) then
            elseif GetUnitLifePercent(currentUnit) > lowHpPercent then
            elseif IsUnitStunOrSlow(currentUnit) then
            elseif bestTarget == null then
                set bestTarget = currentUnit
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. Ungoaled Priority
                if not IsHeroGoaled(currentUnit) and IsHeroGoaled(bestTarget) then
                    set bestTarget = currentUnit
                elseif IsHeroGoaled(currentUnit) and not IsHeroGoaled(bestTarget) then
                    // Keep bestTarget
                else
                    // TIE on Goaled Status (Both Goaled or Both Ungoaled)
                    // 2. Lowest Health Priority
                    if GetUnitLifePercent(currentUnit) < GetUnitLifePercent(bestTarget) then
                        set bestTarget = currentUnit
                    endif
                endif
            endif
        endloop

        // Clean up
        call DestroyGroup(allies)
        set allies = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempAIItem = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE

        return bestTarget
    endfunction

    function FindHealthyRunningEnemyTargetInRange takes unit ownerHero, real range, AIAbility abil, AIItem itm returns unit
        local group enemies = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)
        local real healthyHpPercent = 50.0
    
        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = FIND_TEAM_TYPE_ENEMIES
        set tempHeroUnit = ownerHero
        set tempAIAbility = abil
        set tempAIItem = itm
        call GroupEnumUnitsInRange(enemies, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamHeroes))

        // Not Allowed Target: MagicImmune, customFilter, CCed
        // Priority Order:
        // 1. Ungoaled
        // 1. In Hazard Zone
        // 2. Healthy (HP > 50%)
        // 3. Fastest Move Speed
            
        loop
            set currentUnit = FirstOfGroup(enemies)
            exitwhen currentUnit == null
            call GroupRemoveUnit(enemies, currentUnit)

            // --- VALIDATION LAYER ---
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
            elseif tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
            elseif tempAIItem != 0 and not tempAIItem.customFilter(currentUnit) then
            elseif IsUnitStunOrSlow(currentUnit) then
            elseif bestTarget == null then
                set bestTarget = currentUnit
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. Ungoaled Priority
                if not IsHeroGoaled(currentUnit) and IsHeroGoaled(bestTarget) then
                    set bestTarget = currentUnit
                elseif IsHeroGoaled(currentUnit) and not IsHeroGoaled(bestTarget) then
                    // Keep bestTarget
                else
                    // TIE on Goaled Status (Both Goaled or Both Ungoaled)
                    // 2. In Hazard Zone Priority
                    if IsUnitInAnyHazardZone(currentUnit) and not IsUnitInAnyHazardZone(bestTarget) then
                        set bestTarget = currentUnit
                    elseif not IsUnitInAnyHazardZone(currentUnit) and IsUnitInAnyHazardZone(bestTarget) then
                        // Keep bestTarget
                    else
                        // TIE on Hazard Zone (Both in or both out)
                        // 3. Healthy Priority
                        if GetUnitLifePercent(currentUnit) > healthyHpPercent and GetUnitLifePercent(bestTarget) <= healthyHpPercent then
                            set bestTarget = currentUnit
                        elseif GetUnitLifePercent(currentUnit) <= healthyHpPercent and GetUnitLifePercent(bestTarget) > healthyHpPercent then
                            // Keep bestTarget
                        else
                            // TIE on Health Bracket (Both > 50% or Both <= 50%)
                            // 4. Fastest Move Speed Priority  
                            if GetUnitMoveSpeed(currentUnit) > GetUnitMoveSpeed(bestTarget) then
                                set bestTarget = currentUnit
                            endif
                        endif
                    endif
                endif
            endif
        endloop

        // Clean up
        call DestroyGroup(enemies)
        set enemies = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempAIItem = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE

        return bestTarget
    endfunction

    function FindSpeedUpAllyTargetInRange takes unit ownerHero, real range, AIAbility abil returns unit
        local group heroes = CreateGroup()
        local unit currentUnit = null
        local real minHpPercent = 50.0 
        local unit bestTarget = null
        local real minSpeed = 200.0
        local real maxSpeed = 300.0
        local player heroOwner = GetOwningPlayer(ownerHero)
    
        // Comparison variables
        local real currentHp
        local real bestHp
        local boolean isCurrentBehind
        local boolean isBestBehind
        local real currentDist
        local real bestDist

        // Not Allowed Target: MagicImmune, customFilter, CCed, In Hazard Zone, Speed <200 or >300, Goaled Hero
        // Priority Order:
        // 1. HP >= 50%
        // 2. Behind
        // 3. Far from Hero
        // 4. Self

        set tempHeroOwner = heroOwner
        set tempFindTeamType = FIND_TEAM_TYPE_ALLIES
        set tempHeroUnit = ownerHero
        set tempAIAbility = abil
        call GroupEnumUnitsInRange(heroes, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamHeroes))
            
        loop
            set currentUnit = FirstOfGroup(heroes)
            exitwhen currentUnit == null
            call GroupRemoveUnit(heroes, currentUnit)

            // --- VALIDATION LAYER ---
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
            elseif tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
            elseif IsUnitStunOrSlow(currentUnit) then
            elseif IsUnitInAnyHazardZone(currentUnit) then
            elseif GetUnitMoveSpeed(currentUnit) < minSpeed or GetUnitMoveSpeed(currentUnit) > maxSpeed then
            elseif IsHeroGoaled(currentUnit) then
            elseif bestTarget == null then
                set bestTarget = currentUnit
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                set currentHp = GetUnitLifePercent(currentUnit)
                set bestHp = GetUnitLifePercent(bestTarget)

                // 1. HP >= 50% Priority
                if currentHp >= minHpPercent and bestHp < minHpPercent then
                    set bestTarget = currentUnit
                elseif currentHp < minHpPercent and bestHp >= minHpPercent then
                    // Keep bestTarget
                else
                    // TIE on HP Bracket (Both >= 50% or Both < 50%)
                    // 2. Behind Priority
                    set isCurrentBehind = IsUnitBehindUnit(currentUnit, ownerHero)
                    set isBestBehind = IsUnitBehindUnit(bestTarget, ownerHero)

                    if isCurrentBehind and not isBestBehind then
                        set bestTarget = currentUnit
                    elseif not isCurrentBehind and isBestBehind then
                        // Keep bestTarget
                    else
                        // TIE on Position (Both behind or both in front)
                        // 3. Distance Priority (Farther)
                        set currentDist = DistanceBetweenUnits(ownerHero, currentUnit)
                        set bestDist = DistanceBetweenUnits(ownerHero, bestTarget)

                        if currentDist > bestDist then
                            set bestTarget = currentUnit
                        endif
                    endif
                endif
            endif
        endloop

        // 4. Self Priority (Fallback)
        // Select self if no valid target found, or if the best found target is in front.
        if bestTarget == null or IsUnitInFrontOfUnit(bestTarget, ownerHero) then
            set bestTarget = ownerHero
        endif

        // Clean up
        call DestroyGroup(heroes)
        set heroes = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE

    
        return bestTarget
    endfunction

    function FindTeleportAllyTargetInRange takes AIHero owner, real range, real minDistance, AIAbility abil returns unit
        local group targets = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local unit ownerHero = owner.hero
        local player heroOwner = GetOwningPlayer(ownerHero)
        
        // Comparison variables
        local real currentHpPct
        local real bestHpPct
        local boolean isCurrentCCed
        local boolean isBestCCed
        local real currentDist
        local real bestDist

        // Not Allowed Target: customFilter, In Hazard Zone, Behind, Too close(700), Trailing
        // Priority Order:
        // 1. HP >= 50%
        // 2. CCed
        // 3. Far from owner
        // 4. Goaled Hero

        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = FIND_TEAM_TYPE_ALLIES
        set tempHeroUnit = ownerHero
        set tempAIAbility = abil
        call GroupEnumUnitsInRange(targets, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamHeroes))
    
        loop
            set currentUnit = FirstOfGroup(targets)
            exitwhen currentUnit == null
            call GroupRemoveUnit(targets, currentUnit)
    
            // --- VALIDATION LAYER ---
            if tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
                // Skip invalid target
            elseif IsUnitInAnyHazardZone(currentUnit) then
                // Skip units in danger
            elseif IsUnitBehindUnit(currentUnit, ownerHero) then
                // Skip units behind the bot
            elseif DistanceBetweenUnits(ownerHero, currentUnit) < minDistance then
                // Skip units too close
            elseif not IsUnitLeadingUnit(currentUnit, ownerHero) then
                // Skip trailing units
            elseif bestTarget == null then
                set bestTarget = currentUnit
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                set currentHpPct = GetUnitLifePercent(currentUnit)
                set bestHpPct = GetUnitLifePercent(bestTarget)
                
                // 1. HP >= 50% Priority
                if currentHpPct >= 50.0 and bestHpPct < 50.0 then
                    set bestTarget = currentUnit
                elseif currentHpPct < 50.0 and bestHpPct >= 50.0 then
                    // Keep existing bestTarget
                
                else
                    // TIE on HP Bracket (Both >= 50% or Both < 50%)
                    // 2. CCed Priority
                    set isCurrentCCed = IsUnitStunOrSlow(currentUnit)
                    set isBestCCed = IsUnitStunOrSlow(bestTarget)
                    
                    if isCurrentCCed and not isBestCCed then
                        set bestTarget = currentUnit
                    elseif not isCurrentCCed and isBestCCed then
                        // Keep existing bestTarget
                    
                    else
                        // TIE on CC Priority (Both CC'ed or Both Not)
                        // 3. Distance Priority
                        set currentDist = DistanceBetweenUnits(ownerHero, currentUnit)
                        set bestDist = DistanceBetweenUnits(ownerHero, bestTarget)
                        
                        if currentDist > bestDist then
                            set bestTarget = currentUnit
                        elseif currentDist < bestDist then
                            // Keep existing bestTarget
                        
                        else
                            // TIE on Distance
                            // 4. Goaled Hero Priority
                            if IsHeroGoaled(currentUnit) and not IsHeroGoaled(bestTarget) then
                                set bestTarget = currentUnit
                            endif
                        endif
                    endif
                endif
            endif
        endloop
    
        // Clean up
        call DestroyGroup(targets)
        set targets = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE
        
        return bestTarget
    endfunction

    function GetHeroGroupAroundUnit takes unit centerUnit, real radius, integer findTeamType returns group
        local group heroGroup = CreateGroup()
        local player centerPlayer = GetOwningPlayer(centerUnit)

        // Set temp variables for filter function
        set tempHeroOwner = centerPlayer
        set tempFindTeamType = findTeamType
        set tempHeroUnit = centerUnit
        set tempAIAbility = 0
        set tempAIItem = 0

        call GroupEnumUnitsInRange(heroGroup, GetUnitX(centerUnit), GetUnitY(centerUnit), radius, Filter(function FilterValidVisibleTeamHeroes))

        // Clean up temp variables
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE
        set tempAIAbility = 0
        set tempAIItem = 0
        set centerPlayer = null

        return heroGroup
    endfunction

    function GetHeroCountAroundUnit takes unit centerUnit, real radius, integer findTeamType returns integer
        local group heroGroup = GetHeroGroupAroundUnit(centerUnit, radius, findTeamType)
        local integer count = CountUnitsInGroup(heroGroup)
        call DestroyGroup(heroGroup)
        set heroGroup = null
        return count
    endfunction

    function EvaluateComboTarget takes AIHero owner, unit currentUnit, unit bestTarget, real comboExpectedDamage, real comboMinHpThreshold returns unit
        local real currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)
        local real bestTargetHp = GetUnitState(bestTarget, UNIT_STATE_LIFE)
        
        local boolean currentIsStunOrSlow = IsUnitStunOrSlow(currentUnit)
        local boolean bestIsStunOrSlow = IsUnitStunOrSlow(bestTarget)
        
        local boolean currentIsKillable = (currentHp <= comboExpectedDamage)
        local boolean bestIsKillable = (bestTargetHp <= comboExpectedDamage)
    
        // Initial check: if there is no best target yet, current is automatically the best.
        if bestTarget == null then
            return currentUnit
        endif
    
        // 1. Ungoaled Hero (Higher priority than anything else)
        if not IsHeroGoaled(currentUnit) and IsHeroGoaled(bestTarget) then
            call owner.botLog("Priority 1: Current unit is Ungoaled, Best is not.")
            return currentUnit
        elseif IsHeroGoaled(currentUnit) and not IsHeroGoaled(bestTarget) then
            return bestTarget
        endif

        // 2. Secure Kills (Is the target killable with the combo?)
        if currentIsKillable and not bestIsKillable then
            call owner.botLog("Priority 5: Current is killable, Best is not.")
            return currentUnit
        elseif not currentIsKillable and bestIsKillable then
            return bestTarget
        endif

        // 3. Avoid Overkill (Target is above the min threshold)
        if currentHp >= comboMinHpThreshold and bestTargetHp < comboMinHpThreshold then
            call owner.botLog("Priority 3: Avoiding overkill on current unit.")
            return currentUnit
        elseif currentHp < comboMinHpThreshold and bestTargetHp >= comboMinHpThreshold then
            return bestTarget
        endif

        // 4. Prioritize Stunned/Slowed
        if currentIsStunOrSlow and not bestIsStunOrSlow then
            call owner.botLog("Priority 4: Current is CC'd.")
            return currentUnit
        elseif not currentIsStunOrSlow and bestIsStunOrSlow then
            return bestTarget
        endif

        // 5. Hero carry more than 2 items
        if IsUnitCarryMoreThanTwoItem(currentUnit) and not IsUnitCarryMoreThanTwoItem(bestTarget) then
            call owner.botLog("Priority 2: Current has more items.")
            return currentUnit
        elseif not IsUnitCarryMoreThanTwoItem(currentUnit) and IsUnitCarryMoreThanTwoItem(bestTarget) then
            return bestTarget
        endif
     
        // 6. Minimize Overkill Among Kills (If both are killable, pick the one with higher HP)
        if currentIsKillable and bestIsKillable then
            if currentHp > bestTargetHp then
                call owner.botLog("Priority 6: Both killable, picking current (less overkill).")
                return currentUnit
            else
                return bestTarget
            endif
        endif
    
        // 7. Damage Efficiency (If neither are killable, pick the one with lower HP)
        if not currentIsKillable and not bestIsKillable then
            if currentHp < bestTargetHp then
                call owner.botLog("Priority 7: Neither killable, picking current (lower HP).")
                return currentUnit
            else
                return bestTarget
            endif
        endif
    
        // 8. Fallback
        return bestTarget
    endfunction

    function FindBestComboTarget takes AIHero owner, real range, AIAbility abil returns unit
        local group heroes = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local real comboExpectedDamage = owner.combatData.comboExpectedDamage
        local real comboMinHpThreshold = comboExpectedDamage * owner.combatData.comboOverkillThresholdPercent
            
        // Set temp variables for filter function
        set tempHeroOwner = GetOwningPlayer(owner.hero)
        set tempFindTeamType = FIND_TEAM_TYPE_ENEMIES
        set tempHeroUnit = owner.hero
        set tempAIAbility = abil
        call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterValidVisibleTeamHeroes))
        call owner.botLog("Found " + I2S(CountUnitsInGroup(heroes)) + " potential combo targets in range.")
            
        // Iterate through filtered enemies to find best target
        loop
            set currentUnit = FirstOfGroup(heroes)
            exitwhen currentUnit == null
            call GroupRemoveUnit(heroes, currentUnit)
                

            // Not allow: Invulnerable/Magic Immune, customFilter
                
            //  Current Priority Order:                                                                                     
            // 1. Ungoaled Hero
            // 2. Secure Kills
            // 3. Avoid Overkill 
            // 4. Prioritize Stunned/Slowed
            // 5. Hero carry more than 2 items
            // 6. Minimize Overkill Among Kills
            // 7. Damage Efficiency
            // 8. Fallback to Overkill

            // Skip if unit is invulnerable
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
                // Skip this unit
            elseif tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
                // Skip - doesn't pass custom filter
            else
                // Valid target - evaluate
                set bestTarget = EvaluateComboTarget(owner, currentUnit, bestTarget, comboExpectedDamage, comboMinHpThreshold)
            endif

        endloop
            
        // Clean up
        call DestroyGroup(heroes)
        set heroes = null
        set currentUnit = null
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE
        set tempAIAbility = 0
        return bestTarget
    endfunction

    function FindLowHealthEnemyTargetInRange takes AIHero owner, unit overrideCenterUnit, real range, real expectedDamage, boolean shouldAvoidOverKill, boolean isLowHealthOnly, AIAbility abil, AIItem itm returns unit
        local group enemies = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(owner.hero)
        local real lowHpThreshold = expectedDamage * 0.5 // 50% of expected damage
    
        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = FIND_TEAM_TYPE_ENEMIES
        set tempHeroUnit = owner.hero
        set tempAIAbility = abil
        set tempAIItem = itm
        if overrideCenterUnit != null then
            call GroupEnumUnitsInRange(enemies, GetUnitX(overrideCenterUnit), GetUnitY(overrideCenterUnit), range, Filter(function FilterValidVisibleTeamHeroes))
        else
            call GroupEnumUnitsInRange(enemies, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterValidVisibleTeamHeroes))
        endif

        // Not Allowed Target: MagicImmune, customFilter, above expectedDamage(if isLowHealthOnly), above HP threshold(if shouldAvoidOverKill)
        // Priority:                                                                                     
        // 1. Ungoaled Hero
        // 2. Killable
        // 3. Avoid Overkill 
        // 4. Prioritize Stunned/Slowed
        // 5. Hero carry more than 2 items
        // 6. Minimize Overkill Among Kills
        // 7. Damage Efficiency
        // 8. Fallback to Overkill if not shouldAvoidOverKill

        loop
            set currentUnit = FirstOfGroup(enemies)
            exitwhen currentUnit == null
            call GroupRemoveUnit(enemies, currentUnit)

            // --- VALIDATION LAYER ---
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
            elseif tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
            elseif tempAIItem != 0 and not tempAIItem.customFilter(currentUnit) then
            elseif isLowHealthOnly and GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) > expectedDamage then
            elseif shouldAvoidOverKill and GetUnitStateSwap(UNIT_STATE_LIFE, currentUnit) < lowHpThreshold then
            elseif bestTarget == null then
                set bestTarget = currentUnit
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // Evaluate and possibly update bestTarget
                set bestTarget = EvaluateComboTarget(owner, currentUnit, bestTarget, expectedDamage, lowHpThreshold)
            endif
        endloop

        // Clean up
        call DestroyGroup(enemies)
        set enemies = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempAIItem = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE

        return bestTarget
    endfunction

    function FindRandomHeroInRange takes AIHero owner, real range, integer findTeamType, boolean bExcludeSelf, AIAbility abil returns unit
        local group heroes = CreateGroup()
        local unit randomHero
        local unit currentUnit
        local integer findCount = 0
        local integer i = 0

        // Not allow: Invulnerable/Magic Immune

        // Set temp variables for filter function
        set tempHeroOwner = GetOwningPlayer(owner.hero)
        set tempFindTeamType = findTeamType
        set tempHeroUnit = owner.hero
        set tempAIAbility = abil
            
        call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterValidVisibleTeamHeroes))
        set findCount = CountUnitsInGroup(heroes)

        if findCount > 0 then
            loop
                set currentUnit = FirstOfGroup(heroes)
                exitwhen i >= findCount

                if tempAIAbility != 0 then
                    if not tempAIAbility.customFilter(currentUnit) then
                        call GroupRemoveUnit(heroes, currentUnit)
                    endif
                endif

                if IsUnitInvulnerableOrMagicImmune(currentUnit) then
                    call GroupRemoveUnit(heroes, currentUnit)
                endif

                if bExcludeSelf and currentUnit == owner.hero then
                    call GroupRemoveUnit(heroes, currentUnit)
                endif

                set i = i + 1
            endloop
        endif

        set randomHero = GroupPickRandomUnit(heroes)
            
        // Clean up
        set tempAIAbility = 0
        call DestroyGroup(heroes)
        set heroes = null
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE
            
        return randomHero
    endfunction

    function FindRandomEnemyHeroInRange takes AIHero owner, real range, AIAbility abil returns unit
        return FindRandomHeroInRange(owner, range, FIND_TEAM_TYPE_ENEMIES, false, abil)
    endfunction
        
    function FindRandomAllyHeroInRange takes AIHero owner, real range, boolean bExcludeSelf, AIAbility abil returns unit
        return FindRandomHeroInRange(owner, range, FIND_TEAM_TYPE_ALLIES, bExcludeSelf, abil)
    endfunction

    // Helper function to determine if current unit should replace the best unit
    // Priority: 1. Heroes in hazard zones, 2. Higher hero count around unit, 3. Lower HP
    function ShouldUpdateBestUnit takes unit currentUnit, unit bestUnit, integer currentCount, integer bestCount returns boolean
        local boolean isCurrentInHazard = IsUnitInAnyHazardZone(currentUnit)
        local boolean isBestInHazard = false
        
        // If no best unit yet, take the current one
        if bestUnit == null then
            return true
        endif
        
        set isBestInHazard = IsUnitInAnyHazardZone(bestUnit)
        
        // Current is in hazard zone but best is not - take current
        if isCurrentInHazard and not isBestInHazard then
            return true
        endif
        
        // Best is in hazard zone but current is not - keep best
        if isBestInHazard and not isCurrentInHazard then
            return false
        endif
        
        // Both in same hazard status - compare counts
        if currentCount > bestCount then
            return true
        elseif currentCount == bestCount then
            // Same count - prioritize lower HP (more vulnerable target)
            return GetUnitState(currentUnit, UNIT_STATE_LIFE) < GetUnitState(bestUnit, UNIT_STATE_LIFE)
        endif
        
        return false
    endfunction

    function FindCrowdedHeroInRange takes AIHero owner, real range, real crowdRange, integer findTeamType returns unit
        local group heroes = CreateGroup()
        local unit currentUnit = null
        local unit bestUnit = null
        local integer bestCount = - 1
        local integer currentCount = 0

        // Set temp variables for filter function
        set tempHeroOwner = GetOwningPlayer(owner.hero)
        set tempFindTeamType = findTeamType
        set tempHeroUnit = owner.hero
        set tempAIAbility = 0
        call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterValidVisibleTeamHeroes))

        // Priority:
        // 1. In Hazard Zone
        // 2. Most Heroes around within crowdRange
        // 3. Lowest HP

        loop
            set currentUnit = FirstOfGroup(heroes)
            exitwhen currentUnit == null
            call GroupRemoveUnit(heroes, currentUnit)

            // Count how many heroes are around this currentUnit within crowdRange
            set currentCount = GetHeroCountAroundUnit(currentUnit, crowdRange, findTeamType)

            // Determine if we should update the best unit
            if ShouldUpdateBestUnit(currentUnit, bestUnit, currentCount, bestCount) then
                set bestUnit = currentUnit
                set bestCount = currentCount
            endif
        endloop

        // Clean up
        call DestroyGroup(heroes)
        set heroes = null
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE

        return bestUnit
    endfunction

    function FindPointAroundCrowdedHeroes takes AIHero owner, real rangeRadius, integer findTeamType returns location
        local group allTargets = GetHeroGroupAroundUnit(owner.hero, MAX_RANGE, findTeamType)
        local unit array u
        local integer count = 0
        local integer i = 0
        local integer j = 0
        local real midX = 0
        local real midY = 0
        local integer currentScore = 0
        local integer bestScore = - 1
        local real bestX = 0
        local real bestY = 0
        local group tempGroup = CreateGroup()
        local unit fallbackUnit
        local real tempTargetDis = 0

        if CountUnitsInGroup(allTargets) == 0 then
            call DestroyGroup(allTargets)
            call DestroyGroup(tempGroup)
            set allTargets = null
            set tempGroup = null
            return Location(0.0, 0.0)
        endif
    
        set fallbackUnit = GroupPickRandomUnit(allTargets)
        set bestX = GetUnitX(fallbackUnit)
        set bestY = GetUnitY(fallbackUnit)

        // 1. Transfer group to array for nested looping (JASS requirement)
        loop
            set u[count] = FirstOfGroup(allTargets)
            exitwhen u[count] == null
            call GroupRemoveUnit(allTargets, u[count])
            if tempAIItem != 0 then
                if tempAIItem.customFilter(u[count]) then
                    set count = count + 1
                endif
            else
                set count = count + 1
            endif
        endloop

        // Set temp variables for filter function
        set tempHeroOwner = GetOwningPlayer(owner.hero)
        set tempFindTeamType = findTeamType
        set tempHeroUnit = owner.hero
        set tempAIAbility = 0
    
        // 2. Pairwise Centroid Check
        set i = 0
        loop
            exitwhen i >= count
            set j = i // Start j at i to check the unit itself AND midpoints with others
            loop
                exitwhen j >= count
                
                set tempTargetDis = DistanceBetweenUnits(u[i], u[j])
                if tempTargetDis <= rangeRadius * 2 then
                    // Only consider pairs within double the range radius

                    // Calculate midpoint between unit i and unit j
                    set midX = (GetUnitX(u[i]) + GetUnitX(u[j])) / 2
                    set midY = (GetUnitY(u[i]) + GetUnitY(u[j])) / 2
    
                    // Evaluation: How many units are inside rangeRadius from this midpoint?
                    call GroupClear(tempGroup)
                    call GroupEnumUnitsInRange(tempGroup, midX, midY, rangeRadius, Filter(function FilterValidVisibleTeamHeroes))
                    set currentScore = CountUnitsInGroup(tempGroup)
    
                    if currentScore > bestScore then
                        set bestScore = currentScore
                        set bestX = midX
                        set bestY = midY
                    endif
                endif
                
                set j = j + 1
            endloop
            set i = i + 1
        endloop
    
        // Clean up
        call DestroyGroup(allTargets)
        call DestroyGroup(tempGroup)
        set allTargets = null
        set tempGroup = null
        set tempAIAbility = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE

        return Location(bestX, bestY)
    endfunction

    // low health and crowded ally target
    function FindChainHealAllyTargetInRange takes unit ownerHero, real range, real effectiveRadius, AIAbility abil, AIItem itm returns unit
        local group allies = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local player heroOwner = GetOwningPlayer(ownerHero)
        local real lowHpPercent = HEAL_HP_PERCENTAGE_THRESHOLD
        local integer minNearbyAllies = 2
        local real crowdRange = effectiveRadius
        local integer currentCount = 0
        local integer findTeamType = FIND_TEAM_TYPE_ALLIES
    
        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = findTeamType
        set tempHeroUnit = ownerHero
        set tempAIAbility = abil
        set tempAIItem = itm
        call GroupEnumUnitsInRange(allies, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterValidVisibleTeamHeroes))

        // Not Allowed Target: customFilter, HP above certain threshold
        // Priority Order:
        // 1. Ungoaled
        // 2. Most Nearby Allies
        // 3. Lowest Health

        loop
            set currentUnit = FirstOfGroup(allies)
            exitwhen currentUnit == null
            call GroupRemoveUnit(allies, currentUnit)

            // --- VALIDATION LAYER ---
            if tempAIAbility != 0 and not tempAIAbility.customFilter(currentUnit) then
            elseif tempAIItem != 0 and not tempAIItem.customFilter(currentUnit) then
            elseif GetUnitLifePercent(currentUnit) > lowHpPercent then
            elseif bestTarget == null then
                set bestTarget = currentUnit
            else
                // --- PRIORITY TOURNAMENT LAYER ---
                // 1. Ungoaled Priority
                if not IsHeroGoaled(currentUnit) and IsHeroGoaled(bestTarget) then
                    set bestTarget = currentUnit
                elseif IsHeroGoaled(currentUnit) and not IsHeroGoaled(bestTarget) then
                    // Keep bestTarget
                else
                    // TIE on Goaled Status (Both Goaled or Both Ungoaled)
                    // 2. Most Nearby Allies Priority
                    // Count how many heroes are around this currentUnit within crowdRange
                    set currentCount = GetHeroCountAroundUnit(currentUnit, crowdRange, findTeamType)
                    if currentCount > GetHeroCountAroundUnit(bestTarget, crowdRange, findTeamType) then
                        set bestTarget = currentUnit
                    elseif currentCount < GetHeroCountAroundUnit(bestTarget, crowdRange, findTeamType) then
                        // Keep bestTarget
                    else
                        // TIE on Nearby Allies Count
                        // 3. Lowest Health Priority
                        if GetUnitLifePercent(currentUnit) < GetUnitLifePercent(bestTarget) then
                            set bestTarget = currentUnit
                        endif
                    endif
                endif
            endif
        endloop
        // Clean up
        call DestroyGroup(allies)
        set allies = null
        set currentUnit = null
        set tempAIAbility = 0
        set tempAIItem = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE
        return bestTarget
    endfunction

    function IsDestructableInFrontOfUnit takes destructable tree, unit heroUnit returns boolean
        local real heroX = GetUnitX(heroUnit)
        local real heroY = GetUnitY(heroUnit)
        local real treeX = GetDestructableX(tree)
        local real treeY = GetDestructableY(tree)
        local real angleToTree = Atan2(treeY - heroY, treeX - heroX)
        local real heroFacingAngle = GetUnitFacing(heroUnit) * bj_DEGTORAD
        local real angleDiff = AngleDiff(heroFacingAngle, angleToTree)
        local real frontAngleThreshold = 90.0

        if Abs(angleDiff) <= frontAngleThreshold * bj_DEGTORAD then
            return true
        else
            return false
        endif

    endfunction

    function EnumNearDestructableTrees takes nothing returns nothing
        local destructable tree = GetEnumDestructable()
        local integer destructableTypeId = GetDestructableTypeId(tree)
        local real treeDist = DistanceBetweenDestructableAndUnit(tree, tempHeroUnit)

        // some blockers are destructables but not trees
        if destructableTypeId == 'YTfb' then 
            return
        endif
        if destructableTypeId == 'B001' then 
            return
        endif
        if destructableTypeId == 'YTlb' then 
            return
        endif
        if destructableTypeId == 'Ytlc' then 
            return
        endif
        if GetDestructableLife(tree) <= 0.0 then
            return
        endif
        if IsDestructableInFrontOfUnit(tree, tempHeroUnit) then
            if treeDist < tempNearestTreeDist then
                set tempNearestTreeDist = treeDist
                set tempTree = tree
            endif
        endif

    endfunction

    function FindNearestTreeInFrontOfUnit takes unit sourceUnit, real range returns destructable
        local location sourceLoc = Location(GetUnitX(sourceUnit), GetUnitY(sourceUnit))
        local destructable nearestTree = null

        if not IsUnitFacingAlongTrack(sourceUnit) then
            return null
        endif
      
        set tempHeroUnit = sourceUnit
        set tempTree = null
        set tempNearestTreeDist = MAX_RANGE

        call EnumDestructablesInCircle(range, sourceLoc, function EnumNearDestructableTrees)
        set nearestTree = tempTree

        // Clean up
        set tempHeroUnit = null
        set tempTree = null
        set tempNearestTreeDist = MAX_RANGE
        call RemoveLocation(sourceLoc)
        set sourceLoc = null
        return nearestTree
    endfunction

    // Get nearest forward waypoint index after teleport
    function GetNearestForwardWaypointIndex takes integer currentIndex, real x, real y returns integer
        local integer i = currentIndex + 1
        local integer bestIndex = currentIndex
        local real bestDistance = 999999.0
        local real distance
        local real waypointX
        local real waypointY
        
        loop
            exitwhen i > GoalWaypointIndex
            set waypointX = GetRectCenterX(WaypointAreas[i])
            set waypointY = GetRectCenterY(WaypointAreas[i])
            set distance = SquareRoot((x - waypointX) * (x - waypointX) + (y - waypointY) * (y - waypointY))
            
            if distance < bestDistance then
                set bestDistance = distance
                set bestIndex = i + 1
            endif
            
            set i = i + 1
        endloop
        
        return bestIndex
    endfunction

    function FindNearestTreeInRange takes unit sourceUnit, real range returns destructable
        local location sourceLoc = Location(GetUnitX(sourceUnit), GetUnitY(sourceUnit))
        local destructable nearestTree = null

        set tempHeroUnit = sourceUnit
        set tempTree = null
        set tempNearestTreeDist = MAX_RANGE

        call EnumDestructablesInCircle(range, sourceLoc, function EnumNearDestructableTrees)
        set nearestTree = tempTree

        // Clean up
        set tempHeroUnit = null
        set tempTree = null
        set tempNearestTreeDist = MAX_RANGE
        call RemoveLocation(sourceLoc)
        set sourceLoc = null
        return nearestTree
    endfunction

    function FilterDeadUnits takes nothing returns boolean
        local unit filterUnit = GetFilterUnit()
        if IsUnitType(filterUnit, UNIT_TYPE_DEAD) then
            return true
        else
            return false
        endif
    endfunction

    function FindDeadUnitInRange takes unit sourceUnit, real range returns unit
        local group deadUnits = CreateGroup()
        local unit deadUnit = null

        call GroupEnumUnitsInRange(deadUnits, GetUnitX(sourceUnit), GetUnitY(sourceUnit), range, Filter(function FilterDeadUnits))

        set deadUnit = FirstOfGroup(deadUnits)

        // Clean up
        call DestroyGroup(deadUnits)
        set deadUnits = null

        return deadUnit
    endfunction

    function FindTargetUnitForAbility takes AIHero owner, AIAbility abil returns unit
        local unit targetUnit = null

        // difficulty < DIFF_HARD
        if not IsSmartFindingTargetUnit(owner.difficulty) then
            // Non-smart finding: use simple random selection based on findTargetType
            if abil.findTargetType == FIND_TARGET_TYPE_ENEMY_COMBO then
                set targetUnit = FindRandomEnemyHeroInRange(owner, abil.castRange, abil)
            elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING then
                set targetUnit = FindRandomEnemyHeroInRange(owner, abil.castRange, abil)
            elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_LOW_HEALTH then
                set targetUnit = FindRandomEnemyHeroInRange(owner, abil.castRange, abil)
            elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_ONLY then
                set targetUnit = FindRandomEnemyHeroInRange(owner, abil.castRange, abil)
            elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_AVOID_OVERKILL then
                set targetUnit = FindRandomEnemyHeroInRange(owner, abil.castRange, abil)
            elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_CROWDED then
                set targetUnit = FindRandomEnemyHeroInRange(owner, abil.castRange, abil)
            elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_BACK then
                set targetUnit = FindBackOrCloseEnemyTargetInRange(owner.hero, abil.effectiveRadius * 1.0, 0, true, abil, 0)
                if targetUnit != null then
                    call owner.botLog("Found back enemy target for ability, result: " + GetUnitName(targetUnit))
                endif
            elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_BACK_OR_CLOSE then
                set targetUnit = FindBackOrCloseEnemyTargetInRange(owner.hero, abil.effectiveRadius * 1.0, abil.effectiveRadius, false, abil, 0)
                if targetUnit != null then
                    call owner.botLog("Found back enemy target for ability, result: " + GetUnitName(targetUnit))
                endif
            elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_CC then
                set targetUnit = FindRandomEnemyHeroInRange(owner, abil.castRange, abil)
            elseif abil.findTargetType == FIND_TARGET_TYPE_ALLY_CC then
                set targetUnit = FindRandomAllyHeroInRange(owner, abil.castRange, false, abil)
            elseif abil.findTargetType == FIND_TARGET_TYPE_ALLY_SPEED_UP then
                set targetUnit = FindRandomAllyHeroInRange(owner, abil.castRange, false, abil)
            elseif abil.findTargetType == FIND_TARGET_TYPE_ALLY_HEAL then
                set targetUnit = FindRandomAllyHeroInRange(owner, abil.castRange, false, abil)
            elseif abil.findTargetType == FIND_TARGET_TYPE_ALLY_CHAIN_HEAL then
                set targetUnit = FindRandomAllyHeroInRange(owner, abil.castRange, false, abil)
            elseif abil.findTargetType == FIND_TARGET_TYPE_ALLY_TELEPORT_FULL_MAP then
                if IsHeroGoaled(owner.hero) then
                    return null
                endif
                set targetUnit = FindTeleportAllyTargetInRange(owner, abil.castRange, 3000.0, abil)
                if targetUnit != null then
                    call owner.botLog("Found ally hero target for teleport ability, result: " + GetUnitName(targetUnit))
                endif
                return targetUnit
            elseif abil.findTargetType == FIND_TARGET_TYPE_ALL_HOLY_LIGHT then
                set targetUnit = FindHolyLightAllyTargetInRange(owner.hero, abil.castRange, abil.expectedDamage)
                if targetUnit != null then
                    call owner.botLog("Found Holy Light ally target for ability, result: " + GetUnitName(targetUnit))
                endif
            elseif abil.findTargetType == FIND_TARGET_TYPE_ALL_DEATH_COIL then
                set targetUnit = FindDeathCoilAllyTargetInRange(owner.hero, abil.castRange, abil.expectedDamage)
                if targetUnit != null then
                    call owner.botLog("Found Death Coil ally target for ability, result: " + GetUnitName(targetUnit))
                endif
            else
                call owner.botLogError("Unsupported ability find target type for non-smart finding: " + I2S(abil.findTargetType))
            endif

            if targetUnit == null then
                call owner.botLog("No valid target found for combo ability.")
                return null
            endif

            call owner.botLog("Found random target, result: " + GetUnitName(targetUnit))
            call owner.setDebugTextTagContent("Combat: " + GetObjectName(abil.abilityId) + " - Target " + GetUnitName(targetUnit))
            call owner.setDebugTextTagColorPreset("RED")

            return targetUnit
        endif
            
        if abil.findTargetType == FIND_TARGET_TYPE_ENEMY_COMBO then
            if abil.comboIndex > 0 then
                if owner.comboTargetUnit != null then
                    // Check if we should use existing combo target
                    set targetUnit = owner.comboTargetUnit
                    call owner.botLog("Using existing combo target for combo ability: " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagContent("Combat: " + abil.orderString + " - Using Combo Target " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagColorPreset("RED")
                    return targetUnit
                endif
                set targetUnit = FindBestComboTarget(owner, abil.castRange, abil)
                if targetUnit == null then
                    call owner.botLog("No valid combo target found.")
                    return null
                endif
                call owner.botLog("Found best combo target, result: " + GetUnitName(targetUnit) + " for ability " + abil.getName())
                call owner.setDebugTextTagContent("Combat: " + abil.orderString + " - Combo Target " + GetUnitName(targetUnit))
                call owner.setDebugTextTagColorPreset("RED")
                return targetUnit
            endif
        elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING then
            set targetUnit = FindHealthyRunningEnemyTargetInRange(owner.hero, abil.castRange, abil, 0)
            if targetUnit != null then
                call owner.botLog("Found healthy running enemy target for ability, result: " + GetUnitName(targetUnit))
            endif
        elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_LOW_HEALTH then
            set targetUnit = FindLowHealthEnemyTargetInRange(owner, null, abil.castRange, abil.expectedDamage, false, false, abil, 0)
            if targetUnit != null then
                call owner.botLog("Found low health enemy target for ability, result: " + GetUnitName(targetUnit))
            endif
        elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_ONLY then
            set targetUnit = FindLowHealthEnemyTargetInRange(owner, null, abil.castRange, abil.expectedDamage, false, true, abil, 0)
            if targetUnit != null then
                call owner.botLog("Found low health only enemy target for ability, result: " + GetUnitName(targetUnit))
            endif
        elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_AVOID_OVERKILL then
            set targetUnit = FindLowHealthEnemyTargetInRange(owner, null, abil.castRange, abil.expectedDamage, true, false, abil, 0)
            if targetUnit != null then
                call owner.botLog("Found low health enemy target for ability, result: " + GetUnitName(targetUnit))
            endif
        elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_CROWDED then
            set targetUnit = FindCrowdedHeroInRange(owner, abil.castRange, abil.effectiveRadius, FIND_TEAM_TYPE_ENEMIES)
            if targetUnit != null then
                call owner.botLog("Found crowded low health enemy target for ability, result: " + GetUnitName(targetUnit))
            endif
        elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_BACK then
            set targetUnit = FindBackOrCloseEnemyTargetInRange(owner.hero, abil.effectiveRadius * 2.0, 0, true, abil, 0)
            if targetUnit != null then
                call owner.botLog("Found back enemy target for ability, result: " + GetUnitName(targetUnit))
            endif
        elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_BACK_OR_CLOSE then
            set targetUnit = FindBackOrCloseEnemyTargetInRange(owner.hero, abil.effectiveRadius * 2.0, abil.effectiveRadius, false, abil, 0)
            if targetUnit != null then
                call owner.botLog("Found back enemy target for ability, result: " + GetUnitName(targetUnit))
            endif
        elseif abil.findTargetType == FIND_TARGET_TYPE_ENEMY_CC then
            set targetUnit = FindCCedTargetInRange(owner.hero, abil.castRange, FIND_TEAM_TYPE_ENEMIES, false, abil, 0)
            if targetUnit != null then
                call owner.botLog("Found CC'ed enemy target for ability, result: " + GetUnitName(targetUnit))
            endif
        elseif abil.findTargetType == FIND_TARGET_TYPE_ALLY_CC then
            set targetUnit = FindRandomAllyHeroInRange(owner, abil.castRange, false, 0)
            call owner.botLog("Force using ability on CC'ed ally: " + GetUnitName(targetUnit))
        elseif abil.findTargetType == FIND_TARGET_TYPE_ALLY_SPEED_UP then
            set targetUnit = FindSpeedUpAllyTargetInRange(owner.hero, abil.castRange, abil)
            if targetUnit != null then
                call owner.botLog("Found ally hero target for speed-up ability, result: " + GetUnitName(targetUnit))
            endif
            return targetUnit
        elseif abil.findTargetType == FIND_TARGET_TYPE_ALLY_HEAL then
            set targetUnit = FindHealAllyTargetInRange(owner.hero, abil.castRange, abil, 0)
            if targetUnit != null then
                call owner.botLog("Found heal ally target for ability, result: " + GetUnitName(targetUnit))
            endif
        elseif abil.findTargetType == FIND_TARGET_TYPE_ALLY_CHAIN_HEAL then
            set targetUnit = FindChainHealAllyTargetInRange(owner.hero, abil.castRange, abil.effectiveRadius, abil, 0)
            if targetUnit != null then
                call owner.botLog("Found chain heal ally target for ability, result: " + GetUnitName(targetUnit))
            endif
        elseif abil.findTargetType == FIND_TARGET_TYPE_ALLY_TELEPORT_FULL_MAP then
            if IsHeroGoaled(owner.hero) then
                return null
            endif
            if GetUnitLifePercent(owner.hero) < 35.0 then
                call owner.botLog("Skipping teleport target finding due to low health.")
                return null
            endif
            set targetUnit = FindTeleportAllyTargetInRange(owner, abil.castRange, 3000.0, abil)
            if targetUnit != null then
                call owner.botLog("Found ally hero target for teleport ability, result: " + GetUnitName(targetUnit))
            endif
            return targetUnit
        elseif abil.findTargetType == FIND_TARGET_TYPE_ALL_HOLY_LIGHT then
            set targetUnit = FindHolyLightAllyTargetInRange(owner.hero, abil.castRange, abil.expectedDamage)
            if targetUnit != null then
                call owner.botLog("Found Holy Light ally target for ability, result: " + GetUnitName(targetUnit))
            endif
        elseif abil.findTargetType == FIND_TARGET_TYPE_ALL_DEATH_COIL then
            set targetUnit = FindDeathCoilAllyTargetInRange(owner.hero, abil.castRange, abil.expectedDamage)
            if targetUnit != null then
                call owner.botLog("Found Death Coil ally target for ability, result: " + GetUnitName(targetUnit))
            endif
        else
            call owner.botLogError("Unsupported ability find target type: " + I2S(abil.findTargetType))
        endif
            
        return targetUnit
    endfunction

    function FindTargetUnitForItem takes AIHero owner, AIItem itm returns unit
        local unit targetUnit = null
        local real heroX = GetUnitX(owner.hero)
        local real heroY = GetUnitY(owner.hero)

        if itm.findTargetType == FIND_TARGET_TYPE_ALLY_SPEED_UP then
            set targetUnit = FindSpeedUpAllyTargetInRange(owner.hero, itm.castRange, 0)
            if targetUnit != null then
                call owner.botLog("Found ally hero target for speed-up item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALLY_TELEPORT then
            set targetUnit = FindTeleportAllyTargetInRange(owner, itm.castRange, 700.0, 0)
            if targetUnit != null then
                call owner.botLog("Found ally hero target for teleport item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING then
            set targetUnit = FindHealthyRunningEnemyTargetInRange(owner.hero, itm.castRange, 0, itm)
            if targetUnit != null then
                call owner.botLog("Found healthy running enemy target for item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ENEMY_BACK then
            set targetUnit = FindBackOrCloseEnemyTargetInRange(owner.hero, itm.effectiveRadius * 2.0, 0, true, 0, itm)
            if targetUnit != null then
                call owner.botLog("Found back enemy target for item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ENEMY_FRONT then
            set targetUnit = FindFrontTargetInRange(owner.hero, itm.castRange, FIND_TEAM_TYPE_ENEMIES, itm.getMinTargetDistance(), IsHeroGoaled(owner.hero), 0, itm)
            if targetUnit != null then
                call owner.botLog("Found front enemy target for item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ENEMY_CONTROL_UNIT then
            set targetUnit = FindControlUnitEnemyTargetInRange(owner.hero, itm.castRange, 0, itm)
            if targetUnit != null then
                call owner.botLog("Found control unit enemy target for item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ENEMY_CC then
            set targetUnit = FindCCedTargetInRange(owner.hero, itm.castRange, FIND_TEAM_TYPE_ENEMIES, false, 0, itm)
            if targetUnit != null then
                call owner.botLog("Found CC'ed enemy target for item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALLY_CC then
            set targetUnit = FindCCedTargetInRange(owner.hero, itm.castRange, FIND_TEAM_TYPE_ALLIES, false, 0, itm)
            if targetUnit != null then
                call owner.botLog("Found CC'ed ally target for item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALLY_HEAL then
            set targetUnit = FindHealAllyTargetInRange(owner.hero, itm.castRange, 0, itm)
            if targetUnit != null then
                call owner.botLog("Found heal ally target for item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALLY_CC_OR_LOW_HEALTH then
            set targetUnit = FindCCedTargetInRange(owner.hero, itm.castRange, FIND_TEAM_TYPE_ALLIES, false, 0, itm)
            if targetUnit != null then
                call owner.botLog("Found CC'ed ally target for item, result: " + GetUnitName(targetUnit))
                return targetUnit
            endif
            set targetUnit = FindLowHealthTargetInRange(owner.hero, itm.castRange, FIND_TEAM_TYPE_ALLIES, 0, itm)
            if targetUnit != null then
                call owner.botLog("Found low health ally target for item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_SELF_FORCE_STAFF then
            if RectContainsCoords(gg_rct_AIWayPointAreaCrossSea, heroX, heroY) then
                if not IsUnitFacingEast(owner.hero) then
                    // issue move right to face east
                    call IssuePointOrder(owner.hero, "move", heroX + 10.0, heroY)
                    call owner.botLog("Adjusting facing direction to east for Force Staff self-use.")
                    return null
                endif
                call IssueImmediateOrder(owner.hero, "stop")
                set targetUnit = owner.hero
            endif
            if RectContainsCoords(gg_rct_AIWayPointAreaCrossTree, heroX, heroY) then
                if not IsUnitFacingWestNarrow(owner.hero) then
                    // issue move up to face west
                    call IssuePointOrder(owner.hero, "move", heroX - 10.0, heroY)
                    call owner.botLog("Adjusting facing direction to west for Force Staff self-use.")
                    return null
                endif
                // stop moving before using item
                call IssueImmediateOrder(owner.hero, "stop")
                set targetUnit = owner.hero
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALL_FRONT then
            set targetUnit = FindFrontTargetInRange(owner.hero, itm.castRange, FIND_TEAM_TYPE_ALL, itm.getMinTargetDistance(), true, 0, itm)
            if targetUnit != null then
                call owner.botLog("Finding front target for item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALL_UNIT_FRONT then
            set targetUnit = FindFrontTargetInRange(owner.hero, itm.castRange, FIND_TEAM_TYPE_ALL, itm.getMinTargetDistance(), false, 0, itm)
            if targetUnit != null then
                call owner.botLog("Finding front target for item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALL_ENEMY_LEADING_OR_ALLY_TRAILING then
            set targetUnit = FindLeadingEnemyTargetInRange(owner.hero, itm.castRange, itm.getMinTargetDistance(), 0, itm)
            if targetUnit != null then
                call owner.botLog("Found leading enemy target for item, result: " + GetUnitName(targetUnit))
                return targetUnit
            endif
            set targetUnit = FindTrailingAllyTargetInRange(owner.hero, itm.castRange, itm.getMinTargetDistance(), 0, itm)
            if targetUnit != null then
                call owner.botLog("Found trailing ally target for item, result: " + GetUnitName(targetUnit))
                return targetUnit
            endif
            call owner.botLog("No target MeatHook")
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALL_ILLUSION then
            set targetUnit = FindIllusionTargetInRange(owner.hero, itm.castRange)
            if targetUnit != null then
                call owner.botLog("Finding illusion target for item, result: " + GetUnitName(targetUnit))
            endif
        else
            call BotLogErrorWithPlayer(GetOwningPlayer(owner.hero), "Unsupported item find target type: " + I2S(itm.findTargetType))
        endif
        return targetUnit
    endfunction

    function FindForceToUseTargetUnitForItem takes AIHero owner, AIItem itm returns unit
        local unit targetUnit = null
        if itm.findTargetType == FIND_TARGET_TYPE_ALLY_SPEED_UP then
            set targetUnit = FindSpeedUpAllyTargetInRange(owner.hero, itm.castRange, 0)
            if targetUnit == null then
                set targetUnit = owner.hero
            endif
            call owner.botLog("Force using speed-up item on ally: " + GetUnitName(targetUnit))
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALLY_TELEPORT then
            set targetUnit = FindRandomAllyHeroInRange(owner, itm.castRange, true, 0)
            call owner.botLog("Force using teleport item on random ally: " + GetUnitName(targetUnit))
        elseif itm.findTargetType == FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING then
            set targetUnit = FindRandomEnemyHeroInRange(owner, itm.castRange, 0)
            call owner.botLog("Force using item on healthy running enemy: " + GetUnitName(targetUnit))
        elseif itm.findTargetType == FIND_TARGET_TYPE_ENEMY_CONTROL_UNIT then
            set targetUnit = FindControlUnitEnemyTargetInRange(owner.hero, itm.castRange, 0, itm)
            call owner.botLog("Finding control unit enemy target for item, result: " + GetUnitName(targetUnit))
        elseif itm.findTargetType == FIND_TARGET_TYPE_ENEMY_FRONT then
            set targetUnit = FindFrontTargetInRange(owner.hero, itm.castRange, FIND_TEAM_TYPE_ENEMIES, 0.0, true, 0, itm)
            if targetUnit == null then
                set targetUnit = FindFrontTargetInRange(owner.hero, itm.castRange, FIND_TEAM_TYPE_ENEMIES, 0.0, false, 0, itm)
            endif
            if itm != 0 then
                if itm.itemId == 'I00E' then // Nether Swap
                    if targetUnit == null then
                        set targetUnit = FindRandomAllyHeroInRange(owner, itm.castRange, true, 0)
                    endif
                endif
            endif
            if targetUnit != null then
                call owner.botLog("Finding front target for item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ENEMY_CC then
            set targetUnit = FindRandomEnemyHeroInRange(owner, itm.castRange, 0)
            call owner.botLog("Force using item on CC'ed enemy: " + GetUnitName(targetUnit))
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALLY_CC then
            set targetUnit = FindRandomAllyHeroInRange(owner, itm.castRange, false, 0)
            call owner.botLog("Force using item on CC'ed ally: " + GetUnitName(targetUnit))
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALLY_HEAL then
            set targetUnit = owner.hero
            call owner.botLog("Force using item on self for heal item")
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALLY_CC_OR_LOW_HEALTH then
            set targetUnit = owner.hero
            call owner.botLog("Force using item on self")
        elseif itm.findTargetType == FIND_TARGET_TYPE_SELF_FORCE_STAFF then
            set targetUnit = FindSpeedUpAllyTargetInRange(owner.hero, itm.castRange, 0)
            if targetUnit == null then
                set targetUnit = owner.hero
            endif
            call owner.botLog("Force using Force Staff item on self or ally: " + GetUnitName(targetUnit))
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALL_FRONT then
            set targetUnit = FindFrontTargetInRange(owner.hero, itm.castRange, FIND_TEAM_TYPE_ALL, itm.getMinTargetDistance(), true, 0, itm)
            if targetUnit != null then
                return targetUnit
            endif
            set targetUnit = owner.hero
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALL_UNIT_FRONT then
            set targetUnit = FindFrontTargetInRange(owner.hero, itm.castRange, FIND_TEAM_TYPE_ALL, itm.getMinTargetDistance(), false, 0, itm)
            if targetUnit != null then
                return targetUnit
            endif
            set targetUnit = owner.hero
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALL_ILLUSION then
            set targetUnit = FindIllusionTargetInRange(owner.hero, itm.castRange)
            if targetUnit != null then
                call owner.botLog("Finding illusion target for item, result: " + GetUnitName(targetUnit))
            endif
        elseif itm.findTargetType == FIND_TARGET_TYPE_ALL_ENEMY_LEADING_OR_ALLY_TRAILING then
            set targetUnit = FindLeadingEnemyTargetInRange(owner.hero, itm.castRange, itm.getMinTargetDistance(), 0, itm)
            if targetUnit != null then
                call owner.botLog("Finding leading enemy target for item, result: " + GetUnitName(targetUnit))
                return targetUnit
            endif
            set targetUnit = FindTrailingAllyTargetInRange(owner.hero, itm.castRange, itm.getMinTargetDistance(), 0, itm)
            if targetUnit != null then
                call owner.botLog("Finding trailing ally target for item, result: " + GetUnitName(targetUnit))
                return targetUnit
            endif
            set targetUnit = owner.hero
        else
            call BotLogErrorWithPlayer(GetOwningPlayer(owner.hero), "Unsupported item find target type for force use: " + I2S(itm.findTargetType))
        endif
        return targetUnit
    endfunction

    function StateId2String takes integer stateId returns string
        if stateId == STATE_NONE then
            return "None"
        elseif stateId == STATE_RUN then
            return "Run"
        elseif stateId == STATE_COMBAT then
            return "Combat"
        elseif stateId == STATE_HAZARD then
            return "Hazard"
        elseif stateId == STATE_FOLLOW then
            return "Follow"
        elseif stateId == STATE_DEAD then
            return "Dead"
        elseif stateId == STATE_PICKUP_ITEM then
            return "Pickup Item"
        elseif stateId == STATE_GOALED then
            return "Goaled"
        else
            return "Unknown State Id: " + I2S(stateId)
        endif
    endfunction

endlibrary