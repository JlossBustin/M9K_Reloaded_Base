--[[
	M9K Reloaded - Impact Effect Helpers

	Shared utility functions for impact effects to reduce code duplication.
	Used by: m9kr_metal_impact, m9kr_ricochet (spark helpers)
	         m9kr_bullet_impact, m9kr_dust_impact (smoke helpers)
]]--

M9KR = M9KR or {}

local gravity_cv = GetConVar("sv_gravity")

-- ============================================================================
-- Spark Helpers (metal_impact + ricochet)
-- ============================================================================

-- Spawns bouncing yellowflare spark particles expanding from impact point.
-- opts: count, caliberScale (1), color (nil = no explicit color)
function M9KR.CreateSparkBurst(emitter, pos, dir, opts)
	local count = opts.count or math.random(4, 7)
	local caliberScale = opts.caliberScale or 1
	local sparkLife = 1
	local grav = Vector(0, 0, gravity_cv and -gravity_cv:GetFloat() or -600)

	for _ = 1, count do
		local part = emitter:Add("effects/yellowflare", pos)
		if part then
			part:SetVelocity(Lerp(0.25, dir, VectorRand()) * math.Rand(95, 125))
			part:SetDieTime(math.Rand(0.25, 1) * sparkLife)
			part:SetStartAlpha(255)
			part:SetEndAlpha(0)
			part:SetStartSize(math.Rand(2, 4) * caliberScale)
			part:SetEndSize(0)
			part:SetRoll(0)
			part:SetGravity(grav)
			part:SetCollide(true)
			part:SetBounce(0.55)
			part:SetAirResistance(0.5)
			part:SetStartLength(0.2)
			part:SetEndLength(0)
			part:SetVelocityScale(true)
			if opts.color then
				part:SetColor(opts.color[1], opts.color[2], opts.color[3])
			end
		end
	end
end

-- Spawns a single yellowflare flash particle at impact point.
-- opts: size, life (0.1), caliberScale (1), color (nil = no explicit color)
function M9KR.CreateImpactFlash(emitter, pos, opts)
	local part = emitter:Add("effects/yellowflare", pos)
	if part then
		part:SetStartAlpha(255)
		part:SetEndAlpha(0)
		part:SetStartSize(opts.size * (opts.caliberScale or 1))
		part:SetDieTime(opts.life or 0.1)
		part:SetEndSize(0)
		part:SetRoll(math.Rand(0, 360))
		if opts.color then
			part:SetColor(opts.color[1], opts.color[2], opts.color[3])
		end
	end
end

-- ============================================================================
-- Smoke Helpers (bullet_impact + dust_impact)
-- ============================================================================

-- Spawns caliber-scaled smoke particles from impact point.
-- The loop body calls setupParticle(particle, i, count, normal, caliberScale)
-- for per-particle velocity, dieTime, size, and color setup.
-- Common properties (air resistance, alpha, roll, lighting) are set by this helper.
function M9KR.CreateSmokePuff(emitter, pos, normal, count, caliberScale, setupParticle)
	for i = 0, count - 1 do
		local p = emitter:Add("particle/particle_smokegrenade", pos)
		if p then
			p:SetAirResistance(400)
			p:SetStartAlpha(math.Rand(200, 255))
			p:SetEndAlpha(0)
			p:SetRoll(math.Rand(-25, 25))
			p:SetRollDelta(math.Rand(-0.05, 0.05))
			p:SetLighting(true)
			setupParticle(p, i, count, normal, caliberScale)
		end
	end
end
