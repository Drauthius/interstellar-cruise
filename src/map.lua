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

local astar = require("lib.astar")
local bitop = require("lib.bitop")
local heap = require("lib.heap")
local class = require("lib.middleclass")
local config = require("gameconfig")

astar.heap = heap

local Map = class("Map")

-- Map stuff.
Map.static.GRID_SIZE = 16
Map.static.HALF_GRID_SIZE = Map.GRID_SIZE / 2

-- Collision stuff.
Map.static.EMPTY = 0
Map.static.WALKABLE = 1
Map.static.CONNECTION = 2
Map.static.WALL = 4
Map.static.FURNITURE = 8

local function _gridAddType(grid, type)
	grid.collision = bitop.bor(grid.collision, type)
end

local function _gridHasType(grid, type)
	return bitop.band(grid.collision, type) ~= 0
end

local function _interpretRoom(self, room, func)
	local i, j = self:worldToGridCoords(room.x, room.y)
	local w, h = room.collisionMap:getDimensions()
	local sw, sh = self:worldToGridCoords(w, h)
	sw, sh = sw - 1, sh - 1
	local rot = math.floor(math.abs(math.deg(room.rotation)) / 90) % 4

	local function toGrid(x, y)
		local pi, pj = self:worldToGridCoords(x, y)
		if rot == 1 then
			pi, pj = pj, sw - pi + 1
		elseif rot == 2 then
			pi = sw - pi + 1
			pj = sh - pj + 1
		elseif rot == 3 then
			pi, pj = sh - pj + 1, pi
		end

		return i + pi - 1, j + pj - 1
	end

	for x=Map.HALF_GRID_SIZE,w,Map.GRID_SIZE do
		for y=Map.HALF_GRID_SIZE,h,Map.GRID_SIZE do
			local r, g, b, a = room.collisionMap:getData():getPixel(x, y)
			local i, j = toGrid(x, y)
			local type

			if a < 150 then -- lol
				type = Map.WALKABLE
			elseif r == 0 and g == 0 and b == 0 then
				type = Map.WALL
			elseif r == 0 and g == 255 and b == 0 then
				type = Map.CONNECTION
			elseif r == 255 and g == 0 and b == 0 then
				type = Map.EMPTY
			elseif r == 0 and g == 0 and b == 255 then
				type = Map.FURNITURE
			else
				assert(false, ("Colours %d,%d,%d,%d not understood."):format(r,g,b,a))
			end

			func(i, j, type)
		end
	end
end

function Map:initialize(width, height)
	self.width = width
	self.height = height

	self.rooms = {}

	self.grid = {}
	for i=1,width do
		self.grid[i] = {}
		for j=1,height do
			self.grid[i][j] = {
				i = i,
				j = j,
				collision = Map.EMPTY
			}
		end
	end
end

function Map:addRoom(room)
	local walkable = 0
	local furniture = 0

	_interpretRoom(self, room, function(i, j, type)
		if type == Map.WALL or type == Map.EMPTY then
			_gridAddType(self.grid[i][j], type)
		else
			_gridAddType(self.grid[i][j], Map.WALKABLE)
			if type == Map.CONNECTION then
				_gridAddType(self.grid[i][j], Map.CONNECTION)
			elseif type == Map.WALKABLE then
				walkable = walkable + 1
			elseif type == Map.FURNITURE then
				furniture = furniture + 1
			end
		end
	end)

	room.capacity = math.ceil(walkable * config.ROOM_CAPACITY_PER_WALKABLE + furniture * config.ROOM_CAPACITY_PER_FURNITURE)
	room.placed = true

	table.insert(self.rooms, room)

	self.debugRoom = nil
end

function Map:canPlace(room)
	self.debugRoom = room

	if room:isRotating() then
		return false
	end

	local w, h = room.image:getDimensions()
	local rot = math.floor(math.abs(math.deg(room.rotation)) / 90) % 4

	if rot == 1 or rot == 3 then
		w, h = h, w
	end

	local i, j = self:worldToGridCoords(room.x, room.y)
	local sw, sh = self:worldToGridCoords(w, h)
	sw, sh = sw - 1, sh - 1 -- One for the previous grid
	if i < 1 or j < 1 or i + sw - 1 > self.width or j + sh - 1 > self.height then
		return false
	end

	local isBlocked = false
	local hasConnection = false
	_interpretRoom(self, room, function(i, j, type)
		if not isBlocked then
			isBlocked = self.grid[i][j].collision ~= Map.EMPTY and type ~= Map.EMPTY
		end

		if not isBlocked and not hasConnection and type == Map.CONNECTION then
			for ni=i-1,i+1 do
				for nj=j-1,j+1 do
					if math.abs(ni - i) == 1 and math.abs(nj - j) == 1 then
						-- Don't allow diagonals.
					elseif self.grid[ni] and self.grid[ni][nj] and _gridHasType(self.grid[ni][nj], Map.CONNECTION) then
						hasConnection = true
					end
				end
			end
		end
	end)

	return not isBlocked and hasConnection
end

function Map:gridToWorldCoords(i, j)
	return (i - 1) * Map.GRID_SIZE, (j - 1) * Map.GRID_SIZE -- Upper corner of grid.
end

