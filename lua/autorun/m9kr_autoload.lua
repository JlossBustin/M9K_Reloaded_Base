--[[
	M9K Reloaded - Autoloader

	GMod only autoruns files directly in lua/autorun/, not subdirectories.
	This loader includes all M9K:R systems from subdirectories in the correct order.
]]--

AddCSLuaFile()

print("[M9K:R] Loading M9K Reloaded systems...")

-- Precache particles (TFA Realistic Muzzleflashes 2.0 - optimized for multiplayer)
if CLIENT then
	game.AddParticles("particles/realistic_muzzleflashes_2.pcf")
	print("[M9K:R] Loaded realistic_muzzleflashes_2.pcf (284 KB, hardware-accelerated)")

	-- Load TFA Ballistics particles (bullet impacts, smoke, etc.)
	game.AddParticles("particles/tfa_ballistics.pcf")
	print("[M9K:R] Loaded tfa_ballistics.pcf (bullet impact particles)")
end

if SERVER then
	game.AddParticles("particles/realistic_muzzleflashes_2.pcf")
	game.AddParticles("particles/tfa_ballistics.pcf")

	-- Server-controlled ConVars (replicated to clients, only server can change)
	CreateConVar("m9kr_bullet_impact", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
		"Bullet impact effects: 0 = GMod Default, 1 = M9K Custom", 0, 1)
	CreateConVar("m9kr_metal_impact", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
		"Metal impact effects: 0 = GMod Default, 1 = M9K Custom", 0, 1)
	CreateConVar("m9kr_dust_impact", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
		"Dust impact effects: 0 = GMod Default, 1 = M9K Custom", 0, 1)
	CreateConVar("m9kr_muzzle_heatwave", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED},
		"Muzzle heatwave level: 0 = Disabled, 1 = Full (100%), 2 = Reduced (50%)", 0, 2)
end

-- Precache TFA Realistic 2.0 muzzleflash particle systems
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

print("[M9K:R] Precached TFA Realistic 2.0 particle systems")

-- Load client-side systems
if CLIENT then
	include("autorun/client/m9kr_particles.lua")
	include("autorun/client/m9kr_muzzleflash_dynlight.lua")
	include("autorun/client/m9kr_muzzleflash_scotch.lua")
	include("autorun/client/m9kr_particle_lighting.lua")
	include("autorun/client/m9kr_safety_handler.lua")
	include("autorun/client/m9kr_suppressor_handler.lua")
	include("autorun/client/m9kr_viewmodel_mods.lua")
	include("autorun/client/m9kr_low_ammo_warning.lua")
	include("autorun/client/m9kr_shell_ejection.lua")
	print("[M9K:R] Loaded client-side systems: particles, muzzle effects, lighting, safety, suppressor, viewmodel, low ammo, shell ejection")
end

-- Load shared systems (autorun/tools/)
include("autorun/tools/m9kr_ballistics.lua")
include("autorun/tools/m9kr_ballistics_tracers.lua")
include("autorun/tools/m9kr_penetration.lua")

print("[M9K:R] All M9K Reloaded systems loaded successfully")
