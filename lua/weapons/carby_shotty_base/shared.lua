-- Variables that are used on both client and server
SWEP.Category = ""
SWEP.Author = "Generic Default, Worshipper, Clavus, and Bob"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.Base = "carby_gun_base"
SWEP.MuzzleAttachment = "1" -- Should be "1" for CSS models or "muzzle" for hl2 models
SWEP.ShellEjectAttachment = "2" -- Should be "2" for CSS models or "1" for hl2 models
SWEP.DrawCrosshair = true -- Hell no, crosshairs r 4 nubz!
SWEP.ViewModelFOV = 65 -- How big the gun will look
SWEP.ViewModelFlip = true -- True for CSS models, False for HL2 models

SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.Primary.Sound = Sound("") -- Sound of the gun
SWEP.Primary.RPM = 0 -- This is in Rounds Per Minute
SWEP.Primary.ClipSize = 0 -- Size of a clip
SWEP.Primary.DefaultClip = 0 -- Default number of bullets in a clip
SWEP.Primary.KickUp = 0 -- Maximum up recoil (rise)
SWEP.Primary.KickDown = 0 -- Maximum down recoil (skeet)
SWEP.Primary.KickHorizontal = 0 -- Maximum side recoil (koolaid)
-- SWEP.Primary.Automatic removed - now controlled by fire mode system
SWEP.Primary.Ammo = "none" -- What kind of ammo
SWEP.Primary.Reloading = false -- Reloading func

SWEP.ReloadCancelled = false  -- set when player cancels reload
SWEP.ReloadFinishing = false  -- set when finish animation is playing
SWEP.InsertingShell = false  -- already used

SWEP.Secondary.Ammo = ""
SWEP.Secondary.IronFOV = 0 -- How much you 'zoom' in. Less is more!

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

--[[
	SHOTGUN FIRE MODES:

	Fire modes are set using SWEP.FireModes and SWEP.FireModeNames (inherited from carby_gun_base)

	Available fire modes for shotguns:
	- "single" : Semi-automatic (SPAS-12, AA-12, Saiga-12)
	- "double" : Both barrels at once (double-barrel, marshal)
	              Uses burst system with BurstCount=2 and very small BurstDelay (~0.01)
	- "pump"   : Pump-action (Benelli M3, W1200, Mossberg 500)
	- "burst"  : 2 rounds back-to-back with delay (DP-12)
	              Uses burst system with BurstCount=2 and larger BurstDelay (~0.1-0.15)

	Example weapon configs:

	Pump-action with burst:
		SWEP.FireModes = {"pump", "burst"}
		SWEP.BurstCount = 2
		SWEP.BurstDelay = 0.15  -- Noticeable delay between shots
]]--

function SWEP:Initialize()
	-- Base class initialization (copied from carby_gun_base to fix inheritance)
	self.Reloadaftershoot = 0
	self:SetHoldType(self.HoldType)
	self.OrigCrossHair = self.DrawCrosshair

	-- Initialize chamber state
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

		-- Network the initial fire mode to clients
		if SERVER then
			self.Weapon:SetNWInt("CurrentFireMode", self.CurrentFireMode)
		end

		local mode = self.FireModes[self.CurrentFireMode]
		-- Only "auto" mode should have automatic fire, everything else is semi
		self.Primary.Automatic = (mode == "auto")
		self:SelectFireMode(mode)
	else
		-- No FireModes defined, default to semi-auto
		self.Primary.Automatic = false
		self.CurrentFireMode = 1

		-- Network the initial fire mode to clients
		if SERVER then
			self.Weapon:SetNWInt("CurrentFireMode", self.CurrentFireMode)
		end

		self:SelectFireMode("single")
	end

	-- Initialize recoil tracking
	self.ViewPunchP = 0
	self.ViewPunchY = 0

	-- Initialize tracer shot counter
	self.ShotCount = 0
	self.IronSightsProgress = 0
	self.IronSightsProgressSmooth = 0

	-- Initialize suppressor state network variable
	self:SetIsSuppressed(self.Silenced or false)

	-- Initialize safety state network variable
	self:SetIsOnSafe(self.Safety or false)

	-- Set correct world model based on initial suppressor state
	self:UpdateWorldModel()

	-- Shotgun-specific initialization
	self.ShotgunReloading = false
	self.ReloadCancelled = false
	self.ReloadFinishing = false
	self.InsertingShell = false
	self.CanCancelReload = false
	self.NextReload = 0

	-- STATE-BASED RELOAD: Initialize reload state
	self.ReloadState = M9KR_RELOAD_STATES.IDLE
	self.ReloadStateEnd = 0

	-- NPC configuration
	if SERVER and IsValid(self.Owner) and self.Owner:IsNPC() then
		self:SetNPCMinBurst(3)
		self:SetNPCMaxBurst(10)
		self:SetNPCFireRate(1 / (self.Primary.RPM / 60))
	end

	if CLIENT then
		-- Create a new table for every weapon instance
		if self.ViewModelBoneMods then
			self.ViewModelBoneMods = table.FullCopy(self.ViewModelBoneMods)
		end

		-- Initialize animation variables (fast assignment, no function calls)
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

		-- Initialize view model bone build function
		if IsValid(self.Owner) and self.Owner:IsPlayer() and self.Owner:Alive() then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) and M9KR and M9KR.ViewModelMods then
				M9KR.ViewModelMods.ResetBonePositions(vm)
				-- Initialize viewmodel visibility
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
	-- Shotguns have their own fire mode logic, different from rifles
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
		-- Default to single for shotguns that don't define fire modes
		return "single"
	end
