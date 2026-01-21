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
        if aiHero != null then
            call aiHero.onBeTargetedByEnemyAbility(caster, abilityId)
        endif
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


endlibrary