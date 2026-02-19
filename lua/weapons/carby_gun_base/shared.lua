-- Variables that are used on both client and server

-- Precache arrow impact model
util.PrecacheModel("models/viper/mw/attachments/crossbow/attachment_vm_sn_crossbow_mag.mdl")

-- Base weapon class (required for GMod weapon system)
SWEP.Base = "weapon_base"

-- Animation sequence name mappings for viewmodel activities
-- These map GMod activity constants to the sequence names used in weapon models
-- ACT_VM_DRAW_DEPLOY -> "draw_first" - First time drawing the weapon
-- ACT_VM_RELOAD -> "reload" - Standard reload animation
-- ACT_VM_RELOAD_EMPTY -> "reload_empty" - Reload from empty animation
-- ACT_VM_PRIMARYATTACK_1 -> "fire_ads" - ADS (aimed down sights) fire animation
-- ACT_VM_PRIMARYATTACK_2 -> "fire_suppressed_ads" - Suppressed ADS fire animation
-- ACT_VM_IDLE -> "idle" - Idle animation

SWEP.Category = ""
SWEP.Gun = ""
SWEP.Author = "Generic Default, Worshipper, Clavus, and Bob"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.MuzzleAttachment = "1" -- Should be "1" for CSS models or "muzzle" for hl2 models
SWEP.WMCorrectedMuzzle = false -- Set true on MW-ported weapons where bonemerge positioning doesn't match the Offset render
SWEP.MuzzleFlashEffect = "m9kr_muzzleflash_rifle" -- Muzzle flash effect when unsuppressed
SWEP.MuzzleFlashEffectSilenced = nil -- Muzzle flash effect when suppressed (optional, set per weapon)
SWEP.DrawCrosshair = true
SWEP.ShowCrosshairInADS = false -- If true, crosshair stays visible during ADS (for weapons without perfect iron sights)
SWEP.ViewModelFOV = 65 -- How big the gun will look
SWEP.ViewModelFlip = true -- True for CSS models, False for HL2 models
SWEP.WorldModel = "" -- World model path
SWEP.WorldModelSilenced = nil -- World model path when suppressed (optional, for weapons with CanBeSilenced)

SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.Primary.Sound = Sound("") -- Sound of the gun
SWEP.Primary.Round = "" -- What kind of bullet?
SWEP.Primary.Cone = 0.2 -- Accuracy of NPCs
SWEP.Primary.Recoil = 10
SWEP.Primary.Damage = 10
SWEP.Primary.NumShots = 1
SWEP.Primary.RPM = 0 -- This is in Rounds Per Minute
SWEP.Primary.ClipSize = 0 -- Size of a clip
SWEP.Primary.DefaultClip = 0 -- Default number of bullets in a clip
SWEP.Primary.KickUp = 0 -- Maximum up recoil (rise)
SWEP.Primary.KickDown = 0 -- Maximum down recoil (skeet)
SWEP.Primary.KickHorizontal = 0 -- Maximum side recoil (koolaid)
SWEP.Primary.Ammo = "none"

SWEP.EmptySoundPlayed = false
SWEP.CanReload = true

-- Chamber mechanics for +1 tactical reload system
SWEP.HasChamber = true -- Enable chamber mechanics (set to false to disable)
SWEP.ChamberRound = false -- Is there currently a round chambered?

-- High-RPM weapon optimization (for weapons like minigun at 2500+ RPM)
SWEP.DisableBulletImpacts = false -- Disable per-bullet impact effects (prevents view lock at high fire rates)
SWEP.SoundIndicatorInterval = nil -- Play fire sound every N shots instead of every shot (nil = every shot)

-- Action sounds to stop on holster (draw, reload, bolt sounds, etc. - NOT fire sounds)
-- Example: SWEP.ActionSounds = {"M9KR_MA5C.Draw", "M9KR_MA5C.Reload", "M9KR_MA5C.Reload_Empty"}
SWEP.ActionSounds = {}

-- Fire mode system with dynamic spread modifiers
-- Spread values (hip fire only, ADS always 0):
--   auto: 0.0125 (default hip fire)
--   burst: 0.003 (tighter hip fire)
--   semi: 0.0001 (very tight hip fire)
--   bolt: 0.001 (bolt-action precision)
SWEP.FireModes = {"auto", "semi"} -- Defaults : weapons override this
SWEP.CurrentFireMode = 1 -- Index into FireModes table
SWEP.FireModeNames = {
	-- standard fire modes
	safe = "SAFETY", -- new mode - Use Key + Attack to toggle
	auto = "AUTOMATIC",
	semi = "SEMI-AUTOMATIC",
	burst = "BURST-FIRE",
	-- bolt action rifles
	bolt = "BOLT-ACTION",
	lever = "LEVER-ACTION",
	-- these are primarily to be used for shotguns
	pump = "PUMP-ACTION",
	single = "SINGLE-SHOT",
	double = "DOUBLE-SHOT",
	break_action = "BREAK-ACTION"
}

-- Burst fire configuration
SWEP.BurstDelay = 0.05 -- Delay between each shot within a burst (e.g., shot 1 -> shot 2 -> shot 3)
SWEP.BurstCount = 3 -- Number of shots per burst
SWEP.BurstTriggerPull = 0.35 -- Time in seconds before next trigger pull after burst completes
 
SWEP.Secondary.ClipSize = ""
SWEP.Secondary.Ammo = ""

SWEP.Penetration = true
SWEP.Ricochet = true
SWEP.MaxRicochet = 1
SWEP.RicochetCoin = 1
SWEP.BoltAction = false
SWEP.Scoped = false
SWEP.ShellTime = 0.35
SWEP.CanBeSilenced = false
SWEP.HasGL = false
SWEP.Silenced = false
SWEP.NextSilence = 0
SWEP.NextFireSelect = 0
SWEP.NextSafetyToggle = 0 -- Cooldown for safety toggle
SWEP.OrigCrossHair = true
SWEP.JumpCancelsSprint = true -- If true, jumping while sprinting cancels sprint and allows shooting
SWEP.Safety = false -- Weapon safety (default OFF, toggle with USE + ATTACK)
SWEP.ReloadSpeedModifier = 1.0 -- Reload animation speed multiplier (1.0 = normal speed, 2.0 = 2x speed)

SWEP.CrouchPos = Vector(0, 1.5, -0.3)
SWEP.CrouchAng = Vector(0, 0, -7)

-- Low ammo sound system (TFA-style)
SWEP.LowAmmoSoundThreshold = 0.33 -- Play low ammo sound when below 33% of clip

-- Client-only animation variables, low ammo, ADS/sprint/FOV state are in cl_init.lua
 
local PainMulti = 1
 
if GetConVar("M9KDamageMultiplier") == nil then
		PainMulti = 1
		print("M9KDamageMultiplier is missing! You may have hit the lua limit! Reverting multiplier to 1.")
else
		PainMulti = GetConVar("M9KDamageMultiplier"):GetFloat()
		if PainMulti < 0 then
				PainMulti = PainMulti * -1
				print("Your damage multiplier was in the negatives. It has been reverted to a positive number. Your damage multiplier is now "..PainMulti)
		end
end
 
function NewM9KDamageMultiplier(cvar, previous, new)
		print("multiplier has been changed ")
		if GetConVar("M9KDamageMultiplier") == nil then
				PainMulti = 1
				print("M9KDamageMultiplier is missing! You may have hit the lua limit! Reverting multiplier to 1, you will notice no changes.")
		else
				PainMulti = GetConVar("M9KDamageMultiplier"):GetFloat()
				if PainMulti < 0 then
						PainMulti = PainMulti * -1
						print("Your damage multiplier was in the negatives. It has been reverted to a positive number. Your damage multiplier is now "..PainMulti)
				end
		end
end
cvars.AddChangeCallback("M9KDamageMultiplier", NewM9KDamageMultiplier)
 
function NewDefClips(cvar, previous, new)
		print("Default clip multiplier has changed. A server restart will be required for these changes to take effect.")
end
cvars.AddChangeCallback("M9KDefaultClip", NewDefClips)
 
if GetConVar("M9KDefaultClip") == nil then
		print("M9KDefaultClip is missing! You may have hit the lua limit!")
else
		if GetConVar("M9KDefaultClip"):GetInt() >= 0 then
				print("M9K Weapons will now spawn with "..GetConVar("M9KDefaultClip"):GetFloat().." clips.")
		else
				print("Default clips will be not be modified")
		end
end
 
SWEP.IronSightsPos = Vector (2.4537, 1.0923, 0.2696)
SWEP.IronSightsAng = Vector (0.0186, -0.0547, 0)

-- These multipliers reduce recoil when aiming down sights
-- Runtime scaling means we only need ONE fire animation, not separate hip/ADS versions
-- 
-- PHILOSOPHY: When ADS, weapons should have MINIMAL horizontal jump
-- This creates stable, controllable ADS that feels professional and tactical
SWEP.ViewModelPunchPitchMultiplier = 0.5  -- Hip-fire vertical viewmodel recoil
SWEP.ViewModelPunchYawMultiplier = 0.5  -- Hip-fire horizontal viewmodel recoil
SWEP.ViewModelPunch_VerticalMultiplier = 0.3  -- Hip-fire backward push
SWEP.ViewModelPunch_MaxVerticalOffset = 3  -- Maximum backward offset in units

