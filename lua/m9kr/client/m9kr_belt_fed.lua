--[[
	M9K Reloaded - Belt-Fed Weapon Support

	Supports THREE belt display methods:

	1. BODYGROUP-BASED (like Ameli):
	   - SWEP.BeltBG (bodygroup index, e.g., 1)
	   - SWEP.BeltMax (total bodygroup count, e.g., 12 for bodygroups 0-11)
	   - SWEP.BeltHideTime (seconds into reload when old belt hides)
	   - SWEP.BeltShowTime (seconds into reload when new belt shows)

	2. BONE-BASED (like MG4):
	   - SWEP.BeltChain (table mapping ammo thresholds to bone names)
	     Example: { [0] = "j_bullet1", [1] = "j_bullet2", ... }
	   - Bones are scaled to 0 when ammo <= threshold

	3. MULTI-BODYGROUP (like Stoner 63):
	   - SWEP.BeltBodygroups (table mapping ammo thresholds to bodygroup indices)
	     Example: { [0] = 1, [1] = 2, [2] = 3, ... }
	   - Each bodygroup is set to 1 (blank) when ammo <= threshold

	Optional empty reload timing (for weapons with different empty/tactical reload animations):
	   - SWEP.BeltHideTimeEmpty (seconds into empty reload when old belt hides)
	   - SWEP.BeltShowTimeEmpty (seconds into empty reload when new belt shows)
]]--

M9KR = M9KR or {}
M9KR.BeltFed = M9KR.BeltFed or {}
M9KR.BeltFed.Disabled = false
M9KR.BeltFed.ReloadStartTime = M9KR.BeltFed.ReloadStartTime or {}  -- Track reload start time per weapon
M9KR.BeltFed.ReloadWasEmpty = M9KR.BeltFed.ReloadWasEmpty or {}   -- Track if reload started with empty clip
M9KR.BeltFed.BoneCache = M9KR.BeltFed.BoneCache or {}  -- Cache bone indices per weapon class
M9KR.BeltFed.LastWeaponClass = nil    -- Track last active weapon CLASS to detect swaps
M9KR.BeltFed.LastViewModelModel = nil  -- Track viewmodel's actual model path
M9KR.BeltFed.ManipulatedBones = M9KR.BeltFed.ManipulatedBones or {} -- Track bone IDs we've manipulated for cleanup
M9KR.BeltFed.NeedsBoneReset = false -- Flag to trigger bone reset in PreDrawViewModel

--[[
	Update bone-based belt (like MG4)
	Scales bullet bones to 0 when ammo is at or below their threshold
]]--
local function UpdateBoneBelt(vm, weapon, showAll)
	local beltChain = weapon.BeltChain
	if not beltChain then return end

	local clip = weapon:Clip1()

	for threshold, boneName in pairs(beltChain) do
		local boneID = vm:LookupBone(boneName)
		if boneID and boneID >= 0 then
			-- Track this bone ID for cleanup on weapon swap
			M9KR.BeltFed.ManipulatedBones[boneID] = true

			if showAll or clip > threshold then
				-- Show bullet
				vm:ManipulateBoneScale(boneID, Vector(1, 1, 1))
			else
				-- Hide bullet
				vm:ManipulateBoneScale(boneID, Vector(0, 0, 0))
			end
		end
	end
end

--[[
	Update bodygroup-based belt (like Ameli)
]]--
local function UpdateBodygroupBelt(vm, weapon, bodygroup)
	vm:SetBodygroup(weapon.BeltBG, bodygroup)
end

--[[
	Update multi-bodygroup belt (like Stoner 63)
	Each bullet is a separate bodygroup with states: 0=visible, 1=blank
]]--
local function UpdateMultiBodygroupBelt(vm, weapon, showAll)
	local beltBodygroups = weapon.BeltBodygroups
	if not beltBodygroups then return end

	local clip = weapon:Clip1()

	for threshold, bgIndex in pairs(beltBodygroups) do
		if showAll or clip > threshold then
			-- Show bullet (bodygroup state 0)
			vm:SetBodygroup(bgIndex, 0)
		else
			-- Hide bullet (bodygroup state 1 = blank)
			vm:SetBodygroup(bgIndex, 1)
		end
	end
end

--[[
	Helper function to reset all bone manipulations on a viewmodel
	Resets scale, position, and angles to defaults
]]--
local function ResetAllBones(vm)
	if not IsValid(vm) then return end
	local boneCount = vm:GetBoneCount() or 0
	-- Reset a large range of bones to ensure we cover all possible indices
	for boneID = 0, math.max(boneCount, 128) do
		vm:ManipulateBoneScale(boneID, Vector(1, 1, 1))
		-- Also reset position and angles in case something else modified them
		vm:ManipulateBonePosition(boneID, Vector(0, 0, 0))
		vm:ManipulateBoneAngles(boneID, Angle(0, 0, 0))
	end
