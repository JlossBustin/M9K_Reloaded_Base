--[[
	M9K Reloaded - Client-Side Shell Ejection Handler

	Handles shell ejection for both viewmodel (first-person) and worldmodel (third-person).
	Uses auto-determined positioning with universal offsets applied to worldmodel data.
	Works immediately for all players without requiring caching or pre-configuration.

	Includes complete shell collision sound database for caliber-specific sounds.
]]--

M9KR = M9KR or {}
M9KR.ShellEjection = M9KR.ShellEjection or {}

-- Universal shell ejection offsets (applied to all weapons)
-- Adjust these values to fine-tune shell spawn position for all weapons
M9KR.ShellEjection.UniversalOffset = {
	Forward = 5,   -- Units forward from weapon position
	Right = 2,     -- Units right from weapon position
	Up = 1         -- Units up from weapon position
}

-- Shell ejection sound parameters (increased from effect defaults for better audibility)
M9KR.ShellEjection.SoundLevel = {55, 65}       -- Sound radius (increased from 45-55)
M9KR.ShellEjection.SoundPitch = {80, 120}      -- Pitch variation
M9KR.ShellEjection.SoundVolume = {1.0, 1.15}   -- Volume (increased from 0.85-0.95)

-- FAS2 collision sounds (caliber-specific) - complete database from m9kr_shell effect
local ShellSounds_Rifle = {
	"fas2/casings/casings_rifle1.wav", "fas2/casings/casings_rifle2.wav",
	"fas2/casings/casings_rifle3.wav", "fas2/casings/casings_rifle4.wav",
	"fas2/casings/casings_rifle5.wav", "fas2/casings/casings_rifle6.wav",
	"fas2/casings/casings_rifle7.wav", "fas2/casings/casings_rifle8.wav",
	"fas2/casings/casings_rifle9.wav", "fas2/casings/casings_rifle10.wav",
	"fas2/casings/casings_rifle11.wav", "fas2/casings/casings_rifle12.wav"
}

local ShellSounds_Pistol = {
	"fas2/casings/casings_pistol1.wav", "fas2/casings/casings_pistol2.wav",
	"fas2/casings/casings_pistol3.wav", "fas2/casings/casings_pistol4.wav",
	"fas2/casings/casings_pistol5.wav", "fas2/casings/casings_pistol6.wav",
	"fas2/casings/casings_pistol7.wav", "fas2/casings/casings_pistol8.wav",
	"fas2/casings/casings_pistol9.wav", "fas2/casings/casings_pistol10.wav",
	"fas2/casings/casings_pistol11.wav", "fas2/casings/casings_pistol12.wav"
}

local ShellSounds_Shotgun = {
	"fas2/casings/shells_12g1.wav", "fas2/casings/shells_12g2.wav",
	"fas2/casings/shells_12g3.wav", "fas2/casings/shells_12g4.wav",
	"fas2/casings/shells_12g5.wav", "fas2/casings/shells_12g6.wav",
	"fas2/casings/shells_12g7.wav", "fas2/casings/shells_12g8.wav",
	"fas2/casings/shells_12g9.wav", "fas2/casings/shells_12g10.wav",
	"fas2/casings/shells_12g11.wav", "fas2/casings/shells_12g12.wav"
}

local ShellSounds_Heavy = {
	"fas2/casings/casings_50bmg1.wav", "fas2/casings/casings_50bmg2.wav",
	"fas2/casings/casings_50bmg3.wav", "fas2/casings/casings_50bmg4.wav",
	"fas2/casings/casings_50bmg5.wav", "fas2/casings/casings_50bmg6.wav",
	"fas2/casings/casings_50bmg7.wav", "fas2/casings/casings_50bmg8.wav",
	"fas2/casings/casings_50bmg9.wav", "fas2/casings/casings_50bmg10.wav",
	"fas2/casings/casings_50bmg11.wav", "fas2/casings/casings_50bmg12.wav"
}