end

function SWEP:GetFireModeCount()
	if not self.FireModes then return 0 end

	-- Check the weapon's class definition directly via weapons.GetStored
	-- This prevents counting inherited fire modes from parent classes
	local weaponClass = weapons.GetStored(self:GetClass())
	if weaponClass and weaponClass.FireModes then
		-- Count only explicitly defined entries in the weapon class
		local count = 0
		for i = 1, 10 do
			-- Use rawget to avoid metatable lookups (inheritance)
			if rawget(weaponClass.FireModes, i) ~= nil then
				count = count + 1
			else
				break
			end
		end
		return count
	end

	-- Fallback: if we can't get the stored weapon, return 1
	return 1
end

function SWEP:CycleFireMode()
	-- Only cycle if we have multiple fire modes defined
	if not self.FireModes or #self.FireModes <= 1 then
		return
	end

	-- Ensure CurrentFireMode is valid
	self.CurrentFireMode = self.CurrentFireMode or 1
	if self.CurrentFireMode < 1 or self.CurrentFireMode > #self.FireModes then
		self.CurrentFireMode = 1
	end

	-- Cycle to next fire mode
	self.CurrentFireMode = (self.CurrentFireMode % #self.FireModes) + 1

	-- Get the new fire mode
	local newMode = self.FireModes[self.CurrentFireMode]
	if not newMode then
		self.CurrentFireMode = 1
		newMode = self.FireModes[1]
	end

	-- Network the current fire mode to clients for HUD display (SERVER only)
	if SERVER then
		self.Weapon:SetNWInt("CurrentFireMode", self.CurrentFireMode)

		-- Apply the new fire mode settings on SERVER
		self:SelectFireMode(newMode)
	end

	-- Trigger fire mode switch animation (viewmodel manipulation)
	self.FireModeSwitchTime = CurTime()

	-- Play fire mode switch sound
	if IsValid(self.Weapon) then
		self.Weapon:EmitSound("Weapon_AR2.Empty")
	end
end

function SWEP:IsFireModeBurst()
	-- Shotguns use burst for both "burst" and "double" modes
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

	-- Apply specific fire mode settings
	if mode == "auto" then
		self.Primary.Automatic = true
	elseif mode == "single" then
		self.Primary.Automatic = false
	elseif mode == "double" then
		-- Double-barrel mode
		self.Primary.Automatic = false
	elseif mode == "pump" then
		-- Pump-action mode
		self.Primary.Automatic = false
	elseif mode == "burst" then
		-- Burst mode (like DP-12)
		self.Primary.Automatic = false
	else
		-- Default to single for unknown modes
		self.Primary.Automatic = false
	end
end

--[[
   Name: SWEP:GetAnimationLength()
   Desc: Gets the actual duration of a viewmodel animation sequence
   Args: act - Activity number (e.g., ACT_VM_RELOAD, ACT_SHOTGUN_RELOAD_START)
         useSync - Not used anymore, kept for compatibility
   Returns: duration in seconds, or fallback to default if sequence not found
]]
function SWEP:GetAnimationLength(act, useSync)
	if not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return 0.5  -- Default fallback
	end

	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then
		return 0.5  -- Default fallback
	end

	-- Get the sequence from the activity
	local seq = vm:SelectWeightedSequence(act)
	if not seq or seq < 0 then
		return 0.5  -- Default fallback
	end

	-- Get the natural duration of the sequence
	local duration = vm:SequenceDuration(seq)
	if not duration or duration <= 0 then
		return 0.5  -- Default fallback
	end

	return duration
end

--[[
   Name: SWEP:ProcessReloadStatus()
   Desc: State machine for shotgun reloads - called every Think()
         Handles state transitions based on animation timing
]]
function SWEP:ProcessReloadStatus()
	if not IsValid(self) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return
	end

	-- Only process if we're in a reload state
	if self.ReloadState == M9KR_RELOAD_STATES.IDLE then
		return
	end

	local ct = CurTime()

	-- Check if current state has expired
	if ct < self.ReloadStateEnd then
		return  -- Still waiting for current state to finish
	end

	-- State has expired - transition to next state
	local nextState = M9KR_RELOAD_STATES.IDLE
	local stateEndTime = ct

	if self.ReloadState == M9KR_RELOAD_STATES.START then
		-- START -> LOOP (begin inserting first shell immediately)
		nextState = M9KR_RELOAD_STATES.LOOP
		-- Insert first shell immediately (no delay)
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

	-- Update state
	self.ReloadState = nextState
	self.ReloadStateEnd = stateEndTime
end

--[[
   Name: SWEP:StateInsertShell()
   Desc: Inserts a shell during LOOP state (called by state machine)
]]
function SWEP:StateInsertShell()
	if not IsValid(self) or not IsValid(self.Owner) then return end

	-- Determine how many shells we can load this step
	local currentClip = self:Clip1()
	local maxClip = self.Primary.ClipSize
	local reserveAmmo = self.Owner:GetAmmoCount(self.Primary.Ammo)

	-- Calculate how much space we have for loading shells
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

	-- Add shells to clip
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

		-- Play reload animation AFTER setting playback rate
		self:SendWeaponAnim(ACT_VM_RELOAD)

		-- Play insert sound if configured
		if self.ForcePlayInsertSound then
			self:EmitSound(self.ForcePlayInsertSound)
		end
	end
end

--[[
   Name: SWEP:ShouldContinueReload()
   Desc: Checks if reload should continue or finish
   Returns: shouldContinue (bool), shouldFinish (bool)
]]
function SWEP:ShouldContinueReload()
	if not IsValid(self.Owner) then
		return false, true  -- Can't continue, should finish
	end

	local currentClip = self:Clip1()
	local maxClip = self.Primary.ClipSize
	local reserveAmmo = self.Owner:GetAmmoCount(self.Primary.Ammo)

	-- Check for manual cancel first
	if self.ReloadCancelled then
		return false, true  -- Don't continue, should finish
	end

	-- Check if we're done based on reload type
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

--[[
   Name: SWEP:CompleteReload()
   Desc: Called when reload FINISH state completes
]]
function SWEP:CompleteReload()
	self.ShotgunReloading = false
	self.ReloadFinishing = false
	self.InsertingShell = false
	self.ReloadCancelled = false
	self.Weapon:SetNWBool("Reloading", false)

	-- Send weapon back to idle animation
	if self.Silenced then
		self:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
	else
		self:SendWeaponAnim(ACT_VM_IDLE)
	end
end

--[[
   Name: SWEP:CompleteCancelReload()
   Desc: Called when reload CANCEL state completes
]]
function SWEP:CompleteCancelReload()
	self.ShotgunReloading = false
	self.ReloadFinishing = false
	self.ReloadCancelled = false
	self.Weapon:SetNWBool("Reloading", false)

	-- Send weapon back to idle animation
	if self.Silenced then
		self:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
	else
		self:SendWeaponAnim(ACT_VM_IDLE)
	end
end

--[[
   Name: SWEP:PrimaryAttack()
   Desc: Override gun_base PrimaryAttack to use Think()-based burst instead of timer-based
]]
function SWEP:PrimaryAttack()
	-- Prevent firing if safety is engaged
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
			-- Burst handling (Think()-based, no timers)
			if self:IsFireModeBurst() then
				-- Don't start a new burst if one is already running
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

				-- Fire first shot immediately
				self:ShootBulletInformation()
				self.Weapon:TakePrimaryAmmo(1)

				if CLIENT then
					self.LastShotTime = CurTime()
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

				-- Spawn M9K muzzle flash and smoke effects (first burst shot)
				local fx = EffectData()
				fx:SetEntity(self.Weapon)
				fx:SetOrigin(self.Owner:GetShootPos())

				-- Get muzzle direction from worldmodel attachment
				local muzzleDir = self.Owner:GetAimVector()
				local att = self.Weapon:GetAttachment(self.Weapon:LookupAttachment(self.MuzzleAttachment or "1"))
				if att and att.Ang then
					muzzleDir = att.Ang:Forward()
				end

				fx:SetNormal(muzzleDir)
				fx:SetAttachment(self.MuzzleAttachment)

				-- Spawn muzzle flash effect
				if GetConVar("M9KR_MuzzleFlash") ~= nil and GetConVar("M9KR_MuzzleFlash"):GetBool() then
					if CLIENT or (game.SinglePlayer() and SERVER) then
						local effectName = self.MuzzleFlashEffect or "m9kr_muzzleflash_shotgun"
						if self.Silenced and self.MuzzleFlashEffectSilenced then
							effectName = self.MuzzleFlashEffectSilenced
						end
						util.Effect(effectName, fx)

						-- Spawn muzzle smoke trail
						local smokeCvar = GetConVar("m9kr_muzzlesmoketrail")
						if smokeCvar and smokeCvar:GetInt() == 1 then
							util.Effect("m9kr_muzzlesmoke", fx)
						end
					end
				end

				self.Owner:SetAnimation(PLAYER_ATTACK1)
				self:EjectShell()

				-- Set next attack time
				self.Weapon:SetNextSecondaryFire(CurTime() + 1 / (self.Primary.RPM / 60))
				self.Weapon:SetNextPrimaryFire(CurTime() + (self.BurstTriggerPull or 0.35))
			else
				-- Non-burst modes: use gun_base logic
				local gunBase = baseclass.Get("carby_gun_base")
				if gunBase and gunBase.PrimaryAttack then
					gunBase.PrimaryAttack(self)
				end
			end
		end
	end
end

--[[
   Name: SWEP:Think()
   Desc: Called every frame.
]]
function SWEP:Think()
	-- Critical safety check for weapon state during transitions
	if not IsValid(self) or not IsValid(self.Weapon) then
		return
	end

	-- Check if owner is valid - weapon switching can invalidate this
	if not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return
	end

	-- STATE-BASED RELOAD SYSTEM: Process reload states every frame
	self:ProcessReloadStatus()

	-- Shotgun-specific: Cancel reload if player presses attack during reload
	-- Only block if player is actually sprinting (not just holding sprint key while standing still)
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

	-- Shotgun-specific: Burst fire logic
	if self.BurstShotsRemaining and self.BurstShotsRemaining > 0 and (not self.NextBurstShotTime or CurTime() >= self.NextBurstShotTime) then
		if not IsValid(self) or not IsValid(self:GetOwner()) or self:Clip1() <= 0 then
			self.BurstShotsRemaining = 0
			return
		end

		self:ShootBulletInformation()
		self:TakePrimaryAmmo(1)

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

		-- Spawn M9K muzzle flash and smoke effects
		local fx = EffectData()
		fx:SetEntity(self.Weapon)
		fx:SetOrigin(self.Owner:GetShootPos())

		-- Get muzzle direction from worldmodel attachment
		local muzzleDir = self.Owner:GetAimVector()
		local att = self.Weapon:GetAttachment(self.Weapon:LookupAttachment(self.MuzzleAttachment or "1"))
		if att and att.Ang then
			muzzleDir = att.Ang:Forward()
		end

		fx:SetNormal(muzzleDir)
		fx:SetAttachment(self.MuzzleAttachment)

		-- Spawn muzzle flash effect
		if GetConVar("M9KR_MuzzleFlash") ~= nil and GetConVar("M9KR_MuzzleFlash"):GetBool() then
			if CLIENT or (game.SinglePlayer() and SERVER) then
				local effectName = self.MuzzleFlashEffect or "m9kr_muzzleflash_shotgun"
				if self.Silenced and self.MuzzleFlashEffectSilenced then
					effectName = self.MuzzleFlashEffectSilenced
				end
				util.Effect(effectName, fx)

				-- Spawn muzzle smoke trail
				local smokeCvar = GetConVar("m9kr_muzzlesmoketrail")
				if smokeCvar and smokeCvar:GetInt() == 1 then
					util.Effect("m9kr_muzzlesmoke", fx)
				end
			end
		end

		self:GetOwner():SetAnimation(PLAYER_ATTACK1)
		self:GetOwner():MuzzleFlash()
		self:EjectShell()

		self.BurstShotsRemaining = self.BurstShotsRemaining - 1
		self.NextBurstShotTime = CurTime() + self.BurstDelay

		-- Spawn barrel smoke when burst completes
		if self.BurstShotsRemaining == 0 then
			-- Create timer to spawn barrel smoke 0.75s after burst completes
			local timerName = "ShotgunBurstSmoke_" .. self:EntIndex()
			if CLIENT then
				timerName = timerName .. "_CLIENT"
			elseif SERVER then
				timerName = timerName .. "_SERVER"
			end

			timer.Create(timerName, 0.75, 1, function()
				if IsValid(self) and self.SpawnBarrelSmoke then
					self:SpawnBarrelSmoke()
				end
			end)
		end
	end

	-- Base class Think() logic (copied from carby_gun_base to fix inheritance)
	-- Store viewmodel reference for muzzle flash effects
	if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() then
		self.OwnerViewModel = self.Owner:GetViewModel()

		-- Update PCF particle lighting every frame
		if self.SmokePCFLighting then
			self:SmokePCFLighting()
		end

		-- Update progress values (TFA-style approach)
		self:UpdateProgressRatios()
	end

	-- TFA-Style Recoil Decay System
	local ft = FrameTime()

	-- Smoothly update IronSights progress for recoil interpolation
	local isInADS = false
	if CLIENT and M9KR and M9KR.WeaponState and M9KR.WeaponState.GetVisualState then
		isInADS = M9KR.WeaponState.GetVisualState(self)
	end
	local targetProgress = isInADS and 1.0 or 0.0
	self.IronSightsProgressSmooth = self.IronSightsProgressSmooth or 0
	self.IronSightsProgressSmooth = Lerp(ft * 8, self.IronSightsProgressSmooth, targetProgress)

	-- Decay ViewPunch accumulator over time
	if self.ViewPunchP then
		self.ViewPunchP = Lerp(ft * 5, self.ViewPunchP, 0)
	end
	if self.ViewPunchY then
		self.ViewPunchY = Lerp(ft * 5, self.ViewPunchY, 0)
	end

	-- Suppressor attachment/detachment animation management
	if self.CanBeSilenced and (self:GetIsAttachingSuppressor() or self:GetIsDetachingSuppressor()) then
		local animEndTime = self:GetSuppressorAnimEndTime()
		if CurTime() >= animEndTime then
			-- Animation complete - restore hold type and update world model
			if self.OriginalHoldType then
				self:SetHoldType(self.OriginalHoldType)
			end

			-- Clear both animation flags
			self:SetIsAttachingSuppressor(false)
			self:SetIsDetachingSuppressor(false)

			-- Update world model to show final state
			self:UpdateWorldModel()
		end
	end

	-- Sprint-Jump Detection System
	local isOnGround = self.Owner:IsOnGround()
	self.LastGroundState = self.LastGroundState or true

	-- Detect jump event (was on ground, now in air)
	if self.LastGroundState and not isOnGround then
		-- Check if player is sprinting when they jump
		if self:GetSprint() and self.Owner:KeyDown(IN_SPEED) then
			self.SprintJumping = true
		else
			self.SprintJumping = false
		end
	end

	-- Clear sprint-jumping flag when landing
	if isOnGround and not self.LastGroundState then
		self.SprintJumping = false
	end

	-- Update ground state tracker
	self.LastGroundState = isOnGround

	self:IronSight()
end

--[[
   Name: SWEP:CanStartReload()
   Desc: Determines if reload can start, factoring automatic gating
]]
function SWEP:CanStartReload()
	if self.ShotgunReloading or self.ReloadFinishing then return false end
	if not self.CanReload then return false end

	-- Automatic fire gating: cannot reload while holding fire
	if self.Primary.Automatic and self.Owner:KeyDown(IN_ATTACK) then
		return false
	end

	-- Clip is full or no ammo
	if self:Clip1() >= self.Primary.ClipSize or self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
		return false
	end

	return true
end

--[[
   Name: SWEP:UpdateReloadGate()
   Desc: Updates the reload gate each frame
]]
function SWEP:UpdateReloadGate()
	if not IsValid(self) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then return end

	if self:CanStartReload() then
		self.CanReload = true
	else
		self.CanReload = false
	end
end

function SWEP:Holster()
	-- Critical safety checks for weapon state during transitions
	if not IsValid(self) or not IsValid(self.Weapon) then
		return true
	end

	-- Get both entity index and owner ID for timer cleanup
	local entIndex = self:EntIndex()

	-- Additional safety check for valid entity index
	if not entIndex or entIndex <= 0 then
		return true
	end

	-- Clean up burst timer (from parent gun_base)
	local burstTimerName = "M9K_Burst_" .. entIndex
	if timer.Exists(burstTimerName) then
		timer.Remove(burstTimerName)
	end
	self.BurstShotsRemaining = 0

	-- Cancel parent gun_base timers
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

	-- Cancel shotgun-specific timers (using owner ID)
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

	-- Reset shotgun-specific state variables
	self.ShotgunReloading = false
	self.InsertingShell = false
	self.ReloadCancelled = false
	self.ReloadFinishing = false

	-- STATE-BASED RELOAD: Reset reload state machine when holstering
	self.ReloadState = M9KR_RELOAD_STATES.IDLE
	self.ReloadStateEnd = 0

	-- Cancel reload state when holstering
	if IsValid(self.Weapon) then
		self.Weapon:SetNWBool("Reloading", false)
	end

	-- Reset crouch state to prevent issues during weapon switching
	self.crouchMul = 0
	self.bLastCrouching = false
	self.fCrouchTime = nil

	-- CLIENT-side cleanup
	if CLIENT and IsValid(self.Owner) and not self.Owner:IsNPC() then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			-- Reset viewmodel playback rate
			vm:SetPlaybackRate(1.0)

			-- Reset viewmodel bones (from parent gun_base)
			if M9KR and M9KR.ViewModelMods then
				M9KR.ViewModelMods.ResetBonePositions(vm)
			end
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
	-- Critical safety checks for weapon state during removal
	if not IsValid(self) or not self.EntIndex then
		return
	end

	-- Clean up all active timers when weapon is removed
	local entIndex = self:EntIndex()

	-- Additional safety check for valid entity index
	if not entIndex or entIndex <= 0 then
		return
	end

	-- Clean up burst timer (from parent gun_base)
	local burstTimerName = "M9K_Burst_" .. entIndex
	if timer.Exists(burstTimerName) then
		timer.Remove(burstTimerName)
	end

	-- Cancel all parent gun_base timers
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

	-- Clean up shotgun-specific timers (using owner ID)
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

	-- Reset shotgun-specific state variables
	self.ShotgunReloading = false
	self.InsertingShell = false
	self.ReloadCancelled = false
	self.ReloadFinishing = false

	-- STATE-BASED RELOAD: Reset reload state machine when removing
	self.ReloadState = M9KR_RELOAD_STATES.IDLE
	self.ReloadStateEnd = 0

	-- CLIENT-side cleanup
	if CLIENT and IsValid(self.Owner) and not self.Owner:IsNPC() then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			-- Reset viewmodel bones (from parent gun_base)
			if M9KR and M9KR.ViewModelMods then
				M9KR.ViewModelMods.ResetBonePositions(vm)
			end
		end
	end
end

--[[
   Name: SWEP:Deploy()
   Desc: Whip it out.
]]
function SWEP:Deploy()
	if not IsValid(self) then return end
	if not IsValid(self.Owner) then return end
	if not self.Owner:IsPlayer() then return end
	self.BurstShotsRemaining = nil
	self.ContinuousShotCount = 0  -- Reset progressive spread counter (auto mode)
	self.RapidFireHeat = 0  -- Reset rapid fire heat (semi/burst spam)
	self.LastShotTime = 0
	self.LastTriggerState = false

	self:SetHoldType(self.HoldType)

	local timerName = "ShotgunReload_" ..  self.Owner:UniqueID()
	if (timer.Exists(timerName)) then
		timer.Destroy(timerName)
	end

	-- Initialize chamber state on deploy if not set
	if self.ChamberRound == nil then
		self.ChamberRound = false
	end

	-- Deferred CLIENT initialization (moved from Initialize() for faster spawn)
	if CLIENT and not self.FirstDeployDone then
		self.FirstDeployDone = true

		-- Create instance-level Offset table for offset adjuster tool
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

		-- WepSelectIcon texture loading for weapon selection HUD
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
		self:SetSprint(false) -- Clear sprint state initially
		
		-- Check if player is currently sprinting when weapon is deployed
		if self.Owner:KeyDown(IN_SPEED) then
			local velocity = self.Owner:GetVelocity()
			local speed = velocity:Length2D()
			local isOnGround = self.Owner:IsOnGround()
			
			-- If actually sprinting (not just holding key while standing still)
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

--[[
   Name: SWEP:Reload()
   Desc: Reload is being pressed.
]]
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

    -- Reset tracer shot counter on reload (fresh magazine = reset tracer pattern)
    self.ShotCount = 0

    -- Shell-by-shell reload - fire mode doesn't affect reload
    local maxcap = self.Primary.ClipSize
    local spaceavail = self:Clip1()
    local isEmpty = spaceavail == 0

    -- Calculate shells to load based on reload type
    local shellz
    if self.HasChamber and not isEmpty then
        -- Tactical/partial reload: load to magazine + 1 for chamber
        shellz = maxcap - spaceavail + 1
    else
        -- Empty reload: load to magazine only (no +1)
        shellz = maxcap - spaceavail
    end

    -- Chamber system: Allow reload if magazine is full but we can add +1 to chamber
    local canReload = false
    if self.HasChamber then
        -- With chamber system: allow reload if not at max capacity (magazine + chamber)
        if spaceavail < maxcap + 1 and self.Owner:GetAmmoCount(self.Primary.Ammo) > 0 then
            canReload = true
        end
    else
        -- Without chamber system: standard behavior
        if spaceavail < maxcap and self.Owner:GetAmmoCount(self.Primary.Ammo) > 0 then
            canReload = true
        end
    end

    -- STATE-BASED RELOAD: Check if already reloading
    if self.ReloadState > M9KR_RELOAD_STATES.IDLE or not canReload then
        return
    end

    self.ShotgunReloading = true
    self.ReloadCancelled = false
    self.ReloadFinishing = false
    self.CanCancelReload = false
    self.Weapon:SetNWBool("Reloading", true)

    -- Track reload state for chamber system
    local currentClip = self:Clip1()
    local isEmpty = currentClip == 0

    -- Track if we started this reload empty (for finish animation selection)
    self.StartedReloadEmpty = isEmpty

    -- Chamber mechanics: Determine if this is a tactical reload (will get +1 chamber)
    if self.HasChamber and not isEmpty then
        -- Tactical reload: magazine has ammo, will get +1 chamber after loading
        self.ChamberRound = true
    elseif self.HasChamber and isEmpty then
        -- Empty reload: will fill magazine but NO +1 chamber initially
        -- (will chamber first round using reload_end_empty animation)
        self.ChamberRound = false
    else
        -- No chamber system
        self.ChamberRound = false
    end

    self.Owner:SetAnimation(PLAYER_RELOAD)

    if SERVER then
        -- FOV managed by m9kr_weapon_state_handler.lua
        self:SetIronsights(false)
    end

    -- STATE-BASED RELOAD: Set initial state
    -- ProcessReloadStatus() will handle the rest
    if self.SkipReloadStartFinish then
        -- Skip start animation - go directly to LOOP state and insert first shell
        self.ReloadState = M9KR_RELOAD_STATES.LOOP
        self.ReloadStateEnd = CurTime()  -- Immediately start inserting
    else
        self.Weapon:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)
        self.ReloadState = M9KR_RELOAD_STATES.START
        -- Use a shorter time for START - don't wait for full animation, transition to LOOP faster
        local startTime = math.min(self.ShellTime or 0.35, self:GetAnimationLength(ACT_SHOTGUN_RELOAD_START, false) * 0.5)
        self.ReloadStateEnd = CurTime() + startTime
    end
