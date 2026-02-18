--[[
	M9K Reloaded - Client-Side ViewModel Bone Modifications Handler

	Handles viewmodel bone modifications for custom weapon positioning.
	Watches for M9KR weapons with ViewModelBoneMods and applies them automatically.

	This separates visual CLIENT logic from the weapon base for cleaner organization.
]]--

M9KR = M9KR or {}
M9KR.ViewModelMods = M9KR.ViewModelMods or {}

-- ConVar to enable/disable viewmodel bone mods
CreateClientConVar("m9kr_viewmodel_mods_enabled", "1", true, false, "Enable M9K Reloaded viewmodel bone modifications", 0, 1)

-- Track applied bone modifications per viewmodel
M9KR.ViewModelMods.AppliedMods = M9KR.ViewModelMods.AppliedMods or {}

--[[
	Update bone positions on a viewmodel
	Uses ManipulateBone* functions for consistent, animation-friendly bone modifications
]]--
function M9KR.ViewModelMods.UpdateBonePositions(vm, weapon)
	if not IsValid(vm) then return end
	if not IsValid(weapon) then return end
	if not weapon.ViewModelBoneMods then return end
	if vm:GetBoneCount() == 0 then return end

	-- Check if enabled
	if not GetConVar("m9kr_viewmodel_mods_enabled"):GetBool() then return end

	-- Initialize bone modification tracking
	if not vm.ViewModelBoneMods then
		vm.ViewModelBoneMods = {}
	end

	-- Apply bone modifications using ManipulateBone* functions
	for k, v in pairs(weapon.ViewModelBoneMods) do
		local bone = vm:LookupBone(k)
		if not bone then continue end

		-- Apply scale
		if v.scale then
			vm:ManipulateBoneScale(bone, v.scale)
		end

		-- Apply position offset
		if v.pos then
			vm:ManipulateBonePosition(bone, v.pos)
		end

		-- Apply angle offset
		if v.angle then
			vm:ManipulateBoneAngles(bone, v.angle)
		end

		-- Track that we've modified this bone
		vm.ViewModelBoneMods[bone] = true
	end
end

--[[
	Reset bone positions on a viewmodel
	Clears all modifications applied by UpdateBonePositions
]]--
function M9KR.ViewModelMods.ResetBonePositions(vm)
	if not IsValid(vm) then return end
	if vm:GetBoneCount() == 0 then return end
	if not vm.ViewModelBoneMods then return end

	-- Reset all modified bones
	for bone, _ in pairs(vm.ViewModelBoneMods) do
		vm:ManipulateBoneScale(bone, Vector(1, 1, 1))
		vm:ManipulateBoneAngles(bone, Angle(0, 0, 0))
		vm:ManipulateBonePosition(bone, Vector(0, 0, 0))
	end

	vm.ViewModelBoneMods = nil
end

--[[
	PreDrawViewModel hook - Apply bone modifications and control visibility
	Return true to hide viewmodel, nil to draw normally
]]--
hook.Add("PreDrawViewModel", "M9KR.ViewModelMods.Apply", function(vm, ply, weapon)
	if not IsValid(vm) then return end
	if not IsValid(weapon) then return end

	-- Check viewmodel visibility for scoped weapons (controlled by weapon_state_handler)
	if weapon.ShouldDrawViewModel == false then
		return true -- Hide viewmodel (for scoped weapons in ADS)
	end

	-- Apply bone modifications if enabled
	if GetConVar("m9kr_viewmodel_mods_enabled"):GetBool() then
		-- Only process M9KR weapons with ViewModelBoneMods
		if weapon.ViewModelBoneMods then
			-- Apply mods every frame to handle viewmodel resets and model changes
			-- This is the standard approach for viewmodel bone modifications in GMod
			M9KR.ViewModelMods.UpdateBonePositions(vm, weapon)
			vm.M9KR_ModsAppliedFor = weapon
		end
	end
end)

--[[
	Cleanup when weapon is removed or switched
]]--
hook.Add("Think", "M9KR.ViewModelMods.Cleanup", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local vm = ply:GetViewModel()
	if not IsValid(vm) then return end

	local weapon = ply:GetActiveWeapon()

	-- If no weapon or weapon doesn't have bone mods, reset
	if not IsValid(weapon) or not weapon.ViewModelBoneMods then
		if vm.ViewModelBoneMods then
			M9KR.ViewModelMods.ResetBonePositions(vm)
			vm.M9KR_ModsAppliedFor = nil
		end
	-- If we switched weapons, reset and allow re-application
	elseif vm.M9KR_ModsAppliedFor and vm.M9KR_ModsAppliedFor ~= weapon then
		M9KR.ViewModelMods.ResetBonePositions(vm)
		vm.M9KR_ModsAppliedFor = nil
	end
end)

print("[M9K:R] Client-side viewmodel bone modifications handler loaded")
