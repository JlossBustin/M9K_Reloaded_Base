--[[
	M9K Reloaded - Dust Impact Effect

	Custom dust particle impact effect
	Controlled by m9kr_dust_impact ConVar (0 = GMod default, 1 = M9K custom)
	Uses M9KR.CreateSmokePuff helper
]]--

function EFFECT:Init(data)
	local dustCvar = GetConVar("m9kr_dust_impact")
	if dustCvar and dustCvar:GetInt() == 0 then
		util.Effect("Impact", data)
		return
	end

	local penetration = data:GetMagnitude() or 14
	local caliberScale = penetration / 14

	local posoffset = data:GetOrigin()
	local forward = data:GetNormal()
	local emitter = ParticleEmitter(posoffset)

	if not emitter then return end

	local particleCount = math.Round(8 * caliberScale)
	particleCount = math.max(3, math.min(particleCount, 20))

	M9KR.CreateSmokePuff(emitter, posoffset, forward, particleCount, caliberScale,
		function(p, i, count, norm, scale)
			p:SetVelocity(90 * math.sqrt(i) * norm)
			p:SetDieTime(math.Rand(0.75, 1) * (1 + math.sqrt(i) / 3))
			local iclamped = math.Clamp(i, 1, count)
			local iclamped_sqrt = math.sqrt(iclamped / count) * count
			p:SetStartSize(1 * scale * iclamped_sqrt)
			p:SetEndSize(math.Rand(1.5, 1.75) * scale * iclamped)
			p:SetColor(255, 255, 255)
		end)

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
	return false
end
