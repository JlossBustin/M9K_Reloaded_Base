--[[
	M9K Reloaded - Ballistics Database

	Real-world ballistics data for penetration and ricochet calculations.
	Based on shell casing models to provide accurate, caliber-specific performance.

	Penetration values represent maximum penetration depth in inches through soft materials.
	Values are scaled for game balance while maintaining realistic proportions between calibers.
]]--

M9KR = M9KR or {}
M9KR.Ballistics = M9KR.Ballistics or {}

--[[
	Ballistics Database Structure:

	[shell_model_path] = {
		caliber = "Display name",
		penetration = number,     -- Max penetration depth (Source units, ~1.33 units per inch)
		maxRicochet = number,     -- Maximum number of ricochets
		canRicochet = boolean,    -- Can ricochet off hard surfaces
		armorPiercing = boolean,  -- Can penetrate metal (anti-materiel rounds)
	}

	Penetration Scale Guide (Source engine units):
	- Pistol calibers (9mm, .45 ACP): 8-12 units
	- Intermediate rifle (5.56, 5.45, 7.62x39): 14-18 units
	- Full-power rifle (7.62 NATO, .308): 18-22 units
	- Magnum rifle (.300 Win, .338 Lapua): 22-28 units
	- Anti-materiel (.50 BMG, .408 CheyTac): 30-40 units
	- Shotgun (buckshot): 4-6 units
	- Shotgun (slug): 10-14 units

	Note: Material modifiers apply (wood/flesh: 2x, concrete: 0.5x, metal: varies by AP)
]]--

M9KR.Ballistics.Database = {
	-- Pistol Calibers
	["models/shells/9x18mm.mdl"] = {
		caliber = "9x18mm Makarov",
		penetration = 8,
		maxRicochet = 2,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/9x19mm.mdl"] = {
		caliber = "9x19mm Parabellum",
		penetration = 9,
		maxRicochet = 2,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/45acp.mdl"] = {
		caliber = ".45 ACP",
		penetration = 10,
		maxRicochet = 2,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/5_7x28mm.mdl"] = {
		caliber = "5.7x28mm",
		penetration = 12,
		maxRicochet = 3,
		canRicochet = true,
		armorPiercing = false,
	},

	[".38 Special"] = {
		caliber = ".38 Special",
		penetration = 10,
		maxRicochet = 2,
		canRicochet = true,
		armorPiercing = false,
	},

	[".455 Webley"] = {
		caliber = ".455 Webley",
		penetration = 11,
		maxRicochet = 2,
		canRicochet = true,
		armorPiercing = false,
	},

	-- Magnum Pistol Calibers
	["models/shells/357mag.mdl"] = {
		caliber = ".357 Magnum",
		penetration = 12,
		maxRicochet = 3,
		canRicochet = true,
		armorPiercing = false,
	},

	[".44 Magnum"] = {
		caliber = ".44 Magnum",
		penetration = 13,
		maxRicochet = 3,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/50ae.mdl"] = {
		caliber = ".50 AE",
		penetration = 14,
		maxRicochet = 4,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/454casull.mdl"] = {
		caliber = ".454 Casull",
		penetration = 15,
		maxRicochet = 4,
		canRicochet = true,
		armorPiercing = false,
	},

	[".500 S&W Magnum"] = {
		caliber = ".500 S&W Magnum",
		penetration = 16,
		maxRicochet = 4,
		canRicochet = true,
		armorPiercing = false,
	},

	-- Intermediate Rifle Calibers
	["models/shells/5_45x39mm.mdl"] = {
		caliber = "5.45x39mm",
		penetration = 14,
		maxRicochet = 4,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/5_56x45mm.mdl"] = {
		caliber = "5.56x45mm",
		penetration = 16,
		maxRicochet = 5,
		canRicochet = true,
		armorPiercing = false,
	},

	-- Caseless Ammunition (futuristic/experimental)
	["6.8mm Caseless"] = {
		caliber = "6.8mm Caseless",
		penetration = 17,
		maxRicochet = 5,
		canRicochet = true,
		armorPiercing = false,
	},

	["10x24mm Caseless"] = {
		caliber = "10x24mm Caseless",
		penetration = 18,
		maxRicochet = 4,
		canRicochet = true,
		armorPiercing = false,
	},

	-- Electromagnetic Kinetic Slug (EMSSS-12)
	["Kinetic Slug"] = {
		caliber = "Kinetic Slug",
		penetration = 25,
		maxRicochet = 3,
		canRicochet = true,
		armorPiercing = true,
	},

	["models/shells/7_62x39mm.mdl"] = {
		caliber = "7.62x39mm",
		penetration = 17,
		maxRicochet = 5,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/7_62x39mm_live.mdl"] = {
		caliber = "7.62x39mm",
		penetration = 17,
		maxRicochet = 5,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/300blk.mdl"] = {
		caliber = ".300 Blackout",
		penetration = 18,
		maxRicochet = 5,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/9x39mm.mdl"] = {
		caliber = "9x39mm",
		penetration = 15,
		maxRicochet = 4,
		canRicochet = true,
		armorPiercing = true,  -- AP rounds standard for AS VAL
	},

	-- Large-Bore Intermediate Calibers
	["models/shells/50beowulf_shell.mdl"] = {
		caliber = "12.7x42mmRB",
		penetration = 22,
		maxRicochet = 6,
		canRicochet = true,
		armorPiercing = false,
	},

	-- Full-Power Rifle Calibers
	["models/shells/7_62x51mm.mdl"] = {
		caliber = "7.62x51mm",
		penetration = 20,
		maxRicochet = 6,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/shell_762nato.mdl"] = {
		caliber = "7.62x51mm",
		penetration = 20,
		maxRicochet = 6,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/7_62x54mm.mdl"] = {
		caliber = "7.62x54mmR",
		penetration = 21,
		maxRicochet = 6,
		canRicochet = true,
		armorPiercing = false,
	},

	-- Magnum Rifle Calibers
	["models/shells/300win.mdl"] = {
		caliber = ".300 Winchester",
		penetration = 24,
		maxRicochet = 7,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/338lapua.mdl"] = {
		caliber = ".338 Lapua",
		penetration = 28,
		maxRicochet = 8,
		canRicochet = false,
		armorPiercing = true,
	},

	["models/shells/shell_338mag.mdl"] = {
		caliber = ".338 Magnum",
		penetration = 26,
		maxRicochet = 7,
		canRicochet = true,
		armorPiercing = false,
	},

	-- Anti-Materiel Calibers
	["models/shells/408cheytac.mdl"] = {
		caliber = ".408 CheyTac",
		penetration = 35,
		maxRicochet = 10,
		canRicochet = true,
		armorPiercing = true,
	},

	["models/shells/50bmg.mdl"] = {
		caliber = ".50 BMG",
		penetration = 40,
		maxRicochet = 10,
		canRicochet = true,
		armorPiercing = true,
	},

	["models/shells/12_7x55mm.mdl"] = {
		caliber = "12.7x55mm",
		penetration = 38,
		maxRicochet = 10,
		canRicochet = true,
		armorPiercing = true,
	},

	["models/shells/23mm.mdl"] = {
		caliber = "Shrapnel-10 Buckshot",
		penetration = 45,
		maxRicochet = 12,
		canRicochet = true,
		armorPiercing = true,
	},

	-- Shotgun Ammunition
	["M296 8-Gauge Magnum"] = {
		caliber = "M296 8-Gauge Magnum",
		penetration = 7,
		maxRicochet = 0,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/12g_buck.mdl"] = {
		caliber = "12g Buckshot",
		penetration = 5,
		maxRicochet = 0,
		canRicochet = true,  -- Individual pellets can ricochet
		armorPiercing = false,
	},

	["models/shells/12g_bucknball.mdl"] = {
		caliber = "12g Buck-n-Ball",
		penetration = 6,
		maxRicochet = 0,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/12g_slug.mdl"] = {
		caliber = "12g Slug",
		penetration = 12,
		maxRicochet = 1,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/shell_13gauge.mdl"] = {
		caliber = "13 Gauge",
		penetration = 4,
		maxRicochet = 0,
		canRicochet = true,
		armorPiercing = false,
	},

	["models/shells/shell_38gauge.mdl"] = {
		caliber = "38 Gauge",
		penetration = 3,
		maxRicochet = 0,
		canRicochet = true,
		armorPiercing = false,
	},

	-- .410 Bore (Taurus Judge) - small-bore revolver shotshell
	-- Lower penetration than 12g due to smaller payload and shorter barrel
	-- Individual pellets can ricochet off hard surfaces
	[".410 Bore"] = {
		caliber = ".410 Bore",
		penetration = 4,
		maxRicochet = 0,
		canRicochet = true,
		armorPiercing = false,
	},
}

