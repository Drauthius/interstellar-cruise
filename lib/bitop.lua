--[[
-- Wrapper for LuaJIT's BitOp library, or Lua's 5.2 bit32 library.
--]]

local bitop = {}

local bitlib
if pcall(require, "bit") then
	bitlib = require("bit")
	bitlib.tobits = function(bit)
		-- From luabit
		local tbl = {}
		local count = 1
		while bit > 0 do
			local last = math.mod(bit, 2)
			if last == 1 then
				tbl[count] = 1
			else
				tbl[count] = 0
			end
			bit = (bit - last) / 2
			count = count + 1
		end
		return tbl
	end
elseif bit32 then
	bitlib = bit32
else
	require("lib.luabit.init")
	bitlib = bit
end

bitop.band = bitlib.band
bitop.bor = bitlib.bor
bitop.bnot = bitlib.bnot
bitop.tobits = bitlib.tobits

return bitop
