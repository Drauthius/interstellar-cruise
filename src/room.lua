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
require("lib.math")

local config = require("gameconfig")

local Room = class("Room")

-- Room types
Room.static.SPAWN = 1
Room.static.LIVING_QUARTERS = 2
Room.static.HYGIENE = 3
Room.static.RESTAURANT = 4
Room.static.ENTERTAINMENT = 5
Room.static.MISC = 6

Room.static.tints = {
	[Room.SPAWN] = { 255, 255, 255 },
	[Room.LIVING_QUARTERS] = { 152, 185, 237 },
	[Room.HYGIENE] = { 84, 209, 153 },
	[Room.RESTAURANT] = { 230, 157, 62 },
	[Room.ENTERTAINMENT] = { 180, 140, 219 },
	[Room.MISC] = { 255, 255, 255 }
}

Room.static.MAX_ROOM_SPRITES = 18
Room.static.sprites = {}
Room.static.furniture = {
	[Room.LIVING_QUARTERS] = {
		["1x1"] = {
			image = love.graphics.newImage("gfx/livingquarter_furniture_1x1.png"),
			quads = {}
		},
		["1x2"] = {
			image = love.graphics.newImage("gfx/livingquarter_furniture_1x2.png"),
			quads = {}
		},
		["2x2"] = {
			image = love.graphics.newImage("gfx/livingquarter_furniture_2x2.png"),
			quads = {}
		}
	},
	[Room.HYGIENE] = {
		["1x1"] = {
			image = love.graphics.newImage("gfx/hygiene_furniture_1x1.png"),
			quads = {}
		},
		["1x2"] = {
			image = love.graphics.newImage("gfx/hygiene_furniture_1x2.png"),
			quads = {}
		},
		["2x2"] = {
			image = love.graphics.newImage("gfx/hygiene_furniture_2x2.png"),
			quads = {}
		}
	},
	[Room.ENTERTAINMENT] = {
		["1x1"] = {
			image = love.graphics.newImage("gfx/entertainment_furniture_1x1.png"),
			quads = {}
		},
		["1x2"] = {
			image = love.graphics.newImage("gfx/entertainment_furniture_1x2.png"),
			quads = {}
		},
		["2x2"] = {
			image = love.graphics.newImage("gfx/entertainment_furniture_2x2.png"),
			quads = {}
		}
	},
	[Room.RESTAURANT] = {
		["1x1"] = {
			image = love.graphics.newImage("gfx/restaurant_furniture_1x1.png"),
			quads = {}
		},
		["2x2"] = {
			image = love.graphics.newImage("gfx/restaurant_furniture_2x2.png"),
			quads = {}
		}
	}
}

for _,types in pairs(Room.furniture) do
	for k,v in pairs(types) do
		local w, h = v.image:getDimensions()
		local wo, ho = 1, 1
		if k == "1x2" then
			ho = 2
		elseif k == "2x2" then
			ho = 2
			wo =  2
		end
		for i=0,w,20*wo do
			for j=0,h,20*ho do
				table.insert(v.quads, love.graphics.newQuad(i + 2, j + 2, (20 - 4) * wo, (20 - 4) * ho, v.image:getDimensions()))
			end
		end
	end
end

function Room:initialize(roomType, x, y, roomImage)
	assert(roomType)
	self.type = roomType

	self.x, self.y = x, y
	self.rotation = 0

	local roomDesign
	if roomImage then
		if not Room.sprites[roomImage] then
			Room.sprites[roomImage] = {
				image = love.graphics.newImage(("gfx/%s.png"):format(roomImage)),
				collisionImage = love.graphics.newImage(("gfx/%s_cmX.png"):format(roomImage))
			}
		end
	else
		roomDesign = love.math.random(Room.MAX_ROOM_SPRITES)
		if not Room.sprites[roomDesign] then
			Room.sprites[roomDesign] = {
				image = love.graphics.newImage(("gfx/floor%d.png"):format(roomDesign)),
				collisionImage = love.graphics.newImage(("gfx/floor%d_cmX.png"):format(roomDesign))
			}
		end
	end

	self.image = Room.sprites[roomDesign or roomImage].image
	self.collisionMap = Room.sprites[roomDesign or roomImage].collisionImage

	self.halfWidth = self.image:getWidth() / 2
	self.halfHeight = self.image:getHeight() / 2

	self.capacity = 0
	self.currentUsers = 0
	self.placed = false

	self.furniture = {}
	self:addFurniture()
