function table.reverse(tbl)
	local len = #tbl
	local half = math.floor(len/2)
	local j
	local i=1,half do
		j = len - i + 1
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end
