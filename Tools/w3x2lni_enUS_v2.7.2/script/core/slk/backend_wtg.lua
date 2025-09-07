local lang = require 'lang'
local w2l
local wtg
local wts
local state
local hex

local pack_eca

local CALL     = lang.lml.CALL:match '^(.-)%s*$'
local DISABLE  = lang.lml.DISABLE:match '^(.-)%s*$'
local PRESET   = lang.lml.PRESET:match '^(.-)%s*$'
local VARIABLE = lang.lml.VARIABLE:match '^(.-)%s*$'
local CONSTANT = lang.lml.CONSTANT:match '^(.-)%s*$'
local ARRAY    = lang.lml.ARRAY:match '^(.-)%s*$'
local DEFAULT  = lang.lml.DEFAULT:match '^(.-)%s*$'

local type_map = {
    [lang.lml.LIST] = -1,
    [lang.lml.EVENT] = 0,
    [lang.lml.CONDITION] = 1,
    [lang.lml.ACTION] = 2,
    [CALL] = 3,
}

local type_key = {
    [lang.lml.EVENT] = 'event',
    [lang.lml.CONDITION] = 'condition',
    [lang.lml.ACTION] = 'action',
    [CALL] = 'call',
}

local arg_type_map = {
    [DISABLE] = -1,
    [PRESET] = 0,
    [VARIABLE] = 1,
    [CALL] = 2,
    [CONSTANT] = 3,
}


