--[[
	M9K Reloaded - Autoloader

	This is the ONLY file in lua/autorun/. All M9KR systems live in lua/m9kr/
	and are loaded here in the correct order with proper realm control.

	This prevents double-execution from GMod's engine autorun and avoids
	filename conflicts with other addons in the virtual filesystem.
]]--

AddCSLuaFile()

print("[M9K:R] Loading M9K Reloaded systems...")

-- ============================================================================
-- Particle Precaching
-- ============================================================================

if CLIENT then
	game.AddParticles("particles/realistic_muzzleflashes_2.pcf")
	game.AddParticles("particles/tfa_ballistics.pcf")
end

if SERVER then
	game.AddParticles("particles/realistic_muzzleflashes_2.pcf")
	game.AddParticles("particles/tfa_ballistics.pcf")
end

PrecacheParticleSystem("muzzleflash_pistol")
PrecacheParticleSystem("muzzleflash_pistol_optimized")
PrecacheParticleSystem("muzzleflash_pistol_rbull")
PrecacheParticleSystem("muzzleflash_pistol_rbull_optimized")
PrecacheParticleSystem("muzzleflash_smg_bizon")
PrecacheParticleSystem("muzzleflash_smg_optimized")
PrecacheParticleSystem("muzzleflash_6")
PrecacheParticleSystem("muzzleflash_6_optimized")
PrecacheParticleSystem("muzzleflash_shotgun")
PrecacheParticleSystem("muzzleflash_shotgun_optimized")
PrecacheParticleSystem("muzzleflash_slug")
PrecacheParticleSystem("muzzleflash_sr25")
PrecacheParticleSystem("muzzleflash_sr25_optimized")
PrecacheParticleSystem("muzzleflash_minimi")
PrecacheParticleSystem("muzzleflash_vollmer_optimized")
PrecacheParticleSystem("muzzleflash_suppressed")
PrecacheParticleSystem("muzzleflash_suppressed_optimized")

-- ============================================================================
-- Server ConVars (replicated to clients, only server can change)
-- ============================================================================

if SERVER then
	CreateConVar("m9kr_bullet_impact", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
		"Bullet impact effects: 0 = GMod Default, 1 = M9K Custom", 0, 1)
	CreateConVar("m9kr_metal_impact", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
		"Metal impact effects: 0 = GMod Default, 1 = M9K Custom", 0, 1)
	CreateConVar("m9kr_dust_impact", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
		"Dust impact effects: 0 = GMod Default, 1 = M9K Custom", 0, 1)
	CreateConVar("m9kr_hud_mode", "7", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
		"M9K HUD elements (bitfield): +1 = Weapon, +2 = Health/Armor, +4 = Squad. 0 = HL2 default, 7 = Full M9KR HUD", 0, 7)

	-- Gameplay ConVars (centralized from legacy weapon pack autoruns)
	CreateConVar("m9kr_weapon_strip", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED},
		"Strip weapons when empty (no ammo, no reserve)", 0, 1)
	CreateConVar("m9kr_safety_enabled", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED},
		"Enable weapon safety toggle (SHIFT+E+R)", 0, 1)
	CreateConVar("m9kr_damage_multiplier", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED},
		"Global damage multiplier for M9KR weapons")
	CreateConVar("m9kr_default_clip", "-1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED},
		"Clip multiplier for weapon spawns (-1 = use weapon default)", -1, 100)
	CreateConVar("m9kr_unique_slots", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED},
		"Give M9KR weapons unique weapon selection slots", 0, 1)
	CreateConVar("m9kr_low_ammo_threshold", "33", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED},
		"Low ammo warning threshold as percentage of magazine (0 = disabled)", 0, 100)
	CreateConVar("m9kr_ads_time", "0.55", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED},
		"ADS transition time in seconds (lower = faster)", 0.1, 2)
	CreateConVar("m9kr_ammo_detonation", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED},
		"Ammo crates can explode when shot", 0, 1)
end

-- ============================================================================
-- Visual effect ConVars (SP = server-replicated, MP = per-client)
-- ============================================================================

if game.SinglePlayer() then
	if SERVER then
		CreateConVar("m9kr_muzzleflash", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
			"Enable M9KR custom muzzle flash effects", 0, 1)
		CreateConVar("m9kr_muzzle_heatwave", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
			"Muzzle heatwave: 0 = Off, 1 = Full, 2 = Reduced (50%)", 0, 2)
		CreateConVar("m9kr_muzzlesmoke", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
			"Muzzle particle quality: 0 = Optimized (lighter), 1 = Full (all effects)", 0, 1)
	end
else
	if CLIENT then
		CreateClientConVar("m9kr_muzzleflash", "1", true, true,
			"Enable M9KR custom muzzle flash effects", 0, 1)
		CreateClientConVar("m9kr_muzzle_heatwave", "1", true, true,
			"Muzzle heatwave: 0 = Off, 1 = Full, 2 = Reduced (50%)", 0, 2)
		CreateClientConVar("m9kr_muzzlesmoke", "1", true, true,
			"Muzzle particle quality: 0 = Optimized (lighter), 1 = Full (all effects)", 0, 1)
	end
end

-- ============================================================================
-- Client ConVars (per-player preference, limited by server m9kr_hud_mode)
-- ============================================================================

if CLIENT then
	CreateConVar("m9kr_hud_weapon", "1", FCVAR_ARCHIVE,
		"Show M9K custom weapon HUD (ammo, fire mode). Limited by server m9kr_hud_mode", 0, 1)
	CreateConVar("m9kr_hud_health", "1", FCVAR_ARCHIVE,
		"Show M9K custom health/armor HUD. Limited by server m9kr_hud_mode", 0, 1)
	CreateConVar("m9kr_hud_squad", "1", FCVAR_ARCHIVE,
		"Show M9K custom squad HUD. Limited by server m9kr_hud_mode", 0, 1)
