-- Variables that are used on both client and server
SWEP.Category = ""
SWEP.Author = "Generic Default, Worshipper, Clavus, and Bob"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.Base = "carby_gun_base"
SWEP.MuzzleAttachment = "1"
SWEP.ShellEjectAttachment = "2"
SWEP.DrawCrosshair = true
SWEP.ViewModelFOV = 65
SWEP.ViewModelFlip = true

SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.Primary.Sound = Sound("")
SWEP.Primary.RPM = 0
SWEP.Primary.ClipSize = 0
SWEP.Primary.DefaultClip = 0
SWEP.Primary.KickUp = 0
SWEP.Primary.KickDown = 0
SWEP.Primary.KickHorizontal = 0
SWEP.Primary.Ammo = "none"
SWEP.Primary.Reloading = false

SWEP.ReloadCancelled = false
SWEP.ReloadFinishing = false
SWEP.InsertingShell = false

SWEP.Secondary.Ammo = ""
SWEP.Secondary.IronFOV = 0

SWEP.IronSightsPos = Vector(2.4537, 1.0923, 0.2696)
SWEP.IronSightsAng = Vector(0.0186, -0.0547, 0)

SWEP.ShotgunReloading = false
SWEP.ShotgunFinish = 0.5
SWEP.ShellTime = 0.35
SWEP.InsertingShell = false

SWEP.NextReload = 0

-- Chamber system variables (+1 reload mechanic for lever-action and pump-action shotguns)
SWEP.HasChamber = false  -- Set to true in weapon-specific shared.lua for +1 in chamber
SWEP.ChamberRound = false  -- Tracks if a round is currently chambered

SWEP.ShellsPerLoad = 1  -- Default: 1 shell per reload step
SWEP.SkipReloadStartFinish = false  -- Skip ACT_SHOTGUN_RELOAD_START/FINISH for models without those animations

-- STATE-BASED RELOAD SYSTEM (replaces timer-based approach)
-- Ensures animations complete before transitioning, fixing QC event timing issues
SWEP.ReloadState = 0  -- Current reload state
SWEP.ReloadStateEnd = 0  -- CurTime when current state should end

-- Reload state constants
if not M9KR_RELOAD_STATES then
	M9KR_RELOAD_STATES = {
		IDLE = 0,              -- Not reloading
		START = 1,             -- Playing reload_start animation
		LOOP = 2,              -- Playing reload loop animation (inserting shell)
		WAIT = 3,              -- Waiting for loop animation to finish
		FINISH = 4,            -- Playing reload_end animation
		CANCEL = 5             -- Reload was cancelled
	}
end

function SWEP:Initialize()
	-- Base class initialization (copied from carby_gun_base to fix inheritance)
	self.Reloadaftershoot = 0
	self.OriginalHoldType = self.HoldType or "ar2"
	self:M9KR_SetHoldType(self.HoldType)
	self.OrigCrossHair = self.DrawCrosshair

	self.ChamberRound = false

	-- Fix metatable inheritance issue: ensure FireModes is a clean copy
	if self.FireModes then
		self.FireModes = table.Copy(self.FireModes)
	end

	-- Initialize fire mode - set Primary.Automatic for GMod's base SWEP system
	if self.FireModes then
		-- HOT-RELOAD FIX: Restore fire mode from networked variable if available
		local networkedMode = self.Weapon:GetNWInt("CurrentFireMode", 0)
		if networkedMode > 0 then
			self.CurrentFireMode = networkedMode
		else
			self.CurrentFireMode = self.CurrentFireMode or 1
		end

		local modeCount = self:GetFireModeCount()
		if self.CurrentFireMode < 1 or self.CurrentFireMode > modeCount then
			self.CurrentFireMode = 1
		end

		if SERVER then
			self.Weapon:SetNWInt("CurrentFireMode", self.CurrentFireMode)
		end

		local mode = self.FireModes[self.CurrentFireMode]
		self.Primary.Automatic = (mode == "auto")
		self:SelectFireMode(mode)
	else
		-- No FireModes defined, default to semi-auto
		self.Primary.Automatic = false
		self.CurrentFireMode = 1

		if SERVER then
			self.Weapon:SetNWInt("CurrentFireMode", self.CurrentFireMode)
		end

		self:SelectFireMode("single")
	end

	self.ViewPunchP = 0
	self.ViewPunchY = 0

	self.ShotCount = 0
	self.IronSightsProgress = 0
	self.IronSightsProgressSmooth = 0

	self:SetIsSuppressed(self.Silenced or false)
	self:SetIsOnSafe(self.Safety or false)
	self:UpdateWorldModel()

	self.ShotgunReloading = false
	self.ReloadCancelled = false
	self.ReloadFinishing = false
	self.InsertingShell = false
	self.CanCancelReload = false
	self.NextReload = 0

	self.ReloadState = M9KR_RELOAD_STATES.IDLE
	self.ReloadStateEnd = 0

	if SERVER and IsValid(self.Owner) and self.Owner:IsNPC() then
		self:SetNPCMinBurst(3)
		self:SetNPCMaxBurst(10)
		self:SetNPCFireRate(1 / (self.Primary.RPM / 60))
	end

	if CLIENT then
		if self.ViewModelBoneMods then
			self.ViewModelBoneMods = table.FullCopy(self.ViewModelBoneMods)
		end

		self.AnimationTime = 0
		self.BreathIntensity = 0
		self.WalkIntensity = 0
		self.SprintIntensity = 0
		self.JumpVelocitySmooth = 0
		self.LateralVelocity = 0
		self.LateralVelocitySmooth = 0
		self.LastGroundState = true

		-- Defer expensive operations to Deploy() for faster spawn
		-- Offset table and texture loading happen on first deploy

		if IsValid(self.Owner) and self.Owner:IsPlayer() and self.Owner:Alive() then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetViewModelBones(vm)
				if self.ShowViewModel == nil or self.ShowViewModel then
					vm:SetColor(Color(255, 255, 255, 255))
				else
					vm:SetMaterial("Debug/hsv")
					vm:SetColor(Color(255, 255, 255, 1))
				end
			end
		end
	end
