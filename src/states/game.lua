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

local config = require("gameconfig")
local cron = require("lib.cron")
local gamera = require("lib.gamera")
local State = require("lib.state.state")

local Room = require("src.room")
local Person = require("src.person")
local Map = require("src.map")
local Widget = require("src.widget")

local Game = State:subclass("Game")

Game.static.background = love.graphics.newImage("gfx/spacebg1.png")
Game.static.stars = {
	--love.graphics.newImage("gfx/rymdtransp1.png"),
	love.graphics.newImage("gfx/rymdtransp2.png"),
	love.graphics.newImage("gfx/rymdtransp3.png"),
	love.graphics.newImage("gfx/rymdtransp4.png")
}
Game.static.buildMenuImages = {
	livingQuarters = love.graphics.newImage("gfx/buildLivingQuarters.png"),
	hygiene = love.graphics.newImage("gfx/buildHygiene.png"),
	restaurant = love.graphics.newImage("gfx/buildRestaurant.png"),
	entertainment = love.graphics.newImage("gfx/buildEntertainment.png"),
	corridor = love.graphics.newImage("gfx/corridor.png"),
	bend = love.graphics.newImage("gfx/bend.png"),
	threeway = love.graphics.newImage("gfx/3xcross.png"),
	fourway = love.graphics.newImage("gfx/4xcross.png")
}
Game.static.music = love.audio.newSource(config.GAME_MUSIC, "stream")

local function _loadAudio(sfx)
	local ret = {}
	for _,audio in ipairs(sfx) do
		table.insert(ret, love.audio.newSource(audio, "static"))
	end
	if #ret < 1 then
		return nil
	else
		return ret
	end
end

