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
-- Weapons should override this with their specific action sound names
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

-- Low ammo sounds and ADS sounds are now handled by centralized CLIENT files:
-- - lua/m9kr/client/m9kr_low_ammo_warning.lua
-- - lua/m9kr/client/m9kr_weapon_state_handler.lua

-- Animation variables (clientside)
if CLIENT then
	SWEP.AnimationTime = 0 -- Time tracker for animations
	SWEP.BreathIntensity = 0 -- Smooth breath intensity
	SWEP.WalkIntensity = 0 -- Smooth walk intensity
	SWEP.SprintIntensity = 0 -- Smooth sprint intensity
	SWEP.JumpVelocity = 0 -- Vertical velocity for jump tracking
	SWEP.JumpVelocitySmooth = 0 -- Smoothed vertical velocity
	SWEP.LateralVelocity = 0 -- Horizontal velocity for tilt
	SWEP.LateralVelocitySmooth = 0 -- Smoothed lateral velocity
	SWEP.LastGroundState = true -- Track if player was on ground last frame
end
 
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

--[[
	DrawWeaponSelection - Draw weapon icon in weapon selection HUD
	CLIENT-side only. Loads material lazily on first call.
]]--
function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
	if not CLIENT then return end

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

--[[
	Spawn barrel smoke trail using TFA PCF particle system
	Called after firing (0.75s idle) or on reload
	CLIENT-side only as PCF particles are client-rendered
	Controlled by m9kr_muzzlesmoketrail ConVar (0=Disabled, 1=Enabled)
	
	DISABLED - All muzzle smoke effects have been removed
]]--
function SWEP:SpawnBarrelSmoke()
	-- Muzzle smoke completely disabled
	return