end

-- Fire mode system methods for shotguns (overrides carby_gun_base)
function SWEP:GetCurrentFireMode()
	if self.FireModes and #self.FireModes > 0 then
		-- On client, read from networked variable to stay in sync with server
		if CLIENT then
			local networkedMode = self.Weapon:GetNWInt("CurrentFireMode", 0)
			if networkedMode > 0 then
				self.CurrentFireMode = networkedMode
			end
		end

		local currentIndex = self.CurrentFireMode or 1
		return self.FireModes[currentIndex] or "single"
	else
		return "single"
	end
end

function SWEP:GetFireModeCount()
	if not self.FireModes then return 0 end

	-- Check the weapon's class definition directly via weapons.GetStored
	-- This prevents counting inherited fire modes from parent classes
	local weaponClass = weapons.GetStored(self:GetClass())
	if weaponClass and weaponClass.FireModes then
		local count = 0
		for i = 1, 10 do
			if rawget(weaponClass.FireModes, i) ~= nil then
				count = count + 1
			else
				break
			end
		end
		return count
	end

	return 1
end

function SWEP:CycleFireMode()
	if not self.FireModes or #self.FireModes <= 1 then
		return
	end

	self.CurrentFireMode = self.CurrentFireMode or 1
	if self.CurrentFireMode < 1 or self.CurrentFireMode > #self.FireModes then
		self.CurrentFireMode = 1
	end

	self.CurrentFireMode = (self.CurrentFireMode % #self.FireModes) + 1

	local newMode = self.FireModes[self.CurrentFireMode]
	if not newMode then
		self.CurrentFireMode = 1
		newMode = self.FireModes[1]
	end

	-- Network the current fire mode to clients for HUD display (SERVER only)
	if SERVER then
		self.Weapon:SetNWInt("CurrentFireMode", self.CurrentFireMode)

		self:SelectFireMode(newMode)
	end

	self.FireModeSwitchTime = CurTime()

	-- Sound is played CLIENT-side when the NW fire mode change is detected
	-- (in GetViewModelPosition, inherited from gun_base). Playing here would double-play in SP.
end

function SWEP:IsFireModeBurst()
	local mode = self:GetCurrentFireMode()
	return mode == "burst" or mode == "double"
end

function SWEP:SelectFireMode(mode)
	-- If no mode specified, cycle through available modes (called by fire mode handler)
	if mode == nil then
		-- Cooldown check to prevent spam
		if self.NextFireSelect and CurTime() < self.NextFireSelect then return end
		self.NextFireSelect = CurTime() + 0.5

		self:CycleFireMode()
		return
	end

	self.Primary.Automatic = (mode == "auto")
end

function SWEP:GetAnimationLength(act, useSync)
	if not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return 0.5  -- Default fallback
	end

	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then
		return 0.5  -- Default fallback
	end

	local seq = vm:SelectWeightedSequence(act)
	if not seq or seq < 0 then
		return 0.5  -- Default fallback
	end

	local duration = vm:SequenceDuration(seq)
	if not duration or duration <= 0 then
		return 0.5  -- Default fallback
	end

	return duration
end

function SWEP:ProcessReloadStatus()
	if not IsValid(self) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return
	end

	if self.ReloadState == M9KR_RELOAD_STATES.IDLE then
		return
	end

	local ct = CurTime()

	if ct < self.ReloadStateEnd then
		return
	end
	local nextState = M9KR_RELOAD_STATES.IDLE
	local stateEndTime = ct

	if self.ReloadState == M9KR_RELOAD_STATES.START then
		-- START -> LOOP (begin inserting first shell immediately)
		nextState = M9KR_RELOAD_STATES.LOOP
		stateEndTime = ct

	elseif self.ReloadState == M9KR_RELOAD_STATES.LOOP then
		-- LOOP -> Check if should finish BEFORE inserting shell
		local shouldContinue, shouldFinish = self:ShouldContinueReload()

		if shouldFinish then
			-- Done reloading - go to finish
			if self.SkipReloadStartFinish then
				-- Skip finish animation - go directly to idle
				nextState = M9KR_RELOAD_STATES.IDLE
				self:CompleteReload()
				stateEndTime = ct
			else
				local finishTime = self:GetAnimationLength(ACT_SHOTGUN_RELOAD_FINISH, false)
				self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
				self:SetNextPrimaryFire(ct + finishTime)
				nextState = M9KR_RELOAD_STATES.FINISH
				stateEndTime = ct + finishTime
			end
		elseif shouldContinue then
			-- Insert shell and continue looping
			self:StateInsertShell()
			-- Next loop happens after ShellTime
			nextState = M9KR_RELOAD_STATES.LOOP
			stateEndTime = ct + (self.ShellTime or 0.35)
		else
			-- This shouldn't happen, but safety fallback
			nextState = M9KR_RELOAD_STATES.IDLE
		end

	elseif self.ReloadState == M9KR_RELOAD_STATES.WAIT then
		-- WAIT state deprecated but kept for compatibility
		-- Just transition to next loop
		nextState = M9KR_RELOAD_STATES.LOOP
		stateEndTime = ct + (self.ShellTime or 0.35)

	elseif self.ReloadState == M9KR_RELOAD_STATES.FINISH then
		-- FINISH -> IDLE (reload complete)
		nextState = M9KR_RELOAD_STATES.IDLE
		self:CompleteReload()

	elseif self.ReloadState == M9KR_RELOAD_STATES.CANCEL then
		-- CANCEL -> IDLE (cancel animation complete)
		nextState = M9KR_RELOAD_STATES.IDLE
		self:CompleteCancelReload()
	end

	self.ReloadState = nextState
	self.ReloadStateEnd = stateEndTime
end

function SWEP:StateInsertShell()
	if not IsValid(self) or not IsValid(self.Owner) then return end

	local currentClip = self:Clip1()
	local maxClip = self.Primary.ClipSize
	local reserveAmmo = self.Owner:GetAmmoCount(self.Primary.Ammo)
	local spaceInMagazine = maxClip - currentClip
	local shellsToLoad = 0

	if self.HasChamber and self.ChamberRound and not self.StartedReloadEmpty then
		-- Tactical/partial reload with +1 chamber
		if currentClip < maxClip then
			shellsToLoad = math.min(self.ShellsPerLoad or 1, spaceInMagazine, reserveAmmo)
		elseif currentClip == maxClip and reserveAmmo > 0 then
			shellsToLoad = 1  -- Load 1 for chamber
		end
	else
		-- Empty reload or standard reload
		shellsToLoad = math.min(self.ShellsPerLoad or 1, spaceInMagazine, reserveAmmo)
	end

	if shellsToLoad > 0 then
		if SERVER then
			self.Owner:RemoveAmmo(shellsToLoad, self.Primary.Ammo, false)
			self:SetClip1(self:Clip1() + shellsToLoad)
		end

		-- ShellTime controls animation playback rate - SET BEFORE PLAYING ANIMATION
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) and self.ShellTime then
			local seq = vm:SelectWeightedSequence(ACT_VM_RELOAD)
			if seq and seq >= 0 then
				local naturalDuration = vm:SequenceDuration(seq)
				if naturalDuration > 0 and naturalDuration > self.ShellTime then
					-- Calculate playback rate: if ShellTime is shorter, play faster
					local playbackRate = naturalDuration / self.ShellTime
					vm:SetPlaybackRate(playbackRate)
				else
					-- Reset to normal speed if ShellTime is longer than animation
					vm:SetPlaybackRate(1.0)
				end
			end
		end

		self:SendWeaponAnim(ACT_VM_RELOAD)

		if self.ForcePlayInsertSound then
			self:EmitSound(self.ForcePlayInsertSound)
		end
	end
