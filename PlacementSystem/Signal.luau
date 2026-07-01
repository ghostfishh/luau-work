--!strict
-- A lightweight Signal implementation for the placement system API
local Signal = {}
Signal.__index = Signal

type Connection = {
	Disconnect: (Connection) -> (),
	_handler: (...any) -> (),
	_signal: any,
}

function Signal.new()
	local self = setmetatable({}, Signal)
	self._handlers = {}
	return self
end

function Signal:Connect(handler: (...any) -> ()): Connection
	local connection = {
		_handler = handler,
		_signal = self,
		Disconnect = function(conn)
			for i, h in ipairs(self._handlers) do
				if h == conn._handler then
					table.remove(self._handlers, i)
					break
				end
			end
		end,
	}
	table.insert(self._handlers, handler)
	return connection
end

function Signal:Fire(...: any)
	local args = {...}
	for i = #self._handlers, 1, -1 do
		local handler = self._handlers[i]
		if handler then
			task.spawn(handler, unpack(args))
		end
	end
end

function Signal:Destroy()
	self._handlers = {}
end

return Signal
