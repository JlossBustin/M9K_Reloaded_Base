util.PrecacheModel("models/viper/mw/attachments/crossbow/attachment_vm_sn_crossbow_mag.mdl")

SWEP.Base = "weapon_base"

SWEP.Category = ""
SWEP.Gun = ""
SWEP.Author = "Generic Default, Worshipper, Clavus, and Bob"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.MuzzleAttachment = "1"
SWEP.WMCorrectedMuzzle = false
SWEP.MuzzleFlashType = "rifle"
SWEP.MuzzleFlashTypeSilenced = nil
SWEP.DrawCrosshair = true
SWEP.ShowCrosshairInADS = false
SWEP.ViewModelFOV = 65
SWEP.ViewModelFlip = true
SWEP.WorldModel = ""
SWEP.WorldModelSilenced = nil

SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.Primary.Sound = Sound("")
SWEP.Primary.Round = ""
SWEP.Primary.Cone = 0.2
SWEP.Primary.Recoil = 10
SWEP.Primary.Damage = 10
SWEP.Primary.NumShots = 1
SWEP.Primary.RPM = 0
SWEP.Primary.ClipSize = 0
SWEP.Primary.DefaultClip = 0
SWEP.Primary.KickUp = 0
SWEP.Primary.KickDown = 0
SWEP.Primary.KickHorizontal = 0
SWEP.Primary.Ammo = "none"

SWEP.EmptySoundPlayed = false
SWEP.CanReload = true

SWEP.HasChamber = true
SWEP.ChamberRound = false

SWEP.DisableBulletImpacts = false
SWEP.SoundIndicatorInterval = nil
SWEP.ActionSounds = {}

SWEP.CurrentFireMode = 1
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

SWEP.BurstDelay = 0.05
SWEP.BurstCount = 3
SWEP.BurstTriggerPull = 0.35
 
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
SWEP.NextSafetyToggle = 0
SWEP.OrigCrossHair = true
SWEP.JumpCancelsSprint = true
SWEP.Safety = false
SWEP.ReloadSpeedModifier = 1.0

SWEP.CrouchPos = Vector(0, 1.5, -0.3)
SWEP.CrouchAng = Vector(0, 0, -7)

SWEP.LowAmmoSoundThreshold = 0.33
 
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
 
local function NewM9KDamageMultiplier(cvar, previous, new)
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
 
local function NewDefClips(cvar, previous, new)
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

SWEP.ViewModelPunchPitchMultiplier = 0.5
SWEP.ViewModelPunchYawMultiplier = 0.5
SWEP.ViewModelPunch_VerticalMultiplier = 0.3
SWEP.ViewModelPunch_MaxVerticalOffset = 3

SWEP.ViewPunchP = 0
SWEP.ViewPunchY = 0
SWEP.IronSightsProgress = 0

SWEP.Offset = {
	Pos = {
		Up = 0,
		Right = 0,
		Forward = 0
	},
	Ang = {
		Up = 0,
		Right = 0,
		Forward = 0
	},
	Scale = 1
}

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsSuppressed")
	self:NetworkVar("Bool", 1, "IsAttachingSuppressor")
	self:NetworkVar("Bool", 2, "IsDetachingSuppressor")
	self:NetworkVar("Float", 0, "SuppressorAnimEndTime")
	self:NetworkVar("Bool", 3, "IsOnSafe")
	self:NetworkVar("Int", 0, "M9KRShotsFired")
	self:NetworkVar("String", 0, "M9KRHoldType")

	-- Third-person muzzle flash: fires on ALL clients when shot counter changes
	if CLIENT then
		self:NetworkVarNotify("M9KRShotsFired", self.OnM9KRShotsFiredChanged)
	end
end

-- NetworkVarNotify callback: fires on ALL clients when M9KRShotsFired changes.
-- Spawns third-person muzzle flash for non-owning players in multiplayer.
function SWEP:OnM9KRShotsFiredChanged(name, old, new)
	if game.SinglePlayer() then return end

	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end
	if owner == LocalPlayer() then return end

	local mfCvar = GetConVar("M9KR_MuzzleFlash")
	if not mfCvar or not mfCvar:GetBool() then return end

	local muzzleType = self.MuzzleFlashType or "rifle"
	if self.Silenced and self.MuzzleFlashTypeSilenced then
		muzzleType = self.MuzzleFlashTypeSilenced
	end
	if not muzzleType then return end

	self.m9kr_ActiveMuzzleType = muzzleType

	local fx = EffectData()
	fx:SetEntity(self)
	fx:SetOrigin(owner:GetShootPos())
	fx:SetNormal(owner:GetAimVector())
	fx:SetAttachment(tonumber(self.MuzzleAttachment) or 1)
	util.Effect("m9kr_muzzleflash", fx)

	local smokeCvar = GetConVar("m9kr_muzzlesmoketrail")
	if smokeCvar and smokeCvar:GetInt() == 1 then
		util.Effect("m9kr_muzzlesmoke", fx)
	end
end

