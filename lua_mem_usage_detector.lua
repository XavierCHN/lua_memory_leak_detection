--- Lua memory leak detector
-- @author XavierCHN
-- @date 2017.06.23
-- @license: DO ANYTHING YOU WANT 

local memory_state = {}
local current_memory = 0

local function recordAlloc(event, line_no)
	local memory_increased = collectgarbage("count") - current_memory
  -- if no memory usage increased, 
	if (memory_increased < 1e-6) then return end
  
  -- record the file and line number
	local info = debug.getinfo(2, "S").source
	info = string.format("%s@%s", info, line_no)

	local item = memory_state[info]
	if not item then
		memory_state[info] = {info, 1, memory_increased}
	else
		item[2] = item[2] + 1
		item[3] = item[3] + memory_increased
	end
  
  -- collect memory usage by this file
	current_memory = collectgarbage("count")
end

utilsMemoryLeakDetector = {}

function utilsMemoryLeakDetector:StartRecord()
	if debug.gethook() then
		self:StopRecord()
		return
	end

	memory_state = {}
	current_memory = collectgarbage("count")
	debug.sethook(recordAlloc, "l")
end

function utilsMemoryLeakDetector:EndRecord(count)
	debug.sethook()
	if not memory_state then return end
	local sorted = {}

	for k, v in pairs(memory_state) do
		table.insert(sorted, v)
	end

	table.sort(sorted, function(a, b) return a[3] > b[3] end)

	for i = 1, count do
		local v = sorted[i]
		print(string.format("MemoryDump [MEM: %sK] [COUNT: %s ] [AVG: %s k] %s:", v[3], v[2], v[3] / v[2], v[1]))
	end
end

utilsMemoryLeakDetector:StartRecord()

-- register console command in dota2 workshop tools debug mode
if GameRules and IsInToolsMode() then
	Convars:RegisterCommand("debug_dump_lua_memory_detail",function(_, top_count)
		count = tonumber(top_count) or 30
		utilsMemoryLeakDetector:EndRecord(count)
	end,"Dump lua usage detail to console",FCVAR_CHEAT)
end
