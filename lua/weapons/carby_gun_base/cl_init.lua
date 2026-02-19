-- M9K Reloaded Base - Client Init

include("shared.lua")

-- ============================================================================
-- Client-side Animation Variable Defaults
-- ============================================================================

SWEP.AnimationTime = 0 -- Time tracker for animations
SWEP.BreathIntensity = 0 -- Smooth breath intensity
SWEP.WalkIntensity = 0 -- Smooth walk intensity
SWEP.SprintIntensity = 0 -- Smooth sprint intensity
SWEP.JumpVelocity = 0 -- Vertical velocity for jump tracking
SWEP.JumpVelocitySmooth = 0 -- Smoothed vertical velocity
SWEP.LateralVelocity = 0 -- Horizontal velocity for tilt
SWEP.LateralVelocitySmooth = 0 -- Smoothed lateral velocity
SWEP.LastGroundState = true -- Track if player was on ground last frame

-- ============================================================================
-- DrawWeaponSelection - Draw weapon icon in weapon selection HUD
-- ============================================================================

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
	-- Lazy load icon material if not already loaded
	if not self.WepSelectIconMat and self.Gun then
		self.WepSelectIconMat = Material("vgui/hud/" .. self.Gun)
	end

	-- Draw if we have a valid material (not error material)
	if self.WepSelectIconMat and not self.WepSelectIconMat:IsError() then
		surface.SetDrawColor(255, 255, 255, alpha)
		surface.SetMaterial(self.WepSelectIconMat)

		y = y + 10
		x = x + 10
		wide = wide - 20

		surface.DrawTexturedRect(x, y, wide, wide * 0.5)
	end
end

-- ============================================================================
-- ADS / Sprint / Safety / FOV Input State Management
-- ============================================================================

-- ADS sounds
local IRON_IN_SOUND = "m9k_indicators/ironin.wav"
local IRON_OUT_SOUND = "m9k_indicators/ironout.wav"

-- FOV transition constants
local FOV_TRANSITION_FAST = 0.2
local FOV_TRANSITION_NORMAL = 0.2
local FOV_TRANSITION_SAFETY = 0.25
local FOV_TRANSITION_FROM_SPRINT = 0.35

--[[
	Start a smooth FOV transition on this weapon
]]
function SWEP:M9KR_StartFOVTransition(targetFOV, duration)
	if not IsValid(self.Owner) then return end

	local actualStart = self.m9kr_FOVCurrent or 0
	if actualStart == 0 then
		actualStart = self.Owner:GetFOV()
	end

	self.m9kr_FOVStart = actualStart
	self.m9kr_FOVTarget = targetFOV == 0 and self.Owner:GetFOV() or targetFOV
	self.m9kr_FOVTransitionStart = CurTime()
	self.m9kr_FOVTransitionDuration = duration or FOV_TRANSITION_NORMAL
end

--[[
	Get the ADS target FOV for this weapon
]]
function SWEP:M9KR_GetADSTargetFOV()
	if self.Scoped and self.Secondary and self.Secondary.ScopeZoom then
		return 75 / self.Secondary.ScopeZoom
	elseif self.Secondary and self.Secondary.IronFOV then
		return self.Secondary.IronFOV
	end
	return 0
end

--[[
	Update weapon input state (ADS, sprint, safety, reload, USE key)
	Called every frame from Think(). Manages ADS, sprint, safety, reload, and FOV state.
]]
function SWEP:UpdateWeaponInputState()
	if not IsValid(self) or not IsValid(self.Owner) then return end

	local ply = self.Owner
	local useDown = ply:KeyDown(IN_USE)
	local attack2Down = ply:KeyDown(IN_ATTACK2)
	local speedDown = ply:KeyDown(IN_SPEED)
	local isOnGround = ply:IsOnGround()
	local isReloading = self.Weapon:GetNWBool("Reloading", false)
	local isSafe = self.GetIsOnSafe and self:GetIsOnSafe() or false
	local isPressingMovement = ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT)
	local isActuallySprinting = speedDown and isOnGround and ply:GetVelocity():Length2D() > 20 and isPressingMovement
	local isSprintJumping = speedDown and not isOnGround

	-- =====================
	-- USE KEY STATE
	-- =====================
	-- USE just pressed — force exit ADS
	if useDown and not self.m9kr_LastUseState and not isSafe then
		if self.m9kr_IsInADS then
			self:M9KR_StartFOVTransition(0, FOV_TRANSITION_FAST)
			self.m9kr_IsInADS = false
		end
	end

	-- USE just released — allow re-entering ADS if ATTACK2 still held
	if not useDown and self.m9kr_LastUseState then
		if attack2Down and not isActuallySprinting and not isReloading then
			self:M9KR_StartFOVTransition(self:M9KR_GetADSTargetFOV(), FOV_TRANSITION_NORMAL)
			self.m9kr_IsInADS = true
		end
	end

	self.m9kr_LastUseState = useDown

	-- =====================
	-- ADS STATE
	-- =====================
	-- ATTACK2 just pressed (not blocked by USE/sprint/reload/safety/sprint-jump)
	if attack2Down and not self.m9kr_LastAttack2State and not useDown and not isActuallySprinting and not isReloading and not isSafe and not isSprintJumping then
		self:M9KR_StartFOVTransition(self:M9KR_GetADSTargetFOV(), FOV_TRANSITION_NORMAL)
		self.m9kr_IsInADS = true
		self:EmitSound(IRON_IN_SOUND, 50, 100)
	end

	-- ATTACK2 just released — exit ADS (only if we were in ADS)
	if not attack2Down and self.m9kr_LastAttack2State and not useDown and self.m9kr_IsInADS then
		self:M9KR_StartFOVTransition(0, FOV_TRANSITION_FAST)
		self.m9kr_IsInADS = false
		self:EmitSound(IRON_OUT_SOUND, 50, 100)
	end

	-- Force exit ADS when player actually starts sprinting
	if isActuallySprinting and self.m9kr_IsInADS and not useDown then
		self:M9KR_StartFOVTransition(0, FOV_TRANSITION_FAST)
		self.m9kr_IsInADS = false
		self.m9kr_Attack2HeldDuringSprint = attack2Down
	end

	-- Track ATTACK2 pressed during sprint (for re-entering ADS after sprint)
	if isActuallySprinting and attack2Down and not self.m9kr_IsInADS and not useDown then
		self.m9kr_Attack2HeldDuringSprint = true
	end

	-- Re-enter ADS when sprint ends if ATTACK2 was held during sprint
	if not isActuallySprinting and self.m9kr_Attack2HeldDuringSprint and attack2Down and not useDown and not isReloading and not isSafe then
		self:M9KR_StartFOVTransition(self:M9KR_GetADSTargetFOV(), FOV_TRANSITION_FROM_SPRINT)
		self.m9kr_IsInADS = true
		self:EmitSound(IRON_IN_SOUND, 50, 100)
		self.m9kr_Attack2HeldDuringSprint = false
	end

	-- Clear sprint-ADS flag when ATTACK2 released
	if not attack2Down then
		self.m9kr_Attack2HeldDuringSprint = false
	end

	self.m9kr_LastAttack2State = attack2Down

	-- =====================
	-- SPRINT STATE
	-- =====================
	local shouldSprint = isActuallySprinting and not self.m9kr_IsInADS and not isSafe

	if shouldSprint and not self.m9kr_IsInSprint then
		self.m9kr_IsInSprint = true
		self.m9kr_IsInADS = false
		self.SprintJumping = false
	elseif not shouldSprint and self.m9kr_IsInSprint then
		self.m9kr_IsInSprint = false
		self.SprintIntensity = 0
		self.WalkIntensity = 0
	end

	-- Sprint-jumping flag (allows shooting mid-air)
	self.SprintJumping = isSprintJumping

	-- =====================
	-- SAFETY STATE
	-- =====================
	if isSafe ~= self.m9kr_LastSafetyState then
		if isSafe then
			self:M9KR_StartFOVTransition(0, FOV_TRANSITION_SAFETY)
			self.m9kr_IsInADS = false
		end
	end
	self.m9kr_LastSafetyState = isSafe

	-- =====================
	-- RELOAD STATE
	-- =====================
	-- Just started reloading — force exit ADS
	if isReloading and not self.m9kr_LastReloadState then
		self:M9KR_StartFOVTransition(0, FOV_TRANSITION_FAST)
		self.m9kr_IsInADS = false
	end

	-- Just finished reloading — re-enter ADS if ATTACK2 still held
	if not isReloading and self.m9kr_LastReloadState then
		if attack2Down and not useDown and not isActuallySprinting then
			self:M9KR_StartFOVTransition(self:M9KR_GetADSTargetFOV(), FOV_TRANSITION_NORMAL)
			self.m9kr_IsInADS = true
		end
	end
	self.m9kr_LastReloadState = isReloading

	-- =====================
	-- FOV TRANSITION UPDATE
	-- =====================
	local elapsed = CurTime() - (self.m9kr_FOVTransitionStart or 0)
	local dur = self.m9kr_FOVTransitionDuration or 0.2
	local t = math.Clamp(elapsed / dur, 0, 1)
	t = 1 - math.pow(1 - t, 3) -- Ease-out cubic

	local newFOV = Lerp(t, self.m9kr_FOVStart or 0, self.m9kr_FOVTarget or 0)
	if t >= 1 and (self.m9kr_FOVTarget or 0) == ply:GetFOV() then
		self.m9kr_FOVCurrent = 0
	else
		self.m9kr_FOVCurrent = newFOV
	end

	-- =====================
	-- SCOPED VIEWMODEL VISIBILITY
	-- =====================
	if self.Scoped and self.m9kr_IsInADS then
		self.ShouldDrawViewModel = false
		self.isScoped = true
	else
		self.ShouldDrawViewModel = true
		self.isScoped = false
	end