function SWEP:UpdateWorldModel()
	if not self.CanBeSilenced or not self.WorldModelSilenced then return end

	if not self.WorldModelOriginal then
		self.WorldModelOriginal = self.WorldModel
	end

	local showSuppressor = false
	if self:GetIsAttachingSuppressor() then
		showSuppressor = false
	elseif self:GetIsDetachingSuppressor() then
		showSuppressor = true
	else
		showSuppressor = self:GetIsSuppressed()
	end

	self.WorldModel = showSuppressor and self.WorldModelSilenced or self.WorldModelOriginal
end

function SWEP:Initialize()
	self.m9kr_TimerID = self:EntIndex() .. "_" .. CurTime()
	self.Reloadaftershoot = 0
	self.OriginalHoldType = self.HoldType or "ar2"
	self:M9KR_SetHoldType(self.HoldType)
	self.OrigCrossHair = self.DrawCrosshair

	self.ChamberRound = false

	if self.SoundIndicatorInterval then
		self.ShotsSinceSoundPlayed = 0
	end

	-- Break metatable chain so child weapons don't share parent's FireModes
	if self.FireModes then
		self.FireModes = table.Copy(self.FireModes)
	end
	
	if self.FireModes then
		-- Restore fire mode from NW var on hot-reload (SWEP table is recreated but NW persists)
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

		-- Shotguns and weapons with PreserveSpreadValues keep their manually-defined spread
		local isShotgun = self.Base == "carby_shotty_base" or self.PreserveSpreadValues
		if not self.Primary.Spread and not isShotgun then
			if mode == "bolt" then
				self.Primary.Spread = .001  -- Bolt-action precision
			end
		end
	else
		self.Primary.Automatic = true
	end

	self.ViewPunchP = 0
	self.ViewPunchY = 0

	self.ShotCount = 0
	self.IronSightsProgress = 0
	self.IronSightsProgressSmooth = 0

	self:SetIsSuppressed(self.Silenced or false)
	self:SetIsOnSafe(self.Safety or false)
	self:UpdateWorldModel()

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

	end
end

function SWEP:Equip()
	self:M9KR_SetHoldType(self.HoldType)
end

function SWEP:Deploy()
	self:SetIronsights(false, self.Owner)
	self:SetSprint(false)
	self:M9KR_SetHoldType(self.HoldType)
	self.BurstShotsRemaining = nil
	self.ContinuousShotCount = 0
	self.RapidFireHeat = 0
	self.LastShotTime = 0
	self.LastTriggerState = false

	self:UpdateWorldModel()

	if self.ChamberRound == nil then
		self.ChamberRound = false
	end
	
	if IsValid(self.Owner) and self.Owner:KeyDown(IN_SPEED) then
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
	
	-- CLIENT:
	if CLIENT then
		self.AnimationTime = 0
		self.BreathIntensity = 0
		self.WalkIntensity = 0
		self.SprintIntensity = 0
		self.JumpVelocitySmooth = 0
		self.LateralVelocity = 0
		self.LateralVelocitySmooth = 0
		self.LastGroundState = true
		self.ADSRecoilIntensity = 0
		self.LastShotTime = 0

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
	
	if not self.FirstDeployDone then
		self.FirstDeployDone = true

		if CLIENT then
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
			if self.Silenced then
				local emptySeq = vm:SelectWeightedSequence(ACT_VM_DRAW_EMPTY)
				if emptySeq and emptySeq > -1 then
					vm:SendViewModelMatchingSequence(emptySeq)
					drawAnim = nil
				end
			else
				local deploySeq = vm:SelectWeightedSequence(ACT_VM_DRAW_DEPLOYED)
				if deploySeq and deploySeq > -1 then
					vm:SendViewModelMatchingSequence(deploySeq)
					drawAnim = nil
				end
			end
		end

		if drawAnim then
			self.Weapon:SendWeaponAnim(drawAnim)
		end
	else
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
	self.BurstShotsRemaining = 0
	self.NextBurstShotTime = nil

	-- Cancel active timers to prevent callbacks after weapon switch
	local reloadTimerName = "M9K_Reload_" .. self.m9kr_TimerID
	if timer.Exists(reloadTimerName) then
		timer.Remove(reloadTimerName)
	end
	
	local sprintTimerName = "M9K_ReloadSprint_" .. self.m9kr_TimerID
	if timer.Exists(sprintTimerName) then
		timer.Remove(sprintTimerName)
	end

	local silencerTimerName = "M9K_Silencer_" .. self.m9kr_TimerID
	if timer.Exists(silencerTimerName) then
		timer.Remove(silencerTimerName)
	end
	
	if IsValid(self.Weapon) then
		self.Weapon:SetNWBool("Reloading", false)
		-- Prevent stuck fire delay after mid-reload weapon swap
		self.Weapon:SetNextPrimaryFire(CurTime())
	end
	
	self.crouchMul = 0
	self.bLastCrouching = false
	self.fCrouchTime = nil

	if CLIENT and IsValid(self.Owner) and not self.Owner:IsNPC() then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetViewModelBones(vm)
		end

		self.m9kr_FOVCurrent = 0
		self.m9kr_FOVTarget = 0
		self.m9kr_IsInADS = false
		self.m9kr_IsInSprint = false
		self.ShouldDrawViewModel = true
	end

	-- Stop action sounds (fire sounds use a separate channel and are not stopped)
	if self.ActionSounds and #self.ActionSounds > 0 then
		for _, soundName in ipairs(self.ActionSounds) do
			if IsValid(self.Weapon) then
				self.Weapon:StopSound(soundName)
			end
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
	-- Clean up all active timers
	local timerName = "M9K_Burst_" .. self.m9kr_TimerID
	if timer.Exists(timerName) then
		timer.Remove(timerName)
	end
	
	local reloadTimerName = "M9K_Reload_" .. self.m9kr_TimerID
	if timer.Exists(reloadTimerName) then
		timer.Remove(reloadTimerName)
	end
	
	local sprintTimerName = "M9K_ReloadSprint_" .. self.m9kr_TimerID
	if timer.Exists(sprintTimerName) then
		timer.Remove(sprintTimerName)
	end
	
	local silencerTimerName = "M9K_Silencer_" .. self.m9kr_TimerID
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

