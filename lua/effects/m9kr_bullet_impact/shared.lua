--[[
	M9K Reloaded - Bullet Impact Effect

	Dust/smoke puff effect when bullets hit surfaces
	Controlled by m9kr_bullet_impact ConVar (0 = GMod default, 1 = M9K custom)
	Adapted from TFA Base tfa_bullet_impact
	Uses M9KR.CreateSmokePuff helper
]]--

function EFFECT:Init(data)
	local impactCvar = GetConVar("m9kr_bullet_impact")
	if impactCvar and impactCvar:GetInt() == 0 then
		util.Effect("Impact", data)
		return
	end

	local penetration = data:GetMagnitude() or 14
	local caliberScale = penetration / 14

	local posoffset = data:GetOrigin()
	local normal = data:GetNormal()
	local emitter = ParticleEmitter(posoffset)

	if not emitter then return end

	local particleCount = math.floor(6 * caliberScale)
	particleCount = math.max(3, math.min(particleCount, 20))

	M9KR.CreateSmokePuff(emitter, posoffset, normal, particleCount, caliberScale,
		function(p, i, count, norm, scale)
			local vel = 20 * math.sqrt(i) * norm * 3 + 2 * VectorRand()
			p:SetVelocity(vel)
			p:SetDieTime(math.Rand(0.5, 1.5))
			local iclamped = math.Clamp(i, 1, count)
			p:SetStartSize(math.Rand(2, 4) * iclamped * 0.5 * scale)
			p:SetEndSize(math.Rand(6, 12) * iclamped * 0.5 * scale)
			p:SetColor(200, 200, 200)
		end)

	-- Optional heatwave/gas blur
	local heatwaveCvar = GetConVar("m9kr_muzzle_heatwave")
	if heatwaveCvar and heatwaveCvar:GetInt() > 0 then
		local particle = emitter:Add("sprites/heatwave", posoffset)
		if particle then
			particle:SetVelocity(50 * normal + 0.5 * VectorRand())
			particle:SetAirResistance(200)
			particle:SetStartSize(math.random(12.5, 17.5) * caliberScale)
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