end

function SWEP:ShouldContinueReload()
	if not IsValid(self.Owner) then
		return false, true  -- Can't continue, should finish
	end

	local currentClip = self:Clip1()
	local maxClip = self.Primary.ClipSize
	local reserveAmmo = self.Owner:GetAmmoCount(self.Primary.Ammo)

	if self.ReloadCancelled then
		return false, true  -- Don't continue, should finish
	end

	local isDone = false

	if self.HasChamber and self.ChamberRound and not self.StartedReloadEmpty then
		-- Tactical reload: done when over capacity or out of ammo
		isDone = (currentClip >= maxClip + 1 or reserveAmmo <= 0)
	else
		-- Empty/standard reload: done when magazine full or out of ammo
		isDone = (currentClip >= maxClip or reserveAmmo <= 0)
	end

	if isDone then
		return false, true  -- Don't continue, should finish
	else
		return true, false  -- Continue inserting, not finished
	end
end

function SWEP:CompleteReload()
	self.ShotgunReloading = false
	self.ReloadFinishing = false
	self.InsertingShell = false
	self.ReloadCancelled = false
	self.Weapon:SetNWBool("Reloading", false)

	if self.Silenced then
		self:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
	else
		self:SendWeaponAnim(ACT_VM_IDLE)
	end