-- Override CanPrimaryAttack
function SWEP:CanPrimaryAttack()
	if self.Weapon:Clip1() <= 0 then
		self.ChamberRound = false

		if self.Owner:GetAmmoCount(self.Weapon:GetPrimaryAmmoType()) > 0 then
			if not self.Weapon:GetNWBool("Reloading") then
				self:Reload()
			end
		end
		return false
	end
	return true
end

function SWEP:HasSequence(activityID)	
	if not activityID or not IsValid(self) or not IsValid(self.Owner) then return false end

	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then return false end

	local seqID = vm:SelectWeightedSequence(activityID)
	local hasSeq = seqID and seqID > 0 and seqID ~= -1
	
	return hasSeq
end

function SWEP:HasSequenceByName(sequenceName)
	if not sequenceName or not IsValid(self) or not IsValid(self.Owner) then return false end

	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then return false end

	local seqID = vm:LookupSequence(sequenceName)
	return seqID and seqID > 0 and seqID ~= -1
end

function SWEP:FireBurstShot()
	if not IsValid(self) or not IsValid(self.Weapon) or not IsValid(self.Owner) then
		self.BurstShotsRemaining = 0
		return
	end

	if self.Weapon:Clip1() <= 0 then
		self.BurstShotsRemaining = 0
		return
	end

	-- Cancel burst if player starts sprinting
	local isSprintJumping = self.Owner:KeyDown(IN_SPEED) and not self.Owner:IsOnGround()
	local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
	local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and self.Owner:IsOnGround() and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement
	if isActuallySprinting and not isSprintJumping then
		self.BurstShotsRemaining = 0
		return
	end
	
	self:ShootBulletInformation()
	self.Weapon:TakePrimaryAmmo(1)

	-- In SP, SERVER must also call since CLIENT prediction may not run
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
	
	self:M9KR_SpawnMuzzleFlash()
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self:M9KR_SpawnShellEject()

	-- Can be nil if weapon was switched mid-burst
	if not self.BurstShotsRemaining then return end
	self.BurstShotsRemaining = self.BurstShotsRemaining - 1
	if self.BurstShotsRemaining > 0 then
		self.NextBurstShotTime = CurTime() + (self.BurstDelay or 0.05)
	end
end

function SWEP:PrimaryAttack()
	if not IsValid(self) or not IsValid(self.Weapon) or not IsValid(self.Owner) then
		return
	end

	if self:GetIsOnSafe() then
		return
	end

	if self:CanPrimaryAttack() and self.Owner:IsPlayer() then
		local isSprintJumping = self.Owner:KeyDown(IN_SPEED) and not self.Owner:IsOnGround()
		local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
		local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and self.Owner:IsOnGround() and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement

		if (not isActuallySprinting or isSprintJumping) and not self.Owner:KeyDown(IN_RELOAD) then
			-- Burst handling
			if self:IsFireModeBurst() then
				if self.BurstShotsRemaining and self.BurstShotsRemaining > 0 then
					return
				end
				
				local clips = self.Weapon:Clip1()
				local shotsToFire = math.min(self.BurstCount or 3, clips or 0)
				if shotsToFire <= 0 then
					return
				end
				
				self.BurstShotsRemaining = shotsToFire - 1
				
				self:ShootBulletInformation()
				self.Weapon:TakePrimaryAmmo(1)

				if CLIENT or (game.SinglePlayer() and SERVER) then
					self.LastShotTime = CurTime()
					if self.CheckLowAmmo then self:CheckLowAmmo() end
				end

				local bIron = self.Owner:KeyDown(IN_ATTACK2)
				local shootAnim = ACT_VM_PRIMARYATTACK

				if self.Silenced then
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
						if bIron and self:HasSequence(ACT_VM_PRIMARYATTACK_1) then
								self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_1)
						else
								self.Weapon:SendWeaponAnim(shootAnim)
						end
						self:EmitSound(self.Primary.Sound or "")
				end
				-- Muzzle flash and shell eject
				self:M9KR_SpawnMuzzleFlash()
				self.Owner:SetAnimation(PLAYER_ATTACK1)
				self:M9KR_SpawnShellEject()

				if self.BurstShotsRemaining > 0 then
					self.NextBurstShotTime = CurTime() + (self.BurstDelay or 0.05)
				end

				-- Fire rate timing with tick compensation
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
			-- Single-shot path
			else
				self:ShootBulletInformation()
				self.Weapon:TakePrimaryAmmo(1)
				
				if self.HasChamber and self.Weapon:Clip1() > 0 then
					self.ChamberRound = true
				elseif self.Weapon:Clip1() == 0 then
					self.ChamberRound = false
				end
				
			if CLIENT or (game.SinglePlayer() and SERVER) then
				self.LastShotTime = CurTime()
				if self.CheckLowAmmo then self:CheckLowAmmo() end
			end

			local bIron = self.Owner:KeyDown(IN_ATTACK2)
			local shootAnim = ACT_VM_PRIMARYATTACK

				if self.Silenced then
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
					if bIron and self:HasSequence(ACT_VM_PRIMARYATTACK_1) then
							self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_1)
					else
							self.Weapon:SendWeaponAnim(shootAnim)
					end
					self:EmitSound(self.Primary.Sound)
				end
				-- Muzzle flash and shell eject
				self:M9KR_SpawnMuzzleFlash()
				self.Owner:SetAnimation(PLAYER_ATTACK1)
				self:M9KR_SpawnShellEject()

				-- Fire rate timing with tick compensation
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
		end
	elseif self:CanPrimaryAttack() and self.Owner:IsNPC() then
		self:ShootBulletInformation()
		self.Weapon:TakePrimaryAmmo(1)
		self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		self:EmitSound(self.Primary.Sound)
		self.Owner:SetAnimation(PLAYER_ATTACK1)

		-- Fire rate timing with tick compensation
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