local function pack(fmt, ...)
    hex[#hex+1] = fmt:pack(...)
end

local function pack_head()
    pack('c4', 'WTG!')
    if wtg.format_version then
        pack('LLLLLL'
            , 0x80000004
            , 7
            , wtg.unknown1
            , wtg.unknown2
            , wtg.unknown3
            , wtg.unknown4
        )
    else
        pack('L', 7)
    end
end

local function pack_counts()
    local trigger_count = 0
    local comment_count = 0
    local script_count = 0
    for _, trg in ipairs(wtg.triggers) do
        if trg.type == 0 then
            trigger_count = trigger_count + 1
        elseif trg.wct == 1 then
            script_count = script_count + 1
        else
            comment_count = comment_count + 1
        end
    end

    pack('LL', #wtg.categories, 0)
    pack('LL', trigger_count, 0)
    pack('LL', comment_count, 0)
    pack('LL', script_count, 0)
    pack('LL', #wtg.vars, 0)
    pack('LL'
        , wtg.unknown5
        , wtg.unknown6
    )
end

local function pack_category()
    pack('l', #wtg.categories)
    for _, cate in ipairs(wtg.categories) do
        pack('lzl', cate.id, cate.name, cate.comment)
    end
end

local function pack_var(var)
    local name = var[1]
    local type = var[2]
    local unknow = 1
    local array = 0
    local size = 1
    local default = 0
    local value = ''
    for i = 3, #var do
        local k, v = var[i][1], var[i][2]
        if k == ARRAY then
            array = 1
            size = v
        elseif k == DEFAULT then
            default = 1
            value = v
        end
    end
    pack('zzllllz'
        , name
        , type
        , unknow
        , array
        , size
        , default
        , value
    )

    if wtg.format_version then
        pack('LL'
            , var.id
            , var.category
        )
    end
end

local function pack_vars()
    pack('ll', 2, #wtg.vars)
    for i = 1, #wtg.vars do
        pack_var(wtg.vars[i])
    end
end

local function pack_arg(arg)
    local type = arg[1]
    local value = arg[2]
    local array = false
    if type_map[type] then
        type = CALL
        if type_map[type] ~= CALL then
            value = ''
        end
    elseif type == ARRAY then
        array = true
        type = VARIABLE
    end
    if type == CONSTANT then
        value = w2l:load_wts(wts, value, 299, lang.script.TEXT_TOO_LONG_IN_WTG)
    end
    pack('lz', arg_type_map[type], value)
    if type == CALL then
        pack('l', 1)
        pack_eca(arg)
    else
        pack('l', 0)
    end
    if array then
        pack('l', 1)
        pack_arg(arg[3])
    else
        pack('l', 0)
    end
end

local arg_count = {}
local function get_ui_arg_count(ui)
    local name = ui.name
    if not arg_count[name] then
        local count = 0
        if ui.args then
            for _, arg in ipairs(ui.args) do
                if arg.type ~= 'nothing' then
                    count = count + 1
                end
            end
        end
        arg_count[name] = count
    end
    return arg_count[name]
end

local function pack_args(ui, eca)
    local eca_arg_count = 0
    for i = 3, #eca do
        if eca[i][2] then
            eca_arg_count = eca_arg_count + 1
            pack_arg(eca[i])
        end
    end

    if ui then
        if eca_arg_count ~= get_ui_arg_count(ui) then
            error(lang.script.WTG_ERROR_ARG:format(ui.name, get_ui_arg_count(ui), eca_arg_count))
        end
    end
end

local function pack_list(lists, root)
    local child_count = 0
    for i = 3, #lists do
        if not lists[i][2] and type_map[lists[i][1]] and #lists[i] > 2 then
            child_count = child_count + #lists[i] - 2
        end
    end
    pack('l', child_count)
    local child_id = -1
    for i = 3, #lists do
        if not lists[i][2] and type_map[lists[i][1]] then
            child_id = child_id + 1
            local list = lists[i]
            local type = list[1]
            for i = 3, #list do
                if root then
                    pack_eca(list[i], nil, type)
                else
                    pack_eca(list[i], child_id, type)
                end
            end
        end
    end
end

function pack_eca(eca, child_id, eca_type)
    local name
    local type = eca_type or CALL
    local enable = 1
    if eca[2] then
        name = eca[2]
        if eca[1] == DISABLE then
            enable = 0
        elseif type_map[eca[1]] then
            type = eca[1]
        else
            w2l.messager.text(lang.script.WTG_UNKNOWN_ACTION_STATE:format(eca[1], #hex))
        end
    else
        name = eca[1]
    end
    local ui
    if state then
        ui = state.ui[type_key[type]][name]
        if not ui then
            error(lang.script.WTG_UI_NOT_FOUND:format(name))
        end
    end
    if child_id then
        pack('llzl', type_map[type], child_id, name, enable)
    else
        pack('lzl', type_map[type], name, enable)
    end
    pack_args(ui, eca)
    pack_list(eca)
end

local function pack_trigger(trg)
    pack('zzl'
        , trg.name
        , trg.des
        , trg.type
    )
    if wtg.format_version then
        pack('L', trg.id)
    end
    pack('lllll'
        , trg.enable
        , trg.wct
        , trg.close
        , trg.run
        , trg.category
    )
    pack_list(trg.trg, true)
end

local function pack_triggers()
    pack('l', #wtg.triggers)
    for i = 1, #wtg.triggers do
        pack_trigger(wtg.triggers[i], i)
    end
end

local function pack_category_in_element(cat)
    pack('llzllL'
        , 4
        , cat.id
        , cat.name
        , cat.comment
        , 1
        , cat.category
    )
end

local function pack_var_in_element(var)
    pack('LLzL'
        , 64
        , var.id
        , var[1]
        , var.category
    )
end

local function pack_trigger_in_element(trg)
    if trg.type == 0 then
        pack('L', 8)
    elseif trg.wct == 1 then
        pack('L', 32)
    else
        pack('L', 16)
    end
    pack_trigger(trg)
end

local function pack_elements()
    pack('Lllzlll'
        , 1 + #wtg.objs
        , wtg.unknown7
        , wtg.unknown8
        , w2l.slk and w2l.slk.w3i[lang.w3i.MAP][lang.w3i.MAP_NAME] or 'Unknown'
        , wtg.unknown9
        , wtg.unknown10
        , wtg.unknown11
    )
    for _, obj in ipairs(wtg.objs) do
        if obj.obj == 'category' then
            pack_category_in_element(obj)
        elseif obj.obj == 'var' then
            pack_var_in_element(obj)
        elseif obj.obj == 'trigger' then
            pack_trigger_in_element(obj)
        end
    end
end

return function (w2l_, wtg_, wts_)
    w2l = w2l_
    wtg = wtg_
    wts = wts_
    state = w2l:frontend_trg()
    hex = {}

    pack_head()
    if wtg.format_version then
        pack_counts()
        pack_vars()
        pack_elements()
    else
        pack_category()
        pack_vars()
        pack_triggers()
    end

    return table.concat(hex)
end
