AddCSLuaFile()

local Config = {}

--[[


	Configuration file for Basically A SWEP

	All the goodies have comments above them explaining what they are


]]

-- Gets set as the "Primary" and "Secondary" in the base SWEP class
Config.DefaultAmmoTable = {
	-- Default stuff, go  read the WiKi for these, https://gmodwiki.com/Structures/SWEP#Primary
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
}

return Config
