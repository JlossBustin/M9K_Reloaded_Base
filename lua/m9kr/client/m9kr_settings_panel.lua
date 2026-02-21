--[[
	M9K Reloaded - In-Game Settings Panel

	Accessible via Q menu -> Utilities -> M9K:R
	Server Settings tab: superadmin only
	Client Settings tab: all players
]]--

hook.Add("PopulateToolMenu", "M9KR_SettingsPanel", function()

	-- ================================================================
	-- Server Settings (superadmin only)
	-- ================================================================
	spawnmenu.AddToolMenuOption("Utilities", "M9K:R", "m9kr_server_settings",
		"Server Settings", "", "", function(panel)
		panel:ClearControls()

		if not LocalPlayer():IsSuperAdmin() then
			panel:Help("Only superadmins can change server settings.")
			return
		end

		panel:Help("M9K:R Server Settings")
		panel:Help("Changes apply to all players on the server.")
		panel:Help("")

		-- Gameplay
		panel:Help("--- Gameplay ---")
		panel:CheckBox("Strip empty weapons", "m9kr_weapon_strip")
		panel:NumSlider("Damage multiplier", "m9kr_damage_multiplier", 0.1, 10, 2)
		panel:NumSlider("Default clip multiplier", "m9kr_default_clip", -1, 100, 0)
		panel:CheckBox("Unique weapon slots", "m9kr_unique_slots")
		panel:CheckBox("Dynamic recoil", "m9kr_dynamic_recoil")
		panel:CheckBox("Ammo crate detonation", "m9kr_ammo_detonation")
		panel:CheckBox("Debug mode", "m9kr_debug")

		panel:Help("")

		-- Ballistics
		panel:Help("--- Ballistics ---")
		panel:NumSlider("Penetration mode (0=Off, 1=Dynamic, 2=Vanilla)", "m9kr_penetration_mode", 0, 2, 0)
		panel:CheckBox("Disable penetration (legacy)", "m9kr_disable_penetration")
		panel:NumSlider("Ricochet chance (%)", "m9kr_ricochet_chance", 0, 100, 0)
		panel:NumSlider("Tracer mode (0=Off, 1=Dynamic, 2=Vanilla)", "m9kr_tracer_mode", 0, 2, 0)

		panel:Help("")

		-- Visual Effects
		panel:Help("--- Visual Effects ---")
		panel:CheckBox("Custom bullet impacts", "m9kr_bullet_impact")
		panel:CheckBox("Custom metal impacts", "m9kr_metal_impact")
		panel:CheckBox("Custom dust impacts", "m9kr_dust_impact")
		panel:NumSlider("Muzzle heatwave (0=Off, 1=Full, 2=Reduced)", "m9kr_muzzle_heatwave", 0, 2, 0)
		panel:CheckBox("Muzzle smoke effects", "m9kr_muzzlesmoke")

		panel:Help("")

		-- HUD
		panel:Help("--- HUD ---")
		panel:NumSlider("HUD mode (+1=Weapon, +2=Health, +4=Squad)", "m9kr_hud_mode", 0, 7, 0)
	end)

	-- ================================================================
	-- Client Settings (all players)
	-- ================================================================
	spawnmenu.AddToolMenuOption("Utilities", "M9K:R", "m9kr_client_settings",
		"Client Settings", "", "", function(panel)
		panel:ClearControls()

		panel:Help("M9K:R Client Settings")
		panel:Help("These settings only affect your client.")
		panel:Help("")

		-- HUD Preferences
		panel:Help("--- HUD Elements ---")
		panel:CheckBox("Show weapon HUD (ammo, fire mode)", "m9kr_hud_weapon")
		panel:CheckBox("Show health/armor HUD", "m9kr_hud_health")
		panel:CheckBox("Show squad HUD", "m9kr_hud_squad")
		panel:NumSlider("Low ammo warning threshold (%)", "m9kr_low_ammo_threshold", 0, 100, 0)

		panel:Help("")

		-- Visual Preferences
		panel:Help("--- Visual Effects ---")
		panel:CheckBox("Muzzle flash effects", "m9kr_muzzleflash")
		panel:CheckBox("Gas ejection effects", "m9kr_gas_effect")

		panel:Help("")

		-- TFA Muzzle Flash Compatibility
		panel:Help("--- Muzzle Flash Details ---")
		panel:CheckBox("White flash sprites", "cl_tfa_rms_default_scotchmuzzleflash")
		panel:CheckBox("Muzzle dynamic lights", "cl_tfa_rms_muzzleflash_dynlight")
		panel:CheckBox("Optimized smoke particles", "cl_tfa_rms_optimized_smoke")
	end)
end)
