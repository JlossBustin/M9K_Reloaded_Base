--[[
	M9K Reloaded - Metal Impact Effect

	Custom metal spark impact effect
	Controlled by m9kr_metal_impact ConVar (0 = GMod default, 1 = M9K custom)
]]--

local gravity_cv = GetConVar("sv_gravity")

EFFECT.VelocityRandom = 0.25
EFFECT.VelocityMin = 95
EFFECT.VelocityMax = 125
EFFECT.ParticleCountMin = 4
EFFECT.ParticleCountMax = 7
EFFECT.ParticleLife = 1.3

function EFFECT:Init(data)
	-- Check ConVar - if disabled, spawn default GMod impact instead
	local metalCvar = GetConVar("m9kr_metal_impact")
	if metalCvar and metalCvar:GetInt() == 0 then
		-- Fall back to default GMod impact
		util.Effect("Impact", data)
		return
	end

	-- M9K custom metal impact
	self.StartPos = data:GetOrigin()
	self.Dir = data:GetNormal()
	self.LifeTime = 0.1
	self.DieTime = CurTime() + self.LifeTime
	self.PartMult = 0.2
	self.Grav = Vector(0, 0, -gravity_cv:GetFloat())
	self.SparkLife = 1

	-- Get caliber data for scaling (default to rifle caliber: 14)
	local penetration = data:GetMagnitude() or 14
	local caliberScale = penetration / 14  -- Normalize to rifle caliber (1.0 = rifle)

	local emitter = ParticleEmitter(self.StartPos)

	-- Scale particle count based on caliber
	local basePartCount = math.random(self.ParticleCountMin, self.ParticleCountMax)
	local partcount = math.floor(basePartCount * caliberScale)
	partcount = math.max(2, math.min(partcount, 20))  -- Clamp to 2-20 particles

	for _ = 1, partcount do
		local part = emitter:Add("effects/yellowflare", self.StartPos)
		part:SetVelocity(Lerp(self.VelocityRandom, self.Dir, VectorRand()) * math.Rand(self.VelocityMin, self.VelocityMax))
		part:SetDieTime(math.Rand(0.25, 1) * self.SparkLife)
		part:SetStartAlpha(255)
		part:SetStartSize(math.Rand(2, 4) * caliberScale)  -- Scale spark size by caliber
		part:SetEndSize(0)
		part:SetRoll(0)
		part:SetGravity(self.Grav)
		part:SetCollide(true)
		part:SetBounce(0.55)
		part:SetAirResistance(0.5)
		part:SetStartLength(0.2)
		part:SetEndLength(0)
		part:SetVelocityScale(true)
		part:SetCollide(true)
	end

	local part = emitter:Add("effects/yellowflare", self.StartPos)
	part:SetStartAlpha(255)
	part:SetStartSize(15 * self.PartMult * caliberScale)  -- Scale flash size by caliber
	part:SetDieTime(self.LifeTime * 1)
	part:SetEndSize(0)
	part:SetEndAlpha(0)
	part:SetRoll(math.Rand(0, 360))
	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
	return false
end