end

--[[
   Name: SWEP:InsertShell()
   Desc: DEPRECATED - Replaced by STATE-BASED RELOAD SYSTEM
         Old timer-based shell insertion function.
         Now handled by StateInsertShell() called from ProcessReloadStatus()
]]
function SWEP:InsertShell()
    -- This function is no longer used - replaced by state-based reload system
    -- Shell insertion is now handled by StateInsertShell() in ProcessReloadStatus()
    -- Keeping this stub to avoid errors if anything still references it
end

--[[ OLD TIMER-BASED CODE (DEPRECATED)
function SWEP:InsertShell_OLD()
    if not IsValid(self) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then return end

    local timerName = "ShotgunReload_" .. self.Owner:UniqueID()

    -- Stop immediately if reload was cancelled or already finishing
    if self.ReloadCancelled or self.ReloadFinishing then
        timer.Remove(timerName)
        return
    end

    if self.Owner:Alive() then
        local curwep = self.Owner:GetActiveWeapon()
        if curwep:GetClass() ~= self.Gun then
            timer.Destroy(timerName)
            return
        end

        -- Determine how many shells we can load this step
        -- Chamber system: Calculate max capacity and shells to load
        local currentClip = self:Clip1()
        local maxClip = self.Primary.ClipSize
        local maxCapacity = maxClip
        local reserveAmmo = self.Owner:GetAmmoCount(self.Primary.Ammo)

        -- Calculate how much space we have for loading shells
        local spaceInMagazine = maxClip - currentClip
        local shellsToLoad = 0

        if self.HasChamber and self.ChamberRound and not self.StartedReloadEmpty then
            -- Tactical/partial reload with +1 chamber
            -- Can load to maxClip + 1
            if currentClip < maxClip then
                -- Magazine has space - fill it normally
                shellsToLoad = math.min(self.ShellsPerLoad or 1, spaceInMagazine, reserveAmmo)
            elseif currentClip == maxClip and reserveAmmo > 0 then
                -- Magazine is exactly full - load 1 shell for chambering
                -- This will make clip = maxClip + 1 (e.g., 6 in tube + 1 in chamber = 7)
                shellsToLoad = 1
            else
                -- Already over capacity or no ammo - finish reload
                shellsToLoad = 0
            end
        else
            -- Empty reload or standard reload: fill to maxClip only (no +1)
            shellsToLoad = math.min(self.ShellsPerLoad or 1, spaceInMagazine, reserveAmmo)
        end

        -- FIRST: Add shells to clip if we're loading any
        if shellsToLoad > 0 then
            self.InsertingShell = true

            -- SERVER: Transfer ammo immediately to prevent timing issues with finish condition
            if SERVER then
                -- Transfer ammo from reserves to clip
                self.Owner:RemoveAmmo(shellsToLoad, self.Primary.Ammo, false)
                self:SetClip1(self:Clip1() + shellsToLoad)
            end

            -- For UseLeverCockFinish weapons: check if this is the last shell
            -- The finish animation includes shell insertion, so skip the regular animation/sound
            local isLastShell = false
            local shouldPlayAnimation = true
            local shouldPlaySound = true

            if self.UseLeverCockFinish and self.HasChamber then
                local updatedClip = self:Clip1()

                -- Check if this is the last shell (same logic as finish condition)
                if self.StartedReloadEmpty then
                    -- Empty reload: last shell is when we reach maxClip
                    isLastShell = (updatedClip >= maxClip)
                else
                    -- Tactical/partial reload: last shell is when we exceed maxClip or run out of ammo
                    isLastShell = (updatedClip > maxClip or reserveAmmo - shellsToLoad <= 0)
                end

                if isLastShell then
                    shouldPlayAnimation = false  -- Skip animation, finish animation includes it
                    shouldPlaySound = false      -- Skip sound, finish animation will play lever cock
                end
            end

            -- Play shell insertion animation with a small delay for proper viewmodel sync
            if shouldPlayAnimation then
                -- Use CurTime to make timer name unique for each shell animation
                local shellAnimTimerName = "ShotgunShellAnim_" .. self.Owner:UniqueID() .. "_" .. CurTime()
                timer.Create(shellAnimTimerName, 0.03, 1, function()
                    if not IsValid(self) then return end
                    -- Allow animation to play even if ReloadFinishing is true (for last shell)
                    if not self.ReloadCancelled then
                        self:ShellAnimCaller()
                    end
                end)
            end

            if self.ForcePlayInsertSound and shouldPlaySound then
                self:EmitSound(self.ForcePlayInsertSound)
            end
        end

        -- SECOND: Determine if we should finish the reload (after adding shells)
        local shouldFinish = false
        -- Since ammo is transferred immediately, use the actual current clip value
        local updatedClip = self:Clip1()

        if self.HasChamber and self.ChamberRound and not self.StartedReloadEmpty then
            -- Tactical/partial reload: finish when we've loaded the +1 or out of ammo or can't load more
            if updatedClip > maxClip then
                shouldFinish = true  -- We're over capacity (have the +1 loaded)
            elseif shellsToLoad == 0 or reserveAmmo - shellsToLoad <= 0 then
                shouldFinish = true  -- Can't load any more shells or out of ammo
            end
        else
            -- Empty reload or standard: finish when magazine is full or out of ammo or can't load more
            if updatedClip >= maxClip or shellsToLoad == 0 or reserveAmmo - shellsToLoad <= 0 then
                shouldFinish = true
            end
        end

        -- THIRD: Play finish animation if needed
        if shouldFinish then
            -- Don't run finish logic if we're already finishing
            if self.ReloadFinishing then
                return
            end

            self.ReloadFinishing = true
            self.ReloadCancelled = false

            -- Destroy both the main timer and any lingering shell timers
            timer.Remove(timerName)

            -- Wait for the insert animation to finish before playing the finish animation
            -- For UseLeverCockFinish weapons, we skipped the last shell's animation,
            -- so use a shorter delay for smoother transition to finish animation
            local insertAnimDuration = self.ShellTime + 0.03
            if self.UseLeverCockFinish and self.HasChamber then
                -- Last shell animation was skipped, use minimal delay
                insertAnimDuration = 0.05
            end

            local finishStartTimerName = "ShotgunFinishStart_" .. self.Owner:UniqueID()
            timer.Create(finishStartTimerName, insertAnimDuration, 1, function()
                if not IsValid(self) or not IsValid(self.Owner) then return end

                self.InsertingShell = false  -- Prevent Think() from overriding finish animation

                local vm = self.Owner:GetViewModel()
                local finishTime = 0.5

                if IsValid(vm) then
                    -- Reset viewmodel to after_reload sequence first (like CancelReload does)
                    local afterReloadSeq = vm:LookupSequence("after_reload")
                    if afterReloadSeq and afterReloadSeq >= 0 then
                        vm:ResetSequence(afterReloadSeq)
                    end

                    -- Determine which finish animation to use
                    local startedEmpty = self.StartedReloadEmpty or false
                    local currentMode = self:GetCurrentFireMode()

                    -- Determine which finish animation to use based on fire mode
                    -- Pump-action, burst, lever-action, semi-auto: use ACT_SHOTGUN_RELOAD_FINISH (cycle action)
                    -- Other weapons: use ACT_SHOTGUN_IDLE_DEEP (standard finish)
                    local finishSeq
                    if currentMode == "pump" or currentMode == "burst" or currentMode == "lever" or currentMode == "semi" then
                        -- Pump-action, burst mode, lever-action, or semi-auto: cycle action after reload
                        self.Weapon:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
                        finishSeq = vm:LookupSequence(vm:GetSequenceName(vm:SelectWeightedSequence(ACT_SHOTGUN_RELOAD_FINISH)))
                    else
                        -- Standard finish: use ACT_SHOTGUN_IDLE_DEEP
                        self.Weapon:SendWeaponAnim(ACT_SHOTGUN_IDLE_DEEP)
                        finishSeq = vm:LookupSequence(vm:GetSequenceName(vm:SelectWeightedSequence(ACT_SHOTGUN_IDLE_DEEP)))
                    end

                    -- Get the sequence duration directly from the sequence we just set
                    if finishSeq and finishSeq >= 0 then
                        local seqDuration = vm:SequenceDuration(finishSeq)
                        -- Sanity check: ensure duration is valid and reasonable (0.1 to 5 seconds)
                        if seqDuration and seqDuration > 0.1 and seqDuration < 5 then
                            finishTime = seqDuration
                        end
                    end
                end

                -- Block firing until finish animation completes (add small buffer like CancelReload)
                self.Weapon:SetNextPrimaryFire(CurTime() + finishTime + 0.1)

                local finishTimerName = "ShotgunFinish_" .. self.Owner:UniqueID()
                timer.Create(finishTimerName, finishTime, 1, function()
                    if not IsValid(self) then return end

                    -- Chamber system: The +1 was already added when we loaded the shell
                    -- The finish animation (reload_end_empty) is just visual - showing the lever cycle
                    -- No additional ammo manipulation needed here

                    self.ReloadFinishing = false
                    self.ShotgunReloading = false
                    self.InsertingShell = false
                    self.Weapon:SetNWBool("Reloading", false)

                    -- Send weapon back to idle animation after reload completes
                    if self.Silenced then
                        self.Weapon:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
                    else
                        self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
                    end
                end)
            end)
            return
        end

        -- If we didn't finish, we'll continue loading shells on next timer tick
    end
end
]]-- END OLD TIMER-BASED CODE

