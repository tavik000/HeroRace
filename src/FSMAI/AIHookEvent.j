library AIHookEvent requires AIUtils

    function OnAIHeroCastComplete takes unit u returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.onCastComplete()
        endif
    endfunction

    function OnAIHeroGetItem takes unit u, item itm returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.onGetItem(itm)
        endif
    endfunction

    function OnAIHeroBeTargetedByEnemyAbility takes unit u, unit caster, integer abilityId returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        local real distanceToEnemyCaster = 0.0
        local real projectileSpeed = 0.0
        local boolean bIsProjectileAbility = IsTargetUnitProjectileAbility(abilityId)
        local real timeToWait = 0.0
        if aiHero == null then
            return
        endif

        call aiHero.onBeTargetedByEnemyAbilityImmediate(caster, abilityId)

        if bIsProjectileAbility then
            set distanceToEnemyCaster = DistanceBetweenUnits(u, caster)
            set projectileSpeed = GetNonAIAbilityProjectileSpeed(abilityId)
            if projectileSpeed > 0.0 then
                set timeToWait = (distanceToEnemyCaster / projectileSpeed) - 0.9
                if timeToWait > 0.0 then
                    call aiHero.botLog("Waiting for " + R2S(timeToWait) + " seconds before processing being targeted by enemy ability: " + GetObjectName(abilityId))
                    call PolledWait(timeToWait)
                endif
            endif
        endif

        call aiHero.onBeTargetedByEnemyAbilityProjectileDelayed(caster, abilityId)

    endfunction

    function OnAIHeroBeTargetedByEnemyAttack takes unit u, unit attacker returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.onBeTargetedByEnemyAttack(attacker)
        endif
    endfunction

    function OnAIHeroBeMeatHookedReturnFinish takes unit u returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.onBeMeatHookedReturnFinish()
        endif
    endfunction

    function OnAIHeroBeTargetedByBomberSelfDestruct takes unit u, boolean isMegaBomber returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.onBeTargetedByBomberSelfDestruct(isMegaBomber)
        endif
    endfunction

    function OnTurnOnAIHeroBotTextTag takes nothing returns nothing
        local AIHero aiHero = 0
        local integer i = 0
        local player p = null

        loop
            exitwhen i >= bj_MAX_PLAYERS
            set p = Player(i)
            set aiHero = GetAIHeroByPlayer(p)
            if aiHero != null then
                call aiHero.createDebugTextTag()
            endif
            set i = i + 1
        endloop
    endfunction

endlibrary