--[[
	Determine appropriate collision sounds based on shell model
	Uses same logic as m9kr_shell effect
]]--
function M9KR.ShellEjection.GetShellSoundsForModel(shellModel)
	if not shellModel then return ShellSounds_Rifle end

	local modelLower = string.lower(shellModel)

	-- PISTOL CALIBERS (9mm, .45 ACP, .357 Mag, .50 AE, 5.7x28mm)
	if string.find(modelLower, "9x18mm") or string.find(modelLower, "9x19mm") or
	   string.find(modelLower, "45acp") or string.find(modelLower, "357mag") or
	   string.find(modelLower, "50ae") or string.find(modelLower, "5_7x28mm") then
		return ShellSounds_Pistol
	end

	-- HEAVY/MAGNUM CALIBERS (.454 Casull, .408 CheyTac, .338 Lapua, .300 Win Mag, .50 BMG, 12.7x55mm, 23mm)
	if string.find(modelLower, "454casull") or string.find(modelLower, "408cheytac") or
	   string.find(modelLower, "338lapua") or string.find(modelLower, "338mag") or
	   string.find(modelLower, "300win") or string.find(modelLower, "50bmg") or
	   string.find(modelLower, "12_7x55mm") or string.find(modelLower, "23mm") then
		return ShellSounds_Heavy
	end

	-- SHOTGUN SHELLS (12 gauge variations, 13 gauge, 38 gauge)
	if string.find(modelLower, "12g_") or string.find(modelLower, "12gauge") or
	   string.find(modelLower, "13gauge") or string.find(modelLower, "38gauge") then
		return ShellSounds_Shotgun
	end

	-- RIFLE CALIBERS (5.56mm, 7.62mm variants, 5.45mm, 9x39mm, etc.)
	-- Default to rifle sounds for standard intermediate/full-power rifle calibers
	return ShellSounds_Rifle
end


--[[
	Calculate worldmodel shell ejection position using universal auto-determined offsets
	Applies a universal offset formula to all weapons without requiring caching
	@param weapon - The weapon entity (worldmodel)
	@param owner - The player holding the weapon
	@return pos, ang - World position and angle for shell spawn
]]--
function M9KR.ShellEjection.CalculateWorldmodelShellPos(weapon, owner)
	if not IsValid(weapon) or not IsValid(owner) then return nil, nil end

	-- Get worldmodel position and angle
	local wepPos = weapon:GetPos()
	local wepAng = weapon:GetAngles()

	-- Get universal offset values
	local offset = M9KR.ShellEjection.UniversalOffset

	-- Calculate shell position using universal offset formula
	-- Apply offset in weapon's local coordinate space
	local shellPos = wepPos +
		wepAng:Forward() * offset.Forward +
		wepAng:Right() * offset.Right +
		wepAng:Up() * offset.Up

	-- Shell ejects to the right (90 degrees from forward)
	local shellAng = Angle(wepAng.p, wepAng.y + 90, wepAng.r)

	return shellPos, shellAng
end


--[[
	Spawn shell ejection effect from viewmodel
	@param weapon - The weapon entity
	@param viewmodel - The viewmodel entity
	@param attachmentId - Attachment index (passed from QC event or weapon property)
]]--
function M9KR.ShellEjection.SpawnShell(weapon, viewmodel, attachmentId)
	if not IsValid(weapon) or not IsValid(viewmodel) then return end
	if not weapon.ShellModel then return end

	-- Use attachment ID from QC event parameter, or fall back to weapon property, or default to 2
	attachmentId = attachmentId or tonumber(weapon.ShellEjectAttachment) or 2

	-- Get the attachment data
	local attachment = viewmodel:GetAttachment(attachmentId)
	if not attachment then return end  -- Attachment doesn't exist

	-- Create shell ejection effect
	local effectData = EffectData()
	effectData:SetOrigin(attachment.Pos)
	effectData:SetNormal(attachment.Ang:Forward())
	effectData:SetEntity(weapon)
	effectData:SetAttachment(attachmentId)

	util.Effect("m9kr_shell", effectData)
end


--[[
	Spawn shell ejection effect from worldmodel using auto-determined position
	@param weapon - The weapon entity (worldmodel)
	@param owner - The player holding the weapon
]]--
function M9KR.ShellEjection.SpawnWorldmodelShell(weapon, owner)
	if not IsValid(weapon) or not IsValid(owner) then return end
	if not weapon.ShellModel then return end

	-- Calculate worldmodel shell position using universal offsets
	local shellPos, shellAng = M9KR.ShellEjection.CalculateWorldmodelShellPos(weapon, owner)
	if not shellPos then return end

	-- Create shell ejection effect at calculated worldmodel position
	local effectData = EffectData()
	effectData:SetOrigin(shellPos)
	effectData:SetNormal(shellAng:Forward())
	effectData:SetEntity(weapon)

	util.Effect("m9kr_shell", effectData)
end

--[[
	Detect other players firing and spawn worldmodel shells client-side
	EntityFireBullets runs on both client and server — no networking needed
]]--
hook.Add("EntityFireBullets", "M9KR_ShellEjection_Worldmodel", function(entity, data)
	if not IsValid(entity) or not entity:IsPlayer() then return end

	-- Local player shells are handled by viewmodel EjectShell
	if entity == LocalPlayer() then return end

	local weapon = entity:GetActiveWeapon()
	if not IsValid(weapon) or not weapon.ShellModel then return end

	M9KR.ShellEjection.SpawnWorldmodelShell(weapon, entity)
end)

print("[M9K:R] Client-side shell ejection handler loaded (viewmodel + worldmodel with auto-determined positioning)")
