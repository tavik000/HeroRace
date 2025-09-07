local setmetatable = setmetatable
local ipairs = ipairs
local tbl_remove = table.remove

local trg = {}
trg.__index = trg
trg.type = 'trigger'
trg._enable = true
trg._removed = false

function trg:disable()
	self._enable = false
end

function trg:enable()
	self._enable = true
end

function trg:is_enable()
	return self._enable
end

function trg:__call(...)
	if self._removed or not self._enable then
		return
	end
    return self[1](...)
end

function trg:remove()
	if self._removed then
		return
	end	
    local event = self[2]
    self._removed = true
	self[1] = nil
	self[2] = nil
    if not event.clean then
        event.clean = {}
    end
    event.clean[self] = true
end

local _onces = {}
local _events = {}
local ev = {}

function ev.emit(name, ...)
	local event = _events[name]
	if not event then
		return
    end
    local res
    event.lock = (event.lock or 0) + 1
	for i = 1, #event do
		res = event[i](...)
        if res ~= nil then
			break
		end
	end
    event.lock = event.lock - 1
    if event.lock == 0 and event.clean then
        for i, trg in ipairs(event) do
            if event.clean[trg] then
                tbl_remove(event, i)
                break
            end
        end
        event.clean = nil
    end
    return res
end

function ev.emit_once(name, ...)
    if _onces[name] then
        return
    end
    _onces[name] = true
    return ev.emit(name, ...)
end

function ev.on(name, f)
	local event = _events[name]
	if not event then
		event = {}
		_events[name] = event
	end
	local t = { f, event }
	event[#event+1] = t
	return setmetatable(t, trg)
end

return ev
