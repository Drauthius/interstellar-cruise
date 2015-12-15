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

local anim8 = require("lib.anim8")
local class = require("lib.middleclass")
local config = require("gameconfig")
local cron = require("lib.cron")
require("lib.math")

local Room = require("src.room")

local Person = class("Person")

Person.static.spriteSheet = love.graphics.newImage("gfx/people.png")
Person.static.spriteGrid = anim8.newGrid(16, 16, Person.spriteSheet:getWidth(), Person.spriteSheet:getHeight(), -2, -2, 4)
Person.static.iconSheet = love.graphics.newImage("gfx/icons.png")
Person.static.iconQuads = {
	uncleanliness = love.graphics.newQuad(0, 0, 16, 15, Person.iconSheet:getDimensions()),
	--hunger = love.graphics.newQuad(0, 17, 16, 15, Person.iconSheet:getDimensions()),
	hunger = love.graphics.newQuad(0, 80, 16, 15, Person.iconSheet:getDimensions()),
	boredom = love.graphics.newQuad(0, 33, 16, 15, Person.iconSheet:getDimensions()),
	--sleepiness = love.graphics.newQuad(0, 49, 16, 15, Person.iconSheet:getDimensions())
	sleepiness = love.graphics.newQuad(0, 64, 16, 15, Person.iconSheet:getDimensions())
}

local function _statToRoom(stat)
	if stat == "boredom" then
		return Room.ENTERTAINMENT
	elseif stat == "sleepiness" then
		return Room.LIVING_QUARTERS
	elseif stat == "hunger" then
		return Room.RESTAURANT
	elseif stat == "uncleanliness" then
		return Room.HYGIENE
	end
end

function Person:initialize(map, x, y)
	self.map = map
	self.x, self.y = x, y

	local sprite = love.math.random(1, 23) -- 24 is bugged, lol
	local row, columns
	if sprite % 2 ~= 0 then
		row = math.floor(sprite / 2) + 1
		columns = {
			'1-3',
			'7-9',
			'13-15'
		}
	else
		row = sprite / 2 + 1
		columns = {
			'4-6',
			'10-12',
			'16-18'
		}
	end

	self.animations = {
		down = anim8.newAnimation(Person.spriteGrid(columns[1], row), config.WALKING_ANIMATION_SPEED),
		up = anim8.newAnimation(Person.spriteGrid(columns[2], row), config.WALKING_ANIMATION_SPEED),
		side = anim8.newAnimation(Person.spriteGrid(columns[3], row), config.WALKING_ANIMATION_SPEED)
	}
	self.currentAnimation = self.animations.down
	self.currentAnimation:pause()

	self.stats = {
		boredom = love.math.random(unpack(config.STARTING_STATS.boredom)),
		sleepiness = love.math.random(unpack(config.STARTING_STATS.sleepiness)),
		hunger = love.math.random(unpack(config.STARTING_STATS.hunger)),
		uncleanliness = love.math.random(unpack(config.STARTING_STATS.uncleanliness))
	}
	self.happiness = love.math.random(config.STARTING_HAPPINESS_MIN, config.STARTING_HAPPINESS_MAX)

	self:doSomething()
end

function Person:collectMoney()
	if self.happiness > config.PAY_WHEN_HAPPINESS_IS_ABOVE then
		return config.UPKEEP_GAIN_PER_PERSON
	else
		return 0
	end
end

function Person:doSomething()
	if self.facilitating then
		--print("I am currently fighting "..self.facilitating)
		if self.stats[self.facilitating] < love.math.random(config.LEAVE_ROOM_WHEN_STAT_REACHES_MIN, config.LEAVE_ROOM_WHEN_STAT_REACHES_MAX) then
			--print("I fought off "..self.facilitating)
			self.targetRoom:release()
			self.targetRoom = nil
			self.facilitating = nil
			self.highestNeed = nil
		end
	elseif not self.target or self.targetReason == "wander" then
		-- Check if we're bummed.
		if self.happiness < config.LEAVE_WHEN_HAPPINESS_IS_BELOW then
			--print("Fuck this space station.")
			self:leave()
		end

		-- Fulfil a need.
		local highestStat, highestStatValue = nil, 0
		for stat,value in pairs(self.stats) do
			if value > highestStatValue then
				highestStat = stat
				highestStatValue = value
			end
		end
		if highestStatValue > love.math.random(config.ENTER_ROOM_WHEN_STAT_REACHES_MIN, config.ENTER_ROOM_WHEN_STAT_REACHES_MAX) then
			self.highestNeed = highestStat
			--print("I have "..highestStat)
			local room = self.map:findClosestRoom(self.x, self.y, _statToRoom(highestStat))
			if room then
				if self.target then
					self:stop()
				end
				self.target = self.map:randomWalkableGridInRoom(room)
				self.targetRoom = room
				self.targetReason = highestStat
			end
		end

		-- Wander
		if not self.target then
			local i, j = self.map:worldToGridCoords(self.x, self.y)
			self.target = self.map:randomWalkableGrid(i, j, 5, 5)
			self.targetReason = "wander"
		end
	end

	self.clock = cron.after(love.math.random() * 2 + 1, self.doSomething, self)
	self.blinkingTimer = cron.every(config.BLINKING_ICON_SPEED, function()
		if self.facilitating then
			self.iconBlinking = not self.iconBlinking
		else
			self.iconBlinking = false
		end
	end)
