--[[
	M9K Reloaded - Squad Member Tracker (Server-Side)

	Tracks NPC squad members following players and networks the count to clients
	for display in the custom HUD with icon-based display.

	Uses GMod's native squad system - NPCs that join the player's squad are
	assigned to the "player_squad" squad name by the engine.
]]--

-- NPC type classification for icons
local function GetNPCType(npc)
	local class = npc:GetClass()

	-- Check if citizen is a medic (has healthkit weapon or healing capability)
	if class == "npc_citizen" then
		-- Check model path for medic indicators
		local model = npc:GetModel()
		if model then
			model = model:lower()
			-- Check for "group##m" pattern (e.g., group01m, group02m, group03m) - the "m" denotes medic
			if string.find(model, "group%d+m") then
				return "medic"
			end
			-- Also check for explicit medic/odessa references
			if string.find(model, "odessa") or string.find(model, "medic") then
				return "medic"
			end
		end

		-- Check all weapons in NPC's inventory (fallback method)
		local weapons = npc:GetWeapons()
		for _, weapon in ipairs(weapons) do
			if IsValid(weapon) and weapon:GetClass() == "weapon_medkit" then
				return "medic"
			end
		end

		return "citizen"
	end

	-- Special NPCs
	if class == "npc_alyx" then return "alyx" end
	if class == "npc_barney" then return "barney" end
	if class == "npc_monk" then return "monk" end
	if class == "npc_vortigaunt" then return "vortigaunt" end

	-- Default to citizen for any other followable NPC
	return "citizen"
end

-- Update squad counts for all players every 0.5 seconds
timer.Create("M9KR_UpdateSquadCounts", 0.5, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() then
			-- Get all NPCs in the "player_squad" squad
			local squadMembers = ai.GetSquadMembers("player_squad")
			local squadData = {
				citizen = 0,
				medic = 0,
				alyx = 0,
				barney = 0,
				monk = 0,
				vortigaunt = 0
			}

			-- Count NPCs by type
			if squadMembers then
				for _, npc in ipairs(squadMembers) do
					if IsValid(npc) and npc:Health() > 0 then
						local npcType = GetNPCType(npc)
						squadData[npcType] = squadData[npcType] + 1
					end
				end
			end

			-- Network the squad data as JSON string
			ply:SetNWString("M9KR_SquadData", util.TableToJSON(squadData))

			-- Also keep total count for backwards compatibility
			local totalCount = 0
			for _, count in pairs(squadData) do
				totalCount = totalCount + count
			end
			ply:SetNWInt("M9KR_SquadCount", totalCount)
		end
	end
end)

print("[M9K:R] Squad tracker loaded")
