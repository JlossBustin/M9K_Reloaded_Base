--[[
	M9K Reloaded - Fire Mode Switching Handler

	Handles CLIENT-side detection of fire mode switching input (USE + RELOAD)
	and networks it reliably to the SERVER for execution.

	This solves the issue where SERVER-side KeyPressed() detection is unreliable
	for USE + RELOAD combinations due to network latency.
]]--

if CLIENT then
	-- Network string for fire mode switching
	net.Receive("M9KR_SelectFireMode_Response", function()
		local newMode = net.ReadString()
		local weaponName = net.ReadString()

		-- HUD/chat already displays fire mode changes, no additional notification needed
	end)

	-- Track last RELOAD key state for each weapon to detect press
	local lastReloadState = {}

	-- Detect fire mode switching input on CLIENT
	hook.Add("Think", "M9KR_FireModeSwitchDetection", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		local weapon = ply:GetActiveWeapon()
		if not IsValid(weapon) then return end

		-- Check if weapon has the fire mode system (SelectFireMode function)
		if not weapon.SelectFireMode then return end

		-- Get weapon ID for tracking
		local weaponID = weapon:EntIndex()

		-- Track RELOAD key state
		local reloadDown = ply:KeyDown(IN_RELOAD)
		local wasReloadDown = lastReloadState[weaponID] or false
		lastReloadState[weaponID] = reloadDown

		-- Detect RELOAD key press (transition from up to down) while USE is held
		if reloadDown and not wasReloadDown and ply:KeyDown(IN_USE) then
			-- Check if weapon can switch fire modes
			local modeCount = weapon.GetFireModeCount and weapon:GetFireModeCount() or 0

			if modeCount > 1 then
				-- Check if weapon is on safe
				local isOnSafe = weapon.GetIsOnSafe and weapon:GetIsOnSafe() or false

				if not isOnSafe then
					-- Check if weapon is not reloading
					local isReloading = weapon:GetNWBool("Reloading", false)

					if not isReloading then
						-- Check if SHIFT is held (safety toggle uses SHIFT + E + R)
						-- Don't switch fire mode when SHIFT is held
						if ply:KeyDown(IN_SPEED) then return end

						-- Check if safety was recently toggled (prevents race condition)
						-- When exiting safety with E + R, we don't want to also switch fire mode
						-- Uses timestamp check instead of LastSafetyState which can be stale
						-- depending on Think hook execution order
						if weapon.SafetyToggleTime and (CurTime() - weapon.SafetyToggleTime) < 0.5 then
							return
						end

						-- Check cooldown
						if not weapon.M9KR_NextFireSelectClient or CurTime() >= weapon.M9KR_NextFireSelectClient then
							weapon.M9KR_NextFireSelectClient = CurTime() + 0.5
							-- Send fire mode switch request to server
							net.Start("M9KR_SelectFireMode_Request")
							net.SendToServer()
						end
					end
				end
			end
		end
	end)
end

if SERVER then
	-- Network string for fire mode switching
	util.AddNetworkString("M9KR_SelectFireMode_Request")
	util.AddNetworkString("M9KR_SelectFireMode_Response")

	-- Receive fire mode switch request from CLIENT
	net.Receive("M9KR_SelectFireMode_Request", function(len, ply)
		if not IsValid(ply) then return end

		local weapon = ply:GetActiveWeapon()
		if not IsValid(weapon) then return end

		-- Check if weapon has fire mode system
		if not weapon.SelectFireMode then return end

		-- Verify weapon can switch fire modes
		local modeCount = weapon.GetFireModeCount and weapon:GetFireModeCount() or 0

		if modeCount > 1 then
			-- Verify weapon is not on safe and not reloading
			local isOnSafe = weapon.GetIsOnSafe and weapon:GetIsOnSafe() or false

			if not isOnSafe then
				-- Reject if safety was recently toggled (E+R used for safety, not fire mode)
				if weapon.SafetyToggleTime and (CurTime() - weapon.SafetyToggleTime) < 0.5 then return end

				local isReloading = weapon:GetNWBool("Reloading", false)

				if not isReloading then
					-- Call SelectFireMode (works for all weapon bases)
					weapon:SelectFireMode()

					-- Get the new fire mode and send response to client
					local newMode = weapon:GetCurrentFireMode() or "unknown"
					local weaponClass = weapon:GetClass() or "weapon"

					net.Start("M9KR_SelectFireMode_Response")
					net.WriteString(newMode)
					net.WriteString(weaponClass)
					net.Send(ply)
				end
			end
		end
	end)
end
