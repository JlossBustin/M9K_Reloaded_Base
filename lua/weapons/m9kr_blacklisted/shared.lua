--[[
	M9K Reloaded - Blacklisted Weapon Base

	Weapons disabled via their <weaponname>_allowed ConVar get their base
	set to this. The weapon exists in the Lua registry but cannot be
	spawned or used. Replaces external bobs_blacklisted dependency.
]]--

SWEP.Base = "weapon_base"
SWEP.PrintName = "Blacklisted"
SWEP.Author = "M9K Reloaded"
SWEP.Category = ""
SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Weight = 0

function SWEP:Initialize() end
function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end
function SWEP:Think() end
