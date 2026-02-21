--[[
	M9K Reloaded - In-Game Settings Panel

	Accessible via Q menu -> M9K:R Settings tab
	Server Settings tab: superadmin only
	Client Settings tab: all players
]]--

hook.Add("AddToolMenuTabs", "M9KR_SettingsTab", function()
	spawnmenu.AddToolTab("M9KR", "M9K:R Settings", "icon16/gun.png")
end)

-- Default values for reset buttons
local SERVER_DEFAULTS = {
	m9kr_weapon_strip = "0",
	m9kr_safety_enabled = "1",
	m9kr_damage_multiplier = "1",
	m9kr_default_clip = "-1",
	m9kr_unique_slots = "1",
	m9kr_low_ammo_threshold = "33",
	m9kr_ads_time = "0.55",
	m9kr_penetration_mode = "1",
	m9kr_ricochet_chance = "15",
	m9kr_tracer_mode = "1",
	m9kr_bullet_impact = "1",
	m9kr_metal_impact = "1",
	m9kr_dust_impact = "1",
	m9kr_hud_mode = "7",
}

local CLIENT_DEFAULTS = {
	m9kr_hud_weapon = "1",
	m9kr_hud_health = "1",
	m9kr_hud_squad = "1",
	m9kr_muzzleflash = "1",
	m9kr_muzzle_heatwave = "1",
	m9kr_muzzlesmoke = "1",
	cl_tfa_rms_default_scotchmuzzleflash = "1",
	cl_tfa_rms_muzzleflash_dynlight = "1",
	cl_tfa_rms_optimized_smoke = "1",
}

-- Short category names for blacklist display
local CAT_SHORT = {
	["M9K Reloaded : Handguns"] = "Handgun",
	["M9K Reloaded : Submachine Guns"] = "SMG",
	["M9K Reloaded : Rifles"] = "Rifle",
	["M9K Reloaded : Machine Guns"] = "MG",
	["M9K Reloaded : Shotguns"] = "Shotgun",
	["M9K Reloaded : Sniper Rifles"] = "Sniper",
}

-- Helper: adds a slider with inline label and a named reset button
local function AddSliderWithDefault(panel, label, name, cvar, min, max, decimals, default)
	panel:NumSlider(label, cvar, min, max, decimals)
	local btn = panel:Button("Reset " .. name .. " to Default (" .. default .. ")")
	btn.DoClick = function() RunConsoleCommand(cvar, default) end
end