end

-- ============================================================================
-- CalcView - Smooth FOV transitions for ADS/scope zoom
-- ============================================================================

function SWEP:CalcView(ply, origin, angles, fov)
	if not IsValid(ply) or ply ~= LocalPlayer() then return end

	local currentFOV = self.m9kr_FOVCurrent or 0
	if currentFOV > 0 then
		return {
			origin = origin,
			angles = angles,
			fov = currentFOV
		}
	end
end

-- ============================================================================
-- UpdateProgressRatios - TFA-style lightweight progress value updates
-- ============================================================================

local function mathApproach(current, target, delta)
	delta = math.abs(delta)
	if current < target then
		return math.min(current + delta, target)
	else
		return math.max(current - delta, target)
	end
end

function SWEP:UpdateProgressRatios()
	local bIron = self.m9kr_IsInADS or false
	local bSprint = self.m9kr_IsInSprint or false
	local bSafe = self:GetIsOnSafe()
	local bCrouching = self.Owner:KeyDown(IN_DUCK) or self.Owner:Crouching()
	local bReloading = self.Weapon:GetNWBool("Reloading", false)

	-- Initialize progress values if they don't exist
	self.IronSightsProgress = self.IronSightsProgress or 0
	self.SprintProgress = self.SprintProgress or 0
	self.SafetyProgress = self.SafetyProgress or 0
	self.CrouchProgress = self.CrouchProgress or 0

	local ft = FrameTime()

	-- Calculate targets
	-- When reloading, use idle positioning (not sprint) - player can still move with walking bob/tilt
	local ironTarget = (bIron and not bSafe) and 1 or 0
	local sprintTarget = (bSprint and not bSafe and not bIron and not bReloading) and 1 or 0
	local safetyTarget = bSafe and 1 or 0
	local crouchTarget = bCrouching and 1 or 0

	-- Calculate speeds (must match IRONSIGHT_TIME)
	local IRONSIGHT_TIME = 0.8
	local adsTransitionSpeed = 12.5 / (IRONSIGHT_TIME / 0.3)
	local sprintTransitionSpeed = 7.5
	local safetyTransitionSpeed = 12.5 / ((IRONSIGHT_TIME * 0.5) / 0.3)
	local crouchTransitionSpeed = 2.5

	-- Update progress values using TFA-style approach (simple float lerping)
	self.IronSightsProgress = mathApproach(
		self.IronSightsProgress,
		ironTarget,
		(ironTarget - self.IronSightsProgress) * ft * adsTransitionSpeed
	)

	self.SprintProgress = mathApproach(
		self.SprintProgress,
		sprintTarget,
		(sprintTarget - self.SprintProgress) * ft * sprintTransitionSpeed
	)

	self.SafetyProgress = mathApproach(
		self.SafetyProgress,
		safetyTarget,
		(safetyTarget - self.SafetyProgress) * ft * safetyTransitionSpeed
	)

	self.CrouchProgress = mathApproach(
		self.CrouchProgress,
		crouchTarget,
		(crouchTarget - self.CrouchProgress) * ft * crouchTransitionSpeed
	)
end

-- ============================================================================
-- Safety Transition Multiplier
-- ============================================================================

--[[
	GetSafetyTransitionMul - Smooth transition multiplier for viewmodel safety animation
	Returns 0-1 value for lerping viewmodel position during safety transitions
]]--
function SWEP:GetSafetyTransitionMul()
	if not self.GetIsOnSafe then return 0 end
	if not self:GetIsOnSafe() then return 0 end

	local transitionTime = 0.25
	local elapsed = CurTime() - (self.m9kr_SafetyTransitionStart or 0)
	return math.Clamp(elapsed / transitionTime, 0, 1)
end

-- ============================================================================
-- Viewmodel Bone Modifications
-- ============================================================================

--[[
	ApplyViewModelBoneMods - Apply custom bone modifications to viewmodel
	Uses ManipulateBone* functions for persistent, animation-friendly modifications.
	Called from PreDrawViewModel hook.
]]--
function SWEP:ApplyViewModelBoneMods(vm)
	if not IsValid(vm) then return end
	if not self.ViewModelBoneMods then return end
	if vm:GetBoneCount() == 0 then return end

	for k, v in pairs(self.ViewModelBoneMods) do
		local bone = vm:LookupBone(k)
		if not bone then continue end

		if v.scale then
			vm:ManipulateBoneScale(bone, v.scale)
		end
		if v.pos then
			vm:ManipulateBonePosition(bone, v.pos)
		end
		if v.angle then
			vm:ManipulateBoneAngles(bone, v.angle)
		end
	end
end

--[[
	ResetViewModelBones - Reset all bone modifications on a viewmodel
	Clears ManipulateBone* changes. Called from Deploy/Holster/reload paths.
]]--
function SWEP:ResetViewModelBones(vm)
	if not IsValid(vm) then return end
	if vm:GetBoneCount() == 0 then return end

	local boneCount = vm:GetBoneCount() or 0
	for boneID = 0, boneCount - 1 do
		vm:ManipulateBoneScale(boneID, Vector(1, 1, 1))
		vm:ManipulateBonePosition(boneID, Vector(0, 0, 0))
		vm:ManipulateBoneAngles(boneID, Angle(0, 0, 0))
	end
end

-- ============================================================================
-- Belt-Fed Weapon Support
-- Supports 3 belt display methods: bone-based, bodygroup-based, multi-bodygroup
-- ============================================================================

-- Belt helper: Update bone-based belt (like MG4)
-- Scales bullet bones to 0 when ammo is at or below their threshold
local function BeltUpdateBones(vm, weapon, showAll)
	local beltChain = weapon.BeltChain
	if not beltChain then return end

	local clip = weapon:Clip1()

	for threshold, boneName in pairs(beltChain) do
		local boneID = vm:LookupBone(boneName)
		if boneID and boneID >= 0 then
			if showAll or clip > threshold then
				vm:ManipulateBoneScale(boneID, Vector(1, 1, 1))
			else
				vm:ManipulateBoneScale(boneID, Vector(0, 0, 0))
			end
		end
	end
end

-- Belt helper: Update bodygroup-based belt (like Ameli)
local function BeltUpdateBodygroup(vm, weapon, bodygroup)
	vm:SetBodygroup(weapon.BeltBG, bodygroup)
