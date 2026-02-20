--[[
	M9K Reloaded - Consolidated Muzzle Flash Effect
	Uses TFA Realistic Muzzleflashes 2.0 PCF particle system for optimal performance

	Single parameterized effect replacing 10 separate muzzle flash files.
	The active muzzle type is read from the weapon's m9kr_ActiveMuzzleType field,
	which is set by M9KR_SpawnMuzzleFlash() or OnM9KRShotsFiredChanged().

	Each type key maps to a config with: life, heat, flash, particle names,
	dlight brightness, and dlight size.

	Performance: PCF particles are hardware-accelerated, ~75% less CPU overhead than programmatic particles
]]--

local blankvec = Vector(0, 0, 0)

-- ============================================================================
-- Muzzle flash type configs
-- ============================================================================
local MUZZLE_CONFIGS = {
	pistol       = { life = 0.085, heat = 0.70, flash = 0.70, particle = "muzzleflash_pistol",       particleOpt = "muzzleflash_pistol_optimized",       brightness = 0.9,  dlightSize = 384  },
	revolver     = { life = 0.1,   heat = 0.85, flash = 0.85, particle = "muzzleflash_pistol_rbull", particleOpt = "muzzleflash_pistol_rbull_optimized", brightness = 1.25, dlightSize = 512  },
	smg          = { life = 0.085, heat = 0.80, flash = 0.75, particle = "muzzleflash_smg_bizon",    particleOpt = "muzzleflash_smg_optimized",          brightness = 0.95, dlightSize = 384  },
	rifle        = { life = 0.085, heat = 0.80, flash = 0.80, particle = "muzzleflash_6",            particleOpt = "muzzleflash_6_optimized",            brightness = 1.05, dlightSize = 1024 },
	shotgun      = { life = 0.1,   heat = 1.0,  flash = 1.0,  particle = "muzzleflash_shotgun",      particleOpt = "muzzleflash_shotgun_optimized",      brightness = 1.25, dlightSize = 512  },
	shotgun_slug = { life = 0.1,   heat = 1.0,  flash = 1.0,  particle = "muzzleflash_slug",         particleOpt = "muzzleflash_shotgun_optimized",      brightness = 1.25, dlightSize = 512  },
	sniper       = { life = 0.1,   heat = 0.90, flash = 0.90, particle = "muzzleflash_sr25",         particleOpt = "muzzleflash_sr25_optimized",         brightness = 1.25, dlightSize = 512  },
	lmg          = { life = 0.1,   heat = 0.80, flash = 0.80, particle = "muzzleflash_minimi",       particleOpt = "muzzleflash_vollmer_optimized",      brightness = 1.05, dlightSize = 512  },
	hmg          = { life = 0.1,   heat = 0.90, flash = 0.90, particle = "muzzleflash_minimi",       particleOpt = "muzzleflash_vollmer_optimized",      brightness = 1.25, dlightSize = 512  },
	silenced     = { life = 0.085, heat = 0.65, flash = 0.50, particle = "muzzleflash_suppressed",   particleOpt = "muzzleflash_suppressed_optimized",   brightness = 0.85, dlightSize = 128  },
}