--[[
	Get ballistics data for a weapon based on its shell model
	Returns ballistics table or nil if not found
]]--
function M9KR.Ballistics.GetData(shellModel)
	if not shellModel or shellModel == "" then
		return nil
	end

	-- First, try exact match (for custom ammo types like "6.8mm Caseless")
	if M9KR.Ballistics.Database[shellModel] then
		return M9KR.Ballistics.Database[shellModel]
	end

	-- Normalize the path (handle both "models/shells/..." and just the filename)
	local normalizedPath = string.lower(shellModel)
	if string.sub(normalizedPath, 1, 7) ~= "models/" then
		normalizedPath = "models/shells/" .. normalizedPath
	end
	if string.sub(normalizedPath, -4) ~= ".mdl" then
		normalizedPath = normalizedPath .. ".mdl"
	end

	return M9KR.Ballistics.Database[normalizedPath]
end

--[[
	Get penetration value for a weapon
	Returns penetration depth or default value if not found
]]--
function M9KR.Ballistics.GetPenetration(shellModel, defaultValue)
	local data = M9KR.Ballistics.GetData(shellModel)
	if data then
		return data.penetration
	end
	return defaultValue or 14  -- Default to intermediate rifle penetration
end

--[[
	Get maximum ricochet count for a weapon
	Returns max ricochet count or default value if not found
]]--
function M9KR.Ballistics.GetMaxRicochet(shellModel, defaultValue)
	local data = M9KR.Ballistics.GetData(shellModel)
	if data then
		return data.maxRicochet
	end
	return defaultValue or 4  -- Default to intermediate rifle ricochet
end

--[[
	Check if weapon can ricochet
	Returns boolean
]]--
function M9KR.Ballistics.CanRicochet(shellModel, defaultValue)
	local data = M9KR.Ballistics.GetData(shellModel)
	if data then
		return data.canRicochet
	end
	return defaultValue or false
end

--[[
	Check if weapon can penetrate armor (metal surfaces)
	Returns boolean
]]--
function M9KR.Ballistics.IsArmorPiercing(shellModel, defaultValue)
	local data = M9KR.Ballistics.GetData(shellModel)
	if data then
		return data.armorPiercing
	end
	return defaultValue or false
end

print("[M9K:R] Ballistics database loaded with " .. table.Count(M9KR.Ballistics.Database) .. " calibers")
