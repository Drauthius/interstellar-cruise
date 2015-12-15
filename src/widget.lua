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

local class = require("lib.middleclass")

local Widget = class("Widget")

Widget.static.background = love.graphics.newImage("gfx/buildbutton.png")
Widget.static.coin = love.graphics.newImage("gfx/coin.png")

function Widget:initialize(image, cost, x, y, ox, oy)
	self.image = image
	self.cost = cost
	self.font = love.graphics.newFont("ttf/pixel font-7.ttf", 14)
	self.x = x
	self.y = y
	self.w, self.h = Widget.background:getDimensions()
	self.ox = ox or 0
	self.oy = oy or self.ox
end

function Widget:wasClicked(x, y)
	return x >= self.x - self.ox and x <= self.x + self.w + self.ox and
	       y >= self.y - self.oy and y <= self.y + self.h + self.oy
end

function Widget:draw()
	love.graphics.draw(Widget.background, self.x, self.y)
	love.graphics.draw(self.image, self.x + 2, self.y + 4 + ((48 - self.image:getHeight()) / 2))
	local y = self.y + self.h - self.font:getHeight() - 2
	love.graphics.draw(Widget.coin, self.x + 3, y + 1, 0, 0.8)
	love.graphics.setFont(self.font)
	love.graphics.printf(self.cost, self.x + 4, y, self.w, "center")

	if debug then
		love.graphics.rectangle("line", self.x - self.ox, self.y - self.oy, self.w + self.ox, self.h + self.oy)
	end
end

return Widget