end

function SWEP:CompleteCancelReload()
	self.ShotgunReloading = false
	self.ReloadFinishing = false
	self.ReloadCancelled = false
	self.Weapon:SetNWBool("Reloading", false)

	if self.Silenced then
		self:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
	else
		self:SendWeaponAnim(ACT_VM_IDLE)
	end
end

function SWEP:PrimaryAttack()
	if self:GetIsOnSafe() then
		return
	end

	-- Prevent firing during reload - Think() will handle calling CancelReload()
	-- This prevents the weapon from firing a shot when player tries to cancel reload
	if self.ReloadState and self.ReloadState > M9KR_RELOAD_STATES.IDLE then
		return
	end

	if self:CanPrimaryAttack() and self.Owner:IsPlayer() then
		-- Allow shooting if: not actually sprinting, OR sprint jumping is active
		-- Actually sprinting = SPEED held, on ground, moving, AND pressing movement keys
		local isSprintJumping = self.Owner:KeyDown(IN_SPEED) and not self.Owner:IsOnGround()
		local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
		local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and self.Owner:IsOnGround() and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement

		if (not isActuallySprinting or isSprintJumping) and not self.Owner:KeyDown(IN_RELOAD) then
			if self:IsFireModeBurst() then
				if self.BurstShotsRemaining and self.BurstShotsRemaining > 0 then
					return
				end

				local clips = self.Weapon:Clip1()
				local shotsToFire = math.min(self.BurstCount or 3, clips or 0)
				if shotsToFire <= 0 then
					return
				end

				-- Set BurstShotsRemaining and let Think() handle subsequent shots
				self.BurstShotsRemaining = shotsToFire - 1
				self.NextBurstShotTime = CurTime() + self.BurstDelay

				self:ShootBulletInformation()
				self.Weapon:TakePrimaryAmmo(1)

				-- In SP, SERVER runs PrimaryAttack (CLIENT prediction may not), so SERVER must also call
				if CLIENT or (game.SinglePlayer() and SERVER) then
					self.LastShotTime = CurTime()
					if self.CheckLowAmmo then self:CheckLowAmmo() end
				end

				local bIron = self.Owner:KeyDown(IN_ATTACK2)

				if self.Silenced then
					if bIron and self:HasSequence(ACT_VM_PRIMARYATTACK_2) then
						self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_2)
					else
						self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_SILENCED)
					end
					self:EmitSound(self.Primary.SilencedSound or "")
				else
					if bIron and self:HasSequence(ACT_VM_PRIMARYATTACK_1) then
						self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_1)
					else
						self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
					end
					self:EmitSound(self.Primary.Sound or "")
				end

				self:M9KR_SpawnMuzzleFlash()
				self.Owner:SetAnimation(PLAYER_ATTACK1)
				self:M9KR_SpawnShellEject()

				self.Weapon:SetNextSecondaryFire(CurTime() + 1 / (self.Primary.RPM / 60))
				self.Weapon:SetNextPrimaryFire(CurTime() + (self.BurstTriggerPull or 0.35))
			else
				local gunBase = baseclass.Get("carby_gun_base")
				if gunBase and gunBase.PrimaryAttack then
					gunBase.PrimaryAttack(self)
				end
			end
		end
	end
end

