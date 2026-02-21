--[[
	M9K Reloaded - Ricochet Effect
	Adapted from TFA Realistic Muzzleflashes 3.0 - tfa_metal_impact.lua

	Shows yellow spark particles that bounce and fall when bullets ricochet off hard surfaces.
	Uses M9KR.CreateSparkBurst / M9KR.CreateImpactFlash helpers
]]--

local SPARK_COLOR = Color(255, 200, 100)
local FLASH_CENTER_COLOR = Color(255, 255, 200)

function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local dir = data:GetNormal()

	local emitter = ParticleEmitter(pos)
	if not emitter then return end

	M9KR.CreateSparkBurst(emitter, pos, dir, {
		count = math.random(4, 7),
		color = SPARK_COLOR,
	})

	-- Large flash at impact point
	M9KR.CreateImpactFlash(emitter, pos, {size = 15 * 0.2, life = 0.1, color = SPARK_COLOR})
	-- Additional bright center flash
	M9KR.CreateImpactFlash(emitter, pos, {size = 8 * 0.2, life = 0.05, color = FLASH_CENTER_COLOR})

	emitter:Finish()

	-- Dynamic light for ricochet
	local dlight = DynamicLight(self:EntIndex())
	if dlight then
		dlight.pos = pos
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
