--[[
	M9K Reloaded - Tracer System

	Handles tracer frequency and appearance based on ballistics data.
	Real-world military tracer ratios vary by caliber and weapon class.

	ConVar: m9kr_tracer_mode
	0 = Disabled (no tracers)
	1 = Dynamic (ballistics-based tracer frequency by caliber)
	2 = Vanilla (original M9K tracer logic)
]]--

M9KR = M9KR or {}
M9KR.Tracers = M9KR.Tracers or {}

-- Create ConVar for tracer mode (server-only)
if SERVER then
	CreateConVar("m9kr_tracer_mode", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED},
		"Tracer system mode: 0 = Disabled, 1 = Dynamic (ballistics-based), 2 = Vanilla (M9K ammo-based)", 0, 2)
end

--[[
	Dynamic Tracer Frequency Database

	Based on real-world military tracer ratios:
	- Pistols/SMGs: 1:5 (every 5th round is a tracer)
	- Rifles: 1:4 (every 4th round)
	- Machine Guns: 1:3 (every 3rd round)
	- Heavy/Anti-Materiel: 1:2 (every 2nd round)

	Fields:
	- tracerFrequency: How often a tracer appears (1 = every shot, 5 = every 5th shot)
	- tracerType: Visual style (0 = standard, 1 = heavy)
	- tracerColor: RGB color {r, g, b} for the tracer beam
	- tracerWidth: Beam width in units

	REALISTIC TRACER COLORS BY COUNTRY/CALIBER:
	- Red: Western/NATO ammunition (most common modern standard)
	- Green: Russian/Soviet and Chinese ammunition
	- White: British and some older NATO rounds
	- Yellow/Orange: Incendiary rounds, some Asian ammunition
	- Purple-Red: Heavy anti-materiel rounds (.50 BMG+) - iconic, lingering red with purple tint

	DATABASE MATCHES ACTUAL MODELS IN models/shells/ DIRECTORY
]]--
M9KR.Tracers.Database = {
	-- ========== PISTOL CALIBERS (1:5 ratio) ==========

	-- Russian/Soviet Pistol Calibers - Green tracers
	["models/shells/9x18mm.mdl"] = {tracerFrequency = 5, tracerType = 0, tracerColor = {100, 255, 120}, tracerWidth = 2.5},  -- 9x18mm Makarov (Russian) - bright green

	-- NATO/Western Pistol Calibers - Red tracers
	["models/shells/9x19mm.mdl"] = {tracerFrequency = 5, tracerType = 0, tracerColor = {255, 80, 80}, tracerWidth = 2.5},   -- 9x19mm Parabellum (NATO) - red
	["models/shells/45acp.mdl"] = {tracerFrequency = 5, tracerType = 0, tracerColor = {255, 90, 70}, tracerWidth = 2.5},    -- .45 ACP (US) - red-orange
	["models/shells/5_7x28mm.mdl"] = {tracerFrequency = 5, tracerType = 0, tracerColor = {255, 100, 100}, tracerWidth = 2}, -- 5.7x28mm (NATO) - bright red

	[".38 Special"] = {tracerFrequency = 5, tracerType = 0, tracerColor = {255, 100, 80}, tracerWidth = 2.5},                   -- .38 Special (Colt Official Police) - red
	[".455 Webley"] = {tracerFrequency = 5, tracerType = 0, tracerColor = {240, 240, 220}, tracerWidth = 2.5},               -- .455 Webley (Webley MKVI) - white (British)

	-- Magnum Pistol Calibers - Red with orange tint (higher power)
	["models/shells/357mag.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 120, 60}, tracerWidth = 3},    -- .357 Magnum - red-orange
	[".44 Magnum"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 115, 55}, tracerWidth = 3},                 -- .44 Magnum (S&W M29) - red-orange
	["models/shells/50ae.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 110, 50}, tracerWidth = 3.5},    -- .50 AE (Desert Eagle) - intense red-orange
	["models/shells/454casull.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 100, 40}, tracerWidth = 3.5}, -- .454 Casull - very intense red-orange
	[".500 S&W Magnum"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 95, 35}, tracerWidth = 3.5},           -- .500 S&W Magnum (S&W M500) - intense red-orange

	-- ========== INTERMEDIATE RIFLE CALIBERS (1:4 ratio) ==========

	-- Russian/Soviet Rifle Calibers - Green tracers
	["models/shells/5_45x39mm.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {120, 255, 100}, tracerWidth = 3},    -- 5.45x39mm (AK-74, Russian) - green
	["models/shells/7_62x39mm.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {100, 255, 80}, tracerWidth = 3.5},    -- 7.62x39mm (AK-47, Russian/Chinese) - bright green
	["models/shells/7_62x39mm_live.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {100, 255, 80}, tracerWidth = 3.5}, -- 7.62x39mm (alternate model) - bright green
	["models/shells/9x39mm.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {80, 255, 100}, tracerWidth = 3.5},       -- 9x39mm (VSS/VAL, Russian subsonic) - green

	-- NATO/Western Rifle Calibers - Red tracers
	["models/shells/5_56x45mm.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 90, 80}, tracerWidth = 3},  -- 5.56x45mm NATO (M16/M4/SCAR-L) - red
	["6.8mm Caseless"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 120, 50}, tracerWidth = 3.5},            -- 6.8mm Caseless (MR-C, futuristic) - orange-red
	["10x24mm Caseless"] = {tracerFrequency = 3, tracerType = 0, tracerColor = {255, 180, 60}, tracerWidth = 3.5},         -- 10x24mm Caseless (M41A Pulse Rifle) - bright orange-yellow
	["Kinetic Slug"] = {tracerFrequency = 2, tracerType = 1, tracerColor = {210, 230, 255}, tracerWidth = 5},              -- Kinetic Slug (EMSSS-12, electromagnetic) - near-white blue
	["models/shells/300blk.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 100, 70}, tracerWidth = 3.5}, -- .300 Blackout (AR-15 platform) - red-orange

	-- ========== LARGE-BORE INTERMEDIATE CALIBERS (1:4 ratio) ==========

	-- Western Large-Bore Calibers - Red-orange tracers (heavy hitting)
	["models/shells/50beowulf_shell.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 100, 70}, tracerWidth = 4},  -- .50 Beowulf (12.7x42mm) - red-orange

	-- ========== FULL-POWER RIFLE CALIBERS (1:4 ratio) ==========

	-- NATO/Western Battle Rifle Calibers - Red with white tint (high visibility)
	["models/shells/7_62x51mm.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 100, 90}, tracerWidth = 4},   -- 7.62x51mm NATO (FAL/G3/SCAR-H) - bright red
	["models/shells/shell_762nato.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 100, 90}, tracerWidth = 4}, -- 7.62 NATO (alternate model) - bright red

	-- Russian/Soviet Battle Rifle Calibers - Green with yellow tint
	["models/shells/7_62x54mm.mdl"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {140, 255, 80}, tracerWidth = 4},  -- 7.62x54mmR (Mosin/SVD/PKM, Russian) - green-yellow

	-- ========== MAGNUM RIFLE CALIBERS (1:3 ratio) ==========

	-- Western Magnum Rifle Calibers - Red-orange (high power)
	["models/shells/300win.mdl"] = {tracerFrequency = 3, tracerType = 0, tracerColor = {255, 120, 60}, tracerWidth = 4.5},     -- .300 Win Mag - red-orange
	["models/shells/338lapua.mdl"] = {tracerFrequency = 3, tracerType = 0, tracerColor = {255, 110, 50}, tracerWidth = 5},     -- .338 Lapua Magnum - intense red-orange
	["models/shells/shell_338mag.mdl"] = {tracerFrequency = 3, tracerType = 0, tracerColor = {255, 110, 50}, tracerWidth = 5}, -- .338 Mag (alternate) - intense red-orange

	-- ========== ANTI-MATERIEL/HEAVY CALIBERS (1:2 ratio) - ICONIC PURPLE-RED ==========

	-- Heavy calibers get distinctive purple-red color that lingers more on the red side
	-- These are meant to be highly visible and intimidating
	["models/shells/408cheytac.mdl"] = {tracerFrequency = 2, tracerType = 1, tracerColor = {255, 60, 120}, tracerWidth = 6},  -- .408 CheyTac - purple-red (magenta tint)
	["models/shells/50bmg.mdl"] = {tracerFrequency = 2, tracerType = 1, tracerColor = {255, 50, 100}, tracerWidth = 6},       -- .50 BMG - iconic purple-red
	["models/shells/12_7x55mm.mdl"] = {tracerFrequency = 2, tracerType = 1, tracerColor = {255, 40, 140}, tracerWidth = 6},   -- 12.7x55mm (Russian heavy) - purple-red with more purple
	["models/shells/23mm.mdl"] = {tracerFrequency = 1, tracerType = 1, tracerColor = {255, 30, 160}, tracerWidth = 8},        -- 23mm autocannon - deep purple-red (almost magenta)

	-- ========== SHOTGUN CALIBERS (1:6 ratio) ==========

	-- 8-Gauge Magnum buckshot - NO tracers (buckshot rounds don't use tracers)
	["M296 8-Gauge Magnum"] = {tracerFrequency = 9999, tracerType = 0, tracerColor = {255, 255, 180}, tracerWidth = 2},

	-- Shotgun tracers - Yellow/white (uncommon, specialty loads)
	["models/shells/12g_buck.mdl"] = {tracerFrequency = 6, tracerType = 0, tracerColor = {255, 255, 180}, tracerWidth = 2},     -- 12 gauge buckshot - pale yellow
	["models/shells/12g_bucknball.mdl"] = {tracerFrequency = 6, tracerType = 0, tracerColor = {255, 255, 180}, tracerWidth = 2}, -- 12 gauge buck-n-ball - pale yellow
	["models/shells/12g_slug.mdl"] = {tracerFrequency = 5, tracerType = 0, tracerColor = {255, 240, 160}, tracerWidth = 3},      -- 12 gauge slug - brighter yellow
	["models/shells/shell_13gauge.mdl"] = {tracerFrequency = 6, tracerType = 0, tracerColor = {255, 255, 180}, tracerWidth = 2}, -- 13 gauge - pale yellow
	["models/shells/shell_38gauge.mdl"] = {tracerFrequency = 6, tracerType = 0, tracerColor = {255, 255, 180}, tracerWidth = 2}, -- 38 gauge - pale yellow

	-- .410 Bore buckshot - NO tracers (buckshot rounds don't use tracers)
	[".410 Bore"] = {tracerFrequency = 9999, tracerType = 0, tracerColor = {255, 255, 180}, tracerWidth = 2},
}

--[[
	Vanilla M9K Tracer Logic
	Based on ammo type, matching original M9K behavior
	Uses consistent white/orange color for standard tracers, red/orange for heavy
]]--
M9KR.Tracers.VanillaFrequency = {
	-- Standard calibers: White/orange tracers, consistent width
	["pistol"] = {tracerFrequency = 5, tracerType = 0, tracerColor = {255, 220, 180}, tracerWidth = 3},
	["357"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 220, 180}, tracerWidth = 3},
	["smg1"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 220, 180}, tracerWidth = 3},
	["ar2"] = {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 220, 180}, tracerWidth = 3},
	["SniperPenetratedRound"] = {tracerFrequency = 3, tracerType = 0, tracerColor = {255, 220, 180}, tracerWidth = 3},
	["buckshot"] = {tracerFrequency = 6, tracerType = 0, tracerColor = {255, 220, 180}, tracerWidth = 3},
	["slam"] = {tracerFrequency = 5, tracerType = 0, tracerColor = {255, 220, 180}, tracerWidth = 3},
	["AirboatGun"] = {tracerFrequency = 2, tracerType = 1, tracerColor = {255, 220, 180}, tracerWidth = 3},
}

--[[
	Get tracer data from shell model (Dynamic mode)
	Returns full tracer data table with frequency, type, color, and width
]]--
function M9KR.Tracers.GetTracerDataFromShell(shellModel)
	if not shellModel then
		return {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 220, 180}, tracerWidth = 3}
	end

	local data = M9KR.Tracers.Database[shellModel]
	if data then
		return data
	end

	-- Fallback: default rifle-like behavior
	return {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 220, 180}, tracerWidth = 3}
end

--[[
	Get tracer data from ammo type (Vanilla mode)
	Returns full tracer data table with frequency, type, color, and width
]]--
function M9KR.Tracers.GetTracerDataFromAmmo(ammoType)
	if not ammoType then
		return {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 220, 180}, tracerWidth = 3}
	end

	local data = M9KR.Tracers.VanillaFrequency[ammoType]
	if data then
		return data
	end

	-- Fallback: default rifle-like behavior
	return {tracerFrequency = 4, tracerType = 0, tracerColor = {255, 220, 180}, tracerWidth = 3}
end

--[[
	Get tracer name from type ID

	Returns empty string to avoid ugly HL2 default tracers.
	M9K uses m9kr_tracer effect for PCF particle tracers instead.
]]--
function M9KR.Tracers.GetTracerName(tracerType)
	-- Return empty string to disable HL2's ugly default tracers
	-- We use m9kr_tracer effect for proper PCF particle tracers
	return ""
end

--[[
	Spawn an animated beam tracer effect

	@param weapon - The weapon entity
	@param endPos - Tracer end position (bullet impact)
	@param tracerData - Tracer data table from database (contains color, width, type)
	@param attachment - Muzzle attachment index (optional, will be looked up if not provided)
]]--
function M9KR.Tracers.SpawnTracerEffect(weapon, endPos, tracerData, attachment)
	if not IsValid(weapon) then return end

	-- Use default values if tracerData is nil
	if not tracerData then
		tracerData = {tracerType = 0, tracerColor = {255, 220, 180}, tracerWidth = 3}
	end

	-- Get attachment index if not provided
	if not attachment then
		attachment = weapon:LookupAttachment(weapon.MuzzleAttachment or "muzzle")
		if not attachment or attachment <= 0 then
			attachment = 1
		end
	end

	-- Create the tracer effect
	local effectData = EffectData()
	effectData:SetOrigin(endPos)
	effectData:SetScale(tracerData.tracerType or 0)
	effectData:SetEntity(weapon)
	effectData:SetAttachment(attachment)

	-- Encode color into Start vector (RGB)
	local color = tracerData.tracerColor or {255, 220, 180}
	effectData:SetStart(Vector(color[1], color[2], color[3]))

	-- Encode width into Magnitude
	effectData:SetMagnitude(tracerData.tracerWidth or 3)

	util.Effect("m9kr_tracer", effectData)
end

--[[
	Main function: Determine if this shot should show a tracer

	@param weapon - The weapon entity
	@param shotNumber - Current shot count (for frequency calculation)
	@return shouldShowTracer (boolean), tracerName (string)
]]--
function M9KR.Tracers.ShouldShowTracer(weapon, shotNumber)
	if not IsValid(weapon) then
		return false, "Tracer"
	end

	local cvar = GetConVar("m9kr_tracer_mode")
	if not cvar then return false, "Tracer" end
	local tracerMode = cvar:GetInt()

	-- Mode 0: Disabled
	if tracerMode == 0 then
		return false, "Tracer"
	end

	local tracerData

	-- Mode 2: Vanilla (ammo-based)
	if tracerMode == 2 then
		local ammoType = weapon.Primary and weapon.Primary.Ammo or "ar2"
		tracerData = M9KR.Tracers.GetTracerDataFromAmmo(ammoType)
	else
		-- Mode 1 (default): Dynamic (shell model-based)
		local shellModel = weapon.ShellModel
		tracerData = M9KR.Tracers.GetTracerDataFromShell(shellModel)
	end

	-- Calculate if this shot should show a tracer based on frequency
	local shouldShow = (shotNumber % tracerData.tracerFrequency) == 0
	local tracerName = M9KR.Tracers.GetTracerName(tracerData.tracerType)

	return shouldShow, tracerName
end

--[[
	Helper function for penetration/ricochet systems
	Returns the tracer setting (0 or 1) and tracer name
]]--
function M9KR.Tracers.GetTracerForPenetration(weapon)
	if not IsValid(weapon) then
		return 0, "Tracer"
	end

	local cvar = GetConVar("m9kr_tracer_mode")
	if not cvar then return 0, "Tracer" end
	local tracerMode = cvar:GetInt()

	-- Mode 0: Disabled
	if tracerMode == 0 then
		return 0, "Tracer"
	end

	-- For penetration/ricochet, always show tracer if mode is enabled
	-- (If the original shot had a tracer, the penetration should too)
	local tracerData

	if tracerMode == 2 then
		-- Vanilla mode
		local ammoType = weapon.Primary and weapon.Primary.Ammo or "ar2"
		tracerData = M9KR.Tracers.GetTracerDataFromAmmo(ammoType)
	else
		-- Dynamic mode
		local shellModel = weapon.ShellModel
		tracerData = M9KR.Tracers.GetTracerDataFromShell(shellModel)
	end

	local tracerName = M9KR.Tracers.GetTracerName(tracerData.tracerType)

	return 1, tracerName
end

print("[M9K:R] Tracer system loaded with " .. table.Count(M9KR.Tracers.Database) .. " calibers")
