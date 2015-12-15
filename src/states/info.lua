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

local State = require("lib.state.state")

local Info = State:subclass("Info")

function Info:initialize()
	self.headerFont = love.graphics.newFont("ttf/spleen machine.ttf", 18)
	self.bodyFont = love.graphics.newFont("ttf/FreePixel.ttf", 16)

	self.howtoPlay = [[You are to build a space station to meet the needs of visitors who are beamed onto your vessel. Order various kinds of facilities to acquire random shaped parts to accommodate your guests; please them and they will keep paying the citizen tax - fail and face the consequences of bankruptcy. Citizens have needs: hygiene, sleep, hunger and entertainment. If one or more of their needs are not met their happiness level will decrease. When their happiness is low, they will go red, signifying their displeasure with your provided services, and may leave the vessel soon.]]
	self.plot = [[In the distant future where automated production and robotics has made human labour redundant, the biggest problems are boredom and personal well-being. You, a relatively young supercomputer (about 1.2 picoseconds old), after having looked around the immediate vicinity in your solar system, you want to amuse yourself by building a new “Interstellar Cruise Vessel” for bored humans.]]
	self.instructions = [[Click the buttons to acquire the various room types, right mouse button rotates the piece 90 degrees, while left mouse button attaches the part to the already built station if the position is valid.]]
end

function Info:onEnter()
	self.timer = 0
end

function Info:update(dt)
	self.timer = self.timer + dt
end

function Info:draw()
	love.graphics.setFont(self.headerFont)
	love.graphics.print("Goal", 20, 50)
	love.graphics.print("Plot", 420, 50)
	love.graphics.printf("Instructions", 0, 410, love.window.getWidth(), "center")

	love.graphics.setFont(self.bodyFont)
	love.graphics.printf(self.howtoPlay, 20, 52 + self.headerFont:getHeight(), 400 - 20)
	love.graphics.printf(self.plot, 420, 52 + self.headerFont:getHeight(), love.window.getWidth() - 420 - 10)
	love.graphics.printf(self.instructions, 10, 412 + self.headerFont:getHeight(), love.window.getWidth() - 20, "center")

	love.graphics.setFont(self.headerFont)
	love.graphics.setColor(255, 255, 255, (math.sin(2 * self.timer) * 0.5 + 0.5) * 255)
	love.graphics.printf("Click to continue", 0, love.window.getHeight() - self.headerFont:getHeight() - 10, love.window.getWidth(), "center")
	love.graphics.setColor(255, 255, 255, 255)
end

function Info:mouseMoved() end

function Info:mousePressed(x, y, button)
	if button == "l" then
		self:getStateManager():switchState("Game")
	end
end

return Info
