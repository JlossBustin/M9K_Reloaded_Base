--[[
	M9K Reloaded - Ricochet Effect
	Adapted from TFA Realistic Muzzleflashes 3.0 - tfa_metal_impact.lua

	Shows yellow spark particles that bounce and fall when bullets ricochet off hard surfaces.
]]--

local gravity_cv = GetConVar("sv_gravity")

EFFECT.VelocityRandom = 0.25
EFFECT.VelocityMin = 95
EFFECT.VelocityMax = 125
EFFECT.ParticleCountMin = 4
EFFECT.ParticleCountMax = 7
EFFECT.ParticleLife = 1.3

function EFFECT:Init(data)
	self.StartPos = data:GetOrigin()
	self.Dir = data:GetNormal()
	self.LifeTime = 0.1
	self.DieTime = CurTime() + self.LifeTime
	self.PartMult = 0.2
	self.Grav = Vector(0, 0, gravity_cv and -gravity_cv:GetFloat() or -600)
	self.SparkLife = 1

	local emitter = ParticleEmitter(self.StartPos)
	if not emitter then return end

	local partcount = math.random(self.ParticleCountMin, self.ParticleCountMax)

	-- Create bouncing spark particles
	for _ = 1, partcount do
		local part = emitter:Add("effects/yellowflare", self.StartPos)
		if part then
			part:SetVelocity(Lerp(self.VelocityRandom, self.Dir, VectorRand()) * math.Rand(self.VelocityMin, self.VelocityMax))
			part:SetDieTime(math.Rand(0.25, 1) * self.SparkLife)
			part:SetStartAlpha(255)
			part:SetEndAlpha(0)
			part:SetStartSize(math.Rand(2, 4))
			part:SetEndSize(0)
			part:SetRoll(0)
			part:SetGravity(self.Grav)
			part:SetCollide(true)
			part:SetBounce(0.55)
			part:SetAirResistance(0.5)
			part:SetStartLength(0.2)
			part:SetEndLength(0)
			part:SetVelocityScale(true)
			part:SetColor(255, 200, 100)  -- Yellow-orange spark color
		end
	end

	-- Large flash at impact point
	local part = emitter:Add("effects/yellowflare", self.StartPos)
	if part then
		part:SetStartAlpha(255)
		part:SetEndAlpha(0)
		part:SetStartSize(15 * self.PartMult)
		part:SetDieTime(self.LifeTime * 1)
		part:SetEndSize(0)
		part:SetRoll(math.Rand(0, 360))
		part:SetColor(255, 200, 100)
	end

	-- Additional bright flash
	part = emitter:Add("effects/yellowflare", self.StartPos)
	if part then
		part:SetStartAlpha(255)
		part:SetEndAlpha(0)
		part:SetStartSize(8 * self.PartMult)
		part:SetDieTime(self.LifeTime * 0.5)
		part:SetEndSize(0)
		part:SetRoll(math.Rand(0, 360))
		part:SetColor(255, 255, 200)  -- Brighter center
	end

	emitter:Finish()

	-- Optional: Add dynamic light for ricochet
	local dlight = DynamicLight(self:EntIndex())
	if dlight then
		dlight.pos = self.StartPos
		dlight.r = 255
		dlight.g = 200
		dlight.b = 100
		dlight.brightness = 3
		dlight.size = 64
		dlight.decay = 512
		dlight.dietime = CurTime() + 0.1
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
	return false
end
