SWEP.Base = "weapon_bas_ball_shooter"
SWEP.PrintName = "Admin Ball Shooter"

SWEP.Category = "Basically Some SWEPs"
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.Primary = BAS.Util.SetupAmmoTable({
	Ammo = "Buckshot",
	ClipSize = 100,
	DefaultClip = 100,
	Automatic = true,

	BulletSpread = Vector(16, 16),
	BulletCount = 10,
	FireInterval = 0.1,

	UsesAmmo = true,
	Enabled = true,

	Sound = ")weapons/shotgun/shotgun_fire7.wav"
})

if SERVER then
	function SWEP:OwnerCanSpawnItem()
		return self:GetOwner():IsAdmin()
	end
end