function SWEP:Think()
	if not IsValid(self) or not IsValid(self.Weapon) then
		return
	end

	if not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return
	end

	-- CLIENT: Sync Primary.Automatic with SERVER fire mode
	-- CycleFireMode runs SERVER-only, so CLIENT must read the networked fire mode
	-- and update Primary.Automatic to prevent full-auto behavior in semi/burst modes
	if CLIENT and self.FireModes then
		local networkedMode = self.Weapon:GetNWInt("CurrentFireMode", 0)
		if networkedMode > 0 and self.FireModes[networkedMode] then
			self.Primary.Automatic = (self.FireModes[networkedMode] == "auto")
		end
	end

	self:ProcessReloadStatus()

	-- Cancel reload if player presses attack during reload
	local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
	local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and self.Owner:IsOnGround() and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement

	-- Only allow canceling during START, LOOP, or WAIT states (not during FINISH or CANCEL)
	local canCancel = (self.ReloadState == M9KR_RELOAD_STATES.START or
	                   self.ReloadState == M9KR_RELOAD_STATES.LOOP or
	                   self.ReloadState == M9KR_RELOAD_STATES.WAIT)

	if not self:GetIsOnSafe() and self.Owner:KeyPressed(IN_ATTACK) and canCancel and not isActuallySprinting then
		-- Cancel reload immediately without checking if we can fire
		-- CancelReload() will set NextPrimaryFire to prevent firing
		self:CancelReload()
	end

	-- Safety toggle & fire mode switching (USE + RELOAD input)
	-- E + SHIFT + R = Enter safety mode
	-- E + R (when in safety) = Exit safety and restore last fire mode
	-- E + R (when not in safety, no SHIFT) = Cycle fire mode
	if SERVER and self.Owner:KeyDown(IN_USE) and self.Owner:KeyPressed(IN_RELOAD) then
		if self:GetIsOnSafe() then
			self:SafetyOff()
		elseif self.Owner:KeyDown(IN_SPEED) then
			self:SafetyOn()
		elseif not self.Weapon:GetNWBool("Reloading", false) then
			self:SelectFireMode()
		end
	end

	if self.BurstShotsRemaining and self.BurstShotsRemaining > 0 and (not self.NextBurstShotTime or CurTime() >= self.NextBurstShotTime) then
		if not IsValid(self) or not IsValid(self:GetOwner()) or self:Clip1() <= 0 then
			self.BurstShotsRemaining = 0
			return
		end

		self:ShootBulletInformation()
		self:TakePrimaryAmmo(1)

		-- In SP, SERVER runs Think (CLIENT prediction may not), so SERVER must also call
		if CLIENT or (game.SinglePlayer() and SERVER) then
			if self.CheckLowAmmo then self:CheckLowAmmo() end
		end

		local bIron = self.Owner:KeyDown(IN_ATTACK2)

		if self.Silenced then
			if bIron and self:HasSequence(ACT_VM_PRIMARYATTACK_2) then
				self:SendWeaponAnim(ACT_VM_PRIMARYATTACK_2)
			else
				self:SendWeaponAnim(ACT_VM_PRIMARYATTACK_SILENCED)
			end
			self:EmitSound(self.Primary.SilencedSound)
		else
			if bIron and self:HasSequence(ACT_VM_PRIMARYATTACK_1) then
				self:SendWeaponAnim(ACT_VM_PRIMARYATTACK_1)
			else
				self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
			end
			self:EmitSound(self.Primary.Sound)
		end

		self:M9KR_SpawnMuzzleFlash()
		self:GetOwner():SetAnimation(PLAYER_ATTACK1)
		self:GetOwner():MuzzleFlash()
		self:M9KR_SpawnShellEject()

		self.BurstShotsRemaining = self.BurstShotsRemaining - 1
		self.NextBurstShotTime = CurTime() + self.BurstDelay
	end

	if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() then
		self.OwnerViewModel = self.Owner:GetViewModel()

		self:UpdateWeaponInputState()

		-- Guard FrameTime-based updates against multiple calls per frame
		-- In multiplayer, Think() can run multiple times per frame during prediction
		local curFrame = FrameNumber()
		if self.m9kr_LastProgressFrame ~= curFrame then
			self.m9kr_LastProgressFrame = curFrame
			self:UpdateProgressRatios()
		end
		-- SP low ammo detection: in SP, PrimaryAttack runs on SERVER only,
		-- so CLIENT detects ammo decrease to trigger low ammo sounds
		if game.SinglePlayer() and self.CheckLowAmmo then
			local currentClip = self:Clip1()
			if self.m9kr_LastClipForLowAmmo and currentClip < self.m9kr_LastClipForLowAmmo then
				self.LastShotTime = CurTime()
				self:CheckLowAmmo()
			end
			self.m9kr_LastClipForLowAmmo = currentClip
		end

		self:UpdateBeltAmmo()
	end

	-- Recoil Decay System
	-- Guard against double-advancement on CLIENT during prediction
	local ft = FrameTime()
	local shouldDecayRecoil = true
	if CLIENT then
		local curFrame = FrameNumber()
		if self.m9kr_LastDecayFrame == curFrame then
			shouldDecayRecoil = false
		end
		self.m9kr_LastDecayFrame = curFrame
	end

	local isInADS = CLIENT and (self.m9kr_IsInADS or false) or false
	local targetProgress = isInADS and 1.0 or 0.0
	self.IronSightsProgressSmooth = self.IronSightsProgressSmooth or 0
	if shouldDecayRecoil then
		self.IronSightsProgressSmooth = Lerp(ft * 8, self.IronSightsProgressSmooth, targetProgress)
	end

	if shouldDecayRecoil and self.ViewPunchP then
		self.ViewPunchP = Lerp(ft * 5, self.ViewPunchP, 0)
	end
	if shouldDecayRecoil and self.ViewPunchY then
		self.ViewPunchY = Lerp(ft * 5, self.ViewPunchY, 0)
	end

	if self.CanBeSilenced and (self:GetIsAttachingSuppressor() or self:GetIsDetachingSuppressor()) then
		local animEndTime = self:GetSuppressorAnimEndTime()
		if CurTime() >= animEndTime then
			if self.OriginalHoldType then
				self:M9KR_SetHoldType(self.OriginalHoldType)
			end

			self:SetIsAttachingSuppressor(false)
			self:SetIsDetachingSuppressor(false)
			self:UpdateWorldModel()
		end
	end

	-- Sprint-Jump Detection System
	local isOnGround = self.Owner:IsOnGround()
	self.LastGroundState = self.LastGroundState or true

	if self.LastGroundState and not isOnGround then
		if self:GetSprint() and self.Owner:KeyDown(IN_SPEED) then
			self.SprintJumping = true
		else
			self.SprintJumping = false
		end
	end

	if isOnGround and not self.LastGroundState then
		self.SprintJumping = false
	end

	self.LastGroundState = isOnGround

	self:UpdateSafetyHoldType()

	self:IronSight()
