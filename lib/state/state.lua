local class = require("lib.middleclass")

local State = class("State")

function State:setManager(mgr)
	self._stateManager = mgr
end

function State:getStateManager()
	return self._stateManager
end

function State:onEnter(...) end

function State:onLeave() end

function State:update(dt) end

function State:draw() end

return State
