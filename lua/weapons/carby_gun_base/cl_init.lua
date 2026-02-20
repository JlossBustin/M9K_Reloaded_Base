-- M9K Reloaded Base - Client Init

include("shared.lua")

-- Cached ConVar for HUD mode (avoid GetConVar lookup every frame)
local m9kr_hud_mode = GetConVar("m9kr_hud_mode")

-- Client-side Animation Variable Defaults

SWEP.BreathIntensity = 0
SWEP.WalkIntensity = 0
SWEP.SprintIntensity = 0
SWEP.JumpVelocity = 0
SWEP.JumpVelocitySmooth = 0
SWEP.LateralVelocity = 0
SWEP.LateralVelocitySmooth = 0
SWEP.LastGroundState = true

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
	if not self.WepSelectIconMat and self.Gun then
		self.WepSelectIconMat = Material("vgui/hud/" .. self.Gun)
	end

	if self.WepSelectIconMat and not self.WepSelectIconMat:IsError() then
		surface.SetDrawColor(255, 255, 255, alpha)
		surface.SetMaterial(self.WepSelectIconMat)

		y = y + 10
		x = x + 10
		wide = wide - 20

		surface.DrawTexturedRect(x, y, wide, wide * 0.5)
	end
end

-- ADS / Sprint / Safety / FOV Input State Management
local IRON_IN_SOUND = "m9k_indicators/ironin.wav"
local IRON_OUT_SOUND = "m9k_indicators/ironout.wav"

local FOV_TRANSITION_FAST = 0.2
local FOV_TRANSITION_NORMAL = 0.2
local FOV_TRANSITION_SAFETY = 0.25
local FOV_TRANSITION_FROM_SPRINT = 0.35

function SWEP:M9KR_StartFOVTransition(targetFOV, duration)
	if not IsValid(self.Owner) then return end

	local actualStart = self.m9kr_FOVCurrent or 0
	if actualStart == 0 then
		actualStart = self.Owner:GetFOV()
	end

	self.m9kr_FOVStart = actualStart
	-- targetFOV == 0 means "return to default" (exit ADS)
	self.m9kr_FOVReturningToDefault = (targetFOV == 0)
	self.m9kr_FOVTarget = targetFOV == 0 and self.Owner:GetFOV() or targetFOV
	self.m9kr_FOVTransitionStart = CurTime()
	self.m9kr_FOVTransitionDuration = duration or FOV_TRANSITION_NORMAL
end

function SWEP:M9KR_GetADSTargetFOV()
	if self.Scoped and self.Secondary and self.Secondary.ScopeZoom then
		return 75 / self.Secondary.ScopeZoom
	elseif self.Secondary and self.Secondary.IronFOV then
		return self.Secondary.IronFOV
	end
	return 0
end

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

	-- ADS toggle
	if attack2Down and not self.m9kr_LastAttack2State and not useDown and not isActuallySprinting and not isReloading and not isSafe and not isSprintJumping then
		self:M9KR_StartFOVTransition(self:M9KR_GetADSTargetFOV(), FOV_TRANSITION_NORMAL)
		self.m9kr_IsInADS = true
		self:EmitSound(IRON_IN_SOUND, 50, 100)
	end

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

	if not attack2Down then
		self.m9kr_Attack2HeldDuringSprint = false
	end

	self.m9kr_LastAttack2State = attack2Down

	-- Sprint state
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

	self.SprintJumping = isSprintJumping

	-- Safety state
	if isSafe ~= self.m9kr_LastSafetyState then
		if isSafe then
			self:M9KR_StartFOVTransition(0, FOV_TRANSITION_SAFETY)
			self.m9kr_IsInADS = false
		end
	end
	self.m9kr_LastSafetyState = isSafe

	-- Reload state
	if isReloading and not self.m9kr_LastReloadState then
		self:M9KR_StartFOVTransition(0, FOV_TRANSITION_FAST)
		self.m9kr_IsInADS = false
	end

	if not isReloading and self.m9kr_LastReloadState then
		if attack2Down and not useDown and not isActuallySprinting then
			self:M9KR_StartFOVTransition(self:M9KR_GetADSTargetFOV(), FOV_TRANSITION_NORMAL)
			self.m9kr_IsInADS = true
		end
	end
	self.m9kr_LastReloadState = isReloading

	-- FOV transition update
	local elapsed = CurTime() - (self.m9kr_FOVTransitionStart or 0)
	local dur = self.m9kr_FOVTransitionDuration or 0.2
	local t = math.Clamp(elapsed / dur, 0, 1)
	t = 1 - math.pow(1 - t, 3) -- Ease-out cubic

	local newFOV = Lerp(t, self.m9kr_FOVStart or 0, self.m9kr_FOVTarget or 0)
	if t >= 1 and self.m9kr_FOVReturningToDefault then
		self.m9kr_FOVCurrent = 0
	else
		self.m9kr_FOVCurrent = newFOV
	end

	-- Scoped viewmodel visibility
	if self.Scoped and self.m9kr_IsInADS then
		self.ShouldDrawViewModel = false
		self.isScoped = true
	else
		self.ShouldDrawViewModel = true
		self.isScoped = false
	end
