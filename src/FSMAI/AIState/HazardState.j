struct HazardState extends AIState
    integer hazardType  // 0 = Spike, 1 = Net, etc.
    boolean bIsGoingThroughFastSpike = false

    static method create takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.stateID = STATE_HAZARD
        return this
    endmethod

    method onEnter takes nothing returns nothing
        local real ux = GetUnitX(owner.hero)
        local real uy = GetUnitY(owner.hero)
        local boolean hasNearbyEnemy = false

        call this.botLog("Entering Hazard State")
        
        // Determine hazard type based on current location
        if IsInSlowSpikeHazardZone(owner) then
            set this.hazardType = HAZARD_TYPE_SLOW_SPIKE
            if owner.currentWaypointIndex > 8 then
                call owner.setWaypointIndex(8) // Reset to before Slow Spike Hazard
                call this.botLog("Resetting waypoint index to 8 for Slow Spike Hazard")
            endif
            call this.botLog("Detected Slow Spike Hazard Zone")
            call owner.setDebugTextTagContent("Hazard: Slow Spike Zone")
            call owner.setDebugTextTagColorPreset("ORANGE")
        elseif IsInFastSpikeHazardZone(owner) then
            set this.hazardType = HAZARD_TYPE_FAST_SPIKE
            if owner.currentWaypointIndex > 10 then
                call owner.setWaypointIndex(10) // Reset to before Fast Spike Hazard
                call this.botLog("Resetting waypoint index to 10 for Fast Spike Hazard")
            endif
            call this.botLog("Detected Fast Spike Hazard Zone")
            call owner.setDebugTextTagContent("Hazard: Fast Spike Zone")
            call owner.setDebugTextTagColorPreset("ORANGE")
        elseif IsInNetHazardZone(owner) then
            set this.hazardType = HAZARD_TYPE_NET
            if owner.currentWaypointIndex > 12 then
                call owner.setWaypointIndex(12) // Reset to before Net Hazard
                call this.botLog("Resetting waypoint index to 12 for Net Hazard")
            endif
            call this.botLog("Detected Net Hazard Zone")
            call owner.setDebugTextTagContent("Hazard: Net Zone")
            call owner.setDebugTextTagColorPreset("ORANGE")
        elseif IsInSpiderNetHazardZone(owner) then
            set this.hazardType = HAZARD_TYPE_SPIDER_NET
            call this.botLog("Detected Spider Net Hazard Zone")
            call owner.setDebugTextTagContent("Hazard: Spider Net Zone")
            call owner.setDebugTextTagColorPreset("ORANGE")
        elseif IsInOrangeFishWaitArea(owner) then
            set hasNearbyEnemy = GetHeroCountAroundUnit(owner.hero, HAZARD_ORANGE_FISH_ENEMY_DETECT_RADIUS, FIND_TEAM_TYPE_ENEMIES) > 0
            if IsOrangeFishStable() and hasNearbyEnemy then
                set this.hazardType = HAZARD_TYPE_ORANGE_FISH
                call IssueImmediateOrder(owner.hero, "stop")
                call this.botLog("Detected Orange Fish Hazard Zone")
                call owner.setDebugTextTagContent("Hazard: Orange Fish Zone")
                call owner.setDebugTextTagColorPreset("ORANGE")
            else
                call this.botLogError("Orange Fish Hazard Zone detected but conditions not met!")
            endif
        else
            // Other hazard types can be added here
            call this.botLogError("Unknown hazard type detected!")
        endif
    endmethod
        
    method onUpdate takes nothing returns nothing
        local unit blockingUnit = null
        local boolean hasBlockingUnitAhead
        local boolean hasBlockingUnitBehind
        local real blockDetectRadius = 100.0

        if not IsUnitAliveBJ(owner.hero) then
            return
        endif

        if owner.TryEnterGiveItemState() then
            return 
        endif

        if owner.TryEnterPickupItemState() then
            return
        endif

        call owner.tryAvoidBlockingUnit() 

        if this.hazardType == HAZARD_TYPE_SLOW_SPIKE then
            call this.onSlowSpikeHazardZoneUpdate()
        elseif this.hazardType == HAZARD_TYPE_FAST_SPIKE then
            call this.onFastSpikeHazardZoneUpdate()
        elseif this.hazardType == HAZARD_TYPE_NET then
            call this.onNetHazardZoneUpdate()
        elseif this.hazardType == HAZARD_TYPE_SPIDER_NET then
            call this.onSpiderNetHazardZoneUpdate()
        elseif this.hazardType == HAZARD_TYPE_ORANGE_FISH then
            call this.onOrangeFishHazardZoneUpdate()
        else
            call this.botLogError("Unknown hazard type in update!")
        endif
    endmethod
        
    method onSlowSpikeHazardZoneUpdate takes nothing returns nothing
        local real heroX = GetUnitX(owner.hero)
        local real heroY = GetUnitY(owner.hero)
        local real avoidanceDetectRadiusBase = 150
        local real slowSpikeRadius = SLOW_SPIKE_RADIUS
        local real avoidanceDetectRadius = avoidanceDetectRadiusBase + slowSpikeRadius
        local boolean hasSlowSpikeAhead = false
        local boolean hasSlowSpikeBehind = false
        local unit slowSpikeUnit = null
        local rect currentWaypointArea

        set currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
            
        if owner.currentWaypointIndex < 8 then
            call this.botLogError("Waypoint index less than 8 in Slow Spike Hazard Zone, correcting to 8")
            call owner.setWaypointIndex(8)
        endif

        // Check if hero has reached the current waypoint area
        if RectContainsCoords(currentWaypointArea, heroX, heroY) then
            call owner.changeState(RunState.create())
            return
        endif

        if IsUnitInvulnerableOrMagicImmune(owner.hero) then
            call this.botLog("Hero is invulnerable or magic immune, skipping spike avoidance")
            call owner.setDebugTextTagContent("Hazard: Magic Immune - No Dodge")
            call owner.setDebugTextTagColorPreset("ORANGE")
            return
        endif

        // check ahead
        set slowSpikeUnit = this.getHazardAround(avoidanceDetectRadius, false, SLOW_SPIKE_UNIT_TYPE_ID, SLOW_SPIKE_SPEED, SLOW_SPIKE_RADIUS)
        set hasSlowSpikeAhead = slowSpikeUnit != null

        // detect slow spike ahead within certain radius
        if hasSlowSpikeAhead then
            call this.botLog("Slow Spike detected ahead, issuing dodge maneuver")
            call owner.setDebugTextTagContent("Hazard: Dodging Slow Spike Ahead")
            call owner.setDebugTextTagColorPreset("ORANGE")
            call owner.avoidTargetUnitAhead(slowSpikeUnit, SLOW_SPIKE_SPEED, 1.0, false)
            return
        else 
            // check behind
            set slowSpikeUnit = this.getHazardAround(avoidanceDetectRadius, true, SLOW_SPIKE_UNIT_TYPE_ID, SLOW_SPIKE_SPEED, SLOW_SPIKE_RADIUS)
            set hasSlowSpikeBehind = slowSpikeUnit != null
            if hasSlowSpikeBehind then
                call this.botLog("Slow Spike detected behind, issuing dodge maneuver")
                call owner.setDebugTextTagContent("Hazard: Dodging Slow Spike Behind")
                call owner.setDebugTextTagColorPreset("ORANGE")
                call owner.avoidTargetUnitBehind(slowSpikeUnit, true, 1.0, false)
                return
            endif
        endif

        // No more spikes around, keep moving to next waypoint
        call owner.moveToNextWaypoint()
    endmethod

    method checkHazardUnit takes unit u, boolean bCheckBehind, integer checkingUnitTypeId, real checkingUnitMoveSpeed, real hazardHitRadius returns boolean
        local real targetUnitX = GetUnitX(u)
        local real targetUnitY = GetUnitY(u)
        local real targetMoveSpeed = checkingUnitMoveSpeed
        local real targetUnitMovingAngle = GetUnitFacing(u)
        local real predictedTargetUnitX = targetUnitX + targetMoveSpeed * UPDATE_PERIOD * Cos(targetUnitMovingAngle * bj_DEGTORAD)
        local real predictedTargetUnitY = targetUnitY + targetMoveSpeed * UPDATE_PERIOD * Sin(targetUnitMovingAngle * bj_DEGTORAD)
        local real ownerHeroX = GetUnitX(owner.hero)
        local real ownerHeroY = GetUnitY(owner.hero)

        // Aloc is Locus ability
        if GetUnitTypeId(u) == checkingUnitTypeId and GetUnitAbilityLevel(u, 'Aloc') > 0 then
            if not bCheckBehind then
                if IsUnitInFrontOfUnit(u, owner.hero) then
                    if not IsUnitInRangeXY(u, ownerHeroX, ownerHeroY, hazardHitRadius) then
                        call this.botLog("hazard unit detected ahead and within avoidance range.")
                        return true
                    else
                        call this.botLog("hazard unit detected ahead but too close to dodge.")
                    endif
                endif
            else
                if not IsUnitInFrontOfUnit(u, owner.hero) then
                    if not IsUnitInRangeXY(u, ownerHeroX, ownerHeroY, hazardHitRadius) then
                        call this.botLog("hazard unit detected behind and within avoidance range.")
                        return true
                    else
                        call this.botLog("hazard unit detected behind but too close to dodge.")
                    endif
                endif
            endif
        endif
        return false
    endmethod

    method getHazardAround takes real detectRadius, boolean bCheckBehind, integer hazardUnitTypeId, real hazardUnitMoveSpeed, real hazardHitRadius returns unit
        local group spikeGroup = CreateGroup()
        local unit u
        local real heroX = GetUnitX(owner.hero)
        local real heroY = GetUnitY(owner.hero)
        local unit resultUnit = null
        local boolexpr filter = Filter(function AntiLeak)
        local real closestDistance = 99999.0
        local real currentTargetDistance
            
        // Detect locus unit must use GroupEnumUnitsOfPlayer for Player(11)
        call GroupEnumUnitsOfPlayer(spikeGroup, Player(11), filter) 
        loop
            set u = FirstOfGroup(spikeGroup)
            exitwhen u == null

            call GroupRemoveUnit(spikeGroup, u)
            if IsUnitInRangeXY(u, heroX, heroY, detectRadius)  then
                if this.checkHazardUnit(u, bCheckBehind, hazardUnitTypeId, hazardUnitMoveSpeed, hazardHitRadius) then
                    set currentTargetDistance = DistanceBetweenXY(heroX, heroY, GetUnitX(u), GetUnitY(u))
                    if currentTargetDistance < closestDistance then
                        set closestDistance = currentTargetDistance
                        set resultUnit = u
                    endif
                endif
            endif
        endloop
        call DestroyGroup(spikeGroup)
            
        return resultUnit
    endmethod

    method onFastSpikeHazardZoneUpdate takes nothing returns nothing
        local integer currentOrder
        local real heroX = GetUnitX(owner.hero)
        local real heroY = GetUnitY(owner.hero)
        local rect currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]

        if owner.currentWaypointIndex < 10 then
            call this.botLogError("Waypoint index less than 10 in Fast Spike Hazard Zone, correcting to 10")
            call owner.setWaypointIndex(10)
        endif

        if not IsTriggerEnabled(gg_trg_FastSpike) then
            call this.botLog("Fast Spike trigger is disabled, skipping hazard handling")
            call owner.setDebugTextTagContent("Hazard: Fast Spike Trigger Disabled")
            call owner.setDebugTextTagColorPreset("ORANGE")
            call owner.moveToNextWaypoint()
            call owner.changeState(RunState.create())
            return
        endif

        // Check if hero has reached the current waypoint area
        if RectContainsCoords(currentWaypointArea, heroX, heroY) then
            call owner.changeState(RunState.create())
            return
        endif

        if this.bIsGoingThroughFastSpike then
            set currentOrder = GetUnitCurrentOrder(owner.hero)
            if currentOrder == 0 then
                // Hero is idle (no current order) - reissue move command to current waypoint
                call this.botLog("Hero is idle, reissuing move command")
                call owner.setDebugTextTagContent("Hazard: Reissuing Move Command")
                call owner.setDebugTextTagColorPreset("ORANGE")
                call owner.moveToNextWaypoint()
            endif
            return
        endif

        if udg_bShouldBotGoFastSpike then
            set bIsGoingThroughFastSpike = true
            call this.botLog("Fast Spike hazard - going through quickly")
            call owner.setDebugTextTagContent("Hazard: Fast Spike - Going Through")
            call owner.setDebugTextTagColorPreset("ORANGE")
            call owner.moveToNextWaypoint()
        else
            call this.botLog("Fast Spike hazard - waiting to proceed")
            call owner.setDebugTextTagContent("Hazard: Fast Spike - Waiting")
            call owner.setDebugTextTagColorPreset("ORANGE")
            call IssueImmediateOrder(owner.hero, "stop")
        endif
    endmethod

    method onNetHazardZoneUpdate takes nothing returns nothing
        local real heroX = GetUnitX(owner.hero)
        local real heroY = GetUnitY(owner.hero)
        local real avoidanceDetectRadiusBase = 150
        local real netRadius = NET_RADIUS
        local real avoidanceDetectRadius = avoidanceDetectRadiusBase + netRadius
        local boolean hasNetAhead = false
        local boolean hasNetBehind = false
        local unit netUnit = null
        local rect currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]

        if owner.currentWaypointIndex < 12 then
            call this.botLogError("Waypoint index less than 12 in Net Hazard Zone, correcting to 12")
            call owner.setWaypointIndex(12)
        endif


        if not IsTriggerEnabled(gg_trg_Net01) then
            call this.botLog("Net trigger is disabled, skipping hazard handling")
            call owner.setDebugTextTagContent("Hazard: Net Trigger Disabled")
            call owner.setDebugTextTagColorPreset("ORANGE")
            call owner.moveToNextWaypoint()
            call owner.changeState(RunState.create())
            return
        endif

        // Check if hero has reached the current waypoint area
        if RectContainsCoords(currentWaypointArea, heroX, heroY) then
            call owner.changeState(RunState.create())
            return
        endif

        if IsUnitInvulnerableOrMagicImmune(owner.hero) then
            call this.botLog("Hero is invulnerable or magic immune, skipping spike avoidance")
            call owner.setDebugTextTagContent("Hazard: Magic Immune - No Dodge")
            call owner.setDebugTextTagColorPreset("ORANGE")
            return
        endif

        // check ahead
        set netUnit = this.getHazardAround(avoidanceDetectRadius, false, NET_UNIT_TYPE_ID, NET_SPEED, NET_RADIUS)
        set hasNetAhead = netUnit != null

        // detect net ahead within certain radius
        if hasNetAhead then
            call this.botLog("Net detected ahead, issuing dodge maneuver")
            call owner.setDebugTextTagContent("Hazard: Dodging Net Ahead")
            call owner.setDebugTextTagColorPreset("ORANGE")
            call owner.avoidTargetUnitAhead(netUnit, NET_SPEED, 1.0, false)
            return
        else 
            // check behind
            set netUnit = this.getHazardAround(avoidanceDetectRadius, true, NET_UNIT_TYPE_ID, NET_SPEED, NET_RADIUS)
            set hasNetBehind = netUnit != null
            if hasNetBehind then
                call this.botLog("Net detected behind, issuing dodge maneuver")
                call owner.setDebugTextTagContent("Hazard: Dodging Net Behind")
                call owner.setDebugTextTagColorPreset("ORANGE")
                call owner.avoidTargetUnitBehind(netUnit, true, 1.0, false)
                return
            endif
        endif
        
        if owner.tryEnterCombat() then
            return
        endif

        // No more net around, keep moving to next waypoint
        call owner.moveToNextWaypoint()
    endmethod

    method onSpiderNetHazardZoneUpdate takes nothing returns nothing
        local real heroX = GetUnitX(owner.hero)
        local real heroY = GetUnitY(owner.hero)
        local real avoidanceDetectRadiusBase = 100
        local real netRadius = SPIDER_NET_RADIUS
        local real avoidanceDetectRadius = avoidanceDetectRadiusBase + netRadius
        local boolean hasNetAhead = false
        local boolean hasNetBehind = false
        local unit netUnit = null
        local rect currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
        local boolean isNetInvisible = false

        // Check if hero has reached the current waypoint area
        if not IsInSpiderNetHazardZone(owner) then
            call owner.changeState(RunState.create())
            return
        endif

        // Pickup force staff in spider net hazard zone
        if IsCurrentGoalWaypoint(owner) then
            if owner.shouldCrossSeaOrTree() then
                call owner.setWaypointIndex(131) // Cross Tree Area
                call owner.moveToNextWaypoint()
                return
            endif
        endif

        if IsUnitInvulnerableOrMagicImmune(owner.hero) then
            call this.botLog("Hero is invulnerable or magic immune, skipping spike avoidance")
            call owner.setDebugTextTagContent("Hazard: Magic Immune - No Dodge")
            call owner.setDebugTextTagColorPreset("ORANGE")
            return
        endif

        // check ahead
        set netUnit = this.getHazardAround(avoidanceDetectRadius, false, SPIDER_NET_UNIT_TYPE_ID, 0, SPIDER_NET_RADIUS)
        if netUnit != null then
            set isNetInvisible = GetUnitAbilityLevel(netUnit, 'Apiv') > 0
        endif
        set hasNetAhead = netUnit != null and not isNetInvisible

        // detect net ahead within certain radius
        if hasNetAhead then
            call this.botLog("Spider Net detected ahead, issuing dodge maneuver")
            call owner.setDebugTextTagContent("Hazard: Dodging Spider Net Ahead")
            call owner.setDebugTextTagColorPreset("ORANGE")
            call owner.avoidTargetUnitAhead(netUnit, 0, 1.0, false)
            return
        else 
            // check behind
            set netUnit = this.getHazardAround(avoidanceDetectRadius, true, SPIDER_NET_UNIT_TYPE_ID, 0, SPIDER_NET_RADIUS)
            if netUnit != null then
                set isNetInvisible = GetUnitAbilityLevel(netUnit, 'Apiv') > 0
            endif
            set hasNetBehind = netUnit != null and not isNetInvisible
            if hasNetBehind then
                call this.botLog("Spider Net detected behind, issuing dodge maneuver")
                call owner.setDebugTextTagContent("Hazard: Dodging Spider Net Behind")
                call owner.setDebugTextTagColorPreset("ORANGE")
                call owner.avoidTargetUnitBehind(netUnit, true, 1.0, false)
                return
            endif
        endif

        if owner.tryEnterCombat() then
            return
        endif

        // No more spider net around, keep moving to next waypoint
        call owner.moveToNextWaypoint()
    endmethod

    method moveToRandomPointInOrangeFishZone takes nothing returns nothing
        local rect orangeZone = gg_rct_AIHazardOrangeFishWaitArea
        local real x
        local real y
        set x = GetRandomReal(GetRectMinX(orangeZone), GetRectMaxX(orangeZone))
        set y = GetRandomReal(GetRectMinY(orangeZone), GetRectMaxY(orangeZone))

        call IssuePointOrder(owner.hero, "move", x, y)
    endmethod

    method onOrangeFishHazardZoneUpdate takes nothing returns nothing
        local boolean hasNearbyEnemy = false

        if not IsInOrangeFishWaitArea(owner) then
            call owner.changeState(RunState.create())
            return
        endif

        if not IsOrangeFishStable() then
            call this.botLog("Orange Fish is not stable, exiting hazard state")
            call owner.changeState(RunState.create())
            return
        endif

        set hasNearbyEnemy = GetHeroCountAroundUnit(owner.hero, HAZARD_ORANGE_FISH_ENEMY_DETECT_RADIUS, FIND_TEAM_TYPE_ENEMIES) > 0

        if not hasNearbyEnemy then
            call this.botLog("No nearby enemies detected, exiting Orange Fish hazard state")
            call owner.changeState(RunState.create())
            return
        endif

        if IsUnitInvulnerableOrMagicImmune(owner.hero) then
            call this.botLog("Hero is invulnerable or magic immune, skipping Orange Fish hazard handling")
            call owner.changeState(RunState.create())
            return
        endif

        if owner.tryEnterCombat() then
            return
        endif

        if owner.TryEnterGiveItemState() then
            return 
        endif

        if owner.TryEnterPickupItemState() then
            return
        endif

        call this.moveToRandomPointInOrangeFishZone()

    endmethod


    method onExit takes nothing returns nothing
        call this.botLog("Exiting Hazard State")
        call owner.setDebugTextTagContent("Hazard: Exiting")
        call owner.setDebugTextTagColorPreset("ORANGE")
    endmethod

endstruct