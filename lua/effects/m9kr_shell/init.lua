--[[
	M9K Reloaded - Shell Ejection Effect
	Adapted from TFA Realistic Muzzleflashes shell ejection system

	Features:
	- Physical shell casings with realistic ejection physics
	- Smoke trails from hot brass
	- Collision sounds from FAS2 (caliber-specific)
	- Uses M9K Reloaded's extensive shell model library
	- Integrates with ballistics database for intelligent scaling
]]--

EFFECT.Velocity = {120, 160}
EFFECT.VelocityRand = {-15, 40}
EFFECT.VelocityAngle = Vector(1, 1, 10)
EFFECT.VelocityRandAngle = Vector(10, 10, 5)

-- FAS2 collision sounds (caliber-specific)
EFFECT.ShellSounds_Rifle = {
	"fas2/casings/casings_rifle1.wav", "fas2/casings/casings_rifle2.wav",
	"fas2/casings/casings_rifle3.wav", "fas2/casings/casings_rifle4.wav",
	"fas2/casings/casings_rifle5.wav", "fas2/casings/casings_rifle6.wav",
	"fas2/casings/casings_rifle7.wav", "fas2/casings/casings_rifle8.wav",
	"fas2/casings/casings_rifle9.wav", "fas2/casings/casings_rifle10.wav",
	"fas2/casings/casings_rifle11.wav", "fas2/casings/casings_rifle12.wav"
}

EFFECT.ShellSounds_Pistol = {
	"fas2/casings/casings_pistol1.wav", "fas2/casings/casings_pistol2.wav",
	"fas2/casings/casings_pistol3.wav", "fas2/casings/casings_pistol4.wav",
	"fas2/casings/casings_pistol5.wav", "fas2/casings/casings_pistol6.wav",
	"fas2/casings/casings_pistol7.wav", "fas2/casings/casings_pistol8.wav",
	"fas2/casings/casings_pistol9.wav", "fas2/casings/casings_pistol10.wav",
	"fas2/casings/casings_pistol11.wav", "fas2/casings/casings_pistol12.wav"
}

EFFECT.ShellSounds_Shotgun = {
	"fas2/casings/shells_12g1.wav", "fas2/casings/shells_12g2.wav",
	"fas2/casings/shells_12g3.wav", "fas2/casings/shells_12g4.wav",
	"fas2/casings/shells_12g5.wav", "fas2/casings/shells_12g6.wav",
	"fas2/casings/shells_12g7.wav", "fas2/casings/shells_12g8.wav",
	"fas2/casings/shells_12g9.wav", "fas2/casings/shells_12g10.wav",
	"fas2/casings/shells_12g11.wav", "fas2/casings/shells_12g12.wav"
}

EFFECT.ShellSounds_Heavy = {
	"fas2/casings/casings_50bmg1.wav", "fas2/casings/casings_50bmg2.wav",
	"fas2/casings/casings_50bmg3.wav", "fas2/casings/casings_50bmg4.wav",
	"fas2/casings/casings_50bmg5.wav", "fas2/casings/casings_50bmg6.wav",
	"fas2/casings/casings_50bmg7.wav", "fas2/casings/casings_50bmg8.wav",
	"fas2/casings/casings_50bmg9.wav", "fas2/casings/casings_50bmg10.wav",
	"fas2/casings/casings_50bmg11.wav", "fas2/casings/casings_50bmg12.wav"
}

EFFECT.SoundLevel = {55, 65}
EFFECT.SoundPitch = {80, 120}
EFFECT.SoundVolume = {1.0, 1.15}
EFFECT.LifeTime = 15
EFFECT.FadeTime = 0.5
EFFECT.SmokeTime = {1, 1}  -- 1 second duration
EFFECT.SmokeParticleTrail = "tfa_ins2_weapon_shell_smoke"  -- Dark, visible smoke (same as muzzle trail)

local upVec = Vector(0, 0, 1)