-- Deferred effects: SP creates immediately; MP queues for render time (FireAnimationEvent/PostDrawViewModel).
-- MP third-person uses NetworkVarNotify on shot counter (fires on all clients); holdtype is synced via M9KRHoldType NetworkVar.

-- SetHoldType wrapper that also networks hold type to all clients
function SWEP:M9KR_SetHoldType(holdType)
	self:SetHoldType(holdType)
	if SERVER and self.SetM9KRHoldType then
		self:SetM9KRHoldType(holdType)
	end
end

function SWEP:M9KR_SpawnMuzzleFlash()
	local mfCvar = GetConVar("M9KR_MuzzleFlash")
	if not mfCvar or not mfCvar:GetBool() then return end

	local muzzleType = self.MuzzleFlashType or "rifle"
	if self.Silenced and self.MuzzleFlashTypeSilenced then
		muzzleType = self.MuzzleFlashTypeSilenced
	end
	if not muzzleType then return end

	self.m9kr_ActiveMuzzleType = muzzleType

	local smokeCvar = GetConVar("m9kr_muzzlesmoketrail")
	local doSmoke = smokeCvar and smokeCvar:GetInt() == 1

	-- SP
	if game.SinglePlayer() and SERVER then
		local fx = EffectData()
		fx:SetEntity(self)
		fx:SetOrigin(self.Owner:GetShootPos())
		fx:SetNormal(self.Owner:GetAimVector())
		fx:SetAttachment(tonumber(self.MuzzleAttachment) or 1)
		util.Effect("m9kr_muzzleflash", fx)
		if doSmoke then util.Effect("m9kr_muzzlesmoke", fx) end
		return
	end

	-- MP: increment shot counter
	if SERVER then
		local count = self:GetM9KRShotsFired() or 0
		self:SetM9KRShotsFired(count + 1)
	end

	-- MP CLIENT: queue deferred flash
	if CLIENT then
		if not IsFirstTimePredicted() then return end
		self.m9kr_PendingMuzzleFlash = {smoke = doSmoke, time = CurTime()}
	end
end

function SWEP:M9KR_SpawnShellEject()
	if self.NoShellEject then return end
	if CLIENT then
		if not IsValid(self) or not IsValid(self.Owner) then return end
		if self.Owner ~= LocalPlayer() then return end
		if not self.ShellModel then return end

		if not game.SinglePlayer() and not IsFirstTimePredicted() then return end
		self.m9kr_PendingShellEject = true
		self.m9kr_PendingShellEjectTime = CurTime()
	end
end

-- EjectShell() is defined in cl_init.lua (CLIENT-only viewmodel effect)

function SWEP:FireAnimationEvent(pos, ang, event, options)
	-- Block muzzle flash events: 21 (primary), 22 (secondary), 5001 (CS:S), 5011 (DoD:S), 5021 (TF2), 6001 (attachment)
	if event == 21 or event == 22 or event == 5001 or event == 5011 or event == 5021 or event == 6001 then
		-- Create deferred muzzle flash; mark model as having QC muzzle events
		if CLIENT then self.m9kr_HasQCMuzzleEvent = true end
		if CLIENT and self.m9kr_PendingMuzzleFlash then
			local pending = self.m9kr_PendingMuzzleFlash
			self.m9kr_PendingMuzzleFlash = nil

			local fx = EffectData()
			fx:SetEntity(self.Weapon)
			fx:SetOrigin(pos)
			fx:SetNormal(ang:Forward())
			fx:SetAttachment(self.MuzzleAttachment)

			util.Effect("m9kr_muzzleflash", fx)
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

			-- Parse QC params: "EjectBrass_556 3 90" -> extract attachment ID
			local parts = {}
			for part in string.gmatch(optStr, "%S+") do
				table.insert(parts, part)
			end

			if parts[2] then
				self._qcShellAttachment = tonumber(parts[2])
			end

			-- Eject shell at render time (attachment positions are reliable here)
			if self.m9kr_PendingShellEject or game.SinglePlayer() then
				self.m9kr_PendingShellEject = nil
				self.m9kr_PendingShellEjectTime = nil
				self:EjectShell()
			end
		end
		return true -- Block default brass
	end

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