function Map:midGridToWorldCoords(i, j)
	return (i - 1) * Map.GRID_SIZE + Map.HALF_GRID_SIZE, (j - 1) * Map.GRID_SIZE + Map.HALF_GRID_SIZE -- Middle of grid.
end

function Map:worldToGridCoords(x, y)
	return math.floor(x / Map.GRID_SIZE) + 1, math.floor(y / Map.GRID_SIZE) + 1
end

function Map:getGrid(i, j)
	return self.grid[i][j]
end

function Map:randomWalkableGrid(i, j, dx, dy)
	local walkable = {}
	local si, sj = math.max(i - dx, 1), math.max(j - dy, 1)

	for x=si,math.min(i + dx, self.width) do
		for y=sj,math.min(j + dy, self.height) do
			if _gridHasType(self.grid[x][y], Map.WALKABLE) then
				table.insert(walkable, self.grid[x][y])
			end
		end
	end

	local candidates = #walkable
	if candidates > 0 then
		return walkable[love.math.random(candidates)]
	end
end

function Map:randomWalkableGridInRoom(room)
	local walkable = {}

	_interpretRoom(self, room, function(i, j, type)
		if _gridHasType(self.grid[i][j], Map.WALKABLE) and not _gridHasType(self.grid[i][j], Map.CONNECTION)then
			table.insert(walkable, self.grid[i][j])
		end
	end)

	local candidates = #walkable
	if candidates > 0 then
		return walkable[love.math.random(candidates)]
	end
end

function Map:findClosestRoom(x, y, type)
	local closest, distance = nil, math.huge
	for _,room in ipairs(self.rooms) do
		if room.type == type then
			local dist = math.distancesquared(x, y, room.x, room.y)
			if dist < distance then
				closest = room
				distance = dist
			end
		end
	end

	return closest
end

function Map:findRandomRoom(type, exclude)
	local rooms = {}

	for _,room in ipairs(self.rooms) do
		if room.type == type then
			local add = true
			for _,ex in ipairs(exclude) do
				if ex == room then
					add = false
					break
				end
			end

			if add then
				table.insert(rooms, room)
			end
		end
	end

	local candidates = #rooms
	if candidates > 0 then
		return rooms[love.math.random(candidates)]
	end
end

function Map:getPath(start, target)
	return astar.reconstructPath(start, target, astar.search(self, start, target))
end

function Map:neighbours(node)
	local neighbours = {}
	for i=math.max(node.i - 1, 1),math.min(node.i + 1, self.width) do
		for j=math.max(node.j - 1, 1),math.min(node.j + 1, self.height) do
			if (i ~= node.i or j ~= node.j) and _gridHasType(self.grid[i][j], Map.WALKABLE) then
				-- Don't cut corners.
				local cutsCorner = false
				if math.abs(node.i - i) == 1 and math.abs(node.j - j) == 1 then
					--cutsCorner = not _gridHasType(self.grid[i][node.j], Map.WALKABLE) or not _gridHasType(self.grid[node.j][j], Map.WALKABLE)
					cutsCorner = true
				end
				--[[
				local cutsCorner = false
				if math.abs(node.i - i) == 1 then
					if self.grid[i][node.j].collision ~= Map.WALKABLE then
						cutsCorner = true
					elseif math.abs(node.j - j) == 1 then
						cutsCorner = self.grid[node.i][j] ~= Map.WALKABLE
					end
				end
				print(i,j,self.grid[i][j].collision)
				if true and not cutsCorner then
					table.insert(neighbours, self.grid[i][j])
				end]]--
				if not cutsCorner then
					table.insert(neighbours, self.grid[i][j])
				end
			end
		end
	end

	return neighbours
end

function Map:cost()
	return 1
end

function Map:heuristic(node, target)
	return math.abs(node.i - target.i) + math.abs(node.j - target.j)
end

function Map:draw()
	for _,room in ipairs(self.rooms) do
		room:draw()
	end

	if debug then
		local transparency = 50

		for i in ipairs(self.grid) do
			for j in ipairs(self.grid[i]) do
				if _gridHasType(self.grid[i][j], Map.WALKABLE) then
					love.graphics.setColor(0, 255, 0, transparency)
				elseif _gridHasType(self.grid[i][j], Map.WALL) then
					love.graphics.setColor(255, 0, 0, transparency)
				else
					love.graphics.setColor(0, 0, 255, transparency)
				end

				local x, y = self:gridToWorldCoords(i, j)
				love.graphics.rectangle("fill", x, y, Map.GRID_SIZE, Map.GRID_SIZE)
				love.graphics.setColor(255, 255, 255, 255)
			end
		end

		if self.debugRoom then
			_interpretRoom(self, self.debugRoom, function(i, j, type)
				if type == Map.WALKABLE then
					love.graphics.setColor(0, 255, 0, transparency)
				elseif type == Map.WALL then
					love.graphics.setColor(255, 0, 0, transparency)
				elseif type == Map.CONNECTION then
					love.graphics.setColor(0, 180, 180, transparency)
				else
					love.graphics.setColor(0, 0, 255, transparency)
				end

				local x, y = self:gridToWorldCoords(i, j)
				love.graphics.rectangle("fill", x, y, Map.GRID_SIZE, Map.GRID_SIZE)
				love.graphics.setColor(255, 255, 255, 255)
			end)
		end
	end
end

return Map
