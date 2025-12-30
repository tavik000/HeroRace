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
endlibrary