function SWEP:ShootBulletInformation()
	local CurrentDamage, CurrentRecoil, CurrentCone

	self.ContinuousShotCount = (self.ContinuousShotCount or 0) + 1

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

	CurrentCone = self:GetDynamicSpread()

	local damagedice = math.Rand(0.85, 1.3)
	local basedamage = PainMulti * self.Primary.Damage
	CurrentDamage = basedamage * damagedice
	CurrentRecoil = self.Primary.Recoil

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

	local origKickUp = self.Primary.KickUp
	local origKickDown = self.Primary.KickDown
	local origKickHorizontal = self.Primary.KickHorizontal

	-- Check if fully crouched and grounded
	local isFullyCrouched = false
	if self.Owner:IsPlayer() and self.Owner:Crouching() and self.Owner:IsOnGround() then
		local currentViewZ = self.Owner:GetViewOffset().z
		local duckedViewZ = self.Owner:GetViewOffsetDucked().z
		isFullyCrouched = (currentViewZ <= duckedViewZ + 1)
	end

	-- Crouch modifiers
	if isFullyCrouched then
		self.Primary.KickUp = origKickUp * 0.75
		self.Primary.KickDown = origKickDown * 0.90
		self.Primary.KickHorizontal = origKickHorizontal * 0.90
	end

	if isInADS and self.Owner:KeyDown(IN_ATTACK2) then
		self.Primary.KickDown = self.Primary.KickDown * 0.25
		self.Primary.KickHorizontal = self.Primary.KickHorizontal * 0.25

		-- ADS recoil reduction
		self:ShootBullet(CurrentDamage, CurrentRecoil / 6, self.Primary.NumShots, CurrentCone)
	-- Player is not aiming
	else
		if IsValid(self) and IsValid(self.Weapon) and IsValid(self.Owner) then
			self:ShootBullet(CurrentDamage, CurrentRecoil, self.Primary.NumShots, CurrentCone)
		end
	end

	self.Primary.KickUp = origKickUp
	self.Primary.KickDown = origKickDown
	self.Primary.KickHorizontal = origKickHorizontal

end
 
function SWEP:ShootBullet(damage, recoil, num_bullets, aimcone)

	num_bullets             = num_bullets or 1
	aimcone                         = aimcone or 0

	self:ShootEffects()

	self.ShotCount = (self.ShotCount or 0) + 1

	local shouldShowTracer = false
	local tracerName = "Tracer"
	local tracerType = 0
	local tracerData = nil

	-- Disable tracers for shotgun pellets and NoTracers weapons
	local isShotgunPellets = (num_bullets > 1)

	if M9KR and M9KR.Tracers and M9KR.Tracers.ShouldShowTracer and not isShotgunPellets and not self.NoTracers then
		shouldShowTracer, tracerName = M9KR.Tracers.ShouldShowTracer(self, self.ShotCount)

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
		if shouldShowTracer and M9KR and M9KR.Tracers and M9KR.Tracers.SpawnTracerEffect then
			M9KR.Tracers.SpawnTracerEffect(self, tracedata.HitPos, tracerData)

		end

		-- Bullet impact effects (CLIENT only)
		if CLIENT and IsFirstTimePredicted() and tracedata.HitPos and not self.DisableBulletImpacts then
			local impactCvar = GetConVar("m9kr_bullet_impact")
			local metalCvar = GetConVar("m9kr_metal_impact")
			local dustCvar = GetConVar("m9kr_dust_impact")

			if impactCvar and impactCvar:GetInt() == 1 then
				local fx = EffectData()
				fx:SetOrigin(tracedata.HitPos)
				fx:SetNormal(tracedata.HitNormal or Vector(0, 0, 1))

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

		if self.Penetration and IsFirstTimePredicted() then
			-- Construct paininfo table from dmginfo object
			local paininfo = {
				Damage = dmginfo:GetDamage(),
				Force = dmginfo:GetDamageForce()
			}
			self:BulletPenetrate(0, attacker, tracedata, paininfo)
		end

		-- Arrow impact for non-penetrating weapons
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

	local kickPitch = math.Rand(-self.Primary.KickDown, -self.Primary.KickUp)
	local kickYaw = math.Rand(-self.Primary.KickHorizontal, self.Primary.KickHorizontal)

	local anglo1 = Angle(kickPitch, kickYaw, 0)
	if self.Owner:IsPlayer() then
		self.Owner:ViewPunch(anglo1)

		self.ViewPunchP = (self.ViewPunchP or 0) + kickPitch
		self.ViewPunchY = (self.ViewPunchY or 0) + kickYaw

		local eyes = self.Owner:EyeAngles()
		eyes.pitch = math.Clamp(eyes.pitch + kickPitch, -89, 89)  -- Clamp to prevent overflow
		eyes.yaw = eyes.yaw + kickYaw
		self.Owner:SetEyeAngles(eyes)
	end
