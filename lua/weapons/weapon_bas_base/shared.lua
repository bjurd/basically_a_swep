SWEP.Spawnable = false
SWEP.AdminOnly = true

SWEP.ViewModel = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = Model("models/error.mdl")

SWEP.UseHands = true

SWEP.ReloadSound = ""

SWEP.Primary = BAS.Util.GenerateAmmoTable()
SWEP.Secondary = BAS.Util.GenerateAmmoTable()

-- Extension things
AccessorFunc(SWEP, "m_iReloadAnimation", "ReloadAnimation", FORCE_NUMBER)
AccessorFunc(SWEP, "m_iOwnerReloadAnimation", "OwnerReloadAnimation", FORCE_NUMBER)

AccessorFunc(SWEP, "m_iPrimaryAttackAnimation", "PrimaryAttackAnimation", FORCE_NUMBER)
AccessorFunc(SWEP, "m_iOwnerPrimaryAttackAnimation", "OwnerPrimaryAttackAnimation", FORCE_NUMBER)

AccessorFunc(SWEP, "m_iSecondaryAttackAnimation", "SecondaryAttackAnimation", FORCE_NUMBER)
AccessorFunc(SWEP, "m_iOwnerSecondaryAttackAnimation", "OwnerSecondaryAttackAnimation", FORCE_NUMBER)

AccessorFunc(SWEP, "m_bInPrimaryFire", "InPrimaryFire", FORCE_BOOL)
AccessorFunc(SWEP, "m_bInSecondaryFire", "InSecondaryFire", FORCE_BOOL)

AccessorFunc(SWEP, "m_iRandomSeed", "RandomSeed", FORCE_NUMBER)

-- Hooks
function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "ReloadFinishTime")
end

function SWEP:Precache()
	util.PrecacheSound(self.ReloadSound or "")

	util.PrecacheSound(self.Primary.Sound or "")
	util.PrecacheSound(self.Secondary.Sound or "")

	util.PrecacheModel(self.ViewModel)
	util.PrecacheModel(self.WorldModel)
end

function SWEP:Initialize()
	self:Precache()

	self:SetReloadAnimation(ACT_VM_RELOAD)
	self:SetOwnerReloadAnimation(PLAYER_RELOAD)

	self:SetPrimaryAttackAnimation(ACT_VM_PRIMARYATTACK)
	self:SetOwnerPrimaryAttackAnimation(PLAYER_ATTACK1)

	self:SetSecondaryAttackAnimation(ACT_VM_SECONDARYATTACK)
	self:SetOwnerSecondaryAttackAnimation(PLAYER_ATTACK1)

	self:SetRandomSeed(BAS.minstd:RandomInt(10000, 9999999)) -- RandomInt returning floats wtflip

	hook.Add("PostEntityFireBullets", self, function(self, Entity, Data)
		if Entity ~= self:GetOwner() then return end
		if Entity:GetActiveWeapon() ~= self then return end

		self:PostFireBullets(Data)
	end)

	self:OnInitialized()
end

function SWEP:OnInitialized()
	-- For override
end

function SWEP:CanReload()
	if CurTime() < self:GetReloadFinishTime() then return false end

	-- For override

	return true
end

function SWEP:Reload()
	if not self:CanReload() then return end

	local DefaultSuccess = self:DefaultReload(self:GetReloadAnimation())

	if DefaultSuccess then
		self:EmitSound(self.ReloadSound)
		self:SetReloadFinishTime(CurTime() + self:SequenceDuration(self:GetReloadAnimation()))

		self:CallOnOwner("SetAnimation", self:GetOwnerReloadAnimation())
	else
		self:SetReloadFinishTime(0)
	end

	return self:OnReload(DefaultSuccess)
end

function SWEP:OnReload(DefaultSuccess)
	-- For override
end

function SWEP:CanPrimaryAttack()
	if CurTime() < self:GetReloadFinishTime() then return false end -- Reload animation playing
	if not self.Primary.Enabled then return false end

	if CurTime() < self:GetNextPrimaryFire() then return false end

	if self.Primary.UsesAmmo and (not self:HasAmmo() or self:Clip1() <= 0) then
		self:Reload()

		return false
	end

	return true
end

function SWEP:CanSecondaryAttack()
	if CurTime() < self:GetReloadFinishTime() then return false end -- Reload animation playing
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

	self:SetInPrimaryFire(true)
	do
		local _, BlockAnimations = xpcall(self.OnPrimaryAttack, ErrorNoHaltWithStack, self)

		if BlockAnimations ~= false then
			self:SendWeaponAnim(self:GetPrimaryAttackAnimation())

			self:CallOnOwner("MuzzleFlash")
			self:CallOnOwner("SetAnimation", self:GetOwnerPrimaryAttackAnimation())

			self:EmitSound(self.Primary.Sound)
		end
	end
	self:SetInPrimaryFire(false)
end

function SWEP:SecondaryAttack()
	if not self:CanSecondaryAttack() then return end

	self:SetInSecondaryFire(true)
	do
		local _, BlockAnimations = xpcall(self.OnSecondaryAttack, ErrorNoHaltWithStack, self)

		if BlockAnimations ~= false then
			self:SendWeaponAnim(self:GetSecondaryAttackAnimation())

			self:CallOnOwner("MuzzleFlash")
			self:CallOnOwner("SetAnimation", self:GetOwnerSecondaryAttackAnimation())

			self:EmitSound(self.Secondary.Sound)
		end
	end
	self:SetInSecondaryFire(false)
