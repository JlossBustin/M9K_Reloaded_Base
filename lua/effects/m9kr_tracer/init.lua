--[[
	M9K Reloaded - Tracer Effect

	Uses animated render.DrawBeam tracers for all calibers (TFA Base style)
	Color, width, and frequency are dynamically determined by caliber from m9kr_ballistics_tracers.lua

	REALISTIC TRACER COLORS BY COUNTRY/CALIBER:
	- Red: Western/NATO ammunition (M16, M4, SCAR, FAL, G3, etc.)
	- Green: Russian/Soviet and Chinese ammunition (AK-47, AK-74, PKM, etc.)
	- Yellow/White: Shotgun specialty loads
	- Purple-Red: Heavy anti-materiel rounds (.50 BMG, .408 CheyTac, 12.7mm, 23mm)
	  └─ Iconic color that lingers more on the red side with purple tint
	  └─ Highly visible and intimidating for heavy calibers

	Examples:
	- 9x19mm NATO: Red tracers
	- 9x18mm Makarov: Green tracers (Russian)
	- 5.56x45mm NATO: Red tracers (M16/M4)
	- 7.62x39mm: Bright green tracers (AK-47, Russian/Chinese)
	- 7.62x51mm NATO: Bright red tracers (FAL/G3/SCAR-H)
	- 7.62x54mmR: Green-yellow tracers (Mosin/SVD, Russian)
	- .50 BMG: Purple-red tracers (iconic heavy caliber color)
	- 23mm autocannon: Deep purple-red tracers (almost magenta)
]]--

-- Tracer beam material and properties
EFFECT.Mat = Material("effects/laser_tracer")
EFFECT.Speed = 8192  -- Units per second (fast, like a bullet)
EFFECT.TracerLength = 96  -- Length of the tracer beam in units
EFFECT.BeamWidth = 3  -- Width of the tracer beam (standard calibers)

function EFFECT:Init(data)
	self.EndPos = data:GetOrigin()
	self.TracerType = data:GetScale() or 0  -- 0 = standard, 1 = heavy

	-- Decode color from Start vector (RGB encoded in XYZ)
	local colorVec = data:GetStart()
	if colorVec and colorVec ~= Vector(0, 0, 0) then
		self.TracerColor = {r = colorVec.x, g = colorVec.y, b = colorVec.z}
	else
		-- Fallback to default white/orange
		self.TracerColor = {r = 255, g = 220, b = 180}
	end

	-- Decode width from Magnitude
	self.TracerWidth = data:GetMagnitude()
	if not self.TracerWidth or self.TracerWidth == 0 then
		self.TracerWidth = 3  -- Default width
	end

	local weaponEnt = data:GetEntity()
	local weaponEntOG = weaponEnt
	local attachment = data:GetAttachment()

	-- Get owner entity
	local owent
	if IsValid(weaponEnt) then
		owent = weaponEnt:GetOwner()
		if not IsValid(owent) then
			owent = weaponEnt:GetParent()
		end
	end

	-- CRITICAL: Switch to viewmodel for first person, worldmodel for third person
	local useEyePos = false
	local isThirdPerson = false
	if IsValid(owent) and owent:IsPlayer() then
		if owent ~= LocalPlayer() or owent:ShouldDrawLocalPlayer() then
			-- Third person - use worldmodel (active weapon)
			isThirdPerson = true
			weaponEnt = owent:GetActiveWeapon()
			if not IsValid(weaponEnt) then return end
		else
			-- First person - check if scoped (weapon.isScoped set by m9kr_weapon_state_handler)
			if IsValid(weaponEntOG) and weaponEntOG.isScoped then
				-- Scoped weapon while ADS - use player's eye position for accurate tracer
				useEyePos = true
			else
				-- Not scoped - use viewmodel
				weaponEnt = owent:GetViewModel()
				if not IsValid(weaponEnt) then return end
			end
		end
	end

	local startPos
	if useEyePos then
		-- Use player's shoot position for scoped weapons, offset to match muzzle flash position
		-- This matches the visual muzzle flash offset (-8 down, +5 forward)
		local eyePos = owent:GetShootPos()
		local aimAng = owent:EyeAngles()

		-- Offset to match muzzle flash: -8 down, +5 forward
		startPos = eyePos + aimAng:Up() * -8 + aimAng:Forward() * 5
	else
		-- Get correct attachment index from weapon
		if IsValid(weaponEntOG) and weaponEntOG.MuzzleAttachment then
			attachment = weaponEnt:LookupAttachment(weaponEntOG.MuzzleAttachment)

			if not attachment or attachment <= 0 then
				attachment = 1
			end

			if weaponEntOG.Akimbo then
				attachment = 2 - weaponEntOG.AnimCycle
			end
		end

		-- Get attachment position
		local angpos = weaponEnt:GetAttachment(attachment)
		if not angpos or not angpos.Pos then
			angpos = {
				Pos = Vector(0, 0, 0),
				Ang = Angle(0, 0, 0)
			}
		end

		-- Third person: correct tracer origin using weapon's world model offset
		if isThirdPerson and IsValid(weaponEntOG) and weaponEntOG.WMCorrectedMuzzle and weaponEntOG.Offset then
			local offset = weaponEntOG.Offset
			if offset.Pos and offset.Ang then
				local boneIndex = owent:LookupBone("ValveBiped.Bip01_R_Hand")
				if boneIndex then
					local bonePos, boneAng = owent:GetBonePosition(boneIndex)
					if angpos.Pos then
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
						local corrPos = LocalToWorld(localPos, localAng, offsetPos, offsetAng)
						angpos.Pos = corrPos
					end
				end
			end
		end

		startPos = angpos.Pos
	end

	self.StartPos = startPos

	-- Calculate animation properties
	self.Normal = (self.EndPos - self.StartPos):GetNormalized()
	self.Length = (self.EndPos - self.StartPos):Length()
	self.Life = 0
	self.MaxLife = self.Length / self.Speed  -- Time it takes to reach target

	-- Set render bounds so effect is visible
	self:SetRenderBoundsWS(self.StartPos, self.EndPos)
end

function EFFECT:Think()
	if not self.MaxLife then return false end

	self.Life = self.Life + FrameTime()
	return self.Life < self.MaxLife
end

function EFFECT:Render()
	if not self.Life or not self.MaxLife or not self.Length then return end

	local lifeFrac = self.Life / self.MaxLife

	-- Calculate start and end positions of the moving beam
	local startBeamPos = Lerp(lifeFrac, self.StartPos, self.EndPos)
	local endBeamPos = Lerp(lifeFrac + (self.TracerLength / self.Length), self.StartPos, self.EndPos)

	-- Fade out as it approaches target
	local alpha = math.Clamp(255 * (1 - lifeFrac), 0, 255)

	-- Use color and width from database
	local color = Color(self.TracerColor.r, self.TracerColor.g, self.TracerColor.b, alpha)

	-- Draw the beam
	render.SetMaterial(self.Mat)
	render.DrawBeam(startBeamPos, endBeamPos, self.TracerWidth, 0, 1, color)
end
