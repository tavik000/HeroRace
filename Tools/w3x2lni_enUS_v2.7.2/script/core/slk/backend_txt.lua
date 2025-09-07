local w3xparser = require 'w3xparser'
local lang = require 'lang'
local convertreal = require 'convertreal'

local table_concat = table.concat
local ipairs = ipairs
local string_char = string.char
local pairs = pairs
local table_sort = table.sort
local table_insert = table.insert
local math_floor = math.floor
local select = select
local table_unpack = table.unpack
local os_clock = os.clock
local type = type
local next = next

local report
local w2l
local metadata
local keys
local remove_unuse_object
local object

local function to_type(tp, value, reforge)
    if tp == 0 then
        if not value then
            return nil
        end
        local value = tostring(math_floor(value))
        if value == '0' then
            return reforge and 0 or nil
        end
        return value
    elseif tp == 1 or tp == 2 then
        if not value then
            return nil
        end
        if type(value) == 'number' then
            value = convertreal(value)
        end
        if value:find('.', 1, true) then
            value = value:gsub('0+$', '')
        end
        value = value:gsub('%.$', '')
        if value == '' then
            return nil
        end
        if value == '0' then
            return reforge and 0 or nil
        end
        return value
    elseif tp == 3 then
        if not value then
            return
        end
        if tostring(value):find(',', nil, false) then
            value = '"' .. value .. '"'
        end
        return value
    end
end

local function get_index_data(tp, l, n)
    local null
    for i = n, 1, -1 do
        local v = to_type(tp, l[i])
        if v and v ~= '' then
            l[i] = v
            null = ''
        else
            l[i] = null
        end
    end
    if #l == 0 then
        return
    end
    if tp == 3 then
        for i = #l, 2, -1 do
            if l[i] == l[i-1] then
                l[i] = nil
            else
                break
            end
        end
    end
    return table_concat(l, ',')
end

