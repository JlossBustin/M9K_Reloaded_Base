--[[
	M9K Reloaded - Client-Side Particle Lighting System

	Handles PCF particle lighting and cleanup for weapon effects.
	Adds methods to SWEP base for smoke particle lighting (TFA Base style).

	This replaces lua/weapons/carby_gun_base/client/cl_effects.lua
]]--

local SWEP = FindMetaTable("Weapon")
if not SWEP then return end

local vector_up = Vector(0, 0, 1)
local math = math
local render = render
local LerpVector = LerpVector

-- Smoke lighting parameters
local SmokeLightingMin = Vector(0.15, 0.15, 0.15)
local SmokeLightingMax = Vector(0.75, 0.75, 0.75)
local SmokeLightingClamp = 1

--[[
	ComputeSmokeLighting
	Used to light PCF smoke particles by setting Control Point 1
	Adapted from TFA Base effects system
]]--
function SWEP:ComputeSmokeLighting(pos, nrm, pcf)
	if not IsValid(pcf) then return end

	-- Compute environmental lighting at the smoke position
	local licht = render.ComputeLighting(pos, nrm)

	-- Calculate average light intensity
	local lichtFloat = math.Clamp((licht.r + licht.g + licht.b) / 3, 0, SmokeLightingClamp) / SmokeLightingClamp

	-- Lerp between min and max lighting based on environment
	local lichtFinal = LerpVector(lichtFloat, SmokeLightingMin, SmokeLightingMax)

	-- Apply lighting to particle control point 1
	pcf:SetControlPoint(1, lichtFinal)
end

--[[
	SmokePCFLighting
	Loop through all SmokePCF tables and apply lighting to them
	Called from weapon Think to update particle lighting
]]--
function SWEP:SmokePCFLighting()
	-- Get muzzle position for lighting calculation
	local att = self:LookupAttachment(self.MuzzleAttachment or 1)
	if not att or att <= 0 then return end

	local angpos = self:GetAttachment(att)
	if not angpos then return end

	local pos = angpos.Pos

	-- Apply lighting to worldmodel smoke PCF particles
	if self.SmokePCF then
		for _, v in pairs(self.SmokePCF) do
			self:ComputeSmokeLighting(pos, vector_up, v)
		end
	end

	-- Apply lighting to viewmodel smoke PCF particles
	local owner = self:GetOwner()
	if IsValid(owner) and owner == LocalPlayer() then
		local vm = owner:GetViewModel()
		if IsValid(vm) and vm.SmokePCF then
			-- Get viewmodel muzzle position
			local vmatt = vm:LookupAttachment(self.MuzzleAttachment or 1)
			if vmatt and vmatt > 0 then
				local vmangpos = vm:GetAttachment(vmatt)
				if vmangpos then
					for _, v in pairs(vm.SmokePCF) do
						self:ComputeSmokeLighting(vmangpos.Pos, vector_up, v)
					end
				end
			end
		end
	end
end

--[[
	CleanParticles
	Cleans up PCF particles on weapon and viewmodel
	Called when weapon is holstered or removed
]]--
function SWEP:CleanParticles()
	if not IsValid(self) then return end

	-- Stop PCF particles on weapon (worldmodel)
	if self.SmokePCF then
		for att, pcf in pairs(self.SmokePCF) do
			if IsValid(pcf) then
				pcf:StopEmission()
			end
		end
		self.SmokePCF = {}
	end

	-- Stop worldmodel particles (legacy method compatibility)
	if self.StopParticles then
		self:StopParticles()
	end

	if self.StopParticleEmission then
		self:StopParticleEmission()
	end

	-- Stop PCF particles on viewmodel
	local owner = self:GetOwner()
	if IsValid(owner) and owner == LocalPlayer() then
		local vm = owner:GetViewModel()
		if IsValid(vm) then
			-- Stop PCF particles on viewmodel
			if vm.SmokePCF then
				for att, pcf in pairs(vm.SmokePCF) do
					if IsValid(pcf) then
						pcf:StopEmission()
					end
				end
				vm.SmokePCF = {}
			end

			-- Stop viewmodel particles (legacy method compatibility)
			if vm.StopParticles then
				vm:StopParticles()
			end

			if vm.StopParticleEmission then
				vm:StopParticleEmission()
			end
		end
	end
end

print("[M9K:R] Client-side particle lighting system loaded (SWEP metatable extended)")
