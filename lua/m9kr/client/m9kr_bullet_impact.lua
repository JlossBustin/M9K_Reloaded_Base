--[[
	M9K Reloaded - Bullet Impact Effect System

	Controls bullet impact dust/smoke effects:
	- ConVar: m9kr_bullet_impact (0 = GMod default, 1 = M9K custom)
	- ConVar: m9kr_metal_impact (0 = GMod default, 1 = M9K custom)
	- ConVar: m9kr_dust_impact (0 = GMod default, 1 = M9K custom)
	- Uses EntityFireBullets hook for proper effect spawning
]]--

-- ConVars created server-side in m9kr_autoload.lua (server-controlled, replicated to clients)
M9KR_BulletImpact = GetConVar("m9kr_bullet_impact")
M9KR_MetalImpact = GetConVar("m9kr_metal_impact")
M9KR_DustImpact = GetConVar("m9kr_dust_impact")

-- M9K weapon base lookup
local M9K_BASES = {
	["carby_gun_base"] = true,
	["carby_shotty_base"] = true,
	["carby_scoped_base"] = true,
}

-- Hook: Spawn bullet impact effects when M9K weapons fire
hook.Add("EntityFireBullets", "M9KR_BulletImpactEffects", function(entity, data)
	if not IsValid(entity) then return end

	-- Get weapon from entity (entity could be player or weapon)
	local wep
	if entity:IsPlayer() then
		wep = entity:GetActiveWeapon()
	elseif entity:IsWeapon() then
		wep = entity
	else
		return
	end

	if not IsValid(wep) then return end

	-- Check if it's an M9K:R weapon
	if not wep.Base or not M9K_BASES[wep.Base] then return end

	-- Use the Callback to spawn impact effects
	local originalCallback = data.Callback
	data.Callback = function(attacker, tr, dmginfo)
		-- Call original callback if it exists
		local result
		if originalCallback then
			result = originalCallback(attacker, tr, dmginfo)
		end

		-- Only spawn effects on CLIENT and only once per shot (prediction check)
		if CLIENT and IsFirstTimePredicted() and tr.HitPos then
			-- Skip smoke plume effects for flesh (use default GMod blood effects)
			if tr.MatType == MAT_FLESH or tr.MatType == MAT_ALIENFLESH then
				return result
			end

			local fx = EffectData()
			fx:SetOrigin(tr.HitPos)
			fx:SetNormal(tr.HitNormal or Vector(0, 0, 1))
			fx:SetEntity(entity)  -- Pass entity for weapon access in effects

			-- Get caliber data for scaling (default to rifle caliber: 14)
			local penetration = 14
			if IsValid(wep) and wep.ShellModel and M9KR and M9KR.Ballistics then
				local ballisticsData = M9KR.Ballistics.GetData(wep.ShellModel)
				if ballisticsData then
					penetration = ballisticsData.penetration
				end
			end

			fx:SetMagnitude(penetration)  -- Pass penetration value for caliber-based scaling

			-- Determine which effect to spawn (unified smoke plumes for all non-flesh surfaces)
			local effectName = nil
			if tr.MatType == MAT_METAL and M9KR_MetalImpact:GetInt() == 1 then
				effectName = "m9kr_metal_impact"  -- Metal gets sparks
			elseif M9KR_BulletImpact:GetInt() == 1 then
				effectName = "m9kr_bullet_impact"  -- All other materials get smoke plumes
			end

			if effectName then
				util.Effect(effectName, fx)
			end
		end

		return result
	end

	-- Don't return true - let other hooks run (e.g., muzzle smoke trail)
end)

print("[M9K:R] Bullet impact system loaded (EntityFireBullets hook)")
