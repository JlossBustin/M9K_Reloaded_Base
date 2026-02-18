--[[
	M9K Reloaded - Centralized Weapon State Handler (CLIENT)

	Manages all CLIENT-side weapon state transitions, animations, and visual feedback:
	- ADS/Scope state management (ironsights, scope zoom)
	- Sprint state handling
	- Safety mode visual feedback
	- USE key idle state forcing
	- FOV transitions with smooth easing
	- Player animations for multiplayer visibility
	- Crosshair state management
	- Mouse sensitivity adjustments

	This centralizes all CLIENT-side logic that was previously scattered across
	weapon base shared.lua files with "if CLIENT then" blocks.

	State is synchronized from SERVER via networked variables (NWBool/NWInt):
	- Reloading (NWBool)
	- IsOnSafe (networked via SetIsOnSafe/GetIsOnSafe)
	- Ironsights (networked via SetIronsights/GetIronsights)
	- Sprint (networked via SetSprint/GetSprint)
]]--

M9KR = M9KR or {}
M9KR.WeaponState = M9KR.WeaponState or {}

-- State tracking per weapon entity
local weaponStates = {}

-- Constants for smooth transitions
local TRANSITION_TIME_FAST = 0.2   -- USE key, sprint
local TRANSITION_TIME_NORMAL = 0.2 -- ADS/Scope entry/exit (fast and responsive)
local TRANSITION_TIME_SAFETY = 0.25 -- Safety toggle



-- ADS (Aim Down Sights) sounds - universal for all weapons
local IRON_IN_SOUND = "m9k_indicators/ironin.wav"
local IRON_OUT_SOUND = "m9k_indicators/ironout.wav"

--[[
	Get or create weapon state
]]--
function M9KR.WeaponState.GetState(weapon)
	if not IsValid(weapon) then return nil end

	local entIndex = weapon:EntIndex()

	if not weaponStates[entIndex] then
		weaponStates[entIndex] = {
			-- Transition timing
			fovTransitionStart = 0,
			fovTransitionDuration = TRANSITION_TIME_NORMAL,
			fovStart = 0,
			fovTarget = 0,

			-- Visual state
			currentFOV = 0,

			-- CLIENT-side ADS/Sprint state (read by GetViewModelPosition)
			isInADS = false,
			isInSprint = false,

			-- Input tracking
			lastUseState = false,
			lastAttack2State = false,
			lastSpeedState = false,

			-- Animation state (for tracking transitions)
			lastIronsightsState = false,
			lastSprintState = false,
			lastSafetyState = false,

			-- Weapon type detection
			isScoped = false,
			scopeZoom = 4,
			isBoltAction = false,
			isShotgun = false,
			isAkimbo = false,
			canBeSilenced = false,

		}
	end

	return weaponStates[entIndex]
end

--[[
	Get CLIENT-side ADS/Sprint state for GetViewModelPosition
	Returns: isInADS, isInSprint
]]--
function M9KR.WeaponState.GetVisualState(weapon)
	if not IsValid(weapon) then return false, false end
	local state = M9KR.WeaponState.GetState(weapon)
	if not state then return false, false end
	return state.isInADS, state.isInSprint
end

--[[
	Cleanup invalid weapon states
]]--
hook.Add("Think", "M9KR_WeaponState_Cleanup", function()
	for entIndex, _ in pairs(weaponStates) do
		local ent = Entity(entIndex)
		if not IsValid(ent) then
			weaponStates[entIndex] = nil
		end
	end
end)

--[[
	Detect weapon type and special features
	Returns: isScoped, scopeZoom, isBoltAction, isShotgun, isAkimbo, canBeSilenced
]]--
local function DetectWeaponType(weapon)
	if not IsValid(weapon) then return false, 4, false, false, false, false end

	-- Detect scoped weapons
	local isScoped = weapon.Scoped or false
	local scopeZoom = 4

	if weapon.Secondary and weapon.Secondary.ScopeZoom then
		scopeZoom = weapon.Secondary.ScopeZoom
	end

	-- Detect bolt action weapons
	local isBoltAction = weapon.BoltAction or false

	-- Detect shotguns (tube-fed reload system)
	local isShotgun = false
	if weapon.Primary and weapon.Primary.ClipSize and weapon.Primary.ClipSize > 2 then
		-- Check if weapon has CanStartReload (indicator of incremental reload system)
		if weapon.CanStartReload ~= nil then
			isShotgun = true
		end
	end

	-- Detect akimbo weapons (dual wielding)
	local isAkimbo = weapon.Akimbo or false

	-- Detect silenced weapons
	local canBeSilenced = weapon.CanBeSilenced or false

	return isScoped, scopeZoom, isBoltAction, isShotgun, isAkimbo, canBeSilenced