end

function SWEP:OnPrimaryAttack()
	-- For override
	-- Return false to prevent animations, muzzle flash and sounds
end

function SWEP:OnSecondaryAttack()
	-- For override
	-- Return false to prevent animations, muzzle flash and sounds
end

function SWEP:PostFireBullets()
	-- For override
end

-- Utilities
function SWEP:CallOnOwner(FunctionName, ...)
	local Owner = self:GetOwner()
	if not IsValid(Owner) then return end

	-- Let it error on purpose to alert retardation
	return Owner[FunctionName](Owner, ...)
end

function SWEP:EitherFireMode(Primary, Secondary, Fallback)
	if self:GetInPrimaryFire() then return Primary end
	if self:GetInSecondaryFire() then return Secondary end

	return Fallback
end

function SWEP:GetCurrentFireTable()
	local FireTable = self:EitherFireMode(self.Primary, self.Secondary)
	assert(FireTable, "Tried to do fire operation outside of fire!")

	return FireTable
end

function SWEP:ApplyNextFireTime()
	local FireTable = self:GetCurrentFireTable()
	assert(FireTable, "Tried to ApplyNextFireTime outside of fire!")

	local ApplyFunction = self:EitherFireMode(self.SetNextPrimaryFire, self.SetNextSecondaryFire)
	assert(ApplyFunction, "Tried to ApplyNextFireTime outside of fire!")

	ApplyFunction(self, CurTime() + FireTable.FireInterval)
end

function SWEP:ApplyViewPunch()
	local Owner = self:GetOwner()
	if not Owner:IsPlayer() then return end -- Don't call on invalid owner kthx

	local PunchCone = self:GetCurrentFireTable().ViewPunch
	if PunchCone:IsZero() then return end

	local VeritcalPunch = math.Rand(-math.abs(PunchCone.x), 0)
	if PunchCone.x < 0 then VeritcalPunch = -VeritcalPunch end

	local HorizontalPunch = math.Rand(-PunchCone.y, PunchCone.y)

	Owner:ViewPunch(Angle(VeritcalPunch, HorizontalPunch))
end

function SWEP:ApplyAimPunch()
	local PunchCone = self:GetCurrentFireTable().AimPunch
	if PunchCone:IsZero() then return end

	local Owner = self:GetOwner()

	local VeritcalPunch = math.Rand(-PunchCone.x, PunchCone.x)
	local HorizontalPunch = math.Rand(-PunchCone.y, PunchCone.y)

	local EyeAngles = Owner:EyeAngles()

	EyeAngles.pitch = math.Clamp(math.NormalizeAngle(EyeAngles.pitch + VeritcalPunch), -89, 89) -- TODO: Use cl_pitchdown and cl_pitchup?
	EyeAngles.yaw = math.NormalizeAngle(EyeAngles.yaw + HorizontalPunch)

	if Owner:IsPlayer() then
		Owner:SetEyeAngles(EyeAngles)
	else
		Owner:SetAngles(EyeAngles)
	end
end

function SWEP:GenerateBullet(Output, BulletIndex)
	BulletIndex = tonumber(BulletIndex) or 1

	local FireTable = self:GetCurrentFireTable()
	local Owner = self:GetOwner()

	Output = Output or {}

	Output.Attacker = Owner
	Output.IgnoreEntity = Owner

	Output.Src = Owner:EyePos()
	Output.Dir = Owner:EyeAngles():Forward()
	Output.Spread = self:CalculateBulletSpread(BulletIndex)

	Output.AmmoType = FireTable.Ammo
	Output.Damage = FireTable.BulletDamage
	Output.Distance = FireTable.BulletDistance
	Output.Force = 0
	Output.HullSize = 0
	Output.Num = 1
	Output.Tracer = 1

	return Output
end

function SWEP:RunTrace(StartPos, EndPos)
	local TraceData = BAS.Util.ResetTrace()

	TraceData.start = StartPos
	TraceData.endpos = EndPos
	TraceData.filter = { self, self:GetOwner() }

	return BAS.Util.RunTrace()
end

function SWEP:CalculateBulletSpread(Offset)
	Offset = tonumber(Offset) or 0

	local FireTable = self:GetCurrentFireTable()
	local Spread = Vector(FireTable.BulletSpread)

	math.randomseed(self:GetRandomSeed() + Offset)

	Spread.x = math.Rand(0, Spread.x)
	Spread.y = math.Rand(0, Spread.y)

	return Spread
end

function SWEP:FireBasicBullets()
	if not IsFirstTimePredicted() then return end

	local Owner = self:GetOwner()
	assert(IsValid(Owner), "Tried to FireBasicBullets with invalid owner!")

	local FireTable = self:GetCurrentFireTable()

	if Owner:IsPlayer() then
		Owner:LagCompensation(true)
	end
	do
		local BulletData = {}

		for BulletIndex = 1, FireTable.BulletCount do
			self:GenerateBullet(BulletData, BulletIndex)

			Owner:FireBullets(BulletData)
		end
	end
	if Owner:IsPlayer() then
		Owner:LagCompensation(false)
	end
end