end

-- Belt helper: Update multi-bodygroup belt (like Stoner 63)
-- Each bullet is a separate bodygroup with states: 0=visible, 1=blank
local function BeltUpdateMultiBodygroup(vm, weapon, showAll)
	local beltBodygroups = weapon.BeltBodygroups
	if not beltBodygroups then return end

	local clip = weapon:Clip1()

	for threshold, bgIndex in pairs(beltBodygroups) do
		if showAll or clip > threshold then
			vm:SetBodygroup(bgIndex, 0)
		else
			vm:SetBodygroup(bgIndex, 1)
		end
	end
end

-- Belt helper: Reset all bodygroups on a viewmodel
-- Bodygroups persist on the viewmodel entity across model changes
local function BeltResetAllBodygroups(vm)
	if not IsValid(vm) then return end
	for bgIndex = 0, 10 do
		vm:SetBodygroup(bgIndex, 0)
	end
end

--[[
	UpdateBeltAmmo - Update belt-fed weapon display based on ammo and reload state
	Supports 3 belt types: bone-based, bodygroup-based, multi-bodygroup
	Called from Think() CLIENT block.
]]--
function SWEP:UpdateBeltAmmo()
	local ply = self.Owner
	if not IsValid(ply) then return end

	local vm = ply:GetViewModel()
	if not IsValid(vm) then return end

	-- Detect viewmodel model change (bones/bodygroups persist across model changes)
	local currentVMModel = vm:GetModel()
	if self.m9kr_BeltLastModel ~= currentVMModel then
		self.m9kr_BeltNeedsBoneReset = true
		self.m9kr_BeltReloadStart = nil
		self.m9kr_BeltReloadWasEmpty = nil
		self.m9kr_BeltLastModel = currentVMModel
	end

	-- Determine belt type
	local isBoneBased = self.BeltChain ~= nil
	local isBodygroupBased = self.BeltBG ~= nil and self.BeltMax ~= nil
	local isMultiBodygroup = self.BeltBodygroups ~= nil

	-- If weapon has no belt system, nothing to do
	if not isBoneBased and not isBodygroupBased and not isMultiBodygroup then return end

	-- Check if reloading
	local isReloading = self.Reloading or self:GetNWBool("Reloading", false)

	if isBoneBased then
		-- BONE-BASED BELT (like MG4)
		if isReloading then
			if not self.m9kr_BeltReloadStart then
				self.m9kr_BeltReloadStart = CurTime()
				self.m9kr_BeltReloadWasEmpty = (self:Clip1() == 0)
			end

			local reloadElapsed = CurTime() - self.m9kr_BeltReloadStart
			local wasEmpty = self.m9kr_BeltReloadWasEmpty

			local hideTime, showTime
			if wasEmpty and self.BeltHideTimeEmpty then
				hideTime = self.BeltHideTimeEmpty
				showTime = self.BeltShowTimeEmpty or self.BeltShowTime or 5.0
			else
				hideTime = self.BeltHideTime or 4.0
				showTime = self.BeltShowTime or 5.0
			end

			if reloadElapsed >= showTime then
				BeltUpdateBones(vm, self, true)
			elseif reloadElapsed >= hideTime then
				for threshold, boneName in pairs(self.BeltChain) do
					local boneID = vm:LookupBone(boneName)
					if boneID and boneID >= 0 then
						vm:ManipulateBoneScale(boneID, Vector(0, 0, 0))
					end
				end
			end
		else
			self.m9kr_BeltReloadStart = nil
			self.m9kr_BeltReloadWasEmpty = nil
			BeltUpdateBones(vm, self, false)
		end

	elseif isBodygroupBased then
		-- BODYGROUP-BASED BELT (like Ameli)
		if isReloading then
			if not self.m9kr_BeltReloadStart then
				self.m9kr_BeltReloadStart = CurTime()
				self.m9kr_BeltReloadWasEmpty = (self:Clip1() == 0)
			end

			local reloadElapsed = CurTime() - self.m9kr_BeltReloadStart
			local wasEmpty = self.m9kr_BeltReloadWasEmpty

			local hideTime, showTime
			if wasEmpty and self.BeltHideTimeEmpty then
				hideTime = self.BeltHideTimeEmpty
				showTime = self.BeltShowTimeEmpty or self.BeltShowTime or 5.0
			else
				hideTime = self.BeltHideTime or 4.0
				showTime = self.BeltShowTime or 5.0
			end

			local bodygroup
			if reloadElapsed < hideTime then
				bodygroup = math.Clamp(self:Clip1(), 0, self.BeltMax - 1)
			elseif reloadElapsed < showTime then
				bodygroup = 0
			else
				bodygroup = self.BeltMax - 1
			end

			BeltUpdateBodygroup(vm, self, bodygroup)
		else
			self.m9kr_BeltReloadStart = nil
			self.m9kr_BeltReloadWasEmpty = nil
			local bodygroup = math.Clamp(self:Clip1(), 0, self.BeltMax - 1)
			BeltUpdateBodygroup(vm, self, bodygroup)
		end

	elseif isMultiBodygroup then
		-- MULTI-BODYGROUP BELT (like Stoner 63)
		if isReloading then
			if not self.m9kr_BeltReloadStart then
				self.m9kr_BeltReloadStart = CurTime()
				self.m9kr_BeltReloadWasEmpty = (self:Clip1() == 0)
			end

			local reloadElapsed = CurTime() - self.m9kr_BeltReloadStart
			local wasEmpty = self.m9kr_BeltReloadWasEmpty

			local hideTime, showTime
			if wasEmpty and self.BeltHideTimeEmpty then
				hideTime = self.BeltHideTimeEmpty
				showTime = self.BeltShowTimeEmpty or self.BeltShowTime or 5.0
			else
				hideTime = self.BeltHideTime or 4.0
				showTime = self.BeltShowTime or 5.0
			end

			if reloadElapsed >= showTime then
				BeltUpdateMultiBodygroup(vm, self, true)
			elseif reloadElapsed >= hideTime then
				for threshold, bgIndex in pairs(self.BeltBodygroups) do
					vm:SetBodygroup(bgIndex, 1)
				end
			end
		else
			self.m9kr_BeltReloadStart = nil
			self.m9kr_BeltReloadWasEmpty = nil
			BeltUpdateMultiBodygroup(vm, self, false)
		end
	end
end

-- PreDrawViewModel hook: viewmodel bone mods, belt bone reset, visibility control
-- Thin global hook that delegates to SWEP methods
hook.Add("PreDrawViewModel", "M9KR_ViewModelHandler", function(vm, ply, weapon)
	if not IsValid(vm) then return end
	if not IsValid(weapon) then return end

	-- Hide viewmodel when scoped weapon is in ADS
	if weapon.ShouldDrawViewModel == false then
		return true
	end

	-- Belt-fed: reset all bones + bodygroups on viewmodel model change
	-- This fires AFTER the new model is loaded, ensuring safe manipulation
	if weapon.m9kr_BeltNeedsBoneReset then
		local boneCount = vm:GetBoneCount() or 0
		for boneID = 0, math.max(boneCount, 128) do
			vm:ManipulateBoneScale(boneID, Vector(1, 1, 1))
			vm:ManipulateBonePosition(boneID, Vector(0, 0, 0))
			vm:ManipulateBoneAngles(boneID, Angle(0, 0, 0))
		end
		BeltResetAllBodygroups(vm)
		weapon.m9kr_BeltNeedsBoneReset = false
	end

	-- Apply viewmodel bone modifications
	if weapon.ApplyViewModelBoneMods and weapon.ViewModelBoneMods then
		weapon:ApplyViewModelBoneMods(vm)
	end
end)

-- ============================================================================
-- Low Ammo Warning System
-- Plays caliber-specific warning sounds when ammo is low
-- ============================================================================

-- ConVar for low ammo threshold
CreateClientConVar("m9kr_low_ammo_threshold", "33", true, false, "Low ammo warning threshold (percentage of magazine)", 0, 100)

