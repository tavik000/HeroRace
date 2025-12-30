library AIItemConfig
    globals
        hashtable ItemDataTable
    endglobals

    function InitItemData takes nothing returns nothing
        set ItemDataTable = InitHashtable()
    
        // Example: SaveReal(ItemDataTable, itemId, key, value)
        // Item 'I001' - Force Staff
        call SaveReal(ItemDataTable, 'I001', 0, 15.0)    // base cooldown
        call SaveReal(ItemDataTable, 'I001', 1, 600.0)   // cast range
        call SaveReal(ItemDataTable, 'I001', 2, 150.0)   // effective radius
        call SaveInteger(ItemDataTable, 'I001', 3, CAST_POINT_SELF_FRONT) // cast type
        call SaveInteger(ItemDataTable, 'I001', 4, FIND_TARGET_TYPE_SELF_FORCE_STAFF) // find target type
        call SaveBoolean(ItemDataTable, 'I001', 5, false) // is passive
    
        // Add more items...
    endfunction

    function GetItemBaseCooldown takes integer itemId returns real
        return LoadReal(ItemDataTable, itemId, 0)
    endfunction

    function GetItemCastRange takes integer itemId returns real
        return LoadReal(ItemDataTable, itemId, 1)
    endfunction

    function GetItemEffectiveRadius takes integer itemId returns real
        return LoadReal(ItemDataTable, itemId, 2)
    endfunction

    function GetItemCastType takes integer itemId returns integer
        return LoadInteger(ItemDataTable, itemId, 3)
    endfunction

    function GetItemFindTargetType takes integer itemId returns integer
        return LoadInteger(ItemDataTable, itemId, 4)
    endfunction

    function GetItemIsPassive takes integer itemId returns boolean
        return LoadBoolean(ItemDataTable, itemId, 5)
    endfunction
endlibrary