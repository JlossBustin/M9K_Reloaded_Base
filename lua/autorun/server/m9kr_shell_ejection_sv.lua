--[[
	M9K Reloaded - Server-Side Shell Ejection Broadcaster

	Broadcasts shell ejection events to all clients when players fire weapons.
	Clients use this to spawn shells on other players' worldmodels.
]]--

util.AddNetworkString("M9KR_ShellEject")

--[[
	Hook into EntityFireBullets to detect when players shoot
	Broadcasts to all clients so they can spawn worldmodel shells
]]--
hook.Add("EntityFireBullets", "M9KR_ShellEjection_Broadcast", function(entity, data)
	if not IsValid(entity) or not entity:IsPlayer() then return end

	local weapon = entity:GetActiveWeapon()
	if not IsValid(weapon) or not weapon.ShellModel then return end

	-- Broadcast shell ejection event to all clients
	net.Start("M9KR_ShellEject")
		net.WriteEntity(entity)
		net.WriteString(weapon:GetClass())
	net.Broadcast()
end)

print("[M9K:R] Server-side shell ejection broadcaster loaded")