-- Ammo type to low ammo sound mapping (caliber-specific sounds)
local LowAmmoSoundByAmmoType = {
	["pistol"] = "m9k_indicators/lowammo_indicator_handgun.wav",
	["357"] = "m9k_indicators/lowammo_indicator_revolver.wav",
	["smg1"] = "m9k_indicators/lowammo_indicator_smg.wav",
	["ar2"] = "m9k_indicators/lowammo_indicator_ar.wav",
	["buckshot"] = "m9k_indicators/lowammo_indicator_shotgun.wav",
	["slam"] = "m9k_indicators/lowammo_indicator_shotgun.wav",
	["SniperPenetratedRound"] = "m9k_indicators/lowammo_indicator_sr.wav",
	["AirboatGun"] = "m9k_indicators/lowammo_indicator_shotgun_auto.wav",
}

local LastAmmoSoundByAmmoType = {
	["pistol"] = "m9k_indicators/lowammo_dry_handgun.wav",
	["357"] = "m9k_indicators/lowammo_dry_revolver.wav",
	["smg1"] = "m9k_indicators/lowammo_dry_smg.wav",
	["ar2"] = "m9k_indicators/lowammo_dry_ar.wav",
	["buckshot"] = "m9k_indicators/lowammo_dry_shotgun.wav",
	["slam"] = "m9k_indicators/lowammo_dry_shotgun.wav",
	["SniperPenetratedRound"] = "m9k_indicators/lowammo_dry_sr.wav",
	["AirboatGun"] = "m9k_indicators/lowammo_dry_shotgun_auto.wav",
}

-- Precache all low ammo sounds
for _, soundPath in pairs(LowAmmoSoundByAmmoType) do
	util.PrecacheSound(soundPath)
end
for _, soundPath in pairs(LastAmmoSoundByAmmoType) do
	util.PrecacheSound(soundPath)
end

--[[
	CheckLowAmmo - Check ammo and play caliber-specific warning sounds
	Called from PrimaryAttack/FireBurstShot AFTER TakePrimaryAmmo.
	Clip1() is already decremented, so no prediction trick needed.
]]--
function SWEP:CheckLowAmmo()
	-- Skip weapons that have disabled low ammo warnings (bows, crossbows, etc.)
	if self.NoLowAmmoWarning then return end

	-- Verify weapon has proper primary structure
	if not self.Primary or not self.Primary.ClipSize then return end

	local clip = self:Clip1()
	local maxClip = self.Primary.ClipSize

	-- Don't warn for weapons with no magazine (like shotguns that feed directly)
	if maxClip <= 1 then return end

	-- Calculate ammo percentage
	local threshold = GetConVar("m9kr_low_ammo_threshold"):GetInt() / 100
	local isLowAmmo = clip <= (maxClip * threshold) and clip > 0

	-- Play low ammo sound when in low ammo state
	-- For high-RPM weapons with SoundIndicatorInterval, throttle the warning sound
	-- Otherwise play on EVERY shot (TFA-style behavior)
	if isLowAmmo then
		local shouldPlayWarning = true

		-- Check if weapon uses SoundIndicatorInterval (high-RPM weapons like minigun)
		if self.SoundIndicatorInterval then
			self.m9kr_LowAmmoShotsSinceWarning = (self.m9kr_LowAmmoShotsSinceWarning or 0) + 1
			shouldPlayWarning = (self.m9kr_LowAmmoShotsSinceWarning >= self.SoundIndicatorInterval)
			if shouldPlayWarning then
				self.m9kr_LowAmmoShotsSinceWarning = 0
			end
		end

		if shouldPlayWarning then
			local ammoType = self:GetPrimaryAmmoType()
			local ammoTypeName = game.GetAmmoName(ammoType) or "ar2"
			local snd = LowAmmoSoundByAmmoType[ammoTypeName] or "m9k_indicators/lowammo_indicator_ar.wav"

			-- Semi-auto snipers (DMRs) get a distinct sound from bolt-action
			if ammoTypeName == "SniperPenetratedRound" and not self.BoltAction then
				snd = "m9k_indicators/lowammo_indicator_dmr.wav"
			end

			self:EmitSound(snd, 60, 100, 0.5, CHAN_AUTO)
		end
	end

	-- Detect last round fired (clip just hit 0)
	-- Always plays regardless of SoundIndicatorInterval since it's a one-time event
	if clip == 0 then
		local ammoType = self:GetPrimaryAmmoType()
		local ammoTypeName = game.GetAmmoName(ammoType) or "ar2"
		local snd = LastAmmoSoundByAmmoType[ammoTypeName] or "m9k_indicators/lowammo_dry_ar.wav"

		-- Semi-auto snipers (DMRs) get a distinct sound from bolt-action
		if ammoTypeName == "SniperPenetratedRound" and not self.BoltAction then
			snd = "m9k_indicators/lowammo_dry_dmr.wav"
		end

		self:EmitSound(snd, 60, 100, 0.5, CHAN_AUTO)

		-- Reset warning counter when mag empties
		self.m9kr_LowAmmoShotsSinceWarning = 0
	end

	-- Reset counter when transitioning into low ammo state (so first warning plays immediately)
	if isLowAmmo and not self.m9kr_LowAmmoWasLow then
		self.m9kr_LowAmmoShotsSinceWarning = self.SoundIndicatorInterval or 0
	end

	-- Update state
	self.m9kr_LowAmmoWasLow = isLowAmmo
end

-- ============================================================================
-- Worldmodel Shell Ejection
-- Spawns shell casings for other players' weapons (viewmodel shells are
-- handled by SWEP:EjectShell in shared.lua)
-- ============================================================================

-- Universal shell ejection offsets (applied to all weapons)
local ShellEjectionOffset = {
	Forward = 5,   -- Units forward from weapon position
	Right = 2,     -- Units right from weapon position
	Up = 1         -- Units up from weapon position
}

--[[
	CalculateWorldmodelShellPos - Calculate worldmodel shell spawn position
	Uses universal offset formula applied to weapon's local coordinate space.
]]--
function SWEP:CalculateWorldmodelShellPos()
	local wepPos = self:GetPos()
	local wepAng = self:GetAngles()

	local shellPos = wepPos +
		wepAng:Forward() * ShellEjectionOffset.Forward +
		wepAng:Right() * ShellEjectionOffset.Right +
		wepAng:Up() * ShellEjectionOffset.Up

	-- Shell ejects to the right (90 degrees from forward)
	local shellAng = Angle(wepAng.p, wepAng.y + 90, wepAng.r)

	return shellPos, shellAng
end

--[[
	SpawnWorldmodelShell - Spawn a shell casing from the worldmodel
	Used for other players' weapons (third-person view).
]]--
function SWEP:SpawnWorldmodelShell()
	if not self.ShellModel then return end

	local shellPos, shellAng = self:CalculateWorldmodelShellPos()
	if not shellPos then return end

	local effectData = EffectData()
	effectData:SetOrigin(shellPos)
	effectData:SetNormal(shellAng:Forward())
	effectData:SetEntity(self)

	util.Effect("m9kr_shell", effectData)
end

-- EntityFireBullets hook: spawn worldmodel shells for other players
-- The local player's shells are handled by SWEP:EjectShell (viewmodel)
hook.Add("EntityFireBullets", "M9KR_WorldmodelShells", function(entity, data)
	if not IsValid(entity) then return end

	-- Resolve the player who fired
	local owner
	if entity:IsPlayer() then
		owner = entity
	elseif entity:IsWeapon() then
		owner = entity:GetOwner()
	else
		return
	end

	if not IsValid(owner) or not owner:IsPlayer() then return end

	-- Local player shells are handled by viewmodel EjectShell
	if owner == LocalPlayer() then return end

	local weapon = owner:GetActiveWeapon()
	if not IsValid(weapon) or not weapon.ShellModel then return end

	-- Call SpawnWorldmodelShell if it exists (M9KR weapons)
	if weapon.SpawnWorldmodelShell then
		weapon:SpawnWorldmodelShell()
	end
end)