end

function SWEP:CalcView(ply, origin, angles, fov)
	if not IsValid(ply) or ply ~= LocalPlayer() then return end

	local currentFOV = self.m9kr_FOVCurrent or 0
	if currentFOV > 0 then
		return origin, angles, currentFOV
	end
end

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

	self.IronSightsProgress = self.IronSightsProgress or 0
	self.SprintProgress = self.SprintProgress or 0
	self.SafetyProgress = self.SafetyProgress or 0
	self.CrouchProgress = self.CrouchProgress or 0

	local ft = FrameTime()

	-- When reloading, use idle positioning (not sprint) - player can still move with walking bob/tilt
	local ironTarget = (bIron and not bSafe) and 1 or 0
	local sprintTarget = (bSprint and not bSafe and not bIron and not bReloading) and 1 or 0
	local safetyTarget = bSafe and 1 or 0
	local crouchTarget = bCrouching and 1 or 0

	-- Speeds must match IRONSIGHT_TIME
	local IRONSIGHT_TIME = 0.55
	local adsTransitionSpeed = 12.5 / (IRONSIGHT_TIME / 0.3)
	local sprintTransitionSpeed = 7.5
	local safetyTransitionSpeed = 12.5 / ((IRONSIGHT_TIME * 0.5) / 0.3)
	local crouchTransitionSpeed = 2.5

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

function SWEP:GetSafetyTransitionMul()
	if not self.GetIsOnSafe then return 0 end
	if not self:GetIsOnSafe() then return 0 end

	local transitionTime = 0.25
	local elapsed = CurTime() - (self.m9kr_SafetyTransitionStart or 0)
	return math.Clamp(elapsed / transitionTime, 0, 1)
end

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

-- Belt-Fed Weapon Support
-- Supports 3 belt display methods: bone-based, bodygroup-based, multi-bodygroup
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

local function BeltUpdateBodygroup(vm, weapon, bodygroup)
	vm:SetBodygroup(weapon.BeltBG, bodygroup)
end

-- Each bullet is a separate bodygroup: 0=visible, 1=blank
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

-- Bodygroups persist on the viewmodel entity across model changes
local function BeltResetAllBodygroups(vm)
	if not IsValid(vm) then return end
	for bgIndex = 0, 10 do
		vm:SetBodygroup(bgIndex, 0)
	end
end

function SWEP:UpdateBeltAmmo()
	local ply = self.Owner
	if not IsValid(ply) then return end

	local vm = ply:GetViewModel()
	if not IsValid(vm) then return end

	-- Bones/bodygroups persist across model changes, so detect and reset
	local currentVMModel = vm:GetModel()
	if self.m9kr_BeltLastModel ~= currentVMModel then
		self.m9kr_BeltNeedsBoneReset = true
		self.m9kr_BeltReloadStart = nil
		self.m9kr_BeltReloadWasEmpty = nil
		self.m9kr_BeltLastModel = currentVMModel
	end

	local isBoneBased = self.BeltChain ~= nil
	local isBodygroupBased = self.BeltBG ~= nil and self.BeltMax ~= nil
	local isMultiBodygroup = self.BeltBodygroups ~= nil

	if not isBoneBased and not isBodygroupBased and not isMultiBodygroup then return end

	local isReloading = self.Reloading or self:GetNWBool("Reloading", false)

	if isBoneBased then
		-- Bone-based belt
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
		-- Bodygroup-based belt (applied in PreDrawViewModel; engine resets bodygroups before render)
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

			if reloadElapsed < hideTime then
				self.m9kr_BeltBodygroupValue = math.Clamp(self:Clip1(), 0, self.BeltMax - 1)
			elseif reloadElapsed < showTime then
				self.m9kr_BeltBodygroupValue = 0
			else
				self.m9kr_BeltBodygroupValue = self.BeltMax - 1
			end
		else
			self.m9kr_BeltReloadStart = nil
			self.m9kr_BeltReloadWasEmpty = nil
			self.m9kr_BeltBodygroupValue = math.Clamp(self:Clip1(), 0, self.BeltMax - 1)
		end

	elseif isMultiBodygroup then
		-- Multi-bodygroup belt (applied in PreDrawViewModel)
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
				self.m9kr_BeltMultiShowAll = true
				self.m9kr_BeltMultiHideAll = false
			elseif reloadElapsed >= hideTime then
				self.m9kr_BeltMultiShowAll = false
				self.m9kr_BeltMultiHideAll = true
			else
				self.m9kr_BeltMultiShowAll = false
				self.m9kr_BeltMultiHideAll = false
			end
		else
			self.m9kr_BeltReloadStart = nil
			self.m9kr_BeltReloadWasEmpty = nil
			self.m9kr_BeltMultiShowAll = false
			self.m9kr_BeltMultiHideAll = false
		end
	end
