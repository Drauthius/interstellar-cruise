--[[
Copyright (C) 2015  Albert Diserholt

This file is part of Interstellar Cruise.

Interstellar Cruise is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Interstellar Cruise is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Interstellar Cruise.  If not, see <http://www.gnu.org/licenses/>.
--]]

-- Globals
debug = false

-- Classes
local StateManager = require("lib.state.manager")
local MainMenu = require("src.states.mainmenu")
local Info = require("src.states.info")
local Game = require("src.states.game")

-- Objects
local statemgr
local control

function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")

	statemgr = StateManager:new(
		Info:new(),
		MainMenu:new(),
		Game:new())
	statemgr:enterState("MainMenu")
	statemgr:reverseDrawOrder(true)
end

function love.update(dt)
	statemgr:update(dt)
end

function love.draw()
	statemgr:draw()
end

function love.keypressed(key)
	if key == "rctrl" then
		debug = not debug
	end
end

function love.mousemoved(x, y, dx, dy)
	statemgr:getForegroundState():mouseMoved(x, y)
end

function love.mousepressed(x, y, button)
	statemgr:getForegroundState():mousePressed(x, y, button)
end
