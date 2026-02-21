--[[
	M9K Reloaded - Penetration System

	Handles bullet penetration and ricochet calculations based on ballistics data.
	This system dynamically reads weapon's ShellModel to determine penetration behavior.

	ConVar: m9kr_penetration_mode
	0 = Disabled (no penetration)
	1 = Dynamic (new ballistics-based system)
	2 = Vanilla (original M9K penetration logic)
]]--

M9KR = M9KR or {}
M9KR.Penetration = M9KR.Penetration or {}

-- Create ConVars for penetration mode (server-only)
if SERVER then
	CreateConVar("m9kr_penetration_mode", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED},
		"Penetration system mode: 0 = Disabled, 1 = Dynamic (ballistics-based), 2 = Vanilla (original M9K)", 0, 2)

	-- ConVar for ricochet probability (allows tuning)
	CreateConVar("m9kr_ricochet_chance", "15", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
		"Percentage chance (0-100) that a bullet will ricochet off eligible surfaces. Default 15% (~1 in 7 shots).", 0, 100)
end

-- Fallback ammo type lookup table for when shell model isn't in the ballistics database
-- Used by DynamicPenetration() when weapon has no ShellModel or it's unrecognized
local AMMO_FALLBACK = {
	["pistol"]                = {penetration = 9,  maxRicochet = 2, canRicochet = true,  armorPiercing = false},
	["357"]                   = {penetration = 12, maxRicochet = 3, canRicochet = true,  armorPiercing = false},
	["smg1"]                  = {penetration = 14, maxRicochet = 4, canRicochet = false, armorPiercing = false},
	["ar2"]                   = {penetration = 16, maxRicochet = 5, canRicochet = false, armorPiercing = false},
	["SniperPenetratedRound"] = {penetration = 20, maxRicochet = 6, canRicochet = false, armorPiercing = false},
	["buckshot"]              = {penetration = 5,  maxRicochet = 0, canRicochet = true,  armorPiercing = false},
	["slam"]                  = {penetration = 12, maxRicochet = 1, canRicochet = true,  armorPiercing = false},
}

local AMMO_DEFAULT = {penetration = 14, maxRicochet = 4, canRicochet = false, armorPiercing = false}

-- Near-miss bullet sounds
local bulletMissSounds = {
	"weapons/fx/nearmiss/bulletLtoR03.wav",
	"weapons/fx/nearmiss/bulletLtoR04.wav",
	"weapons/fx/nearmiss/bulletLtoR06.wav",
	"weapons/fx/nearmiss/bulletLtoR07.wav",
	"weapons/fx/nearmiss/bulletLtoR09.wav",
	"weapons/fx/nearmiss/bulletLtoR10.wav",
	"weapons/fx/nearmiss/bulletLtoR13.wav",
	"weapons/fx/nearmiss/bulletLtoR14.wav"
}