end

function SWEP:CanStartReload()
	if self.ShotgunReloading or self.ReloadFinishing then return false end
	if not self.CanReload then return false end

	if self.Primary.Automatic and self.Owner:KeyDown(IN_ATTACK) then
		return false
	end

	if self:Clip1() >= self.Primary.ClipSize or self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
		return false
	end

	return true
end

function SWEP:UpdateReloadGate()
	if not IsValid(self) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then return end

	if self:CanStartReload() then
		self.CanReload = true
	else
		self.CanReload = false
	end
end

function SWEP:Holster()
	if not IsValid(self) or not IsValid(self.Weapon) then
		return true
	end

	local entIndex = self:EntIndex()
	if not entIndex or entIndex <= 0 then
		return true
	end

	local burstTimerName = "M9K_Burst_" .. entIndex
	if timer.Exists(burstTimerName) then
		timer.Remove(burstTimerName)
	end
	self.BurstShotsRemaining = 0

	local gunBaseReloadTimer = "M9K_Reload_" .. entIndex
	if timer.Exists(gunBaseReloadTimer) then
		timer.Remove(gunBaseReloadTimer)
	end

	local gunBaseSprintTimer = "M9K_ReloadSprint_" .. entIndex
	if timer.Exists(gunBaseSprintTimer) then
		timer.Remove(gunBaseSprintTimer)
	end

	local silencerTimerName = "M9K_Silencer_" .. entIndex
	if timer.Exists(silencerTimerName) then
		timer.Remove(silencerTimerName)
	end

	if IsValid(self.Owner) then
		local ownerID = self.Owner:UniqueID()

		local shotgunTimers = {
			"ShotgunReload_" .. ownerID,
			"ShotgunDoubleReload_" .. ownerID,
			"ShotgunMarshalReload_" .. ownerID,
			"ShotgunFinish_" .. ownerID,
			"ShotgunShellAnim_" .. ownerID,
			"ShotgunCancelFinish_" .. ownerID
		}

		for _, timer_name in ipairs(shotgunTimers) do
			if timer.Exists(timer_name) then
				timer.Destroy(timer_name)
			end
		end
	end

	self.ShotgunReloading = false
	self.InsertingShell = false
	self.ReloadCancelled = false
	self.ReloadFinishing = false

	self.ReloadState = M9KR_RELOAD_STATES.IDLE
	self.ReloadStateEnd = 0

	if IsValid(self.Weapon) then
		self.Weapon:SetNWBool("Reloading", false)
	end

	self.crouchMul = 0
	self.bLastCrouching = false
	self.fCrouchTime = nil

	if CLIENT and IsValid(self.Owner) and not self.Owner:IsNPC() then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			vm:SetPlaybackRate(1.0)
			self:ResetViewModelBones(vm)
		end
	end

	-- Stop action sounds (draw, reload, bolt, etc.) when switching weapons
	-- Fire sounds use a different channel and are NOT stopped
	if self.ActionSounds and #self.ActionSounds > 0 then
		for _, soundName in ipairs(self.ActionSounds) do
			if IsValid(self.Weapon) then
				self.Weapon:StopSound(soundName)
			end
			-- Also stop on viewmodel (some sounds may be played there)
			if CLIENT and IsValid(self.Owner) and not self.Owner:IsNPC() then
				local vm = self.Owner:GetViewModel()
				if IsValid(vm) then
					vm:StopSound(soundName)
				end
			end
		end
	end

	return true
