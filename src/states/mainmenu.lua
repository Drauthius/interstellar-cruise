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

local config = require("gameconfig")
local Game = require("src.states.game")

local MainMenu = State:subclass("MainMenu")
MainMenu.static.music = love.audio.newSource(config.MENU_MUSIC)
MainMenu.static.musicLoop = love.audio.newSource(config.MENU_MUSIC_LOOP)

function MainMenu:initialize()
	self.mainMenu = {
		image = love.graphics.newImage("gfx/mainmenu.png"),
		x = 150,
		y = 290
	}
	self.logo = love.graphics.newImage("gfx/logo.png")

	MainMenu.music:setVolume(config.MENU_MUSIC_VOLUME)
	MainMenu.musicLoop:setVolume(config.MENU_MUSIC_VOLUME)
	MainMenu.musicLoop:setLooping(true)
end

function MainMenu:onEnter()
	MainMenu.music:play()
	MainMenu.musicLoop:stop()
end

function MainMenu:onLeave()
	MainMenu.music:stop()
	MainMenu.musicLoop:stop()
end

function MainMenu:update(dt)
	if MainMenu.music:isPaused() then
		MainMenu.musicLoop:play()
	end
end

function MainMenu:draw()
	love.graphics.draw(Game.background)
	if self:getStateManager():getForegroundState() == self then
		love.graphics.draw(self.logo, 40, 40)
		love.graphics.draw(self.mainMenu.image, self.mainMenu.x, self.mainMenu.y)
	end
end

function MainMenu:mouseMoved() end

function MainMenu:mousePressed(x, y, button)
	if button == "l" then
		if x > self.mainMenu.x and x < self.mainMenu.x + self.mainMenu.image:getWidth() then
			if y > self.mainMenu.y and y < self.mainMenu.y + 24 then
				self:getStateManager():enterState("Info")
			elseif y > self.mainMenu.y + 30 and y < self.mainMenu.y + 54 then
				love.event.quit()
			end
		end
	end
end

return MainMenu
