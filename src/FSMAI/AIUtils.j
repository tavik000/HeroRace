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

    function FilterSuitablePickUpItem takes nothing returns nothing
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

        call EnumItemsInRectBJ(rec, function FilterSuitablePickUpItem)
        call RemoveRect(rec)
        set foundItem = tempFoundItem

        return foundItem
    endfunction

    function GetHeroCastPoint takes integer heroTypeId returns real
        if HaveSavedReal(heroCastPointMap, heroTypeId, 0) then
            return LoadReal(heroCastPointMap, heroTypeId, 0)
        else
            call BotLogError("Unknown hero type for GetHeroCastPoint: " + I2S(heroTypeId))
            return 0.5  // Default cast point for unknown hero types
        endif
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

    // Generic filter function for heroes (enemies or allies)
    function FilterTeamHeroes takes nothing returns boolean
        local unit filterUnit = GetFilterUnit()
        
        if not IsValidHeroTarget(filterUnit) then
            set filterUnit = null
            return false
        endif

        // Check if we want allies or enemies
        if bTempFilterForAllies then
            // Filter for allies (same team, but not the same unit)
            if IsUnitEnemy(filterUnit, tempHeroOwner) then
                set filterUnit = null
                return false
            endif
        else
            // Filter for enemies
            if not IsUnitEnemy(filterUnit, tempHeroOwner) then
                set filterUnit = null
                return false
            endif
        endif
        
        set filterUnit = null
        return true
    endfunction

    function GetAIHeroFromUnit takes unit u returns AIHero
        if u == null then
            return 0
        endif
        return LoadInteger(udg_UnitAIHeroMap, GetHandleId(u), 0)
    endfunction

    function DestroyAIHero takes unit u returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.destroy()
        endif
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
            if wpi == 14 then
                return true
            endif
        endif
        return false
    endfunction

    function IsFinalWaypoint takes AIHero aiHero returns boolean
        if aiHero.currentWaypointIndex >= WaypointCount then
            return true
        endif
        return false
    endfunction


endlibrary