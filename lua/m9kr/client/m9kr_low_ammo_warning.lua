--[[
	M9K Reloaded - Client-Side Low Ammo Warning System

	Handles low ammo warning sounds for M9KR weapons.
	Centralized system that watches ammo counts and plays appropriate sounds.

	ConVar:
	- m9kr_low_ammo_threshold: Percentage of magazine at which to trigger warning (default 33%)
]]--

M9KR = M9KR or {}
M9KR.LowAmmo = M9KR.LowAmmo or {}

-- ConVar for low ammo threshold (no enable/disable - purely auditory feedback)
CreateClientConVar("m9kr_low_ammo_threshold", "33", true, false, "Low ammo warning threshold (percentage of magazine)", 0, 100)

-- Track low ammo state per weapon to avoid spam
M9KR.LowAmmo.WeaponStates = M9KR.LowAmmo.WeaponStates or {}

-- Ammo type to low ammo sound mapping (caliber-specific sounds)
local LowAmmoSoundByAmmoType = {
	["pistol"] = "m9k_indicators/lowammo_indicator_handgun.wav",
	["357"] = "m9k_indicators/lowammo_indicator_revolver.wav",
	["smg1"] = "m9k_indicators/lowammo_indicator_smg.wav",
	["ar2"] = "m9k_indicators/lowammo_indicator_ar.wav",
	["buckshot"] = "m9k_indicators/lowammo_indicator_shotgun.wav",
	["slam"] = "m9k_indicators/lowammo_indicator_shotgun.wav",
	["SniperPenetratedRound"] = "m9k_indicators/lowammo_indicator_sr.wav",
	["AirboatGun"] = "m9k_indicators/lowammo_indicator_shotgun_auto.wav",
}

local LastAmmoSoundByAmmoType = {
	["pistol"] = "m9k_indicators/lowammo_dry_handgun.wav",
	["357"] = "m9k_indicators/lowammo_dry_revolver.wav",
	["smg1"] = "m9k_indicators/lowammo_dry_smg.wav",
	["ar2"] = "m9k_indicators/lowammo_dry_ar.wav",
	["buckshot"] = "m9k_indicators/lowammo_dry_shotgun.wav",
	["slam"] = "m9k_indicators/lowammo_dry_shotgun.wav",
	["SniperPenetratedRound"] = "m9k_indicators/lowammo_dry_sr.wav",
	["AirboatGun"] = "m9k_indicators/lowammo_dry_shotgun_auto.wav",
}

--[[
	Get or create weapon low ammo state tracker
]]--
function M9KR.LowAmmo.GetWeaponState(weapon)
	if not IsValid(weapon) then return nil end

	local entIndex = weapon:EntIndex()
	if not M9KR.LowAmmo.WeaponStates[entIndex] then
		M9KR.LowAmmo.WeaponStates[entIndex] = {
			wasLowAmmo = false,
			lastWarnTime = 0,
			lastClip = 0,
			shotsSinceLastWarning = 0,  -- Counter for SoundIndicatorInterval throttling
		}
	end

	return M9KR.LowAmmo.WeaponStates[entIndex]
end

--[[
	Clean up old weapon states
]]--
hook.Add("Think", "M9KR.LowAmmo.CleanupStates", function()
	for entIndex, state in pairs(M9KR.LowAmmo.WeaponStates) do
		local ent = Entity(entIndex)
		if not IsValid(ent) then
			M9KR.LowAmmo.WeaponStates[entIndex] = nil
		end
	end
end)