end

hook.Add("PreDrawViewModel", "M9KR_ViewModelHandler", function(vm, ply, weapon)
	if not IsValid(vm) then return end
	if not IsValid(weapon) then return end

	if weapon.ShouldDrawViewModel == false then
		return true
	end

	-- Reset bones/bodygroups after viewmodel model change
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

	if weapon.ApplyViewModelBoneMods and weapon.ViewModelBoneMods then
		weapon:ApplyViewModelBoneMods(vm)
	end

	-- Must be set here, not Think (engine resets bodygroups before rendering)
	if weapon.BeltBG and weapon.m9kr_BeltBodygroupValue ~= nil then
		vm:SetBodygroup(weapon.BeltBG, weapon.m9kr_BeltBodygroupValue)
	end

	if weapon.BeltBodygroups then
		if weapon.m9kr_BeltMultiHideAll then
			for threshold, bgIndex in pairs(weapon.BeltBodygroups) do
				vm:SetBodygroup(bgIndex, 1)
			end
		else
			local clip = weapon:Clip1()
			for threshold, bgIndex in pairs(weapon.BeltBodygroups) do
				if weapon.m9kr_BeltMultiShowAll or clip > threshold then
					vm:SetBodygroup(bgIndex, 0)
				else
					vm:SetBodygroup(bgIndex, 1)
				end
			end
		end
	end
end)

-- Fallback for models without QC animation events (no muzzle flash or EjectBrass events).
-- Effects are normally consumed by FireAnimationEvent; this fires only after a time delay
-- if no QC event was detected.
hook.Add("PostDrawViewModel", "M9KR_DeferredEffects", function(vm, ply, weapon)
	if not IsValid(weapon) then return end

	if weapon.m9kr_PendingMuzzleFlash and not weapon.m9kr_HasQCMuzzleEvent then
		local elapsed = CurTime() - (weapon.m9kr_PendingMuzzleFlash.time or 0)
		if elapsed > 0.3 then
			local pending = weapon.m9kr_PendingMuzzleFlash
			weapon.m9kr_PendingMuzzleFlash = nil

			if IsValid(ply) then
				local fx = EffectData()
				fx:SetEntity(weapon)
				fx:SetOrigin(ply:GetShootPos())

				local muzzleDir = ply:GetAimVector()
				local attId = weapon:LookupAttachment(weapon.MuzzleAttachment or "1")
				if attId and attId > 0 then
					local att = vm:GetAttachment(attId)
					if att and att.Ang then
						muzzleDir = att.Ang:Forward()
					end
				end

				fx:SetNormal(muzzleDir)
				fx:SetAttachment(weapon.MuzzleAttachment)

				util.Effect(pending.name, fx)
				if pending.smoke then
					util.Effect("m9kr_muzzlesmoke", fx)
				end
			end
		end
	end

	if weapon.m9kr_PendingShellEject and not weapon.m9kr_HasQCShellEvent then
		local elapsed = CurTime() - (weapon.m9kr_PendingShellEjectTime or 0)
		if elapsed > 0.3 then
			weapon.m9kr_PendingShellEject = nil
			weapon.m9kr_PendingShellEjectTime = nil
			if weapon.EjectShell then
				weapon:EjectShell()
			end
		end
	end
end)

-- Low Ammo Warning System

CreateClientConVar("m9kr_low_ammo_threshold", "33", true, false, "Low ammo warning threshold (percentage of magazine)", 0, 100)

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

for _, soundPath in pairs(LowAmmoSoundByAmmoType) do
	util.PrecacheSound(soundPath)
end
for _, soundPath in pairs(LastAmmoSoundByAmmoType) do
	util.PrecacheSound(soundPath)
end

