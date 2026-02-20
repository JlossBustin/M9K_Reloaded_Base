-- M9K Reloaded Scoped Base - Client Init

include("shared.lua")

-- ============================================================================
-- HUD Functions
-- ============================================================================

-- HUDShouldDraw inherited from carby_gun_base

-- ============================================================================
-- Scope Sway
-- ============================================================================

-- Calculate scope sway offset and rotation based on movement
-- Returns: swayX, swayY (position offset), rotationAngle (degrees)
function SWEP:GetScopeSway()
	if not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return 0, 0, 0
	end

	-- Initialize animation variables
	self.BreathIntensity = self.BreathIntensity or 0
	self.WalkIntensity = self.WalkIntensity or 0
	self.SprintIntensity = self.SprintIntensity or 0
	self.LateralVelocitySmooth = self.LateralVelocitySmooth or 0
	self.LastEyeAngles = self.LastEyeAngles or self.Owner:EyeAngles()
	self.CameraRotationVelocity = self.CameraRotationVelocity or 0

	-- Check if game is paused (singleplayer)
	-- In singleplayer, FrameTime() returns 0 when paused
	local rawFrameTime = FrameTime()
	local isPaused = (rawFrameTime == 0)

	local ft = isPaused and 0.001 or math.Clamp(rawFrameTime, 0, 0.1)
	local ct = CurTime()

	-- Use CurTime() directly as the animation clock (same as gun_base)
	local animTime = CurTime()

	local velocity = self.Owner:GetVelocity()
	local speed = velocity:Length2D()
	local isOnGround = self.Owner:IsOnGround()

	-- Check if player is pressing movement keys (for immediate sprint exit when keys released)
	local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)

	local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and speed > 50 and isOnGround and isPressingMovement
	if self.JumpCancelsSprint and not isOnGround and (self.SprintJumping or false) then
		isActuallySprinting = false
	end

	local isSprinting = isActuallySprinting
	local isWalking = speed > 20 and not isSprinting and isOnGround
	local isShooting = self.Weapon:GetNextPrimaryFire() > ct - 0.15
	local isReloading = self.Weapon:GetNWBool("Reloading")

	-- Track camera rotation velocity for view turning tilt
	local currentEyeAngles = self.Owner:EyeAngles()
	local angleDiff = currentEyeAngles.y - self.LastEyeAngles.y

	-- Handle angle wrap-around (-180 to 180)
	if angleDiff > 180 then
		angleDiff = angleDiff - 360
	elseif angleDiff < -180 then
		angleDiff = angleDiff + 360
	end

	-- Calculate angular velocity (degrees per second)
	local angularVelocity = angleDiff / ft
	self.CameraRotationVelocity = Lerp(ft * 5, self.CameraRotationVelocity, angularVelocity)
	self.LastEyeAngles = currentEyeAngles

	-- Track lateral velocity for tilt animation (matching gun_base)
	local eyeAng = self.Owner:EyeAngles()
	local rightVec = eyeAng:Right()
	rightVec.z = 0
	rightVec:Normalize()
	local lateralVel = velocity:Dot(rightVec)
	self.LateralVelocitySmooth = Lerp(ft * 3, self.LateralVelocitySmooth, lateralVel)

	-- Calculate target intensities
	local targetBreath = 0  -- No breathing sway when scoped
	local targetWalk = isWalking and math.Clamp(speed / 200, 0, 1) or 0
	local targetSprint = isSprinting and math.Clamp(speed / 250, 0, 1) or 0

	-- Smooth transitions (matching gun_base speeds)
	self.BreathIntensity = Lerp(ft * 2, self.BreathIntensity, targetBreath)
	self.WalkIntensity = Lerp(ft * 6, self.WalkIntensity, targetWalk)
	self.SprintIntensity = Lerp(ft * 4, self.SprintIntensity, targetSprint)

	-- Calculate sway
	local swayX = 0
	local swayY = 0
	local rotationAngle = 0

	-- Reduced ADS multiplier for more visible scope sway (60% reduction instead of 85%)
	local aimMult = 1 - 0.60  -- 0.40 (more visible than gun_base ADS)

	-- Walking bob (very slow frequency, increased scale for visible movement through scope)
	if self.WalkIntensity > 0.01 then
		local walkMult = self.WalkIntensity * aimMult
		local walkTime = animTime * 2.5  -- Slow horizontal sway frequency

		-- Vertical bob - slower frequency (reduced multiplier) for smoother up/down movement
		swayY = swayY + math.abs(math.sin(walkTime * 1.25)) * walkMult * 0.05 * 180  -- Reduced from *1.5 to *1.25 for slower vertical

		-- Horizontal sway - decreased amplitude for less left/right movement
		swayX = swayX + math.sin(walkTime) * walkMult * 0.25 * 60
	end

	-- Sprint bob (slower frequency, increased scale for visible movement)
	if self.SprintIntensity > 0.01 then
		local sprintMult = self.SprintIntensity
		local sprintTime = animTime * 3.5  -- Slow horizontal sway frequency

		-- Vertical bob - slower frequency (reduced multiplier) for smoother up/down movement
		swayY = swayY + math.abs(math.sin(sprintTime * 1.25)) * sprintMult * 0.1 * 180  -- Reduced from *1.5 to *1.25 for slower vertical

		-- Horizontal sway - decreased amplitude for less left/right movement
		swayX = swayX + math.sin(sprintTime) * sprintMult * 0.3 * 60
	end

	-- Lateral tilt rotation (5-10 degree range, non-inverted)
	local xVelocityClamped = self.LateralVelocitySmooth

	-- TFA's square root scaling for high velocities (matching gun_base)
	if math.abs(xVelocityClamped) > 200 then
		local sign = (xVelocityClamped < 0) and -1 or 1
		xVelocityClamped = (math.sqrt((math.abs(xVelocityClamped) - 200) / 50) * 50 + 200) * sign
	end

	-- Calculate rotation angle from lateral movement (5-10 degree range at full strafe speed)
	-- At 200 units/sec strafe speed, aim for ~7.5 degrees rotation
	-- NEGATIVE sign for correct direction: strafe right = tilt right (positive velocity = positive angle)
	local rotationScale = -0.0375  -- 200 * 0.0375 = 7.5 degrees at full strafe
	rotationAngle = xVelocityClamped * rotationScale

	-- Add camera rotation tilt (when turning view while scoped)
	-- Camera turning right (positive angular velocity) = tilt right (positive angle)
	-- Scale camera rotation to degrees (max ~5 degrees at moderate turn speed)
	-- Reduced by 15% from 0.015 to 0.01275 for subtler movement
	local cameraTiltScale = 0.01275  -- Angular velocity to tilt conversion (positive for matching direction)
	local cameraTilt = self.CameraRotationVelocity * cameraTiltScale
	rotationAngle = rotationAngle + cameraTilt

	-- Clamp total rotation to reasonable range (max ±10 degrees)
	rotationAngle = math.Clamp(rotationAngle, -10, 10)

	-- Add minimal horizontal translation for subtle movement (keep scope mostly centered)
	swayX = swayX + (xVelocityClamped * 0.02)  -- Very small translation

	-- Add jump offset to scope sway (matching scoped ADS jump intensity from gun_base)
	self.JumpVelocitySmooth = self.JumpVelocitySmooth or 0
	self.JumpIntensitySmooth = self.JumpIntensitySmooth or 0

	-- Smooth vertical velocity tracking
	local jumpVelocityTarget = velocity.z
	self.JumpVelocitySmooth = Lerp(ft * 5, self.JumpVelocitySmooth, jumpVelocityTarget)

	-- Detect jumping
	local isJumping = not isOnGround and math.abs(velocity.z) > 10

	-- Calculate raw jump intensity with scoped ADS reduction (0.4 multiplier from gun_base)
	local rawJumpIntensity = (3 + math.Clamp(math.abs(self.JumpVelocitySmooth) - 100, 0, 200) / 200 * 4) * 0.4

	-- Smoothly lerp jump intensity
	local jumpIntensityTarget = isJumping and rawJumpIntensity or 0
	self.JumpIntensitySmooth = Lerp(ft * 8, self.JumpIntensitySmooth, jumpIntensityTarget)

	-- Apply jump sway to scope (subtle movement)
	local trigX = -math.Clamp(self.JumpVelocitySmooth / 200, -1, 1) * math.pi / 2
	local sinValue = math.sin(trigX)
	local jumpScale = 15  -- Scale factor for scope pixels

	-- Add jump sway (horizontal and vertical)
	swayX = swayX + (sinValue * jumpScale * self.JumpIntensitySmooth)
	swayY = swayY - (sinValue * jumpScale * self.JumpIntensitySmooth * 0.3)  -- Less vertical movement

	return swayX, swayY, rotationAngle
