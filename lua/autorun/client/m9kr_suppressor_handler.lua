--[[
	M9K Reloaded - Client-Side Suppressor State Handler

	Handles visual aspects of suppressor attachment/detachment (animations, model swaps, etc.)
	Watches the networked IsSuppressed variable and responds with smooth transitions.

	This separates visual CLIENT logic from SERVER game logic to prevent desync issues.
]]--

M9KR = M9KR or {}
M9KR.Suppressor = M9KR.Suppressor or {}

-- ConVar to enable/disable suppressor visual handling
CreateClientConVar("m9kr_suppressor_enabled", "1", true, false, "Enable M9K Reloaded suppressor visual handling", 0, 1)

-- Track suppressor states per weapon for animation sync
M9KR.Suppressor.WeaponStates = M9KR.Suppressor.WeaponStates or {}

--[[
	Get or create weapon state tracker
]]--
function M9KR.Suppressor.GetWeaponState(weapon)
	if not IsValid(weapon) then return nil end

	local entIndex = weapon:EntIndex()
	if not M9KR.Suppressor.WeaponStates[entIndex] then
		M9KR.Suppressor.WeaponStates[entIndex] = {
			lastSuppressorState = false,
			isAnimating = false,
			animEndTime = 0,
		}
	end

	return M9KR.Suppressor.WeaponStates[entIndex]
end

--[[
	Clean up old weapon states
]]--
hook.Add("Think", "M9KR.Suppressor.CleanupStates", function()
	for entIndex, state in pairs(M9KR.Suppressor.WeaponStates) do
		local ent = Entity(entIndex)
		if not IsValid(ent) then
			M9KR.Suppressor.WeaponStates[entIndex] = nil
		end
	end
end)

--[[
	Update weapon visual state based on networked suppressor variables
	Called from weapon Think or animation hooks
]]--
function M9KR.Suppressor.UpdateWeaponState(weapon)
	if not IsValid(weapon) then return end
	if not weapon.GetIsSuppressed then return end -- Not a M9KR weapon

	-- Check if suppressor handling is enabled
	if not GetConVar("m9kr_suppressor_enabled"):GetBool() then return end

	local state = M9KR.Suppressor.GetWeaponState(weapon)
	if not state then return end

	local isSuppressed = weapon:GetIsSuppressed()
	local isAttaching = (weapon.GetIsAttachingSuppressor and weapon:GetIsAttachingSuppressor()) or false
	local isDetaching = (weapon.GetIsDetachingSuppressor and weapon:GetIsDetachingSuppressor()) or false

	-- Track animation state
	if isAttaching or isDetaching then
		if not state.isAnimating then
			state.isAnimating = true
			state.animEndTime = (weapon.GetSuppressorAnimEndTime and weapon:GetSuppressorAnimEndTime()) or 0
		end
	else
		if state.isAnimating and CurTime() >= state.animEndTime then
			state.isAnimating = false
		end
	end

	-- Detect state change
	if isSuppressed ~= state.lastSuppressorState then
		state.lastSuppressorState = isSuppressed
	end

	return state
end

--[[
	Check if weapon is currently animating suppressor attach/detach
]]--
function M9KR.Suppressor.IsAnimating(weapon)
	if not IsValid(weapon) then return false end

	local state = M9KR.Suppressor.GetWeaponState(weapon)
	if not state then return false end

	return state.isAnimating
end

print("[M9K:R] Client-side suppressor handler loaded")