end

--[[
	Smooth FOV transition using easing

	IMPORTANT: Does NOT call ply:SetFOV() - that would fight with CalcView!
	CalcView hook reads state.currentFOV and applies it to the view table.
]]--
local function UpdateFOVTransition(state, ply)
	if not IsValid(ply) then return end

	local elapsed = CurTime() - state.fovTransitionStart
	local t = math.Clamp(elapsed / state.fovTransitionDuration, 0, 1)

	-- Ease out cubic for smooth deceleration
	t = 1 - math.pow(1 - t, 3)

	local newFOV = Lerp(t, state.fovStart, state.fovTarget)

	-- If transition is complete and target was default FOV, set to exactly 0
	if t >= 1 and state.fovTarget == ply:GetFOV() then
		state.currentFOV = 0
	else
		state.currentFOV = newFOV
	end

	-- DO NOT call ply:SetFOV() here! CalcView hook handles FOV application.
end

--[[
	Start a FOV transition
]]--
local function StartFOVTransition(state, ply, targetFOV, duration)
	if not IsValid(ply) then return end

	-- If currentFOV is 0, we're at default FOV - use the player's actual default FOV
	local actualStartFOV = state.currentFOV
	if actualStartFOV == 0 then
		actualStartFOV = ply:GetFOV() -- Get player's default FOV (usually 75)
	end

	state.fovStart = actualStartFOV
	state.fovTarget = targetFOV == 0 and ply:GetFOV() or targetFOV
	state.fovTransitionStart = CurTime()
	state.fovTransitionDuration = duration or TRANSITION_TIME_NORMAL
end

--[[
	Handle USE key idle state forcing

	When USE is held:
	- Force exit from ADS/Scope/Sprint
	- Show viewmodel (for scoped weapons)
	- Restore normal FOV
	- Restore normal mouse sensitivity

	When USE is released:
	- If ATTACK2 still held, smoothly re-enter ADS/Scope
]]--
local function HandleUseKeyState(weapon, ply, state)
	if not IsValid(weapon) or not IsValid(ply) then return end

	local useDown = ply:KeyDown(IN_USE)
	local attack2Down = ply:KeyDown(IN_ATTACK2)
	local speedDown = ply:KeyDown(IN_SPEED)
	local isReloading = weapon:GetNWBool("Reloading", false)
	local isSafe = weapon.GetIsOnSafe and weapon:GetIsOnSafe() or false
	local isOnGround = ply:IsOnGround()

	-- Check if player is pressing movement keys (for immediate sprint exit when keys released)
	local isPressingMovement = ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT)

	-- Check if player is actually sprinting (not just holding sprint key)
	local isActuallySprinting = speedDown and isOnGround and ply:GetVelocity():Length2D() > 20 and isPressingMovement

	-- USE key just pressed - force exit ADS/Scope and idle state
	if useDown and not state.lastUseState and not isSafe then
		-- Check CLIENT-side ADS state instead of networked variable
		if state.isInADS then
			-- Exit ADS/Scope immediately
			StartFOVTransition(state, ply, 0, TRANSITION_TIME_FAST)
			state.isInADS = false

			-- Show viewmodel (critical for scoped weapons)
		end
	end

	-- USE key just released - allow re-entering ADS/Scope if ATTACK2 still held
	if not useDown and state.lastUseState then
		if attack2Down and not isActuallySprinting and not isReloading then
			-- Re-enter ADS/Scope
			local targetFOV = 0

			if state.isScoped then
				-- Scoped weapon - zoom in and hide viewmodel
				targetFOV = 75 / state.scopeZoom
			elseif weapon.Secondary and weapon.Secondary.IronFOV then
				-- Non-scoped weapon with iron sights
				targetFOV = weapon.Secondary.IronFOV
			end

			StartFOVTransition(state, ply, targetFOV, TRANSITION_TIME_NORMAL)
			state.isInADS = true  -- CRITICAL: Set ADS state flag so viewmodel positioning works
		end
	end

	state.lastUseState = useDown
end