-- Called after TakePrimaryAmmo; Clip1() is already decremented.
function SWEP:CheckLowAmmo()
	if self.NoLowAmmoWarning then return end
	if not self.Primary or not self.Primary.ClipSize then return end

	local clip = self:Clip1()
	local maxClip = self.Primary.ClipSize

	if maxClip <= 1 then return end

	local threshold = GetConVar("m9kr_low_ammo_threshold"):GetInt() / 100
	local isLowAmmo = clip <= (maxClip * threshold) and clip > 0

	-- For high-RPM weapons with SoundIndicatorInterval, throttle the warning sound
	if isLowAmmo then
		local shouldPlayWarning = true

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

			if ammoTypeName == "SniperPenetratedRound" and not self.BoltAction then
				snd = "m9k_indicators/lowammo_indicator_dmr.wav"
			end

			self:EmitSound(snd, 60, 100, 0.5, CHAN_AUTO)
		end
	end

	if clip == 0 then
		local ammoType = self:GetPrimaryAmmoType()
		local ammoTypeName = game.GetAmmoName(ammoType) or "ar2"
		local snd = LastAmmoSoundByAmmoType[ammoTypeName] or "m9k_indicators/lowammo_dry_ar.wav"

		-- Semi-auto snipers (DMRs) get a distinct sound from bolt-action
		if ammoTypeName == "SniperPenetratedRound" and not self.BoltAction then
			snd = "m9k_indicators/lowammo_dry_dmr.wav"
		end

		self:EmitSound(snd, 60, 100, 0.5, CHAN_AUTO)

		self.m9kr_LowAmmoShotsSinceWarning = 0
	end

	-- Reset so first warning plays immediately on transition into low ammo
	if isLowAmmo and not self.m9kr_LowAmmoWasLow then
		self.m9kr_LowAmmoShotsSinceWarning = self.SoundIndicatorInterval or 0
	end

	self.m9kr_LowAmmoWasLow = isLowAmmo
end

-- Viewmodel Shell Ejection (CLIENT-only: uses GetViewModel, LocalPlayer, util.Effect)
function SWEP:EjectShell()
	if self.NoShellEject then return end
	if not IsValid(self) or not IsValid(self.Owner) then return end
	if not self.ShellModel then return end

	if self.Owner ~= LocalPlayer() then return end

	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then return end

	-- Attachment priority: QC-cached > weapon property > default 2
	local attachmentId = self._qcShellAttachment or tonumber(self.ShellEjectAttachment) or 2

	local attachment = vm:GetAttachment(attachmentId)
	if not attachment then return end

	local effectData = EffectData()
	effectData:SetOrigin(attachment.Pos)
	effectData:SetNormal(attachment.Ang:Forward())
	effectData:SetEntity(self)
	effectData:SetAttachment(attachmentId)

	util.Effect("m9kr_shell", effectData)
end

-- Worldmodel Shell Ejection

local ShellEjectionOffset = {
	Forward = 5,
	Right = 2,
	Up = 1
}

function SWEP:CalculateWorldmodelShellPos()
	local wepPos = self:GetPos()
	local wepAng = self:GetAngles()

	local shellPos = wepPos +
		wepAng:Forward() * ShellEjectionOffset.Forward +
		wepAng:Right() * ShellEjectionOffset.Right +
		wepAng:Up() * ShellEjectionOffset.Up

	local shellAng = Angle(wepAng.p, wepAng.y + 90, wepAng.r)

	return shellPos, shellAng
end

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

hook.Add("EntityFireBullets", "M9KR_WorldmodelShells", function(entity, data)
	if not IsValid(entity) then return end

	local owner
	if entity:IsPlayer() then
		owner = entity
	elseif entity:IsWeapon() then
		owner = entity:GetOwner()
	else
		return
	end

	if not IsValid(owner) or not owner:IsPlayer() then return end

	if owner == LocalPlayer() then return end

	local weapon = owner:GetActiveWeapon()
	if not IsValid(weapon) or not weapon.ShellModel then return end

	if weapon.SpawnWorldmodelShell then
		weapon:SpawnWorldmodelShell()
	end
end)

-- Bullet Impact Effects
-- ConVars created server-side in m9kr_autoload.lua, replicated to clients

local M9KR_BulletImpact = GetConVar("m9kr_bullet_impact")
local M9KR_MetalImpact = GetConVar("m9kr_metal_impact")