-- Internal recoil tracking (don't modify these)
SWEP.ViewPunchP = 0  -- Vertical recoil accumulator
SWEP.ViewPunchY = 0  -- Horizontal recoil accumulator
SWEP.IronSightsProgress = 0  -- 0.0 = hip, 1.0 = fully ADS

-- World model offset for proper positioning (prevents "crotch gun" issue)
-- Maps to bone-relative coordinates (Forward/Right/Up and rotations)
-- When using SWEP Construction Kit to position weapons:
--   SCK Position X → Offset.Pos.Up
--   SCK Position Y → Offset.Pos.Right
--   SCK Position Z → Offset.Pos.Forward
--   SCK Angle Pitch → Offset.Ang.Up
--   SCK Angle Yaw → Offset.Ang.Right
--   SCK Angle Roll → Offset.Ang.Forward
SWEP.Offset = {
	Pos = {
		Up = 0,      -- Vertical position (SCK Position X)
		Right = 0,   -- Horizontal position left/right (SCK Position Y)
		Forward = 0  -- Depth position forward/back (SCK Position Z)
	},
	Ang = {
		Up = 0,      -- Rotation around vertical axis / yaw (SCK Angle Pitch)
		Right = 0,   -- Rotation around horizontal axis / pitch (SCK Angle Yaw)
		Forward = 0  -- Rotation around depth axis / roll (SCK Angle Roll)
	},
	Scale = 1        -- World model scale (default 1.0)
}

--[[
	Network variables for client-server synchronization
	Allows suppressor state to be visible to all players
]]--
function SWEP:SetupDataTables()
	-- Network suppressor state so other players can see the suppressor attachment
	self:NetworkVar("Bool", 0, "IsSuppressed")

	-- Network suppressor attachment/detachment animation state
	self:NetworkVar("Bool", 1, "IsAttachingSuppressor")  -- TRUE while ATTACH animation is playing
	self:NetworkVar("Bool", 2, "IsDetachingSuppressor")  -- TRUE while DETACH animation is playing
	self:NetworkVar("Float", 0, "SuppressorAnimEndTime") -- Time when animation finishes

	-- Network safety state so other players can see the weapon is on safe
	self:NetworkVar("Bool", 3, "IsOnSafe") -- TRUE when weapon safety is engaged
end

--[[
	Update world model based on suppressor state
	Switches between regular and suppressed world models dynamically

	ATTACHMENT BEHAVIOR:
	- During ATTACH animation: Suppressor is HIDDEN (not yet visible)
	- After ATTACH completes: Suppressor becomes VISIBLE

	DETACHMENT BEHAVIOR:
	- During DETACH animation: Suppressor is STILL VISIBLE (being removed)
	- After DETACH completes: Suppressor becomes HIDDEN

	This creates realistic behavior where:
	- You can't see a suppressor that hasn't been attached yet
	- You CAN see a suppressor while it's being removed
]]--
function SWEP:UpdateWorldModel()
	if not self.CanBeSilenced or not self.WorldModelSilenced then return end

	-- Store the original world model on first call
	if not self.WorldModelOriginal then
		self.WorldModelOriginal = self.WorldModel
	end

	-- Determine which world model to use based on suppressor state and animation
	local showSuppressor = false

	if self:GetIsAttachingSuppressor() then
		-- ATTACHING: Hide suppressor during animation (not yet attached)
		showSuppressor = false
	elseif self:GetIsDetachingSuppressor() then
		-- DETACHING: Keep suppressor visible during animation (still attached)
		showSuppressor = true
	else
		-- NOT ANIMATING: Show suppressor based on current state
		showSuppressor = self:GetIsSuppressed()
	end

	local newModel = showSuppressor and self.WorldModelSilenced or self.WorldModelOriginal

	-- Update WorldModel property (this is what the engine uses for rendering)
	self.WorldModel = newModel

	-- DO NOT call SetModel() here - it breaks viewmodel animations!
	-- The WorldModel property change is sufficient for rendering.
	-- The actual world model entity is only created/updated during DrawWorldModel()
end

function SWEP:Initialize()
	self.Reloadaftershoot = 0 -- Can't reload when firing
	self:SetHoldType(self.HoldType)
	self.OrigCrossHair = self.DrawCrosshair

	-- Initialize chamber state
	self.ChamberRound = false

	-- Initialize sound interval counter for high-RPM weapons
	if self.SoundIndicatorInterval then
		self.ShotsSinceSoundPlayed = 0
	end

	-- Fix metatable inheritance issue: ensure FireModes is a clean copy
	-- GMod's metatable inheritance can cause child weapons to see parent's FireModes
	-- Use table.Copy to break the metatable chain completely
	if self.FireModes then
		self.FireModes = table.Copy(self.FireModes)
	end
	
	-- Initialize fire mode - set Primary.Automatic for GMod's base SWEP system
	-- GMod's weapon system reads Primary.Automatic to determine auto-fire behavior
	-- We set it based on the FireMode enum system for compatibility
	if self.FireModes then
		-- HOT-RELOAD FIX: Restore fire mode from networked variable if available
		-- When lua_openscript reloads the weapon, the networked variable persists
		-- but the SWEP table is recreated, so we need to restore state
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

		-- Set hip-fire spread based on fire mode (if not already defined by weapon)
		-- Shotguns and weapons with manually-defined spread values are excluded
		-- Check for shotty_base OR weapons with PreserveSpreadValues flag (for magazine-fed shotguns)
		local isShotgun = self.Base == "carby_shotty_base" or self.PreserveSpreadValues
		if not self.Primary.Spread and not isShotgun then
			if mode == "bolt" then
				self.Primary.Spread = .001  -- Bolt-action precision
			end
		end
	else
		-- No FireModes defined, default to auto
		self.Primary.Automatic = true
	end

	-- Initialize recoil tracking
	self.ViewPunchP = 0
	self.ViewPunchY = 0

	-- Initialize tracer shot counter
	self.ShotCount = 0
	self.IronSightsProgress = 0
	self.IronSightsProgressSmooth = 0  -- Smoothed version for animations

	-- Initialize suppressor state network variable
	self:SetIsSuppressed(self.Silenced or false)

	-- Initialize safety state network variable (weapon starts on safe)
	self:SetIsOnSafe(self.Safety or false)

	-- Set correct world model based on initial suppressor state
	self:UpdateWorldModel()

	-- Low ammo and ADS sounds are precached by centralized CLIENT files
	
	if SERVER and IsValid(self.Owner) and self.Owner:IsNPC() then
		self:SetNPCMinBurst(3)
		self:SetNPCMaxBurst(10)
		self:SetNPCFireRate(1 / (self.Primary.RPM / 60))
	end
	
	if CLIENT then
		-- Create a new table for every weapon instance (if it exists)
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
		-- Offset table, viewmodel setup, and texture loading happen on first deploy
	end
end

-- DrawWeaponSelection is in cl_init.lua


function SWEP:Equip()
		self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
	self:SetIronsights(false, self.Owner) -- Set the ironsight false
	self:SetSprint(false) -- Clear sprint state initially
	self:SetHoldType(self.HoldType)
	self.BurstShotsRemaining = nil
	self.ContinuousShotCount = 0  -- Reset progressive spread counter (auto mode)
	self.RapidFireHeat = 0  -- Reset rapid fire heat (semi/burst spam)
	self.LastShotTime = 0
	self.LastTriggerState = false

	-- Update world model to match current suppressor state (important when switching weapons)
	self:UpdateWorldModel()

	-- Initialize chamber state on deploy if not set
	if self.ChamberRound == nil then
		self.ChamberRound = false
	end
	
	-- Check if player is currently sprinting when weapon is deployed
	if IsValid(self.Owner) and self.Owner:KeyDown(IN_SPEED) then
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
	
	-- Initialize animation variables on deploy (clientside)
	if CLIENT then
		self.AnimationTime = 0
		self.BreathIntensity = 0
		self.WalkIntensity = 0
		self.SprintIntensity = 0
		self.JumpVelocitySmooth = 0
		self.LateralVelocity = 0
		self.LateralVelocitySmooth = 0
		self.LastGroundState = true
		self.ADSRecoilIntensity = 0 -- For tracking ADS recoil animation
		self.LastShotTime = 0 -- Track when last shot was fired

		-- Weapon input state (ADS, sprint, FOV transitions)
		self.m9kr_IsInADS = false
		self.m9kr_IsInSprint = false
		self.m9kr_FOVCurrent = 0
		self.m9kr_FOVStart = 0
		self.m9kr_FOVTarget = 0
		self.m9kr_FOVTransitionStart = 0
		self.m9kr_FOVTransitionDuration = 0.2
		self.m9kr_LastUseState = false
		self.m9kr_LastAttack2State = false
		self.m9kr_LastReloadState = false
		self.m9kr_LastSafetyState = false
		self.m9kr_Attack2HeldDuringSprint = false
		self.ShouldDrawViewModel = true
	end
	
	-- Handle first deploy vs subsequent deploys
	if not self.FirstDeployDone then
		-- First time deploying this weapon
		self.FirstDeployDone = true

		-- Deferred CLIENT initialization (moved from Initialize() for faster spawn)
		if CLIENT then
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

			-- Initialize viewmodel visibility
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				if self.ShowViewModel == nil or self.ShowViewModel then
					vm:SetColor(Color(255, 255, 255, 255))
				else
					vm:SetMaterial("Debug/hsv")
				end
			end
		end

		local drawAnim = ACT_VM_DRAW
		local vm = self.Owner:GetViewModel()

		if IsValid(vm) then
			-- Try special first-time deploy animations
			if self.Silenced then
				-- For suppressed weapons, try ACT_VM_DRAW_EMPTY
				local emptySeq = vm:SelectWeightedSequence(ACT_VM_DRAW_EMPTY)
				if emptySeq and emptySeq > -1 then
					vm:SendViewModelMatchingSequence(emptySeq)
					drawAnim = nil  -- Don't send anim again
				end
			else
				-- For regular weapons, try ACT_VM_DRAW_DEPLOYED
				local deploySeq = vm:SelectWeightedSequence(ACT_VM_DRAW_DEPLOYED)
				if deploySeq and deploySeq > -1 then
					vm:SendViewModelMatchingSequence(deploySeq)
					drawAnim = nil  -- Don't send anim again
				end
			end
		end

		-- Only send weapon anim if we didn't already send a sequence
		if drawAnim then
			self.Weapon:SendWeaponAnim(drawAnim)
		end
	else
		-- Subsequent deploys use standard draw animation
		if self.Silenced then
			self.Weapon:SendWeaponAnim(ACT_VM_DRAW_SILENCED)
		else
			self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
		end
	end
	
	self.Weapon:SetNWBool("Reloading", false)

	if not self.Owner:IsNPC() and IsValid(self.Owner) and IsValid(self.Owner:GetViewModel()) then
		if self.ResetSights then
			self.ResetSights = CurTime() + self.Owner:GetViewModel():SequenceDuration()
		end
	end

	return true
end
 
function SWEP:Holster()
	-- Clean up burst state when holstering
	self.BurstShotsRemaining = 0
	self.NextBurstShotTime = nil
	
	-- Cancel any active reload timers to prevent ammo being added after weapon switch
	local reloadTimerName = "M9K_Reload_" .. self:EntIndex()
	if timer.Exists(reloadTimerName) then
		timer.Remove(reloadTimerName)
	end
	
	-- Cancel reload sprint transition timer
	local sprintTimerName = "M9K_ReloadSprint_" .. self:EntIndex()
	if timer.Exists(sprintTimerName) then
		timer.Remove(sprintTimerName)
	end
	
	-- Cancel silencer attachment/detachment timer
	local silencerTimerName = "M9K_Silencer_" .. self:EntIndex()
	if timer.Exists(silencerTimerName) then
		timer.Remove(silencerTimerName)
	end
	
	-- Cancel reload state when holstering
	if IsValid(self.Weapon) then
		self.Weapon:SetNWBool("Reloading", false)
		-- Reset NextPrimaryFire to prevent being unable to fire after mid-reload weapon swap
		-- The draw animation delay will be added in Deploy()
		self.Weapon:SetNextPrimaryFire(CurTime())
	end
	
	-- Reset crouch state to prevent issues during weapon switching
	self.crouchMul = 0
	self.bLastCrouching = false
	self.fCrouchTime = nil

	if CLIENT and IsValid(self.Owner) and not self.Owner:IsNPC() then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetViewModelBones(vm)
		end

		-- Reset weapon input state so next weapon starts clean
		self.m9kr_FOVCurrent = 0
		self.m9kr_FOVTarget = 0
		self.m9kr_IsInADS = false
		self.m9kr_IsInSprint = false
		self.ShouldDrawViewModel = true
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
	-- Clean up burst timer when weapon is removed
	local timerName = "M9K_Burst_" .. self:EntIndex()
	if timer.Exists(timerName) then
		timer.Remove(timerName)
	end
	
	-- Clean up reload timer when weapon is removed
	local reloadTimerName = "M9K_Reload_" .. self:EntIndex()
	if timer.Exists(reloadTimerName) then
		timer.Remove(reloadTimerName)
	end
	
	-- Clean up reload sprint transition timer when weapon is removed
	local sprintTimerName = "M9K_ReloadSprint_" .. self:EntIndex()
	if timer.Exists(sprintTimerName) then
		timer.Remove(sprintTimerName)
	end
	
	-- Clean up silencer timer when weapon is removed
	local silencerTimerName = "M9K_Silencer_" .. self:EntIndex()
	if timer.Exists(silencerTimerName) then
		timer.Remove(silencerTimerName)
	end
	
	if CLIENT and IsValid(self.Owner) and not self.Owner:IsNPC() then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetViewModelBones(vm)
		end

	end
end
 
function SWEP:GetCapabilities()
		return CAP_WEAPON_RANGE_ATTACK1, CAP_INNATE_RANGE_ATTACK1
end
 
function SWEP:Precache()
		util.PrecacheSound(self.Primary.Sound)
		util.PrecacheModel(self.ViewModel)
		util.PrecacheModel(self.WorldModel)
end

-- Override CanPrimaryAttack to prevent engine's default "Weapon_AR2.Empty" click sound
function SWEP:CanPrimaryAttack()
	-- Check if we have ammo in clip
	if self.Weapon:Clip1() <= 0 then
		-- Mark chamber as empty
		self.ChamberRound = false
		
		-- Allow reload on empty fire if we have reserve ammo
		if self.Owner:GetAmmoCount(self.Weapon:GetPrimaryAmmoType()) > 0 then
			-- Trigger reload instead of returning false with click sound
			if not self.Weapon:GetNWBool("Reloading") then
				self:Reload()
			end
		end
		return false -- No click sound, just return false
	end
	return true
end

-- Helper function to check if viewmodel has a specific animation sequence
function SWEP:HasSequence(activityID)	
	if not activityID or not IsValid(self) or not IsValid(self.Owner) then return false end

	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then return false end

	local seqID = vm:SelectWeightedSequence(activityID)
	local hasSeq = seqID and seqID > 0 and seqID ~= -1
	
	return hasSeq
end

-- Helper function to check if a sequence exists by name
function SWEP:HasSequenceByName(sequenceName)
	if not sequenceName or not IsValid(self) or not IsValid(self.Owner) then return false end

	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then return false end

	local seqID = vm:LookupSequence(sequenceName)
	return seqID and seqID > 0 and seqID ~= -1
end

-- Helper function to fire a single burst shot
function SWEP:FireBurstShot()
	if not IsValid(self) or not IsValid(self.Weapon) or not IsValid(self.Owner) then
		self.BurstShotsRemaining = 0
		return
	end

	-- Check if we still have ammo
	if self.Weapon:Clip1() <= 0 then
		self.BurstShotsRemaining = 0
		return
	end

	-- CRITICAL: Stop burst immediately if player starts actually sprinting
	-- Sprint only blocks if player is moving while holding sprint key on ground AND pressing movement keys
	local isSprintJumping = self.Owner:KeyDown(IN_SPEED) and not self.Owner:IsOnGround()
	local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
	local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and self.Owner:IsOnGround() and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement
	if isActuallySprinting and not isSprintJumping then
		-- Player is actually sprinting on ground - cancel burst
		self.BurstShotsRemaining = 0
		return
	end
	
	-- Fire the shot
	self:ShootBulletInformation()
	self.Weapon:TakePrimaryAmmo(1)

	-- Track shot time for ADS recoil animation and low ammo warning
	-- In SP, SERVER runs PrimaryAttack (CLIENT prediction may not), so SERVER must also call
	if CLIENT or (game.SinglePlayer() and SERVER) then
		self.LastShotTime = CurTime()
		if self.CheckLowAmmo then self:CheckLowAmmo() end
	end
	
	-- Determine fire animation based on ADS state
	-- On SERVER: Check if owner is holding IN_ATTACK2 (for animation networking)
	-- PrimaryAttack runs on SERVER, so we check owner's key state directly
	local bIron = self.Owner:KeyDown(IN_ATTACK2)

	if self.Silenced then
		if bIron and self:HasSequence(ACT_VM_PRIMARYATTACK_2) then
			self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_2)
		else
			self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_SILENCED)
		end

		-- Play sound with overlap support for high-RPM weapons
		if self.SoundIndicatorInterval then
			self.ShotsSinceSoundPlayed = (self.ShotsSinceSoundPlayed or 0) + 1
			if self.ShotsSinceSoundPlayed >= self.SoundIndicatorInterval then
				self:EmitSound(self.Primary.SilencedSound or "")
				self.ShotsSinceSoundPlayed = 0
			end
		else
			self:EmitSound(self.Primary.SilencedSound or "")
		end
	else
		if bIron and self:HasSequence(ACT_VM_PRIMARYATTACK_1) then
			self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_1)
		else
			self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		end

		-- Play sound with overlap support for high-RPM weapons
		if self.SoundIndicatorInterval then
			self.ShotsSinceSoundPlayed = (self.ShotsSinceSoundPlayed or 0) + 1
			if self.ShotsSinceSoundPlayed >= self.SoundIndicatorInterval then
				self:EmitSound(self.Primary.Sound or "")
				self.ShotsSinceSoundPlayed = 0
			end
		else
			self:EmitSound(self.Primary.Sound or "")
		end
	end
	
	-- Muzzle flash and shell eject (deferred in MP for correct attachment positions)
	self:M9KR_SpawnMuzzleFlash()
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self:M9KR_SpawnShellEject()

	-- Schedule next burst shot if any remaining
	-- Safety check: BurstShotsRemaining can be nil if weapon was switched mid-burst
	if not self.BurstShotsRemaining then return end
	self.BurstShotsRemaining = self.BurstShotsRemaining - 1
	if self.BurstShotsRemaining > 0 then
		-- Schedule next shot via Think() (timers don't survive MP prediction)
		self.NextBurstShotTime = CurTime() + (self.BurstDelay or 0.05)
	end
end

function SWEP:PrimaryAttack()
	if not IsValid(self) or not IsValid(self.Weapon) or not IsValid(self.Owner) then
		return
	end

	-- Prevent firing if safety is engaged
	if self:GetIsOnSafe() then
		return
	end

	if self:CanPrimaryAttack() and self.Owner:IsPlayer() then
		-- Allow shooting if: not actually sprinting, OR sprint jumping is active
		-- Sprint jumping = SPEED held while not on ground
		-- Actually sprinting = SPEED held, on ground, moving, AND pressing movement keys
		local isSprintJumping = self.Owner:KeyDown(IN_SPEED) and not self.Owner:IsOnGround()
		local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
		local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and self.Owner:IsOnGround() and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement

		if (not isActuallySprinting or isSprintJumping) and not self.Owner:KeyDown(IN_RELOAD) then
			-- Burst handling
			if self:IsFireModeBurst() then
				-- Don't start a new burst if one is already running
				if self.BurstShotsRemaining and self.BurstShotsRemaining > 0 then
					return
				end
				
				local clips = self.Weapon:Clip1()
				local shotsToFire = math.min(self.BurstCount or 3, clips or 0)
				if shotsToFire <= 0 then
					-- Empty - no sound (TFA dry fire sounds handle this)
					return
				end
				
				-- Set BurstShotsRemaining BEFORE firing to prevent rapid-fire trigger spam
				self.BurstShotsRemaining = shotsToFire - 1
				
				-- Fire first shot immediately
				self:ShootBulletInformation()
				self.Weapon:TakePrimaryAmmo(1)

				-- Track shot time for ADS recoil animation and low ammo warning
				-- In SP, SERVER runs PrimaryAttack (CLIENT prediction may not), so SERVER must also call
				if CLIENT or (game.SinglePlayer() and SERVER) then
					self.LastShotTime = CurTime()
					if self.CheckLowAmmo then self:CheckLowAmmo() end
				end

				-- Determine fire animation based on ADS state and available sequences
				-- On SERVER: Check if owner is holding IN_ATTACK2 (for animation networking)
				-- PrimaryAttack runs on SERVER, so we check owner's key state directly
				local bIron = self.Owner:KeyDown(IN_ATTACK2)
				local shootAnim = ACT_VM_PRIMARYATTACK

				if self.Silenced then
						-- Silenced weapon logic
						if bIron and self:HasSequence(ACT_VM_PRIMARYATTACK_2) then
								self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_2)
						elseif self:HasSequence(ACT_VM_PRIMARYATTACK_SILENCED) then
								shootAnim = ACT_VM_PRIMARYATTACK_SILENCED
								self.Weapon:SendWeaponAnim(shootAnim)
						else
								self.Weapon:SendWeaponAnim(shootAnim)
						end
						self:EmitSound(self.Primary.SilencedSound or "")
				else
						-- Non-silenced weapon logic
						if bIron and self:HasSequence(ACT_VM_PRIMARYATTACK_1) then
								self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_1)
						else
								self.Weapon:SendWeaponAnim(shootAnim)
						end
						self:EmitSound(self.Primary.Sound or "")
				end
				-- Muzzle flash and shell eject (deferred in MP for correct attachment positions)
				self:M9KR_SpawnMuzzleFlash()
				self.Owner:SetAnimation(PLAYER_ATTACK1)
				self:M9KR_SpawnShellEject()

				-- Schedule remaining burst shots via Think() (timers don't survive MP prediction)
				if self.BurstShotsRemaining > 0 then
					self.NextBurstShotTime = CurTime() + (self.BurstDelay or 0.05)
				end

				-- Time before next trigger pull with tick interval compensation (BurstTriggerPull is now in seconds)
				local curtime = CurTime()
				local curatt = self.Weapon:GetNextPrimaryFire()
				local diff = curtime - curatt

				if diff > engine.TickInterval() or diff < 0 then
					curatt = curtime
				end

				local burstDelay = self.BurstTriggerPull or 0.35
				self.Weapon:SetNextPrimaryFire(curatt + burstDelay)

				self:CheckWeaponsAndAmmo()
				self.RicochetCoin = math.random(1, 4)
				if self.BoltAction then
					self:BoltBack()
				end
			-- Normal single-shot path (existing behavior)
			else
				self:ShootBulletInformation()
				self.Weapon:TakePrimaryAmmo(1)
				
				-- Mark that we fired from the chamber
				if self.HasChamber and self.Weapon:Clip1() > 0 then
					self.ChamberRound = true
				elseif self.Weapon:Clip1() == 0 then
					self.ChamberRound = false
				end
				
			-- Track shot time for ADS recoil animation and low ammo warning
			-- In SP, SERVER runs PrimaryAttack (CLIENT prediction may not), so SERVER must also call
			if CLIENT or (game.SinglePlayer() and SERVER) then
				self.LastShotTime = CurTime()
				if self.CheckLowAmmo then self:CheckLowAmmo() end
			end

			-- Determine fire animation based on ADS state and available sequences
			-- On SERVER: Check if owner is holding IN_ATTACK2 (for animation networking)
			-- PrimaryAttack runs on SERVER, so we check owner's key state directly
			local bIron = self.Owner:KeyDown(IN_ATTACK2)
			local shootAnim = ACT_VM_PRIMARYATTACK

				if self.Silenced then
					-- Silenced weapon logic
					if bIron and self:HasSequence(ACT_VM_PRIMARYATTACK_2) then
							self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_2)
					elseif self:HasSequence(ACT_VM_PRIMARYATTACK_SILENCED) then
							shootAnim = ACT_VM_PRIMARYATTACK_SILENCED
							self.Weapon:SendWeaponAnim(shootAnim)
					else
							self.Weapon:SendWeaponAnim(shootAnim)
					end
					self:EmitSound(self.Primary.SilencedSound)
				else
					-- Non-silenced weapon logic
					if bIron and self:HasSequence(ACT_VM_PRIMARYATTACK_1) then
							self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_1)
					else
							self.Weapon:SendWeaponAnim(shootAnim)
					end
					self:EmitSound(self.Primary.Sound)
				end
				-- Muzzle flash and shell eject (deferred in MP for correct attachment positions)
				self:M9KR_SpawnMuzzleFlash()
				self.Owner:SetAnimation(PLAYER_ATTACK1)
				self:M9KR_SpawnShellEject()

				-- Set fire rate timing with tick interval compensation (CRITICAL for RPM control)
				-- This ensures accurate fire rates on low tickrate servers
				local curtime = CurTime()
				local curatt = self.Weapon:GetNextPrimaryFire()
				local diff = curtime - curatt

				if diff > engine.TickInterval() or diff < 0 then
					curatt = curtime
				end

				local fireDelay = 1 / (self.Primary.RPM / 60)
				self.Weapon:SetNextPrimaryFire(curatt + fireDelay)
				self:CheckWeaponsAndAmmo()
				self.RicochetCoin = math.random(1, 4)
				if self.BoltAction then
					self:BoltBack()
				end
			end
		end -- Close: if (not self.Owner:KeyDown(IN_SPEED)...)
	elseif self:CanPrimaryAttack() and self.Owner:IsNPC() then
		self:ShootBulletInformation()
		self.Weapon:TakePrimaryAmmo(1)
		self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		self:EmitSound(self.Primary.Sound)
		self.Owner:SetAnimation(PLAYER_ATTACK1)

		-- Set fire rate timing with tick interval compensation for NPCs
		local curtime = CurTime()
		local curatt = self.Weapon:GetNextPrimaryFire()
		local diff = curtime - curatt

		if diff > engine.TickInterval() or diff < 0 then
			curatt = curtime
		end

		local fireDelay = 1 / (self.Primary.RPM / 60)
		self.Weapon:SetNextPrimaryFire(curatt + fireDelay)

		self.RicochetCoin = math.random(1, 4)
	end