local function _playRandom(audio)
	if audio then
		local i = love.math.random(#audio)
		if audio[i]:isPlaying() then
			audio[i]:rewind()
		else
			audio[i]:play()
		end
	end
end

function Game:initialize()
	Game.music:setLooping(true)
	Game.music:setVolume(config.GAME_MUSIC_VOLUME)

	self.bodyFont = love.graphics.newFont("ttf/pixel font-7.ttf", 16)
	self.gameOverFont = love.graphics.newFont("ttf/pixel font-7.ttf", 26)
	self.moneyFont = love.graphics.newFont("ttf/pixel font-7.ttf", 32)

	config.MASS_EMIGRATION_THRESHOLD = config.MASS_EMIGRATION_THRESHOLD / 100 * config.STAT_MAX
end

function Game:onEnter()
	self.map = Map:new(math.floor(Game.background:getWidth() / Map.GRID_SIZE), math.floor(Game.background:getHeight() / Map.GRID_SIZE))

	self.stars = 1
	self.starsTimer = cron.every(0.5, function()
		self.stars = math.random(1, #Game.stars)
	end)

	self.spawner = Room:new(Room.SPAWN, math.floor(self.map.width / 2) * Map.GRID_SIZE, math.floor(self.map.height / 2) * Map.GRID_SIZE, "portalroom")
	self.map:addRoom(self.spawner)
	self.people = {}
	self:spawnPeople()
	self:spawnPeople()

	self.camera = gamera.new(0, 0, Game.background:getDimensions())
	self.camera:setPosition(self.spawner.x + self.spawner.image:getWidth() / 2, self.spawner.y + self.spawner.image:getHeight() / 2)
	self.backgroundOffsetX = config.BACKGROUND_SCALE * Game.background:getWidth() / 2
	self.backgroundOffsetY = config.BACKGROUND_SCALE * Game.background:getHeight() / 2
	self.backgroundCamera = gamera.new(-self.backgroundOffsetX, -self.backgroundOffsetY, Game.background:getWidth() + self.backgroundOffsetX, Game.background:getHeight() + self.backgroundOffsetY)

	local y = love.window.getHeight() - 30 - Widget.background:getHeight()
	local x = (love.window.getWidth() - 8 * (Widget.background:getWidth() + 10)) / 2
	self.buildLivingQuarter = Widget:new(Game.buildMenuImages.livingQuarters, config.BUILD_COST_LIVING_QUARTER, x, y)
	x = x + Widget.background:getWidth() + 10
	self.buildHygiene = Widget:new(Game.buildMenuImages.hygiene, config.BUILD_COST_HYGIENE, x, y)
	x = x + Widget.background:getWidth() + 10
	self.buildRestaurant = Widget:new(Game.buildMenuImages.restaurant, config.BUILD_COST_RESTAURANT, x, y)
	x = x + Widget.background:getWidth() + 10
	self.buildEntertainment = Widget:new(Game.buildMenuImages.entertainment, config.BUILD_COST_ENTERTAINMENT, x, y)
	x = x + Widget.background:getWidth() + 10
	self.buildCorridor = Widget:new(Game.buildMenuImages.corridor, config.BUILD_COST_CORRIDOR, x, y)
	x = x + Widget.background:getWidth() + 10
	self.buildBend = Widget:new(Game.buildMenuImages.bend, config.BUILD_COST_BEND, x, y)
	x = x + Widget.background:getWidth() + 10
	self.buildThreeWay = Widget:new(Game.buildMenuImages.threeway, config.BUILD_COST_THREE_WAY, x, y)
	x = x + Widget.background:getWidth() + 10
	self.buildFourWay = Widget:new(Game.buildMenuImages.fourway, config.BUILD_COST_FOUR_WAY, x, y)

	self.upkeepTimer = cron.every(config.UPKEEP_TIME, self.upkeep, self)
	self.numConnections = 0
	self.money = config.STARTING_BUDGET
	self.moneyDelta = 0

	self.buyStationAudio = _loadAudio(config.AUDIO_BUY_STATION_PART)
	self.rotateStationAudio = _loadAudio(config.AUDIO_ROTATE_STATION_PART)
	self.placeStationAudio = _loadAudio(config.AUDIO_CONNECT_STATION_PART)
	self.placeStationDelayAudio = _loadAudio(config.AUDIO_CONNECT_STATION_PART_DELAYED)
	self.placeStationDelayTimer = nil
	self.randomNoiseAudio = _loadAudio(config.AUDIO_RANDOM_NOISE)
	for _,audio in ipairs(self.randomNoiseAudio or {}) do
		audio:setVolume(config.AUDIO_RANDOM_NOISE_VOLUME)
	end

	self.overallHappiness = config.STAT_MAX / 2
	self.overallSleepiness = 0
	self.overallUncleanliness = 0
	self.overallHunger = 0
	self.overallBoredom = 0

	Game.music:play()

	love.mouse.setGrabbed(true)
end

function Game:onLeave()
	Game.music:stop()

	self.gameOver = nil
	self.gameOverTimer = nil
	self.placing = nil

	love.mouse.setGrabbed(false)
end

function Game:upkeep()
	self.moneyDelta = -(#self.map.rooms - self.numConnections) * config.UPKEEP_COST_PER_UNIT
	self.moneyDelta = self.moneyDelta - self.numConnections * config.UPKEEP_COST_PER_CONNECTION

	for _,person in ipairs(self.people) do
		self.moneyDelta = self.moneyDelta + person:collectMoney()
	end

	self.money = self.money + self.moneyDelta

	if self.money < config.BANKRUPTCY_THRESHOLD then
		self:triggerGameOver("BANKRUPTCY")
	end
end

function Game:triggerGameOver(reason)
	if not self.gameOver then
		self.gameOver = reason
		self.gameOverTimer = 0

		for _,person in ipairs(self.people) do
			person:leave()
		end

		self.score = #self.people
	end
end

function Game:spawnPeople()
	if not self.gameOver then
		local w, h = self.spawner.image:getDimensions()
		local x, y = self.spawner.x + w / 2, self.spawner.y + h / 2
		local i, j = self.map:worldToGridCoords(x, y)
		for n=1,love.math.random(config.SPAWN_COUNT_MIN, config.SPAWN_COUNT_MAX) do
			local grid = self.map:randomWalkableGrid(i, j, 2, 2)
			x, y = self.map:gridToWorldCoords(grid.i, grid.j)
			table.insert(self.people, Person:new(self.map, x, y))
		end
	end

	self.spawnTimer = nil
end

function Game:update(dt)
	local leavers = {}
	local stats = {
		happiness = 0,
		sleepiness = 0,
		uncleanliness = 0,
		hunger = 0,
		boredom = 0
	}
	local happiness = 0
	for key,person in ipairs(self.people) do
		if person:hasLeft() then
			table.insert(leavers, key, 1)
		else
			person:update(dt)
			for stat,value in pairs(stats) do
				if stat == "happiness" then
					stats[stat] = value + person[stat]
				else
					stats[stat] = value + person.stats[stat]
				end
			end
		end
	end
	for _,key in ipairs(leavers) do
		assert(self.people[key]:hasLeft())
		table.remove(self.people, key)
	end
	if #self.people > 0 then
		self.overallHappiness = stats.happiness / #self.people
		self.overallSleepiness = stats.sleepiness / #self.people
		self.overallUncleanliness = stats.uncleanliness / #self.people
		self.overallHunger = stats.hunger / #self.people
		self.overallBoredom = stats.boredom / #self.people

		if self.overallHappiness < config.MASS_EMIGRATION_THRESHOLD then
			self:triggerGameOver("UNHAPPINESS")
		end
	else
		-- No NaN's please.
		self.overallHappiness = 0
		self.overallSleepiness = 0
		self.overallUncleanliness = 0
		self.overallHunger = 0
		self.overallBoredom = 0
	end

	if self.placing then
		self.placing:update(dt)
	end

	local x, y = love.mouse.getPosition()
	local dx, dy = 0, 0
	if x < config.SCROLL_DISTANCE then
		dx = dx - 10
	elseif x > love.window.getWidth() - config.SCROLL_DISTANCE then
		dx = dx + 10
	end
	if y < config.SCROLL_DISTANCE then
		dy = dy - 10
	elseif y > love.window.getHeight() - config.SCROLL_DISTANCE then
		dy = dy + 10
	end
	local cx, cy = self.camera:getPosition()
	--dx = dx + dt * 0.1 * (x - cx)
	self.camera:setPosition(cx + dx, cy + dy)

	self.starsTimer:update(dt)
	self.upkeepTimer:update(dt)

	if self.spawnTimer then
		self.spawnTimer:update(dt)
	else
		self.spawnTimer = cron.after(love.math.random(config.SPAWN_INTERVAL_MIN, config.SPAWN_INTERVAL_MAX), self.spawnPeople, self)
	end
	if self.placeStationDelayTimer then
		self.placeStationDelayTimer:update(dt)
	end

	if self.randomNoiseTimer then
		self.randomNoiseTimer:update(dt)
	else
		self.randomNoiseTimer = cron.after(love.math.random(config.AUDIO_RANDOM_NOISE_TIME_MIN, config.AUDIO_RANDOM_NOISE_TIME_MAX), function()
			_playRandom(self.randomNoiseAudio)
			self.randomNoiseTimer = nil
		end)
	end

	if self.gameOverTimer then
		self.gameOverTimer = self.gameOverTimer + dt
	end
end

function Game:draw()
	local cx, cy = self.camera:getPosition()
	self.backgroundCamera:setPosition(cx * config.BACKGROUND_SCALE, cy * config.BACKGROUND_SCALE)
	self.backgroundCamera:draw(function()
		love.graphics.draw(Game.background, -self.backgroundOffsetX, -self.backgroundOffsetY)
		love.graphics.draw(Game.stars[self.stars], -self.backgroundOffsetX, -self.backgroundOffsetY)
	end)

	self.camera:draw(function()
		self.map:draw()

		for _,person in ipairs(self.people) do
			person:draw()
		end

		if self.placing then
			if self.map:canPlace(self.placing) then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(255, 50, 50, 200)
			end
			self.placing:draw()
			love.graphics.setColor(255, 255, 255, 255)
		end
	end)

	local moneyText = tostring(math.floor(self.money))
	love.graphics.setFont(self.moneyFont)
	love.graphics.printf(moneyText, 0, 10, love.window.getWidth(), "center")
	if self.moneyDelta < 0 then
		love.graphics.setColor(255, 0, 0, 255)
	end
	local deltaText = "("
	if self.moneyDelta > 0 then
		deltaText = deltaText .. "+"
	elseif self.moneyDelta == 0 then
		deltaText = deltaText .. "+"
		--deltaText = deltaText .. "±" -- No support in font :(
	end
	deltaText = deltaText .. math.floor(self.moneyDelta) .. ")"
	-- Delta to the right.
	love.graphics.print(deltaText, love.window.getWidth() / 2 + self.moneyFont:getWidth(moneyText) / 2 + 10, 10)
	love.graphics.setColor(255, 255, 255, 255)
	-- Coin to the left
	love.graphics.draw(Widget.coin, love.window.getWidth() / 2 - self.moneyFont:getWidth(moneyText) / 2 - 10, 11 + (self.moneyFont:getHeight() - Widget.coin:getHeight()) / 2)

	if not self.gameOver then
		self.buildLivingQuarter:draw()
		self.buildHygiene:draw()
		self.buildRestaurant:draw()
		self.buildEntertainment:draw()
		self.buildCorridor:draw()
		self.buildBend:draw()
		self.buildThreeWay:draw()
		self.buildFourWay:draw()
	end

	love.graphics.setFont(self.bodyFont)
	love.graphics.print("Number of inhabitants: " .. #self.people, 10, 10)
	love.graphics.print("Overall happiness: " .. math.floor(self.overallHappiness / config.STAT_MAX * 100) .. "%", 10, 10 + 1 * 13)
	love.graphics.print("Overall sleepiness: " .. math.floor(self.overallSleepiness / config.STAT_MAX * 100) .. "%", 10, 10 + 2 * 13)
	love.graphics.print("Overall uncleanliness: " .. math.floor(self.overallUncleanliness / config.STAT_MAX * 100) .. "%", 10, 10 + 3 * 13)
	love.graphics.print("Overall hunger: " .. math.floor(self.overallHunger / config.STAT_MAX * 100) .. "%", 10, 10 + 4 * 13)
	love.graphics.print("Overall boredom: " .. math.floor(self.overallBoredom / config.STAT_MAX * 100) .. "%", 10, 10 + 5 * 13)

	if self.gameOver then
		love.graphics.push()
		love.graphics.translate(love.window.getWidth() / 2, love.window.getHeight() / 2)
		if self.gameOverTimer > 1.4 then
			love.graphics.scale(5)
		else
			love.graphics.scale(40 - self.gameOverTimer * 25)
		end
		love.graphics.setColor(255, 20, 20, 255)
		love.graphics.setFont(self.gameOverFont)
		love.graphics.print(self.gameOver, -self.gameOverFont:getWidth(self.gameOver) / 2, 10, math.rad(-25))
		love.graphics.pop()

		if self.gameOverTimer > 1.4 then
			love.graphics.setColor(255, 255, 255, (math.sin(2 * self.gameOverTimer) * 0.5 + 0.5) * 255)
			love.graphics.printf("Click to continue", 0, love.window.getHeight() - self.gameOverFont:getHeight() - 10, love.window.getWidth(), "center")
		end
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.printf("Your interstellar cruise reached "..self.score.." inhabitants.", 0, love.window.getHeight() - 2 * (self.gameOverFont:getHeight() + 10), love.window.getWidth(), "center")
	end
end

function Game:mouseMoved(x, y)
	x, y = self.camera:toWorld(x, y)
	if self.placing then
		local w, h = self.placing.image:getDimensions()
		x, y = x - w / 2, y - h / 2
		-- Moveable in increments of Map.GRID_SIZE
		x = math.floor(x / Map.GRID_SIZE + 0.5) * Map.GRID_SIZE
		y = math.floor(y / Map.GRID_SIZE + 0.5) * Map.GRID_SIZE
		self.placing.x = x
		self.placing.y = y
	end
end

function Game:mousePressed(x, y, button)
	if button == "wu" then
		self.camera:setScale(math.min(self.camera:getScale() + config.ZOOM_SPEED, config.ZOOM_MAX))
	elseif button == "wd" then
		self.camera:setScale(math.max(self.camera:getScale() - config.ZOOM_SPEED, config.ZOOM_MIN))
	end

	if self.gameOver then
		if self.gameOverTimer > 1.4 and button == "l" then
			self:getStateManager():switchState("MainMenu")
		end
		return
	end

	if self.placing then
		if button == "l" then
			if self.map:canPlace(self.placing) then
				_playRandom(self.placeStationAudio)
				self.placeStationDelayTimer = cron.after(love.math.random(config.AUDIO_CONNECT_STATION_PART_DELAYED_TIME_MIN, config.AUDIO_CONNECT_STATION_PART_DELAYED_TIME_MAX), function()
					_playRandom(self.placeStationDelayAudio)
					self.placeStationDelayTimer = nil
				end)

				self.map:addRoom(self.placing)
				self.placing = nil
			end
		elseif button == "r" then
			_playRandom(self.rotateStationAudio)

			self.placing:startRotation(-90)
		end
	elseif button == "l" then
		if self.money <= config.BUILD_MIN_BUDGET then
			-- No money, no service.
			return
		end

		local type, room
		if self.buildLivingQuarter:wasClicked(x, y) then
			type = Room.LIVING_QUARTERS
			self.money = self.money - config.BUILD_COST_LIVING_QUARTER
		elseif self.buildHygiene:wasClicked(x, y) then
			type = Room.HYGIENE
			self.money = self.money - config.BUILD_COST_HYGIENE
		elseif self.buildRestaurant:wasClicked(x, y) then
			type = Room.RESTAURANT
			self.money = self.money - config.BUILD_COST_RESTAURANT
		elseif self.buildEntertainment:wasClicked(x, y) then
			type = Room.ENTERTAINMENT
			self.money = self.money - config.BUILD_COST_ENTERTAINMENT
		elseif self.buildCorridor:wasClicked(x, y) then
			type = Room.MISC
			room = "corridor"
			self.money = self.money - config.BUILD_COST_CORRIDOR
		elseif self.buildBend:wasClicked(x, y) then
			type = Room.MISC
			room = "bend"
			self.money = self.money - config.BUILD_COST_BEND
		elseif self.buildThreeWay:wasClicked(x, y) then
			type = Room.MISC
			room = "3xcross"
			self.money = self.money - config.BUILD_COST_THREE_WAY
		elseif self.buildFourWay:wasClicked(x, y) then
			type = Room.MISC
			room = "4xcross"
			self.money = self.money - config.BUILD_COST_FOUR_WAY
		end

		if type then
			_playRandom(self.buyStationAudio)

			self.placing = Room:new(type, 0, 0, room)
			self:mouseMoved(love.mouse.getPosition())

			if type == Room.MISC then
				self.numConnections = self.numConnections + 1
			end
		end
	end
end

return Game
