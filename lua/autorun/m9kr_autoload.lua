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
	CreateConVar("m9kr_muzzle_heatwave", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
		"Muzzle heatwave level: 0 = Disabled, 1 = Full (100%), 2 = Reduced (50%)", 0, 2)
	CreateConVar("m9kr_hud_mode", "4", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
		"M9K:R HUD Mode: 0 = GMod Default, 1 = Weapon HUD, 2 = Weapon + Squad, 3 = Weapon + Health/Armor, 4 = Full HUD", 0, 4)
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

-- ============================================================================
-- Send client & shared files to clients (SERVER only)
-- ============================================================================

if SERVER then
	-- Shared files (clients need these too)
	AddCSLuaFile("m9kr/shared/m9kr_ballistics.lua")
	AddCSLuaFile("m9kr/shared/m9kr_ballistics_tracers.lua")
	AddCSLuaFile("m9kr/shared/m9kr_penetration.lua")

	-- Client files
	AddCSLuaFile("m9kr/client/m9kr_particles.lua")
	AddCSLuaFile("m9kr/client/m9kr_muzzleflash_dynlight.lua")
	AddCSLuaFile("m9kr/client/m9kr_muzzleflash_scotch.lua")
	AddCSLuaFile("m9kr/client/m9kr_hud.lua")
	AddCSLuaFile("m9kr/client/m9kr_muzzle_heatwave.lua")
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
	include("m9kr/client/m9kr_particles.lua")
	include("m9kr/client/m9kr_muzzleflash_dynlight.lua")
	include("m9kr/client/m9kr_muzzleflash_scotch.lua")
	include("m9kr/client/m9kr_hud.lua")
	include("m9kr/client/m9kr_muzzle_heatwave.lua")
end

print("[M9K:R] All M9K Reloaded systems loaded successfully")
