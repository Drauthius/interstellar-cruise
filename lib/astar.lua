local astar = {
	heap = nil
}

local function reverse(a)
	local len = #a
	local half = math.floor(len/2)
	local j
	for i=1,half do
		j = len - i + 1
		a[i], a[j] = a[j], a[i]
	end
	return a
end

function astar.search(graph, start, target)
	local open = astar.heap.newHeap(2, function(a,b) return a.cost < b.cost end)
	open:push({ node = start, cost = 0 })

	local cameFrom = {}
	local costSoFar = {}

	cameFrom[start] = start
	costSoFar[start] = 0

	while not open:empty() do
		local current = open:pop()

		if current.node == target then
			break
		end

		for _,nextNode in pairs(graph:neighbours(current.node)) do
			local newCost = costSoFar[current.node] + graph:cost(current.node, nextNode)

			if costSoFar[nextNode] == nil or newCost < costSoFar[nextNode] then
				costSoFar[nextNode] = newCost
				local priority = newCost + graph:heuristic(nextNode, target)
				open:push({ node = nextNode, cost = priority })
				cameFrom[nextNode] = current.node
			end
		end
	end

	return cameFrom, costSoFar
end

function astar.reconstructReversedPath(start, target, cameFrom)
	local path = {}
	if cameFrom[target] ~= nil then
		while target ~= start do
			table.insert(path, target)
			target = cameFrom[target]
		end
		table.insert(path, start)
	end
	return path
end

function astar.reconstructPath(start, target, cameFrom)
	return reverse(astar.reconstructReversedPath(start, target, cameFrom))
end

return astar
