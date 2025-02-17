SWEP.Base = "weapon_bas_laser_pistol"
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

	FireSound = "beams/beamstart5.wav"
})

SWEP.Secondary = BAS.Util.SetupAmmoTable({
	Ammo = "SMG1",
	ClipSize = 1,
	DefaultClip = 1,
	Automatic = false,

	ViewPunch = Vector(6, 4),
	AimPunch = Vector(1, 0.75),

	BulletSpread = Vector(0.1, 0.1),
	BulletCount = 1,
	BulletDamage = 70,
	FireInterval = 1.5,

	UsesAmmo = true,
	Enabled = true,

	FireSound = "beams/beamstart5.wav"
})

function SWEP:OnInitialized()
	self:SetHoldType("smg")
end

function SWEP:OnSecondaryAttack()
	self:FireBasicBullets()

	self:TakePrimaryAmmo(1)

	self:ApplyNextFireTime()
	self:ApplyPrimaryFireInterval(self:GetCurrentFireTable().FireInterval)

	self:ApplyViewPunch()
	self:ApplyAimPunch()

	return true
end

function SWEP:PostFireBullets(Data)
	if not Data.Trace.Hit then return end

	local Effect = EffectData()
	do
		Effect:SetOrigin(Data.Trace.HitPos)
		Effect:SetStart(Data.Trace.StartPos)
		Effect:SetAttachment(1)
		Effect:SetEntity(self)
	end
	util.Effect("ToolTracer", Effect)

	if SERVER then
		self:IgniteInArea(Data.Trace.HitPos, self:GetInSecondaryFire() and 100 or 50)
	end
end
