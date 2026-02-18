--[[
	M9K Reloaded - Muzzle Flash Dynamic Lighting System

	Controls dynamic lighting from muzzle flashes (TFA Realistic 2.0 compatibility)
	- ConVar: cl_tfa_rms_muzzleflash_dynlight (0 = Disabled, 1 = Enabled)
	- Creates temporary light sources at muzzle position when firing
	- Used by TFA Realistic Muzzleflashes 2.0 PCF muzzleflash effects
]]--

-- Create TFA Realistic 2.0 ConVar (if it doesn't exist)
if not ConVarExists("cl_tfa_rms_muzzleflash_dynlight") then
	CreateClientConVar("cl_tfa_rms_muzzleflash_dynlight", "1", true, false,
		"Enable dynamic lighting from muzzle flashes")
end

-- Print status on load
timer.Simple(0.15, function()
	local dynlight = GetConVar("cl_tfa_rms_muzzleflash_dynlight")
	if dynlight and dynlight:GetBool() then
		print("[M9K:R] Muzzle flash dynamic lighting: ENABLED")
	else
		print("[M9K:R] Muzzle flash dynamic lighting: DISABLED")
	end
end)

print("[M9K:R] Muzzle flash dynamic lighting system loaded (cl_tfa_rms_muzzleflash_dynlight)")
