//===========================================================================
// Trigger: AISummon
globals
    hashtable udg_SummonAttackTargetTimerMap
    constant integer SUMMON_KEY_ATTACK_TARGET = 0
    constant integer SUMMON_KEY_SUMMON_UNIT = 1
    constant integer SUMMON_KEY_SUMMONER = 2
    constant integer SUMMON_KEY_BLINK_LAST_CAST_TIME = 3
    constant integer SUMMON_KEY_CRIPPLE_LAST_CAST_TIME = 4
    constant integer SUMMON_KEY_STOMP_LAST_CAST_TIME = 5
    constant integer SUMMON_KEY_DISPEL_LAST_CAST_TIME = 6
    constant integer SUMMON_KEY_THROW_STONE_LAST_CAST_TIME = 7
    constant real SUMMON_BLINK_CD = 20.0
    constant real SUMMON_FRENZY_MANA_COST = 100.0
    constant real SUMMON_CRIPPLE_CD = 40.0
    constant real SUMMON_STOMP_CD = 15.0
    constant real SUMMON_DISPEL_CD = 10.0
    constant real SUMMON_THROW_STONE_CD = 50.0
endglobals
//===========================================================================

function Trig_AISummonConditions takes nothing returns boolean
    local player summonedPlayer = GetOwningPlayer( GetSummonedUnit())
    return IsPlayerBot(summonedPlayer)
endfunction

function FindSummonAttackTargetUnit takes AIHero summonerAIHero, unit summonUnit, real expectedDamage returns unit
    local unit attackTarget = null
    set attackTarget = FindLowHealthEnemyTargetInRange(summonerAIHero, summonUnit, 1500.0, expectedDamage, false, false, 0, 0)

    if attackTarget == null then
        set attackTarget = FindLowHealthEnemyTargetInRange(summonerAIHero, summonUnit, 2000.0, expectedDamage, false, false, 0, 0)
        if attackTarget == null then
            set attackTarget = FindLowHealthEnemyTargetInRange(summonerAIHero, summonUnit, 4000.0, expectedDamage, false, false, 0, 0)
            if attackTarget == null then
                set attackTarget = FindLowHealthEnemyTargetInRange(summonerAIHero, summonUnit, MAX_RANGE, expectedDamage, false, false, 0, 0)
            endif
        endif
    endif
    return attackTarget
endfunction

function AISummonIsUnitGrizzly takes unit summonUnit returns boolean
    return (GetUnitTypeId(summonUnit) == 'n01E')
endfunction

function AISummonIsUnitQuillBeast takes unit summonUnit returns boolean
    return (GetUnitTypeId(summonUnit) == 'n01P')
endfunction

function AISummonIsUnitInferno takes unit summonUnit returns boolean
    return (GetUnitTypeId(summonUnit) == 'n009')
endfunction

function AISummonIsUnitSpiritWolf takes unit summonUnit returns boolean
    return (GetUnitTypeId(summonUnit) == 'o00C')
endfunction

function AISummonIsUnitTreant takes unit summonUnit returns boolean
    return (GetUnitTypeId(summonUnit) == 'e00A')
endfunction

function AISummonIsUnitDoomGuard takes unit summonUnit returns boolean
    return (GetUnitTypeId(summonUnit) == 'n01R')
endfunction

function AISummonIsUnitCarrionBeetle takes unit summonUnit returns boolean
    return (GetUnitTypeId(summonUnit) == 'u008')
endfunction

function AISummonIsUnitEarthPanda takes unit summonUnit returns boolean
    return (GetUnitTypeId(summonUnit) == 'n01M')
endfunction

function AISummonIsUnitWindPanda takes unit summonUnit returns boolean
    return (GetUnitTypeId(summonUnit) == 'n01N')
endfunction

function AISummonIsUnitFirePanda takes unit summonUnit returns boolean
    return (GetUnitTypeId(summonUnit) == 'n01O')
endfunction

function AISummonIsBlinkCooldownReady takes unit summonUnit, real blinkCooldown, timer attackTargetTimer returns boolean
    local real currentTime = TimerGetElapsed(gameTimer)
    local real lastBlinkCastTime = LoadReal(udg_SummonAttackTargetTimerMap, GetHandleId(attackTargetTimer), SUMMON_KEY_BLINK_LAST_CAST_TIME)
    return (currentTime >= lastBlinkCastTime + blinkCooldown) or (IsNearlyZero(lastBlinkCastTime))