end

function SWEP:OnRemove()
	if not IsValid(self) or not self.EntIndex then
		return
	end

	local entIndex = self:EntIndex()
	if not entIndex or entIndex <= 0 then
		return
	end

	local burstTimerName = "M9K_Burst_" .. entIndex
	if timer.Exists(burstTimerName) then
		timer.Remove(burstTimerName)
	end

	local parentTimers = {
		"M9K_Reload_" .. entIndex,
		"M9K_ReloadSprint_" .. entIndex,
		"M9K_Silencer_" .. entIndex
	}

	for _, timerName in ipairs(parentTimers) do
		if timer.Exists(timerName) then
			timer.Remove(timerName)
		end
	end

	if IsValid(self.Owner) then
		local ownerID = self.Owner:UniqueID()

		local shotgunTimers = {
			"ShotgunReload_" .. ownerID,
			"ShotgunDoubleReload_" .. ownerID,
			"ShotgunMarshalReload_" .. ownerID,
			"ShotgunFinish_" .. ownerID,
			"ShotgunShellAnim_" .. ownerID,
			"ShotgunCancelFinish_" .. ownerID
		}

		for _, timer_name in ipairs(shotgunTimers) do
			if timer.Exists(timer_name) then
				timer.Destroy(timer_name)
			end
		end
	end

	-- Reset crouch state to prevent GetViewModelPosition crashes
	self.crouchMul = 0
	self.bLastCrouching = false
	self.fCrouchTime = nil

	self.ShotgunReloading = false
	self.InsertingShell = false
	self.ReloadCancelled = false
	self.ReloadFinishing = false
	self.ReloadState = M9KR_RELOAD_STATES.IDLE
	self.ReloadStateEnd = 0

	if CLIENT and IsValid(self.Owner) and not self.Owner:IsNPC() then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetViewModelBones(vm)
		end
	end
end

function SWEP:Deploy()
	if not IsValid(self) then return end
	if not IsValid(self.Owner) then return end
	if not self.Owner:IsPlayer() then return end
	self.BurstShotsRemaining = nil
	self.ContinuousShotCount = 0
	self.RapidFireHeat = 0
	self.LastShotTime = 0
	self.LastTriggerState = false

	self:M9KR_SetHoldType(self.HoldType)

	local timerName = "ShotgunReload_" ..  self.Owner:UniqueID()
	if (timer.Exists(timerName)) then
		timer.Destroy(timerName)
	end

	if self.ChamberRound == nil then
		self.ChamberRound = false
	end

	if CLIENT and not self.FirstDeployDone then
		self.FirstDeployDone = true

		if self.Offset then
			local baseOffset = self.Offset
			self.Offset = {
				Pos = {
					Up = baseOffset.Pos.Up or 0,
					Right = baseOffset.Pos.Right or 0,
					Forward = baseOffset.Pos.Forward or 0
				},
				Ang = {
					Up = baseOffset.Ang.Up or 0,
					Right = baseOffset.Ang.Right or 0,
					Forward = baseOffset.Ang.Forward or 0
				},
				Scale = baseOffset.Scale or 1
			}
		end

		if not self.WepSelectIcon or self.WepSelectIcon == 0 then
			local oldpath = "vgui/hud/name"
			local newpath = string.gsub(oldpath, "name", self.Gun)
			self.WepSelectIcon = surface.GetTextureID(newpath)
		end
	end

	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)

	self.Weapon:SetNextPrimaryFire(CurTime() + .25)
	self.Weapon:SetNextSecondaryFire(CurTime() + .25)
	self.ActionDelay = (CurTime() + .25)

	if (SERVER) then
		self:SetIronsights(false)
		self:SetSprint(false)
		
		if self.Owner:KeyDown(IN_SPEED) then
			local velocity = self.Owner:GetVelocity()
			local speed = velocity:Length2D()
			local isOnGround = self.Owner:IsOnGround()

			if speed > 50 and isOnGround then
				self.IronSightsPos = self.RunSightsPos
				self.IronSightsAng = self.RunSightsAng
				self:SetSprint(true)
				self.DrawCrosshair = false
				if self.Weapon:GetNextPrimaryFire() <= (CurTime() + 0.3) then
					self.Weapon:SetNextPrimaryFire(CurTime() + 0.3)
				end
			end
		end
	end
	
	self.Owner.NextReload = CurTime() + 1

	return true
