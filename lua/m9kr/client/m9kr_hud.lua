--[[
	M9K Reloaded - Client-Side HUD System

	Centralized HUD drawing for M9K weapons:
	- Weapon name (PrintName)
	- Fire mode indicator (SAFE / AUTO / SEMI / BURST)
	- Caliber (from ShellModel)
	- Magazine capacity + chamber (+1)
	- Reserve ammo (DefaultClip)

	This completely replaces GMod's default ammo display.
]]--

-- ConVar to toggle between custom HUD and standard GMod HUD
CreateClientConVar("m9kr_hud_mode", "1", true, false, "M9K:R HUD Mode: 0 = GMod Default, 1 = Custom M9K:R HUD", 0, 1)

-- Create custom fonts for HUD elements
surface.CreateFont("M9KR_AmmoLarge", {
	font = "Roboto",
	size = 120,
	weight = 700,
	antialias = true,
	shadow = true
})

surface.CreateFont("M9KR_AmmoSmall", {
	font = "Roboto",
	size = 40,
	weight = 500,
	antialias = true,
	shadow = true
})

surface.CreateFont("M9KR_Reserve", {
	font = "Roboto",
	size = 60,
	weight = 600,
	antialias = true,
	shadow = true
})

surface.CreateFont("M9KR_FireMode", {
	font = "Roboto",
	size = 28,
	weight = 600,
	antialias = true,
	shadow = true
})

surface.CreateFont("M9KR_WeaponName", {
	font = "Roboto",
	size = 24,
	weight = 700,
	antialias = true,
	shadow = true
})

surface.CreateFont("M9KR_Caliber", {
	font = "Roboto",
	size = 24,
	weight = 500,
	antialias = true,
	shadow = true
})

surface.CreateFont("M9KR_Health", {
	font = "Roboto",
	size = 110,  -- 10 less than M9KR_AmmoLarge (120)
	weight = 700,
	antialias = true,
	shadow = true
})

surface.CreateFont("M9KR_HealthLabel", {
	font = "Roboto",
	size = 24,
	weight = 500,
	antialias = true,
	shadow = true
})

surface.CreateFont("M9KR_Armor", {
	font = "Roboto",
	size = 110,  -- Same size as health
	weight = 700,
	antialias = true,
	shadow = true
})

surface.CreateFont("M9KR_ArmorLabel", {
	font = "Roboto",
	size = 24,
	weight = 500,
	antialias = true,
	shadow = true
})

-- Legacy font names for compatibility with weapon base code
-- These are created once globally instead of per-weapon to improve performance
local scale = ScrH() / 480
surface.CreateFont("M9K_ChamberPlus", {
	font = "HudDefault",
	size = math.floor(10 * scale),
	weight = 700,
	antialias = true,
})

surface.CreateFont("M9K_FireMode", {
	font = "HudDefault",
	size = math.floor(7 * scale),
	weight = 700,
	antialias = true,
})

-- M9K weapon base lookup (used throughout this file for base checks)
local M9K_BASES = {
	["carby_gun_base"] = true,
	["carby_shotty_base"] = true,
	["carby_scoped_base"] = true,
}

-- Idle fade tracking
local lastActivityTime = 0
local lastEyeAngles = Angle(0, 0, 0)
local IDLE_FADE_START = 3  -- Seconds before fade starts
local IDLE_FADE_ALPHA = 50  -- Alpha when idle (out of 255) - much more noticeable fade

-- Squad death animation tracking
local squadAnimData = {}  -- Stores {type, previousCount, currentCount, fadeStartTime}
local SQUAD_FADE_DURATION = 0.5  -- How long the death fade takes in seconds

