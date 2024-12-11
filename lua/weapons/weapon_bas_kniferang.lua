DEFINE_BASECLASS("weapon_bas_shooter_base")

SWEP.Base = "weapon_bas_shooter_base"
SWEP.PrintName = "Kniferang"

SWEP.Category = "Basically Some SWEPs"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 0

SWEP.ViewModel = Model("models/weapons/v_knife_t.mdl")
SWEP.WorldModel = Model("models/weapons/w_knife_t.mdl")

SWEP.EntityClass = "bas_thrown_kniferang"
SWEP.EntityModel = SWEP.WorldModel

SWEP.DeploySound = "weapons/knife/knife_deploy1.wav"

SWEP.Primary = BAS.Util.SetupAmmoTable({
	ViewPunch = Vector(1, 1),

	BulletCount = 1,
	FireInterval = 0.25,

	UsesAmmo = false,
	Enabled = true,

	FireSound = "weapons/knife/knife_slash1.wav"
})

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Entity", 0, "ThrownKniferang")

	if SERVER then
		self:NetworkVarNotify("ThrownKniferang", self.OnKniferangRemoved)
	end
end

function SWEP:OnInitialized()
	self:SetHoldType("melee")
end

if SERVER then
	function SWEP:OwnerCanSpawnItem()
		return hook.Run("PlayerSpawnSENT", self:GetOwner(), self.EntityClass)
	end

	function SWEP:SpawnItem(ItemIndex, SpawnTrace)
		local Kniferang = ents.Create(self.EntityClass)
		if not IsValid(Kniferang) then return NULL end

		local SpawnPos = SpawnTrace.HitPos
		SpawnPos:Add(SpawnTrace.HitNormal)

		Kniferang:SetModel(self.EntityModel)
		Kniferang:SetPos(SpawnPos)
		Kniferang:SetAngles(SpawnTrace.Normal:Angle())

		Kniferang:Spawn()
		Kniferang:Activate()

		return Kniferang
	end

	function SWEP:RegisterSpawnedItem(Item, SpawnTrace)
		local Owner = self:GetOwner()

		undo.Create("SENT")
		undo.SetPlayer(Owner)
		undo.AddEntity(Item)
		undo.SetCustomUndoText("Undone Thrown Kniferang")
		undo.Finish("Scripted Entity (" .. self.EntityClass .. ")")

		Item:SetCreator(Owner)
		Owner:AddCleanup("sents", Item)

		hook.Run("PlayerSpawnedSENT", Owner, Item)
	end

	function SWEP:PostItemSpawned(Item, SpawnTrace)
		self:SetThrownKniferang(Item)
		Item:SetNW2Entity("m_ThrowerWeapon", self)

		if self:CallOnOwner("IsPlayer") then
			self:GetOwner():GetViewModel():SetNoDraw(true)
		end
	end

	function SWEP:OnKniferangRemoved()
		if self:CallOnOwner("IsPlayer") then
			self:GetOwner():GetViewModel():SetNoDraw(false)
		end
	end
end

function SWEP:CanPrimaryAttack()
	local BaseResult = BaseClass.CanPrimaryAttack(self)
	if not BaseResult then return false end

	if IsValid(self:GetThrownKniferang()) then
		return false
	end

	return true
end