hook.Add("PopulateToolMenu", "M9KR_SettingsPanel", function()

	-- ================================================================
	-- Server Settings (superadmin only)
	-- ================================================================
	spawnmenu.AddToolMenuOption("M9KR", "Settings", "m9kr_server_settings",
		"Server Settings", "", "", function(panel)
		panel:ClearControls()

		if not LocalPlayer():IsSuperAdmin() then
			panel:Help("Only superadmins can change server settings.")
			return
		end

		panel:Help("M9K:R Server Settings")
		panel:Help("Changes apply to all players on the server.")
		local resetBtn = panel:Button("Reset All Server Settings to Defaults")
		resetBtn.DoClick = function()
			for cvar, val in pairs(SERVER_DEFAULTS) do
				RunConsoleCommand(cvar, val)
			end
		end

		panel:Help("")
		panel:CheckBox("Strip empty weapons", "m9kr_weapon_strip")
		panel:CheckBox("Unique weapon slots", "m9kr_unique_slots")
		panel:CheckBox("Safety mode toggle (SHIFT+E+R)", "m9kr_safety_enabled")
		panel:CheckBox("Custom bullet impacts", "m9kr_bullet_impact")
		panel:CheckBox("Custom metal impacts", "m9kr_metal_impact")
		panel:CheckBox("Custom dust impacts", "m9kr_dust_impact")
		AddSliderWithDefault(panel, "Damage Multiplier", "Damage Multiplier", "m9kr_damage_multiplier", 0.1, 10, 2, "1")

		panel:Help("")
		panel:NumSlider("Clip Multiplier*", "m9kr_default_clip", -1, 100, 0)
		panel:Help("* Clip Multiplier changes require map change to take effect")
		local clipBtn = panel:Button("Reset Clip Multiplier to Default (-1)")
		clipBtn.DoClick = function() RunConsoleCommand("m9kr_default_clip", "-1") end

		panel:Help("")
		panel:NumSlider("Low Ammo Sounds", "m9kr_low_ammo_threshold", 0, 100, 0)
		panel:Help("Plays warning sounds when magazine drops below this %. 0 = off.")
		local lowAmmoBtn = panel:Button("Reset Low Ammo Sounds to Default (33)")
		lowAmmoBtn.DoClick = function() RunConsoleCommand("m9kr_low_ammo_threshold", "33") end

		panel:Help("")
		AddSliderWithDefault(panel, "ADS Time (seconds)", "ADS Time", "m9kr_ads_time", 0.1, 2, 2, "0.55")

		panel:Help("")
		panel:Help("Penetration (0=Off, 1=Dynamic, 2=Vanilla)")
		panel:NumSlider("", "m9kr_penetration_mode", 0, 2, 0)
		panel:Help("Tracers (0=Off, 1=Dynamic, 2=Vanilla)")
		panel:NumSlider("", "m9kr_tracer_mode", 0, 2, 0)
		AddSliderWithDefault(panel, "Ricochet Chance (%)", "Ricochet Chance", "m9kr_ricochet_chance", 0, 100, 0, "15")

		panel:Help("")
		panel:NumSlider("HUD Mode", "m9kr_hud_mode", 0, 7, 0)
		panel:Help("Controls which M9K:R HUD elements are enabled server-wide:")
		panel:Help("  0 = All disabled (HL2 default HUD)")
		panel:Help("  1 = Weapon HUD only")
		panel:Help("  2 = Health/Armor HUD only")
		panel:Help("  3 = Weapon + Health/Armor")
		panel:Help("  4 = Squad HUD only")
		panel:Help("  5 = Weapon + Squad")
		panel:Help("  6 = Health/Armor + Squad")
		panel:Help("  7 = All enabled (Full M9K:R HUD)")
	end)

	-- ================================================================
	-- Client Settings (all players)
	-- ================================================================
	spawnmenu.AddToolMenuOption("M9KR", "Settings", "m9kr_client_settings",
		"Client Settings", "", "", function(panel)
		panel:ClearControls()

		panel:Help("M9K:R Client Settings")
		panel:Help("These settings only affect your client.")
		local resetBtn = panel:Button("Reset All Client Settings to Defaults")
		resetBtn.DoClick = function()
			for cvar, val in pairs(CLIENT_DEFAULTS) do
				RunConsoleCommand(cvar, val)
			end
		end

		panel:Help("")
		panel:Help("--- HUD Elements ---")
		panel:Help("Server must enable each via HUD mode.")
		panel:CheckBox("Show weapon HUD (ammo, fire mode)", "m9kr_hud_weapon")
		panel:CheckBox("Show health/armor HUD", "m9kr_hud_health")
		panel:CheckBox("Show squad HUD", "m9kr_hud_squad")

		panel:Help("")
		panel:Help("--- Visual Effects ---")
		panel:CheckBox("Muzzle flash effects", "m9kr_muzzleflash")
		panel:CheckBox("Full muzzle particles (heavier)", "m9kr_muzzlesmoke")
		panel:Help("Heatwave (0=Off, 1=Full, 2=Reduced)")
		panel:NumSlider("", "m9kr_muzzle_heatwave", 0, 2, 0)

		panel:Help("")
		panel:Help("--- Muzzle Flash Details ---")
		panel:CheckBox("White flash sprites", "cl_tfa_rms_default_scotchmuzzleflash")
		panel:CheckBox("Muzzle dynamic lights", "cl_tfa_rms_muzzleflash_dynlight")
		panel:CheckBox("Optimized smoke particles", "cl_tfa_rms_optimized_smoke")
	end)

	-- ================================================================
	-- Weapon Blacklist (superadmin only)
	-- ================================================================
	spawnmenu.AddToolMenuOption("M9KR", "Settings", "m9kr_blacklist",
		"Weapon Blacklist", "", "", function(panel)
		panel:ClearControls()

		if not LocalPlayer():IsSuperAdmin() then
			panel:Help("Only superadmins can manage the weapon blacklist.")
			return
		end

		panel:Help("M9K:R Weapon Blacklist")
		panel:Help("* Changes require map change to take effect")

		-- Gather weapons by category and track blacklist state locally
		local weaponsByCategory = {}
		local allWeapons = {}
		local blacklistedSet = {}
		for _, wep in pairs(weapons.GetList()) do
			local class = wep.ClassName
			if class and string.StartsWith(class, "m9kr_") and class ~= "m9kr_blacklisted" then
				local cat = wep.Category or "Uncategorized"
				weaponsByCategory[cat] = weaponsByCategory[cat] or {}
				local name = wep.PrintName or class
				table.insert(weaponsByCategory[cat], { class = class, name = name })
				allWeapons[class] = { name = name, cat = cat }
				local cv = GetConVar(class .. "_allowed")
				if cv and not cv:GetBool() then
					blacklistedSet[class] = true
				end
			end
		end
		for _, weps in pairs(weaponsByCategory) do
			table.sort(weps, function(a, b) return a.name < b.name end)
		end

		-- Clear all button (DoClick assigned after functions are defined)
		local clearBtn = panel:Button("Clear Entire Blacklist")

		-- Category dropdown
		panel:Help("")
		local catBox = vgui.Create("DComboBox")
		catBox:SetValue("Select Category")
		panel:AddItem(catBox)

		-- Weapon dropdown
		local wepBox = vgui.Create("DComboBox")
		wepBox:SetValue("Select Weapon")
		panel:AddItem(wepBox)

		-- Populate categories
		catBox:AddChoice("All")
		local sortedCats = table.GetKeys(weaponsByCategory)
		table.sort(sortedCats)
		for _, cat in ipairs(sortedCats) do
			catBox:AddChoice(cat)
		end

		-- Track selected category for refresh
		local selectedCat = nil

		local function RefreshWeaponDropdown()
			wepBox:Clear()
			wepBox:SetValue("Select Weapon")
			if not selectedCat then return end

			local wepsToShow = {}
			if selectedCat == "All" then
				for _, catWeps in pairs(weaponsByCategory) do
					for _, wep in ipairs(catWeps) do
						if not blacklistedSet[wep.class] then
							table.insert(wepsToShow, wep)
						end
					end
				end
				table.sort(wepsToShow, function(a, b) return a.name < b.name end)
			else
				if not weaponsByCategory[selectedCat] then return end
				for _, wep in ipairs(weaponsByCategory[selectedCat]) do
					if not blacklistedSet[wep.class] then
						table.insert(wepsToShow, wep)
					end
				end
			end

			for _, wep in ipairs(wepsToShow) do
				wepBox:AddChoice(wep.name .. " (" .. wep.class .. ")", wep.class)
			end
		end

		catBox.OnSelect = function(self, index, value)
			selectedCat = value
			RefreshWeaponDropdown()
		end

		-- Blacklist button
		local addBtn = panel:Button("Blacklist Selected Weapon")
		local printBtn = panel:Button("Print Blacklist to Console")

		-- Blacklisted weapons list
		panel:Help("")
		panel:Help("-------------------------------------------------")
		local blHeader = panel:Help("Currently Blacklisted Weapons:")
		blHeader:SetFont("DermaDefaultBold")
		panel:Help("-------------------------------------------------")

		local listScroll = vgui.Create("DScrollPanel")
		listScroll:SetTall(300)
		panel:AddItem(listScroll)
		local listContainer = vgui.Create("DListLayout", listScroll)
		listContainer:Dock(TOP)

		local function RebuildBlacklist()
			listContainer:Clear()

			local blacklisted = {}
			for class, info in pairs(allWeapons) do
				if blacklistedSet[class] then
					table.insert(blacklisted, { class = class, name = info.name, cat = info.cat })
				end
			end
			table.sort(blacklisted, function(a, b) return a.name < b.name end)

			if #blacklisted == 0 then
				local noItems = listContainer:Add("DLabel")
				noItems:SetText("  No weapons blacklisted")
				noItems:SetTall(25)
			else
				for _, wep in ipairs(blacklisted) do
					local row = listContainer:Add("DPanel")
					row:SetTall(25)
					row:DockMargin(0, 0, 0, 2)
					row.Paint = function() end

					local removeBtn = vgui.Create("DButton", row)
					removeBtn:SetText("Remove")
					removeBtn:Dock(RIGHT)
					removeBtn:SetWide(70)
					removeBtn.DoClick = function()
						blacklistedSet[wep.class] = nil
						RunConsoleCommand(wep.class .. "_allowed", "1")
						RebuildBlacklist()
						RefreshWeaponDropdown()
					end

					local label = vgui.Create("DLabel", row)
					local shortCat = CAT_SHORT[wep.cat] or wep.cat
					label:SetText("  " .. wep.name .. " (" .. shortCat .. ")")
					label:SetFont("DermaDefaultBold")
					label:SetTextColor(Color(0, 0, 0))
					label:Dock(FILL)
				end
			end
		end

		addBtn.DoClick = function()
			local _, data = wepBox:GetSelected()
			if data then
				blacklistedSet[data] = true
				RunConsoleCommand(data .. "_allowed", "0")
				RebuildBlacklist()
				RefreshWeaponDropdown()
			end
		end

		clearBtn.DoClick = function()
			for class, _ in pairs(allWeapons) do
				if blacklistedSet[class] then
					blacklistedSet[class] = nil
					RunConsoleCommand(class .. "_allowed", "1")
				end
			end
			RebuildBlacklist()
			RefreshWeaponDropdown()
		end

		printBtn.DoClick = function()
			local blacklisted = {}
			for class, info in pairs(allWeapons) do
				if blacklistedSet[class] then
					table.insert(blacklisted, { class = class, name = info.name, cat = info.cat })
				end
			end
			table.sort(blacklisted, function(a, b) return a.name < b.name end)
			print("[M9K:R] Currently Blacklisted Weapons:")
			if #blacklisted == 0 then
				print("  No weapons blacklisted")
			else
				for _, wep in ipairs(blacklisted) do
					print("  " .. wep.name .. " (" .. wep.class .. ") - " .. wep.cat)
				end
			end
			print("[M9K:R] Total: " .. #blacklisted .. " weapons blacklisted")
		end

		RebuildBlacklist()
	end)
end)
