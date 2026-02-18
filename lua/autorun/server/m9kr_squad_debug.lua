--[[
	M9K Reloaded - Squad Debug Tool (Server-Side)

	This is a temporary diagnostic tool to discover the exact squad name
	that GMod uses for NPCs following the player.

	To use:
	1. Spawn a citizen NPC
	2. Make it follow you (use key on citizen)
	3. Open console and type: lua_run PrintAllSquads()

	This will print all NPCs, their squad names, and their disposition to you.
]]--

-- Global function to print squad information (callable from console)
function PrintAllSquads()
	print("=== SQUAD DEBUG INFORMATION ===")

	local allNPCs = ents.FindByClass("npc_*")
	local citizenTypes = {
		["npc_citizen"] = true,
		["npc_alyx"] = true,
		["npc_barney"] = true,
		["npc_monk"] = true,
		["npc_vortigaunt"] = true
	}

	for _, npc in ipairs(allNPCs) do
		if IsValid(npc) and citizenTypes[npc:GetClass()] then
			local squadName = npc:GetSquad() or "NO_SQUAD"
			local playerEnt = player.GetAll()[1] -- Get first player for testing

			if IsValid(playerEnt) then
				local disposition = npc:Disposition(playerEnt)
				local dispName = "UNKNOWN"

				if disposition == D_HT then dispName = "HATE"
				elseif disposition == D_FR then dispName = "FEAR"
				elseif disposition == D_NU then dispName = "NEUTRAL"
				elseif disposition == D_LI then dispName = "LIKE"
				end

				print(string.format(
					"NPC: %s | Class: %s | Squad: '%s' | Disposition: %s (%d)",
					tostring(npc),
					npc:GetClass(),
					squadName,
					dispName,
					disposition
				))
			end
		end
	end

	-- Also print all unique squad names found
	print("\n=== UNIQUE SQUAD NAMES ===")
	local uniqueSquads = {}
	for _, npc in ipairs(ents.GetAll()) do
		if IsValid(npc) and npc:IsNPC() then
			local squad = npc:GetSquad()
			if squad and squad ~= "" then
				uniqueSquads[squad] = (uniqueSquads[squad] or 0) + 1
			end
		end
	end

	for squadName, count in pairs(uniqueSquads) do
		print(string.format("  Squad '%s': %d members", squadName, count))
	end

	print("=== END SQUAD DEBUG ===")
end

-- Alternative: Bind to a key for easier testing
concommand.Add("m9kr_debug_squads", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then
		print("[M9K:R] Squad debug requires admin privileges")
		return
	end

	PrintAllSquads()
end)

print("[M9K:R] Squad debug tool loaded")
print("[M9K:R] - Use 'm9kr_debug_squads' in console to see all NPC squad info")
print("[M9K:R] - Or type 'lua_run PrintAllSquads()' in server console")
