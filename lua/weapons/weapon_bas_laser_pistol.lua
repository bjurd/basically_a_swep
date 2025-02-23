SWEP.Base = "weapon_bas_base"
SWEP.PrintName = "Laser Pistol"

SWEP.Category = "Basically Some SWEPs"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 1

SWEP.ViewModel = Model("models/weapons/c_pistol.mdl")
SWEP.WorldModel = Model("models/weapons/w_pistol.mdl")

SWEP.ReloadSound = ")weapons/pistol/pistol_reload1.wav"

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

	FireSound = "beams/beamstart5.wav"
})

-- Don't light these on fire
SWEP.BlacklistClasses = {
	gmod_hands = true,
	predicted_viewmodel = true,
	swcs_shield = true,
	vfire = true,
	vfire_ball = true,
	vfire_cluster = true,
	viewmodel = true
}

-- Don't start a fire if these were hit
SWEP.BlockingClasses = {
	swcs_shield = true
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

function SWEP:CanIgnite(Entity, Owner, DamageInfo)
	if not Entity:IsValid() then return true end

	if Entity == Owner then return false end

	if self.BlacklistClasses[Entity:GetClass()] then return false end
	if Entity:IsWeapon() then return false end

	if Entity:IsPlayer() then
		if Entity:HasGodMode() then
			return false
		end

		if hook.Run("PlayerShouldTakeDamage", Entity, Owner) == false then
			return false
		end
	end

	if hook.Run("EntityTakeDamage", Entity, DamageInfo) == true then
		return false
	end

	return self:CanIgnite(Entity:GetParent(), Owner, DamageInfo)
end

function SWEP:IgniteInArea(Origin, Radius)
	local Entities = ents.FindInSphere(Origin, Radius)
	if #Entities < 1 then return end

	local Owner = self:GetOwner()

	local FireTable = self:GetCurrentFireTable()
	local DamageInfo = DamageInfo()
	DamageInfo:SetAmmoType(self:EitherFireMode(self.GetPrimaryAmmoType, self.GetSecondaryAmmoType, self.GetPrimaryAmmoType)(self)) -- Ew
	DamageInfo:SetAttacker(Owner)
	DamageInfo:SetBaseDamage(FireTable.BulletDamage)
	DamageInfo:SetDamage(FireTable.BulletDamage)
	DamageInfo:SetDamageForce(vector_origin)
	DamageInfo:SetDamageType(bit.bor(DMG_BULLET, DMG_BURN))
	DamageInfo:SetInflictor(self)
	DamageInfo:SetReportedPosition(self:GetPos())

	for EntityIndex = 1, #Entities do
		if not self:CanIgnite(Entities[EntityIndex], Owner, DamageInfo) then continue end

		Entities[EntityIndex]:Ignite(5)
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

	if IsValid(Data.Trace.Entity) then
		if self.BlockingClasses[Data.Trace.Entity:GetClass()] then
			return
		end
	end

	if SERVER then
		self:IgniteInArea(Data.Trace.HitPos, 50)
	end
end