end

--[[
	Deferred Effect System
	In multiplayer, viewmodel attachment positions are unreliable during CLIENT prediction
	because SetupBones hasn't run yet. Effects are queued and created during render time
	(FireAnimationEvent or PostDrawViewModel) when positions are accurate.
	In singleplayer, SERVER creates effects immediately (CLIENT prediction may not run
	weapon attack functions in SP mode).
]]

function SWEP:M9KR_SpawnMuzzleFlash()
	local mfCvar = GetConVar("M9KR_MuzzleFlash")
	if not mfCvar or not mfCvar:GetBool() then return end

	local effectName = self.MuzzleFlashEffect or "m9kr_muzzleflash_rifle"
	if self.Silenced and self.MuzzleFlashEffectSilenced then
		effectName = self.MuzzleFlashEffectSilenced
	end

	local smokeCvar = GetConVar("m9kr_muzzlesmoketrail")
	local doSmoke = smokeCvar and smokeCvar:GetInt() == 1

	-- SP SERVER: create effects immediately (engine sends to client)
	if game.SinglePlayer() and SERVER then
		local fx = EffectData()
		fx:SetEntity(self.Weapon)
		fx:SetOrigin(self.Owner:GetShootPos())
		fx:SetNormal(self.Owner:GetAimVector())
		fx:SetAttachment(self.MuzzleAttachment)
		util.Effect(effectName, fx)
		if doSmoke then util.Effect("m9kr_muzzlesmoke", fx) end
		return
	end

	-- MP CLIENT: queue for render time (attachment positions unreliable during prediction)
	if CLIENT then
		if not IsFirstTimePredicted() then return end
		self.m9kr_PendingMuzzleFlash = {name = effectName, smoke = doSmoke, time = CurTime()}
	end