endfunction

function AISummonIsCrippleCooldownReady takes unit summonUnit, real crippleCooldown, timer attackTargetTimer returns boolean
    local real currentTime = TimerGetElapsed(gameTimer)
    local real lastCrippleCastTime = LoadReal(udg_SummonAttackTargetTimerMap, GetHandleId(attackTargetTimer), SUMMON_KEY_CRIPPLE_LAST_CAST_TIME)
    return (currentTime >= lastCrippleCastTime + crippleCooldown) or (IsNearlyZero(lastCrippleCastTime))
endfunction

function AISummonIsStompCooldownReady takes unit summonUnit, real stompCooldown, timer attackTargetTimer returns boolean
    local real currentTime = TimerGetElapsed(gameTimer)
    local real lastStompCastTime = LoadReal(udg_SummonAttackTargetTimerMap, GetHandleId(attackTargetTimer), SUMMON_KEY_STOMP_LAST_CAST_TIME)
    return (currentTime >= lastStompCastTime + stompCooldown) or (IsNearlyZero(lastStompCastTime))
endfunction

function AISummonIsDispelCooldownReady takes unit summonUnit, real dispelCooldown, timer attackTargetTimer returns boolean
    local real currentTime = TimerGetElapsed(gameTimer)
    local real lastDispelCastTime = LoadReal(udg_SummonAttackTargetTimerMap, GetHandleId(attackTargetTimer), SUMMON_KEY_DISPEL_LAST_CAST_TIME)
    return (currentTime >= lastDispelCastTime + dispelCooldown) or (IsNearlyZero(lastDispelCastTime))
endfunction

function AISummonIsThrowStoneCooldownReady takes unit summonUnit, real throwStoneCooldown, timer attackTargetTimer returns boolean
    local real currentTime = TimerGetElapsed(gameTimer)
    local real lastThrowStoneCastTime = LoadReal(udg_SummonAttackTargetTimerMap, GetHandleId(attackTargetTimer), SUMMON_KEY_THROW_STONE_LAST_CAST_TIME)
    return (currentTime >= lastThrowStoneCastTime + throwStoneCooldown) or (IsNearlyZero(lastThrowStoneCastTime))
endfunction

function AISummonIsFrenzyManaReady takes unit summonUnit returns boolean
    return (GetUnitStateSwap(UNIT_STATE_MANA, summonUnit) >= SUMMON_FRENZY_MANA_COST)
endfunction

function AISummonGoAndAttackNewTarget takes unit summonUnit, unit newAttackTarget, timer attackTargetTimer returns nothing
    local real distanceToAttackTarget = DistanceBetweenUnits(summonUnit, newAttackTarget)
    local real currentTime = TimerGetElapsed(gameTimer)

    if AISummonIsUnitEarthPanda(summonUnit) then
        call IssuePointOrder(summonUnit, "move", GoalX, GoalY)
        return
    endif

    if AISummonIsUnitGrizzly(summonUnit) or AISummonIsUnitSpiritWolf(summonUnit) then
        if distanceToAttackTarget > 1200.0 then
            // blink then attack
            if AISummonIsBlinkCooldownReady(summonUnit, SUMMON_BLINK_CD, attackTargetTimer) then
                call IssuePointOrder(summonUnit, "blink", GetUnitX(newAttackTarget), GetUnitY(newAttackTarget))
                call SaveReal(udg_SummonAttackTargetTimerMap, GetHandleId(attackTargetTimer), SUMMON_KEY_BLINK_LAST_CAST_TIME, currentTime)
                call BotLog("Summoned Grizzly blink to attack target: " + GetUnitName(newAttackTarget))    
                call PolledWait(0.5)
            else
                call BotLog("Summoned Grizzly blink on cooldown, cannot blink to target: " + GetUnitName(newAttackTarget))
            endif
        endif
    endif

    if AISummonIsUnitFirePanda(summonUnit) then
        call IssueTargetOrder(summonUnit, "move", newAttackTarget)
        return
    endif

    call IssueTargetOrder(summonUnit, "attack", newAttackTarget)
