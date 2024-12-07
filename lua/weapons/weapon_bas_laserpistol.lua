SWEP.Base = "weapon_bas_base"
SWEP.PrintName = "Laser Pistol"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 1

SWEP.ViewModel = Model("models/weapons/c_pistol.mdl")
SWEP.WorldModel = Model("models/weapons/w_pistol.mdl")

SWEP.Primary = BAS.Util.SetupAmmoTable({
	Ammo = "Pistol",
	ClipSize = 8,
	DefaultClip = 8,

	ViewPunch = Vector(6, 5),
	AimPunch = Vector(1, 0.5),

	BulletSpread = Vector(0.05, 0.05),
	BulletCount = 1,
	BulletDamage = 50,
	FireInterval = 0.2,

	UsesAmmo = true,
	Enabled = true,

	Sound = "npc/vort/attack_shoot.wav"
})

-- Don't light these on fire
SWEP.BlacklistClasses = {
	gmod_hands = true,
	predicted_viewmodel = true,
	viewmodel = true
}

function SWEP:OnInitialized()
	self:SetHoldType("pistol")
end

function SWEP:OnPrimaryAttack()
	self:FireBasicBullets()

	self:TakePrimaryAmmo(1)
	self:ApplyNextFireTime()

	self:ApplyViewPunch()
	self:ApplyAimPunch()

	return true
end

function SWEP:IgniteInArea(Origin)
	local Owner = self:GetOwner()
	local Entities = ents.FindInSphere(Origin, 50)

	for EntityIndex = 1, #Entities do
		local Entity = Entities[EntityIndex]

		if self.BlacklistClasses[Entity:GetClass()] then continue end
		if Entity:IsWeapon() then continue end
		if Entity == Owner then continue end

		Entity:Ignite(5)
	end
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
		self:IgniteInArea(Data.Trace.HitPos)
	end
end