end


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
	-- Clean up burst timer when holstering
	local timerName = "M9K_Burst_" .. self:EntIndex()
	if timer.Exists(timerName) then
		timer.Remove(timerName)
	end
	self.BurstShotsRemaining = 0
	
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
		if IsValid(vm) and M9KR and M9KR.ViewModelMods then
			M9KR.ViewModelMods.ResetBonePositions(vm)
		end

		-- Clean up PCF particles when holstering
		if self.CleanParticles then
			self:CleanParticles()
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
		if IsValid(vm) and M9KR and M9KR.ViewModelMods then
			M9KR.ViewModelMods.ResetBonePositions(vm)
		end

		-- Clean up PCF particles when weapon is removed
		if self.CleanParticles then
			self:CleanParticles()
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
	-- Low ammo sound handled by m9kr_low_ammo_warning.lua
	self.Weapon:TakePrimaryAmmo(1)
	
	-- Track shot time for ADS recoil animation and smoke trail timer
	if CLIENT then
		self.LastShotTime = CurTime()

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
	
	-- Effects
	local fx = EffectData()
	fx:SetEntity(self.Weapon)
	fx:SetOrigin(self.Owner:GetShootPos())

	-- Get muzzle direction from worldmodel attachment (for proper third-person alignment)
	local muzzleDir = self.Owner:GetAimVector()  -- Default to aim direction
	local att = self.Weapon:GetAttachment(self.Weapon:LookupAttachment(self.MuzzleAttachment or "1"))
	if att and att.Ang then
		muzzleDir = att.Ang:Forward()  -- Use actual barrel direction from worldmodel
	end

	fx:SetNormal(muzzleDir)
	fx:SetAttachment(self.MuzzleAttachment)

	-- Spawn muzzle flash effect
	if GetConVar("M9KR_MuzzleFlash") ~= nil and GetConVar("M9KR_MuzzleFlash"):GetBool() then
		if CLIENT or (game.SinglePlayer() and SERVER) then
			-- Smart muzzle flash: use silenced effect if weapon is suppressed
			local effectName = self.MuzzleFlashEffect or "m9kr_muzzleflash_rifle"
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

	-- Eject shell casing
	self:EjectShell()

	-- Schedule next burst shot if any remaining
	-- Safety check: BurstShotsRemaining can be nil if weapon was switched mid-burst
	if not self.BurstShotsRemaining then return end
	self.BurstShotsRemaining = self.BurstShotsRemaining - 1
	if self.BurstShotsRemaining > 0 then
		-- Use unique timer name per weapon instance
		local timerName = "M9K_Burst_" .. self:EntIndex()
		timer.Create(timerName, self.BurstDelay or 0.05, 1, function()
			if IsValid(self) then
				self:FireBurstShot()
			end
		end)
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
				-- Low ammo sound handled by m9kr_low_ammo_warning.lua
				self.Weapon:TakePrimaryAmmo(1)

				-- Track shot time for ADS recoil animation and smoke trail timer
				if CLIENT then
					self.LastShotTime = CurTime()

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
				local fx = EffectData()
				fx:SetEntity(self.Weapon)
				fx:SetOrigin(self.Owner:GetShootPos())

				-- Get muzzle direction from worldmodel attachment (for proper third-person alignment)
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
						-- Smart muzzle flash: use silenced effect if weapon is suppressed
						local effectName = self.MuzzleFlashEffect or "m9kr_muzzleflash_rifle"
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
			
				-- Eject shell casing
				self:EjectShell()

				-- Schedule remaining burst shots using named timer per weapon instance
				if self.BurstShotsRemaining > 0 then
					local timerName = "M9K_Burst_" .. self:EntIndex()
					timer.Create(timerName, self.BurstDelay or 0.05, 1, function()
						if IsValid(self) then
							self:FireBurstShot()
						end
					end)
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

				-- Low ammo sound handled by m9kr_low_ammo_warning.lua

				self.Weapon:TakePrimaryAmmo(1)
				
				-- Mark that we fired from the chamber
				if self.HasChamber and self.Weapon:Clip1() > 0 then
					self.ChamberRound = true
				elseif self.Weapon:Clip1() == 0 then
					self.ChamberRound = false
				end
				
			-- Track shot time for ADS recoil animation and smoke trail timer
			if CLIENT then
				self.LastShotTime = CurTime()

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
				local fx = EffectData()
				fx:SetEntity(self.Weapon)
				fx:SetOrigin(self.Owner:GetShootPos())

				-- Get muzzle direction from worldmodel attachment (for proper third-person alignment)
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
						-- Smart muzzle flash: use silenced effect if weapon is suppressed
						local effectName = self.MuzzleFlashEffect or "m9kr_muzzleflash_rifle"
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

				-- Eject shell casing
				self:EjectShell()

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
	Shell Ejection System
	Ejects physical shell casing models from the weapon's shell eject attachment

	NOTE: Shell collision sounds are handled by m9kr_shell_ejection.lua and m9kr_shell effect.
	No need for duplicate sound tables in weapon base.
]]
function SWEP:EjectShell(attachmentId, velocity)
	-- Skip shell ejection for caseless ammunition weapons
	if self.NoShellEject then return end
	if not CLIENT then return end
	if not IsValid(self) or not IsValid(self.Owner) then return end
	if not self.ShellModel then return end

	-- Only spawn viewmodel shells for the local player
	if self.Owner ~= LocalPlayer() then return end

	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then return end

	-- Delegate to M9KR shell ejection system (handles physics, smoke trails, collision sounds, cleanup)
	M9KR.ShellEjection.SpawnShell(self, vm, attachmentId)
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
	if event == 21 or event == 22 or event == 5001 or event == 5011 or event == 5021 or event == 6001 then return true end

	-- Block all EjectBrass events from weapon model QCs
	-- Event 20 = Brass ejection event in GMod/Source Engine
	if event == 20 then
		-- Check if this is a brass ejection effect
		local optStr = tostring(options or "")
		if string.find(optStr, "EjectBrass") then
			if CLIENT then
				-- Parse QC parameters to cache the correct shell eject attachment
				-- Format: "EjectBrass_556 2 110" → <effect_name> <attachment_id> <velocity>
				local parts = {}
				for part in string.gmatch(optStr, "%S+") do
					table.insert(parts, part)
				end

				-- Cache the QC attachment ID so EjectShell() uses the correct position
				-- This auto-detects the shell eject attachment from the viewmodel's animation data
				if parts[2] then
					self._qcShellAttachment = tonumber(parts[2])
				end
			end
			return true -- Block default Source Engine brass (EjectShell is called from firing code)
		end
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
	if CLIENT and M9KR and M9KR.WeaponState and M9KR.WeaponState.GetVisualState then
		-- CLIENT: Use visual state for smooth transitions
		isInADS = M9KR.WeaponState.GetVisualState(self)
	elseif SERVER then
		-- SERVER: Directly detect ADS conditions (ironsights networked var is not set by weapon state handler)
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

	-- Mark that weapon has been fired (prevents tactical reload smoke)
	self.Weapon.M9KR_HasFired = true

	-- Mark that smoke hasn't spawned yet for this firing session
	self.Weapon.M9KR_SmokeSpawned = false

	-- Set fire time and handle smoke timer on BOTH CLIENT and SERVER
	-- CLIENT: For first-person viewmodel smoke
	-- SERVER: For third-person worldmodel smoke (visible to other players)

	-- Set global fire time for smoke effect checking
	M9KR_LastWeaponFireTime = M9KR_LastWeaponFireTime or {}
	M9KR_LastWeaponFireTime[self.Weapon] = CurTime()

	-- CLIENT: Stop any active PCF smoke particles when firing (shooting interrupts smoke)
	if CLIENT and self.CleanParticles then
		self:CleanParticles()
	end

	-- Store the time when this timer was created on weapon (not closure variable)
	self.Weapon.M9KR_SmokeTimerCreateTime = CurTime()

	-- Cancel any existing timer (shooting interrupts idle smoke)
	local timerName = "M9KR_IdleSmoke_" .. self.Weapon:EntIndex()
	if CLIENT then
		timerName = timerName .. "_CLIENT"
	elseif SERVER then
		timerName = timerName .. "_SERVER"
	end

	if timer.Exists(timerName) then
		timer.Remove(timerName)
	end

	-- Create new timer for 0.75 seconds
	timer.Create(timerName, 0.75, 1, function()
		if not IsValid(self.Weapon) then return end

		-- Don't spawn if already spawned (prevents duplicate from reload)
		if self.Weapon.M9KR_SmokeSpawned then
			return
		end

		-- Don't spawn if weapon fired after this timer was created
		M9KR_LastWeaponFireTime = M9KR_LastWeaponFireTime or {}
		local lastFire = M9KR_LastWeaponFireTime[self.Weapon]
		if lastFire and self.Weapon.M9KR_SmokeTimerCreateTime and lastFire > self.Weapon.M9KR_SmokeTimerCreateTime then
			return
		end

		-- Mark as spawned
		self.Weapon.M9KR_SmokeSpawned = true

		-- Spawn barrel smoke effect
		self:SpawnBarrelSmoke()
	end)
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

		-- Spawn barrel smoke on reload (only if weapon has been fired)
		if self.Weapon.M9KR_HasFired and not self.Weapon.M9KR_SmokeSpawned then
			self.Weapon.M9KR_SmokeSpawned = true

			-- Cancel idle smoke timer if it exists (check both CLIENT and SERVER timers)
			local timerName = "M9KR_IdleSmoke_" .. self.Weapon:EntIndex()
			if CLIENT then
				timerName = timerName .. "_CLIENT"
			elseif SERVER then
				timerName = timerName .. "_SERVER"
			end

			if timer.Exists(timerName) then
				timer.Remove(timerName)
			end

			self:SpawnBarrelSmoke()
		end

		if not self.Owner:IsNPC() then
			if IsValid(self.Owner:GetViewModel()) then
				self.ResetSights = CurTime() + (self.Owner:GetViewModel():SequenceDuration() / (self.ReloadSpeedModifier or 1))
			else
				self.ResetSights = CurTime() + 3
			end
		end

		-- FOV managed by m9kr_weapon_state_handler.lua
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

	-- Spawn barrel smoke on reload (only if weapon has been fired)
	if self.Weapon.M9KR_HasFired and not self.Weapon.M9KR_SmokeSpawned then
		self.Weapon.M9KR_SmokeSpawned = true

		-- Cancel idle smoke timer if it exists (check both CLIENT and SERVER timers)
		local timerName = "M9KR_IdleSmoke_" .. self.Weapon:EntIndex()
		if CLIENT then
			timerName = timerName .. "_CLIENT"
		elseif SERVER then
			timerName = timerName .. "_SERVER"
		end

		if timer.Exists(timerName) then
			timer.Remove(timerName)
		end

		self:SpawnBarrelSmoke()
	end

	if SERVER and IsValid(self.Weapon) then
		if self.Weapon:Clip1() < self.Primary.ClipSize and not self.Owner:IsNPC() then
			-- When the current clip < full clip and the rest of your ammo > 0, then
			-- FOV managed by m9kr_weapon_state_handler.lua
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
					-- FOV managed by m9kr_weapon_state_handler.lua
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
					-- FOV managed by m9kr_weapon_state_handler.lua
					self:SetSprint(false)
					self:SetIronsights(true, self.Owner)
				else
					return
				end
			else
				if SERVER then
					-- FOV managed by m9kr_weapon_state_handler.lua
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
						-- FOV managed by m9kr_weapon_state_handler.lua
						self:SetSprint(false)
						self:SetIronsights(true, self.Owner)
						self.DrawCrosshair = false
				else return end
		elseif self.Owner:KeyDown(IN_SPEED) and self.Owner:GetVelocity():Length2D() > 20 and self.Weapon:GetClass() == self.Gun then
				-- Only enter sprint animation if player is actually moving
				if self.Weapon:GetNextPrimaryFire() <= (CurTime() + .03) then
						self.Weapon:SetNextPrimaryFire(CurTime()+0.3)
				end
				-- FOV managed by m9kr_weapon_state_handler.lua
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
	-- FOV managed by m9kr_weapon_state_handler.lua
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
				-- FOV managed by m9kr_weapon_state_handler.lua
				self:SetSprint(false)
				self:SetIronsights(true, self.Owner)
				self.DrawCrosshair = false
			end
		elseif self.Owner:KeyDown(IN_SPEED) and self.Owner:GetVelocity():Length2D() > 20 and self.Weapon:GetClass() == self.Gun then
			-- Only enter sprint animation if player is actually moving
			if self.Weapon:GetNextPrimaryFire() <= (CurTime() + 0.3) then
				self.Weapon:SetNextPrimaryFire(CurTime() + 0.3)
			end
			-- FOV managed by m9kr_weapon_state_handler.lua
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
		-- FOV managed by m9kr_weapon_state_handler.lua
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

	-- Cycle through the fire modes
	self:CycleFireMode()

	-- Play selection sound
	if IsValid(self.Weapon) then
		self.Weapon:EmitSound("Weapon_AR2.Empty")
		return
    end
