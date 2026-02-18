--[[
	M9K Reloaded - Penetration Tracer Effect
	Adapted from TFA Realistic Muzzleflashes 3.0 - tfa_penetrate.lua

	Shows a subtle white/gray tracer with small flare particles when bullets penetrate surfaces.
]]--

local PenetColor = Color(255, 255, 255, 255)
local PenetMat = Material("trails/smoke")
local PenetMat2 = Material("effects/yellowflare")
local cv_gv = GetConVar("sv_gravity")

function EFFECT:Init(data)
	self.StartPos = data:GetStart() or data:GetOrigin()
	self.EndPos = data:GetOrigin()
	self.Dir = (self.EndPos - self.StartPos):GetNormalized()
	self.Len = self.StartPos:Distance(self.EndPos)
	self.LifeTime = 0.75
	self.DieTime = CurTime() + self.LifeTime
	self.Thickness = 1
	self.Grav = Vector(0, 0, cv_gv and -cv_gv:GetFloat() or -600)
	self.PartMult = 1

	-- Get caliber data for scaling (default to rifle caliber: 14)
	local penetration = data:GetMagnitude() or 14
	local caliberScale = penetration / 14  -- Normalize to rifle caliber (1.0 = rifle)

	-- Spawn smoke particles along penetration path (replaces beam)
	local particleCount = math.floor(4 * caliberScale)
	particleCount = math.max(2, math.min(particleCount, 12))  -- Clamp to 2-12 particles

	local emitter = ParticleEmitter(self.StartPos)
	if emitter then
		for i = 0, particleCount - 1 do
			local t = i / math.max(particleCount - 1, 1)  -- 0 to 1 along penetration path
			local pos = LerpVector(t, self.StartPos, self.EndPos)

			local particle = emitter:Add("particle/particle_smokegrenade", pos)
			if particle then
				particle:SetVelocity(self.Dir * 15 + VectorRand() * 8)
				particle:SetAirResistance(300)
				particle:SetStartAlpha(math.Rand(120, 170))
				particle:SetEndAlpha(0)
				particle:SetDieTime(self.LifeTime)
				particle:SetStartSize(math.Rand(0.5, 1.5) * caliberScale)
				particle:SetEndSize(math.Rand(2, 4) * caliberScale)
				particle:SetRoll(math.Rand(-25, 25))
				particle:SetRollDelta(math.Rand(-0.05, 0.05))
				particle:SetColor(180, 180, 180)
				particle:SetLighting(true)
			end
		end
	end

	-- Create entry particle effect at start position
	emitter = ParticleEmitter(self.StartPos)
	if emitter then
		-- Small flash at entry point (scaled by caliber)
		local part = emitter:Add("effects/yellowflare", self.StartPos)
		if part then
			part:SetStartAlpha(225)
			part:SetStartSize(1 * caliberScale)
			part:SetDieTime(self.LifeTime / 5)
			part:SetEndSize(0)
			part:SetEndAlpha(0)
			part:SetRoll(math.Rand(0, 360))
			part:SetColor(200, 200, 200)
		end

		-- Larger flash at entry (scaled by caliber)
		part = emitter:Add("effects/yellowflare", self.StartPos)
		if part then
			part:SetStartAlpha(255)
			part:SetStartSize(1.5 * self.PartMult * caliberScale)
			part:SetDieTime(self.LifeTime / 6)
			part:SetEndSize(0)
			part:SetEndAlpha(0)
			part:SetRoll(math.Rand(0, 360))
			part:SetColor(200, 200, 200)
		end

		emitter:Finish()
	end

	-- Create exit particle effect (scaled by caliber)
	emitter = ParticleEmitter(self.EndPos)
	if emitter then
		-- Small flash at exit point (scaled by caliber)
		local part = emitter:Add("effects/yellowflare", self.EndPos)
		if part then
			part:SetStartAlpha(225)
			part:SetStartSize(1.5 * caliberScale)
			part:SetDieTime(self.LifeTime / 5)
			part:SetEndSize(0)
			part:SetEndAlpha(0)
			part:SetRoll(math.Rand(0, 360))
			part:SetColor(200, 200, 200)
		end

		emitter:Finish()
	end
end

function EFFECT:Think()
	if self.DieTime and (CurTime() > self.DieTime) then return false end
	return true
end

function EFFECT:Render()
	-- Beam rendering replaced with smoke particles (spawned in Init)
	-- Particles handle the visual effect along the penetration path
	return
end