local function add_data(obj, meta, value, keyval)
    local key = meta.field
    if meta.index then
        -- TODO: 有点奇怪的写法
        if meta.index == 1 then
            local value = get_index_data(meta.type, {obj[meta.key..'_1'], obj[meta.key..'_2']}, 2)
            if not value then
                if meta.cantempty and not meta.reforge then
                    value = ','
                else
                    return
                end
            end
            keyval[#keyval+1] = {key:sub(1,-3), value}
        end
        return
    end
    if meta.appendindex then
        if type(value) == 'table' then
            local len = 0
            for n in pairs(value) do
                if n > len then
                    len = n
                end
            end
            if len == 0 then
                return
            end
            if len > 1 then
                keyval[#keyval+1] = {key..'count', len}
            end
            local flag
            for i = 1, len do
                local key = key
                if i > 1 then
                    key = key .. (i-1)
                end
                if value[i] and value[i] ~= '' then
                    flag = true
                    if meta.concat then
                        keyval[#keyval+1] = {key, value[i]}
                    else
                        keyval[#keyval+1] = {key, to_type(meta.type, value[i])}
                    end
                end
            end
            if not flag and len > 1 then
                keyval[#keyval] = nil
            end
        else
            if not value then
                return
            end
            if meta.concat then
                keyval[#keyval+1] = {key, value}
            else
                keyval[#keyval+1] = {key, to_type(meta.type, value)}
            end
        end
        return
    end
    if meta.concat then
        if value and value ~= 0 then
            keyval[#keyval+1] = {key, value}
        end
        return
    end
    if type(value) == 'table' then
        if #value == 0 then
            return
        end
        value = get_index_data(meta.type, value, #value)
    else
        value = to_type(meta.type, value, meta.reforge)
    end
    if not value or value == '' then
        if meta.cantempty and not meta.reforge then
            value = ','
        else
            return
        end
    end
    if value then
        keyval[#keyval+1] = {key, value}
    end
end

local function add_extra_data(keyval, key, data)
    local len = 0
    for k in pairs(data) do
        if k > len then
            len = k
        end
    end
    if len == 0 then
        return
    end
    keyval[#keyval+1] = {key, get_index_data(3, data, len)}
end

local function sortpairs(tbl)
    local keys = {}
    for k in pairs(tbl) do
        keys[#keys+1] = k
    end
    table.sort(keys)
    local i = 0
    return function ()
        i = i + 1
        local k = keys[i]
        return k, tbl[k]
    end
end

local function create_keyval(obj, txt_obj)
    local keyval = {}
    for _, key in ipairs(keys) do
        if key ~= 'editorsuffix'
        and key ~= 'editorname' then
            add_data(obj, metadata[key], obj[key], keyval)
        end
    end
    if txt_obj then
        for k, v in sortpairs(txt_obj) do
            if k:sub(1, 1) ~= '_' then
                add_extra_data(keyval, k, v)
            end
        end
    end
    return keyval
end

local function stringify_obj(str, obj, txt_obj)
    local keyval = create_keyval(obj, txt_obj)
    if #keyval == 0 then
        return
    end
    table_sort(keyval, function(a, b)
        return a[1]:lower() < b[1]:lower()
    end)
    local empty = true
    str[#str+1] = ('[%s]'):format(obj._slk_id or obj._id)
    for _, kv in ipairs(keyval) do
        local key, val = kv[1], kv[2]
        if val ~= '' then
            if type(val) == 'string' then
                val = val:gsub('\r\n', '|n'):gsub('[\r\n]', '|n')
            end
            str[#str+1] = key .. '=' .. val
            empty = false
        end
    end
    if empty then
        str[#str] = nil
    else
        str[#str+1] = ''
    end
end

local function report_failed(obj, key, tip, info)
    report.n = report.n + 1
    if not report[tip] then
        report[tip] = {}
    end
    if report[tip][obj._id] then
        return
    end
    local type, id, name = w2l:get_displayname(obj)
    report[tip][obj._id] = {
        ("%s %s %s"):format(type, id, name),
        ("%s %s"):format(key, info),
    }
end

local function check_string(s)
    return type(s) == 'string' and s:find(',', nil, false) and s:find('"', nil, false)
end

local function is_same(a, b)
    local tp1 = type(a)
    local tp2 = type(b)
    if tp1 ~= tp2 then
        return false
    end
    if tp1 == 'table' then
        local used = {}
        for k, v in pairs(a) do
            if not is_same(v, b[k]) then
                return false
            end
            used[k] = true
        end
        for k in pairs(b) do
            if not used[k] then
                return false
            end
        end
        return true
    else
        return a == b
    end
end

local function prebuild_data(obj, key, r)
    if not obj[key] then
        return
    end
    local name = obj._id
    local meta = metadata[key]
    if meta.reforge then
        if is_same(obj[key], obj[meta.reforge]) then
            return
        end
    end
    if type(obj[key]) == 'table' then
        object[name][key] = {}
        local t = {}
        for k, v in pairs(obj[key]) do
            if check_string(v) then
                report_failed(obj, meta.field, lang.report.TEXT_CANT_ESCAPE_IN_TXT, v)
                object[name][key][k] = v
            else
                t[k] = v
            end
        end
        if not next(object[name][key]) then
            object[name][key] = nil
        end
        r[key] = t
    else
        if check_string(obj[key]) then
            report_failed(obj, meta.field, lang.report.TEXT_CANT_ESCAPE_IN_TXT, obj[key])
            object[name][key] = obj[key]
        else
            r[key] = obj[key]
        end
    end
end

local function prebuild_obj(name, obj)
    if remove_unuse_object and not obj._mark then
        return
    end
    if obj._keep_obj then
        return
    end
    local r = {}
    for _, key in ipairs(keys) do
        prebuild_data(obj, key, r)
    end
    if next(r) then
        r._id = obj._id
        r._slk_id = obj._slk_id
        return r
    end
end

local function prebuild_merge(obj, a, b)
    if a._type ~= b._type then
        local tp1, _, name1 = w2l:get_displayname(a)
        local tp2, _, name2 = w2l:get_displayname(b)
        w2l.messager.report(lang.report.WARN, 2, (lang.report.OBJECT_ID_CONFLICT):format(obj._id), ('[%s]%s --> [%s]%s'):format(tp1, name1, tp2, name2))
    end
    for k, v in pairs(b) do
        if k == '_id' or k == '_type' or k == '_slk_id' then
            goto CONTINUE
        end
        local id = b._id
        if type(v) == 'table' then
            if type(a[k]) == 'table' then
                for i, iv in pairs(v) do
                    if a[k][i] ~= iv then
                        report_failed(obj, metadata[k].field, lang.report.TXT_CONFLICT, '--> ' .. a._id)
                        if object[id][k] then
                            object[id][k][i] = iv
                        else
                            object[id][k] = {[i] = iv}
                        end
                    end
                end
            else
                report_failed(obj, metadata[k].field, lang.report.TXT_CONFLICT, '--> ' .. a._id)
                for i, iv in pairs(v) do
                    if object[id][k] then
                        object[id][k][i] = iv
                    else
                        object[id][k] = {[i] = iv}
                    end
                end
            end
        else
            if a[k] ~= v then
                report_failed(obj, metadata[k].field, lang.report.TXT_CONFLICT, '--> ' .. a._id)
                object[id][k] = v
            end
        end
        ::CONTINUE::
    end
end

local function prebuild(type, input, output, list)
    for name, obj in sortpairs(input) do
        local r = prebuild_obj(name, obj)
        if r then
            r._type = type
            name = name:lower()
            if output[name] then
                prebuild_merge(obj, output[name], r)
            else
                output[name] = r
                list[#list+1] = r._id
            end
        end
    end
end

local function update_constant(type)
    metadata = w2l:metadata()[type]
    keys = w2l:keydata()[type] or {}
end

return function(w2l_, slk, report_, obj)
    w2l = w2l_
    report = report_
    remove_unuse_object = w2l.setting.remove_unuse_object
    local txt = {}
    local list = {}
    local type_list = {'ability', 'buff', 'unit', 'item', 'upgrade'}
    if w2l.setting.slk_doodad then
        type_list[#type_list+1] = 'doodad'
        type_list[#type_list+1] = 'destructable'
    end
    for _, type in ipairs(type_list) do
        list[type] = {}
        object = obj[type]
        update_constant(type)
        if slk[type] then
            prebuild(type, slk[type], txt, list[type])
        end
    end
    local r = {}
    for _, type in ipairs(type_list) do
        update_constant(type)
        local str = {}
        table_sort(list[type])
        for _, name in ipairs(list[type]) do
            local lname = name:lower()
            stringify_obj(str, txt[lname], slk['txt'][lname])
        end
        r[type] = table_concat(str, '\r\n')
    end
    return r
end
