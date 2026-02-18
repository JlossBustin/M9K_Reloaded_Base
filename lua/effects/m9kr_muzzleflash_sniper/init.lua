--[[
	M9K Reloaded - Sniper Rifle Muzzle Flash Effect
	Uses TFA Realistic Muzzleflashes 2.0 PCF particle system for optimal performance

	TFA Realistic 2.0 Properties:
	- Particle: muzzleflash_sr25 / muzzleflash_sr25_optimized
	- Life: 0.1 seconds (longer for power weapons)
	- HeatSize: 0.90 (large heatwave for sniper rifles)
	- Dynamic light: 512 size, brightness 1.25

	Performance: PCF particles are hardware-accelerated, ~75% less CPU overhead than programmatic particles
]]--

local blankvec = Vector(0, 0, 0)

EFFECT.Life = 0.1
EFFECT.HeatSize = 0.90
EFFECT.FlashSize = 0.90

function EFFECT:Init(data)
	self.Position = blankvec
	self.WeaponEnt = data:GetEntity()
	self.WeaponEntOG = self.WeaponEnt
	self.Attachment = data:GetAttachment()
	self.Dir = data:GetNormal()

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

	-- Check if weapon is scoped in ADS (weapon.isScoped set by m9kr_weapon_state_handler)
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

	local usingFallbackPos = (isScoped and isFirstPerson)

	local smokeCvar = GetConVar("m9kr_muzzlesmoke")
	local smokeEnabled = smokeCvar and smokeCvar:GetInt() == 1

	if usingFallbackPos or correctedThirdPerson then
		if smokeEnabled then
			ParticleEffect("muzzleflash_sr25", self.vOffset, self.Dir:Angle())
		else
			ParticleEffect("muzzleflash_sr25_optimized", self.vOffset, self.Dir:Angle())
		end
	else
		if smokeEnabled then
			ParticleEffectAttach("muzzleflash_sr25", PATTACH_POINT_FOLLOW, self.WeaponEnt, self.Attachment)
		else
			ParticleEffectAttach("muzzleflash_sr25_optimized", PATTACH_POINT_FOLLOW, self.WeaponEnt, self.Attachment)
		end
	end

	-- scotchmuzzleflash sprites
	if GetConVar("cl_tfa_rms_default_scotchmuzzleflash"):GetFloat() >= 1 then
		local emitter = ParticleEmitter(self.vOffset)
		local AddVel = Vector()
		local sval = 1 - math.random(0, 1) * 2
		local flashCount = math.Round(self.FlashSize * 8)

		for _ = 1, flashCount do
			local particle = emitter:Add("effects/scotchmuzzleflash1", self.vOffset + FrameTime() * AddVel)

			if (particle) then
				particle:SetVelocity(dir * 6 * self.FlashSize + 1.05 * AddVel)
				particle:SetLifeTime(0)
				particle:SetDieTime(self.Life * 1)
				particle:SetStartAlpha(math.Rand(40, 140))
				particle:SetEndAlpha(0)
				particle:SetStartSize(2 * math.Rand(1, 1.5) * self.FlashSize)
				particle:SetEndSize(20 * math.Rand(0.5, 1) * self.FlashSize)
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

	-- Dynamic lighting
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
			dlight.brightness = 1.25
			dlight.Decay = 500
			dlight.Size = 512
			dlight.DieTime = CurTime() + fadeouttime
		end
	end

	-- Heatwave effect
	if TFA and TFA.GetGasEnabled and TFA.GetGasEnabled() then
		local emitter = ParticleEmitter(self.vOffset)
		local AddVel = Vector()
		local particle = emitter:Add("sprites/heatwave", self.vOffset + dir*2)

		if (particle) then
			particle:SetVelocity(dir * 25 * self.HeatSize + 1.05 * AddVel)
			particle:SetLifeTime(0)
			particle:SetDieTime(self.Life)
			particle:SetStartAlpha(math.Rand(200, 225))
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(3, 5) * self.HeatSize)
			particle:SetEndSize(math.Rand(8, 12) * self.HeatSize)
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
