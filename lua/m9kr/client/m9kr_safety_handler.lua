--[[
	M9K Reloaded - Client-Side Safety State Handler

	Handles visual aspects of weapon safety state (viewmodel positioning, hold types, etc.)
	Watches the networked IsOnSafe variable and responds with smooth transitions.

	This separates visual CLIENT logic from SERVER game logic to prevent desync issues.
]]--

M9KR = M9KR or {}
M9KR.Safety = M9KR.Safety or {}

-- ConVar to enable/disable safety system visual handling
CreateClientConVar("m9kr_safety_enabled", "1", true, false, "Enable M9K Reloaded safety system visual handling", 0, 1)

-- Track safety states per weapon for smooth transitions
M9KR.Safety.WeaponStates = M9KR.Safety.WeaponStates or {}

--[[
	Get or create weapon state tracker
]]--
function M9KR.Safety.GetWeaponState(weapon)
	if not IsValid(weapon) then return nil end

	if not M9KR.Safety.WeaponStates[weapon] then
		M9KR.Safety.WeaponStates[weapon] = {
			lastSafetyState = false,
			transitionStartTime = 0,
			originalHoldType = nil,
		}
	end

	return M9KR.Safety.WeaponStates[weapon]
end

--[[
	Clean up old weapon states
]]--
hook.Add("Think", "M9KR.Safety.CleanupStates", function()
	for weapon, state in pairs(M9KR.Safety.WeaponStates) do
		if not IsValid(weapon) then
			M9KR.Safety.WeaponStates[weapon] = nil
		end
	end
end)

--[[
	Update weapon visual state based on networked safety variable
	Called from Think hook to continuously sync hold types
]]--
function M9KR.Safety.UpdateWeaponState(weapon)
	if not IsValid(weapon) then return end
	if not weapon.GetIsOnSafe then return end -- Not a M9KR weapon

	-- Check if safety handling is enabled
	if not GetConVar("m9kr_safety_enabled"):GetBool() then return end

	local state = M9KR.Safety.GetWeaponState(weapon)
	if not state then return end

	local isSafe = weapon:GetIsOnSafe()

	-- Initialize or refresh original hold type
	-- Always check weapon.OriginalHoldType if available to handle weapon switches
	if not state.originalHoldType or state.originalHoldType == "passive" or state.originalHoldType == "normal" then
		-- Get the weapon's base hold type from weapon definition
		if weapon.OriginalHoldType and weapon.OriginalHoldType ~= "passive" and weapon.OriginalHoldType ~= "normal" then
			-- Weapon has a defined OriginalHoldType, use it
			state.originalHoldType = weapon.OriginalHoldType
		elseif not state.originalHoldType then
			-- First time initialization - check current hold type
			local currentHoldType = weapon.HoldType
			if currentHoldType ~= "passive" and currentHoldType ~= "normal" then
				state.originalHoldType = currentHoldType
			else
				-- Fallback to ar2 for rifles, pistol for pistols
				state.originalHoldType = "ar2"
			end
		end
	end

	-- Detect state change
	if isSafe ~= state.lastSafetyState then
		state.lastSafetyState = isSafe
		state.transitionStartTime = CurTime()

		-- When transitioning OUT of safety, try to update original hold type from weapon definition
		-- This ensures we restore to the correct hold type even if it changed
		if not isSafe then
			-- If weapon has a defined OriginalHoldType, use that
			if weapon.OriginalHoldType and weapon.OriginalHoldType ~= "passive" then
				state.originalHoldType = weapon.OriginalHoldType
			-- Otherwise, if the weapon's current HoldType is not passive, update to that
			elseif weapon.HoldType ~= "passive" and weapon.HoldType ~= "normal" then
				state.originalHoldType = weapon.HoldType
			end
			-- If both are passive/normal, keep existing originalHoldType as fallback

			-- FORCE immediate hold type update when disengaging safety
			-- This ensures third-person view updates immediately
			local targetHoldType = state.originalHoldType or "ar2"
			weapon:SetHoldType(targetHoldType)
		end
	end

	-- Continuously enforce hold type based on safety state (prevents desync)
	if isSafe then
		-- Engaging safety - determine safe hold type based on weapon type
		-- Pistols/revolvers use 'normal', rifles use 'passive'
		local safeHoldType = "passive"
		if state.originalHoldType == "pistol" or state.originalHoldType == "revolver" then
			safeHoldType = "normal"
		end

		if weapon.HoldType ~= safeHoldType then
			weapon:SetHoldType(safeHoldType)
		end
	else
		-- Disengaging safety - restore original hold type
		local targetHoldType = state.originalHoldType or "ar2"
		if weapon.HoldType ~= targetHoldType then
			weapon:SetHoldType(targetHoldType)
		end
	end

	return state
end

--[[
	Think hook: Update all M9KR weapons' safety states
]]--
hook.Add("Think", "M9KR.Safety.UpdateWeapons", function()
	if not GetConVar("m9kr_safety_enabled"):GetBool() then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	-- Update active weapon
	local weapon = ply:GetActiveWeapon()
	if IsValid(weapon) and weapon.GetIsOnSafe then
		M9KR.Safety.UpdateWeaponState(weapon)
	end

	-- Also update all weapons on other players in view (for third person)
	for _, otherPly in ipairs(player.GetAll()) do
		if otherPly ~= ply and IsValid(otherPly) then
			local otherWeapon = otherPly:GetActiveWeapon()
			if IsValid(otherWeapon) and otherWeapon.GetIsOnSafe then
				M9KR.Safety.UpdateWeaponState(otherWeapon)
			end
		end
	end
end)

--[[
	Get safety transition multiplier for smooth viewmodel animations
	Returns 0-1 value for lerping viewmodel position
]]--
function M9KR.Safety.GetTransitionMul(weapon)
	if not IsValid(weapon) then return 0 end
	if not weapon.GetIsOnSafe then return 0 end

	local state = M9KR.Safety.GetWeaponState(weapon)
	if not state then return 0 end

	local isSafe = weapon:GetIsOnSafe()
	if not isSafe then return 0 end -- Not in safety mode

	-- Calculate smooth transition multiplier
	local transitionTime = 0.25 -- Fast transition (IRONSIGHT_TIME * 0.5)
	local elapsed = CurTime() - state.transitionStartTime
	local mul = math.Clamp(elapsed / transitionTime, 0, 1)

	return mul
end

print("[M9K:R] Client-side safety handler loaded")