-- Helper function to draw squad member icon (similar to default GMod HUD)
local function DrawSquadIcon(x, y, size, isMedic, alpha)
	local iconColor = Color(255, 255, 255, alpha)  -- White icons

	-- Draw person silhouette (more proportional)
	-- Head (rounded square, positioned at top)
	local headSize = size * 0.35
	local headX = x + (size * 0.5) - (headSize * 0.5)
	local headY = y
	draw.NoTexture()
	surface.SetDrawColor(iconColor)
	surface.DrawRect(headX, headY, headSize, headSize)

	-- Body (wider rectangle below head)
	-- Medics get slightly larger body to compensate for cross overlay
	local bodyWidth = isMedic and (size * 0.75) or (size * 0.7)
	local bodyHeight = isMedic and (size * 0.58) or (size * 0.55)
	local bodyX = x + (size * 0.5) - (bodyWidth * 0.5)
	local bodyY = y + headSize + (size * 0.05)
	surface.DrawRect(bodyX, bodyY, bodyWidth, bodyHeight)

	-- If medic, draw uniform cross centered on body
	if isMedic then
		-- Create a uniform, equal-armed cross (like a + symbol)
		local crossArmLength = size * 0.32  -- Total length of each arm
		local crossThickness = size * 0.11  -- Thickness of cross arms

		-- Center the cross on the body
		local crossCenterX = bodyX + (bodyWidth * 0.5)  -- Horizontal center of body
		local crossCenterY = bodyY + (bodyHeight * 0.5)  -- Vertical center of body

		surface.SetDrawColor(255, 0, 0, alpha)  -- Red cross

		-- Vertical bar (centered)
		surface.DrawRect(
			crossCenterX - (crossThickness * 0.5),
			crossCenterY - (crossArmLength * 0.5),
			crossThickness,
			crossArmLength
		)

		-- Horizontal bar (centered)
		surface.DrawRect(
			crossCenterX - (crossArmLength * 0.5),
			crossCenterY - (crossThickness * 0.5),
			crossArmLength,
			crossThickness
		)
	end
end

--[[
	Helper: Extract caliber name from shell model path
	Tries to use ballistics database first for accurate names, falls back to parsing filename
	Example: "models/shells/5_56x45mm.mdl" -> "5.56x45mm"
]]--
local function GetCaliberFromShell(shellModel)
	if not shellModel or shellModel == "" then return "UNKNOWN" end

	-- Try to get caliber name from ballistics database first (preserves proper casing)
	if M9KR and M9KR.Ballistics and M9KR.Ballistics.GetData then
		local ballisticsData = M9KR.Ballistics.GetData(shellModel)
		if ballisticsData and ballisticsData.caliber then
			-- Return as-is from database (already has proper casing like "7.62x39mm")
			return ballisticsData.caliber
		end
	end

	-- Fallback: parse shell model filename
	-- Extract filename from path
	local filename = string.GetFileFromFilename(shellModel)

	-- Remove .mdl extension
	filename = string.Replace(filename, ".mdl", "")

	-- Remove common model suffixes (_shell, _casing, etc.)
	filename = string.Replace(filename, "_shell", "")
	filename = string.Replace(filename, "_casing", "")

	-- Replace underscores with periods for caliber format
	-- "5_56x45mm" -> "5.56x45mm"
	filename = string.Replace(filename, "_", ".")

	-- Keep "mm" lowercase but uppercase letters (NATO, etc.)
	-- This handles parsed filenames properly
	return filename
end

--[[
	Helper: Calculate HUD alpha based on idle time
]]--
local function GetHUDAlpha()
	local idleTime = CurTime() - lastActivityTime

	if idleTime < IDLE_FADE_START then
		return 255
	else
		-- Fade to idle alpha
		local fadeProgress = math.min((idleTime - IDLE_FADE_START) / 1, 1)
		return Lerp(fadeProgress, 255, IDLE_FADE_ALPHA)
	end
end

