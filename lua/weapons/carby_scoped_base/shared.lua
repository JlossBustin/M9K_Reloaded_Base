-- Variables that are used on both client and server
SWEP.Category = ""
SWEP.Author = "Generic Default, Worshipper, Clavus, and Bob"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.MuzzleAttachment = "1" -- Should be "1" for CSS models or "muzzle" for hl2 models
SWEP.ShellEjectAttachment = "2" -- Should be "2" for CSS models or "1" for hl2 models
SWEP.DrawCrosshair = true
SWEP.ViewModelFOV = 65
SWEP.ViewModelFlip = true

SWEP.Base = "carby_gun_base"

SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.Primary.Sound = Sound("") -- Sound of the gun
SWEP.Primary.Round = ("") -- What kind of bullet?
SWEP.Primary.RPM = 0 -- This is in Rounds Per Minute
SWEP.Primary.Cone = 0.15 -- Accuracy of NPCs
SWEP.Primary.Recoil = 10
SWEP.Primary.Damage = 10
SWEP.Primary.Spread = .01 -- define from-the-hip accuracy 1 is terrible, .0001 is exact)
SWEP.Primary.NumShots = 1
SWEP.Primary.ClipSize = 0 -- Size of a clip
SWEP.Primary.DefaultClip = 0 -- Default number of bullets in a clip
SWEP.Primary.KickUp = 0 -- Maximum up recoil (rise)
SWEP.Primary.KickDown = 0 -- Maximum down recoil (skeet)
SWEP.Primary.KickHorizontal = 0 -- Maximum up recoil (stock)
SWEP.Primary.Ammo = "none" -- What kind of ammo

-- Chamber system variables (+1 reload mechanic)
SWEP.HasChamber = true  -- Enables +1 in chamber for tactical reloads
SWEP.ChamberRound = false  -- Tracks if a round is chambered

-- Fire mode selection cooldown timer
SWEP.NextFireSelect = 0

-- SWEP.Secondary.ClipSize = 0 -- Size of a clip
-- SWEP.Secondary.DefaultClip = 0 -- Default number of bullets in a clip
SWEP.Secondary.Ammo = ""

SWEP.Secondary.ScopeZoom = 0
SWEP.Secondary.UseACOG = false
SWEP.Secondary.UseMilDot = false
SWEP.Secondary.UseSVD = false
SWEP.Secondary.UseParabolic = false
SWEP.Secondary.UseElcan = false
SWEP.Secondary.UseGreenDuplex = false

-- Carby's new optics
SWEP.Secondary.UseVortexAMG = false
SWEP.Secondary.UseBurrisMTAC = false
SWEP.Secondary.UseRedDotHybrid = false
SWEP.Secondary.UseGreenPin = false

SWEP.Scoped = true
SWEP.BoltAction = false

SWEP.Penetration = true
SWEP.Ricochet = true
SWEP.MaxRicochet = 1

SWEP.Tracer = 0

SWEP.data = {} -- The starting firemode
SWEP.data.ironsights = 1
SWEP.ScopeScale = 0.55
SWEP.ReticleScale = 0.5
SWEP.IronSightsPos = Vector(2.4537, 1.0923, 0.2696)
SWEP.IronSightsAng = Vector(0.0186, -0.0547, 0)

-- Dynamic ReticleScale configuration based on optic type and weapon class
function SWEP:GetOptimalReticleScale()
	-- Default optic-based scales for weapons without specific overrides
	local opticScales = {
		-- Aimpoint optics
		UseAimpoint = 0.4,
		UseACOG = 0.6, 
		UseMilDot = 0.6,
		UseBurrisMTAC = 0.6,
		
		-- High magnification scopes (smaller reticles)
		UseVortexAMG = 0.4,
		UseSVD = 0.45,
		UseParabolic = 0.5,
		
		-- Medium magnification scopes
		UseElcan = 0.55,
		UseGreenDuplex = 0.55,
		
		-- Low magnification/red dot sights (larger reticles)
		UseRedDotHybrid = 0.65,
		UseGreenPin = 0.3,
		UseMatador = 0.6,
		UseParabellum = 0.6
	}
	
	-- Check which optic is enabled and return its optimal scale
	for opticType, scale in pairs(opticScales) do
		if self.Secondary[opticType] then
			return scale
		end
	end
	
	-- Default fallback if no specific optic is found
	return 0.5
end