end

function SWEP:M9KR_SpawnShellEject()
	if self.NoShellEject then return end
	if not CLIENT then return end
	if not IsValid(self) or not IsValid(self.Owner) then return end
	if self.Owner ~= LocalPlayer() then return end
	if not self.ShellModel then return end

	-- Queue for render time. In both SP and MP, the pending flag is consumed by:
	-- 1. FireAnimationEvent (event 20 / EjectBrass) — if the model has QC events
	-- 2. PostDrawViewModel fallback — if the model lacks QC events (TFA-ported models)
	-- In SP, FireAnimationEvent also ejects unconditionally via game.SinglePlayer() check,
	-- so models WITH QC events will eject there and clear the flag. Models WITHOUT QC events
	-- will fall through to PostDrawViewModel where the flag gets consumed.
	if not game.SinglePlayer() and not IsFirstTimePredicted() then return end
	self.m9kr_PendingShellEject = true
	self.m9kr_PendingShellEjectTime = CurTime()
end

--[[
	Shell Ejection System
	Ejects physical shell casing models from the weapon's shell eject attachment

	NOTE: Shell collision sounds are handled by the m9kr_shell effect.
	No need for duplicate sound tables in weapon base.
]]
function SWEP:EjectShell()
	-- Skip shell ejection for caseless ammunition weapons
	if self.NoShellEject then return end
	if not CLIENT then return end
	if not IsValid(self) or not IsValid(self.Owner) then return end
	if not self.ShellModel then return end

	-- Only spawn viewmodel shells for the local player
	if self.Owner ~= LocalPlayer() then return end

	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then return end

	-- Resolve shell eject attachment: QC-cached > weapon property > default 2
	-- QC data is authoritative (parsed from the model's animation events, always correct for the model)
	-- Weapon config ShellEjectAttachment is a fallback for models without QC EjectBrass events
	local attachmentId = self._qcShellAttachment or tonumber(self.ShellEjectAttachment) or 2

	-- Get attachment position from viewmodel
	local attachment = vm:GetAttachment(attachmentId)
	if not attachment then return end

	-- Create shell ejection effect directly
	local effectData = EffectData()
	effectData:SetOrigin(attachment.Pos)
	effectData:SetNormal(attachment.Ang:Forward())
	effectData:SetEntity(self)
	effectData:SetAttachment(attachmentId)

	util.Effect("m9kr_shell", effectData)
end

--[[
	Override QC Shell Ejection Events
	Blocks the legacy EjectBrass_* events from QC files to prevent double shell spawning
	The custom EjectShell() system handles all shell ejection with collision sounds
]]
function SWEP:FireAnimationEvent(pos, ang, event, options)
	-- Block all animation-based muzzle flash events (we use custom particle effects instead)
	-- Event 21 = Primary muzzle flash (rifles, pistols)
	-- Event 22 = Secondary muzzle flash (silenced weapons, alternate effects)
	-- Event 5001 = CS:S muzzle flash
	-- Event 5011 = DoD:S muzzle flash
	-- Event 5021 = TF2 muzzle flash
	-- Event 6001 = Attachment-based muzzle flash
	if event == 21 or event == 22 or event == 5001 or event == 5011 or event == 5021 or event == 6001 then
		-- MP deferred effect: create muzzle flash now with animation-accurate position
		-- Track that this model has QC muzzle events (prevents PostDrawViewModel fallback)
		if CLIENT then self.m9kr_HasQCMuzzleEvent = true end
		if CLIENT and self.m9kr_PendingMuzzleFlash then
			local pending = self.m9kr_PendingMuzzleFlash
			self.m9kr_PendingMuzzleFlash = nil

			local fx = EffectData()
			fx:SetEntity(self.Weapon)
			fx:SetOrigin(pos)
			fx:SetNormal(ang:Forward())
			fx:SetAttachment(self.MuzzleAttachment)

			util.Effect(pending.name, fx)
			if pending.smoke then
				util.Effect("m9kr_muzzlesmoke", fx)
			end
		end
		return true
	end

	-- Block all EjectBrass events from weapon model QCs
	local optStr = tostring(options or "")
	if string.find(optStr, "EjectBrass") then
		if CLIENT then
			-- Track that this model has QC shell events (prevents PostDrawViewModel fallback)
			self.m9kr_HasQCShellEvent = true

			-- Parse QC parameters to cache the correct shell eject attachment
			-- Format: "EjectBrass_556 3 90" → <effect_name> <attachment_id> <velocity>
			local parts = {}
			for part in string.gmatch(optStr, "%S+") do
				table.insert(parts, part)
			end

			-- Cache the QC attachment ID so EjectShell() uses the correct position
			-- This auto-detects the shell eject attachment from the viewmodel's animation data
			if parts[2] then
				self._qcShellAttachment = tonumber(parts[2])
			end

			-- Create shell eject now (vm:GetAttachment is reliable during render)
			-- SP: always eject when fire animation plays (no pending flag needed)
			-- MP: only eject when the pending flag was set during prediction
			if self.m9kr_PendingShellEject or game.SinglePlayer() then
				self.m9kr_PendingShellEject = nil
				self.m9kr_PendingShellEjectTime = nil
				self:EjectShell()
			end
		end
		return true -- Block default Source Engine brass (EjectShell handles it)
	end

	-- Let other events pass through to default handler
	return false
end

function SWEP:CheckWeaponsAndAmmo()
	if SERVER and IsValid(self.Weapon) and GetConVar("M9KWeaponStrip"):GetBool() then
		if self.Weapon:Clip1() == 0 and self.Owner:GetAmmoCount(self.Weapon:GetPrimaryAmmoType()) == 0 then
			timer.Simple(0.1, function()
				if SERVER and IsValid(self) and IsValid(self.Owner) then
					self.Owner:StripWeapon(self.Gun)
				end
			end)
		end
	end
end

-- Name: SWEP:ShootBulletInformation()
-- Desc: This func adds the damage, the recoil, the number of shots and the cone on the bullet.
function SWEP:ShootBulletInformation()
	local CurrentDamage, CurrentRecoil, CurrentCone

	-- Increment continuous shot counter for progressive spread system (auto mode)
	self.ContinuousShotCount = (self.ContinuousShotCount or 0) + 1

	-- Track rapid fire heat for semi/burst spam detection
	local curTime = CurTime()
	self.LastShotTime = self.LastShotTime or 0
	self.RapidFireHeat = self.RapidFireHeat or 0

	local timeSinceLastShot = curTime - self.LastShotTime
	local rapidFireThreshold = 0.25  -- Shots faster than this are considered "spamming"

	if timeSinceLastShot < rapidFireThreshold then
		-- Rapid fire - increase heat
		self.RapidFireHeat = self.RapidFireHeat + 1
	else
		-- Controlled fire - decay heat based on time elapsed
		-- Decay rate: lose 1 heat per 0.15 seconds of pause
		local heatDecay = math.floor(timeSinceLastShot / 0.15)
		self.RapidFireHeat = math.max(0, self.RapidFireHeat - heatDecay)
	end

	self.LastShotTime = curTime

	-- Use dynamic spread system based on fire mode and ADS state
	CurrentCone = self:GetDynamicSpread()

	local damagedice = math.Rand(0.85, 1.3)
	local basedamage = PainMulti * self.Primary.Damage
	CurrentDamage = basedamage * damagedice
	CurrentRecoil = self.Primary.Recoil

	-- Check ADS state on both CLIENT and SERVER
	local isInADS = false
	if CLIENT then
		isInADS = self.m9kr_IsInADS or false
	elseif SERVER then
		local isReloading = self.Weapon:GetNWBool("Reloading", false)
		local isSafe = self.GetIsOnSafe and self:GetIsOnSafe() or false
		local isOnGround = self.Owner:IsOnGround()
		local isSprintJumping = self.Owner:KeyDown(IN_SPEED) and not isOnGround
		local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
		local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and isOnGround and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement

		isInADS = self.Owner:KeyDown(IN_ATTACK2) and
				  not self.Owner:KeyDown(IN_USE) and
				  not isActuallySprinting and
				  not isReloading and
				  not isSafe and
				  not isSprintJumping
	end

	-- Store original kick values for restoration after shooting
	local origKickUp = self.Primary.KickUp
	local origKickDown = self.Primary.KickDown
	local origKickHorizontal = self.Primary.KickHorizontal

	-- Check if player is FULLY crouched on ground (not crouch jumping or transitioning)
	-- Compare current view offset to ducked offset to ensure player is fully ducked
	-- Only check for players - NPCs/nextbots don't have GetViewOffsetDucked()
	local isFullyCrouched = false
	if self.Owner:IsPlayer() and self.Owner:Crouching() and self.Owner:IsOnGround() then
		local currentViewZ = self.Owner:GetViewOffset().z
		local duckedViewZ = self.Owner:GetViewOffsetDucked().z
		-- Allow small tolerance (1 unit) for floating point precision
		isFullyCrouched = (currentViewZ <= duckedViewZ + 1)
	end

	-- Apply crouch modifiers (these stack with ADS modifiers)
	if isFullyCrouched then
		-- Crouch reduces recoil when fully stable on ground
		-- KickUp: 25% reduction (retain 75%)
		-- KickDown: 10% reduction (retain 90%)
		-- KickHorizontal: 10% reduction (retain 90%)
		self.Primary.KickUp = origKickUp * 0.75
		self.Primary.KickDown = origKickDown * 0.90
		self.Primary.KickHorizontal = origKickHorizontal * 0.90
	end

	-- Apply ADS modifiers on top of crouch (if applicable)
	if isInADS and self.Owner:KeyDown(IN_ATTACK2) then
		-- ADS reduces KickDown and KickHorizontal by 75% (retain 25%)
		-- KickUp stays at crouch value (or original if not crouched)
		-- These multiply with crouch modifiers if both active
		self.Primary.KickDown = self.Primary.KickDown * 0.25
		self.Primary.KickHorizontal = self.Primary.KickHorizontal * 0.25

		-- Fire with reduced recoil (divide by 6 for TFA-style ADS recoil reduction)
		self:ShootBullet(CurrentDamage, CurrentRecoil / 6, self.Primary.NumShots, CurrentCone)
	-- Player is not aiming
	else
		if IsValid(self) and IsValid(self.Weapon) and IsValid(self.Owner) then
			self:ShootBullet(CurrentDamage, CurrentRecoil, self.Primary.NumShots, CurrentCone)
		end
	end

	-- Restore original kick values immediately after shooting
	self.Primary.KickUp = origKickUp
	self.Primary.KickDown = origKickDown
	self.Primary.KickHorizontal = origKickHorizontal

end
 
/*---------------------------------------------------------
   Name: SWEP:ShootBullet()
   Desc: A convenience func to shoot bullets.
-----------------------------------------------------*/
function SWEP:ShootBullet(damage, recoil, num_bullets, aimcone)

	num_bullets             = num_bullets or 1
	aimcone                         = aimcone or 0

	self:ShootEffects()

	-- Increment shot counter for tracer frequency calculation
	self.ShotCount = (self.ShotCount or 0) + 1

	-- Use M9K:R dynamic tracer system
	local shouldShowTracer = false
	local tracerName = "Tracer"
	local tracerType = 0
	local tracerData = nil

	-- Disable tracers for shotgun pellets (buckshot), keep for slugs (single projectile)
	-- Also disable if weapon has NoTracers = true (for bows, crossbows, etc.)
	local isShotgunPellets = (num_bullets > 1)

	if M9KR and M9KR.Tracers and M9KR.Tracers.ShouldShowTracer and not isShotgunPellets and not self.NoTracers then
		shouldShowTracer, tracerName = M9KR.Tracers.ShouldShowTracer(self, self.ShotCount)

		-- Get tracer visual type from ballistics database
		tracerData = M9KR.Tracers.GetTracerDataFromShell(self.ShellModel)
		tracerType = tracerData and tracerData.tracerType or 0
	end

	local bullet = {}
		bullet.Num              = num_bullets
		bullet.Src              = self.Owner:GetShootPos()                      -- Source
		bullet.Dir              = self.Owner:GetAimVector()                     -- Dir of bullet
		bullet.Spread   = Vector(aimcone, aimcone, 0)                   -- Aim Cone
		bullet.Tracer   = 0                                                     -- Disable HL2 tracers
		bullet.TracerName = ""                                                  -- Use m9kr_tracer effect instead
		bullet.Force    = damage * 0.25                                 -- Amount of force to give to phys objects
		bullet.Damage   = damage
		bullet.Callback = function(attacker, tracedata, dmginfo)
		-- Spawn M9K:R tracer based on frequency
		if shouldShowTracer and M9KR and M9KR.Tracers and M9KR.Tracers.SpawnTracerEffect then
			M9KR.Tracers.SpawnTracerEffect(self, tracedata.HitPos, tracerData)

		end

		-- Spawn bullet impact effects (CLIENT only, prediction check)
		-- Skip if DisableBulletImpacts is true (for high-RPM weapons like minigun)
		if CLIENT and IsFirstTimePredicted() and tracedata.HitPos and not self.DisableBulletImpacts then
			local impactCvar = GetConVar("m9kr_bullet_impact")
			local metalCvar = GetConVar("m9kr_metal_impact")
			local dustCvar = GetConVar("m9kr_dust_impact")

			if impactCvar and impactCvar:GetInt() == 1 then
				local fx = EffectData()
				fx:SetOrigin(tracedata.HitPos)
				fx:SetNormal(tracedata.HitNormal or Vector(0, 0, 1))

				-- Material-specific effects
				local effectName = nil
				if tracedata.MatType == MAT_METAL and metalCvar and metalCvar:GetInt() == 1 then
					effectName = "m9kr_metal_impact"
				elseif (tracedata.MatType == MAT_DIRT or tracedata.MatType == MAT_SAND or
				        tracedata.MatType == MAT_CONCRETE or tracedata.MatType == MAT_TILE) and
				       dustCvar and dustCvar:GetInt() == 1 then
					effectName = "m9kr_dust_impact"
				else
					effectName = "m9kr_bullet_impact"
				end

				if effectName then
					util.Effect(effectName, fx)
				end
			end
		end

		-- Route to new modular penetration system
		if self.Penetration and IsFirstTimePredicted() then
			-- Construct paininfo table from dmginfo object
			local paininfo = {
				Damage = dmginfo:GetDamage(),
				Force = dmginfo:GetDamageForce()
			}
			self:BulletPenetrate(0, attacker, tracedata, paininfo)
		end

		-- Arrow impact: spawn arrow at hit point for non-penetrating weapons
		if not self.Penetration and SERVER and self.FireArrows then
			self:SpawnImpactArrow({
				pos = tracedata.HitPos,
				dir = tracedata.Normal,
				ent = tracedata.Entity
			})
		end

		return {damage = true, effects = true}
	end

	if IsValid(self) then
		if IsValid(self.Weapon) then
			if IsValid(self.Owner) then
			self.Owner:FireBullets(bullet)
			end
		end
	end

	-- Calculate base recoil angles
	local kickPitch = math.Rand(-self.Primary.KickDown, -self.Primary.KickUp)
	local kickYaw = math.Rand(-self.Primary.KickHorizontal, self.Primary.KickHorizontal)

	-- Apply recoil to camera using ViewPunch (visual screen shake) - players only
	local anglo1 = Angle(kickPitch, kickYaw, 0)
	if self.Owner:IsPlayer() then
		self.Owner:ViewPunch(anglo1)

		-- Track recoil for viewmodel animation scaling (used in CalcView)
		self.ViewPunchP = (self.ViewPunchP or 0) + kickPitch
		self.ViewPunchY = (self.ViewPunchY or 0) + kickYaw

		-- Apply ACTUAL camera recoil immediately (original M9K approach)
		-- This moves the player's aim, not just visual shake
		-- Applied immediately on firing, not in Think() to avoid mouse input conflicts
		local eyes = self.Owner:EyeAngles()
		eyes.pitch = math.Clamp(eyes.pitch + kickPitch, -89, 89)  -- Clamp to prevent overflow
		eyes.yaw = eyes.yaw + kickYaw
		self.Owner:SetEyeAngles(eyes)
	end
end

/*---------------------------------------------------------
   Name: SWEP:SpawnImpactArrow()
   Desc: Spawns a visual arrow prop at the final bullet
         impact point. Used by weapons with SWEP.FireArrows = true.
-----------------------------------------------------*/
function SWEP:SpawnImpactArrow(hitData)
	if not hitData or not hitData.pos then return end

	local arrow = ents.Create("prop_dynamic")
	if not IsValid(arrow) then return end

	arrow:SetModel("models/viper/mw/attachments/crossbow/attachment_vm_sn_crossbow_mag.mdl")

	-- Position arrow so the tip is embedded and the shaft sticks out
	local dir = hitData.dir or Vector(0, 0, 0)
	arrow:SetPos(hitData.pos - dir * 6)
	arrow:SetAngles(dir:Angle())

	arrow:Spawn()
	arrow:Activate()

	arrow:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

	-- Stick to entities so the arrow follows them (ragdolls, NPCs, etc.)
	if IsValid(hitData.ent) and hitData.ent:GetClass() != "worldspawn" then
		arrow:SetParent(hitData.ent)
	end

	SafeRemoveEntityDelayed(arrow, 10)
end

/*---------------------------------------------------------
   Name: SWEP:BulletPenetrate()
   Desc: Routes to modular penetration system in lua/autorun/m9kr_penetration.lua
         ConVar: m9kr_penetration_mode
         0 = Disabled, 1 = Dynamic (ballistics-based), 2 = Vanilla (original M9K)
-----------------------------------------------------*/
function SWEP:BulletPenetrate(bouncenum, attacker, tr, paininfo)
	-- Route to modular penetration system (protected)
	local res = false
	if M9KR and M9KR.Penetration and M9KR.Penetration.CalculatePenetration then
		local ok, penResult = pcall(M9KR.Penetration.CalculatePenetration, self, bouncenum, attacker, tr, paininfo)
		if not ok then
			res = false
		else
			res = penResult
		end
	end

	-- Arrow impact: when bullet stops (penetration returns false), spawn arrow at this point
	if not res and SERVER and self.FireArrows and tr then
		self:SpawnImpactArrow({
			pos = tr.HitPos,
			dir = tr.Normal,
			ent = tr.Entity
		})
	end

	return res
end
 
function SWEP:SecondaryAttack()
	return false
end
 
function SWEP:Reload()
	if not IsValid(self) or not IsValid(self.Owner) then
		return
	end

	-- Prevent reloading if safety is engaged or USE is held (USE + RELOAD = fire mode toggle)
	if self:GetIsOnSafe() or self.Owner:KeyDown(IN_USE) then
		return
	end

	-- Prevent reload from triggering right after safety toggle or fire mode switch
	-- This fixes the issue where releasing USE + R could trigger a reload
	if self.NextSafetyToggle and CurTime() < self.NextSafetyToggle then
		return
	end
	if self.NextFireSelect and CurTime() < self.NextFireSelect then
		return
	end

	-- Prevent reload spam - don't allow reloading if already reloading
	if self.Weapon:GetNWBool("Reloading") then
		return
	end

	self.BurstShotsRemaining = nil

	-- Reset tracer shot counter on reload (fresh magazine = reset tracer pattern)
	self.ShotCount = 0
	
	if self.Owner:IsNPC() then
		self.Weapon:DefaultReload(ACT_VM_RELOAD)
		return
	end
	
	if self.Owner:KeyDown(IN_USE) then
		return
	end
	
	-- Chamber system: Handle +1 reload mechanic
	local currentClip = self:Clip1()
	local maxClip = self.Primary.ClipSize
	local reserveAmmo = self.Owner:GetAmmoCount(self.Weapon:GetPrimaryAmmoType())
	local isEmpty = currentClip == 0
	
	-- Don't reload if already at max capacity (including chamber)
	if self.HasChamber and not self.noChamber then
		if currentClip >= maxClip + 1 then
			return
		end
		-- Allow reload if magazine is full (maxClip) but we don't have the +1 yet
		-- This enables tactical reload from full magazine to get chamber round
	else
		if currentClip >= maxClip then
			return
		end
	end
	
	-- Don't reload if no reserve ammo
	if reserveAmmo <= 0 then
		return
	end
	
	-- Determine which reload animation to use
	local reloadAct = ACT_VM_RELOAD
	
	if self.Silenced then
		if isEmpty then
			-- Try to use idle reload animation for silenced empty reload
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				local emptySeq = vm:SelectWeightedSequence(ACT_VM_RELOAD_IDLE)
				if emptySeq and emptySeq > 0 then
					reloadAct = ACT_VM_RELOAD_IDLE
				else
					reloadAct = ACT_VM_RELOAD_SILENCED
				end
			else
				reloadAct = ACT_VM_RELOAD_SILENCED
			end
		else
			reloadAct = ACT_VM_RELOAD_SILENCED
		end
	elseif isEmpty then
		-- Try to use empty reload animation if available
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			local emptySeq = vm:SelectWeightedSequence(ACT_VM_RELOAD_EMPTY)
			if emptySeq and emptySeq > 0 then
				reloadAct = ACT_VM_RELOAD_EMPTY
			end
		end
	else
		-- Tactical reload (not empty) - use standard ACT_VM_RELOAD
		reloadAct = ACT_VM_RELOAD
	end
	
	-- Special case: Tactical +1 reload when magazine is already full (skip for revolvers)
	if self.HasChamber and currentClip == maxClip and reserveAmmo > 0 and not self.noChamber then
		-- Magazine is full (30/30), need to manually play reload animation for +1
		self:SendWeaponAnim(reloadAct)

		-- Apply reload speed modifier to animation playback
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) and self.ReloadSpeedModifier then
			vm:SetPlaybackRate(self.ReloadSpeedModifier)
		end

		self:SetNextPrimaryFire(CurTime() + (self:SequenceDuration() / (self.ReloadSpeedModifier or 1)) + 0.1)
		self.ChamberRound = true

		-- Set reload state
		self.Weapon:SetNWBool("Reloading", true)

		-- Show reload animation to other players
		self.Owner:SetAnimation(PLAYER_RELOAD)

		if not self.Owner:IsNPC() then
			if IsValid(self.Owner:GetViewModel()) then
				self.ResetSights = CurTime() + (self.Owner:GetViewModel():SequenceDuration() / (self.ReloadSpeedModifier or 1))
			else
				self.ResetSights = CurTime() + 3
			end
		end

		-- FOV managed by UpdateWeaponInputState/CalcView
		self:SetIronsights(false)

		-- Handle the +1 ammo after animation completes
		local waitdammit = self.Owner:GetViewModel():SequenceDuration() / (self.ReloadSpeedModifier or 1)
		local reloadTimerName = "M9K_Reload_" .. self:EntIndex()
		timer.Create(reloadTimerName, waitdammit + 0.1, 1, function()
			if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end
			
			-- Add the +1 chamber round (skip for revolvers - no chamber)
			local currentAmmo = self.Weapon:Clip1()
			local reserve = self.Owner:GetAmmoCount(self.Weapon:GetPrimaryAmmoType())
			if reserve > 0 and currentAmmo == maxClip and not self.noChamber then
				self.Weapon:SetClip1(maxClip + 1)
				self.Owner:SetAmmo(reserve - 1, self.Weapon:GetPrimaryAmmoType())
			end

			self.Weapon:SetNWBool("Reloading", false)

			-- Send weapon back to idle animation after reload completes
			if self.Silenced then
				self.Weapon:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
			else
				self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
			end
		end)
		
		return
	end
	
	-- Manual reload handling (instead of DefaultReload to control timing)
	self:SendWeaponAnim(reloadAct)

	-- Apply reload speed modifier to animation playback
	local vm = self.Owner:GetViewModel()
	if IsValid(vm) and self.ReloadSpeedModifier then
		vm:SetPlaybackRate(self.ReloadSpeedModifier)
	end

	self:SetNextPrimaryFire(CurTime() + (self:SequenceDuration() / (self.ReloadSpeedModifier or 1)) + 0.1)

	-- Chamber mechanics: Mark whether we should add +1 after animation completes
	if self.HasChamber and not isEmpty then
		-- Tactical reload: will get +1 chamber round after animation
		self.ChamberRound = true
	elseif self.HasChamber and isEmpty then
		-- Empty reload: NO +1 for empty reload
		self.ChamberRound = false
	else
		-- Chamber system disabled
		if self.HasChamber then
			self.ChamberRound = false
		end
	end
	
	if not self.Owner:IsNPC() then
		if IsValid(self.Owner:GetViewModel()) then
			self.ResetSights = CurTime() + (self.Owner:GetViewModel():SequenceDuration() / (self.ReloadSpeedModifier or 1))
		else
			self.ResetSights = CurTime() + 3
		end
	end

	if SERVER and IsValid(self.Weapon) then
		if self.Weapon:Clip1() < self.Primary.ClipSize and not self.Owner:IsNPC() then
			-- When the current clip < full clip and the rest of your ammo > 0, then
			-- FOV managed by UpdateWeaponInputState/CalcView
			-- Zoom = 0
			self:SetIronsights(false)
			-- Set the ironsight to false
			self.Weapon:SetNWBool("Reloading", true)

			-- Show reload animation to other players
			self.Owner:SetAnimation(PLAYER_RELOAD)
		end

		local waitdammit = self.Owner:GetViewModel():SequenceDuration() / (self.ReloadSpeedModifier or 1)
		local reloadTimerName = "M9K_Reload_" .. self:EntIndex()
		timer.Create(reloadTimerName, waitdammit + 0.1, 1, function()
			if not IsValid(self.Weapon) or not IsValid(self.Owner) then
				return
			end
			
			-- Chamber system: Handle all ammo distribution after reload animation completes
			local currentClip = self.Weapon:Clip1()
			local maxClip = self.Primary.ClipSize
			local reserveAmmo = self.Owner:GetAmmoCount(self.Weapon:GetPrimaryAmmoType())
			
			-- Calculate how much ammo we need
			local ammoNeeded = maxClip - currentClip

			-- Add chamber round for tactical reloads (skip for revolvers)
			if self.HasChamber and self.ChamberRound and not self.noChamber then
				ammoNeeded = ammoNeeded + 1  -- Need one extra for chamber
			end
			
			-- Take from reserve and fill magazine + chamber simultaneously
			if reserveAmmo > 0 and ammoNeeded > 0 then
				local ammoToTake = math.min(ammoNeeded, reserveAmmo)
				local newClip = currentClip + ammoToTake
				
				self.Weapon:SetClip1(newClip)
				self.Owner:SetAmmo(reserveAmmo - ammoToTake, self.Weapon:GetPrimaryAmmoType())
			end
			
			self.Weapon:SetNWBool("Reloading", false)

			-- Send weapon back to idle animation after reload completes
			if self.Silenced then
				self.Weapon:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
			else
				self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
			end

			-- Check if player wants to sprint/ADS after reload
			if self.Owner:KeyDown(IN_SPEED) and self.Weapon:GetClass() == self.Gun then
				if SERVER then
					if self.Weapon:GetNextPrimaryFire() <= (CurTime() + 0.03) then
						self.Weapon:SetNextPrimaryFire(CurTime() + 0.3)
					end
					-- FOV managed by UpdateWeaponInputState/CalcView
					self:SetIronsights(false)
					
					-- Delay sprint transition for smoother feel
					-- Gun goes to idle first, then transitions to sprint after 0.35 seconds
					-- This gives enough time for the viewmodel to settle before entering sprint
					-- Mark that we're in post-reload transition to prevent lateral tilt issues
					self.Weapon:SetNWFloat("PostReloadTransition", CurTime() + 0.35)
					
					local sprintTimerName = "M9K_ReloadSprint_" .. self:EntIndex()
					timer.Create(sprintTimerName, 0.35, 1, function()
						if IsValid(self.Weapon) and IsValid(self.Owner) then
							-- Only enter sprint if player is actually sprinting (moving while holding sprint key AND pressing movement keys)
							local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
							local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement
							if isActuallySprinting and not self.Weapon:GetNWBool("Reloading") then
								-- Reset viewmodel position tracking to ensure clean transition
								self.IronSightsPos = self.RunSightsPos
								self.IronSightsAng = self.RunSightsAng
								self:SetSprint(true)
							end
						end
					end)
				end
			elseif self.Owner:KeyDown(IN_ATTACK2) and not self.Owner:KeyDown(IN_SPEED) and self.Weapon:GetClass() == self.Gun then
				if CLIENT then
					return
				end
				if self.Scoped == false then
					-- FOV managed by UpdateWeaponInputState/CalcView
					self:SetSprint(false)
					self:SetIronsights(true, self.Owner)
				else
					return
				end
			else
				if SERVER then
					-- FOV managed by UpdateWeaponInputState/CalcView
					self:SetIronsights(false, self.Owner)
					self:SetSprint(false)
				end
			end
		end)
	end
