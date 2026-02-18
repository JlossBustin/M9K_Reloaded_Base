--[[
	M9K Reloaded - Particle System Loader

	Loads and precaches particle systems for muzzle flashes and effects.
	Uses TFA Realistic Muzzleflashes 2.0 PCF system for optimal multiplayer performance.

	ConVar:
	- cl_tfa_rms_optimized_smoke: Controls optimized particle variants (recommended for multiplayer)
]]--

-- Create TFA Realistic 2.0 ConVar for particle optimization (if it doesn't exist)
if not ConVarExists("cl_tfa_rms_optimized_smoke") then
	CreateClientConVar("cl_tfa_rms_optimized_smoke", "1", true, false,
		"Use optimized muzzleflash particles (recommended for multiplayer)")
end

M9KR = M9KR or {}
M9KR.Particles = M9KR.Particles or {}

-- List of PCF files to load
M9KR.Particles.PCFFiles = {
	"realistic_muzzleflashes_2",  -- TFA Realistic Muzzleflashes 2.0 (284 KB, hardware-accelerated)
	"tfa_ins2_muzzlesmoke",       -- INS2-style muzzle smoke trails
	"tfa_ins2_shellsmoke",        -- INS2-style shell smoke trails
}

local addedPCF = {}
local cachedParticles = {}

-- Particle name mappings (particle name -> TFA PCF file)
M9KR.Particles.ParticleMap = {
	-- Muzzle smoke particles (using original TFA particle files)
	["tfa_ins2_weapon_muzzle_smoke"] = "tfa_ins2_muzzlesmoke",
	["tfa_ins2_weapon_shell_smoke"] = "tfa_ins2_shellsmoke",
	["tfa_ins2_shell_eject"] = "tfa_ins2_ejectionsmoke",
}

--[[
	Initialize particle systems
	Loads PCF files and precaches particle systems
]]--
function M9KR.Particles.Initialize()
	-- Precache materials FIRST so particles can find them
	local materials = {
		"particles/ins_muzzleflash_custom",
		"particles/ins_muzzleflash_split_custom",
		"particles/ins_particle_glow_custom",
		"particles/ins_burstspark_custom",
		"particles/ins_burstspark_trail_custom",
		"particles/ins_spark_trail_custom",
		"particles/mw2019_dust_impact_anim_2_custom",
		"particles/mw2019_dust_impact_anim_4_custom",
		"effects/fas_dust_a_custom",
		"effects/fas_dust_b_custom",
		"effects/fas_dust_thick_custom",
		"effects/fas_flamering_custom",
		"effects/fas_smoke_beam_custom",
		"effects/fas_smoke_trail_custom",
		"effects/fas_sparkwires_custom",
	}

	for _, matPath in ipairs(materials) do
		Material(matPath)
	end

	-- Load each PCF file AFTER materials are loaded
	for _, pcfFile in ipairs(M9KR.Particles.PCFFiles) do
		if not addedPCF[pcfFile] then
			local pcfPath = "particles/" .. pcfFile .. ".pcf"
			game.AddParticles(pcfPath)
			addedPCF[pcfFile] = true
		end
	end

	-- Precache particle systems (barrel smoke)
	for particleName, _ in pairs(M9KR.Particles.ParticleMap) do
		if not cachedParticles[particleName] then
			PrecacheParticleSystem(particleName)
			cachedParticles[particleName] = true
		end
	end

	-- Precache TFA Realistic Muzzleflashes 2.0 particles (bundled with M9KR)
	local tfaParticles = {
		-- TFA Realistic 2.0 muzzleflash particles
		"muzzleflash_pistol",
		"muzzleflash_pistol_optimized",
		"muzzleflash_pistol_rbull",              -- Revolver
		"muzzleflash_pistol_rbull_optimized",
		"muzzleflash_smg_bizon",
		"muzzleflash_smg_optimized",
		"muzzleflash_6",                         -- Rifle
		"muzzleflash_6_optimized",
		"muzzleflash_shotgun",
		"muzzleflash_shotgun_optimized",
		"muzzleflash_slug",                      -- Shotgun slug
		"muzzleflash_sr25",                      -- Sniper
		"muzzleflash_sr25_optimized",
		"muzzleflash_minimi",                    -- LMG/HMG
		"muzzleflash_vollmer_optimized",
		"muzzleflash_suppressed",
		"muzzleflash_suppressed_optimized",

		-- INS2 smoke trail particles (from tfa_ins2_muzzlesmoke.pcf and tfa_ins2_shellsmoke.pcf)
		"tfa_ins2_weapon_muzzle_smoke",          -- INS2-style muzzle smoke trail (wispy, long-lasting)
		"tfa_ins2_weapon_shell_smoke",           -- INS2-style shell smoke trail
	}

	for _, particleName in ipairs(tfaParticles) do
		PrecacheParticleSystem(particleName)
	end
end

-- Initialize when the game loads
hook.Add("InitPostEntity", "M9KR.Particles.Initialize", M9KR.Particles.Initialize)
M9KR.Particles.Initialize()

--[[
	===============================================
	M9K Reloaded - Particle Following System
	===============================================

	Optimized particle following system for viewmodel and worldmodel attachments.
	Keeps muzzle flash particles attached to the weapon barrel during movement.
]]--

local vector_origin = Vector()

M9KR.Particles.FlareParts = {}
M9KR.Particles.VMAttachments = {}

local VMAttachments = M9KR.Particles.VMAttachments
local FlareParts = M9KR.Particles.FlareParts

local ply, vm
local lastVMModel, lastVMAtts
local lastRequired = 0

-- Cache functions for performance
local RealTime = RealTime
local FrameTime = FrameTime
local LocalPlayer = LocalPlayer
local ipairs = ipairs
local isfunction = isfunction
local WorldToLocal = WorldToLocal
local LocalToWorld = LocalToWorld
local table = table

local thinkAttachments = {}
local slowThinkers = 0

-- Update particle positions every frame
hook.Add("PreDrawEffects", "M9KRMuzzleUpdate", function()
	if lastRequired < RealTime() then return end

	if not ply then
		ply = LocalPlayer()
	end

	if not IsValid(vm) then
		vm = ply:GetViewModel()
		if not IsValid(vm) then return end
	end

	local vmmodel = vm:GetModel()

	if vmmodel ~= lastVMModel then
		lastVMModel = vmmodel
		lastVMAtts = vm:GetAttachments()
	end

	if not lastVMAtts then return end

	-- Update viewmodel attachment cache
	if slowThinkers == 0 then
		for i in pairs(thinkAttachments) do
			VMAttachments[i] = vm:GetAttachment(i)
		end
	else
		for i = 1, #lastVMAtts do
			VMAttachments[i] = vm:GetAttachment(i)
		end
	end

	-- Update all registered particles
	for _, v in ipairs(FlareParts) do
		if v and v.ThinkFunc then
			v:ThinkFunc()
		end
	end
end)

-- Register a particle to follow the muzzle attachment
function M9KR.Particles.RegisterParticleThink(particle, partfunc)
	if not particle or not isfunction(partfunc) then return end

	if not ply then
		ply = LocalPlayer()
	end

	if not IsValid(vm) then
		vm = ply:GetViewModel()
		if not IsValid(vm) then return end
	end

	particle.ThinkFunc = partfunc

	-- Calculate initial offset from attachment
	if IsValid(particle.FollowEnt) and particle.Att then
		local angpos = particle.FollowEnt:GetAttachment(particle.Att)

		if angpos then
			particle.OffPos = WorldToLocal(particle:GetPos(), particle:GetAngles(), angpos.Pos, angpos.Ang)
		end
	end

	local att = particle.Att
	local isFast = partfunc == M9KR.Particles.FollowMuzzle and att ~= nil
	local isVM = particle.FollowEnt == vm

	if isFast then
		if isVM then
			thinkAttachments[att] = (thinkAttachments[att] or 0) + 1
		end
	else
		slowThinkers = slowThinkers + 1
	end

	table.insert(FlareParts, particle)

	-- Clean up when particle dies
	timer.Simple(particle:GetDieTime(), function()
		if particle then
			table.RemoveByValue(FlareParts, particle)
		end

		if not isFast then
			slowThinkers = slowThinkers - 1
		elseif isVM and att then
			thinkAttachments[att] = thinkAttachments[att] - 1
			if thinkAttachments[att] <= 0 then thinkAttachments[att] = nil end
		end
	end)

	lastRequired = RealTime() + 0.5
end

-- Follow muzzle attachment (called every frame for registered particles)
function M9KR.Particles.FollowMuzzle(self, first)
	if lastRequired < RealTime() then
		lastRequired = RealTime() + 0.5
		return
	end

	lastRequired = RealTime() + 0.5

	if self.isfirst == nil then
		self.isfirst = false
		first = true
	end

	if not IsValid(ply) or not IsValid(vm) then return end

	if not IsValid(self.FollowEnt) then return end
	local owent = self.FollowEnt:GetOwner() or self.FollowEnt
	if not IsValid(owent) then return end

	-- Apply player velocity on first frame
	local firvel
	if first then
		firvel = owent:GetVelocity() * FrameTime() * 1.1
	else
		firvel = vector_origin
	end

	if not self.Att or not self.OffPos then return end

	-- Viewmodel attachment following
	if self.FollowEnt == vm then
		local angpos = VMAttachments[self.Att]

		if angpos then
			local tmppos = LocalToWorld(self.OffPos, self:GetAngles(), angpos.Pos, angpos.Ang)
			local npos = tmppos + self:GetVelocity() * FrameTime()
			self.OffPos = WorldToLocal(npos + firvel, self:GetAngles(), angpos.Pos, angpos.Ang)
			self:SetPos(npos + firvel)
		end

		return
	end

	-- Worldmodel attachment following
	local angpos = self.FollowEnt:GetAttachment(self.Att)

	if angpos then
		local tmppos = LocalToWorld(self.OffPos, self:GetAngles(), angpos.Pos, angpos.Ang)
		local npos = tmppos + self:GetVelocity() * FrameTime()
		self.OffPos = WorldToLocal(npos + firvel * 0.5, self:GetAngles(), angpos.Pos, angpos.Ang)
		self:SetPos(npos + firvel)
	end
end

print("[M9K:R] Particle system loaded")