--[[
	Determine appropriate collision sounds based on shell model
	Uses same logic as carby_gun_base's GetShellSoundsForModel
]]--
function EFFECT:GetShellSoundsForModel(shellModel)
	if not shellModel then return self.ShellSounds_Rifle end

	local modelLower = string.lower(shellModel)

	-- PISTOL CALIBERS (9mm, .45 ACP, .357 Mag, .50 AE, 5.7x28mm)
	if string.find(modelLower, "9x18mm") or string.find(modelLower, "9x19mm") or
	   string.find(modelLower, "45acp") or string.find(modelLower, "357mag") or
	   string.find(modelLower, "50ae") or string.find(modelLower, "5_7x28mm") then
		return self.ShellSounds_Pistol
	end

	-- HEAVY/MAGNUM CALIBERS (.454 Casull, .408 CheyTac, .338 Lapua, .300 Win Mag, .50 BMG, 12.7x55mm, 23mm)
	if string.find(modelLower, "454casull") or string.find(modelLower, "408cheytac") or
	   string.find(modelLower, "338lapua") or string.find(modelLower, "338mag") or
	   string.find(modelLower, "300win") or string.find(modelLower, "50bmg") or
	   string.find(modelLower, "12_7x55mm") or string.find(modelLower, "23mm") then
		return self.ShellSounds_Heavy
	end

	-- SHOTGUN SHELLS (12 gauge variations, 13 gauge, 38 gauge)
	if string.find(modelLower, "12g_") or string.find(modelLower, "12gauge") or
	   string.find(modelLower, "13gauge") or string.find(modelLower, "38gauge") then
		return self.ShellSounds_Shotgun
	end

	-- RIFLE CALIBERS (5.56mm, 7.62mm variants, 5.45mm, 9x39mm, etc.)
	-- Default to rifle sounds for standard intermediate/full-power rifle calibers
	return self.ShellSounds_Rifle
end

--[[
	Calculate dynamic lighting for smoke particles
	Enhanced visibility with brighter minimum values
]]--
function EFFECT:ComputeSmokeLighting()
	if not self.PCFSmoke then return end

	local licht = render.ComputeLighting(self:GetPos() + upVec * 2, upVec)
	local lichtFloat = math.Clamp((licht.r + licht.g + licht.b) / 3, 0, 1)
	-- Increased minimum from 0.3 to 0.6 for better visibility in dark areas
	local lichtMin = Vector(0.6, 0.6, 0.6)
	local lichtMax = Vector(1, 1, 1)
	local lichtFinal = LerpVector(lichtFloat, lichtMin, lichtMax)

	self.PCFSmoke:SetControlPoint(1, lichtFinal)
end