end
 
function SWEP:PostReloadScopeCheck()
		if self.Weapon == nil then return end
		self.Weapon:SetNWBool("Reloading", false)
		if self.Owner:KeyDown(IN_ATTACK2) and self.Weapon:GetClass() == self.Gun then
				if CLIENT then return end
				if self.Scoped == false then
						-- FOV managed by UpdateWeaponInputState/CalcView
						self:SetSprint(false)
						self:SetIronsights(true, self.Owner)
						self.DrawCrosshair = false
				else return end
		elseif self.Owner:KeyDown(IN_SPEED) and self.Owner:GetVelocity():Length2D() > 20 and self.Weapon:GetClass() == self.Gun then
				-- Only enter sprint animation if player is actually moving
				if self.Weapon:GetNextPrimaryFire() <= (CurTime() + .03) then
						self.Weapon:SetNextPrimaryFire(CurTime()+0.3)
				end
				-- FOV managed by UpdateWeaponInputState/CalcView
				self:SetIronsights(false)
				self:SetSprint(true)
		else return end
end
 
--[[
	Suppressor Attachment/Detachment System with Animation and Hold Type Management

	FEATURES:
	- Weapon goes into PASSIVE hold type during attachment/detachment animation
	- ATTACHING: Suppressor is NOT visible until animation completes
	- DETACHING: Suppressor STAYS visible until animation completes
	- After animation completes, weapon returns to normal hold type
	- Fully networked (CLIENT and SERVER) for multiplayer visibility

	ATTACHMENT FLOW:
	1. Player presses USE + ATTACK2 (suppressor currently OFF)
	2. Weapon immediately switches to PASSIVE hold type (lowers gun)
	3. ATTACH animation plays on viewmodel
	4. IsAttachingSuppressor = true (hides suppressor on world model)
	5. After animation completes:
	   - Hold type restores to original (gun comes back up)
	   - IsAttachingSuppressor = false
	   - Suppressor becomes visible on world model

	DETACHMENT FLOW:
	1. Player presses USE + ATTACK2 (suppressor currently ON)
	2. Weapon immediately switches to PASSIVE hold type (lowers gun)
	3. DETACH animation plays on viewmodel
	4. IsDetachingSuppressor = true (keeps suppressor visible on world model)
	5. After animation completes:
	   - Hold type restores to original (gun comes back up)
	   - IsDetachingSuppressor = false
	   - Suppressor disappears from world model
]]--
function SWEP:Silencer()
	if self.NextSilence > CurTime() then return end

	if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end

	-- Exit iron sights for attachment animation
	-- FOV managed by UpdateWeaponInputState/CalcView
	self:SetIronsights(false)

	-- Store original hold type before changing to passive
	if not self.OriginalHoldType then
		self.OriginalHoldType = self.HoldType or "ar2"
	end

	-- Determine new suppressor state (toggling)
	local isAttaching = not self.Silenced

	-- STEP 1: Change hold type to PASSIVE (lowers gun)
	self:SetHoldType("passive")

	-- STEP 2: Play attachment/detachment animation and set animation flags
	if isAttaching then
		-- ATTACHING SUPPRESSOR
		self:SendWeaponAnim(ACT_VM_ATTACH_SILENCER)
		self.Silenced = true
		self:SetIsSuppressed(true)  -- Network suppressor state (will be visible after animation)

		-- Set ATTACH animation flag (hides suppressor during animation)
		self:SetIsAttachingSuppressor(true)
		self:SetIsDetachingSuppressor(false)
	else
		-- DETACHING SUPPRESSOR
		self:SendWeaponAnim(ACT_VM_DETACH_SILENCER)
		self.Silenced = false
		self:SetIsSuppressed(false)  -- Network suppressor state (will be hidden after animation)

		-- Set DETACH animation flag (keeps suppressor visible during animation)
		self:SetIsAttachingSuppressor(false)
		self:SetIsDetachingSuppressor(true)
	end

	-- Calculate animation duration
	local animDuration = self.Owner:GetViewModel():SequenceDuration() + 0.1
	local animEndTime = CurTime() + animDuration

	-- Store animation end time for networked sync
	self:SetSuppressorAnimEndTime(animEndTime)

	-- Prevent firing during animation
	if self.Weapon:GetNextPrimaryFire() <= animEndTime then
		self.Weapon:SetNextPrimaryFire(animEndTime)
	end
	self.NextSilence = animEndTime

	-- STEP 3: Update world model based on animation state
	-- - ATTACH: Will hide suppressor (IsAttachingSuppressor = true)
	-- - DETACH: Will keep suppressor visible (IsDetachingSuppressor = true)
	self:UpdateWorldModel()

	-- STEP 4: Create timer to complete animation
	local silencerTimerName = "M9K_Silencer_" .. self:EntIndex()
	timer.Create(silencerTimerName, animDuration, 1, function()
		if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end

		-- Animation complete - restore hold type (gun comes back up)
		self:SetHoldType(self.OriginalHoldType or self.HoldType)

		-- Clear animation flags
		self:SetIsAttachingSuppressor(false)
		self:SetIsDetachingSuppressor(false)

		-- Update world model to show final state
		-- - If was ATTACHING: Suppressor now becomes visible
		-- - If was DETACHING: Suppressor now disappears
		self:UpdateWorldModel()

		-- Handle player input after animation completes
		if self.Owner:KeyDown(IN_ATTACK2) and self.Weapon:GetClass() == self.Gun then
			if CLIENT then return end
			if self.Scoped == false then
				-- FOV managed by UpdateWeaponInputState/CalcView
				self:SetSprint(false)
				self:SetIronsights(true, self.Owner)
				self.DrawCrosshair = false
			end
		elseif self.Owner:KeyDown(IN_SPEED) and self.Owner:GetVelocity():Length2D() > 20 and self.Weapon:GetClass() == self.Gun then
			-- Only enter sprint animation if player is actually moving
			if self.Weapon:GetNextPrimaryFire() <= (CurTime() + 0.3) then
				self.Weapon:SetNextPrimaryFire(CurTime() + 0.3)
			end
			-- FOV managed by UpdateWeaponInputState/CalcView
			self:SetIronsights(false)
			self:SetSprint(true)
		end
	end)