--[[
	HUDPaint hook - Draw complete custom HUD
]]--
hook.Add("HUDPaint", "M9KR_HUD_Draw", function()
	-- Check if custom HUD is enabled
	if GetConVar("m9kr_hud_mode"):GetInt() == 0 then return end

	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return end

	-- Only draw for M9K weapons
	if not weapon.Base or not M9K_BASES[weapon.Base] then
		return
	end

	local scrW = ScrW()
	local scrH = ScrH()

	-- ==============================================
	-- HUD POSITION CONFIGURATION
	-- Modify these values to reposition HUD elements
	-- ==============================================

	-- Weapon Name and Caliber Position (centered, on same line)
	-- This aligns with the bottom of the health HUD box
	local weaponInfoY = scrH - 40  -- Bottom edge aligned with health HUD
	local weaponInfoCenterX = scrW - 215  -- Center X position for both

	-- Fire Mode Position (centered, above weapon name)
	local fireModeX = scrW - 215  -- Center X position
	local fireModeY = scrH - 65  -- Above weapon name/caliber

	-- Magazine Capacity Position
	local magazineX = scrW - 240
	local magazineY = scrH - 75  -- Above fire mode

	-- Chamber "+1" Position (offset from magazine)
	local chamberOffsetX = 0  -- Pixels to the right of magazine count
	local chamberY = scrH - 150  -- Above magazine

	-- Dot Separator Position (between magazine and reserves)
	local dotSeparatorX = scrW - 215
	local dotSeparatorY = scrH - 110

	-- Reserve Ammo Position
	local reserveX = scrW - 190
	local reserveY = scrH - 90

	-- Health Position (mirroring magazine capacity on the left side)
	local healthX = 240  -- Mirror of magazineX (scrW - 240), but on left side
	local healthY = scrH - 75  -- Same Y as magazine
	local healthLabelY = scrH - 65  -- Higher up, closer to health number (like fire mode under magazine)

	-- Armor Position (left side, next to health)
	local armorX = 440  -- Left side, closer to health with ~140px spacing
	local armorY = scrH - 75  -- Same Y as health and magazine
	local armorLabelY = scrH - 65  -- Same as health label

	-- ==============================================
	-- END POSITION CONFIGURATION
	-- ==============================================

	-- Get HUD alpha
	local alpha = GetHUDAlpha()
	local white = Color(255, 255, 255, alpha)
	local whiteFaded = Color(255, 255, 255, alpha * 0.35)  -- Darker caliber and reserve text

	-- Get weapon data
	local weaponName = weapon.PrintName or "UNKNOWN"
	local clip = weapon:Clip1()
	local maxClip = weapon.Primary and weapon.Primary.ClipSize or 30
	local reserve = weapon:Ammo1()
	local caliber = GetCaliberFromShell(weapon.ShellModel)

	-- Check if chambered
	local isChambered = clip > maxClip
	local displayClip = isChambered and maxClip or clip

	-- Get fire mode
	local fireMode = "SAFE"
	local fireModeColor = Color(255, 100, 130, alpha)  -- Pink-red for SAFE

	if weapon.GetIsOnSafe and weapon:GetIsOnSafe() then
		fireMode = "SAFETY"
		fireModeColor = Color(255, 100, 130, alpha)  -- Pink-red
	elseif weapon.FireModes and weapon.GetCurrentFireMode then
		local mode = weapon:GetCurrentFireMode()
		if mode then
			fireMode = weapon.FireModeNames and weapon.FireModeNames[mode] or string.upper(mode)
			fireModeColor = Color(100, 255, 100, alpha)  -- Green when not on safe
		end
	end

	-- Draw HUD elements

	-- 1. Fire mode (centered)
	draw.SimpleText(fireMode, "M9KR_FireMode", fireModeX, fireModeY,
		fireModeColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

	-- 2. Weapon name and caliber (centered as combined unit with dot separator)
	-- Calculate text widths for proper centering
	surface.SetFont("M9KR_WeaponName")
	local weaponNameWidth = surface.GetTextSize(weaponName)
	surface.SetFont("M9KR_Caliber")
	local caliberWidth = surface.GetTextSize(caliber)
	local dotWidth = surface.GetTextSize("•")

	-- Total width including spacing and dot
	local spacing = 8  -- Space on each side of the dot
	local totalWidth = weaponNameWidth + spacing + dotWidth + spacing + caliberWidth

	-- Calculate starting position (center the entire block)
	local startX = weaponInfoCenterX - (totalWidth / 2)

	-- Draw weapon name (white)
	draw.SimpleText(weaponName, "M9KR_WeaponName", startX, weaponInfoY,
		white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

	-- Draw dot separator (white, centered)
	draw.SimpleText("•", "M9KR_Caliber", startX + weaponNameWidth + spacing, weaponInfoY,
		white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

	-- Draw caliber (faded white)
	draw.SimpleText(caliber, "M9KR_Caliber", startX + weaponNameWidth + spacing + dotWidth + spacing, weaponInfoY,
		whiteFaded, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

	-- 4. Magazine capacity with subtle color transition
	-- Calculate magazine fraction (how full it is)
	local magFrac = math.Clamp(displayClip / maxClip, 0, 1)

	-- Subtle transition from white (full) to safety red (empty)
	-- Uses the same red as safety fire mode: Color(255, 100, 130)
	local magColor = Color(
		255,  -- Red stays at 255
		Lerp(magFrac, 100, 255),  -- Green: 100 (empty) -> 255 (full)
		Lerp(magFrac, 130, 255),  -- Blue: 130 (empty) -> 255 (full)
		alpha
	)

	draw.SimpleText(displayClip, "M9KR_AmmoLarge", magazineX, magazineY,
		magColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)

	-- 5. "+1" chamber indicator (if chambered)
	if isChambered then
		draw.SimpleText("+1", "M9KR_AmmoSmall", magazineX + chamberOffsetX, chamberY,
			Color(100, 255, 100, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	end

	-- 6. Dot separator between magazine and reserves
	draw.SimpleText("•", "M9KR_Caliber", dotSeparatorX, dotSeparatorY,
		white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

	-- 7. Reserve ammo (left-aligned so magazine capacity doesn't move when reserves change)
	draw.SimpleText(reserve, "M9KR_Reserve", reserveX, reserveY,
		whiteFaded, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

	-- 8. Health (bottom-left corner, matching ammo styling)
	local health = ply:Health()
	local maxHealth = ply:GetMaxHealth()

	-- Calculate health color gradient with better color transitions:
	-- 100% - 75%: Green -> Light Green
	-- 75% - 50%: Light Green -> Yellow
	-- 50% - 25%: Yellow -> Orange
	-- 25% - 0%: Orange -> Red
	local healthFrac = math.Clamp(health / maxHealth, 0, 1)
	local healthColor

	if healthFrac > 0.75 then
		-- Green to light green (100% to 75%)
		local t = (healthFrac - 0.75) / 0.25
		healthColor = Color(Lerp(t, 150, 100), 255, Lerp(t, 150, 100), alpha)
	elseif healthFrac > 0.5 then
		-- Light green to yellow (75% to 50%)
		local t = (healthFrac - 0.5) / 0.25
		healthColor = Color(Lerp(t, 255, 150), 255, Lerp(t, 0, 150), alpha)
	elseif healthFrac > 0.25 then
		-- Yellow to orange (50% to 25%)
		local t = (healthFrac - 0.25) / 0.25
		healthColor = Color(255, Lerp(t, 150, 255), 0, alpha)
	else
		-- Orange to red (25% to 0%)
		local t = healthFrac / 0.25
		healthColor = Color(255, Lerp(t, 0, 150), 0, alpha)
	end

	-- Draw health value (reduced font size, centered to handle variable digit counts)
	local healthStr = tostring(health)
	surface.SetFont("M9KR_Health")
	local healthWidth = surface.GetTextSize(healthStr)
	local healthCenterX = healthX - (healthWidth / 2)

	draw.SimpleText(healthStr, "M9KR_Health", healthCenterX, healthY,
		healthColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

	-- Draw "HEALTH" label (faded white, centered under the number)
	draw.SimpleText("HEALTH", "M9KR_HealthLabel", healthCenterX, healthLabelY,
		whiteFaded, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

	-- 9. Armor (right side, matching health styling)
	local armor = ply:Armor()

	-- Only display armor if player has any
	if armor > 0 then
		-- Calculate armor color gradient (blue/cyan tones for armor):
		-- 100% - 75%: Bright cyan
		-- 75% - 50%: Cyan to light blue
		-- 50% - 25%: Light blue to blue
		-- 25% - 0%: Blue to dark blue
		local armorFrac = math.Clamp(armor / 100, 0, 1)  -- Assume max armor is 100
		local armorColor

		if armorFrac > 0.75 then
			-- Bright cyan (100% to 75%)
			local t = (armorFrac - 0.75) / 0.25
			armorColor = Color(Lerp(t, 150, 100), Lerp(t, 255, 255), 255, alpha)
		elseif armorFrac > 0.5 then
			-- Cyan to light blue (75% to 50%)
			local t = (armorFrac - 0.5) / 0.25
			armorColor = Color(Lerp(t, 200, 150), Lerp(t, 220, 255), 255, alpha)
		elseif armorFrac > 0.25 then
			-- Light blue to blue (50% to 25%)
			local t = (armorFrac - 0.25) / 0.25
			armorColor = Color(Lerp(t, 220, 200), Lerp(t, 200, 220), 255, alpha)
		else
			-- Blue to darker blue (25% to 0%)
			local t = armorFrac / 0.25
			armorColor = Color(Lerp(t, 100, 220), Lerp(t, 150, 200), 255, alpha)
		end

		-- Draw armor value (centered to handle variable digit counts)
		local armorStr = tostring(armor)
		surface.SetFont("M9KR_Armor")
		local armorWidth = surface.GetTextSize(armorStr)
		local armorCenterX = armorX - (armorWidth / 2)

		draw.SimpleText(armorStr, "M9KR_Armor", armorCenterX, armorY,
			armorColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

		-- Draw "ARMOR" label (faded white, centered under the number)
		draw.SimpleText("ARMOR", "M9KR_ArmorLabel", armorCenterX, armorLabelY,
			whiteFaded, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end

	-- 10. Squad Following Indicator (bottom center, M9KR styled with icons)
	-- Get squad data from networked variable (set by server-side tracker)
	local squadDataJSON = ply:GetNWString("M9KR_SquadData", "")
	local squadCount = ply:GetNWInt("M9KR_SquadCount", 0)

	-- Only draw the squad indicator if there are squad members
	if squadCount > 0 and squadDataJSON ~= "" then
		local squadData = util.JSONToTable(squadDataJSON) or {}
		local squadY = scrH - 80  -- Bottom of screen
		local squadLabelY = scrH - 55  -- Label below icons

		-- Update animation data for death fades
		for npcType, currentCount in pairs(squadData) do
			if not squadAnimData[npcType] then
				squadAnimData[npcType] = {count = currentCount, animCount = currentCount, fadeStart = 0}
			else
				local animData = squadAnimData[npcType]
				-- Detect count decrease (death)
				if currentCount < animData.count then
					animData.fadeStart = CurTime()
					animData.animCount = animData.count  -- Keep old count for animation
				end
				animData.count = currentCount
			end
		end

		-- Build display list of NPC types with counts > 0
		local displayTypes = {}
		for npcType, count in pairs(squadData) do
			if count > 0 then
				table.insert(displayTypes, {type = npcType, count = count})
			end
		end

		-- Calculate total width for centering
		local iconSize = 32
		local spacing = 10
		local iconTextSpacing = 2  -- Reduced from 5 to bring text closer to icons
		local typeSpacing = 15  -- Space between different NPC types
		local totalWidth = 0

		for i, typeData in ipairs(displayTypes) do
			-- Icon + "x" + number + spacing
			surface.SetFont("M9KR_Caliber")
			local numText = "x " .. typeData.count
			local textW, _ = surface.GetTextSize(numText)
			totalWidth = totalWidth + iconSize + iconTextSpacing + textW
			if i < #displayTypes then
				totalWidth = totalWidth + typeSpacing
			end
		end

		-- Draw centered icons with counts
		local startX = (scrW / 2) - (totalWidth / 2)
		local currentX = startX

		for i, typeData in ipairs(displayTypes) do
			local animData = squadAnimData[typeData.type]
			local isMedic = (typeData.type == "medic")

			-- Calculate death fade color
			local numColor = Color(255, 255, 255, alpha)
			if animData and animData.fadeStart > 0 and CurTime() - animData.fadeStart < SQUAD_FADE_DURATION then
				-- Animating: fade from white to red
				local fadeProg = (CurTime() - animData.fadeStart) / SQUAD_FADE_DURATION
				numColor = Color(255, Lerp(fadeProg, 255, 0), Lerp(fadeProg, 255, 0), alpha)

				-- Display animated count during fade
				typeData.count = animData.animCount
			elseif animData and CurTime() - animData.fadeStart >= SQUAD_FADE_DURATION then
				-- Animation done, update animated count
				animData.animCount = animData.count
				animData.fadeStart = 0
			end

			-- Draw custom squad icon (golden silhouette)
			DrawSquadIcon(currentX, squadY - iconSize, iconSize, isMedic, alpha)

			-- Draw count next to icon
			local numText = "x " .. typeData.count
			draw.SimpleText(numText, "M9KR_Caliber", currentX + iconSize + iconTextSpacing, squadY - (iconSize / 2),
				numColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			-- Move to next position
			surface.SetFont("M9KR_Caliber")
			local textW, _ = surface.GetTextSize(numText)
			currentX = currentX + iconSize + iconTextSpacing + textW + typeSpacing
		end

		-- Draw "SQUAD" label below
		draw.SimpleText("SQUAD", "M9KR_HealthLabel", scrW / 2, squadLabelY,
			whiteFaded, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end
end)

--[[
	Track player activity to reset fade timer
]]--
hook.Add("Think", "M9KR_HUD_ActivityTracker", function()
	-- Only track if custom HUD is enabled
	if GetConVar("m9kr_hud_mode"):GetInt() == 0 then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return end

	-- Only track for M9K weapons
	if not weapon.Base or not M9K_BASES[weapon.Base] then
		return
	end

	-- Check for mouse movement (view angle changes)
	local currentAngles = ply:EyeAngles()
	if currentAngles.p ~= lastEyeAngles.p or currentAngles.y ~= lastEyeAngles.y then
		lastActivityTime = CurTime()
		lastEyeAngles = currentAngles
	end

	-- Reset fade timer on any key activity
	if ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2) or ply:KeyDown(IN_RELOAD) or
	   ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT) or
	   ply:KeyDown(IN_JUMP) or ply:KeyDown(IN_DUCK) or ply:KeyDown(IN_SPEED) then
		lastActivityTime = CurTime()
	end
end)

--[[
	HUDShouldDraw - INSTANTLY hide default HUD for M9K weapons
	NO caching, NO delays - check weapon base EVERY time this is called
]]--
local HUD_MANAGED = {
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true,
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudSquadStatus"] = true,
	["CHudCrosshair"] = true,
}

local HUD_HIDDEN = {
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true,
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudSquadStatus"] = true,
}

hook.Add("HUDShouldDraw", "M9KR_HUD_HideDefault", function(name)
	-- Fast path: only process relevant HUD elements
	if not HUD_MANAGED[name] then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return end

	-- Check if this is an M9K weapon RIGHT NOW (no caching)
	local isM9K = weapon.Base and M9K_BASES[weapon.Base]

	-- INSTANTLY hide HUD elements for M9K weapons (if custom HUD enabled)
	if isM9K and GetConVar("m9kr_hud_mode"):GetInt() == 1 then
		if HUD_HIDDEN[name] then
			return false
		end
	end

	-- Crosshair hiding
	if name == "CHudCrosshair" and weapon.DrawCrosshair == false then
		return false
	end
end)

print("[M9K:R] HUD system loaded")