function EFFECT:Init(data)
	self.IsM9KRShell = true

	self.StartTime = CurTime()
	self.Emitter = ParticleEmitter(self:GetPos())
	self.SmokeDelta = 0

	-- Smoke enabled by default, lasts 3 seconds
	self.SmokeDeath = self.StartTime + math.Rand(self.SmokeTime[1], self.SmokeTime[2])

	self.WeaponEnt = data:GetEntity()

	if not IsValid(self.WeaponEnt) then
		return
	end

	self.WeaponEntOG = self.WeaponEnt
	self.Attachment = data:GetAttachment()
	self.Dir = data:GetNormal()
	self.DirAng = data:GetNormal():Angle()
	self.OriginalOrigin = data:GetOrigin()

	local owent = self.WeaponEnt:GetOwner()

	if self.LifeTime <= 0 or not IsValid(owent) then
		self.StartTime = -1000
		self.SmokeDeath = -1000
		return
	end

	-- For first-person, use viewmodel
	if owent:IsPlayer() and owent == GetViewEntity() and not owent:ShouldDrawLocalPlayer() then
		self.WeaponEnt = owent:GetViewModel()
		if not IsValid(self.WeaponEnt) then
			return
		end
	end

	-- Get shell model from weapon (M9KR weapons use ShellModel property)
	local model = self.WeaponEntOG.ShellModel or "models/shells/shell_762nato.mdl"
	local scale = self.WeaponEntOG.ShellScale or 1
	local yaw = self.WeaponEntOG.ShellYaw or 90

	-- Detect shotgun shells for appropriate sounds
	local modelLower = string.lower(model)
	if string.find(modelLower, "12g_") or string.find(modelLower, "12gauge") or
	   string.find(modelLower, "13gauge") or string.find(modelLower, "38gauge") then
		self.Shotgun = true
	end

	self:SetModel(model)
	self:SetModelScale(scale, 0)
	self:SetPos(data:GetOrigin())

	local mdlang = self.DirAng * 1
	mdlang:RotateAroundAxis(mdlang:Up(), yaw)

	local owang = IsValid(owent) and owent:EyeAngles() or mdlang

	self:SetAngles(owang)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self:SetCollisionBounds(self:OBBMins(), self:OBBMaxs())
	self:PhysicsInitBox(self:OBBMins(), self:OBBMaxs())

	local velocity = self.Dir * math.Rand(self.Velocity[1], self.Velocity[2]) +
	                 owang:Forward() * math.Rand(self.VelocityRand[1], self.VelocityRand[2])

	if IsValid(owent) then
		velocity = velocity + owent:GetVelocity()
	end

	local physObj = self:GetPhysicsObject()

	if physObj:IsValid() then
		physObj:SetDamping(0.1, 1)
		physObj:SetMass(5)
		physObj:SetMaterial("gmod_silent")
		physObj:SetVelocity(velocity)
		local localVel = velocity:Length() * self.WeaponEnt:WorldToLocalAngles(velocity:Angle()):Forward()
		physObj:AddAngleVelocity(localVel.y * self.VelocityAngle)
		physObj:AddAngleVelocity(VectorRand() * velocity:Length() * self.VelocityRandAngle * 0.5)
	end

	-- Get appropriate collision sounds for this shell model
	local soundTable = self:GetShellSoundsForModel(model)
	self.ImpactSound = soundTable[math.random(1, #soundTable)]

	self.setup = true
end

function EFFECT:BounceSound()
	sound.Play(self.ImpactSound, self:GetPos(),
	           math.Rand(self.SoundLevel[1], self.SoundLevel[2]),
	           math.Rand(self.SoundPitch[1], self.SoundPitch[2]),
	           math.Rand(self.SoundVolume[1], self.SoundVolume[2]))
end

function EFFECT:PhysicsCollide(data)
	if self:WaterLevel() > 0 then
		return
	end

	-- Play collision sound if shell is moving fast enough
	if data.Speed > 60 then
		self:BounceSound()

		local impulse = (data.OurOldVelocity - 2 * data.OurOldVelocity:Dot(data.HitNormal) * data.HitNormal) * 0.33
		local phys = self:GetPhysicsObject()

		if phys:IsValid() then
			phys:ApplyForceCenter(impulse)
		end
	end

	-- Start smoke trail on first collision if still within smoke time
	-- DISABLED - Shell ejection smoke has been removed
	return
end

function EFFECT:Think()
	-- Shell smoke disabled - no particle updates needed

	-- Create water splash if shell enters water
	if self:WaterLevel() > 0 and not self.WaterSplashed then
		self.WaterSplashed = true

		local ef = EffectData()
		ef:SetOrigin(self:GetPos())
		ef:SetScale(1)
		util.Effect("watersplash", ef)
	end

	-- Fade out and remove after lifetime expires
	if CurTime() > self.StartTime + self.LifeTime then
		if self.Emitter then
			self.Emitter:Finish()
		end

		return false
	else
		return true
	end
end

function EFFECT:Render()
	if not self.setup then return end

	-- Fade out in last 0.5 seconds
	local alpha = (1 - math.Clamp(CurTime() - (self.StartTime + self.LifeTime - self.FadeTime), 0, self.FadeTime) / self.FadeTime) * 255
	self:SetColor(ColorAlpha(color_white, alpha))
	self:SetupBones()
	self:DrawModel()
end

-- Block annoying scrape sounds
hook.Add("EntityEmitSound", "M9KR_BlockShellScrapeSound", function(sndData)
	if IsValid(sndData.Entity) and sndData.Entity.IsM9KRShell and sndData.SoundName:find("scrape") then
		return false
	end
end)
