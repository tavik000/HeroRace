//===========================================================================
// Trigger: AIDamageBoost
//===========================================================================
function Trig_AIDamageBoostActions takes nothing returns nothing
    local unit damageSource = GetEventDamageSource()
    local unit targetUnit = GetTriggerUnit()
    local real eventDamage = GetEventDamage()
    local player sourcePlayer = GetOwningPlayer(damageSource)
    local real extraDamage = 0.0
    local AIHero aiHero
    local integer difficulty
    local integer targetId
    local integer sourceId

    if sourcePlayer == Player(11) then
        return
    endif
    if eventDamage < 1.0 then
        return
    endif
    if eventDamage > 3000.0 then
        return
    endif
    if not IsUnitType(damageSource, UNIT_TYPE_HERO) then
        // find hero of summoner player
        set aiHero = GetAIHeroByPlayer(sourcePlayer)
    else
        set aiHero = GetAIHeroFromUnit(damageSource)
    endif
    if aiHero == 0 then
        return
    endif
    set damageSource = aiHero.hero

    if not IsPlayerBot(sourcePlayer) then
        return
    endif
    if not IsUnitValid(targetUnit) then
        return
    endif
    if not IsUnitValid(damageSource) then
        return
    endif
    if not IsUnitEnemy(targetUnit, sourcePlayer) then
        return
    endif
    if aiHero == null then
        return
    endif
    set difficulty = aiHero.difficulty
    if difficulty >= DIFF_CRAZY then

        // Prevent recursion: check if this target already got extra damage from this damageSource
        set targetId = GetHandleId(targetUnit)
        set sourceId = GetHandleId(damageSource)
        if LoadBoolean(g_htDamageBoost, targetId, sourceId) then
            return
        endif
        call SaveBoolean(g_htDamageBoost, targetId, sourceId, true)

        set extraDamage = eventDamage * GetExtraDamagePercentage(difficulty)
        call TriggerSleepAction(0.0) // 1-frame delay
        call UnitDamageTarget(damageSource, targetUnit, extraDamage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, null)

        // Clear the recursion flag immediately so next damage events can run
        call SaveBoolean(g_htDamageBoost, targetId, sourceId, false)
    endif

endfunction

//===========================================================================
function InitTrig_AIDamageBoost takes nothing returns nothing
	set gg_trg_AIDamageBoost = CreateTrigger()
#ifdef DEBUG
	call YDWESaveTriggerName(gg_trg_AIDamageBoost,"AIDamageBoost")
#endif
	call YDWESyStemAnyUnitDamagedRegistTrigger(gg_trg_AIDamageBoost)
	call TriggerAddAction(gg_trg_AIDamageBoost, function Trig_AIDamageBoostActions)
endfunction