end

-- ============================================================================
-- Scope HUD Drawing
-- ============================================================================

-- Draw the "+ 1" indicator and fire mode when chambered (for scoped weapons)
function SWEP:DrawHUD()
	-- Critical safety checks for weapon state during transitions
	if not IsValid(self) or not IsValid(self.Weapon) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then
		return
	end

	-- First draw scope reticles if scoped in
	-- Don't draw scope when USE is held (forces idle state), on safety, or actually sprinting
	local isInADS = self.m9kr_IsInADS or false

	-- Only block scope rendering if player is actually sprinting (not just holding sprint key)
	-- Also block if on safety or holding USE key
	local isPressingMovement = self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_BACK) or self.Owner:KeyDown(IN_MOVELEFT) or self.Owner:KeyDown(IN_MOVERIGHT)
	local isActuallySprinting = self.Owner:KeyDown(IN_SPEED) and self.Owner:IsOnGround() and self.Owner:GetVelocity():Length2D() > 20 and isPressingMovement
	if self.Owner:KeyDown(IN_ATTACK2) and isInADS and not self.Owner:KeyDown(IN_USE) and not self:GetIsOnSafe() and not isActuallySprinting then

			-- CRITICAL FIX: Initialize scope tables HERE if missing (for picked-up weapons from ground)
			-- Deploy() is NOT called on CLIENT for world weapons, so this is the only reliable place
			if not self.LensTable or not self.ReticleTable or not self.ScopeTable or not self.QuadTable or not self.FilterTable then
				local iScreenWidth = surface.ScreenWidth()
				local iScreenHeight = surface.ScreenHeight()

				self.ScopeTable = {}
				self.ScopeTable.l = iScreenHeight*self.ScopeScale
				self.ScopeTable.x1 = 0.5*(iScreenWidth + self.ScopeTable.l)
				self.ScopeTable.y1 = 0.5*(iScreenHeight - self.ScopeTable.l)
				self.ScopeTable.x2 = self.ScopeTable.x1
				self.ScopeTable.y2 = 0.5*(iScreenHeight + self.ScopeTable.l)
				self.ScopeTable.x3 = 0.5*(iScreenWidth - self.ScopeTable.l)
				self.ScopeTable.y3 = self.ScopeTable.y2
				self.ScopeTable.x4 = self.ScopeTable.x3
				self.ScopeTable.y4 = self.ScopeTable.y1
				self.ScopeTable.l = (iScreenHeight + 1)*self.ScopeScale

				self.QuadTable = {}
				self.QuadTable.x1 = 0
				self.QuadTable.y1 = 0
				self.QuadTable.w1 = iScreenWidth
				self.QuadTable.h1 = 0.5*iScreenHeight - self.ScopeTable.l
				self.QuadTable.x2 = 0
				self.QuadTable.y2 = 0.5*iScreenHeight + self.ScopeTable.l
				self.QuadTable.w2 = self.QuadTable.w1
				self.QuadTable.h2 = self.QuadTable.h1
				self.QuadTable.x3 = 0
				self.QuadTable.y3 = 0
				self.QuadTable.w3 = 0.5*iScreenWidth - self.ScopeTable.l
				self.QuadTable.h3 = iScreenHeight
				self.QuadTable.x4 = 0.5*iScreenWidth + self.ScopeTable.l
				self.QuadTable.y4 = 0
				self.QuadTable.w4 = self.QuadTable.w3
				self.QuadTable.h4 = self.QuadTable.h3

				self.LensTable = {}
				self.LensTable.x = self.QuadTable.w3
				self.LensTable.y = self.QuadTable.h1
				self.LensTable.w = 2*self.ScopeTable.l
				self.LensTable.h = 2*self.ScopeTable.l

				self.ReticleTable = {}
				self.ReticleTable.wdivider = 3.125
				self.ReticleTable.hdivider = 1.7579/self.ReticleScale
				self.ReticleTable.x = (iScreenWidth/2)-((iScreenHeight/self.ReticleTable.hdivider)/2)
				self.ReticleTable.y = (iScreenHeight/2)-((iScreenHeight/self.ReticleTable.hdivider)/2)
				self.ReticleTable.w = iScreenHeight/self.ReticleTable.hdivider
				self.ReticleTable.h = iScreenHeight/self.ReticleTable.hdivider

				self.FilterTable = {}
				self.FilterTable.wdivider = 3.125
				self.FilterTable.hdivider = 1.7579/1.35
				self.FilterTable.x = (iScreenWidth/2)-((iScreenHeight/self.FilterTable.hdivider)/2)
				self.FilterTable.y = (iScreenHeight/2)-((iScreenHeight/self.FilterTable.hdivider)/2)
				self.FilterTable.w = iScreenHeight/self.FilterTable.hdivider
				self.FilterTable.h = iScreenHeight/self.FilterTable.hdivider
			end

			-- Get scope sway offset and rotation angle
			local swayX, swayY, rotationAngle = self:GetScopeSway()

			-- Calculate center points for rotation
			local lensCenterX = self.LensTable.x + self.LensTable.w / 2
			local lensCenterY = self.LensTable.y + self.LensTable.h / 2
			local reticleCenterX = self.ReticleTable.x + self.ReticleTable.w / 2
			local reticleCenterY = self.ReticleTable.y + self.ReticleTable.h / 2

			if self.Secondary.UseACOG then
			-- Draw the FAKE SCOPE THANG (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)

			-- Draw the CHEVRON (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_acogchevron"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the ACOG REFERENCE LINES (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_acogcross"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)
			end

			if self.Secondary.UseMilDot then
			-- Draw the MIL DOT SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_scopesight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseSVD then
			-- Draw the SVD SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_svdsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseParabolic then
			-- Draw the PARABOLIC SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_parabolicsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseElcan then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_elcanreticle"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the ELCAN SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_elcansight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseGreenDuplex then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_nvgilluminatedduplex"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseAimpoint then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/aimpoint"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)

			end

			-- CARBY'S NEW SCOPES

			if self.Secondary.UseVortexAMG then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/vortex_amg"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the ELCAN SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseBurrisMTAC then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/burris_mtac"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the ELCAN SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseRedDotHybrid then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/red_dot_hybrid"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the ELCAN SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseGreenPin then
			-- Draw the RETICLE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/green_pin"))
			surface.DrawTexturedRectRotated(reticleCenterX + swayX, reticleCenterY + swayY, self.ReticleTable.w, self.ReticleTable.h, rotationAngle)

			-- Draw the ELCAN SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/gdcw_elcansight"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)
			end

			if self.Secondary.UseMatador then

			-- Draw the SCOPE (rotated)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetTexture(surface.GetTextureID("scope/rocketscope"))
			surface.DrawTexturedRectRotated(lensCenterX + swayX - 1, lensCenterY + swayY, self.LensTable.w, self.LensTable.h, rotationAngle)

			end

	end

	-- Chamber indicator and fire mode display handled by lua/m9kr/client/m9kr_hud.lua
end

-- ============================================================================
-- Mouse Sensitivity
-- ============================================================================

--[[
	AdjustMouseSensitivity - Reduce mouse sensitivity when scoped
	Called automatically by the engine when the player has this weapon equipped

	Formula: 1 / (ScopeZoom / 2)
	Examples:
	- 4x scope: 1 / (4 / 2) = 1 / 2 = 0.5 (50% sensitivity)
	- 8x scope: 1 / (8 / 2) = 1 / 4 = 0.25 (25% sensitivity)
	- 12x scope: 1 / (12 / 2) = 1 / 6 = 0.166 (16.6% sensitivity)
]]--
function SWEP:AdjustMouseSensitivity()
	if not IsValid(self.Owner) then return 1 end

	-- Reduce sensitivity when scoped in (state managed by UpdateWeaponInputState)
	if self.m9kr_IsInADS then
		return 1 / (self.Secondary.ScopeZoom / 2)
	end

	return 1
end