function EFFECT:Init(data)
	self.Position = blankvec
	self.WeaponEnt = data:GetEntity()
	self.WeaponEntOG = self.WeaponEnt
	self.Attachment = data:GetAttachment()
	self.Dir = data:GetNormal()

	-- Read muzzle type from weapon (set by M9KR_SpawnMuzzleFlash / OnM9KRShotsFiredChanged)
	local muzzleType = "rifle"
	if IsValid(self.WeaponEntOG) then
		muzzleType = self.WeaponEntOG.m9kr_ActiveMuzzleType or "rifle"
	end
	local cfg = MUZZLE_CONFIGS[muzzleType] or MUZZLE_CONFIGS["rifle"]

	local owent

	if IsValid(self.WeaponEnt) then
		owent = self.WeaponEnt:GetOwner()
	end

	if not IsValid(owent) then
		owent = self.WeaponEnt:GetParent()
	end

	if IsValid(owent) and owent:IsPlayer() then
		if owent ~= LocalPlayer() or owent:ShouldDrawLocalPlayer() then
			self.WeaponEnt = owent:GetActiveWeapon()
			if not IsValid(self.WeaponEnt) then return end
		else

			self.WeaponEnt = owent:GetViewModel()

			local theirweapon = owent:GetActiveWeapon()

			if IsValid(theirweapon) and theirweapon.ViewModelFlip or theirweapon.ViewModelFlipped then
				self.Flipped = true
			end

			if not IsValid(self.WeaponEnt) then return end
		end
	end

	if IsValid(self.WeaponEntOG) and self.WeaponEntOG.MuzzleAttachment then
		self.Attachment = self.WeaponEnt:LookupAttachment(self.WeaponEntOG.MuzzleAttachment)

		if not self.Attachment or self.Attachment <= 0 then
			self.Attachment = 1
		end

		if self.WeaponEntOG.Akimbo then
			self.Attachment = 2 - self.WeaponEntOG.AnimCycle
		end
	end

	local angpos = self.WeaponEnt:GetAttachment(self.Attachment)

	-- Check if weapon is scoped in ADS (weapon.isScoped set by UpdateWeaponInputState)
	-- When scoped, use fallback position below scope crosshair
	local isScoped = IsValid(self.WeaponEntOG) and self.WeaponEntOG.isScoped
	local isFirstPerson = IsValid(owent) and owent:IsPlayer() and owent == LocalPlayer() and not owent:ShouldDrawLocalPlayer()
	local isThirdPerson = IsValid(owent) and owent:IsPlayer() and (owent ~= LocalPlayer() or owent:ShouldDrawLocalPlayer())

	-- Use scale-corrected attachment positions cached by DrawWorldModel (handles Offset.Scale != 1)
	if isThirdPerson and IsValid(self.WeaponEnt) and self.WeaponEnt.WMCorrectedAttachments then
		local corrected = self.WeaponEnt.WMCorrectedAttachments[self.Attachment]
		if corrected then
			angpos = corrected
		end
	end

	-- If scoped in first person or attachment is invalid, use EffectData origin (player eye position)
	-- Offset downward to position below scope crosshair
	if (isScoped and isFirstPerson) or not angpos or not angpos.Pos or angpos.Pos == vector_origin then
		local eyePos = data:GetOrigin()
		local eyeAng = self.Dir:Angle()

		-- Offset position: move down 8 units and forward 5 units from eye position
		-- This positions the muzzle flash below the scope crosshair
		local offsetPos = eyePos + eyeAng:Up() * -8 + eyeAng:Forward() * 5

		angpos = {
			Pos = offsetPos,
			Ang = eyeAng
		}
	end

	-- Third person: correct muzzle position using weapon's world model offset
	-- Only applies to weapons that opt-in via SWEP.WMCorrectedMuzzle = true
	local correctedThirdPerson = false
	if isThirdPerson and IsValid(self.WeaponEnt) and self.WeaponEnt.WMCorrectedMuzzle and self.WeaponEnt.Offset then
		local offset = self.WeaponEnt.Offset
		if offset.Pos and offset.Ang then
			local boneIndex = owent:LookupBone("ValveBiped.Bip01_R_Hand")
			if boneIndex then
				local bonePos, boneAng = owent:GetBonePosition(boneIndex)
				if angpos and angpos.Pos then
					local localPos, localAng = WorldToLocal(angpos.Pos, angpos.Ang, bonePos, boneAng)
					local offsetPos = bonePos + boneAng:Forward() * offset.Pos.Forward
						+ boneAng:Right() * offset.Pos.Right
						+ boneAng:Up() * offset.Pos.Up
					local offsetAng = Angle(boneAng.p, boneAng.y, boneAng.r)
					offsetAng:RotateAroundAxis(offsetAng:Up(), offset.Ang.Up)
					offsetAng:RotateAroundAxis(offsetAng:Right(), offset.Ang.Right)
					offsetAng:RotateAroundAxis(offsetAng:Forward(), offset.Ang.Forward)
					if offset.Scale and offset.Scale ~= 1 then
						localPos = localPos * offset.Scale
					end
					local corrPos, corrAng = LocalToWorld(localPos, localAng, offsetPos, offsetAng)
					angpos = { Pos = corrPos, Ang = corrAng }
					self.Dir = corrAng:Forward()
					correctedThirdPerson = true
				end
			end
		end
	end

	if self.Flipped then
		local tmpang = (self.Dir or angpos.Ang:Forward()):Angle()
		local localang = self.WeaponEnt:WorldToLocalAngles(tmpang)
		localang.y = localang.y + 180
		localang = self.WeaponEnt:LocalToWorldAngles(localang)
		self.Dir = localang:Forward()
	end

	self.Position = self:GetTracerShootPos(angpos.Pos, self.WeaponEnt, self.Attachment)
	self.Norm = self.Dir
	self.vOffset = self.Position

	if correctedThirdPerson then
		self.Position = angpos.Pos
		self.vOffset = angpos.Pos
	end

	local dir = self.Norm

	-- Check if we're using fallback position (scoped in first person)
	local usingFallbackPos = (isScoped and isFirstPerson)

	-- Check if muzzle smoke is enabled (controls particle variant selection)
	local smokeCvar = GetConVar("m9kr_muzzlesmoke")
	local smokeEnabled = smokeCvar and smokeCvar:GetInt() == 1

	-- TFA Realistic 2.0: Choose particle variant based on smoke setting
	if usingFallbackPos or correctedThirdPerson then
		-- Unattached particle at computed world position
		if smokeEnabled then
			ParticleEffect(cfg.particle, self.vOffset, self.Dir:Angle())
		else
			ParticleEffect(cfg.particleOpt, self.vOffset, self.Dir:Angle())
		end
	else
		-- Attach to weapon for smooth tracking
		if smokeEnabled then
			ParticleEffectAttach(cfg.particle, PATTACH_POINT_FOLLOW, self.WeaponEnt, self.Attachment)
		else
			ParticleEffectAttach(cfg.particleOpt, PATTACH_POINT_FOLLOW, self.WeaponEnt, self.Attachment)
		end
	end

	-- Default scotchmuzzleflash sprites (from TFA Realistic 2.0)
	if GetConVar("cl_tfa_rms_default_scotchmuzzleflash"):GetFloat() >= 1 then
		local emitter = ParticleEmitter(self.vOffset)
		local AddVel = Vector()
		local sval = 1 - math.random(0, 1) * 2
		local flashCount = math.Round(cfg.flash * 8)

		for _ = 1, flashCount do
			local particle = emitter:Add("effects/scotchmuzzleflash1", self.vOffset + FrameTime() * AddVel)

			if (particle) then
				particle:SetVelocity(dir * 6 * cfg.flash + 1.05 * AddVel)
				particle:SetLifeTime(0)
				particle:SetDieTime(cfg.life * 1)
				particle:SetStartAlpha(math.Rand(40, 140))
				particle:SetEndAlpha(0)
				particle:SetStartSize(2 * math.Rand(1, 1.5) * cfg.flash)
				particle:SetEndSize(20 * math.Rand(0.5, 1) * cfg.flash)
				particle:SetRoll(math.rad(math.Rand(0, 360)))
				particle:SetRollDelta(math.rad(math.Rand(30, 60)) * sval)
				particle:SetColor(255, 255, 255)
				particle:SetLighting(false)
				if not correctedThirdPerson then
					particle.FollowEnt = self.WeaponEnt
					particle.Att = self.Attachment
				end
			end
		end

		emitter:Finish()
	end

	-- Dynamic lighting (from TFA Realistic 2.0)
	if GetConVar("cl_tfa_rms_muzzleflash_dynlight"):GetFloat() >= 1 then
		local dlight

		if IsValid(self.WeaponEnt) then
			dlight = DynamicLight(self.WeaponEnt:EntIndex())
		else
			dlight = DynamicLight(0)
		end

		local fadeouttime = 0.025

		if (dlight) then
			dlight.Pos = self.Position + dir * 1 - dir:Angle():Right() * 5
			dlight.r = 255
			dlight.g = 192
			dlight.b = 64
			dlight.brightness = cfg.brightness
			dlight.Decay = 500
			dlight.Size = cfg.dlightSize
			dlight.DieTime = CurTime() + fadeouttime
		end
	end

	-- Heatwave effect (from TFA Realistic 2.0)
	if TFA and TFA.GetGasEnabled and TFA.GetGasEnabled() then
		local emitter = ParticleEmitter(self.vOffset)
		local AddVel = Vector()
		local particle = emitter:Add("sprites/heatwave", self.vOffset + dir*2)

		if (particle) then
			particle:SetVelocity(dir * 25 * cfg.heat + 1.05 * AddVel)
			particle:SetLifeTime(0)
			particle:SetDieTime(cfg.life)
			particle:SetStartAlpha(math.Rand(200, 225))
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(3, 5) * cfg.heat)
			particle:SetEndSize(math.Rand(8, 12) * cfg.heat)
			particle:SetRoll(math.Rand(0, 360))
			particle:SetRollDelta(math.Rand(-2, 2))
			particle:SetAirResistance(5)
			particle:SetGravity(Vector(0, 0, 40))
			particle:SetColor(255, 255, 255)
		end

		emitter:Finish()
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
