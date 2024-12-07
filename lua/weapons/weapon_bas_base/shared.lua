SWEP.Spawnable = false
SWEP.AdminOnly = true

SWEP.ViewModel = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = Model("models/error.mdl")

SWEP.UseHands = true

SWEP.Primary = BAS.Util.GenerateAmmoTable()
SWEP.Secondary = BAS.Util.GenerateAmmoTable()

-- Extension things
AccessorFunc(SWEP, "m_iReloadAnimation", "ReloadAnimation", FORCE_NUMBER)
AccessorFunc(SWEP, "m_iOwnerReloadAnimation", "OwnerReloadAnimation", FORCE_NUMBER)

AccessorFunc(SWEP, "m_iPrimaryAttackAnimation", "PrimaryAttackAnimation", FORCE_NUMBER)
AccessorFunc(SWEP, "m_iOwnerPrimaryAttackAnimation", "OwnerPrimaryAttackAnimation", FORCE_NUMBER)

AccessorFunc(SWEP, "m_iSecondaryAttackAnimation", "SecondaryAttackAnimation", FORCE_NUMBER)
AccessorFunc(SWEP, "m_iOwnerSecondaryAttackAnimation", "OwnerSecondaryAttackAnimation", FORCE_NUMBER)

-- Hooks
function SWEP:Initialize()
	self:SetReloadAnimation(ACT_VM_RELOAD)
	self:SetOwnerReloadAnimation(PLAYER_RELOAD)

	self:SetPrimaryAttackAnimation(ACT_VM_PRIMARYATTACK)
	self:SetOwnerPrimaryAttackAnimation(PLAYER_ATTACK1)

	self:SetSecondaryAttackAnimation(ACT_VM_SECONDARYATTACK)
	self:SetOwnerSecondaryAttackAnimation(PLAYER_ATTACK1)

	self:OnInitialized()
end

function SWEP:OnInitialized()
	-- For override
end

function SWEP:CanReload()
	if not IsFirstTimePredicted() then return false end

	-- For override

	return true
end

function SWEP:Reload()
	if not self:CanReload() then return end

	local DefaultSuccess = self:DefaultReload(self:GetReloadAnimation())

	if DefaultSuccess then
		self:CallOnOwner("SetAnimation", self:GetOwnerReloadAnimation())
	end

	return self:OnReload(DefaultSuccess)
end

function SWEP:OnReload(DefaultSuccess)
	-- For override
end

function SWEP:CanPrimaryAttack()
	if not IsFirstTimePredicted() then return false end
	if not self.Primary.Enabled then return false end

	if CurTime() < self:GetNextPrimaryFire() then return false end

	if self.Primary.UsesAmmo and (not self:HasAmmo() or self:Clip1() <= 0) then
		self:Reload()

		return false
	end

	return true
end

function SWEP:CanSecondaryAttack()
	if not IsFirstTimePredicted() then return false end
	if not self.Secondary.Enabled then return false end

	if CurTime() < self:GetNextSecondaryFire() then return false end

	local Clip = self:GetPrimaryAmmoType() == self:GetSecondaryAmmoType() and self:Clip1() or self:Clip2()

	if self.Secondary.UsesAmmo and (not self:HasAmmo() or Clip <= 0) then
		return false
	end

	return true
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	if self:OnPrimaryAttack() ~= false then
		self:SendWeaponAnim(self:GetPrimaryAttackAnimation())
		self:CallOnOwner("SetAnimation", self:GetOwnerPrimaryAttackAnimation())
	end
end

function SWEP:SecondaryAttack()
	if not self:CanSecondaryAttack() then return end

	if self:OnSecondaryAttack() ~= false then
		self:SendWeaponAnim(self:GetSecondaryAttackAnimation())
		self:CallOnOwner("SetAnimation", self:GetOwnerSecondaryAttackAnimation())
	end
end

function SWEP:OnPrimaryAttack()
	-- For override
	-- Return false to prevent animations
end

function SWEP:OnSecondaryAttack()
	-- For override
	-- Return false to prevent animations
end

-- Utilities
function SWEP:CallOnOwner(FunctionName, ...)
	local Owner = self:GetOwner()
	if not IsValid(Owner) then return end

	-- Let it error on purpose to alert retardation
	return Owner[FunctionName](Owner, ...)
end

function SWEP:ApplyNextFireTime(IsSecondary)
	if IsSecondary then
		self:SetNextSecondaryFire(CurTime() + self.Secondary.FireRate)
	else
		self:SetNextPrimaryFire(CurTime() + self.Primary.FireRate)
	end
end