hook.Add("EntityFireBullets", "M9KR_BulletImpactEffects", function(entity, data)
	if not IsValid(entity) then return end

	local wep
	if entity:IsPlayer() then
		wep = entity:GetActiveWeapon()
	elseif entity:IsWeapon() then
		wep = entity
	else
		return
	end

	if not IsValid(wep) then return end

	if not wep.Base or not M9KR.WeaponBases[wep.Base] then return end

	local originalCallback = data.Callback
	data.Callback = function(attacker, tr, dmginfo)
		local result
		if originalCallback then
			result = originalCallback(attacker, tr, dmginfo)
		end

		if IsFirstTimePredicted() and tr.HitPos then
			-- Skip for flesh (use default GMod blood effects)
			if tr.MatType == MAT_FLESH or tr.MatType == MAT_ALIENFLESH then
				return result
			end

			local fx = EffectData()
			fx:SetOrigin(tr.HitPos)
			fx:SetNormal(tr.HitNormal or Vector(0, 0, 1))
			fx:SetEntity(entity)

			local penetration = 14
			if IsValid(wep) and wep.ShellModel and M9KR and M9KR.Ballistics then
				local ballisticsData = M9KR.Ballistics.GetData(wep.ShellModel)
				if ballisticsData then
					penetration = ballisticsData.penetration
				end
			end

			fx:SetMagnitude(penetration)

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

-- GetViewModelPosition

function SWEP:GetViewModelPosition(pos, ang)
	if not IsValid(self) or not IsValid(self.Weapon) then
		return pos, ang
	end

	if not self.Weapon.GetClass or not self.Weapon:GetClass() then
		return pos, ang
	end

	if not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return pos, ang
	end

	if not self.IronSightsPos then
		return pos, ang
	end

	local bIron = self.m9kr_IsInADS or false
	local bSprint = self.m9kr_IsInSprint or false
	local bReloading = self.Weapon:GetNWBool("Reloading")

	local bCrouching = false
	if IsValid(self.Owner) and self.Owner:IsPlayer() then
		bCrouching = self.Owner:KeyDown(IN_DUCK) or self.Owner:Crouching()
	end

	self.bWasReloading = self.bWasReloading or false

	if bReloading ~= self.bWasReloading then
		if bReloading then
			self.DrawCrosshair = false
		elseif not bReloading then
			if self:GetIsOnSafe() then
				self.DrawCrosshair = false
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

	if not self.IronSightsProgress then self.IronSightsProgress = 0 end
	if not self.SprintProgress then self.SprintProgress = 0 end
	if not self.SafetyProgress then self.SafetyProgress = 0 end
	if not self.CrouchProgress then self.CrouchProgress = 0 end

	local bSafe = self:GetIsOnSafe()

	local wasInADS = self.bLastIron or false
	local wasInSprint = self.bLastSprint or false
	local wasInSafety = self.bLastSafety or false

	-- Crosshair visibility
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

	-- Priority: Safety > Sprint > ADS
	local Mul = math.max(self.SafetyProgress, self.SprintProgress, self.IronSightsProgress)

	if IsValid(self.Owner) and self.Owner:IsPlayer() then
		self.BreathIntensity = self.BreathIntensity or 0
		self.WalkIntensity = self.WalkIntensity or 0
		self.SprintIntensity = self.SprintIntensity or 0
		self.JumpVelocitySmooth = self.JumpVelocitySmooth or 0
		self.LateralVelocitySmooth = self.LateralVelocitySmooth or 0
		self.JumpIntensitySmooth = self.JumpIntensitySmooth or 0
		self.LastEyeAngles = self.LastEyeAngles or self.Owner:EyeAngles()
		self.CameraRotationVelocity = self.CameraRotationVelocity or 0

		-- Fire mode change detection
		local currentNetworkedMode = self.Weapon:GetNWInt("CurrentFireMode", 1)
		self.LastNetworkedFireMode = self.LastNetworkedFireMode or currentNetworkedMode
		if currentNetworkedMode ~= self.LastNetworkedFireMode then
			-- Skip animation when toggling safety (within 0.5s of safety toggle)
			local recentSafetyToggle = self.SafetyToggleTime and (CurTime() - self.SafetyToggleTime) < 0.5
			if not recentSafetyToggle and not self:GetIsOnSafe() then
				self.FireModeSwitchTime = CurTime()
				-- SERVER EmitSound may not reach owning player reliably in MP
				self.Weapon:EmitSound("Weapon_AR2.Empty")
			end
			self.LastNetworkedFireMode = currentNetworkedMode
		end

		local rawFrameTime = FrameTime()
		local isPaused = (rawFrameTime == 0)
		local ft = isPaused and 0.001 or math.Clamp(rawFrameTime, 0.001, 0.1)
		local ct = CurTime()

		-- CurTime pauses in SP and is unaffected by prediction re-runs in MP
		local animTime = CurTime()

		local currentEyeAngles = self.Owner:EyeAngles()
		local angleDiff = currentEyeAngles.y - self.LastEyeAngles.y

		if angleDiff > 180 then
			angleDiff = angleDiff - 360
		elseif angleDiff < -180 then
			angleDiff = angleDiff + 360
		end

		local angularVelocity = ft > 0 and (angleDiff / ft) or 0
		self.CameraRotationVelocity = Lerp(ft * 5, self.CameraRotationVelocity, angularVelocity)
		self.LastEyeAngles = currentEyeAngles

		local velocity = self.Owner:GetVelocity()
		local speed = velocity:Length2D()
		local isOnGround = self.Owner:IsOnGround()
		local isJumping = not isOnGround and math.abs(velocity.z) > 10

		local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)

		local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and speed > 50 and isOnGround and isPressingMovement
		if self.JumpCancelsSprint and not isOnGround and (self.SprintJumping or false) then
			isActuallySprinting = false
		end

		local isReloading = self.Weapon:GetNWBool("Reloading")

		local isSprinting = isActuallySprinting and not isReloading
		local isWalking = speed > 20 and (not isSprinting or isReloading) and isOnGround
		local isShooting = self.Weapon:GetNextPrimaryFire() > ct - 0.15

		local isADS = self.IronSightsProgress > 0.1
		local targetBreath = (speed < 5 and not isShooting and not isReloading and isOnGround and not isADS) and 1 or 0
		local targetWalk = isWalking and math.Clamp(speed / 200, 0, 1) or 0
		local targetSprint = isSprinting and math.Clamp(speed / 250, 0, 1) or 0

		local breathSpeed = ft * 2
		local walkSpeed = ft * 6
		local sprintSpeed = ft * 4

		self.BreathIntensity = Lerp(breathSpeed, self.BreathIntensity, targetBreath)
		self.WalkIntensity = Lerp(walkSpeed, self.WalkIntensity, targetWalk)
		self.SprintIntensity = Lerp(sprintSpeed, self.SprintIntensity, targetSprint)

		local zVelocity = velocity.z
		self.JumpVelocitySmooth = Lerp(ft * 7, self.JumpVelocitySmooth or 0, zVelocity)

		local eyeAng = self.Owner:EyeAngles()
		local rightVec = eyeAng:Right()
		rightVec.z = 0
		rightVec:Normalize()
		local lateralVel = velocity:Dot(rightVec)
		self.LateralVelocitySmooth = Lerp(ft * 3, self.LateralVelocitySmooth, lateralVel)

		local up = ang:Up()
		local right = ang:Right()
		local forward = ang:Forward()
		local flip = self.ViewModelFlip and -1 or 1

		local aimMult = 1 - self.IronSightsProgress * 0.85

		if self.BreathIntensity > 0.01 then
			local breatheMult = self.BreathIntensity * aimMult
			local breatheTime = animTime * 1.5

			pos:Add(right * math.sin(breatheTime) * breatheMult * flip * 0.1)
			pos:Add(up * math.cos(breatheTime * 0.5) * breatheMult * 0.06)
			ang:RotateAroundAxis(forward, math.sin(breatheTime) * breatheMult * flip * 0.5)
		end

		if self.WalkIntensity > 0.01 then
			local walkMult = self.WalkIntensity * aimMult
			local walkTime = animTime * 8

			pos:Add(up * math.abs(math.sin(walkTime * 2)) * walkMult * 0.05)
			pos:Add(right * math.sin(walkTime) * walkMult * flip * 0.25)
			ang:RotateAroundAxis(right, -math.sin(walkTime * 2) * walkMult * 1.2)
			ang:RotateAroundAxis(forward, math.sin(walkTime) * walkMult * flip * 1.5)
		end

		if self.SprintIntensity > 0.01 then
			local sprintMult = self.SprintIntensity
			local sprintTime = animTime * 9

			pos:Add(up * math.abs(math.sin(sprintTime * 2)) * sprintMult * 0.1)
			pos:Add(right * math.sin(sprintTime) * sprintMult * flip * 0.3)
			ang:RotateAroundAxis(right, -math.sin(sprintTime * 2) * sprintMult * 2)
			ang:RotateAroundAxis(forward, math.sin(sprintTime) * sprintMult * flip * 1.8)
		end

		local trigX = -math.Clamp(self.JumpVelocitySmooth / 200, -1, 1) * math.pi / 2

		local rawJumpIntensity = (3 + math.Clamp(math.abs(self.JumpVelocitySmooth) - 100, 0, 200) / 200 * 4) * (1 - self.IronSightsProgress * 0.85)

		local jumpIntensityTarget = isJumping and rawJumpIntensity or 0
		self.JumpIntensitySmooth = Lerp(ft * 5, self.JumpIntensitySmooth, jumpIntensityTarget)
		local jumpIntensity = self.JumpIntensitySmooth

		local isScopedWeapon = self.Base == "carby_scoped_base"
		local scopedADSReduction = (isScopedWeapon and bIron) and 0.4 or 1.0
		jumpIntensity = jumpIntensity * scopedADSReduction

		local scale_r = -6
		local sinValue = math.sin(trigX)

		local isFalling = sinValue > 0
		local fallReduction = isFalling and 0.35 or 1.0
		local adsJumpReduction = (self.IronSightsProgress > 0.1) and 0.20 or 1.0

		pos:Add(right * sinValue * scale_r * 0.1 * jumpIntensity * flip * 0.4 * adsJumpReduction * fallReduction)
		pos:Add(-up * sinValue * scale_r * 0.1 * jumpIntensity * 0.4 * adsJumpReduction * fallReduction)
		ang:RotateAroundAxis(forward, sinValue * scale_r * jumpIntensity * flip * 0.4 * adsJumpReduction)

		local xVelocityClamped = self.LateralVelocitySmooth

		-- Square root scaling for high velocities
		if math.abs(xVelocityClamped) > 200 then
			local sign = (xVelocityClamped < 0) and -1 or 1
			xVelocityClamped = (math.sqrt((math.abs(xVelocityClamped) - 200) / 50) * 50 + 200) * sign
		end

		local adsTiltReduction = self.IronSightsProgress > 0.1 and (1 - self.IronSightsProgress * 0.70) or 1.0
		local sprintTiltAmplification = 1.0

		local postReloadTransitionEnd = self.Weapon:GetNWFloat("PostReloadTransition", 0)
		local inPostReloadTransition = CurTime() < postReloadTransitionEnd

		if not inPostReloadTransition and self.SprintIntensity > 0.1 and bSprint and not bReloading then
			sprintTiltAmplification = 1 + self.SprintIntensity * 0.5
		end
		local baseTiltAmount = xVelocityClamped * 0.04 * flip * adsTiltReduction * sprintTiltAmplification

		local cameraTiltScale = adsTiltReduction * 0.01275
		local cameraTilt = self.CameraRotationVelocity * cameraTiltScale * flip

		local totalTilt = baseTiltAmount + cameraTilt
		ang:RotateAroundAxis(forward, totalTilt)

		-- Fire mode switch animation
		if self.FireModeSwitchTime then
			local switchElapsed = ct - self.FireModeSwitchTime
			local totalDuration = 0.4

			if switchElapsed < totalDuration then
				local t = switchElapsed / totalDuration

				local intensity = math.sin(t * math.pi)

				pos:Add(forward * intensity * -0.45)
				pos:Add(up * intensity * 0.12)
				ang:RotateAroundAxis(forward, intensity * 1.5 * flip)
			else
				self.FireModeSwitchTime = nil
			end
		end
	end

	if Mul == 0 and self.CrouchProgress <= 0.001 then
		return pos, ang
	end

	local targetPos = Vector(0, 0, 0)
	local targetAng = Vector(0, 0, 0)

	-- Sprint/safety positioning (shared position)
	if self.SprintProgress > 0.01 or self.SafetyProgress > 0.01 then
		local sprintSafetyProgress = math.max(self.SprintProgress, self.SafetyProgress)
		local sprintPos = self.RunSightsPos or Vector(0, 0, 0)
		local sprintAng = self.RunSightsAng or Vector(0, 0, 0)

		targetPos = LerpVector(sprintSafetyProgress, targetPos, sprintPos)
		targetAng = LerpVector(sprintSafetyProgress, targetAng, sprintAng)
	end

	-- ADS positioning
	if self.IronSightsProgress > 0.02 then
		local adsPos = self.SightsPos or Vector(0, 0, 0)
		local adsAng = self.SightsAng or Vector(0, 0, 0)

		if self.Scoped then
			adsPos = Vector(adsPos.x, adsPos.y - 3, adsPos.z - 2)
		end

		targetPos = LerpVector(self.IronSightsProgress, targetPos, adsPos)
		targetAng = LerpVector(self.IronSightsProgress, targetAng, adsAng)
	end

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

	-- Crouch positioning
	if self.CrouchPos and self.CrouchAng and self.CrouchProgress > 0.001 then
		if not IsValid(self) or not IsValid(self.Weapon) then
			return pos, ang
		end

		if not IsValid(self.Owner) or not self.Owner:IsPlayer() then
			return pos, ang
		end

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

		offset = offset * self.CrouchProgress
		angleOffset = angleOffset * self.CrouchProgress

		-- Fade out crouch offset when entering ADS
		local adsFadeMultiplier = 1 - self.IronSightsProgress
		offset = offset * adsFadeMultiplier
		angleOffset = angleOffset * adsFadeMultiplier

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