end
 
--[[
	Safety Toggle System

	Toggles weapon safety on/off using USE + ATTACK (fire button)

	SAFE MODE BEHAVIOR:
	- Weapon switches to PASSIVE hold type (lowered position)
	- Viewmodel uses RunSightsPos and RunSightsAng positioning
	- Cannot shoot, change fire modes, attach/detach suppressor, or scope
	- HUD displays "SAFE" in red
	- Crosshair is hidden

	HOT STATUS BEHAVIOR:
	- Weapon restores normal hold type
	- Normal viewmodel positioning
	- All weapon functions enabled
]]--
function SWEP:SafetyToggle()
	if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end

	-- Cooldown check (prevent spamming) - increased to 0.6s
	if self.NextSafetyToggle > CurTime() then return end
	self.NextSafetyToggle = CurTime() + 0.6

	-- SERVER: Toggle safety state and handle game logic
	if SERVER then
		local newSafetyState = not self:GetIsOnSafe()
		self:SetIsOnSafe(newSafetyState)

		if newSafetyState then
			-- ENGAGING SAFETY - force exit ADS/sprint
			self:SetIronsights(false)
			self:SetSprint(false)
		else
			-- DISENGAGING SAFETY - add firing delay (slightly longer than reload)
			self:SetNextPrimaryFire(CurTime() + 0.5)
		end
	end

	-- CLIENT: Handle visual/audio feedback
	if CLIENT then
		local newSafetyState = not self:GetIsOnSafe()

		-- Play AR2 empty sound (same as fire mode switching)
		self.Weapon:EmitSound("Weapon_AR2.Empty")

		-- Exit ADS/sprint visually
		-- FOV managed by UpdateWeaponInputState/CalcView
		self:SetIronsights(false)
		self:SetSprint(false)

		if newSafetyState then
			-- Hide crosshair
			self.DrawCrosshair = false

			-- Start safety transition timing (for smooth viewmodel animation)
			self.fSafetyTime = CurTime()
			self.bLastSafety = true
		else
			-- Disengage safety - start idle transition
			self.fIdleTime = CurTime()
			self.bLastSafety = false

			-- Restore normal crosshair
			self.DrawCrosshair = self.OrigCrossHair
		end
	end