end

-- ============================================================================
-- Shared globals
-- ============================================================================

M9KR = M9KR or {}

-- Weapon base lookup (hard-set: constant definition, lua refresh must pick up source changes)
M9KR.WeaponBases = {
	["carby_gun_base"] = true,
	["carby_shotty_base"] = true,
	["carby_scoped_base"] = true,
}

-- Check if a weapon is blacklisted via per-weapon _allowed ConVar.
-- Called at the TOP of every weapon shared.lua before definitions.
function M9KR.IsBlacklisted(swep)
	if SERVER then
		CreateConVar(swep.Gun .. "_allowed", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
			"Allow " .. swep.Gun .. " to be used", 0, 1)
	end
	local allowCvar = GetConVar(swep.Gun .. "_allowed")
	if allowCvar and not allowCvar:GetBool() then
		swep.Base = "m9kr_blacklisted"
		swep.PrintName = swep.Gun
		return true
	end
	return false
end

-- Apply shared weapon configuration from server ConVars.
-- Called at the BOTTOM of every weapon shared.lua after all definitions.
function M9KR.ApplyWeaponConfig(swep)
	local clipCvar = GetConVar("m9kr_default_clip")
	if clipCvar and clipCvar:GetInt() ~= -1 then
		swep.Primary.DefaultClip = swep.Primary.ClipSize * clipCvar:GetInt()
	end

	local slotsCvar = GetConVar("m9kr_unique_slots")
	if slotsCvar and not slotsCvar:GetBool() then
		swep.SlotPos = 2
	end
end

-- ============================================================================
-- Send client & shared files to clients (SERVER only)
-- ============================================================================

if SERVER then
	-- Shared files (clients need these too)
	AddCSLuaFile("m9kr/shared/m9kr_ballistics.lua")
	AddCSLuaFile("m9kr/shared/m9kr_ballistics_tracers.lua")
	AddCSLuaFile("m9kr/shared/m9kr_penetration.lua")

	-- Client files
	AddCSLuaFile("m9kr/client/m9kr_impact_helpers.lua")
	AddCSLuaFile("m9kr/client/m9kr_particles.lua")
	AddCSLuaFile("m9kr/client/m9kr_muzzleflash_dynlight.lua")
	AddCSLuaFile("m9kr/client/m9kr_muzzleflash_scotch.lua")
	AddCSLuaFile("m9kr/client/m9kr_hud.lua")
	AddCSLuaFile("m9kr/client/m9kr_muzzle_heatwave.lua")
	AddCSLuaFile("m9kr/client/m9kr_settings_panel.lua")
end

-- ============================================================================
-- Server ConVar change network system (MP superadmin settings panel)
-- Clients can't RunConsoleCommand server ConVars in MP — route through net
-- ============================================================================

if SERVER then
	util.AddNetworkString("M9KR_SetServerConVar")

	net.Receive("M9KR_SetServerConVar", function(len, ply)
		if not IsValid(ply) or not ply:IsSuperAdmin() then return end

		local cvarName = net.ReadString()
		local cvarValue = net.ReadString()

		-- Only allow m9kr_ prefixed ConVars (covers server settings + weapon blacklist)
		if not string.StartsWith(cvarName, "m9kr_") then return end

		-- Verify the ConVar actually exists
		local cv = GetConVar(cvarName)
		if not cv then return end

		RunConsoleCommand(cvarName, cvarValue)
	end)
end

-- ============================================================================
-- Shared systems (both SERVER and CLIENT)
-- Ballistics MUST load first — tracers and penetration depend on it
-- ============================================================================

include("m9kr/shared/m9kr_ballistics.lua")
include("m9kr/shared/m9kr_ballistics_tracers.lua")
include("m9kr/shared/m9kr_penetration.lua")

-- ============================================================================
-- Server-only systems
-- ============================================================================

if SERVER then
	include("m9kr/server/m9kr_squad_tracker.lua")
end

-- ============================================================================
-- Client-only systems
-- ============================================================================

if CLIENT then
	include("m9kr/client/m9kr_impact_helpers.lua")
	include("m9kr/client/m9kr_particles.lua")
	include("m9kr/client/m9kr_muzzleflash_dynlight.lua")
	include("m9kr/client/m9kr_muzzleflash_scotch.lua")
	include("m9kr/client/m9kr_hud.lua")
	include("m9kr/client/m9kr_muzzle_heatwave.lua")
	include("m9kr/client/m9kr_settings_panel.lua")
end

-- ============================================================================
-- DarkRP anti-pocket exploit protection
-- Prevents players from pocketing ammo crates and projectiles for infinite ammo
-- ============================================================================

local M9KR_NO_POCKET = {
	["m9kr_ammo_357"] = true,
	["m9kr_ammo_ar2"] = true,
	["m9kr_ammo_buckshot"] = true,
	["m9kr_ammo_pistol"] = true,
	["m9kr_ammo_smg"] = true,
	["m9kr_ammo_sniper_rounds"] = true,
	["m9kr_ammo_winchester"] = true,
}

hook.Add("canPocket", "M9KR_PreventPocket", function(ply, wep)
	if not IsValid(wep) then return end
	if M9KR_NO_POCKET[wep:GetClass()] then
		return false
	end
end)

print("[M9K:R] All M9K Reloaded systems loaded successfully")
