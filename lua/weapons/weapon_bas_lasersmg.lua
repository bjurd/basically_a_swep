SWEP.Base = "weapon_bas_laserpistol"
SWEP.PrintName = "Laser SMG"

SWEP.Category = "Basically Some SWEPs"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 2

SWEP.ViewModel = Model("models/weapons/c_smg1.mdl")
SWEP.WorldModel = Model("models/weapons/w_smg1.mdl")

SWEP.ReloadSound = ")weapons/smg1/smg1_reload.wav"

SWEP.Primary = BAS.Util.SetupAmmoTable({
	Ammo = "SMG1",
	ClipSize = 24,
	DefaultClip = 24,
	Automatic = true,

	ViewPunch = Vector(3, 2),
	AimPunch = Vector(0.75, 0.5),

	BulletSpread = Vector(0.05, 0.05),
	BulletCount = 1,
	BulletDamage = 20,
	FireInterval = 0.2,

	UsesAmmo = true,
	Enabled = true,

	Sound = "npc/vort/attack_shoot.wav"
})

function SWEP:OnInitialized()
	self:SetHoldType("smg")
end
