SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = ""

SWEP.UseHands = true

-- Extension things
AddCSLuaFile("shared/ammo.lua")
include("shared/ammo.lua")

-- Stuff
SWEP:SetupAmmo("Primary", {
	-- Default stuff
	Ammo = "",
	ClipSize = 1,
	DefaultClip = 0,
	Automatic = false,

	-- View punch ranges up/down left/right
	ViewPunch = Vector(0, 0),

	-- Aim punch ranges up/down left/right
	AimPunch = Vector(0, 0),

	-- How many bullets to fire per shot
	BulletCount = 0,

	-- Bullet spread ranges up/down left/right
	BulletSpread = Vector(0, 0),

	-- Base damage of each bullet
	BulletDamage = 0,

	-- Maximum distance a bullet can travel
	BulletDistance = 56756,

	-- Whether or not this fire type uses ammo
	UsesAmmo = true,

	-- How many seconds between shots,
	FireInterval = 0,

	-- Whether or not this fire type can be used
	Enabled = false,

	-- The sound to play when fired
	Sound = ""
})

SWEP:SetupAmmo("Secondary", {
	Ammo = "",
	ClipSize = 1,
	DefaultClip = 0,
	Automatic = false,

	ViewPunch = Vector(0, 0),
	AimPunch = Vector(0, 0),

	BulletCount = 0,
	BulletSpread = Vector(0, 0),
	BulletDamage = 0,
	BulletDistance = 56756,

	UsesAmmo = true,
	FireInterval = 0,
	Enabled = false,

	Sound = ""
})

-- Hooks
function SWEP:Initialize()

end