end

function Person:stop()
	local newTarget, newReason

	-- Did we have a purpose?
	if self.targetReason and self.targetReason ~= "wander" then
		if self.targetRoom:useRoom() then
			if self.targetReason == "leave" then
				self.left = true
			else
				self.facilitating = self.targetReason
			end
		else
			local room = self.map:findRandomRoom(_statToRoom(self.targetReason), { self.targetRoom })
			if room then
				--print("Room full. Trying another")
				newTarget = self.map:randomWalkableGridInRoom(room)
				newReason = self.targetReason
				self.targetRoom = room
			else
				--print("Room full, but no other")
				self.targetRoom = nil
			end
		end
	end

	self.target = newTarget
	self.targetReason = newReason
	self.path = nil
	self.pathLocation = nil
	self.currentAnimation:pause()
	self.currentAnimation:gotoFrame(1)
end

function Person:leave()
	local room = self.map:findClosestRoom(self.x, self.y, Room.SPAWN)
	assert(room, "Nowhere to go. :(")

	if self.targetRoom then
		self.targetRoom:release()
		self.targetRoom = nil
	end
	self.facilitating = nil

	if self.target then
		self.targetReason = nil
		self:stop()
	end
	self.target = self.map:randomWalkableGridInRoom(room)
	self.targetRoom = room
	self.targetReason = "leave"
end

function Person:hasLeft()
	return self.left == true
end

function Person:update(dt)
	if self.left then
		return
	end

	if self.facilitating then
		self.stats[self.facilitating] = math.max(self.stats[self.facilitating] - config.STAT_DECREASE[self.facilitating] * dt, 0)
	end

	local highestStat = -1
	for stat,value in pairs(self.stats) do
		value = math.min(value + config.STAT_INCREASE[stat] * dt, config.STAT_MAX)
		if value > highestStat then
			highestStat = value
		end
		self.stats[stat] = value
	end

	if highestStat > config.HAPPINESS_DECREASE_THRESHOLD then
		self.happiness = math.max(self.happiness - config.HAPPINESS_DECREASE_RATE * dt, 0)
	elseif highestStat < config.HAPPINESS_INCREASE_THRESHOLD then
		self.happiness = math.min(self.happiness + config.HAPPINESS_INCREASE_RATE * dt, config.STAT_MAX)
	end

	self.currentAnimation:update(dt)

	if self.target then
		if not self.path then
			self.path = self.map:getPath(self.map:getGrid(self.map:worldToGridCoords(self.x, self.y)), self.target)
			self.pathLocation = 1
		end

		local currentGrid = self.map:getGrid(self.map:worldToGridCoords(self.x + 0.2, self.y + 0.2)) -- damn rounding
		if self.path[self.pathLocation] == currentGrid then
			self.pathLocation = self.pathLocation + 1
		end

		local nextGrid = self.path[self.pathLocation]

		if self.target == currentGrid or not nextGrid then
			self:stop()
		else
			local tx, ty = self.map:gridToWorldCoords(nextGrid.i, nextGrid.j)
			local dx, dy = tx - self.x, ty - self.y
			local len = math.sqrt(dx ^ 2 + dy ^ 2)
			dx, dy = dx / len, dy / len

			local direction = math.deg(math.atan2(dx, dy)) % 360
			if direction >= 330 or direction <= 30 then
				self.currentAnimation = self.animations.down
				self.currentAnimation:resume()
			elseif direction >= 150 and direction <= 210 then
				self.currentAnimation = self.animations.up
				self.currentAnimation:resume()
			elseif direction >= 30 and direction <= 170 then
				self.currentAnimation = self.animations.side
				self.currentAnimation:resume()
				if not self.currentAnimation.flippedH then
					self.currentAnimation:flipH()
				end
			elseif direction >= 210 and direction <= 330 then
				self.currentAnimation = self.animations.side
				self.currentAnimation:resume()
				if self.currentAnimation.flippedH then
					self.currentAnimation:flipH()
				end
			end

			local speed = config.WALKING_SPEED * dt
			self.x = self.x + dx * speed
			self.y = self.y + dy * speed

			if debug then
				love.graphics.setColor(255, 255, 255, 255)
				love.graphics.line(self.x, self.y, tx, ty)
			end
		end
	end

	self.clock:update(dt)
	self.blinkingTimer:update(dt)
end

function Person:draw()
	if self.left then
		return
	end

	local icon = Person.iconQuads[self.highestNeed]
	if icon and not self.iconBlinking then
		love.graphics.draw(Person.iconSheet, icon, self.x, self.y - 15)
	end

	self.currentAnimation:draw(Person.spriteSheet, self.x, self.y)

	if self.happiness <= config.PAY_WHEN_HAPPINESS_IS_ABOVE then
		love.graphics.setColor(255, 0, 0, 220)
		self.currentAnimation:draw(Person.spriteSheet, self.x, self.y)
		love.graphics.setColor(255, 255, 255, 255)
	end
end

return Person