end

function SWEP:Reload()
    if not IsValid(self) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then return end
    if not self.CanReload then return end

    -- Prevent reloading if safety is engaged or USE is held (USE + RELOAD = fire mode toggle)
    if self:GetIsOnSafe() or self.Owner:KeyDown(IN_USE) then return end

    -- Prevent reload from triggering right after safety toggle or fire mode switch
    -- This fixes the issue where releasing USE + R could trigger a reload
    if self.NextSafetyToggle and CurTime() < self.NextSafetyToggle then return end
    if self.NextFireSelect and CurTime() < self.NextFireSelect then return end

    if self.Primary.Automatic and self.Owner:KeyDown(IN_ATTACK) then return end

    if self.Owner:IsNPC() then
        self.Weapon:DefaultReload(ACT_VM_RELOAD)
        return
    end

    if self.Owner:KeyDown(IN_USE) then return end

    self.ShotCount = 0

    local maxcap = self.Primary.ClipSize
    local spaceavail = self:Clip1()
    local isEmpty = spaceavail == 0

    local shellz
    if self.HasChamber and not isEmpty then
        -- Tactical/partial reload: load to magazine + 1 for chamber
        shellz = maxcap - spaceavail + 1
    else
        -- Empty reload: load to magazine only (no +1)
        shellz = maxcap - spaceavail
    end

    local canReload = false
    if self.HasChamber then
        if spaceavail < maxcap + 1 and self.Owner:GetAmmoCount(self.Primary.Ammo) > 0 then
            canReload = true
        end
    else
        if spaceavail < maxcap and self.Owner:GetAmmoCount(self.Primary.Ammo) > 0 then
            canReload = true
        end
    end

    if self.ReloadState > M9KR_RELOAD_STATES.IDLE or not canReload then
        return
    end

    self.ShotgunReloading = true
    self.ReloadCancelled = false
    self.ReloadFinishing = false
    self.CanCancelReload = false
    self.Weapon:SetNWBool("Reloading", true)

    local currentClip = self:Clip1()
    local isEmpty = currentClip == 0
    self.StartedReloadEmpty = isEmpty

    if self.HasChamber and not isEmpty then
        self.ChamberRound = true
    elseif self.HasChamber and isEmpty then
        -- Will chamber first round using reload_end_empty animation
        self.ChamberRound = false
    else
        self.ChamberRound = false
    end

    self.Owner:SetAnimation(PLAYER_RELOAD)

    if SERVER then
        self:SetIronsights(false)
    end

    if self.SkipReloadStartFinish then
        self.ReloadState = M9KR_RELOAD_STATES.LOOP
        self.ReloadStateEnd = CurTime()
    else
        self.Weapon:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)
        self.ReloadState = M9KR_RELOAD_STATES.START
        -- Use a shorter time for START - don't wait for full animation, transition to LOOP faster
        local startTime = math.min(self.ShellTime or 0.35, self:GetAnimationLength(ACT_SHOTGUN_RELOAD_START, false) * 0.5)
        self.ReloadStateEnd = CurTime() + startTime
    end
end

function SWEP:InsertShell()
    -- Stub kept for compatibility; see StateInsertShell()
end

function SWEP:ShellAnimCaller()
	self.Weapon:SendWeaponAnim(ACT_VM_RELOAD)
end

function SWEP:CancelReload()
    if not IsValid(self) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then return end

    if self.ReloadState <= M9KR_RELOAD_STATES.IDLE then return end

    self.ReloadCancelled = true
    self.ReloadFinishing = true
    self.InsertingShell = false

    if self.Owner:KeyDown(IN_ATTACK2) then
        self:SetIronsights(true)
    else
        self:SetIronsights(false)
    end

    if self.SkipReloadStartFinish then
        self:CompleteCancelReload()
        self.ReloadState = M9KR_RELOAD_STATES.IDLE
        self.ReloadStateEnd = CurTime()
        -- Small delay before firing to prevent accidental shot
        self:SetNextPrimaryFire(CurTime() + 0.15)
    else
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then
            vm:ResetSequence(vm:LookupSequence("after_reload"))
        end

        self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)

        local finishTime = self:GetAnimationLength(ACT_SHOTGUN_RELOAD_FINISH, false)
        self.ReloadState = M9KR_RELOAD_STATES.CANCEL
        self.ReloadStateEnd = CurTime() + finishTime

        self:SetNextPrimaryFire(CurTime() + finishTime + 0.1)
    end
end