--[[
	Create near-miss effects (bullet whizzing sound only)
	Screen shake removed to prevent sticky aim with high-RPM/burst weapons

	Now checks the bullet's flight PATH, not just impact point.
	Plays whizzing sound when bullet passes close to a player.

	Must run on SERVER: server broadcasts sound.Play to all clients.
	Client prediction only runs for the shooter, so other players
	would never hear nearby bullets if this ran client-side.
]]--
if SERVER then
	function CreateNearMissEffects(weapon, startPos, hitPos, attacker)
		if not IsValid(weapon) then return end
		if not startPos or not hitPos then return end

		-- Calculate bullet path direction and length
		local bulletDir = hitPos - startPos
		local bulletLength = bulletDir:Length()
		if bulletLength < 1 then return end
		bulletDir:Normalize()

		-- Find nearby players for near-miss whizzing sounds
		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) and ply ~= attacker then
				-- Get player's center mass position (not feet)
				local plyPos = ply:GetPos() + Vector(0, 0, 40)

				-- Calculate closest point on bullet path to player
				-- Using vector projection: closest point = start + dot(plyPos-start, dir) * dir
				local toPlayer = plyPos - startPos
				local projection = toPlayer:Dot(bulletDir)

				-- Clamp projection to the actual bullet path (between start and hit)
				projection = math.Clamp(projection, 0, bulletLength)

				-- Find the closest point on the bullet's path
				local closestPoint = startPos + bulletDir * projection

				-- Calculate distance from player to closest point on bullet path
				local missDistance = plyPos:Distance(closestPoint)

				-- Only play whizzing sound if bullet passed within 128 units of player
				-- and the closest point is not at the very start (shooter's position)
				if missDistance <= 128 and projection > 64 then
					-- Play whizzing sound at a point near the player
					if #bulletMissSounds > 0 then
						local snd = table.Random(bulletMissSounds)
						if snd then
							-- Play sound at the closest point on bullet path
							sound.Play(snd, closestPoint, 75, math.random(90, 130), 1)
						end
					end
				end
			end
		end
	end
end 
--[[
	Vanilla M9K Penetration System
	Original penetration logic from M9K base
]]--
if SERVER then
	function M9KR.Penetration.VanillaPenetration(weapon, bouncenum, attacker, tr, paininfo)
		-- Match legacy M9K pattern: check prediction, not realm
		if not IsFirstTimePredicted() then return false end
		if not IsValid(weapon) then return false end
		-- Basic sanity checks: tracedata and attacker must be present for further processing
		if not tr or not tr.HitPos or not tr.Normal or not tr.HitNormal then return false end
		if not IsValid(attacker) then return false end
		if not attacker.FireBullets then return false end -- Ensure entity can fire bullets
		if not paininfo or not paininfo.Damage or not paininfo.Force then return false end

		-- Use old ricochet/penetration settings from weapon
		local MaxRicochet = weapon.MaxRicochet or 0
		local Ricochet = weapon.Ricochet or false

		-- Ricochet system
		if Ricochet then
			if tr.MatType == MAT_METAL or tr.MatType == MAT_CONCRETE or tr.MatType == MAT_ROCK then
				if bouncenum > MaxRicochet then
					return false
				end

				-- Probability-based ricochet system (default 15% chance, ~1 in 7 shots)
				-- This prevents screen shake spam and sticky mouse issues with high-RPM weapons
				local ricochetChanceCvar = GetConVar("m9kr_ricochet_chance")
				local ricochetChance = ricochetChanceCvar and ricochetChanceCvar:GetInt() or 15
				if math.random(1, 100) > ricochetChance then
					return false  -- Skip this ricochet
				end

				-- Calculate impact angle for realistic ricochet physics
				local DotProduct = tr.HitNormal:Dot(tr.Normal * -1)

				-- Ricochet only at shallow angles (< 30° from surface = > 60° from normal)
				-- DotProduct = 0.0 → grazing shot (0° from surface) → HIGH ricochet chance
				-- DotProduct = 0.5 → 60° from normal (30° from surface) → threshold
				-- DotProduct = 1.0 → perpendicular (90° from surface) → NO ricochet
				if DotProduct > 0.5 then
					return false  -- Too steep - won't ricochet (> 30° from surface)
				end

				-- Calculate ricochet direction
				local RicochetDir = ((2 * tr.HitNormal * DotProduct) + tr.Normal) + (VectorRand() * 0.05)

				-- Validate ricochet direction (prevent NaN/inf crashes)
				if not isvector(RicochetDir) or RicochetDir:IsZero() or RicochetDir:Length() > 10000 then
					return false
				end
				RicochetDir:Normalize()

				-- Create ricochet visual effect (TFA-style sparks)
				local effectdata = EffectData()
				effectdata:SetOrigin(tr.HitPos)
				effectdata:SetNormal(RicochetDir)
				util.Effect("m9kr_ricochet", effectdata)

				-- Play whizzing sound for nearby players (screen shake removed to prevent sticky aim)
				if SERVER then
					CreateNearMissEffects(weapon, tr.StartPos, tr.HitPos, attacker)
				end 

				-- Ricochet bullet - ensure attacker is valid and can fire bullets
				if not IsValid(attacker) or not attacker.FireBullets then return false end

				-- Use timer to prevent crashing (must execute outside bullet callback context)
				if SERVER then
					timer.Simple(0, function()
						if not IsValid(attacker) then return end
						attacker:FireBullets({
							Attacker = attacker,
							Damage = paininfo.Damage * 0.5,
							Force = paininfo.Force,
							Num = 1,
							Src = tr.HitPos + (tr.HitNormal * 5),
							Dir = RicochetDir,
							HullSize = 0,
							Spread = Vector(0, 0, 0),
							Tracer = 0,  -- No tracers for ricochet bullets
							TracerName = "",
							Callback = function(cb_attacker, tracedata, dmginfo)
								-- Match legacy M9K: check prediction in nested callbacks
								if not IsFirstTimePredicted() then return end
								-- Defensive checks inside callback (can be invoked async-ish)
								if not IsValid(weapon) then return end
								if not IsValid(cb_attacker) then return end
								if not tracedata or not dmginfo then return end
								-- Construct paininfo table from dmginfo object
								local paininfo_cb = {
									Damage = dmginfo:GetDamage(),
									Force = dmginfo:GetDamageForce()
								}
								if weapon and weapon.BulletPenetrate then
									weapon:BulletPenetrate(bouncenum + 1, cb_attacker, tracedata, paininfo_cb)
								end
							end
						})
					end)
				end

				return true
			end
		end

		-- Simple penetration based on PenetrationDepth
		local penDistance = weapon.PenetrationDepth or 9
		local MaxPenetration = weapon.MaxPenetration or 3  -- Limit penetration bounces

		-- Check penetration bounce limit
		if bouncenum > MaxPenetration then
			return false
		end

		-- In FireBullets callback, tr.Normal IS the bullet direction (not surface normal!)
		-- Surface normal is tr.HitNormal
		local bulletDir = tr.Normal

		-- Validate bullet direction (prevent NaN/inf crashes)
		if not isvector(bulletDir) or bulletDir:IsZero() or bulletDir:Length() > 10000 then
			return false
		end

		-- Determine exit point based on hit type
		local exitPos

		if tr.MatType == MAT_FLESH or tr.MatType == MAT_ALIENFLESH then
			-- For NPCs/players: skip backwards trace (entities aren't solid walls)
			-- Just offset past the entity's collision hull along bullet direction
			exitPos = tr.HitPos + (bulletDir * 24)
		else
			-- Legacy M9K approach: Trace BACKWARDS from beyond the wall to entry point
			-- This finds the exit point by reversing the trace
			local traceFilter = {weapon}
			if IsValid(weapon.Owner) then
				table.insert(traceFilter, weapon.Owner)
			end
			local penetrationTrace = {
				start = tr.HitPos + (bulletDir * penDistance),  -- Start far ahead
				endpos = tr.HitPos,  -- Trace back to entry
				filter = traceFilter,
				mask = MASK_SHOT
			}

			local trace = util.TraceLine(penetrationTrace)

			-- If trace starts in solid (wall too thick) or didn't find exit, no penetration
			if trace.StartSolid or trace.Fraction >= 1.0 or trace.Fraction <= 0.0 then
				return false
			end

			exitPos = trace.HitPos

			-- Create penetration effect (TFA-style)
			local ballisticsData = nil
			if M9KR and M9KR.Ballistics and M9KR.Ballistics.GetData and weapon.ShellModel then
				ballisticsData = M9KR.Ballistics.GetData(weapon.ShellModel)
			end
			local penetration = ballisticsData and ballisticsData.penetration or 14

			local effectdata = EffectData()
			effectdata:SetStart(exitPos)  -- Exit point (where bullet emerges)
			effectdata:SetOrigin(exitPos + (tr.Normal * 20))  -- Show 20 units forward (subtle tracer)
			effectdata:SetMagnitude(penetration)  -- Pass penetration for caliber-based scaling
			util.Effect("m9kr_penetrate", effectdata)
		end

		-- Create near-miss effects (bullet whizzing sound for nearby players)
		if SERVER then
			CreateNearMissEffects(weapon, tr.StartPos, tr.HitPos, attacker)
		end

		-- Fire penetrating bullet
		-- Ensure attacker is valid and can fire bullets
		if not IsValid(attacker) or not attacker.FireBullets then return false end

		-- Use timer to prevent crashing (must execute outside bullet callback context)
		if SERVER then
			timer.Simple(0, function()
				if not IsValid(attacker) then return end
				attacker:FireBullets({
					Attacker = attacker,
					Damage = paininfo.Damage * 0.7,
					Force = paininfo.Force,
					Num = 1,
					Src = exitPos,
					Dir = tr.Normal,  -- tr.Normal is the bullet direction in callback context
					HullSize = 0,
					Spread = Vector(0, 0, 0),
					Tracer = 0,  -- No tracers for penetration bullets
					TracerName = "",
					Callback = function(cb_attacker, tracedata, dmginfo)
						-- Match legacy M9K: check prediction in nested callbacks
						if not IsFirstTimePredicted() then return end
						if not IsValid(weapon) then return end
						if not IsValid(cb_attacker) then return end
						if not tracedata or not dmginfo then return end
						local paininfo_cb = {
							Damage = dmginfo:GetDamage(),
							Force = dmginfo:GetDamageForce()
						}
						if weapon and weapon.BulletPenetrate then
							weapon:BulletPenetrate(bouncenum + 1, cb_attacker, tracedata, paininfo_cb)
						end
					end
				})
			end)
		end

		return true
	end
end
--[[
	Dynamic Penetration System
	Ballistics-based penetration using shell model data
]]--
function M9KR.Penetration.DynamicPenetration(weapon, bouncenum, attacker, tr, paininfo)
	-- Match legacy M9K pattern: check prediction, not realm
	if not IsFirstTimePredicted() then return false end
	if not IsValid(weapon) then return false end
	-- Defensive sanity checks
	if not tr or not tr.HitPos or not tr.Normal or not tr.HitNormal then return false end
	if not IsValid(attacker) then return false end
	if not attacker.FireBullets then return false end -- Ensure entity can fire bullets
	if not paininfo or not paininfo.Damage or not paininfo.Force then return false end

	-- Get ballistics data from shell model for realistic, caliber-specific penetration
	local ballisticsData = nil
	if M9KR and M9KR.Ballistics and M9KR.Ballistics.GetData and weapon.ShellModel then
		ballisticsData = M9KR.Ballistics.GetData(weapon.ShellModel)
	end

	local MaxPenetration
	local MaxRicochet
	local CanRicochet
	local IsArmorPiercing

	if ballisticsData then
		-- Use real-world ballistics data from shell casing model
		MaxPenetration = ballisticsData.penetration
		MaxRicochet = ballisticsData.maxRicochet
		CanRicochet = ballisticsData.canRicochet
		IsArmorPiercing = ballisticsData.armorPiercing
	else
		-- Fallback to ammo type lookup table if shell model not in database
		local AmmoType = (weapon.Primary and weapon.Primary.Ammo) or "ar2"
		local ammoProps = AMMO_FALLBACK[AmmoType] or AMMO_DEFAULT

		MaxPenetration = ammoProps.penetration
		MaxRicochet = ammoProps.maxRicochet
		CanRicochet = ammoProps.canRicochet
		IsArmorPiercing = ammoProps.armorPiercing
	end

	-- Update weapon's ricochet properties
	weapon.Ricochet = CanRicochet
	weapon.MaxRicochet = MaxRicochet

	-- Metal penetration check - only armor-piercing rounds can penetrate metal
	if tr.MatType == MAT_METAL and not IsArmorPiercing then
		return false
	end

	-- Ricochet system
	if CanRicochet then
		if tr.MatType == MAT_METAL or tr.MatType == MAT_CONCRETE or tr.MatType == MAT_ROCK then
			if bouncenum > MaxRicochet then
				return false
			end

			-- Probability-based ricochet system (default 15% chance, ~1 in 7 shots)
			-- This prevents screen shake spam and sticky mouse issues with high-RPM weapons
			local ricochetChanceCvar = GetConVar("m9kr_ricochet_chance")
			local ricochetChance = ricochetChanceCvar and ricochetChanceCvar:GetInt() or 15
			if math.random(1, 100) > ricochetChance then
				return false  -- Skip this ricochet
			end

			-- Calculate impact angle for realistic ricochet physics
			local DotProduct = tr.HitNormal:Dot(tr.Normal * -1)

			-- Ricochet only at shallow angles (< 30° from surface = > 60° from normal)
			-- DotProduct = 0.0 → grazing shot (0° from surface) → HIGH ricochet chance
			-- DotProduct = 0.5 → 60° from normal (30° from surface) → threshold
			-- DotProduct = 1.0 → perpendicular (90° from surface) → NO ricochet
			if DotProduct > 0.5 then
				return false  -- Too steep - won't ricochet (> 30° from surface)
			end

			-- Calculate ricochet direction
			local RicochetDir = ((2 * tr.HitNormal * DotProduct) + tr.Normal) + (VectorRand() * 0.05)

			-- Validate ricochet direction (prevent NaN/inf crashes)
			if not isvector(RicochetDir) or RicochetDir:IsZero() or RicochetDir:Length() > 10000 then
				return false
			end
			RicochetDir:Normalize()

			-- Create ricochet visual effect (TFA-style sparks)
			local effectdata = EffectData()
			effectdata:SetOrigin(tr.HitPos)
			effectdata:SetNormal(RicochetDir)
			util.Effect("m9kr_ricochet", effectdata)

			-- Play whizzing sound for nearby players (screen shake removed to prevent sticky aim)
			if SERVER then
				CreateNearMissEffects(weapon, tr.StartPos, tr.HitPos, attacker)
			end

			-- Create ricochet trace
			local traceFilter = {weapon}
			if IsValid(weapon.Owner) then
				table.insert(traceFilter, weapon.Owner)
			end
			local penetrationTrace = {
				start = tr.HitPos,
				endpos = tr.HitPos + (RicochetDir * MaxPenetration),
				filter = traceFilter,
				mask = MASK_SHOT_HULL
			}

			local trace = util.TraceLine(penetrationTrace)

			-- Ricochet bullet - ensure attacker can fire bullets
			if not IsValid(attacker) or not attacker.FireBullets then return false end

			-- Use timer to prevent crashing (must execute outside bullet callback context)
			if SERVER then
				timer.Simple(0, function()
					if not IsValid(attacker) then return end
					attacker:FireBullets({
						Attacker = attacker,
						Damage = paininfo.Damage * 0.5,
						Force = paininfo.Force,
						Num = 1,
						Src = tr.HitPos + (tr.HitNormal * 5),
						Dir = RicochetDir,
						HullSize = 0,
						Spread = Vector(0, 0, 0),
						Tracer = 0,  -- No tracers for ricochet bullets
						TracerName = "",
						Callback = function(cb_attacker, tracedata, dmginfo)
							-- Match legacy M9K: check prediction in nested callbacks
							if not IsFirstTimePredicted() then return end
							if not IsValid(weapon) then return end
							if not IsValid(cb_attacker) then return end
							if not tracedata or not dmginfo then return end
							local paininfo_cb = {
								Damage = dmginfo:GetDamage(),
								Force = dmginfo:GetDamageForce()
							}
							if weapon and weapon.BulletPenetrate then
								weapon:BulletPenetrate(bouncenum + 1, cb_attacker, tracedata, paininfo_cb)
							end
						end
					})
				end)
			end

			return true
		end
	end

	-- Check penetration bounce limit (use MaxRicochet as penetration limit too)
	if bouncenum > MaxRicochet then
		return false
	end

	-- In FireBullets callback, tr.Normal IS the bullet direction (not surface normal!)
	-- Surface normal is tr.HitNormal
	local bulletDir = tr.Normal

	-- Validate bullet direction (prevent NaN/inf crashes)
	if not isvector(bulletDir) or bulletDir:IsZero() or bulletDir:Length() > 10000 then
		return false
	end

	-- Penetration check based on material (matching legacy M9K behavior)
	local penDistance = MaxPenetration

	-- Legacy M9K doubles penetration for soft materials - they're easy to shoot through!
	if tr.MatType == MAT_GLASS or tr.MatType == MAT_PLASTIC or tr.MatType == MAT_WOOD or tr.MatType == MAT_FLESH or tr.MatType == MAT_ALIENFLESH then
		penDistance = penDistance * 2.0  -- Soft materials offer minimal resistance
	elseif tr.MatType == MAT_METAL then
		-- Metal is difficult - only AP rounds penetrate effectively
		if IsArmorPiercing then
			penDistance = penDistance * 1.0  -- AP rounds at full strength
		else
			penDistance = penDistance * 0.3  -- Non-AP greatly reduced
		end
	elseif tr.MatType == MAT_CONCRETE or tr.MatType == MAT_ROCK or tr.MatType == MAT_TILE then
		penDistance = penDistance * 0.5  -- Concrete/masonry significant reduction
	elseif tr.MatType == MAT_DIRT or tr.MatType == MAT_SAND then
		penDistance = penDistance * 1.5  -- Soft earth easy to penetrate
	else
		penDistance = penDistance * 1.0  -- Default: use base penetration
	end

	-- Determine exit point based on hit type
	local exitPos

	if tr.MatType == MAT_FLESH or tr.MatType == MAT_ALIENFLESH then
		-- For NPCs/players: skip backwards trace (entities aren't solid walls)
		-- Just offset past the entity's collision hull along bullet direction
		exitPos = tr.HitPos + (bulletDir * 24)
	else
		-- For world geometry: Trace BACKWARDS from beyond the wall to entry point
		-- This finds the exit point by reversing the trace
		local traceFilter = {weapon}
		if IsValid(weapon.Owner) then
			table.insert(traceFilter, weapon.Owner)
		end
		local penetrationTrace = {
			start = tr.HitPos + (bulletDir * penDistance),  -- Start far ahead
			endpos = tr.HitPos,  -- Trace back to entry
			filter = traceFilter,
			mask = MASK_SHOT
		}

		local trace = util.TraceLine(penetrationTrace)

		-- If trace starts in solid (wall too thick) or didn't find exit, no penetration
		if trace.StartSolid or trace.Fraction >= 1.0 or trace.Fraction <= 0.0 then
			return false
		end

		exitPos = trace.HitPos

		-- Create penetration effect (TFA-style)
		-- Show bullet continuing from exit point forward (shorter, more realistic)
		local ballisticsData = nil
		if M9KR and M9KR.Ballistics and M9KR.Ballistics.GetData and weapon.ShellModel then
			ballisticsData = M9KR.Ballistics.GetData(weapon.ShellModel)
		end
		local penetration = ballisticsData and ballisticsData.penetration or 14

		local effectdata = EffectData()
		effectdata:SetStart(exitPos)  -- Exit point (where bullet emerges)
		effectdata:SetOrigin(exitPos + (tr.Normal * 20))  -- Show 20 units forward (subtle tracer)
		effectdata:SetMagnitude(penetration)  -- Pass penetration for caliber-based scaling
		util.Effect("m9kr_penetrate", effectdata)
	end

	-- Create near-miss effects (bullet whizzing sound for nearby players)
	if SERVER then
		CreateNearMissEffects(weapon, tr.StartPos, tr.HitPos, attacker)
	end

	-- Fire penetrating bullet - ensure attacker is valid and can fire
	if not IsValid(attacker) or not attacker.FireBullets then return false end

	-- Use timer to prevent crashing (must execute outside bullet callback context)
	if SERVER then
		timer.Simple(0, function()
			if not IsValid(attacker) then return end
			attacker:FireBullets({
				Attacker = attacker,
				Damage = paininfo.Damage * 0.75,  -- 75% damage after penetration
				Force = paininfo.Force,
				Num = 1,
				Src = exitPos,
				Dir = tr.Normal,  -- tr.Normal is the bullet direction in callback context
				HullSize = 0,
				Spread = Vector(0, 0, 0),
				Tracer = 0,  -- No tracers for penetration bullets
				TracerName = "",
				Callback = function(cb_attacker, tracedata, dmginfo)
					-- Match legacy M9K: check prediction in nested callbacks
					if not IsFirstTimePredicted() then return end
					if not IsValid(weapon) then return end
					if not IsValid(cb_attacker) then return end
					if not tracedata or not dmginfo then return end
					local paininfo_cb = {
						Damage = dmginfo:GetDamage(),
						Force = dmginfo:GetDamageForce()
					}
					if weapon and weapon.BulletPenetrate then weapon:BulletPenetrate(bouncenum + 1, cb_attacker, tracedata, paininfo_cb) end
				end
			})
		end)
	end

	return true
end

--[[
	Main penetration router
	Checks m9kr_penetration_mode ConVar and routes to appropriate system
]]--
function M9KR.Penetration.CalculatePenetration(weapon, bouncenum, attacker, tr, paininfo)
	-- Match legacy M9K pattern: check prediction, not realm
	if not IsFirstTimePredicted() then return false end
	if not IsValid(weapon) then return false end

	local cvar = GetConVar("m9kr_penetration_mode")
	if not cvar then return false end
	local penetrationMode = cvar:GetInt()

	-- Mode 0: Disabled
	if penetrationMode == 0 then return false end

	-- Mode 2: Vanilla M9K penetration
	if penetrationMode == 2 then return M9KR.Penetration.VanillaPenetration(weapon, bouncenum, attacker, tr, paininfo) end

	-- Mode 1 (default): Dynamic ballistics-based penetration
	return M9KR.Penetration.DynamicPenetration(weapon, bouncenum, attacker, tr, paininfo)
end

print("[M9K:R] Penetration system loaded")