--[[
	Handle ADS/Scope state transitions
]]--
local function HandleADSState(weapon, ply, state)
	if not IsValid(weapon) or not IsValid(ply) then return end

	local attack2Down = ply:KeyDown(IN_ATTACK2)
	local useDown = ply:KeyDown(IN_USE)
	local speedDown = ply:KeyDown(IN_SPEED)
	local isReloading = weapon:GetNWBool("Reloading", false)
	local isSafe = weapon.GetIsOnSafe and weapon:GetIsOnSafe() or false
	local isOnGround = ply:IsOnGround()

	-- Check if player is pressing movement keys (for immediate sprint exit when keys released)
	local isPressingMovement = ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT)

	-- Check if player is actually sprinting (not just holding sprint key while standing still)
	local isActuallySprinting = speedDown and isOnGround and ply:GetVelocity():Length2D() > 20 and isPressingMovement

	-- Check if player is sprint-jumping (SPEED held while in air)
	local isSprintJumping = speedDown and not isOnGround

	-- ATTACK2 just pressed (not blocked by USE/actually sprinting/Reload/Safety/SprintJump)
	if attack2Down and not state.lastAttack2State and not useDown and not isActuallySprinting and not isReloading and not isSafe and not isSprintJumping then
		-- Enter ADS/Scope
		local targetFOV = 0

		if state.isScoped then
			-- Scoped weapon - zoom in and hide viewmodel
			targetFOV = 75 / state.scopeZoom
		elseif weapon.Secondary and weapon.Secondary.IronFOV then
			-- Non-scoped weapon with iron sights
			targetFOV = weapon.Secondary.IronFOV
		end

		StartFOVTransition(state, ply, targetFOV, TRANSITION_TIME_NORMAL)

		-- Set CLIENT-side state (read by GetViewModelPosition)
		state.isInADS = true

		-- Play ADS in sound
		weapon:EmitSound(IRON_IN_SOUND, 50, 100)
	end

	-- ATTACK2 just released - exit ADS/Scope (only if we were actually in ADS)
	if not attack2Down and state.lastAttack2State and not useDown and state.isInADS then
		-- Exit ADS/Scope
		StartFOVTransition(state, ply, 0, TRANSITION_TIME_FAST)

		-- Clear CLIENT-side state
		state.isInADS = false

		-- Play ADS out sound
		weapon:EmitSound(IRON_OUT_SOUND, 50, 100)
	end

	-- Force exit ADS/Scope when player actually starts sprinting (not just holding sprint key)
	if isActuallySprinting and state.isInADS and not useDown then
		StartFOVTransition(state, ply, 0, TRANSITION_TIME_FAST)

		-- Clear CLIENT-side state
		state.isInADS = false

		-- Remember that ATTACK2 was held during sprint (for re-entering ADS after sprint)
		state.attack2HeldDuringSprint = attack2Down
	end

	-- Remember if ATTACK2 is pressed DURING actual sprint (even if not in ADS yet)
	-- This handles the case: Sprint -> Press ATTACK2 -> Release Sprint -> Should enter ADS
	if isActuallySprinting and attack2Down and not state.isInADS and not useDown then
		state.attack2HeldDuringSprint = true
	end

	-- Re-enter ADS when sprint ends if ATTACK2 was held during sprint
	if not isActuallySprinting and state.attack2HeldDuringSprint and attack2Down and not useDown and not isReloading and not isSafe then
		-- Enter ADS/Scope with slower transition from sprint for smooth animation
		local targetFOV = 0

		if state.isScoped then
			-- Scoped weapon - zoom in and hide viewmodel
			targetFOV = 75 / state.scopeZoom
		elseif weapon.Secondary and weapon.Secondary.IronFOV then
			-- Non-scoped weapon with iron sights
			targetFOV = weapon.Secondary.IronFOV
		end

		-- Use slower transition (0.35s) when returning from sprint for smoother animation
		StartFOVTransition(state, ply, targetFOV, 0.35)
		state.isInADS = true

		weapon:EmitSound(IRON_IN_SOUND, 50, 100)

		state.attack2HeldDuringSprint = false
	end

	-- Clear the sprint-ADS flag when ATTACK2 released
	if not attack2Down then
		state.attack2HeldDuringSprint = false
	end

	state.lastAttack2State = attack2Down
end