--[[
	Check weapon ammo and trigger warning if needed
]]--
function M9KR.LowAmmo.CheckWeapon(weapon)
	if not IsValid(weapon) then return end

	-- Only check M9KR weapons (verify they use M9K base classes)
	if not weapon.Base then return end
	local isM9KRWeapon = weapon.Base == "carby_gun_base" or
	                     weapon.Base == "carby_shotty_base" or
	                     weapon.Base == "carby_scoped_base"
	if not isM9KRWeapon then return end

	-- Verify weapon has proper primary structure
	if not weapon.Primary or not weapon.Primary.ClipSize then return end

	-- Skip weapons that have disabled low ammo warnings (bows, crossbows, etc.)
	if weapon.NoLowAmmoWarning then return end

	local state = M9KR.LowAmmo.GetWeaponState(weapon)
	if not state then return end

	local clip = weapon:Clip1()
	local maxClip = weapon.Primary.ClipSize

	-- Don't warn for weapons with no magazine (like shotguns that feed directly)
	if maxClip <= 1 then return end

	-- Calculate ammo percentage
	local threshold = GetConVar("m9kr_low_ammo_threshold"):GetInt() / 100
	local isLowAmmo = clip <= (maxClip * threshold) and clip > 0

	-- Play low ammo sound when in low ammo state
	-- For high-RPM weapons with SoundIndicatorInterval, throttle the warning sound
	-- Otherwise play on EVERY shot (TFA-style behavior)
	if isLowAmmo and clip < state.lastClip then
		local shouldPlayWarning = true

		-- Check if weapon uses SoundIndicatorInterval (high-RPM weapons like minigun)
		if weapon.SoundIndicatorInterval then
			state.shotsSinceLastWarning = (state.shotsSinceLastWarning or 0) + 1
			shouldPlayWarning = (state.shotsSinceLastWarning >= weapon.SoundIndicatorInterval)
			if shouldPlayWarning then
				state.shotsSinceLastWarning = 0
			end
		end

		if shouldPlayWarning then
			-- Play caliber-specific low ammo sound
			local ammoType = weapon:GetPrimaryAmmoType()
			local ammoTypeName = game.GetAmmoName(ammoType) or "ar2"
			local snd = LowAmmoSoundByAmmoType[ammoTypeName] or "m9k_indicators/lowammo_indicator_ar.wav"

			-- Semi-auto snipers (DMRs) get a distinct sound from bolt-action
			if ammoTypeName == "SniperPenetratedRound" and not weapon.BoltAction then
				snd = "m9k_indicators/lowammo_indicator_dmr.wav"
			end

			-- Play immediately (no delay) so it syncs with the shot sound
			-- Use CHAN_AUTO to automatically find an available channel
			if IsValid(weapon) and IsValid(LocalPlayer()) then
				weapon:EmitSound(snd, 60, 100, 0.5, CHAN_AUTO)
			end
			state.lastWarnTime = CurTime()
		end
	end

	-- Detect last round fired (clip just hit 0)
	-- Note: This always plays regardless of SoundIndicatorInterval since it's a one-time event
	if clip == 0 and state.lastClip == 1 then
		-- Play caliber-specific last round sound
		local ammoType = weapon:GetPrimaryAmmoType()
		local ammoTypeName = game.GetAmmoName(ammoType) or "ar2"
		local snd = LastAmmoSoundByAmmoType[ammoTypeName] or "m9k_indicators/lowammo_dry_ar.wav"

		-- Semi-auto snipers (DMRs) get a distinct sound from bolt-action
		if ammoTypeName == "SniperPenetratedRound" and not weapon.BoltAction then
			snd = "m9k_indicators/lowammo_dry_dmr.wav"
		end

		-- Play immediately (no delay) so it syncs with the shot sound
		-- Use CHAN_AUTO to automatically find an available channel
		if IsValid(weapon) and IsValid(LocalPlayer()) then
			weapon:EmitSound(snd, 60, 100, 0.5, CHAN_AUTO)
		end

		-- Reset warning counter when mag empties
		state.shotsSinceLastWarning = 0
	end

	-- Reset counter when transitioning into low ammo state (so first warning plays immediately)
	if isLowAmmo and not state.wasLowAmmo then
		state.shotsSinceLastWarning = weapon.SoundIndicatorInterval or 0
	end

	-- Update state
	state.wasLowAmmo = isLowAmmo
	state.lastClip = clip
end

--[[
	Think hook - Check active weapon ammo
]]--
hook.Add("Think", "M9KR.LowAmmo.CheckActiveWeapon", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	local weapon = ply:GetActiveWeapon()
	if IsValid(weapon) then
		M9KR.LowAmmo.CheckWeapon(weapon)
	end
end)

-- Precache all low ammo sounds
for ammoType, soundPath in pairs(LowAmmoSoundByAmmoType) do
	util.PrecacheSound(soundPath)
end
for ammoType, soundPath in pairs(LastAmmoSoundByAmmoType) do
	util.PrecacheSound(soundPath)
end

print("[M9K:R] Low ammo warning system loaded")