end

--[[
	Helper function to reset all bodygroups on a viewmodel
	Bodygroups persist on the viewmodel entity across model changes
	E.g., Ameli sets bodygroup 1 for belt, MG36's bodygroup 1 might control gun parts
]]--
local function ResetAllBodygroups(vm)
	if not IsValid(vm) then return end
	-- Reset bodygroups 0-10 (covers most weapons)
	for bgIndex = 0, 10 do
		vm:SetBodygroup(bgIndex, 0)
	end
end

--[[
	PreDrawViewModel hook - Performs bone and bodygroup reset when model is ready
	This fires AFTER the viewmodel model has been loaded, ensuring safe manipulation
	Runs BEFORE ViewModelMods.Apply (alphabetically), so ViewModelMods can reapply its mods
]]--
hook.Add("PreDrawViewModel", "M9KR.BeltFed.BoneReset", function(vm, ply, weapon)
	if M9KR.BeltFed.Disabled then return end
	if not M9KR.BeltFed.NeedsBoneReset then return end
	if not IsValid(vm) then return end

	-- Model is loaded and ready - now reset bones AND bodygroups
	-- Reset ALL bone scales to ensure belt bones from previous weapon are cleared
	-- Reset ALL bodygroups to ensure belt bodygroups from previous weapon are cleared
	-- (e.g., Ameli uses bodygroup 1 for belt, MG36's bodygroup 1 might control gun parts)
	-- ViewModelMods will reapply its modifications after this hook (runs alphabetically later)
	ResetAllBones(vm)
	ResetAllBodygroups(vm)
	M9KR.BeltFed.ManipulatedBones = {}
	M9KR.BeltFed.NeedsBoneReset = false
end)

--[[
	Think hook - Updates belt based on ammo and reload state
	Automatically detects bodygroup vs bone-based systems
]]--
hook.Add("Think", "M9KR.BeltFed.Think", function()
	if M9KR.BeltFed.Disabled then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return end

	local vm = ply:GetViewModel()
	if not IsValid(vm) then return end

	local weaponClass = weapon:GetClass()
	local weaponID = weapon
	local currentVMModel = vm:GetModel()

	-- IMPORTANT: Detect viewmodel MODEL change or weapon CLASS change
	-- Bone manipulations persist on the viewmodel entity across model changes
	-- We must reset them when the actual model changes (e.g., M249 -> MG36)
	local modelChanged = M9KR.BeltFed.LastViewModelModel ~= currentVMModel
	local weaponChanged = M9KR.BeltFed.LastWeaponClass ~= weaponClass

	if modelChanged or weaponChanged then
		-- Model or weapon changed - flag for bone reset in PreDrawViewModel
		-- This ensures the new model is fully loaded before we reset
		M9KR.BeltFed.NeedsBoneReset = true
		M9KR.BeltFed.ManipulatedBones = {}

		-- Clear any stale reload state
		M9KR.BeltFed.ReloadStartTime[weaponID] = nil
		M9KR.BeltFed.ReloadWasEmpty[weaponID] = nil
		M9KR.BeltFed.LastWeaponClass = weaponClass
		M9KR.BeltFed.LastViewModelModel = currentVMModel
	end

	-- Determine belt type
	local isBoneBased = weapon.BeltChain ~= nil
	local isBodygroupBased = weapon.BeltBG ~= nil and weapon.BeltMax ~= nil
	local isMultiBodygroup = weapon.BeltBodygroups ~= nil

	-- If weapon has no belt system, nothing more to do
	if not isBoneBased and not isBodygroupBased and not isMultiBodygroup then return end

	-- Check if reloading
	local isReloading = weapon.Reloading or weapon:GetNWBool("Reloading", false)

	if isBoneBased then
		-- BONE-BASED BELT (like MG4)
		if isReloading then
			-- Track reload start time and whether it was empty
			if not M9KR.BeltFed.ReloadStartTime[weaponID] then
				M9KR.BeltFed.ReloadStartTime[weaponID] = CurTime()
				M9KR.BeltFed.ReloadWasEmpty[weaponID] = (weapon:Clip1() == 0)
			end

			local reloadElapsed = CurTime() - M9KR.BeltFed.ReloadStartTime[weaponID]
			local wasEmpty = M9KR.BeltFed.ReloadWasEmpty[weaponID]

			-- Use empty timing if available and reload started empty
			local hideTime, showTime
			if wasEmpty and weapon.BeltHideTimeEmpty then
				hideTime = weapon.BeltHideTimeEmpty
				showTime = weapon.BeltShowTimeEmpty or weapon.BeltShowTime or 5.0
			else
				hideTime = weapon.BeltHideTime or 4.0
				showTime = weapon.BeltShowTime or 5.0
			end

			if reloadElapsed >= showTime then
				-- After show time: show all bullets (new belt)
				UpdateBoneBelt(vm, weapon, true)
			elseif reloadElapsed >= hideTime then
				-- Between hide and show: hide all bullets
				for threshold, boneName in pairs(weapon.BeltChain) do
					local boneID = vm:LookupBone(boneName)
					if boneID and boneID >= 0 then
						-- Track this bone ID for cleanup on weapon swap
						M9KR.BeltFed.ManipulatedBones[boneID] = true
						vm:ManipulateBoneScale(boneID, Vector(0, 0, 0))
					end
				end
			end
			-- Before hideTime: keep current state (frozen)
		else
			-- Not reloading - update based on current ammo
			M9KR.BeltFed.ReloadStartTime[weaponID] = nil
			M9KR.BeltFed.ReloadWasEmpty[weaponID] = nil
			UpdateBoneBelt(vm, weapon, false)
		end

	elseif isBodygroupBased then
		-- BODYGROUP-BASED BELT (like Ameli)
		if isReloading then
			-- Track reload start time and whether it was empty
			if not M9KR.BeltFed.ReloadStartTime[weaponID] then
				M9KR.BeltFed.ReloadStartTime[weaponID] = CurTime()
				M9KR.BeltFed.ReloadWasEmpty[weaponID] = (weapon:Clip1() == 0)
			end

			local reloadElapsed = CurTime() - M9KR.BeltFed.ReloadStartTime[weaponID]
			local wasEmpty = M9KR.BeltFed.ReloadWasEmpty[weaponID]

			-- Use empty timing if available and reload started empty
			local hideTime, showTime
			if wasEmpty and weapon.BeltHideTimeEmpty then
				hideTime = weapon.BeltHideTimeEmpty
				showTime = weapon.BeltShowTimeEmpty or weapon.BeltShowTime or 5.0
			else
				hideTime = weapon.BeltHideTime or 4.0
				showTime = weapon.BeltShowTime or 5.0
			end

			local bodygroup
			if reloadElapsed < hideTime then
				-- Before hide time: keep showing current belt (frozen)
				bodygroup = math.Clamp(weapon:Clip1(), 0, weapon.BeltMax - 1)
			elseif reloadElapsed < showTime then
				-- Between hide and show: hide belt completely
				bodygroup = 0
			else
				-- After show time: show full belt (new ammo loaded)
				bodygroup = weapon.BeltMax - 1
			end

			UpdateBodygroupBelt(vm, weapon, bodygroup)
		else
			-- Not reloading - clear reload tracking and show current ammo
			M9KR.BeltFed.ReloadStartTime[weaponID] = nil
			M9KR.BeltFed.ReloadWasEmpty[weaponID] = nil
			local bodygroup = math.Clamp(weapon:Clip1(), 0, weapon.BeltMax - 1)
			UpdateBodygroupBelt(vm, weapon, bodygroup)
		end

	elseif isMultiBodygroup then
		-- MULTI-BODYGROUP BELT (like Stoner 63)
		-- Each bullet is a separate bodygroup with states: 0=visible, 1=blank
		if isReloading then
			-- Track reload start time and whether it was empty
			if not M9KR.BeltFed.ReloadStartTime[weaponID] then
				M9KR.BeltFed.ReloadStartTime[weaponID] = CurTime()
				M9KR.BeltFed.ReloadWasEmpty[weaponID] = (weapon:Clip1() == 0)
			end

			local reloadElapsed = CurTime() - M9KR.BeltFed.ReloadStartTime[weaponID]
			local wasEmpty = M9KR.BeltFed.ReloadWasEmpty[weaponID]

			-- Use empty timing if available and reload started empty
			local hideTime, showTime
			if wasEmpty and weapon.BeltHideTimeEmpty then
				hideTime = weapon.BeltHideTimeEmpty
				showTime = weapon.BeltShowTimeEmpty or weapon.BeltShowTime or 5.0
			else
				hideTime = weapon.BeltHideTime or 4.0
				showTime = weapon.BeltShowTime or 5.0
			end

			if reloadElapsed >= showTime then
				-- After show time: show all bullets (new belt)
				UpdateMultiBodygroupBelt(vm, weapon, true)
			elseif reloadElapsed >= hideTime then
				-- Between hide and show: hide all bullets
				for threshold, bgIndex in pairs(weapon.BeltBodygroups) do
					vm:SetBodygroup(bgIndex, 1)
				end
			end
			-- Before hideTime: keep current state (frozen)
		else
			-- Not reloading - update based on current ammo
			M9KR.BeltFed.ReloadStartTime[weaponID] = nil
			M9KR.BeltFed.ReloadWasEmpty[weaponID] = nil
			UpdateMultiBodygroupBelt(vm, weapon, false)
		end
	end
end)

print("[M9K:R] Belt-fed weapon support loaded (bodygroup + bone + multi-bodygroup systems)")