endfunction

function OnAISummonRetargetTimerUpdate takes nothing returns nothing
    local timer currentTimer = GetExpiredTimer()
    local unit attackTarget = LoadUnitHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_ATTACK_TARGET)
    local unit summonUnit = LoadUnitHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_SUMMON_UNIT)
    local unit summoner = LoadUnitHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_SUMMONER)
    local AIHero summonerAIHero = GetAIHeroByUnit(summoner)
    local real expectedDamage = GetUnitMaxAttackDamage(summonUnit) * 4.0 // Assume 4 attacks
    local unit newAttackTarget = null
    local real distanceToAttackTarget = DistanceBetweenUnits(summonUnit, attackTarget)
    local real distanceToSummoner = 0.0
    local integer currentOrder = GetUnitCurrentOrder(summonUnit)
    local unit ccAllyTarget = null

    if not IsUnitAliveBJ(summonUnit) then
        // Summon died, clean up timer
        call BotLog("Summoned unit (" + GetUnitName(summonUnit) + ") died, cleaning up retarget timer.")
        set attackTarget = null
        set summonUnit = null
        set summoner = null
        call RemoveSavedHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_ATTACK_TARGET)
        call RemoveSavedHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_SUMMON_UNIT)
        call RemoveSavedHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_SUMMONER)
        call DestroyTimer(currentTimer)
        return
    endif

    // Retarget if attack target died or currently idle
    if not IsUnitAliveBJ(attackTarget) or currentOrder == 0 then
        // Attack target died, find new target
        set newAttackTarget = FindSummonAttackTargetUnit(summonerAIHero, summonUnit, expectedDamage)
        if newAttackTarget != null then
            call AISummonGoAndAttackNewTarget(summonUnit, newAttackTarget, currentTimer)
            call BotLog("Summoned unit retargeting to new low health target: " + GetUnitName(newAttackTarget) + " for summoned unit: " + GetUnitName(summonUnit))
            // Update saved attack target
            call SaveUnitHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_ATTACK_TARGET, newAttackTarget)
        else
            if AISummonIsUnitEarthPanda(summonUnit) then
                call IssuePointOrder(summonUnit, "move", GoalX, GoalY)

                // Clean up timer
                set attackTarget = null
                set summonUnit = null
                set summoner = null
                call RemoveSavedHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_ATTACK_TARGET)
                call RemoveSavedHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_SUMMON_UNIT)
                call RemoveSavedHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_SUMMONER)
                call DestroyTimer(currentTimer)
                return
            endif

            // Attack move to summoner's location
            set distanceToSummoner = DistanceBetweenUnits(summonUnit, summoner)
            if distanceToSummoner > 500.0 then
                call IssuePointOrder(summonUnit, "attack", GetUnitX(summoner), GetUnitY(summoner))
                call BotLog("No low health target found for summoned unit, AMove to summoner.")
            else
                call IssuePointOrder(summonUnit, "attack", GoalX, GoalY)
                call BotLog("No low health target found for summoned unit, AMove to goal point.")
            endif

            // Clean up timer
            set attackTarget = null
            set summonUnit = null
            set summoner = null
            call RemoveSavedHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_ATTACK_TARGET)
            call RemoveSavedHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_SUMMON_UNIT)
            call RemoveSavedHandle(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_SUMMONER)
            call DestroyTimer(currentTimer)
        endif
        return
    endif

    if AISummonIsUnitQuillBeast(summonUnit) then
        // Use Frenzy
        if distanceToAttackTarget < 600.0 then
            if AISummonIsFrenzyManaReady(summonUnit) then
                call IssueImmediateOrder(summonUnit, "frenzy")
                call IssueTargetOrder(summonUnit, "attack", attackTarget)
                call BotLog("Summoned Quill Beast using Frenzy on target: " + GetUnitName(attackTarget))
            endif
        endif
    endif

    if AISummonIsUnitDoomGuard(summonUnit) then
        // Use Cripple and Stomp
        if distanceToAttackTarget < 600.0 then
            if AISummonIsCrippleCooldownReady(summonUnit, SUMMON_CRIPPLE_CD, currentTimer) then
                call IssueTargetOrder(summonUnit, "cripple", attackTarget)
                call SaveReal(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_CRIPPLE_LAST_CAST_TIME, TimerGetElapsed(gameTimer))
                call PolledWait(0.5)
                call IssueTargetOrder(summonUnit, "attack", attackTarget)
                call BotLog("Summoned Doom Guard using Cripple on target: " + GetUnitName(attackTarget))
            endif
        endif
        if distanceToAttackTarget < 300.0 then
            if AISummonIsStompCooldownReady(summonUnit, SUMMON_STOMP_CD, currentTimer) then
                call IssueImmediateOrder(summonUnit, "stomp")
                call SaveReal(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_STOMP_LAST_CAST_TIME, TimerGetElapsed(gameTimer))
                call PolledWait(0.5)
                call IssueTargetOrder(summonUnit, "attack", attackTarget)
                call BotLog("Summoned Doom Guard using War Stomp on target: " + GetUnitName(attackTarget))
            endif
        endif
        if AISummonIsDispelCooldownReady(summonUnit, SUMMON_DISPEL_CD, currentTimer) then
            // Check if any allied unit around is CCed
            set ccAllyTarget = FindCCedTargetInRange(summonUnit, MAX_RANGE, FIND_TEAM_TYPE_ALLIES, false, 0, 0)
            if ccAllyTarget != null then
                call IssuePointOrder(summonUnit, "dispel", GetUnitX(ccAllyTarget), GetUnitY(ccAllyTarget))
                call SaveReal(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_DISPEL_LAST_CAST_TIME, TimerGetElapsed(gameTimer))
                call PolledWait(0.5)
                call IssueTargetOrder(summonUnit, "attack", attackTarget)
                call BotLog("Summoned Doom Guard using Dispel on CCed ally: " + GetUnitName(ccAllyTarget))
            endif
        endif
    endif

    if AISummonIsUnitWindPanda(summonUnit) then
        if AISummonIsDispelCooldownReady(summonUnit, SUMMON_DISPEL_CD, currentTimer) then
            // Check if any allied unit around is CCed
            set ccAllyTarget = FindCCedTargetInRange(summonUnit, MAX_RANGE, FIND_TEAM_TYPE_ALLIES, false, 0, 0)
            if ccAllyTarget != null then
                call IssuePointOrder(summonUnit, "dispel", GetUnitX(ccAllyTarget), GetUnitY(ccAllyTarget))
                call SaveReal(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_DISPEL_LAST_CAST_TIME, TimerGetElapsed(gameTimer))
                call PolledWait(0.5)
                call IssueTargetOrder(summonUnit, "attack", attackTarget)
                call BotLog("Summoned Wind Panda using Dispel on CCed ally: " + GetUnitName(ccAllyTarget))
            endif
        endif
    endif

    if AISummonIsUnitEarthPanda(summonUnit) then
        if distanceToAttackTarget < 900.0 then
            if AISummonIsThrowStoneCooldownReady(summonUnit, SUMMON_THROW_STONE_CD, currentTimer) then
                call IssueTargetOrder(summonUnit, "creepthunderbolt", attackTarget)
                call SaveReal(udg_SummonAttackTargetTimerMap, GetHandleId(currentTimer), SUMMON_KEY_THROW_STONE_LAST_CAST_TIME, TimerGetElapsed(gameTimer))
                call PolledWait(0.5)
                call IssuePointOrder(summonUnit, "move", GoalX, GoalY)
                call BotLog("Summoned Earth Panda using Throw Stone on target: " + GetUnitName(attackTarget))
            endif
        endif

        if currentOrder == 0 then
            call IssuePointOrder(summonUnit, "move", GoalX, GoalY)
        endif
        return
    endif

