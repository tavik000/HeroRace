library AIHelper requires KeyUtils
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

    function IsApplyingCombo takes integer difficulty returns boolean
        if difficulty == DIFF_HARD or difficulty == DIFF_CRAZY or difficulty == DIFF_NIGHTMARE then
            return true
        else
            return false
        endif
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

    function EnumItemsAction takes nothing returns nothing
        local item itm = GetEnumItem()
        local real dist = DistanceBetweenXY(tempFoundItemX, tempFoundItemY, GetItemX(itm), GetItemY(itm))
        local real itemAngle = AngleBetweenXY(tempFoundItemX, tempFoundItemY, GetItemX(itm), GetItemY(itm))
        local boolean bIsInFrontArc = IsWithinForwardArc(itemAngle, tempFoundItemUnitFacingAngle)
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

        call EnumItemsInRectBJ(rec, function EnumItemsAction)
        call RemoveRect(rec)
        set foundItem = tempFoundItem

        return foundItem
    endfunction
endlibrary