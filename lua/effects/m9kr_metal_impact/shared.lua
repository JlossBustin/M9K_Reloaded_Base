--[[
	M9K Reloaded - Metal Impact Effect

	Custom metal spark impact effect
	Controlled by m9kr_metal_impact ConVar (0 = GMod default, 1 = M9K custom)
	Uses M9KR.CreateSparkBurst / M9KR.CreateImpactFlash helpers
]]--

function EFFECT:Init(data)
	local metalCvar = GetConVar("m9kr_metal_impact")
	if metalCvar and metalCvar:GetInt() == 0 then
		util.Effect("Impact", data)
		return
	end

	local pos = data:GetOrigin()
	local dir = data:GetNormal()
	local penetration = data:GetMagnitude() or 14
	local caliberScale = penetration / 14

	local emitter = ParticleEmitter(pos)
	if not emitter then return end

	local count = math.floor(math.random(4, 7) * caliberScale)
	count = math.max(2, math.min(count, 20))

	M9KR.CreateSparkBurst(emitter, pos, dir, {count = count, caliberScale = caliberScale})
	M9KR.CreateImpactFlash(emitter, pos, {size = 15 * 0.2, caliberScale = caliberScale, life = 0.1})

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
	return false
end