end
 
-- IronSight
--[[
IronSight - Simplified gun_base variant
Input handling and FOV managed by m9kr_weapon_state_handler.lua
This function now only handles SERVER-side game logic and CLIENT-side animation state
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
	-- Check CLIENT-side ADS state from m9kr_weapon_state_handler.lua
	-- Block ADS bob reduction when on safety or holding USE key
	local isInADS = false
	if CLIENT and M9KR and M9KR.WeaponState and M9KR.WeaponState.GetVisualState then
		isInADS = M9KR.WeaponState.GetVisualState(self)
	end

	if isInADS and self.Owner:KeyDown(IN_ATTACK2) and not self.Owner:KeyDown(IN_USE) and not self:GetIsOnSafe() and not self.Owner:KeyDown(IN_SPEED) then
		self.SwayScale = 0.05
		self.BobScale = 0.05
	else
		self.SwayScale = 1.0
		self.BobScale = 0.1
	end
end
 
--[[
	UpdateProgressRatios - TFA-style lightweight progress value updates

	This function ONLY updates 4 float values (IronSightsProgress, SprintProgress, SafetyProgress, CrouchProgress)
	using simple math.Approach lerping. No heavy logic, no state detection, just smooth transitions.
	This is identical to TFA's CalculateRatios approach.
]]--
if CLIENT then
	local function mathApproach(current, target, delta)
		delta = math.abs(delta)
		if current < target then
			return math.min(current + delta, target)
		else
			return math.max(current - delta, target)
		end
	end

	function SWEP:UpdateProgressRatios()
		-- Get visual states from m9kr_weapon_state_handler.lua
		local bIron, bSprint = false, false
		if M9KR and M9KR.WeaponState and M9KR.WeaponState.GetVisualState then
			bIron, bSprint = M9KR.WeaponState.GetVisualState(self)
		end
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
end

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

	-- Store viewmodel reference for muzzle flash effects (TFA Base approach)
	if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() then
		self.OwnerViewModel = self.Owner:GetViewModel()

		-- Update PCF particle lighting every frame
		if self.SmokePCFLighting then
			self:SmokePCFLighting()
		end

		-- Update progress values (TFA-style approach - lightweight float lerp only, no heavy logic)
		self:UpdateProgressRatios()
	end

	-- TFA-Style Recoil Decay System
	local ft = FrameTime()
	
	-- Smoothly update IronSights progress for recoil interpolation
	-- Check CLIENT-side ADS state from m9kr_weapon_state_handler.lua
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

	-- ALL ADS/Sprint state management is now handled by m9kr_weapon_state_handler.lua (CLIENT)
	-- The weapon base no longer detects key input or manages these networked variables

	self:IronSight()
end

-- GetViewModelPosition
local IRONSIGHT_TIME = 0.8 -- Time to enter in the ironsight mode

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
	if CLIENT and M9KR and M9KR.WeaponState and M9KR.WeaponState.GetVisualState then
		-- CLIENT: Use visual state for smooth transitions
		local isInADS = M9KR.WeaponState.GetVisualState(self)
		isADS = isInADS and self.Owner:KeyDown(IN_ATTACK2)
	elseif SERVER and IsValid(self.Owner) then
		-- SERVER: Directly detect ADS conditions (same logic as ShootBulletInformation)
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

-- GetViewModelPosition
local IRONSIGHT_TIME = 0.8 -- Time to enter in the ironsight mode

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
	
	-- Get current weapon states from CLIENT-side state handler (m9kr_weapon_state_handler.lua)
	local bIron, bSprint = false, false
	if CLIENT and M9KR and M9KR.WeaponState and M9KR.WeaponState.GetVisualState then
		bIron, bSprint = M9KR.WeaponState.GetVisualState(self)
	end
	local bReloading = self.Weapon:GetNWBool("Reloading")
	
	-- Check if player is crouching OR holding crouch key (for smooth transitions)
	local bCrouching = false
	if IsValid(self.Owner) and self.Owner:IsPlayer() then
		-- Use KeyDown for immediate response, fallback to Crouching() for full crouch state
		bCrouching = self.Owner:KeyDown(IN_DUCK) or self.Owner:Crouching()
	end
	
	if CLIENT then
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
	if CLIENT then
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
	end

	-- Calculate final multiplier using highest priority state
	-- Safety > Sprint > ADS (matches TFA's priority system)
	local Mul = math.max(self.SafetyProgress, self.SprintProgress, self.IronSightsProgress)
	
	-- Enhanced animations (clientside only)
	if CLIENT and IsValid(self.Owner) and self.Owner:IsPlayer() then
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

		-- Detect fire mode changes on CLIENT (networked from SERVER)
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

		/*	Apply sine-based movement for smooth arc motion
			When jumping UP: Full movement (trigX negative, sinValue negative, fallReduction = 1.0)
			When falling DOWN: 35% movement (trigX positive, sinValue positive, fallReduction = 0.35)
			All jump components reduced to 20% when ADS for minimal movement */
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
	if CLIENT and IsValid(self.Owner) and self.Owner:IsPlayer() then
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
 
/*---------------------------------------------------------
SetIronsights
-----------------------------------------------------*/
function SWEP:SetIronsights(b)
	-- NOTE: This function is kept for compatibility with existing weapon code (e.g., bolt action reload)
	-- but the networked variable is NO LONGER USED for visual state.
	-- Visual ADS state is now managed by m9kr_weapon_state_handler.lua CLIENT-side only.
	-- ADS sounds are also played by the state handler, not here.
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
 
 
if CLIENT then
 	-- World model rendering with bone-relative offset positioning
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

	--[[
		Particle Lighting System
		Handles PCF particle lighting and cleanup for weapon effects.
		Adapted from TFA Base effects system.
	]]--
	local vector_up = Vector(0, 0, 1)
	local SmokeLightingMin = Vector(0.15, 0.15, 0.15)
	local SmokeLightingMax = Vector(0.75, 0.75, 0.75)
	local SmokeLightingClamp = 1

	-- Compute environmental lighting for PCF smoke particles (Control Point 1)
	function SWEP:ComputeSmokeLighting(pos, nrm, pcf)
		if not IsValid(pcf) then return end

		local licht = render.ComputeLighting(pos, nrm)
		local lichtFloat = math.Clamp((licht.r + licht.g + licht.b) / 3, 0, SmokeLightingClamp) / SmokeLightingClamp
		local lichtFinal = LerpVector(lichtFloat, SmokeLightingMin, SmokeLightingMax)

		pcf:SetControlPoint(1, lichtFinal)
	end

	-- Update lighting on all SmokePCF particles (called from Think)
	function SWEP:SmokePCFLighting()
		local att = self:LookupAttachment(self.MuzzleAttachment or 1)
		if not att or att <= 0 then return end

		local angpos = self:GetAttachment(att)
		if not angpos then return end

		local pos = angpos.Pos

		if self.SmokePCF then
			for _, v in pairs(self.SmokePCF) do
				self:ComputeSmokeLighting(pos, vector_up, v)
			end
		end

		local owner = self:GetOwner()
		if IsValid(owner) and owner == LocalPlayer() then
			local vm = owner:GetViewModel()
			if IsValid(vm) and vm.SmokePCF then
				local vmatt = vm:LookupAttachment(self.MuzzleAttachment or 1)
				if vmatt and vmatt > 0 then
					local vmangpos = vm:GetAttachment(vmatt)
					if vmangpos then
						for _, v in pairs(vm.SmokePCF) do
							self:ComputeSmokeLighting(vmangpos.Pos, vector_up, v)
						end
					end
				end
			end
		end
	end

	-- Clean up PCF particles on weapon and viewmodel (called on holster/remove)
	function SWEP:CleanParticles()
		if not IsValid(self) then return end

		if self.SmokePCF then
			for att, pcf in pairs(self.SmokePCF) do
				if IsValid(pcf) then
					pcf:StopEmission()
				end
			end
			self.SmokePCF = {}
		end

		if self.StopParticles then
			self:StopParticles()
		end

		if self.StopParticleEmission then
			self:StopParticleEmission()
		end

		local owner = self:GetOwner()
		if IsValid(owner) and owner == LocalPlayer() then
			local vm = owner:GetViewModel()
			if IsValid(vm) then
				if vm.SmokePCF then
					for att, pcf in pairs(vm.SmokePCF) do
						if IsValid(pcf) then
							pcf:StopEmission()
						end
					end
					vm.SmokePCF = {}
				end

				if vm.StopParticles then
					vm:StopParticles()
				end

				if vm.StopParticleEmission then
					vm:StopParticleEmission()
				end
			end
		end
	end

	/**************************
			Global utility code
	**************************/

	-- // Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
	-- // Does not copy entities of course, only copies their reference.
	-- // WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
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
end