end

--[[
	SafetyOn - Enter safety mode (SHIFT + E + R)
	Saves the current fire mode before entering safety
]]--
function SWEP:SafetyOn()
	if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end
	if self:GetIsOnSafe() then return end  -- Already in safety

	-- Cooldown check
	if self.NextSafetyToggle > CurTime() then return end
	self.NextSafetyToggle = CurTime() + 0.6

	-- Save current fire mode before entering safety
	self.FireModeBeforeSafety = self.CurrentFireMode or 1

	-- SERVER: Enable safety
	if SERVER then
		self:SetIsOnSafe(true)
		self:SetIronsights(false)
		self:SetSprint(false)
	end

	-- CLIENT: Visual/audio feedback
	if CLIENT then
		self.Weapon:EmitSound("Weapon_AR2.Empty")
		self:SetIronsights(false)
		self:SetSprint(false)
		self.DrawCrosshair = false
		self.fSafetyTime = CurTime()
		self.bLastSafety = true
		-- Skip fire mode switch animation when entering safety
		self.SafetyToggleTime = CurTime()
	end
end

--[[
	SafetyOff - Exit safety mode (E + R when in safety)
	Restores the fire mode that was active before entering safety
]]--
function SWEP:SafetyOff()
	if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end
	if not self:GetIsOnSafe() then return end  -- Not in safety

	-- Cooldown check
	if self.NextSafetyToggle > CurTime() then return end
	self.NextSafetyToggle = CurTime() + 0.6

	-- SERVER: Disable safety and restore fire mode
	if SERVER then
		self:SetIsOnSafe(false)
		self:SetNextPrimaryFire(CurTime() + 0.5)

		-- Restore saved fire mode
		if self.FireModeBeforeSafety and self.FireModes then
			local modeCount = self:GetFireModeCount()
			if self.FireModeBeforeSafety >= 1 and self.FireModeBeforeSafety <= modeCount then
				self.CurrentFireMode = self.FireModeBeforeSafety
				self.Weapon:SetNWInt("CurrentFireMode", self.CurrentFireMode)

				-- Update Primary.Automatic
				local mode = self:GetCurrentFireMode()
				self.Primary.Automatic = (mode == "auto")
			end
		end
	end

	-- Block immediate fire mode cycling after exiting safety
	self.NextFireSelect = CurTime() + 0.5

	-- CLIENT: Visual/audio feedback
	if CLIENT then
		self.Weapon:EmitSound("Weapon_AR2.Empty")
		self.fIdleTime = CurTime()
		self.bLastSafety = false
		self.DrawCrosshair = self.OrigCrossHair
		-- Skip fire mode switch animation when exiting safety
		self.SafetyToggleTime = CurTime()
	end
end

function SWEP:SelectFireMode()
	if self.NextFireSelect and CurTime() < self.NextFireSelect then return end
	self.NextFireSelect = CurTime() + 0.5

	-- Single-mode weapons: no cycling, no sound
	if self:GetFireModeCount() <= 1 then return end

	-- Cycle to the next fire mode
	self:CycleFireMode()

	-- Play selection sound
	self:EmitSound("Weapon_AR2.Empty")
end
 
-- ADS sounds, FOV transitions, UpdateWeaponInputState, M9KR_StartFOVTransition, M9KR_GetADSTargetFOV are in cl_init.lua

-- CalcView is in cl_init.lua

-- IronSight
--[[
IronSight - Simplified gun_base variant
This function handles SERVER-side game logic and CLIENT-side animation state
]]
function SWEP:IronSight()
	if not IsValid(self) or not IsValid(self.Owner) then
		return
	end

	if not self.Owner:IsNPC() then
		if self.ResetSights and CurTime() >= self.ResetSights then
			self.ResetSights = nil

			-- Clear reloading flag on CLIENT to prevent stale NWBool from blocking
			-- the next reload attempt. The SERVER timer clears this 0.1s later
			-- authoritatively, but the CLIENT needs it cleared now so that predicted
			-- Reload() calls can proceed and display the animation correctly.
			if CLIENT then
				self.Weapon:SetNWBool("Reloading", false)
			end

			if self.Silenced then
				self:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
			else
				self:SendWeaponAnim(ACT_VM_IDLE)
			end
		end
	end

	-- Safety and fire mode controls (SERVER only):
	-- SHIFT + E + R = Enter safety mode
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

	-- CLIENT: Detect safety state changes and play sound
	if CLIENT then
		local currentSafety = self:GetIsOnSafe()
		if self.LastSafetyState == nil then
			self.LastSafetyState = currentSafety
		elseif self.LastSafetyState ~= currentSafety then
			-- Safety state changed, play sound and update visual state
			self.Weapon:EmitSound("Weapon_AR2.Empty")
			self.SafetyToggleTime = CurTime()
			self.bLastSafety = currentSafety
			if currentSafety then
				self.DrawCrosshair = false
			else
				self.DrawCrosshair = self.OrigCrossHair
			end
			self.LastSafetyState = currentSafety
		end
	end

	-- Suppressor attachment/detachment (blocked when safety is on or reloading)
	if not self:GetIsOnSafe() and self.CanBeSilenced and self.NextSilence < CurTime() and not self.Weapon:GetNWBool("Reloading") then
		if self.Owner:KeyDown(IN_USE) and self.Owner:KeyPressed(IN_ATTACK2) then
			self:Silencer()
		end
	end

	-- BobScale/SwayScale management - reduced when in ADS
	-- Check CLIENT-side ADS state from UpdateWeaponInputState
	local isInADS = CLIENT and (self.m9kr_IsInADS or false) or false

	if isInADS and self.Owner:KeyDown(IN_ATTACK2) and not self.Owner:KeyDown(IN_USE) and not self:GetIsOnSafe() and not self.Owner:KeyDown(IN_SPEED) then
		self.SwayScale = 0.05
		self.BobScale = 0.05
	else
		self.SwayScale = 1.0
		self.BobScale = 0.1
	end
end
 
-- UpdateProgressRatios is in cl_init.lua

--[[
	UpdateSafetyHoldType - Enforce hold type based on safety state
	Runs on BOTH client and server. SetHoldType is networked, so server
	changes are visible to all clients automatically.
	Replaces the former global CLIENT Think hook (safety handler)
]]--
function SWEP:UpdateSafetyHoldType()
	if not self.GetIsOnSafe then return end

	local isSafe = self:GetIsOnSafe()

	-- Determine target hold type
	if isSafe then
		-- Safety engaged: use passive/normal depending on weapon type
		local safeHoldType = "passive"
		if self.OriginalHoldType == "pistol" or self.OriginalHoldType == "revolver" then
			safeHoldType = "normal"
		end
		if self.HoldType ~= safeHoldType then
			self:SetHoldType(safeHoldType)
		end
	else
		-- Safety off: restore original hold type
		local targetHoldType = self.OriginalHoldType or "ar2"
		if self.HoldType ~= targetHoldType then
			self:SetHoldType(targetHoldType)
		end
	end

	-- CLIENT: Track transition start time for smooth viewmodel animation
	if CLIENT then
		if self.m9kr_LastSafetyHoldTypeState == nil then
			self.m9kr_LastSafetyHoldTypeState = isSafe
		elseif self.m9kr_LastSafetyHoldTypeState ~= isSafe then
			self.m9kr_SafetyTransitionStart = CurTime()
			self.m9kr_LastSafetyHoldTypeState = isSafe
		end
	end
end

-- GetSafetyTransitionMul, ApplyViewModelBoneMods, and ResetViewModelBones are in cl_init.lua

-- Belt-fed, low ammo, shell ejection, bullet impact, and PreDrawViewModel hook are in cl_init.lua

