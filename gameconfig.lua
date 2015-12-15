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

local config = {}

--
-- End-game conditions
--
-- If the money is below the specified amount, the game ends.
config.BANKRUPTCY_THRESHOLD = 0
-- If overall happiness, in percent, is below the specified amount, the game ends.
config.MASS_EMIGRATION_THRESHOLD = 40

--
-- Audio stuff
--
config.GAME_MUSIC = "sfx/echo bouncer.mp3"
config.GAME_MUSIC_VOLUME = 0.6
config.MENU_MUSIC = "sfx/echo bouncer interscreen v3.mp3"
config.MENU_MUSIC_LOOP = "sfx/echo bouncer interscreen v3 loop.mp3"
config.MENU_MUSIC_VOLUME = 1
config.AUDIO_RANDOM_NOISE = { "sfx/knakande station 01.mp3", "sfx/knakande station 02.mp3", "sfx/knakande station 03.mp3" }
config.AUDIO_RANDOM_NOISE_TIME_MIN = 30
config.AUDIO_RANDOM_NOISE_TIME_MAX = 60
config.AUDIO_RANDOM_NOISE_VOLUME = 0.3
config.AUDIO_BUY_STATION_PART = { "sfx/get station part.mp3" }
config.AUDIO_ROTATE_STATION_PART = { "sfx/rotate station part.mp3" }
config.AUDIO_CONNECT_STATION_PART = { "sfx/part lock 01.mp3", "sfx/part lock 02.mp3", "sfx/part lock 03.mp3", "sfx/part lock 04.mp3" }
config.AUDIO_CONNECT_STATION_PART_DELAYED = { "sfx/engine startup 01.mp3", "sfx/engine startup 02.mp3" }
config.AUDIO_CONNECT_STATION_PART_DELAYED_TIME_MIN = 0.5
config.AUDIO_CONNECT_STATION_PART_DELAYED_TIME_MAX = 1

--
-- UI stuff
--
config.ZOOM_MIN = 0.5
config.ZOOM_MAX = 3
config.ZOOM_SPEED = 0.1
-- Number of pixels from the edge before scrolling.
config.SCROLL_DISTANCE = 40
config.BACKGROUND_SCALE = 0.5
config.BLINKING_ICON_SPEED = 0.6

--
-- Room stuff
--
-- How many slots to use for serving people depending on walkable tiles per room.
config.ROOM_CAPACITY_PER_WALKABLE = 0.25
-- How many slots to use for serving people depending on furniture tiles per room.
config.ROOM_CAPACITY_PER_FURNITURE = 0.4
-- The chance, in percent between 0 and 1, of a furniture tile being furnished.
config.ROOM_FURNITURE_CHANCE = 0.7

--
-- Spawning
--
-- Minimum time in seconds between spawning new people.
config.SPAWN_INTERVAL_MIN = 3
-- Maximum time in seconds between spawning new people.
config.SPAWN_INTERVAL_MAX = 14
-- Minimum number of people to spawn each turn.
config.SPAWN_COUNT_MIN = 1
-- Maximum number of people to spawn each turn.
config.SPAWN_COUNT_MAX = 2

--
-- Costs and upkeep
--
config.STARTING_BUDGET = 10000
-- How often to perform upkeep.
config.UPKEEP_TIME = 5
-- Cost for each room (per upkeep phase)
config.UPKEEP_COST_PER_UNIT = 50
-- Cost for each connection/intersection (per upkeep phase)
config.UPKEEP_COST_PER_CONNECTION = 5
-- Gain per happy person.
config.UPKEEP_GAIN_PER_PERSON = 18
-- Minimum budget needed to build something.
config.BUILD_MIN_BUDGET = 0
config.BUILD_COST_LIVING_QUARTER = 1100
config.BUILD_COST_HYGIENE = 1100
config.BUILD_COST_RESTAURANT = 1200
config.BUILD_COST_ENTERTAINMENT = 1300
config.BUILD_COST_CORRIDOR = 150
config.BUILD_COST_BEND = 250
config.BUILD_COST_THREE_WAY = 300
config.BUILD_COST_FOUR_WAY = 400

--
-- Stats
--
-- The maximum a stat and happiness can be.
config.STAT_MAX = 1000
-- Stat values before searching out a room to fill a need.
config.ENTER_ROOM_WHEN_STAT_REACHES_MIN = 400
config.ENTER_ROOM_WHEN_STAT_REACHES_MAX = 600
-- Stat values before leaving the room/slot.
config.LEAVE_ROOM_WHEN_STAT_REACHES_MIN = 0
config.LEAVE_ROOM_WHEN_STAT_REACHES_MAX = 50
-- Stat values when the person comes to the station.
-- (Value is randomized between start and stop.)
config.STARTING_STATS = {
	boredom = { 0, 300 },
	sleepiness = { 100, 500 },
	hunger = { 200, 500 },
	uncleanliness = { 100, 400 }
}
-- Decrease of each stat per second when the need is currently being met.
config.STAT_DECREASE = {
	boredom = 75,
	sleepiness = 45,
	hunger = 120,
	uncleanliness = 165
}
-- Increase of each stat per second (always applied)
config.STAT_INCREASE = {
	boredom = 13,
	sleepiness = 4,
	hunger = 9,
	uncleanliness = 7
}
--
-- Happiness
--
config.STARTING_HAPPINESS_MIN = 500
config.STARTING_HAPPINESS_MAX = 600
-- Only pay upkeep when happiness in above this value.
config.PAY_WHEN_HAPPINESS_IS_ABOVE = 400
-- Leave the station when happiness drops below this value.
config.LEAVE_WHEN_HAPPINESS_IS_BELOW = 50
-- All stats must be below this threshold for happiness to increase.
config.HAPPINESS_INCREASE_THRESHOLD = 450
-- The amount to increase happiness by, per second.
config.HAPPINESS_INCREASE_RATE = 6
-- If one stat is above this threshold, happiness decreases.
config.HAPPINESS_DECREASE_THRESHOLD = 900
-- The amount to decrease happiness by, per second.
config.HAPPINESS_DECREASE_RATE = 15

-- The walking speed of people in pixels per second.
config.WALKING_SPEED = 32
-- The number of seconds before changing animation sprite when walking.
config.WALKING_ANIMATION_SPEED = 0.2

return config
--return setmetatable({}, { __index = config, __newindex = function(table, key) assert(false, "Key " .. key .. "doesn't exist in the configuration.") end })