function SWEP:DrawWorldModel()
	local pl = self:GetOwner()

	if IsValid(pl) then
		local boneIndex = pl:LookupBone("ValveBiped.Bip01_R_Hand")
		if boneIndex then
			local pos, ang = pl:GetBonePosition(boneIndex)

			pos = pos + ang:Forward() * self.Offset.Pos.Forward +
						ang:Right() * self.Offset.Pos.Right +
						ang:Up() * self.Offset.Pos.Up

			ang:RotateAroundAxis(ang:Up(), self.Offset.Ang.Up)
			ang:RotateAroundAxis(ang:Right(), self.Offset.Ang.Right)
			ang:RotateAroundAxis(ang:Forward(), self.Offset.Ang.Forward)

			-- GetAttachment returns unscaled positions, so correct them to match
			-- the visually scaled model when Scale != 1
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

			-- Temporarily disable $bonemerge so SetRenderOrigin works
			local wasBoneMerged = self:IsEffectActive(EF_BONEMERGE)
			if wasBoneMerged then
				self:RemoveEffects(EF_BONEMERGE)
			end

			self:SetRenderOrigin(pos)
			self:SetRenderAngles(ang)

			local scale = self.Offset.Scale or 1
			if scale ~= 1 then
				local matrix = Matrix()
				matrix:Scale(Vector(scale, scale, scale))
				self:EnableMatrix("RenderMultiply", matrix)
			end

			local appliedBones = {}
			if self.WorldModelBoneMods then
				for boneName, boneData in pairs(self.WorldModelBoneMods) do
					local boneIdx = self:LookupBone(boneName)
					if boneIdx then
						if boneData.scale then
							self:ManipulateBoneScale(boneIdx, boneData.scale)
						end
						if boneData.pos then
							self:ManipulateBonePosition(boneIdx, boneData.pos)
						end
						if boneData.angle then
							self:ManipulateBoneAngles(boneIdx, boneData.angle)
						end
						appliedBones[boneIdx] = true
					end
				end
			end

			self:DrawModel()

			for boneIdx, _ in pairs(appliedBones) do
				self:ManipulateBoneScale(boneIdx, Vector(1, 1, 1))
				self:ManipulateBonePosition(boneIdx, Vector(0, 0, 0))
				self:ManipulateBoneAngles(boneIdx, Angle(0, 0, 0))
			end

			if scale ~= 1 then
				self:DisableMatrix("RenderMultiply")
			end

			if wasBoneMerged then
				self:AddEffects(EF_BONEMERGE)
			end
		end
	else
		self:SetRenderOrigin(nil)
		self:SetRenderAngles(nil)

		local appliedBones = {}
		if self.WorldModelBoneMods then
			for boneName, boneData in pairs(self.WorldModelBoneMods) do
				local boneIdx = self:LookupBone(boneName)
				if boneIdx then
					if boneData.scale then
						self:ManipulateBoneScale(boneIdx, boneData.scale)
					end
					if boneData.pos then
						self:ManipulateBonePosition(boneIdx, boneData.pos)
					end
					if boneData.angle then
						self:ManipulateBoneAngles(boneIdx, boneData.angle)
					end
					appliedBones[boneIdx] = true
				end
			end
		end

		self:DrawModel()

		for boneIdx, _ in pairs(appliedBones) do
			self:ManipulateBoneScale(boneIdx, Vector(1, 1, 1))
			self:ManipulateBonePosition(boneIdx, Vector(0, 0, 0))
			self:ManipulateBoneAngles(boneIdx, Angle(0, 0, 0))
		end
	end
end

local M9KR_HudHide = {
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true,
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudSquadStatus"] = true,
	["CHudCrosshair"] = true,
}

function SWEP:HUDShouldDraw(name)
	-- Fast path: only process HUD elements we manage
	if not M9KR_HudHide[name] then return end

	-- Crosshair hiding (applies regardless of HUD mode)
	if name == "CHudCrosshair" and self.DrawCrosshair == false then
		return false
	end

	local hudMode = m9kr_hud_mode:GetInt()
	if hudMode == 0 then return end

	-- Mode >= 1: Hide default ammo (custom weapon HUD replaces it)
	if name == "CHudAmmo" or name == "CHudSecondaryAmmo" then
		return false
	end

	-- Mode 3 or 4: Hide default health/armor
	if (hudMode == 3 or hudMode == 4) and (name == "CHudHealth" or name == "CHudBattery") then
		return false
	end

	-- Mode 2 or 4: Hide default squad
	if (hudMode == 2 or hudMode == 4) and name == "CHudSquadStatus" then
		return false
	end
end

function SWEP:DrawAmmo()
	return true
end

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