--[[
   Name: SWEP:ShellAnimCaller()
   Desc: Animation for inserting a shell.
]]
function SWEP:ShellAnimCaller()
	self.Weapon:SendWeaponAnim(ACT_VM_RELOAD)
end

--[[
   Name: SWEP:CancelReload()
   Desc: Helper for cancelling a reload.
]]
function SWEP:CancelReload()
    if not IsValid(self) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then return end

    -- Only cancel if we were reloading
    if self.ReloadState <= M9KR_RELOAD_STATES.IDLE then return end

    -- Set cancelled flag for state machine
    self.ReloadCancelled = true
    self.ReloadFinishing = true
    self.InsertingShell = false

    -- Restore ironsights immediately based on right-click
    if self.Owner:KeyDown(IN_ATTACK2) then
        self:SetIronsights(true)
    else
        self:SetIronsights(false)
    end

    if self.SkipReloadStartFinish then
        -- Skip finish animation - go directly to idle
        self:CompleteCancelReload()
        self.ReloadState = M9KR_RELOAD_STATES.IDLE
        self.ReloadStateEnd = CurTime()
        -- Small delay before firing to prevent accidental shot
        self:SetNextPrimaryFire(CurTime() + 0.15)
    else
        -- Play finish animation immediately
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then
            vm:ResetSequence(vm:LookupSequence("after_reload"))
        end

        self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)

        -- STATE-BASED RELOAD: Transition to CANCEL state
        -- Let state machine handle completion
        local finishTime = self:GetAnimationLength(ACT_SHOTGUN_RELOAD_FINISH, false)
        self.ReloadState = M9KR_RELOAD_STATES.CANCEL
        self.ReloadStateEnd = CurTime() + finishTime

        -- Delay firing until finish animation completes
        self:SetNextPrimaryFire(CurTime() + finishTime + 0.1)
    end
end

if CLIENT then
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
end