function SWEP:Initialize()
	if not IsValid(self) or not IsValid(self.Weapon) or not IsValid(self.Owner) then return end
	self:SetHoldType(self.HoldType)
	
	-- Set dynamic ReticleScale based on optic type
	self.ReticleScale = self:GetOptimalReticleScale()
	
	-- Initialize chamber to empty
	self.ChamberRound = false
	
	-- Fix metatable inheritance issue: ensure FireModes is a clean copy
	-- GMod's metatable inheritance can cause child weapons to see parent's FireModes
	-- Use table.Copy to break the metatable chain completely
	if self.FireModes then
		self.FireModes = table.Copy(self.FireModes)
	end
	
	-- Initialize fire mode - set Primary.Automatic for GMod's base SWEP system
	-- GMod's weapon system reads Primary.Automatic to determine auto-fire behavior
	-- We set it based on our FireMode enum system for compatibility
	if self.FireModes then
		-- Ensure CurrentFireMode is valid
		self.CurrentFireMode = self.CurrentFireMode or 1
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
	else
		-- No FireModes defined, default to auto
		self.Primary.Automatic = true
	end
	
	self.Weapon:SetNWBool("Reloading", false)
	util.PrecacheSound(self.Primary.Sound)
	if CLIENT then
	
		-- We need to get these so we can scale everything to the player's current resolution.
		local iScreenWidth = surface.ScreenWidth()
		local iScreenHeight = surface.ScreenHeight()
		
		-- The following code is only slightly riped off from Night Eagle
		-- These tables are used to draw things like scopes and crosshairs to the HUD.
		-- so DONT GET RID OF IT!

		self.ScopeTable = {}
		self.ScopeTable.l = iScreenHeight*self.ScopeScale
		self.ScopeTable.x1 = 0.5*(iScreenWidth + self.ScopeTable.l)
		self.ScopeTable.y1 = 0.5*(iScreenHeight - self.ScopeTable.l)
		self.ScopeTable.x2 = self.ScopeTable.x1
		self.ScopeTable.y2 = 0.5*(iScreenHeight + self.ScopeTable.l)
		self.ScopeTable.x3 = 0.5*(iScreenWidth - self.ScopeTable.l)
		self.ScopeTable.y3 = self.ScopeTable.y2
		self.ScopeTable.x4 = self.ScopeTable.x3
		self.ScopeTable.y4 = self.ScopeTable.y1
		self.ScopeTable.l = (iScreenHeight + 1)*self.ScopeScale -- I don't know why this works, but it does.

		self.QuadTable = {}
		self.QuadTable.x1 = 0
		self.QuadTable.y1 = 0
		self.QuadTable.w1 = iScreenWidth
		self.QuadTable.h1 = 0.5*iScreenHeight - self.ScopeTable.l
		self.QuadTable.x2 = 0
		self.QuadTable.y2 = 0.5*iScreenHeight + self.ScopeTable.l
		self.QuadTable.w2 = self.QuadTable.w1
		self.QuadTable.h2 = self.QuadTable.h1
		self.QuadTable.x3 = 0
		self.QuadTable.y3 = 0
		self.QuadTable.w3 = 0.5*iScreenWidth - self.ScopeTable.l
		self.QuadTable.h3 = iScreenHeight
		self.QuadTable.x4 = 0.5*iScreenWidth + self.ScopeTable.l
		self.QuadTable.y4 = 0
		self.QuadTable.w4 = self.QuadTable.w3
		self.QuadTable.h4 = self.QuadTable.h3

		self.LensTable = {}
		self.LensTable.x = self.QuadTable.w3
		self.LensTable.y = self.QuadTable.h1
		self.LensTable.w = 2*self.ScopeTable.l
		self.LensTable.h = 2*self.ScopeTable.l

		self.ReticleTable = {}
		self.ReticleTable.wdivider = 3.125
		self.ReticleTable.hdivider = 1.7579/self.ReticleScale		-- Draws the texture at 512 when the resolution is 1600x900
		self.ReticleTable.x = (iScreenWidth/2)-((iScreenHeight/self.ReticleTable.hdivider)/2)
		self.ReticleTable.y = (iScreenHeight/2)-((iScreenHeight/self.ReticleTable.hdivider)/2)
		self.ReticleTable.w = iScreenHeight/self.ReticleTable.hdivider
		self.ReticleTable.h = iScreenHeight/self.ReticleTable.hdivider

		self.FilterTable = {}
		self.FilterTable.wdivider = 3.125
		self.FilterTable.hdivider = 1.7579/1.35	
		self.FilterTable.x = (iScreenWidth/2)-((iScreenHeight/self.FilterTable.hdivider)/2)
		self.FilterTable.y = (iScreenHeight/2)-((iScreenHeight/self.FilterTable.hdivider)/2)
		self.FilterTable.w = iScreenHeight/self.FilterTable.hdivider
		self.FilterTable.h = iScreenHeight/self.FilterTable.hdivider

		
	end
	if SERVER then
		self:SetNPCMinBurst(3)
		self:SetNPCMaxBurst(10)
		self:SetNPCFireRate(1)
		--self:SetCurrentWeaponProficiency( WEAPON_PROFICIENCY_VERY_GOOD )
	end
	self:SetHoldType(self.HoldType)
	
	if CLIENT then

		-- // Create a new table for every weapon instance
		self.VElements = table.FullCopy( self.VElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

		-- CreateModels() removed - legacy code no longer needed
		-- Viewmodel boneMods are handled by PreDrawViewModel hook

		-- // init view model bone build function
		if IsValid(self.Owner) and self.Owner:IsPlayer() then
			if self.Owner:Alive() then
				local vm = self.Owner:GetViewModel()
				if IsValid(vm) then
					if M9KR and M9KR.ViewModelMods then
					M9KR.ViewModelMods.ResetBonePositions(vm)
				end
					-- // Init viewmodel visibility
					if (self.ShowViewModel == nil or self.ShowViewModel) then
						vm:SetColor(Color(255,255,255,255))
					else
						-- // however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
						vm:SetMaterial("Debug/hsv")			
					end
				end
			end
		end
	end

	-- Defer expensive CLIENT operations to Deploy() for faster spawn

end

function SWEP:Deploy()
	if not IsValid(self) or not IsValid(self.Weapon) or not IsValid(self.Owner) then return end
	self:SetIronsights(false, self.Owner) -- Set the ironsight false
	self:SetSprint(false) -- Clear sprint state initially
	self:SetHoldType(self.HoldType)
	self.BurstShotsRemaining = nil
	self.ContinuousShotCount = 0  -- Reset progressive spread counter (auto mode)
	self.RapidFireHeat = 0  -- Reset rapid fire heat (semi/burst spam)
	self.LastShotTime = 0
	self.LastTriggerState = false

	-- Initialize chamber state on deploy if not set
	if self.ChamberRound == nil then
		self.ChamberRound = false
	end
	
	-- Re-initialize fire mode on deploy to ensure Primary.Automatic is set correctly
	-- This fixes the issue where scoped weapons starting in auto mode won't fire automatically
	if self.FireModes then
		local mode = self.FireModes[self.CurrentFireMode]
		self.Primary.Automatic = (mode == "auto")
	end

	-- Deferred CLIENT initialization (moved from Initialize() for faster spawn)
	if CLIENT and not self.FirstDeployDone then
		self.FirstDeployDone = true

		-- WepSelectIcon texture loading for weapon selection HUD
		if not self.WepSelectIcon or self.WepSelectIcon == 0 then
			local oldpath = "vgui/hud/name"
			local newpath = string.gsub(oldpath, "name", self.Gun)
			self.WepSelectIcon = surface.GetTextureID(newpath)
		end
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

		if CLIENT then
			print("[M9KR SCOPED DEPLOY DEBUG] First deploy for " .. self:GetClass())
			print("  Silenced: " .. tostring(self.Silenced))
		end

		local drawAnim = ACT_VM_DRAW
		local vm = self.Owner:GetViewModel()

		if IsValid(vm) then
			-- Try special first-time deploy animations
			if self.Silenced then
				-- For suppressed weapons, try ACT_VM_DRAW_EMPTY
				local emptySeq = vm:SelectWeightedSequence(ACT_VM_DRAW_EMPTY)
				if CLIENT then
					print("  ACT_VM_DRAW_EMPTY sequence: " .. tostring(emptySeq))
				end
				if emptySeq and emptySeq > -1 then
					vm:SendViewModelMatchingSequence(emptySeq)
					drawAnim = nil  -- Don't send anim again
					if CLIENT then
						print("  -> Playing ACT_VM_DRAW_EMPTY")
					end
				else
					if CLIENT then
						print("  -> ACT_VM_DRAW_EMPTY not found, falling back to ACT_VM_DRAW")
					end
				end
			else
				-- For regular weapons, try ACT_VM_DRAW_DEPLOYED
				local deploySeq = vm:SelectWeightedSequence(ACT_VM_DRAW_DEPLOYED)
				if CLIENT then
					print("  ACT_VM_DRAW_DEPLOYED sequence: " .. tostring(deploySeq))
				end
				if deploySeq and deploySeq > -1 then
					vm:SendViewModelMatchingSequence(deploySeq)
					drawAnim = nil  -- Don't send anim again
					if CLIENT then
						print("  -> Playing ACT_VM_DRAW_DEPLOYED")
					end
				else
					if CLIENT then
						print("  -> ACT_VM_DRAW_DEPLOYED not found, falling back to ACT_VM_DRAW")
					end
				end
			end
		end

		-- Only send weapon anim if we didn't already send a sequence
		if drawAnim then
			self.Weapon:SendWeaponAnim(drawAnim)
			if CLIENT then
				print("  -> Sending fallback anim: ACT_VM_DRAW")
			end
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
	-- Critical safety checks for weapon state during transitions
	if not IsValid(self) or not IsValid(self.Weapon) then
		return true
	end

	-- Clean up all active timers when holstering to prevent reload completion after weapon switch
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

	-- Cancel scoped weapon specific timers
	local reloadTimerName = "M9K_ScopedReload_" .. entIndex
	if timer.Exists(reloadTimerName) then
		timer.Remove(reloadTimerName)
	end

	local sprintTimerName = "M9K_ScopedReloadSprint_" .. entIndex
	if timer.Exists(sprintTimerName) then
		timer.Remove(sprintTimerName)
	end

	local boltTimerName = "M9K_ScopedBolt_" .. entIndex
	if timer.Exists(boltTimerName) then
		timer.Remove(boltTimerName)
	end

	local boltCompleteTimerName = "M9K_ScopedBoltComplete_" .. entIndex
	if timer.Exists(boltCompleteTimerName) then
		timer.Remove(boltCompleteTimerName)
	end

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

	-- Cancel reload state when holstering
	if IsValid(self.Weapon) then
		self.Weapon:SetNWBool("Reloading", false)
	end

	-- Reset approach-based progress values to prevent issues during weapon switching
	self.CrouchProgress = 0
	self.bLastCrouching = false

	-- Reset scope animation variables on CLIENT to prevent DrawHUD/GetScopeSway crashes
	if CLIENT then
		self.AnimationTime = 0
		self.BreathIntensity = 0
		self.WalkIntensity = 0
		self.SprintIntensity = 0
		self.JumpVelocitySmooth = 0
		self.LateralVelocitySmooth = 0
		self.LateralVelocity = 0
		self.LastEyeAngles = nil
		self.CameraRotationVelocity = 0

		-- Reset viewmodel bones (from parent gun_base)
		if IsValid(self.Owner) and not self.Owner:IsNPC() then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				if M9KR and M9KR.ViewModelMods then
					M9KR.ViewModelMods.ResetBonePositions(vm)
				end
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

	-- Cancel all scoped weapon specific timers
	local timerNames = {
		"M9K_ScopedReload_" .. entIndex,
		"M9K_ScopedReloadSprint_" .. entIndex,
		"M9K_ScopedBolt_" .. entIndex,
		"M9K_ScopedBoltComplete_" .. entIndex,
		-- Parent gun_base timers
		"M9K_Reload_" .. entIndex,
		"M9K_ReloadSprint_" .. entIndex,
		"M9K_Silencer_" .. entIndex
	}

	for _, timerName in ipairs(timerNames) do
		if timer.Exists(timerName) then
			timer.Remove(timerName)
		end
	end

	-- Reset approach-based progress values to prevent GetViewModelPosition crashes
	self.CrouchProgress = 0
	self.bLastCrouching = false

	-- Reset scope animation variables on CLIENT to prevent DrawHUD/GetScopeSway crashes
	if CLIENT then
		self.AnimationTime = 0
		self.BreathIntensity = 0
		self.WalkIntensity = 0
		self.SprintIntensity = 0
		self.JumpVelocitySmooth = 0
		self.LateralVelocitySmooth = 0
		self.LateralVelocity = 0
		self.LastEyeAngles = nil
		self.CameraRotationVelocity = 0

		-- Reset viewmodel bones (from parent gun_base)
		if IsValid(self.Owner) and not self.Owner:IsNPC() then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				if M9KR and M9KR.ViewModelMods then
					M9KR.ViewModelMods.ResetBonePositions(vm)
				end
			end
		end
	end
end

function SWEP:BoltBack()
	-- Critical safety checks for weapon state
	if not IsValid(self) or not IsValid(self.Weapon) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return
	end

	if self.Weapon:Clip1() > 0 or self.Owner:GetAmmoCount(self.Weapon:GetPrimaryAmmoType()) > 0 then
		if not SERVER then return end

		local entIndex = self:EntIndex()

		-- Additional safety check for valid entity index
		if not entIndex or entIndex <= 0 then
			return
		end

		if self.Weapon:GetClass() ~= self.Gun then return end

		-- Get viewmodel and animation duration
		local vm = self.Owner:GetViewModel()
		if not IsValid(vm) then return end

		local boltactiontime = vm:SequenceDuration()

		-- Create timer to return to idle after bolt animation completes
		-- NOTE: We do NOT set Reloading=true here - that flag is only for magazine reloads
		-- Fire rate timing is already handled by SetNextPrimaryFire in gun_base
		local boltCompleteTimerName = "M9K_ScopedBoltComplete_" .. entIndex
		timer.Create(boltCompleteTimerName, boltactiontime, 1, function()
			if not IsValid(self) or not IsValid(self.Weapon) or not IsValid(self.Owner) then return end

			-- Don't override reload animations - if weapon is reloading, let reload handle animations
			if self.Weapon:GetNWBool("Reloading") then return end

			-- Send weapon back to idle animation after bolt action completes
			if self.Silenced then
				self.Weapon:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
			else
				self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
			end

			-- If player is still in ADS, restore ironsights position
			if self.Owner:KeyDown(IN_ATTACK2) and self.Weapon:GetClass() == self.Gun then
				self.IronSightsPos = self.SightsPos
				self.IronSightsAng = self.SightsAng
				if not self.ShowCrosshairInADS then
					self.DrawCrosshair = false
				end
				self:SetIronsights(true, self.Owner)
			end
		end)
	end
end

function SWEP:Reload()
	if not IsValid(self) or not IsValid(self.Weapon) or not IsValid(self.Owner) then return end

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
		-- Magazine is full, need to manually play reload animation for +1
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

		-- FOV and viewmodel managed by m9kr_weapon_state_handler.lua
		self:SetIronsights(false)
		if CLIENT then return end

		-- Handle the +1 ammo after animation completes
		local waitdammit = self.Owner:GetViewModel():SequenceDuration() / (self.ReloadSpeedModifier or 1)
		local reloadTimerName = "M9K_ScopedReload_" .. self:EntIndex()
		timer.Create(reloadTimerName, waitdammit + 0.1, 1, function()
			if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end
			
			-- Add the +1 chamber round (skip for revolvers - no chamber)
			local currentAmmo = self.Weapon:Clip1()
			local reserve = self.Owner:GetAmmoCount(self.Weapon:GetPrimaryAmmoType())
			if reserve > 0 and currentAmmo == maxClip and not self.noChamber then
				self.Weapon:SetClip1(maxClip + 1)
				self.Owner:SetAmmo(reserve - 1, self.Weapon:GetPrimaryAmmoType())
			end
			
			self:PostReloadScopeCheck()
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

	if (self.Weapon:Clip1() < self.Primary.ClipSize) and not self.Owner:IsNPC() then
		-- When the current clip < full clip and the rest of your ammo > 0, then

		-- FOV and viewmodel managed by m9kr_weapon_state_handler.lua
		-- Zoom = 0

		self:SetIronsights(false)
		-- Set the ironsight to false
		self.Weapon:SetNWBool("Reloading", true)

		-- Show reload animation to other players
		self.Owner:SetAnimation(PLAYER_RELOAD)

		-- Viewmodel automatically returns to normal position via GetViewModelPosition
		if CLIENT then return end
	end
	
	local waitdammit
	if self.Owner:GetViewModel() == nil then
		waitdammit = 3
	else
		waitdammit = self.Owner:GetViewModel():SequenceDuration() / (self.ReloadSpeedModifier or 1)
	end
	
	local reloadTimerName = "M9K_ScopedReload_" .. self:EntIndex()
	timer.Create(reloadTimerName, waitdammit + .1, 1, function()
		if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end
		
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
		
		self:PostReloadScopeCheck()
	end)
end

function SWEP:PostReloadScopeCheck()
	-- Critical safety checks for weapon state during transitions
	if not IsValid(self) or not IsValid(self.Weapon) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return
	end

	if self.Weapon ~= nil then
		self.Weapon:SetNWBool("Reloading", false)

		-- Send weapon back to idle animation after reload completes
		if self.Silenced then
			self.Weapon:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
		else
			self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
		end

		if self.Owner:KeyDown(IN_ATTACK2) and self.Weapon:GetClass() == self.Gun then
			-- FOV and viewmodel managed by m9kr_weapon_state_handler.lua
			-- Only handle SERVER-side game logic here
			if SERVER then
				self.IronSightsPos = self.SightsPos -- Bring it up
				self.IronSightsAng = self.SightsAng -- Bring it up
				if not self.ShowCrosshairInADS then
					self.DrawCrosshair = false
				end
				self:SetIronsights(true, self.Owner)
			end
		elseif self.Owner:KeyDown(IN_SPEED) and self.Owner:GetVelocity():Length2D() > 20 and self.Weapon:GetClass() == self.Gun then
			-- Only enter sprint animation if player is actually moving
			if self.Weapon:GetNextPrimaryFire() <= (CurTime()+0.3) then
				self.Weapon:SetNextPrimaryFire(CurTime()+0.3) -- Make it so you can't shoot for another quarter second
			end
			self.IronSightsPos = self.RunSightsPos -- Hold it down
			self.IronSightsAng = self.RunSightsAng -- Hold it down
			self:SetIronsights(false, self.Owner)
			-- FOV managed by m9kr_weapon_state_handler.lua

			-- Delay sprint transition for smoother feel
			-- Gun goes to idle first, then transitions to sprint after 0.35 seconds
			-- This gives enough time for the viewmodel to settle before entering sprint
			-- Mark that we're in post-reload transition to prevent lateral tilt issues
			self.Weapon:SetNWFloat("PostReloadTransition", CurTime() + 0.35)
			
			local sprintTimerName = "M9K_ScopedReloadSprint_" .. self:EntIndex()
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
		else return end
	end
end

--[[
SafetyToggle - Scoped weapon override (legacy, kept for compatibility)
Handles safety state changes (visual/audio feedback managed by m9kr_weapon_state_handler.lua)
]]
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
			-- ENGAGING SAFETY - force exit ADS/sprint/scope
			self:SetIronsights(false)
			self:SetSprint(false)
		else
			-- DISENGAGING SAFETY - add firing delay (slightly longer than reload)
			self:SetNextPrimaryFire(CurTime() + 0.5)
		end
	end

	-- CLIENT: Audio feedback only (visual state managed by m9kr_weapon_state_handler.lua)
	if CLIENT then
		local newSafetyState = not self:GetIsOnSafe()

		-- Play AR2 empty sound (same as fire mode switching)
		self.Weapon:EmitSound("Weapon_AR2.Empty")

		-- Update CLIENT-side state flags for viewmodel animation
		-- Note: The approach-based system in GetViewModelPosition handles state transitions automatically
		if newSafetyState then
			self.DrawCrosshair = false
			self.bLastSafety = true
		else
			-- Disengage safety - approach system will smoothly transition
			self.bLastSafety = false
			self.DrawCrosshair = self.OrigCrossHair
		end
	end
end

--[[
	SafetyOn - Enter safety mode (SHIFT + E + R) - Scoped weapon override
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
		self.DrawCrosshair = false
		self.bLastSafety = true
	end
end

--[[
	SafetyOff - Exit safety mode (E + R when in safety) - Scoped weapon override
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
		self.bLastSafety = false
		self.DrawCrosshair = self.OrigCrossHair

		-- Trigger fire mode switch animation (shows the mode being restored)
		self.FireModeSwitchTime = CurTime()
	end
end

--[[
IronSight - Simplified scoped weapon variant
Input handling, FOV, and viewmodel visibility managed by m9kr_weapon_state_handler.lua
This function now only handles SERVER-side game logic and CLIENT-side animation state
]]
function SWEP:IronSight()
	if not IsValid(self) then return end
	if not IsValid(self.Owner) then return end

	-- Safety mode controls (SERVER only to prevent prediction spam):
	-- SHIFT + E + R = Enter safety mode
	-- E + R (when in safety) = Exit safety and restore last fire mode
	-- NOTE: Fire mode switching (E + R when not in safety) is handled by m9kr_firemode_handler.lua
	if SERVER and self.Owner:KeyDown(IN_USE) and self.Owner:KeyPressed(IN_RELOAD) then
		if self:GetIsOnSafe() then
			-- Currently in safety mode - E + R exits and restores last fire mode
			self:SafetyOff()
		elseif self.Owner:KeyDown(IN_SPEED) then
			-- Not in safety, SHIFT held - SHIFT + E + R enters safety
			self:SafetyOn()
		end
		-- Fire mode switching removed - handled by m9kr_firemode_handler.lua to avoid double-triggering
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


	-- BobScale management - reduced when scoped (runs on both CLIENT and SERVER)
	-- Only block scope bob reduction if player is actually sprinting (not just holding sprint key)
	-- Block ADS bob reduction when on safety or holding USE key
	local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
	local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and self.Owner:IsOnGround() and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement
	if self.Owner:KeyDown(IN_ATTACK2) and not self.Owner:KeyDown(IN_USE) and not self:GetIsOnSafe() and not isActuallySprinting then
		self.SwayScale = 0.05
		self.BobScale = 0.05
	else
		self.SwayScale = 1.0
		self.BobScale = 0.5
	end
end

-- HUD drawing moved to lua/m9kr/client/m9kr_hud.lua
-- CustomAmmoDisplay is now centralized

-- Calculate scope sway offset and rotation based on movement
-- Returns: swayX, swayY (position offset), rotationAngle (degrees)
function SWEP:GetScopeSway()
	if not CLIENT or not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return 0, 0, 0
	end
	
	-- Initialize animation variables
	self.AnimationTime = self.AnimationTime or 0
	self.BreathIntensity = self.BreathIntensity or 0
	self.WalkIntensity = self.WalkIntensity or 0
	self.SprintIntensity = self.SprintIntensity or 0
	self.LateralVelocitySmooth = self.LateralVelocitySmooth or 0
	self.LastEyeAngles = self.LastEyeAngles or self.Owner:EyeAngles()
	self.CameraRotationVelocity = self.CameraRotationVelocity or 0
	
	-- Check if game is paused (singleplayer)
	-- In singleplayer, FrameTime() returns 0 when paused
	local rawFrameTime = FrameTime()
	local isPaused = (rawFrameTime == 0)

	local ft = isPaused and 0.001 or math.Clamp(rawFrameTime, 0, 0.1)
	local ct = CurTime()

	-- Update animation time ONLY if not paused (this freezes breathing animation)
	if not isPaused then
		self.AnimationTime = self.AnimationTime + ft
	end
	
	local velocity = self.Owner:GetVelocity()
	local speed = velocity:Length2D()
	local isOnGround = self.Owner:IsOnGround()

	-- Check if player is pressing movement keys (for immediate sprint exit when keys released)
	local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)

	local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and speed > 50 and isOnGround and isPressingMovement
	if self.JumpCancelsSprint and not isOnGround and (self.SprintJumping or false) then
		isActuallySprinting = false
	end
	
	local isSprinting = isActuallySprinting
	local isWalking = speed > 20 and not isSprinting and isOnGround
	local isShooting = self.Weapon:GetNextPrimaryFire() > ct - 0.15
	local isReloading = self.Weapon:GetNWBool("Reloading")
	
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
	local angularVelocity = angleDiff / ft
	self.CameraRotationVelocity = Lerp(ft * 5, self.CameraRotationVelocity, angularVelocity)
	self.LastEyeAngles = currentEyeAngles
	
	-- Track lateral velocity for tilt animation (matching gun_base)
	local eyeAng = self.Owner:EyeAngles()
	local rightVec = eyeAng:Right()
	rightVec.z = 0
	rightVec:Normalize()
	local lateralVel = velocity:Dot(rightVec)
	self.LateralVelocitySmooth = Lerp(ft * 3, self.LateralVelocitySmooth, lateralVel)
	
	-- Calculate target intensities
	local targetBreath = 0  -- No breathing sway when scoped
	local targetWalk = isWalking and math.Clamp(speed / 200, 0, 1) or 0
	local targetSprint = isSprinting and math.Clamp(speed / 250, 0, 1) or 0
	
	-- Smooth transitions (matching gun_base speeds)
	self.BreathIntensity = Lerp(ft * 2, self.BreathIntensity, targetBreath)
	self.WalkIntensity = Lerp(ft * 6, self.WalkIntensity, targetWalk)
	self.SprintIntensity = Lerp(ft * 4, self.SprintIntensity, targetSprint)
	
	-- Calculate sway
	local swayX = 0
	local swayY = 0
	local rotationAngle = 0
	
	-- Reduced ADS multiplier for more visible scope sway (60% reduction instead of 85%)
	local aimMult = 1 - 0.60  -- 0.40 (more visible than gun_base ADS)
	
	-- Walking bob (very slow frequency, increased scale for visible movement through scope)
	if self.WalkIntensity > 0.01 then
		local walkMult = self.WalkIntensity * aimMult
		local walkTime = self.AnimationTime * 2.5  -- Slow horizontal sway frequency
		
		-- Vertical bob - slower frequency (reduced multiplier) for smoother up/down movement
		swayY = swayY + math.abs(math.sin(walkTime * 1.25)) * walkMult * 0.05 * 180  -- Reduced from *1.5 to *1.25 for slower vertical
		
		-- Horizontal sway - decreased amplitude for less left/right movement
		swayX = swayX + math.sin(walkTime) * walkMult * 0.25 * 60
	end
	
	-- Sprint bob (slower frequency, increased scale for visible movement)
	if self.SprintIntensity > 0.01 then
		local sprintMult = self.SprintIntensity
		local sprintTime = self.AnimationTime * 3.5  -- Slow horizontal sway frequency
		
		-- Vertical bob - slower frequency (reduced multiplier) for smoother up/down movement
		swayY = swayY + math.abs(math.sin(sprintTime * 1.25)) * sprintMult * 0.1 * 180  -- Reduced from *1.5 to *1.25 for slower vertical
		
		-- Horizontal sway - decreased amplitude for less left/right movement
		swayX = swayX + math.sin(sprintTime) * sprintMult * 0.3 * 60
	end
	
	-- Lateral tilt rotation (5-10 degree range, non-inverted)
	local xVelocityClamped = self.LateralVelocitySmooth
	
	-- TFA's square root scaling for high velocities (matching gun_base)
	if math.abs(xVelocityClamped) > 200 then
		local sign = (xVelocityClamped < 0) and -1 or 1
		xVelocityClamped = (math.sqrt((math.abs(xVelocityClamped) - 200) / 50) * 50 + 200) * sign
	end
	
	-- Calculate rotation angle from lateral movement (5-10 degree range at full strafe speed)
	-- At 200 units/sec strafe speed, aim for ~7.5 degrees rotation
	-- NEGATIVE sign for correct direction: strafe right = tilt right (positive velocity = positive angle)
	local rotationScale = -0.0375  -- 200 * 0.0375 = 7.5 degrees at full strafe
	rotationAngle = xVelocityClamped * rotationScale
	
	-- Add camera rotation tilt (when turning view while scoped)
	-- Camera turning right (positive angular velocity) = tilt right (positive angle)
	-- Scale camera rotation to degrees (max ~5 degrees at moderate turn speed)
	-- Reduced by 15% from 0.015 to 0.01275 for subtler movement
	local cameraTiltScale = 0.01275  -- Angular velocity to tilt conversion (positive for matching direction)
	local cameraTilt = self.CameraRotationVelocity * cameraTiltScale
	rotationAngle = rotationAngle + cameraTilt
	
	-- Clamp total rotation to reasonable range (max ±10 degrees)
	rotationAngle = math.Clamp(rotationAngle, -10, 10)

	-- Add minimal horizontal translation for subtle movement (keep scope mostly centered)
	swayX = swayX + (xVelocityClamped * 0.02)  -- Very small translation

	-- Add jump offset to scope sway (matching scoped ADS jump intensity from gun_base)
	self.JumpVelocitySmooth = self.JumpVelocitySmooth or 0
	self.JumpIntensitySmooth = self.JumpIntensitySmooth or 0

	-- Smooth vertical velocity tracking
	local jumpVelocityTarget = velocity.z
	self.JumpVelocitySmooth = Lerp(ft * 5, self.JumpVelocitySmooth, jumpVelocityTarget)

	-- Detect jumping
	local isJumping = not isOnGround and math.abs(velocity.z) > 10

	-- Calculate raw jump intensity with scoped ADS reduction (0.4 multiplier from gun_base)
	local rawJumpIntensity = (3 + math.Clamp(math.abs(self.JumpVelocitySmooth) - 100, 0, 200) / 200 * 4) * 0.4

	-- Smoothly lerp jump intensity
	local jumpIntensityTarget = isJumping and rawJumpIntensity or 0
	self.JumpIntensitySmooth = Lerp(ft * 8, self.JumpIntensitySmooth, jumpIntensityTarget)

	-- Apply jump sway to scope (subtle movement)
	local trigX = -math.Clamp(self.JumpVelocitySmooth / 200, -1, 1) * math.pi / 2
	local sinValue = math.sin(trigX)
	local jumpScale = 15  -- Scale factor for scope pixels

	-- Add jump sway (horizontal and vertical)
	swayX = swayX + (sinValue * jumpScale * self.JumpIntensitySmooth)
	swayY = swayY - (sinValue * jumpScale * self.JumpIntensitySmooth * 0.3)  -- Less vertical movement

	return swayX, swayY, rotationAngle
end

-- Draw the "+ 1" indicator and fire mode when chambered (for scoped weapons)
function SWEP:DrawHUD()
	-- Critical safety checks for weapon state during transitions
	if not IsValid(self) or not IsValid(self.Weapon) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return
	end
	
	-- First draw scope reticles if scoped in
	-- Don't draw scope when USE is held (forces idle state), on safety, or actually sprinting
	-- Check CLIENT-side ADS state from m9kr_weapon_state_handler.lua
	local isInADS = false
	if M9KR and M9KR.WeaponState and M9KR.WeaponState.GetVisualState then
		isInADS = M9KR.WeaponState.GetVisualState(self)
	end

	-- Only block scope rendering if player is actually sprinting (not just holding sprint key)
	-- Also block if on safety or holding USE key
	local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
	local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and self.Owner:IsOnGround() and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement
	if self.Owner:KeyDown(IN_ATTACK2) and isInADS and not self.Owner:KeyDown(IN_USE) and not self:GetIsOnSafe() and not isActuallySprinting then

			-- CRITICAL FIX: Initialize scope tables HERE if missing (for picked-up weapons from ground)
			-- Deploy() is NOT called on CLIENT for world weapons, so this is the only reliable place
			if not self.LensTable or not self.ReticleTable or not self.ScopeTable or not self.QuadTable or not self.FilterTable then
				local iScreenWidth = surface.ScreenWidth()
				local iScreenHeight = surface.ScreenHeight()

				self.ScopeTable = {}
				self.ScopeTable.l = iScreenHeight*self.ScopeScale
				self.ScopeTable.x1 = 0.5*(iScreenWidth + self.ScopeTable.l)
				self.ScopeTable.y1 = 0.5*(iScreenHeight - self.ScopeTable.l)
				self.ScopeTable.x2 = self.ScopeTable.x1
				self.ScopeTable.y2 = 0.5*(iScreenHeight + self.ScopeTable.l)
				self.ScopeTable.x3 = 0.5*(iScreenWidth - self.ScopeTable.l)
				self.ScopeTable.y3 = self.ScopeTable.y2
				self.ScopeTable.x4 = self.ScopeTable.x3
				self.ScopeTable.y4 = self.ScopeTable.y1
				self.ScopeTable.l = (iScreenHeight + 1)*self.ScopeScale

				self.QuadTable = {}
				self.QuadTable.x1 = 0
				self.QuadTable.y1 = 0
				self.QuadTable.w1 = iScreenWidth
				self.QuadTable.h1 = 0.5*iScreenHeight - self.ScopeTable.l
				self.QuadTable.x2 = 0
				self.QuadTable.y2 = 0.5*iScreenHeight + self.ScopeTable.l
				self.QuadTable.w2 = self.QuadTable.w1
				self.QuadTable.h2 = self.QuadTable.h1
				self.QuadTable.x3 = 0
				self.QuadTable.y3 = 0
				self.QuadTable.w3 = 0.5*iScreenWidth - self.ScopeTable.l
				self.QuadTable.h3 = iScreenHeight
				self.QuadTable.x4 = 0.5*iScreenWidth + self.ScopeTable.l
				self.QuadTable.y4 = 0
				self.QuadTable.w4 = self.QuadTable.w3
				self.QuadTable.h4 = self.QuadTable.h3

				self.LensTable = {}
				self.LensTable.x = self.QuadTable.w3
				self.LensTable.y = self.QuadTable.h1
				self.LensTable.w = 2*self.ScopeTable.l
				self.LensTable.h = 2*self.ScopeTable.l

				self.ReticleTable = {}
				self.ReticleTable.wdivider = 3.125
				self.ReticleTable.hdivider = 1.7579/self.ReticleScale
				self.ReticleTable.x = (iScreenWidth/2)-((iScreenHeight/self.ReticleTable.hdivider)/2)
				self.ReticleTable.y = (iScreenHeight/2)-((iScreenHeight/self.ReticleTable.hdivider)/2)
				self.ReticleTable.w = iScreenHeight/self.ReticleTable.hdivider
				self.ReticleTable.h = iScreenHeight/self.ReticleTable.hdivider

				self.FilterTable = {}
				self.FilterTable.wdivider = 3.125
				self.FilterTable.hdivider = 1.7579/1.35
				self.FilterTable.x = (iScreenWidth/2)-((iScreenHeight/self.FilterTable.hdivider)/2)
				self.FilterTable.y = (iScreenHeight/2)-((iScreenHeight/self.FilterTable.hdivider)/2)
				self.FilterTable.w = iScreenHeight/self.FilterTable.hdivider
				self.FilterTable.h = iScreenHeight/self.FilterTable.hdivider
			end

			-- Get scope sway offset and rotation angle
			local swayX, swayY, rotationAngle = self:GetScopeSway()

			-- Calculate center points for rotation
			local lensCenterX = self.LensTable.x + self.LensTable.w / 2
			local lensCenterY = self.LensTable.y + self.LensTable.h / 2
			local reticleCenterX = self.ReticleTable.x + self.ReticleTable.w / 2
			local reticleCenterY = self.ReticleTable.y + self.ReticleTable.h / 2

			if self.Secondary.UseACOG then
			-- Draw the FAKE SCOPE THANG (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)

			-- Draw the CHEVRON (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_acogchevron"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the ACOG REFERENCE LINES (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_acogcross"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)
			end

			if self.Secondary.UseMilDot then
			-- Draw the MIL DOT SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_scopesight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseSVD then
			-- Draw the SVD SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_svdsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseParabolic then
			-- Draw the PARABOLIC SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_parabolicsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseElcan then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_elcanreticle"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)
			
			-- Draw the ELCAN SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_elcansight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseGreenDuplex then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_nvgilluminatedduplex"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end
			
			if self.Secondary.UseAimpoint then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/aimpoint"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			
			end

			-- CARBY'S NEW SCOPES

			if self.Secondary.UseVortexAMG then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/vortex_amg"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the ELCAN SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseBurrisMTAC then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/burris_mtac"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the ELCAN SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end	

			if self.Secondary.UseRedDotHybrid then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/red_dot_hybrid"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the ELCAN SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end	

			if self.Secondary.UseGreenPin then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/green_pin"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the ELCAN SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_elcansight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end
			
			if self.Secondary.UseMatador then
			
			-- Draw the SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/rocketscope"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX - 1, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)

			end

	end

	-- Chamber indicator and fire mode display handled by lua/m9kr/client/m9kr_hud.lua
end

--[[
	AdjustMouseSensitivity - Reduce mouse sensitivity when scoped
	Called automatically by the engine when the player has this weapon equipped

	Formula: 1 / (ScopeZoom / 2)
	Examples:
	- 4x scope: 1 / (4 / 2) = 1 / 2 = 0.5 (50% sensitivity)
	- 8x scope: 1 / (8 / 2) = 1 / 4 = 0.25 (25% sensitivity)
	- 12x scope: 1 / (12 / 2) = 1 / 6 = 0.166 (16.6% sensitivity)
]]--
function SWEP:AdjustMouseSensitivity()
	if not IsValid(self.Owner) then return 1 end

	-- Only reduce sensitivity when scoped in (ATTACK2 held, not actually sprinting, not using, not on safety)
	-- Only block if player is actually sprinting (not just holding sprint key AND pressing movement keys)
	-- Block sensitivity reduction when on safety or holding USE key
	local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
	local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and self.Owner:IsOnGround() and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement
	if self.Owner:KeyDown(IN_ATTACK2) and not isActuallySprinting and not self.Owner:KeyDown(IN_USE) and not self:GetIsOnSafe() then
		return 1 / (self.Secondary.ScopeZoom / 2)
	end

	return 1
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