end

function SWEP:SpawnImpactArrow(hitData)
	if not hitData or not hitData.pos then return end

	local arrow = ents.Create("prop_dynamic")
	if not IsValid(arrow) then return end

	arrow:SetModel("models/viper/mw/attachments/crossbow/attachment_vm_sn_crossbow_mag.mdl")

	local dir = hitData.dir or Vector(0, 0, 0)
	arrow:SetPos(hitData.pos - dir * 6)
	arrow:SetAngles(dir:Angle())

	arrow:Spawn()
	arrow:Activate()

	arrow:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

	if IsValid(hitData.ent) and hitData.ent:GetClass() != "worldspawn" then
		arrow:SetParent(hitData.ent)
	end

	SafeRemoveEntityDelayed(arrow, 10)
end

function SWEP:BulletPenetrate(bouncenum, attacker, tr, paininfo)
	local res = false
	if M9KR and M9KR.Penetration and M9KR.Penetration.CalculatePenetration then
		local ok, penResult = pcall(M9KR.Penetration.CalculatePenetration, self, bouncenum, attacker, tr, paininfo)
		if not ok then
			res = false
		else
			res = penResult
		end
	end

	-- Spawn arrow if bullet stopped
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

	if self:GetIsOnSafe() or self.Owner:KeyDown(IN_USE) then
		return
	end

	-- Cooldown after safety/fire mode toggle
	if self.NextSafetyToggle and CurTime() < self.NextSafetyToggle then
		return
	end
	if self.NextFireSelect and CurTime() < self.NextFireSelect then
		return
	end

	if self.Weapon:GetNWBool("Reloading") then
		return
	end

	self.BurstShotsRemaining = nil

	self.ShotCount = 0
	
	if self.Owner:IsNPC() then
		self.Weapon:DefaultReload(ACT_VM_RELOAD)
		return
	end
	
	if self.Owner:KeyDown(IN_USE) then
		return
	end
	
	-- Chamber +1 reload
	local currentClip = self:Clip1()
	local maxClip = self.Primary.ClipSize
	local reserveAmmo = self.Owner:GetAmmoCount(self.Weapon:GetPrimaryAmmoType())
	local isEmpty = currentClip == 0
	
	if self.HasChamber and not self.noChamber then
		if currentClip >= maxClip + 1 then
			return
		end
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

		self:SetIronsights(false)

		-- Handle the +1 ammo after animation completes
		local waitdammit = self.Owner:GetViewModel():SequenceDuration() / (self.ReloadSpeedModifier or 1)
		local reloadTimerName = "M9K_Reload_" .. self.m9kr_TimerID
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

			-- IronSight's ResetSights handler already sent IDLE at T+animDur
			-- No SendWeaponAnim here — avoids overriding any subsequent reload animation
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

	-- Chamber +1 tracking
	if self.HasChamber and not isEmpty then
		self.ChamberRound = true
	elseif self.HasChamber and isEmpty then
		self.ChamberRound = false
	else
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

	if self.Weapon:Clip1() < self.Primary.ClipSize and not self.Owner:IsNPC() then
		self:SetIronsights(false)
		self.Weapon:SetNWBool("Reloading", true)

		-- Show reload animation to other players
		self.Owner:SetAnimation(PLAYER_RELOAD)
	end

	if SERVER and IsValid(self.Weapon) then
		local waitdammit = self.Owner:GetViewModel():SequenceDuration() / (self.ReloadSpeedModifier or 1)
		local reloadTimerName = "M9K_Reload_" .. self.m9kr_TimerID
		timer.Create(reloadTimerName, waitdammit + 0.1, 1, function()
			if not IsValid(self.Weapon) or not IsValid(self.Owner) then
				return
			end
			
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

			-- IronSight's ResetSights handler already sent IDLE at T+animDur
			-- No SendWeaponAnim here — avoids overriding follow-up +1 reload animation

			-- Check if player wants to sprint/ADS after reload
			if self.Owner:KeyDown(IN_SPEED) and self.Weapon:GetClass() == self.Gun then
				if SERVER then
					if self.Weapon:GetNextPrimaryFire() <= (CurTime() + 0.03) then
						self.Weapon:SetNextPrimaryFire(CurTime() + 0.3)
					end
					self:SetIronsights(false)
					
					-- Delay sprint transition for smoother feel
					-- Gun goes to idle first, then transitions to sprint after 0.35 seconds
					-- This gives enough time for the viewmodel to settle before entering sprint
					-- Mark that we're in post-reload transition to prevent lateral tilt issues
					self.Weapon:SetNWFloat("PostReloadTransition", CurTime() + 0.35)
					
					local sprintTimerName = "M9K_ReloadSprint_" .. self.m9kr_TimerID
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
					self:SetSprint(false)
					self:SetIronsights(true, self.Owner)
				else
					return
				end
			else
				if SERVER then
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
				if SERVER and self.Scoped == false then
						self:SetSprint(false)
						self:SetIronsights(true, self.Owner)
						self.DrawCrosshair = false
				end
		elseif self.Owner:KeyDown(IN_SPEED) and self.Owner:GetVelocity():Length2D() > 20 and self.Weapon:GetClass() == self.Gun then
				-- Only enter sprint animation if player is actually moving
				if self.Weapon:GetNextPrimaryFire() <= (CurTime() + .03) then
						self.Weapon:SetNextPrimaryFire(CurTime()+0.3)
				end
				self:SetIronsights(false)
				self:SetSprint(true)
		end
end
 
function SWEP:Silencer()
	if self.NextSilence > CurTime() then return end

	if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end

	self:SetIronsights(false)

	if not self.OriginalHoldType then
		self.OriginalHoldType = self.HoldType or "ar2"
	end

	local isAttaching = not self.Silenced

	self:M9KR_SetHoldType("passive")

	if isAttaching then
		-- ATTACHING SUPPRESSOR
		self:SendWeaponAnim(ACT_VM_ATTACH_SILENCER)
		self.Silenced = true
		self:SetIsSuppressed(true)  -- Network suppressor state (will be visible after animation)

		self:SetIsAttachingSuppressor(true)
		self:SetIsDetachingSuppressor(false)
	else
		-- DETACHING SUPPRESSOR
		self:SendWeaponAnim(ACT_VM_DETACH_SILENCER)
		self.Silenced = false
		self:SetIsSuppressed(false)  -- Network suppressor state (will be hidden after animation)

		self:SetIsAttachingSuppressor(false)
		self:SetIsDetachingSuppressor(true)
	end

	local animDuration = self.Owner:GetViewModel():SequenceDuration() + 0.1
	local animEndTime = CurTime() + animDuration

	self:SetSuppressorAnimEndTime(animEndTime)

	if self.Weapon:GetNextPrimaryFire() <= animEndTime then
		self.Weapon:SetNextPrimaryFire(animEndTime)
	end
	self.NextSilence = animEndTime

	self:UpdateWorldModel()

	local silencerTimerName = "M9K_Silencer_" .. self.m9kr_TimerID
	timer.Create(silencerTimerName, animDuration, 1, function()
		if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end

		-- Restore hold type
		self:M9KR_SetHoldType(self.OriginalHoldType or self.HoldType)

		self:SetIsAttachingSuppressor(false)
		self:SetIsDetachingSuppressor(false)

		-- Update world model
		self:UpdateWorldModel()

		-- Handle player input after animation completes
		if self.Owner:KeyDown(IN_ATTACK2) and self.Weapon:GetClass() == self.Gun then
			if SERVER and self.Scoped == false then
				self:SetSprint(false)
				self:SetIronsights(true, self.Owner)
				self.DrawCrosshair = false
			end
		elseif self.Owner:KeyDown(IN_SPEED) and self.Owner:GetVelocity():Length2D() > 20 and self.Weapon:GetClass() == self.Gun then
			-- Only enter sprint animation if player is actually moving
			if self.Weapon:GetNextPrimaryFire() <= (CurTime() + 0.3) then
				self.Weapon:SetNextPrimaryFire(CurTime() + 0.3)
			end
			self:SetIronsights(false)
			self:SetSprint(true)
		end
	end)
end
 
function SWEP:SafetyToggle()
	if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end

	-- Cooldown
	if self.NextSafetyToggle > CurTime() then return end
	self.NextSafetyToggle = CurTime() + 0.6

	if SERVER then
		local newSafetyState = not self:GetIsOnSafe()
		self:SetIsOnSafe(newSafetyState)

		if newSafetyState then
			self:SetIronsights(false)
			self:SetSprint(false)
		else
			self:SetNextPrimaryFire(CurTime() + 0.5)
		end
	end

	if CLIENT then
		local newSafetyState = not self:GetIsOnSafe()

		self.Weapon:EmitSound("Weapon_AR2.Empty")

		self:SetIronsights(false)
		self:SetSprint(false)

		if newSafetyState then
			-- Hide crosshair
			self.DrawCrosshair = false

			self.fSafetyTime = CurTime()
			self.bLastSafety = true
		else
			self.fIdleTime = CurTime()
			self.bLastSafety = false

			self.DrawCrosshair = self.OrigCrossHair
		end
	end
end

function SWEP:SafetyOn()
	if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end
	if self:GetIsOnSafe() then return end  -- Already in safety

	-- Cooldown check
	if self.NextSafetyToggle > CurTime() then return end
	self.NextSafetyToggle = CurTime() + 0.6

	self.FireModeBeforeSafety = self.CurrentFireMode or 1

	if SERVER then
		self:SetIsOnSafe(true)
		self:SetIronsights(false)
		self:SetSprint(false)
	end

	if CLIENT then
		self.Weapon:EmitSound("Weapon_AR2.Empty")
		self:SetIronsights(false)
		self:SetSprint(false)
		self.DrawCrosshair = false
		self.fSafetyTime = CurTime()
		self.bLastSafety = true
		self.SafetyToggleTime = CurTime()
	end
end

function SWEP:SafetyOff()
	if not IsValid(self.Weapon) or not IsValid(self.Owner) then return end
	if not self:GetIsOnSafe() then return end  -- Not in safety

	-- Cooldown check
	if self.NextSafetyToggle > CurTime() then return end
	self.NextSafetyToggle = CurTime() + 0.6

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

	self.NextFireSelect = CurTime() + 0.5

	if CLIENT then
		self.Weapon:EmitSound("Weapon_AR2.Empty")
		self.fIdleTime = CurTime()
		self.bLastSafety = false
		self.DrawCrosshair = self.OrigCrossHair
		self.SafetyToggleTime = CurTime()
	end
end

function SWEP:SelectFireMode()
	if self.NextFireSelect and CurTime() < self.NextFireSelect then return end
	self.NextFireSelect = CurTime() + 0.5

	if self:GetFireModeCount() <= 1 then return end

	-- Cycle to the next fire mode
	self:CycleFireMode()
end

function SWEP:IronSight()
	if not IsValid(self) or not IsValid(self.Owner) then
		return
	end

	if not self.Owner:IsNPC() then
		if self.ResetSights and CurTime() >= self.ResetSights then
			self.ResetSights = nil

			if self.Silenced then
				self:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
			else
				self:SendWeaponAnim(ACT_VM_IDLE)
			end
		end
	end

	-- Safety/fire mode controls: SHIFT+E+R = safety, E+R = toggle safety or cycle mode
	if SERVER and self.Owner:KeyDown(IN_USE) and self.Owner:KeyPressed(IN_RELOAD) then
		if self:GetIsOnSafe() then
			self:SafetyOff()
		elseif self.Owner:KeyDown(IN_SPEED) then
			self:SafetyOn()
		elseif not self.Weapon:GetNWBool("Reloading", false) then
			self:SelectFireMode()
		end
	end

	if CLIENT then
		local currentSafety = self:GetIsOnSafe()
		if self.LastSafetyState == nil then
			self.LastSafetyState = currentSafety
		elseif self.LastSafetyState ~= currentSafety then
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

	-- Suppressor toggle
	if not self:GetIsOnSafe() and self.CanBeSilenced and self.NextSilence < CurTime() and not self.Weapon:GetNWBool("Reloading") then
		if self.Owner:KeyDown(IN_USE) and self.Owner:KeyPressed(IN_ATTACK2) then
			self:Silencer()
		end
	end

	local isInADS = CLIENT and (self.m9kr_IsInADS or false) or false

	if isInADS and self.Owner:KeyDown(IN_ATTACK2) and not self.Owner:KeyDown(IN_USE) and not self:GetIsOnSafe() and not self.Owner:KeyDown(IN_SPEED) then
		self.SwayScale = 0.05
		self.BobScale = 0.05
	else
		self.SwayScale = 1.0
		self.BobScale = 0.1
	end
end

function SWEP:UpdateSafetyHoldType()
	if not self.GetIsOnSafe then return end

	local isSafe = self:GetIsOnSafe()

	if isSafe then
		local safeHoldType = "passive"
		if self.OriginalHoldType == "pistol" or self.OriginalHoldType == "revolver" then
			safeHoldType = "normal"
		end
		if self.HoldType ~= safeHoldType then
			self:M9KR_SetHoldType(safeHoldType)
		end
	else
		local targetHoldType = self.OriginalHoldType or "ar2"
		if self.HoldType ~= targetHoldType then
			self:M9KR_SetHoldType(targetHoldType)
		end
	end

	if CLIENT then
		if self.m9kr_LastSafetyHoldTypeState == nil then
			self.m9kr_LastSafetyHoldTypeState = isSafe
		elseif self.m9kr_LastSafetyHoldTypeState ~= isSafe then
			self.m9kr_SafetyTransitionStart = CurTime()
			self.m9kr_LastSafetyHoldTypeState = isSafe
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

	local triggerDown = self.Owner:KeyDown(IN_ATTACK)
	if self.LastTriggerState and not triggerDown then
		self.ContinuousShotCount = 0
	end
	self.LastTriggerState = triggerDown

	-- Sync CLIENT Primary.Automatic with SERVER fire mode
	if CLIENT and self.FireModes then
		local networkedMode = self.Weapon:GetNWInt("CurrentFireMode", 0)
		if networkedMode > 0 and self.FireModes[networkedMode] then
			self.Primary.Automatic = (self.FireModes[networkedMode] == "auto")
		end
	end

	-- Process burst fire
	if self.BurstShotsRemaining and self.BurstShotsRemaining > 0 and self.NextBurstShotTime and CurTime() >= self.NextBurstShotTime then
		self:FireBurstShot()
	end

	-- Store viewmodel reference
	if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() then
		self.OwnerViewModel = self.Owner:GetViewModel()

		self:UpdateWeaponInputState()

		-- Guard against prediction double-advance
		local curFrame = FrameNumber()
		if self.m9kr_LastProgressFrame ~= curFrame then
			self.m9kr_LastProgressFrame = curFrame

			self:UpdateProgressRatios()
		end

		-- SP: detect ammo decrease for low ammo sounds
		if game.SinglePlayer() and self.CheckLowAmmo then
			local currentClip = self:Clip1()
			if self.m9kr_LastClipForLowAmmo and currentClip < self.m9kr_LastClipForLowAmmo then
				self.LastShotTime = CurTime()
				self:CheckLowAmmo()
			end
			self.m9kr_LastClipForLowAmmo = currentClip
		end

		-- Belt-fed display update
		self:UpdateBeltAmmo()
	end

	-- Recoil decay
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

	-- Suppressor animation backup completion
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

	-- Sprint-jump detection
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