--[[
	Handle Sprint state
]]--
local function HandleSprintState(weapon, ply, state)
	if not IsValid(weapon) or not IsValid(ply) then return end

	local speedDown = ply:KeyDown(IN_SPEED)
	local isSafe = weapon.GetIsOnSafe and weapon:GetIsOnSafe() or false
	local isReloading = weapon:GetNWBool("Reloading", false)
	local attack2Down = ply:KeyDown(IN_ATTACK2)
	local isOnGround = ply:IsOnGround()

	-- Check if player is pressing movement keys (for immediate sprint exit when keys released)
	local isPressingMovement = ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT)

	-- Determine if player SHOULD be sprinting based on current conditions
	-- Sprint is allowed when: SPEED held, ON GROUND, MOVING, PRESSING MOVEMENT KEYS, not ALREADY in ADS, safety off
	-- Sprint during reload is allowed - maintains sprint positioning for smooth transitions
	-- Sprint-jumping exits sprint to idle position so player can shoot
	-- Note: Movement key check ensures immediate sprint exit when player stops moving (not waiting for velocity decay)
	local isActuallySprinting = speedDown and isOnGround and ply:GetVelocity():Length2D() > 20 and isPressingMovement
	local shouldSprint = isActuallySprinting and not state.isInADS and not isSafe

	-- Detect sprint-jumping (SPEED held but not on ground) - allows shooting during jump
	local isSprintJumping = speedDown and not isOnGround

	-- Continuously enforce sprint state
	if shouldSprint and not state.isInSprint then
		-- Enter sprint
		state.isInSprint = true
		state.isInADS = false
		weapon.SprintJumping = false
	elseif not shouldSprint and state.isInSprint then
		-- Exit sprint (goes to idle when jumping, or when conditions no longer met)
		state.isInSprint = false

		-- Immediately reset viewbob intensities to prevent aggressive bobbing during sprint exit
		-- These variables smoothly lerp to 0 in weapon bases, but we want instant reset for clean transition
		weapon.SprintIntensity = 0
		weapon.WalkIntensity = 0
	end

	-- Continuously set SprintJumping flag when player is sprint-jumping
	-- This allows shooting mid-air during sprint-jumps
	if isSprintJumping then
		weapon.SprintJumping = true
	else
		weapon.SprintJumping = false
	end

	state.lastSpeedState = speedDown
end

--[[
	Handle Safety state visual feedback
]]--
local function HandleSafetyState(weapon, ply, state)
	if not IsValid(weapon) or not IsValid(ply) then return end

	local isSafe = weapon.GetIsOnSafe and weapon:GetIsOnSafe() or false

	-- Safety state changed
	if isSafe ~= state.lastSafetyState then
		if isSafe then
			-- Engaging safety - force exit ADS/Scope
			StartFOVTransition(state, ply, 0, TRANSITION_TIME_SAFETY)
			state.isInADS = false
		end

		-- Update hold type for player animations (handled by m9kr_safety_handler.lua)
	end

	state.lastSafetyState = isSafe
end

--[[
	Handle Reload state
	Re-enter ADS/Scope after reload completes if ATTACK2 still held
	Also handles sprint state after reload completes
]]--
local function HandleReloadState(weapon, ply, state)
	if not IsValid(weapon) or not IsValid(ply) then return end

	local isReloading = weapon:GetNWBool("Reloading", false)
	local attack2Down = ply:KeyDown(IN_ATTACK2)
	local speedDown = ply:KeyDown(IN_SPEED)
	local useDown = ply:KeyDown(IN_USE)
	local isOnGround = ply:IsOnGround()

	-- Check if player is pressing movement keys (for immediate sprint exit when keys released)
	local isPressingMovement = ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT)

	-- Check if player is actually sprinting (not just holding sprint key)
	local isActuallySprinting = speedDown and isOnGround and ply:GetVelocity():Length2D() > 20 and isPressingMovement

	-- Just STARTED reloading - force exit ADS/Scope
	if isReloading and not state.lastReloadState then
		-- Force exit ADS - return FOV to normal
		StartFOVTransition(state, ply, 0, TRANSITION_TIME_FAST)
		state.isInADS = false

		-- Sprint state is managed by HandleSprintState based on SPEED key + reload state
		-- Don't manually clear sprint here - let sprint handler determine if player should sprint

	end

	-- Just finished reloading - check if we should re-enter ADS/Scope
	if not isReloading and state.lastReloadState then
		if attack2Down and not useDown and not isActuallySprinting then
			-- Re-enter ADS/Scope after reload
			local targetFOV = 0

			if state.isScoped then
				-- Scoped weapon - zoom in and hide viewmodel
				targetFOV = 75 / state.scopeZoom
			elseif weapon.Secondary and weapon.Secondary.IronFOV then
				-- Non-scoped weapon with iron sights
				targetFOV = weapon.Secondary.IronFOV
			end

			StartFOVTransition(state, ply, targetFOV, TRANSITION_TIME_NORMAL)
			state.isInADS = true
		end
		-- Sprint re-entry is now handled by HandleSprintState continuously
		-- No need to manually manage sprint here
	end

	state.lastReloadState = isReloading
end

