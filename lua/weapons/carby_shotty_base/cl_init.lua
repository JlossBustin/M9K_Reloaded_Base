-- M9K Reloaded Shotty Base - Client Init

include("shared.lua")

-- ============================================================================
-- HUD Functions
-- ============================================================================

-- Hide default GMod HUD elements when using M9K:R HUD
-- This prevents the default ammo/health HUD from showing
local M9KR_HudHide = {
	CHudAmmo = true,
	CHudSecondaryAmmo = true,
	CHudHealth = true
}

function SWEP:HUDShouldDraw(name)
	-- Only hide if M9K:R HUD is enabled
	if M9KR_HudHide[name] and GetConVar("m9kr_hud_mode"):GetInt() == 1 then
		return false
	end
end
