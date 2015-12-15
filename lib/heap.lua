local heap = {}

--[[!
-- Traverse upwards, to place the item at the correct location.
--]]
local function upHeap(self, i, item)
	local parent = math.floor(i/self.numChildren)

	while parent > 0 and parent ~= i do
		-- We're done if the parent should be before the inserted item.
		if self.comp(self.queue[parent], item) then
			break
		end

		-- Traverse upwards, swapping the parent backwards.
		self.queue[i] = self.queue[parent]
		i = parent
		parent = math.floor(i/self.numChildren)
	end

	self.queue[i] = item
end

--[[!
-- Traverse downwards, to place the item at the correct location.
--]]
local function downHeap(self, i, item)
	local newParent, firstChild

	while true do
		newParent = -1
		firstChild = self.numChildren * i

		-- Go through all the children, and keep track of the one that
		-- should be the new parent.
		for j=firstChild,firstChild + self.numChildren do
			if j <= self.queue.n then
				--if self.comp(self.queue[j] self.queue[newParent] or item) then
					--newParent = j
				if newParent == -1 then
					if self.comp(self.queue[j], item) then
						newParent = j
					end
				elseif self.comp(self.queue[j], self.queue[newParent]) then
					newParent = j
				end
			end
		end

		-- No child should be the new parent. We're done here.
		if newParent == -1 then
			break
		end

		-- Make a child a parent
		self.queue[i] = self.queue[newParent]
		i = newParent
	end

	-- Lastly, move the item to the correct position.
	self.queue[i] = item
end

local Heap = {}
local Heap_mt = { __index = Heap }

function Heap:front()
	return self.queue[1]
end

function Heap:push(item)
	self.queue.n = self.queue.n + 1
	upHeap(self, self.queue.n, item)
end

function Heap:pop()
	assert(self:size() > 0, "Attempted to pop empty heap.")

	local item = self:front()

	self.queue.n = self.queue.n - 1
	downHeap(self, 1, self.queue[self.queue.n+1])
	self.queue[self.queue.n+1] = nil

	return item
end

function Heap:getNumChildren()
	return self.numChildren
end

function Heap:size()
	return self.queue.n
end

function Heap:empty()
	return self:size() == 0
end

--
-- Module functions
--
function heap.newHeap(numChildren, comparator)
	assert(numChildren > 0, "Missing number of children.")

	comparator = comparator or function(a,b) return a < b end

	local newHeap = setmetatable({
		numChildren = numChildren,
		comp = comparator,
		queue = { n = 0 }
	}, Heap_mt)

	return newHeap
end

return heap
