--[[
	M9K Reloaded - Scotch Muzzle Flash Sprite System

	Controls white flash sprites from muzzle flashes (TFA Realistic 2.0 compatibility)
	- ConVar: cl_tfa_rms_default_scotchmuzzleflash (0 = Disabled, 1 = Enabled)
	- Adds bright white flash sprites for enhanced visual feedback
	- Used by TFA Realistic Muzzleflashes 2.0 PCF muzzleflash effects
]]--

-- Create TFA Realistic 2.0 ConVar (if it doesn't exist)
if not ConVarExists("cl_tfa_rms_default_scotchmuzzleflash") then
	CreateClientConVar("cl_tfa_rms_default_scotchmuzzleflash", "1", true, false,
		"Enable white flash sprites")
end

-- Print status on load
timer.Simple(0.15, function()
	local scotch = GetConVar("cl_tfa_rms_default_scotchmuzzleflash")
	if scotch and scotch:GetBool() then
		print("[M9K:R] Scotch muzzle flash sprites: ENABLED")
	else
		print("[M9K:R] Scotch muzzle flash sprites: DISABLED")
	end
end)

print("[M9K:R] Scotch muzzle flash sprite system loaded (cl_tfa_rms_default_scotchmuzzleflash)")
