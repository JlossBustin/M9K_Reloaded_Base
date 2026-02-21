--[[
	M9K Reloaded - Muzzle Heatwave System

	Centralized heatwave distortion control for all muzzle flashes:
	- 3 levels: 0 = Disabled, 1 = Full (100%), 2 = Reduced (50%)
	- Applies to all weapon types
	- Called from muzzleflash and bullet impact effect files
]]--

M9KR = M9KR or {}

-- ConVar created server-side in m9kr_autoload.lua (server-controlled, replicated to clients)
local heatwaveCvar = GetConVar("m9kr_muzzle_heatwave")

--[[
	Helper function: Spawn heatwave particle
	Called from muzzleflash and bullet impact effect Init() functions

	Parameters:
		emitter - ParticleEmitter instance
		position - Vector position to spawn heatwave
		direction - Vector direction for heatwave movement
		heatSize - Base size multiplier (from effect)
		life - Lifetime of particle (from effect)
]]--
function M9KR.SpawnHeatwave(emitter, position, direction, heatSize, life)
	if not emitter then return end
	if not position then return end
	if not direction then return end

	local heatLevel = heatwaveCvar:GetInt()
	if heatLevel == 0 then return end  -- Disabled

	-- Base values
	local baseHeatSize = heatSize or 0.80
	local baseLife = life or 0.085

	-- Adjust for reduction level
	local sizeMultiplier = 1.0
	local lifeMultiplier = 1.0
	local alphaMultiplier = 1.0

	if heatLevel == 2 then  -- 50% reduced
		sizeMultiplier = 0.5
		lifeMultiplier = 0.5
		alphaMultiplier = 0.5
	end

	local adjustedHeatSize = baseHeatSize * sizeMultiplier
	local adjustedLife = baseLife * lifeMultiplier

	-- Spawn heatwave particle
	local particle = emitter:Add("sprites/heatwave", position + direction * 2)

	if particle then
		particle:SetVelocity(direction * 25 * adjustedHeatSize + 1.05 * Vector())
		particle:SetLifeTime(0)
		particle:SetDieTime(adjustedLife)
		particle:SetStartAlpha(math.Rand(200, 225) * alphaMultiplier)
		particle:SetEndAlpha(0)
		particle:SetStartSize(math.Rand(3, 5) * adjustedHeatSize)
		particle:SetEndSize(math.Rand(8, 12) * adjustedHeatSize)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-2, 2))
		particle:SetAirResistance(5)
		particle:SetGravity(Vector(0, 0, 40))
		particle:SetColor(255, 255, 255)
	end
end

print("[M9K:R] Muzzle heatwave system loaded")