-- Think
function SWEP:Think()
	-- Critical safety check for weapon state during transitions
	if not IsValid(self) or not IsValid(self.Weapon) then
		return
	end

	-- Check if owner is valid - weapon switching can invalidate this
	if not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return
	end

	-- Reset continuous shot counter when trigger is released (for progressive spread system)
	local triggerDown = self.Owner:KeyDown(IN_ATTACK)
	if self.LastTriggerState and not triggerDown then
		-- Trigger was just released - reset shot counter
		self.ContinuousShotCount = 0
	end
	self.LastTriggerState = triggerDown

	-- CLIENT: Sync Primary.Automatic with SERVER fire mode
	-- CycleFireMode runs SERVER-only, so CLIENT must read the networked fire mode
	-- and update Primary.Automatic to prevent the engine from calling PrimaryAttack
	-- continuously in semi/burst modes (which would cause full-auto behavior)
	if CLIENT and self.FireModes then
		local networkedMode = self.Weapon:GetNWInt("CurrentFireMode", 0)
		if networkedMode > 0 and self.FireModes[networkedMode] then
			self.Primary.Automatic = (self.FireModes[networkedMode] == "auto")
		end
	end

	-- Burst fire: process queued shots via CurTime check (prediction-safe, unlike timers)
	if self.BurstShotsRemaining and self.BurstShotsRemaining > 0 and self.NextBurstShotTime and CurTime() >= self.NextBurstShotTime then
		self:FireBurstShot()
	end

	-- Store viewmodel reference for muzzle flash effects (TFA Base approach)
	if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() then
		self.OwnerViewModel = self.Owner:GetViewModel()

		-- Update weapon input state (ADS, sprint, safety, reload, FOV transitions)
		-- Safe to call multiple times per frame (uses CurTime-based transitions, not deltas)
		self:UpdateWeaponInputState()

		-- Guard FrameTime-based updates against multiple calls per frame
		-- In multiplayer, Think() can run multiple times per frame during prediction,
		-- which would double-advance FrameTime-accumulated values
		local curFrame = FrameNumber()
		if self.m9kr_LastProgressFrame ~= curFrame then
			self.m9kr_LastProgressFrame = curFrame

			-- Update progress values (TFA-style approach - lightweight float lerp only, no heavy logic)
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

		-- Belt-fed weapon display update (bone/bodygroup belt depletion + reload animation)
		self:UpdateBeltAmmo()
	end

	-- TFA-Style Recoil Decay System
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

	-- Smoothly update IronSights progress for recoil interpolation
	local isInADS = CLIENT and (self.m9kr_IsInADS or false) or false
	local targetProgress = isInADS and 1.0 or 0.0
	self.IronSightsProgressSmooth = self.IronSightsProgressSmooth or 0
	if shouldDecayRecoil then
		self.IronSightsProgressSmooth = Lerp(ft * 8, self.IronSightsProgressSmooth, targetProgress)
	end

	-- Decay ViewPunch accumulator over time
	if shouldDecayRecoil and self.ViewPunchP then
		self.ViewPunchP = Lerp(ft * 5, self.ViewPunchP, 0)
	end
	if shouldDecayRecoil and self.ViewPunchY then
		self.ViewPunchY = Lerp(ft * 5, self.ViewPunchY, 0)
	end

	-- Suppressor attachment/detachment animation management
	-- Check if suppressor animation should complete (backup to timer system)
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
	-- Track ground state to detect when player jumps during sprint
	local isOnGround = self.Owner:IsOnGround()
	self.LastGroundState = self.LastGroundState or true

	-- Detect jump event (was on ground, now in air)
	if self.LastGroundState and not isOnGround then
		-- Check if player is sprinting when they jump
		if self:GetSprint() and self.Owner:KeyDown(IN_SPEED) then
			self.SprintJumping = true
			-- Note: We don't play jump animations because they interfere with weapon firing
			-- The SprintJumping flag is sufficient for gameplay (allows shooting during sprint-jump)
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

	-- ADS/Sprint state management is handled by UpdateWeaponInputState (CLIENT)

	-- Safety hold type enforcement (runs on both CLIENT and SERVER)
	self:UpdateSafetyHoldType()

	self:IronSight()
end

/*---------------------------------------------------------
   Name: SWEP:GetDynamicSpread()
   Desc: Calculate spread based on fire mode, ADS state, and continuous fire
   Returns: Spread value (cone of fire)

   Progressive Spread System (ADS only):
   - Semi/Bolt: Perfect accuracy (0 spread)
   - Auto: First 3 shots accurate, then spread increases up to max
   - Burst: Slightly reduced spread throughout
-----------------------------------------------------*/
local HIP_SPREAD = {
	["burst"]  = 0.007,
	["double"] = 0.007,
	["semi"]   = 0.002,
	["bolt"]   = 0.0001,
	["auto"]   = 0.0135,
	["lever"]  = 0.002,
	["single"] = 0.0001,
}

function SWEP:GetDynamicSpread()
	-- Check ADS state on both CLIENT and SERVER
	local isADS = false
	if CLIENT then
		isADS = (self.m9kr_IsInADS or false) and self.Owner:KeyDown(IN_ATTACK2)
	elseif SERVER and IsValid(self.Owner) then
		local isReloading = self.Weapon:GetNWBool("Reloading", false)
		local isSafe = self.GetIsOnSafe and self:GetIsOnSafe() or false
		local isOnGround = self.Owner:IsOnGround()
		local isSprintJumping = self.Owner:KeyDown(IN_SPEED) and not isOnGround
		local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
		local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and isOnGround and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement

		isADS = self.Owner:KeyDown(IN_ATTACK2) and
				not self.Owner:KeyDown(IN_USE) and
				not isActuallySprinting and
				not isReloading and
				not isSafe and
				not isSprintJumping
	end

	-- Shotguns always use their weapon-defined spread values (Primary.Spread / Primary.IronAccuracy)
	-- Check for shotty_base OR weapons with PreserveSpreadValues flag (for magazine-fed shotguns)
	local isShotgun = self.Base == "carby_shotty_base" or self.PreserveSpreadValues
	if isShotgun then
		if isADS and self.Primary.IronAccuracy then
			return self.Primary.IronAccuracy
		elseif self.Primary.Spread then
			return self.Primary.Spread
		end
	end

	-- Get current fire mode
	local currentMode = self:GetCurrentFireMode()

	-- Initialize rapid fire heat tracking (for semi/burst spam detection)
	self.RapidFireHeat = self.RapidFireHeat or 0
	self.LastShotTime = self.LastShotTime or 0

	-- ADS accuracy with progressive spread for all modes
	if isADS then
		-- Initialize continuous shot counter if needed
		self.ContinuousShotCount = self.ContinuousShotCount or 0

		if currentMode == "bolt" then
			-- Bolt action: Perfect accuracy when ADS (can't spam bolt action)
			return 0
		elseif currentMode == "semi" then
			-- Semi-auto: Perfect accuracy for controlled fire, noticeable spread when spamming
			-- Max ADS semi spread: 0.0065 (punishes spam while rewarding controlled fire)
			local heat = self.RapidFireHeat
			if heat <= 2 then
				return 0  -- Controlled fire: perfect accuracy
			else
				-- Gradually increase spread when spamming
				local spreadProgress = math.Clamp((heat - 2) / 8, 0, 1)
				return spreadProgress * 0.0065
			end
		elseif currentMode == "auto" then
			-- Auto: First 3 shots are accurate, then spread increases up to max
			-- Max ADS auto spread: 0.01 (noticeable but still better than hip fire 0.0135)
			local shotCount = self.ContinuousShotCount
			if shotCount <= 3 then
				return 0  -- First 3 shots: perfect accuracy
			else
				-- Gradually increase spread from shot 4 onwards
				-- Reaches max spread around shot 9
				local spreadProgress = math.Clamp((shotCount - 3) / 6, 0, 1)
				return spreadProgress * 0.01
			end
		elseif currentMode == "burst" or currentMode == "double" then
			-- Burst/Double: Spread increases when spamming bursts rapidly
			-- Max ADS burst spread: 0.007 (between semi and auto)
			local heat = self.RapidFireHeat
			if heat <= 1 then
				return 0.001  -- First burst: minimal spread
			else
				-- Gradually increase spread when spamming bursts
				local spreadProgress = math.Clamp((heat - 1) / 5, 0, 1)
				return 0.001 + spreadProgress * 0.006
			end
		end

		-- Fallback for any undefined modes
		return 0
	end

	-- Hip fire - constant spread per fire mode (non-shotguns only)
	return HIP_SPREAD[currentMode] or 0.01
end

-- GetViewModelPosition is in cl_init.lua
 
/*---------------------------------------------------------
SetIronsights
-----------------------------------------------------*/
function SWEP:SetIronsights(b)
	-- NOTE: This function is kept for compatibility with existing weapon code (e.g., bolt action reload)
	-- but the networked variable is NO LONGER USED for visual state.
	-- Visual ADS state is managed by UpdateWeaponInputState CLIENT-side.
	-- ADS sounds are also played there, not here.
	self.Weapon:SetNWBool("M9K_Ironsights", b)
end
 
function SWEP:GetIronsights()
		return self.Weapon:GetNWBool("M9K_Ironsights")
end

/*---------------------------------------------------------
SetSprint - Separate state for sprint mode
-----------------------------------------------------*/
function SWEP:SetSprint(b)
		self.Weapon:SetNWBool("M9K_Sprinting", b)
end

function SWEP:GetSprint()
		return self.Weapon:GetNWBool("M9K_Sprinting")
end

/*---------------------------------------------------------
Fire Mode System - New enum-based helpers
-----------------------------------------------------*/
-- Get the actual count of fire modes without metatable inheritance
function SWEP:GetFireModeCount()
	if not self.FireModes then return 0 end
	
	-- Check the weapon's class definition directly via weapons.GetStored
	local weaponClass = weapons.GetStored(self:GetClass())
	if weaponClass and weaponClass.FireModes then
		-- Count only explicitly defined entries in the weapon class
		local count = 0
		for i = 1, 10 do
			-- Use rawget to avoid metatable lookups
			if rawget(weaponClass.FireModes, i) ~= nil then
				count = count + 1
			else
				break
			end
		end
		return count
	end
	
	-- Fallback: count using rawget on instance
	local count = 0
	for i = 1, 10 do
		if rawget(self.FireModes, i) ~= nil then
			count = count + 1
		else
			break
		end
	end
	return count
end

function SWEP:GetCurrentFireMode()
	if not self.FireModes then
		return nil
	end

	-- On client, read from networked variable to stay in sync with server
	if CLIENT then
		local networkedMode = self.Weapon:GetNWInt("CurrentFireMode", 0)
		if networkedMode > 0 then
			self.CurrentFireMode = networkedMode
		end
	end

	return self.FireModes[self.CurrentFireMode]
end

function SWEP:GetFireModeName()
	local mode = self:GetCurrentFireMode()
	if not mode then return nil end
	return self.FireModeNames[mode] or mode
end

function SWEP:IsFireModeAuto()
	local mode = self:GetCurrentFireMode()
	return mode == "auto"
end

function SWEP:IsFireModeBurst()
	local mode = self:GetCurrentFireMode()
	return mode == "burst" or mode == "double"
end

function SWEP:IsFireModeSemi()
	local mode = self:GetCurrentFireMode()
	return mode == "semi"
end

function SWEP:CycleFireMode()
	local modeCount = self:GetFireModeCount()
	if not self.FireModes or modeCount <= 1 then
		return false
	end

	self.CurrentFireMode = (self.CurrentFireMode % modeCount) + 1
	local mode = self:GetCurrentFireMode()

	-- Network the current fire mode to clients for HUD display
	if SERVER then
		self.Weapon:SetNWInt("CurrentFireMode", self.CurrentFireMode)
	end

	-- Trigger fire mode switch animation (viewmodel manipulation)
	self.FireModeSwitchTime = CurTime()

	-- Update Primary.Automatic for GMod compatibility
	-- GMod's base SWEP system reads this to control auto-fire
	-- Only "auto" mode should have automatic fire, everything else is semi
	self.Primary.Automatic = (mode == "auto")

	return true, mode
end
 
 
-- DrawWorldModel, HUD functions, and table.FullCopy are in cl_init.lua