-- ============================================================================
-- Bullet Impact Effects
-- Spawns custom dust/smoke/sparks on bullet impact for M9KR weapons
-- Must be a global hook (impacts need to show for ALL players' bullets)
-- ConVars: m9kr_bullet_impact, m9kr_metal_impact, m9kr_dust_impact
-- (created server-side in m9kr_autoload.lua, replicated to clients)
-- ============================================================================

local M9KR_BulletImpact = GetConVar("m9kr_bullet_impact")
local M9KR_MetalImpact = GetConVar("m9kr_metal_impact")

hook.Add("EntityFireBullets", "M9KR_BulletImpactEffects", function(entity, data)
	if not IsValid(entity) then return end

	-- Get weapon from entity (entity could be player or weapon)
	local wep
	if entity:IsPlayer() then
		wep = entity:GetActiveWeapon()
	elseif entity:IsWeapon() then
		wep = entity
	else
		return
	end

	if not IsValid(wep) then return end

	-- Check if it's an M9K:R weapon
	if not wep.Base or not M9KR.WeaponBases[wep.Base] then return end

	-- Use the Callback to spawn impact effects
	local originalCallback = data.Callback
	data.Callback = function(attacker, tr, dmginfo)
		local result
		if originalCallback then
			result = originalCallback(attacker, tr, dmginfo)
		end

		-- Only spawn effects once per shot (prediction check)
		if IsFirstTimePredicted() and tr.HitPos then
			-- Skip smoke plume effects for flesh (use default GMod blood effects)
			if tr.MatType == MAT_FLESH or tr.MatType == MAT_ALIENFLESH then
				return result
			end

			local fx = EffectData()
			fx:SetOrigin(tr.HitPos)
			fx:SetNormal(tr.HitNormal or Vector(0, 0, 1))
			fx:SetEntity(entity)

			-- Get caliber data for scaling (default to rifle caliber: 14)
			local penetration = 14
			if IsValid(wep) and wep.ShellModel and M9KR and M9KR.Ballistics then
				local ballisticsData = M9KR.Ballistics.GetData(wep.ShellModel)
				if ballisticsData then
					penetration = ballisticsData.penetration
				end
			end

			fx:SetMagnitude(penetration)

			-- Determine which effect to spawn
			local effectName = nil
			if tr.MatType == MAT_METAL and M9KR_MetalImpact:GetInt() == 1 then
				effectName = "m9kr_metal_impact"
			elseif M9KR_BulletImpact:GetInt() == 1 then
				effectName = "m9kr_bullet_impact"
			end

			if effectName then
				util.Effect(effectName, fx)
			end
		end

		return result
	end
end)

-- ============================================================================
-- GetViewModelPosition
-- ============================================================================

function SWEP:GetViewModelPosition(pos, ang)
	-- Critical safety checks for weapon state transitions and menu interactions
	if not IsValid(self) or not IsValid(self.Weapon) then
		return pos, ang
	end

	-- Check if weapon is being removed or in invalid state
	if not self.Weapon.GetClass or not self.Weapon:GetClass() then
		return pos, ang
	end

	-- Check if owner is valid
	if not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return pos, ang
	end

	-- Additional safety check for essential weapon properties
	if not self.IronSightsPos then
		return pos, ang
	end

	local bIron = self.m9kr_IsInADS or false
	local bSprint = self.m9kr_IsInSprint or false
	local bReloading = self.Weapon:GetNWBool("Reloading")

	-- Check if player is crouching OR holding crouch key (for smooth transitions)
	local bCrouching = false
	if IsValid(self.Owner) and self.Owner:IsPlayer() then
		-- Use KeyDown for immediate response, fallback to Crouching() for full crouch state
		bCrouching = self.Owner:KeyDown(IN_DUCK) or self.Owner:Crouching()
	end

	self.bWasReloading = self.bWasReloading or false

	if bReloading ~= self.bWasReloading then
		if bReloading then
			-- Reload started - hide crosshair
			self.DrawCrosshair = false
		elseif not bReloading then
			-- Reload finished - restore crosshair based on current state
			-- Check if weapon is in SAFE mode - crosshair should stay hidden
			if self:GetIsOnSafe() then
				self.DrawCrosshair = false
			-- Check if player is ACTUALLY sprinting (SPEED key held and on ground)
			elseif self.Owner:KeyDown(IN_SPEED) and self.Owner:IsOnGround() then
				self.fSprintTime = CurTime()
				self.bLastSprint = true
				self.DrawCrosshair = false
			elseif bIron then
				self.fIronTime = CurTime()
				self.bLastIron = true
				if not self.ShowCrosshairInADS then
					self.DrawCrosshair = false
				end
			else
				self.DrawCrosshair = self.OrigCrossHair
			end
		end
		self.bWasReloading = bReloading
	end

	-- Ensure progress values exist (they are updated by UpdateProgressRatios in Think)
	-- DO NOT reset these values - they persist across frames and menu opens/closes
	if not self.IronSightsProgress then self.IronSightsProgress = 0 end
	if not self.SprintProgress then self.SprintProgress = 0 end
	if not self.SafetyProgress then self.SafetyProgress = 0 end
	if not self.CrouchProgress then self.CrouchProgress = 0 end

	-- Get safety state for later use
	local bSafe = self:GetIsOnSafe()

	-- Handle crosshair visibility based on state changes
	local wasInADS = self.bLastIron or false
	local wasInSprint = self.bLastSprint or false
	local wasInSafety = self.bLastSafety or false

	-- Track state changes for crosshair management
	if bIron and not wasInADS then
		if not self.ShowCrosshairInADS then
			self.DrawCrosshair = false
		end
		self.bLastIron = true
	elseif not bIron and wasInADS then
		self.bLastIron = false
		if not bSprint and not bSafe and not bReloading then
			self.DrawCrosshair = self.OrigCrossHair
		end
	end

	if bSprint and not wasInSprint then
		self.DrawCrosshair = false
		self.bLastSprint = true
	elseif not bSprint and wasInSprint then
		self.bLastSprint = false
		if not bIron and not bSafe and not bReloading then
			self.DrawCrosshair = self.OrigCrossHair
		end
	end

	if bSafe and not wasInSafety then
		self.DrawCrosshair = false
		self.bLastSafety = true
	elseif not bSafe and wasInSafety then
		self.bLastSafety = false
		if not bIron and not bSprint and not bReloading then
			self.DrawCrosshair = self.OrigCrossHair
		end
	end

	-- Calculate final multiplier using highest priority state
	-- Safety > Sprint > ADS (matches TFA's priority system)
	local Mul = math.max(self.SafetyProgress, self.SprintProgress, self.IronSightsProgress)

	-- Enhanced animations
	if IsValid(self.Owner) and self.Owner:IsPlayer() then
		-- Ensure variables are initialized
		self.AnimationTime = self.AnimationTime or 0
		self.BreathIntensity = self.BreathIntensity or 0
		self.WalkIntensity = self.WalkIntensity or 0
		self.SprintIntensity = self.SprintIntensity or 0
		self.JumpVelocitySmooth = self.JumpVelocitySmooth or 0
		self.LateralVelocitySmooth = self.LateralVelocitySmooth or 0
		self.JumpIntensitySmooth = self.JumpIntensitySmooth or 0  -- Smooth jump transition intensity
		self.LastEyeAngles = self.LastEyeAngles or self.Owner:EyeAngles()
		self.CameraRotationVelocity = self.CameraRotationVelocity or 0

		-- Detect fire mode changes (networked from SERVER)
		local currentNetworkedMode = self.Weapon:GetNWInt("CurrentFireMode", 1)
		self.LastNetworkedFireMode = self.LastNetworkedFireMode or currentNetworkedMode
		if currentNetworkedMode ~= self.LastNetworkedFireMode then
			-- Fire mode changed - trigger animation only for normal fire mode switches
			-- Skip animation when toggling safety on/off (within 0.5s of safety toggle)
			local recentSafetyToggle = self.SafetyToggleTime and (CurTime() - self.SafetyToggleTime) < 0.5
			if not recentSafetyToggle and not self:GetIsOnSafe() then
				self.FireModeSwitchTime = CurTime()
			end
			self.LastNetworkedFireMode = currentNetworkedMode
		end

		-- Check if game is paused (singleplayer)
		-- In singleplayer, FrameTime() returns 0 when paused
		local rawFrameTime = FrameTime()
		local isPaused = (rawFrameTime == 0)

		local ft = isPaused and 0.001 or math.Clamp(rawFrameTime, 0.001, 0.1) -- Prevent division by zero when menu opens
		local ct = CurTime()

		-- Update animation time ONLY if not paused (this freezes breathing animation)
		if not isPaused then
			self.AnimationTime = self.AnimationTime + ft
		end

		-- Track camera rotation velocity for view turning tilt
		local currentEyeAngles = self.Owner:EyeAngles()
		local angleDiff = currentEyeAngles.y - self.LastEyeAngles.y

		-- Handle angle wrap-around (-180 to 180)
		if angleDiff > 180 then
			angleDiff = angleDiff - 360
		elseif angleDiff < -180 then
			angleDiff = angleDiff + 360
		end

		-- Calculate angular velocity (degrees per second)
		-- Guard against division by zero (backup safety if ft somehow = 0)
		local angularVelocity = ft > 0 and (angleDiff / ft) or 0
		self.CameraRotationVelocity = Lerp(ft * 5, self.CameraRotationVelocity, angularVelocity)
		self.LastEyeAngles = currentEyeAngles

		-- Get player movement states
		local velocity = self.Owner:GetVelocity()
		local speed = velocity:Length2D()
		local isOnGround = self.Owner:IsOnGround()
		local isJumping = not isOnGround and math.abs(velocity.z) > 10

		-- Check if player is pressing movement keys (for immediate sprint exit when keys released)
		local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)

		local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and speed > 50 and isOnGround and isPressingMovement
		if self.JumpCancelsSprint and not isOnGround and (self.SprintJumping or false) then
			isActuallySprinting = false
		end

		local isReloading = self.Weapon:GetNWBool("Reloading")

		-- During reload: treat sprint as walk (idle positioning with walking bob/tilt, not sprint bob)
		local isSprinting = isActuallySprinting and not isReloading
		local isWalking = speed > 20 and (not isSprinting or isReloading) and isOnGround
		local isShooting = self.Weapon:GetNextPrimaryFire() > ct - 0.15

		local isADS = self.IronSightsProgress > 0.1
		local targetBreath = (speed < 5 and not isShooting and not isReloading and isOnGround and not isADS) and 1 or 0
		local targetWalk = isWalking and math.Clamp(speed / 200, 0, 1) or 0
		local targetSprint = isSprinting and math.Clamp(speed / 250, 0, 1) or 0

		-- Very smooth transitions to prevent jittering
		local breathSpeed = ft * 2
		local walkSpeed = ft * 6
		local sprintSpeed = ft * 4

		self.BreathIntensity = Lerp(breathSpeed, self.BreathIntensity, targetBreath)
		self.WalkIntensity = Lerp(walkSpeed, self.WalkIntensity, targetWalk)
		self.SprintIntensity = Lerp(sprintSpeed, self.SprintIntensity, targetSprint)

		-- TFA-style jump velocity smoothing
		local zVelocity = velocity.z
		self.JumpVelocitySmooth = Lerp(ft * 7, self.JumpVelocitySmooth or 0, zVelocity)

		-- Track lateral velocity for tilt animation
		local eyeAng = self.Owner:EyeAngles()
		local rightVec = eyeAng:Right()
		rightVec.z = 0
		rightVec:Normalize()
		local lateralVel = velocity:Dot(rightVec)
		self.LateralVelocitySmooth = Lerp(ft * 3, self.LateralVelocitySmooth, lateralVel)

		-- Get local axes
		local up = ang:Up()
		local right = ang:Right()
		local forward = ang:Forward()
		local flip = self.ViewModelFlip and -1 or 1

		-- Reduce animation intensity when aiming
		local aimMult = 1 - self.IronSightsProgress * 0.85

		if self.BreathIntensity > 0.01 then
			local breatheMult = self.BreathIntensity * aimMult
			local breatheTime = self.AnimationTime * 1.5

			-- Subtle breathing motion
			pos:Add(right * math.sin(breatheTime) * breatheMult * flip * 0.1)
			pos:Add(up * math.cos(breatheTime * 0.5) * breatheMult * 0.06)

			-- Minimal rotation
			ang:RotateAroundAxis(forward, math.sin(breatheTime) * breatheMult * flip * 0.5)
		end

		if self.WalkIntensity > 0.01 then
			local walkMult = self.WalkIntensity * aimMult
			local walkTime = self.AnimationTime * 8

			-- Natural walking bob (reduced vertical bob by 3/4)
			pos:Add(up * math.abs(math.sin(walkTime * 2)) * walkMult * 0.05)
			pos:Add(right * math.sin(walkTime) * walkMult * flip * 0.25)

			-- Subtle walk sway
			ang:RotateAroundAxis(right, -math.sin(walkTime * 2) * walkMult * 1.2)
			ang:RotateAroundAxis(forward, math.sin(walkTime) * walkMult * flip * 1.5)
		end

		if self.SprintIntensity > 0.01 then
			local sprintMult = self.SprintIntensity
			local sprintTime = self.AnimationTime * 9

			-- Sprint bob (reduced vertical by 3/4, faster than walk)
			pos:Add(up * math.abs(math.sin(sprintTime * 2)) * sprintMult * 0.1)
			pos:Add(right * math.sin(sprintTime) * sprintMult * flip * 0.3)

			-- Sprint sway (less aggressive)
			ang:RotateAroundAxis(right, -math.sin(sprintTime * 2) * sprintMult * 2)
			ang:RotateAroundAxis(forward, math.sin(sprintTime) * sprintMult * flip * 1.8)
		end

		-- Clamp velocity to -1 to 1 range and convert to trigonometric angle
		local trigX = -math.Clamp(self.JumpVelocitySmooth / 200, -1, 1) * math.pi / 2

		-- Calculate raw jump intensity (reduced during ADS to minimize vertical movement)
		-- When fully in ADS (IronSightsProgress=1), intensity is reduced to 15% (1 - 0.85 = 0.15)
		local rawJumpIntensity = (3 + math.Clamp(math.abs(self.JumpVelocitySmooth) - 100, 0, 200) / 200 * 4) * (1 - self.IronSightsProgress * 0.85)

		-- Smoothly lerp jump intensity for smooth transitions (handles repeated jumping)
		-- Speed at ft*5 provides smooth initial rise without snappiness
		local jumpIntensityTarget = isJumping and rawJumpIntensity or 0
		self.JumpIntensitySmooth = Lerp(ft * 5, self.JumpIntensitySmooth, jumpIntensityTarget)

		-- Use smoothed intensity for final application
		local jumpIntensity = self.JumpIntensitySmooth

		-- Reduce jump intensity when ADS on scoped weapons (minor movement, but still noticeable)
		-- Normal weapons and non-ADS scoped weapons get full jump intensity
		local isScopedWeapon = self.Base == "carby_scoped_base"
		local scopedADSReduction = (isScopedWeapon and bIron) and 0.4 or 1.0
		jumpIntensity = jumpIntensity * scopedADSReduction

		-- TFA scale constant
		local scale_r = -6

		-- Calculate sine value for direction
		local sinValue = math.sin(trigX)

		-- When falling DOWN: trigX is positive, sinValue is positive -> gun moves inward/up
		-- Reduce inward movement by 65% (keep 35%) to prevent excessive movement towards center screen
		local isFalling = sinValue > 0
		local fallReduction = isFalling and 0.35 or 1.0  -- 35% of normal when falling, 100% when jumping

		-- Minimal jump movement when ADS (20% of normal jump for all components)
		local adsJumpReduction = (self.IronSightsProgress > 0.1) and 0.20 or 1.0

		-- Apply sine-based movement for smooth arc motion
		-- When jumping UP: Full movement (trigX negative, sinValue negative, fallReduction = 1.0)
		-- When falling DOWN: 35% movement (trigX positive, sinValue positive, fallReduction = 0.35)
		-- All jump components reduced to 20% when ADS for minimal movement
		pos:Add(right * sinValue * scale_r * 0.1 * jumpIntensity * flip * 0.4 * adsJumpReduction * fallReduction)
		pos:Add(-up * sinValue * scale_r * 0.1 * jumpIntensity * 0.4 * adsJumpReduction * fallReduction)
		ang:RotateAroundAxis(forward, sinValue * scale_r * jumpIntensity * flip * 0.4 * adsJumpReduction)

		local xVelocityClamped = self.LateralVelocitySmooth

		-- TFA's square root scaling for high velocities
		if math.abs(xVelocityClamped) > 200 then
			local sign = (xVelocityClamped < 0) and -1 or 1
			xVelocityClamped = (math.sqrt((math.abs(xVelocityClamped) - 200) / 50) * 50 + 200) * sign
		end

		-- ADS tilt reduction: 70% reduction when fully in ADS (allows more tilt while maintaining sight alignment)
		local adsTiltReduction = self.IronSightsProgress > 0.1 and (1 - self.IronSightsProgress * 0.70) or 1.0
		local sprintTiltAmplification = 1.0

		-- Check if we're in the post-reload transition period (waiting to enter sprint)
		local postReloadTransitionEnd = self.Weapon:GetNWFloat("PostReloadTransition", 0)
		local inPostReloadTransition = CurTime() < postReloadTransitionEnd

		-- Amplify tilt during sprint (but NOT during reload - use walking tilt instead)
		-- During reload: walking lateral tilt (sprintTiltAmplification = 1.0)
		-- Reduced amplification from 2.0 to 0.5 to prevent excessive tilt
		if not inPostReloadTransition and self.SprintIntensity > 0.1 and bSprint and not bReloading then
			sprintTiltAmplification = 1 + self.SprintIntensity * 0.5
		end
		local baseTiltAmount = xVelocityClamped * 0.04 * flip * adsTiltReduction * sprintTiltAmplification

		-- Add camera rotation tilt (when turning view while idle or ADS)
		-- Camera turning right (positive angular velocity) = tilt right (positive angle)
		-- Scale based on state: less in ADS to avoid misaligning iron sights
		-- Reduced by 15% from original 0.015 to 0.01275
		local cameraTiltScale = adsTiltReduction * 0.01275  -- Reduced intensity, scaled in ADS
		local cameraTilt = self.CameraRotationVelocity * cameraTiltScale * flip

		-- Combine lateral movement tilt and camera rotation tilt
		local totalTilt = baseTiltAmount + cameraTilt

		-- Apply tilt rotation
		ang:RotateAroundAxis(forward, totalTilt)

		-- Fire mode switch animation
		-- 1) Gun moves slightly back
		-- 2) At the same time, gun moves slightly up and slightly on a right angle
		-- 3) Gun returns to default idle position
		-- All movements happen together smoothly
		if self.FireModeSwitchTime then
			local switchElapsed = ct - self.FireModeSwitchTime
			local totalDuration = 0.4  -- Smooth, not rushed

			if switchElapsed < totalDuration then
				local t = switchElapsed / totalDuration

				-- Smooth sine curve: 0 -> 1 -> 0 over the duration
				local intensity = math.sin(t * math.pi)

				-- All movements happen simultaneously:
				pos:Add(forward * intensity * -0.45)  -- Slightly back
				pos:Add(up * intensity * 0.12)  -- Slightly up
				ang:RotateAroundAxis(forward, intensity * 1.5 * flip)  -- Slight right angle (roll)
			else
				-- Animation complete
				self.FireModeSwitchTime = nil
			end
		end
	end

	-- Early return if no active states and no crouch (all progress values at 0)
	if Mul == 0 and self.CrouchProgress <= 0.001 then
		return pos, ang
	end

	-- TFA-Style Position Calculation: Sequential LerpVector from base position
	-- Start with base idle position (Vector 0,0,0)
	local targetPos = Vector(0, 0, 0)
	local targetAng = Vector(0, 0, 0)

	-- Apply sprint/safety positioning (they use the same position)
	-- SprintProgress handles smooth transitions automatically - no special reload logic needed
	if self.SprintProgress > 0.01 or self.SafetyProgress > 0.01 then
		local sprintSafetyProgress = math.max(self.SprintProgress, self.SafetyProgress)
		local sprintPos = self.RunSightsPos or Vector(0, 0, 0)
		local sprintAng = self.RunSightsAng or Vector(0, 0, 0)

		targetPos = LerpVector(sprintSafetyProgress, targetPos, sprintPos)
		targetAng = LerpVector(sprintSafetyProgress, targetAng, sprintAng)
	end

	-- Apply ADS positioning (overwrites sprint if active, following TFA's priority)
	if self.IronSightsProgress > 0.02 then
		local adsPos = self.SightsPos or Vector(0, 0, 0)
		local adsAng = self.SightsAng or Vector(0, 0, 0)

		-- Special handling for scoped weapons: push gun down and back slightly
		-- Muzzle flash effects are spawned at a distinct position below the scope (handled in FireBurstShot)
		if self.Scoped then
			adsPos = Vector(adsPos.x, adsPos.y - 3, adsPos.z - 2)
		end

		targetPos = LerpVector(self.IronSightsProgress, targetPos, adsPos)
		targetAng = LerpVector(self.IronSightsProgress, targetAng, adsAng)
	end

	-- Apply final position/angle offsets
	if targetAng then
		ang = ang * 1
		ang:RotateAroundAxis(ang:Right(), targetAng.x)
		ang:RotateAroundAxis(ang:Up(), targetAng.y)
		ang:RotateAroundAxis(ang:Forward(), targetAng.z)
	end

	local Right = ang:Right()
	local Up = ang:Up()
	local Forward = ang:Forward()

	pos = pos + targetPos.x * Right
	pos = pos + targetPos.y * Forward
	pos = pos + targetPos.z * Up

	-- TFA-Style Viewmodel Recoil Scaling
	if IsValid(self.Owner) and self.Owner:IsPlayer() then
		-- Allow complete disabling of viewmodel recoil when ADS (like TFA's cl_tfa_viewmodel_vp_enabled)
		local enableViewmodelRecoil = self.ViewModelRecoilEnabled_IronSights
		if enableViewmodelRecoil == nil then
			enableViewmodelRecoil = true  -- Default: enabled
		end

		-- Get ViewPunch values (accumulated recoil)
		local viewPunchP = self.ViewPunchP or 0
		local viewPunchY = self.ViewPunchY or 0

		-- Calculate scaled multipliers based on ADS state using IronSightsProgress
		local pitchMult = Lerp(self.IronSightsProgress,
			self.ViewModelPunchPitchMultiplier or 0.5,
			enableViewmodelRecoil and 0.25 or 0)

		local yawMult = Lerp(self.IronSightsProgress,
			self.ViewModelPunchYawMultiplier or 0.5,
			enableViewmodelRecoil and 0.25 or 0)

		local verticalMult = Lerp(self.IronSightsProgress,
			self.ViewModelPunch_VerticalMultiplier or 0.3,
			enableViewmodelRecoil and 0.1 or 0)

		local maxVerticalOffset = Lerp(self.IronSightsProgress,
			self.ViewModelPunch_MaxVerticalOffset or 3,
			enableViewmodelRecoil and 1 or 0)

		-- Apply scaled rotation recoil
		ang:RotateAroundAxis(ang:Right(), -viewPunchP * pitchMult)
		ang:RotateAroundAxis(ang:Up(), viewPunchY * yawMult)

		-- Apply scaled backward push (negative Y = backward)
		local backwardPush = math.Clamp(viewPunchP * verticalMult, -maxVerticalOffset, maxVerticalOffset)
		pos = pos - Forward * backwardPush
	end

	-- Apply crouch positioning offset with smooth ADS transition
	if self.CrouchPos and self.CrouchAng and self.CrouchProgress > 0.001 then
		-- Additional safety checks for weapon state transitions
		if not IsValid(self) or not IsValid(self.Weapon) then
			return pos, ang
		end

		-- Ensure owner is still valid (weapon switching can invalidate this)
		if not IsValid(self.Owner) or not self.Owner:IsPlayer() then
			return pos, ang
		end

		-- Ensure all required variables exist to prevent crashes
		if not self.CrouchPos.x or not self.CrouchPos.y or not self.CrouchPos.z then
			return pos, ang
		end
		if not self.CrouchAng.x or not self.CrouchAng.y or not self.CrouchAng.z then
			return pos, ang
		end
		if not ang or not ang.Right or not ang.Forward or not ang.Up then
			return pos, ang
		end

		local offset = Vector(self.CrouchPos.x, self.CrouchPos.y, self.CrouchPos.z)
		local angleOffset = Angle(self.CrouchAng.x, self.CrouchAng.y, self.CrouchAng.z)

		-- Apply crouch progress for smooth transitions
		offset = offset * self.CrouchProgress
		angleOffset = angleOffset * self.CrouchProgress

		-- Smoothly fade out crouch positioning when transitioning to ADS
		-- IronSightsProgress = 0 (not in ADS) -> full crouch offset
		-- IronSightsProgress = 1 (fully in ADS) -> no crouch offset
		local adsFadeMultiplier = 1 - self.IronSightsProgress
		offset = offset * adsFadeMultiplier
		angleOffset = angleOffset * adsFadeMultiplier

		-- Safely transform the offset by the view angle
		if ang and ang.Right and ang.Forward and ang.Up then
			local rightVec = ang:Right()
			local forwardVec = ang:Forward()
			local upVec = ang:Up()

			if rightVec and forwardVec and upVec then
				pos = pos + rightVec * offset.x + forwardVec * offset.y + upVec * offset.z
				ang = ang + angleOffset
			end
		end
	end

	return pos, ang
end

-- ============================================================================
-- DrawWorldModel - World model rendering with bone-relative offset positioning
-- ============================================================================

function SWEP:DrawWorldModel()
	local pl = self:GetOwner()

	if IsValid(pl) then
		local boneIndex = pl:LookupBone("ValveBiped.Bip01_R_Hand")
		if boneIndex then
			local pos, ang = pl:GetBonePosition(boneIndex)

			-- Apply positional offset
			pos = pos + ang:Forward() * self.Offset.Pos.Forward +
						ang:Right() * self.Offset.Pos.Right +
						ang:Up() * self.Offset.Pos.Up

			-- Apply rotational offset
			ang:RotateAroundAxis(ang:Up(), self.Offset.Ang.Up)
			ang:RotateAroundAxis(ang:Right(), self.Offset.Ang.Right)
			ang:RotateAroundAxis(ang:Forward(), self.Offset.Ang.Forward)

			-- Cache scale-corrected attachment positions for muzzle flash effects
			-- When Scale != 1, EnableMatrix("RenderMultiply") scales the visual model
			-- around the render origin (pos). GetAttachment returns unscaled bonemerge
			-- positions, so we scale the vector from render origin to attachment to
			-- match where the muzzle visually appears on the scaled model.
			local wmScale = self.Offset.Scale or 1
			if wmScale ~= 1 then
				self.WMCorrectedAttachments = {}
				for i = 1, 4 do
					local attach = self:GetAttachment(i)
					if attach and attach.Pos then
						local corrPos = pos + (attach.Pos - pos) * wmScale
						self.WMCorrectedAttachments[i] = { Pos = corrPos, Ang = attach.Ang }
					end
				end
			else
				self.WMCorrectedAttachments = nil
			end

			-- For models with $bonemerge, temporarily disable it so SetRenderOrigin works
			local wasBoneMerged = self:IsEffectActive(EF_BONEMERGE)
			if wasBoneMerged then
				self:RemoveEffects(EF_BONEMERGE)
			end

			self:SetRenderOrigin(pos)
			self:SetRenderAngles(ang)

			-- Apply scale if specified
			local scale = self.Offset.Scale or 1
			if scale ~= 1 then
				local matrix = Matrix()
				matrix:Scale(Vector(scale, scale, scale))
				self:EnableMatrix("RenderMultiply", matrix)
			end

			-- Apply WorldModelBoneMods if they exist
			local appliedBones = {}
			if self.WorldModelBoneMods then
				for boneName, boneData in pairs(self.WorldModelBoneMods) do
					local boneIdx = self:LookupBone(boneName)
					if boneIdx then
						-- Apply bone manipulations
						if boneData.scale then
							self:ManipulateBoneScale(boneIdx, boneData.scale)
						end
						if boneData.pos then
							self:ManipulateBonePosition(boneIdx, boneData.pos)
						end
						if boneData.angle then
							self:ManipulateBoneAngles(boneIdx, boneData.angle)
						end
						-- Track which bones were modified for cleanup
						appliedBones[boneIdx] = true
					end
				end
			end

			self:DrawModel()

			-- Reset WorldModelBoneMods
			for boneIdx, _ in pairs(appliedBones) do
				self:ManipulateBoneScale(boneIdx, Vector(1, 1, 1))
				self:ManipulateBonePosition(boneIdx, Vector(0, 0, 0))
				self:ManipulateBoneAngles(boneIdx, Angle(0, 0, 0))
			end

			-- Reset scale
			if scale ~= 1 then
				self:DisableMatrix("RenderMultiply")
			end

			-- Re-enable bonemerge if it was active before
			if wasBoneMerged then
				self:AddEffects(EF_BONEMERGE)
			end
		end
	else
		-- Weapon is dropped - render at default position
		self:SetRenderOrigin(nil)
		self:SetRenderAngles(nil)

		-- Apply WorldModelBoneMods if they exist
		local appliedBones = {}
		if self.WorldModelBoneMods then
			for boneName, boneData in pairs(self.WorldModelBoneMods) do
				local boneIdx = self:LookupBone(boneName)
				if boneIdx then
					-- Apply bone manipulations
					if boneData.scale then
						self:ManipulateBoneScale(boneIdx, boneData.scale)
					end
					if boneData.pos then
						self:ManipulateBonePosition(boneIdx, boneData.pos)
					end
					if boneData.angle then
						self:ManipulateBoneAngles(boneIdx, boneData.angle)
					end
					-- Track which bones were modified for cleanup
					appliedBones[boneIdx] = true
				end
			end
		end

		self:DrawModel()

		-- Reset WorldModelBoneMods
		for boneIdx, _ in pairs(appliedBones) do
			self:ManipulateBoneScale(boneIdx, Vector(1, 1, 1))
			self:ManipulateBonePosition(boneIdx, Vector(0, 0, 0))
			self:ManipulateBoneAngles(boneIdx, Angle(0, 0, 0))
		end
	end
end

-- ============================================================================
-- HUD Functions
-- ============================================================================

-- Hide default GMod HUD elements when using M9K:R HUD
-- This prevents the default ammo/health HUD from showing
local M9KR_HudHide = {
	CHudAmmo = true,
	CHudSecondaryAmmo = true,
	CHudHealth = true
}

function SWEP:HUDShouldDraw(name)
	-- Only hide if M9K:R HUD is enabled
	if M9KR_HudHide[name] and GetConVar("m9kr_hud_mode"):GetInt() == 1 then
		return false
	end
end

-- Suppress default GMod ammo HUD when using default HUD mode
-- The clip count already includes the chambered round from tactical reload
function SWEP:DrawAmmo()
	return true
end

-- ============================================================================
-- Utility
-- ============================================================================

-- Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
-- Does not copy entities of course, only copies their reference.
-- WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
function table.FullCopy( tab )

	if (!tab) then return nil end

	local res = {}
	for k, v in pairs( tab ) do
			if (type(v) == "table") then
					res[k] = table.FullCopy(v) --// recursion ho!
			elseif (type(v) == "Vector") then
					res[k] = Vector(v.x, v.y, v.z)
			elseif (type(v) == "Angle") then
					res[k] = Angle(v.p, v.y, v.r)
			else
					res[k] = v
			end
	end

	return res
end