endfunction

function Trig_AISummonActions takes nothing returns nothing
    local unit summoner = GetSummoningUnit()
    local unit summonUnit = GetSummonedUnit()
    local AIHero summonerAIHero = GetAIHeroByUnit(summoner)
    local integer spellId = GetSpellAbilityId()
    local real expectedDamage = GetUnitMaxAttackDamage(summonUnit) * 4.0 // Assume 4 attacks
    local unit attackTarget = null
    local real distanceToAttackTarget = 0.0
    local timer attackTargetTimer = null
    local real distanceToSummoner = 0.0

    if IsUnitWard(summonUnit) then
        return
    endif

    if not IsUnitType(summoner, UNIT_TYPE_HERO) then
        // find hero of summoner player
        set summonerAIHero = GetAIHeroByPlayer(GetOwningPlayer(summoner))
        set summoner = summonerAIHero.hero
    endif

    if not IsAIHardOrAbove(summonerAIHero.difficulty) then
        call BotLog("Summoned unit: " + GetUnitName(summonUnit) + " by summoner: " + GetUnitName(summoner) + " but AI difficulty is not hard or above, skipping summon actions.")
        // clean
        set attackTarget = null
        set summonUnit = null
        set summoner = null
        set summonerAIHero = 0
        return
    endif

    // Illusion hero, just move to goal point
    if IsUnitIllusionBJ(summonUnit) then
        if IsHeroUnitId(GetUnitTypeId(summonUnit)) then
            call IssuePointOrder(summonUnit, "move", GoalX, GoalY)
            return
        endif
    endif

    if AISummonIsUnitCarrionBeetle(summonUnit) then
        set attackTarget = FindStunnedTargetInRange(summonUnit, MAX_RANGE, FIND_TEAM_TYPE_ENEMIES, true, 0, 0)
        if attackTarget != null then
            call IssueTargetOrder(summonUnit, "move", attackTarget)
        endif
        return
    endif


    call BotLog("Summoned unit: " + GetUnitName(summonUnit) + " by summoner: " + GetUnitName(summoner))

    set attackTarget = FindSummonAttackTargetUnit(summonerAIHero, summonUnit, expectedDamage)
    if attackTarget != null then

        if AISummonIsUnitWindPanda(summonUnit) then
            call IssueTargetOrder(summonUnit, "cyclone", FindHealthyRunningEnemyTargetInRange(summonUnit, MAX_RANGE, attackTarget, 0, 0))
            call PolledWait(0.8)
            call IssueImmediateOrder(summonUnit, "windwalk")
        endif

        call AISummonGoAndAttackNewTarget(summonUnit, attackTarget, attackTargetTimer)
        // Keep track if attack target died, so that we can retarget
        set attackTargetTimer = CreateTimer()
        call SaveUnitHandle(udg_SummonAttackTargetTimerMap, GetHandleId(attackTargetTimer), SUMMON_KEY_ATTACK_TARGET, attackTarget)
        call SaveUnitHandle(udg_SummonAttackTargetTimerMap, GetHandleId(attackTargetTimer), SUMMON_KEY_SUMMON_UNIT, summonUnit)
        call SaveUnitHandle(udg_SummonAttackTargetTimerMap, GetHandleId(attackTargetTimer), SUMMON_KEY_SUMMONER, summoner)
        call TimerStart(attackTargetTimer, 2.0, true, function OnAISummonRetargetTimerUpdate)
        call BotLog("Summoned unit attacking low health target: " + GetUnitName(attackTarget) + " for expected damage: " + R2S(expectedDamage))
    else
        // Attack move to summoner's location
        set distanceToSummoner = DistanceBetweenUnits(summonUnit, summoner)
        if distanceToSummoner > 500.0 then
            call IssuePointOrder(summonUnit, "attack", GetUnitX(summoner), GetUnitY(summoner))
            call BotLog("No low health target found for summoned unit, AMove to summoner.")
        else
            call IssuePointOrder(summonUnit, "attack", GoalX, GoalY)
            call BotLog("No low health target found for summoned unit, AMove to goal point.")
        endif
    endif
endfunction

//===========================================================================
function InitTrig_AISummon takes nothing returns nothing
	set gg_trg_AISummon = CreateTrigger()
    set udg_SummonAttackTargetTimerMap = InitHashtable()
	call TriggerRegisterAnyUnitEventBJ(gg_trg_AISummon, EVENT_PLAYER_UNIT_SUMMON)
	call TriggerAddCondition(gg_trg_AISummon, Condition(function Trig_AISummonConditions))
	call TriggerAddAction(gg_trg_AISummon, function Trig_AISummonActions)
endfunction