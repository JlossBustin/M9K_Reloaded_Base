--[[
	M9K Reloaded - Dust Impact Effect

	Custom dust particle impact effect
	Controlled by m9kr_dust_impact ConVar (0 = GMod default, 1 = M9K custom)
]]--

function EFFECT:Init(data)
	-- Check ConVar - if disabled, spawn default GMod impact instead
	local dustCvar = GetConVar("m9kr_dust_impact")
	if dustCvar and dustCvar:GetInt() == 0 then
		-- Fall back to default GMod impact
		util.Effect("Impact", data)
		return
	end

	-- M9K custom dust impact
	-- Get caliber data for scaling (default to rifle caliber: 14)
	local penetration = data:GetMagnitude() or 14
	local caliberScale = penetration / 14  -- Normalize to rifle caliber (1.0 = rifle)

	local posoffset = data:GetOrigin()
	local forward = data:GetNormal()
	local emitter = ParticleEmitter(posoffset)

	-- Scale particle count based on caliber
	local particleCount = math.Round(8 * caliberScale)
	particleCount = math.max(3, math.min(particleCount, 20))  -- Clamp to 3-20 particles

	for i = 0, particleCount do
		local p = emitter:Add("particle/particle_smokegrenade", posoffset)
		p:SetVelocity(90 * math.sqrt(i) * forward)
		p:SetAirResistance(400)
		p:SetStartAlpha(math.Rand(200, 255))
		p:SetEndAlpha(0)
		p:SetDieTime(math.Rand(0.75, 1) * (1 + math.sqrt(i) / 3))
		local iclamped = math.Clamp(i, 1, particleCount)
		local iclamped_sqrt = math.sqrt(iclamped / particleCount) * particleCount
		p:SetStartSize(math.Rand(1, 1) * caliberScale * iclamped_sqrt)  -- Scale by caliber
		p:SetEndSize(math.Rand(1.5, 1.75) * caliberScale * iclamped)  -- Scale by caliber
		p:SetRoll(math.Rand(-25, 25))
		p:SetRollDelta(math.Rand(-0.05, 0.05))
		p:SetColor(255, 255, 255)
		p:SetLighting(true)
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
	return false
end
