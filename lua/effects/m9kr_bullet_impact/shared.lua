--[[
	M9K Reloaded - Bullet Impact Effect

	Dust/smoke puff effect when bullets hit surfaces
	Controlled by m9kr_bullet_impact ConVar (0 = GMod default, 1 = M9K custom)
	Adapted from TFA Base tfa_bullet_impact
]]--

function EFFECT:Init(data)
	-- Check ConVar - if disabled, spawn default GMod impact instead
	local impactCvar = GetConVar("m9kr_bullet_impact")
	if impactCvar and impactCvar:GetInt() == 0 then
		-- Fall back to default GMod impact
		util.Effect("Impact", data)
		return
	end

	-- M9K custom bullet impact
	-- Get caliber data for scaling (default to rifle caliber: 14)
	local penetration = data:GetMagnitude() or 14
	local caliberScale = penetration / 14  -- Normalize to rifle caliber (1.0 = rifle)

	local posoffset = data:GetOrigin()
	local normal = data:GetNormal()
	local emitter = ParticleEmitter(posoffset)

	if not emitter then return end

	-- Scale particle count based on caliber
	local particleCount = math.floor(6 * caliberScale)
	particleCount = math.max(3, math.min(particleCount, 20))  -- Clamp to 3-20 particles

	-- Spawn smoke particles expanding from impact point (scaled by caliber)
	for i = 0, particleCount - 1 do
		local particle = emitter:Add("particle/particle_smokegrenade", posoffset)

		if particle then
			-- Velocity: expand outward along surface normal with random spread
			local vel = 20 * math.sqrt(i) * normal * 3 + 2 * VectorRand()
			particle:SetVelocity(vel)
			particle:SetAirResistance(400)
			particle:SetStartAlpha(math.Rand(200, 255))
			particle:SetEndAlpha(0)
			particle:SetDieTime(math.Rand(0.5, 1.5))

			-- Scale particle sizes by caliber
			local iclamped = math.Clamp(i, 1, particleCount)
			particle:SetStartSize(math.Rand(2, 4) * iclamped * 0.5 * caliberScale)
			particle:SetEndSize(math.Rand(6, 12) * iclamped * 0.5 * caliberScale)
			particle:SetRoll(math.Rand(-25, 25))
			particle:SetRollDelta(math.Rand(-0.05, 0.05))
			particle:SetColor(200, 200, 200)
			particle:SetLighting(true)  -- Enable environmental lighting
		end
	end

	-- Check if heatwave/gas blur should be enabled (use existing m9kr_muzzle_heatwave convar)
	local heatwaveCvar = GetConVar("m9kr_muzzle_heatwave")
	if heatwaveCvar and heatwaveCvar:GetInt() > 0 then
		local particle = emitter:Add("sprites/heatwave", posoffset)

		if particle then
			particle:SetVelocity(50 * normal + 0.5 * VectorRand())
			particle:SetAirResistance(200)
			particle:SetStartSize(math.random(12.5, 17.5) * caliberScale)  -- Scale heatwave by caliber
			particle:SetEndSize(2 * caliberScale)
			particle:SetDieTime(math.Rand(0.15, 0.225))
			particle:SetRoll(math.Rand(-180, 180))
			particle:SetRollDelta(math.Rand(-0.75, 0.75))
		end
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
	return false
end
