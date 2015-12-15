--[[
-- State manager for handling multiple states.
--]]

require("lib.table")
local bitop = require("lib.bitop")
local class = require("lib.middleclass")

local State = require("lib.state.state")
local StateManager = class("StateManager")

--[[
-- Find a state by name.
-- \returns The state class and a number for the bitmask.
--]]
local function findState(states, name)
	for k,v in ipairs(states) do
		if v.class.name == name then
			return v, 2^(k-1)
		end
	end
	assert(false, "Could not find state named "..name)
end

--[[
-- Initiates a state manager with the supplied states.
-- Order is important when using update() or draw().
--]]
function StateManager:initialize(...)
	local arg = { ... }
	local len = #arg
	-- Validate
	for i=1,len do
		local state = arg[i]
		assert(type(state) == "table" and state:isInstanceOf(State), "Only accepts subclasses of State, but got "..tostring(state))
		state:setManager(self)

		for j=i+1,len do
			assert(state.class.name ~= arg[j].class.name, "Duplicate class name found")
		end
	end

	self.states = arg
	self.statesMask = 0
end

--[[
-- Instructs the draw function to reverse the order. This is typically set
-- since in 2D the background is drawn first.
--]]
function StateManager:reverseDrawOrder(reverse)
	self.reverse = reverse
end

--[[
-- Checks whether the given state is active (has been entered and not left).
-- \param name The name of the state.
-- \return True if the given state is active, false otherwise.
--]]
function StateManager:isStateActive(name)
	local state, bit = findState(self.states, name)

	if state and bit and bitop.band(self.statesMask, bit) ~= 0 then
		return true
	else
		return false
	end
end

--[[
-- Get a state instance by name.
-- \param name The name of the state to retrieve.
-- \returns A state instance and a boolean indicating whether the state is
-- currently active, or throws an error if no such state was found.
--]]
function StateManager:getState(name)
	local state, bit = findState(self.states, name)
	local active = bitop.band(self.statesMask, bit) ~= 0

	return state, active
end

--[[
-- Function to return the "foreground" state, which is defined as the first
-- active state in the order given during initialization.
-- \returns The first active state, or nil if none.
--]]
function StateManager:getForegroundState()
	local bits = bitop.tobits(self.statesMask)
	for i,v in ipairs(bits) do
		if v == 1 then
			return self.states[i]
		end
	end
	return nil
end

--[[
-- Enter the specified state, without leaving a state.
-- Will trigger an onEnter if the state is not already active.
-- \param state The name of the state to enter.
-- \param ... Arguments to give to the state, if entering.
--]]
function StateManager:enterState(name, ...)
	local state, bit = findState(self.states, name)

	if not state or not bit or bitop.band(self.statesMask, bit) ~= 0 then
		return
	end

	self.statesMask = bitop.bor(self.statesMask, bit)
	state:onEnter(...)
end

--[[
-- Leave the specified state, without entering a state.
-- Will trigger an onLeave if the state is active.
-- \param state The name of the state to enter.
--]]
function StateManager:leaveState(name)
	local state, bit = findState(self.states, name)

	if not state or not bit or bitop.band(self.statesMask, bit) == 0 then
		return
	end

	self.statesMask = bitop.band(self.statesMask, bitop.bnot(bit))
	state:onLeave()
end

--[[
-- Enter to the specified state, after leaving all current active states.
-- Will trigger an onLeave for all active states, and an onEnter on the
-- specified state. Will not trigger any events on the specified state if it is
-- already active.
-- \param state The name of the state to enter.
-- \param ... Arguments to give to the state, if entering.
--]]
function StateManager:switchState(name, ...)
	local enterState = nil
	local bit

	local bits = bitop.tobits(self.statesMask)
	for i,v in ipairs(bits) do
		local state = self.states[i]

		if state.class.name == name then
			if v == 0 then
				enterState = state
			end
			bit = 2^(i-1)
		elseif v == 1 then
			state:onLeave()
		end
	end

	-- The table was cut short (truncated)
	if bit == nil then
		enterState, bit = findState(self.states, name)
	end

	self.statesMask = bit

	if enterState ~= nil then
		enterState:onEnter(...)
	end
end

--[[
-- Call the update() function of all active states.
--]]
function StateManager:update(dt)
	local bits = bitop.tobits(self.statesMask)
	for i,v in ipairs(bits) do
		if v == 1 then
			self.states[i]:update(dt)
		end
	end
end


--[[
-- Call the draw() function of all active states.
--]]
function StateManager:draw()
	local bits = bitop.tobits(self.statesMask)
	if not self.reverse then
		for i,v in ipairs(bits) do
			if v == 1 then
				self.states[i]:draw()
			end
		end
	else
		for i=#bits,1,-1 do
			if bits[i] == 1 then
				self.states[i]:draw()
			end
		end
	end
end

return StateManager