end

function Room:addFurniture()
	-- Should have made the map._interpretRoom use something in this class
	-- instead.

	if not Room.furniture[self.type] then
		return -- No furniture to add to the room.
	end

	local grid = {}
	for x=8,self.collisionMap:getWidth(),16 do
		local i = math.floor(x / 16)
		grid[i] = {}
		for y=8,self.collisionMap:getHeight(),16 do
			local j = math.floor(y / 16)

			local r, g, b, a = self.collisionMap:getData():getPixel(x, y)

			if r == 0 and g == 0 and b == 255 then
				grid[i][j] = true
			end
		end
	end

	for i=1,self.collisionMap:getWidth() / 16 do
		for j=1,self.collisionMap:getHeight() / 16 do
			if grid[i] and grid[i][j] then
				if love.math.random() < config.ROOM_FURNITURE_CHANCE then
					local furniture = {
						x = i * 16,
						y = j * 16
					}

					if Room.furniture[self.type]["2x2"] and grid[i][j+1] and grid[i+1][j] and grid[i+1][j+1] then
						furniture.type = "2x2"
						furniture.w = 32
						furniture.h = 32
						grid[i][j+1] = nil
						grid[i+1][j] = nil
						grid[i+1][j+1] = nil
					elseif grid[i][j+1] and Room.furniture[self.type]["1x2"] then
						furniture.type = "1x2"
						furniture.w = 16
						furniture.h = 32
						grid[i][j+1] = nil
					elseif Room.furniture[self.type]["1x1"] then
						furniture.type = "1x1"
						furniture.w = 16
						furniture.h = 16
					end

					if furniture.type then
						local furns = Room.furniture[self.type][furniture.type]
						furniture.image = furns.image
						furniture.quad = furns.quads[love.math.random(#furns.quads)]

						table.insert(self.furniture, furniture)
					end
				end
			end
		end
	end
end

function Room:useRoom()
	if self.currentUsers < self.capacity then
		self.currentUsers = self.currentUsers + 1
		return true
	else
		return false
	end
end

function Room:release()
	self.currentUsers = math.max(self.currentUsers - 1, 0)
end

function Room:startRotation(degrees)
	if self.targetRotation then
		-- Too fast clicking. D:
		self.targetRotation = self.targetRotation + math.rad(degrees)
	else
		self.targetRotation = self.rotation + math.rad(degrees)
	end
end

function Room:isRotating()
	return self.targetRotation ~= nil
end

function Room:update(dt)
	if self.targetRotation then
		self.rotation = self.rotation - 10 * dt
		if math.abs(self.rotation - self.targetRotation) < 0.5 then
			self.rotation = -(-self.targetRotation % math.rad(360)) -- Overflows are real.
			self.targetRotation = nil
		end
	end
end

function Room:draw()
	love.graphics.push()
	love.graphics.translate(self.x + self.halfWidth, self.y + self.halfHeight)
	love.graphics.rotate(self.rotation)

	-- lol... The collision map rotates around the top corner, so pictures with
	-- different width/height need to be translated.
	local rot = math.floor(math.abs(math.deg(self.rotation)) / 90) % 4
	local diff = self.halfWidth - self.halfHeight
	if rot == 1 then
		love.graphics.translate(-diff, -diff)
	elseif rot == 3 then
		love.graphics.translate(diff, diff)
	end

	if self.placed then
		love.graphics.setColor(Room.tints[self.type])
	end

	love.graphics.draw(self.image, -self.halfWidth, -self.halfHeight)
	love.graphics.setColor(255, 255, 255, 255)

	for _,furniture in ipairs(self.furniture) do
		love.graphics.draw(furniture.image, furniture.quad, -self.halfWidth + furniture.x, -self.halfHeight + furniture.y)
	end

	if debug then
		love.graphics.setColor(255, 255, 255, 50)
		love.graphics.draw(self.collisionMap, -self.halfWidth, -self.halfHeight)
	end

	love.graphics.setColor(255, 255, 255, 255)

	love.graphics.pop()
end

return Room