--[[
	Update player animations for third-person visibility
]]--
local function UpdatePlayerAnimations(weapon, ply, state)
	if not IsValid(weapon) or not IsValid(ply) then return end

	-- Player animation handling is complex and weapon-specific
	-- Most animation handling is done via CalcMainActivity in weapon bases
	-- This is just a hook point for future expansion
end

--[[
	Main Think hook - handles all weapon state updates
]]--
hook.Add("Think", "M9KR_WeaponState_Update", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	-- Skip updates when player is not alive
	if not ply:Alive() then return end

	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return end

	-- Only handle M9K weapons (carby_gun_base, carby_shotty_base, carby_scoped_base)
	if not weapon.Base or not M9KR.WeaponBases[weapon.Base] then
		return
	end

	local state = M9KR.WeaponState.GetState(weapon)
	if not state then return end

	-- Update weapon type detection (all special features)
	state.isScoped, state.scopeZoom, state.isBoltAction, state.isShotgun, state.isAkimbo, state.canBeSilenced = DetectWeaponType(weapon)

	-- Handle all state transitions
	HandleUseKeyState(weapon, ply, state)
	HandleADSState(weapon, ply, state)
	HandleSprintState(weapon, ply, state)
	HandleSafetyState(weapon, ply, state)
	HandleReloadState(weapon, ply, state)
	UpdatePlayerAnimations(weapon, ply, state)

	-- Update FOV transition
	UpdateFOVTransition(state, ply)

	-- Synchronize state flags to weapon properties
	-- weapon.isScoped = true when scoped weapon is currently in ADS
	weapon.isScoped = state.isScoped and state.isInADS

	-- Hide viewmodel when scoped weapon is in ADS
	-- Muzzle flash/tracer effects will use fallback positioning (below scope crosshair)
	if state.isScoped and state.isInADS then
		weapon.ShouldDrawViewModel = false
	else
		weapon.ShouldDrawViewModel = true
	end
end)

--[[
	Mouse Sensitivity Adjustment:
	Handled by SWEP:AdjustMouseSensitivity() in carby_scoped_base/shared.lua
	This is the proper engine-supported method for per-weapon sensitivity adjustment.
]]--

--[[
	Hook: CalcView for smooth FOV transitions

	This ensures FOV transitions are smooth and not overridden by other systems.
	IMPORTANT: This hook now ONLY modifies FOV, allowing weapon-specific CalcView
	effects (scope sway, recoil, custom view angles) to work properly.

	If a weapon defines its own CalcView, it will run AFTER this one, so weapon-specific
	view modifications will take priority.
]]--
hook.Add("CalcView", "M9KR_WeaponState_CalcView", function(ply, origin, angles, fov)
	if not IsValid(ply) or ply ~= LocalPlayer() then return end

	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return end

	-- Only handle M9K weapons
	if not weapon.Base or not M9KR.WeaponBases[weapon.Base] then
		return
	end

	local state = M9KR.WeaponState.GetState(weapon)
	if not state then return end

	-- Apply FOV if we have an active transition or non-default FOV
	-- During transitions, always apply the FOV
	-- After transition completes to default, currentFOV will be set to 0
	if state.currentFOV and state.currentFOV > 0 then
		local view = {
			origin = origin,
			angles = angles,
			fov = state.currentFOV
		}
		return view
	end

	-- If currentFOV is 0 or nil, don't return anything (use default game FOV)
end)

--[[
	Hook: Weapon switch - reset state
]]--
hook.Add("PlayerSwitchWeapon", "M9KR_WeaponState_WeaponSwitch", function(ply, oldWeapon, newWeapon)
	if not IsValid(ply) or ply ~= LocalPlayer() then return end

	-- Reset FOV state when switching weapons (CalcView will apply it)
	if IsValid(oldWeapon) then
		local state = M9KR.WeaponState.GetState(oldWeapon)
		if state then
			-- Reset FOV state - CalcView will handle returning to default
			state.currentFOV = 0
			state.fovTarget = 0
		end
	end

	-- Viewmodel visibility will be handled by PreDrawViewModel in weapon base
end)

--[[
	Hook: Initialize weapon state on deploy
]]--
hook.Add("Think", "M9KR_WeaponState_InitOnDeploy", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return end

	local state = M9KR.WeaponState.GetState(weapon)
	if not state then return end

	-- Initialize lastReloadState if not set
	if state.lastReloadState == nil then
		state.lastReloadState = weapon:GetNWBool("Reloading", false)
	end
end)

-- Precache ADS sounds
util.PrecacheSound(IRON_IN_SOUND)
util.PrecacheSound(IRON_OUT_SOUND)

print("[M9K:R] Weapon state handler loaded")
