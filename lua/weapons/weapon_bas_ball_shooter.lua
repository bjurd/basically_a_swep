DEFINE_BASECLASS("weapon_bas_shooter_base")

SWEP.Base = "weapon_bas_shooter_base"
SWEP.PrintName = "Ball Shooter"

SWEP.Category = "Basically Some SWEPs"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3

SWEP.ViewModel = Model("models/weapons/c_shotgun.mdl")
SWEP.WorldModel = Model("models/weapons/w_shotgun.mdl")

SWEP.Primary = BAS.Util.SetupAmmoTable({
	Ammo = "Buckshot",
	ClipSize = 5,
	DefaultClip = 5,

	ViewPunch = Vector(1, 1),

	BulletSpread = Vector(16, 16),
	BulletCount = 3,
	FireInterval = 0.25,

	UsesAmmo = true,
	Enabled = true,

	Sound = ")weapons/shotgun/shotgun_fire7.wav"
})

function SWEP:OnInitialized()
	self:SetHoldType("shotgun")
end

if SERVER then
	function SWEP:OwnerCanSpawnItem()
		return hook.Run("PlayerSpawnSENT", self:GetOwner(), "sent_ball")
	end

	function SWEP:RunItemSpawnTrace(BulletData, BulletIndex)
		local TraceResult = BaseClass.RunItemSpawnTrace(self, BulletData, BulletIndex)
		TraceResult.Hit = true -- Force sent_ball's SpawnFunction to run

		return TraceResult
	end

	function SWEP:SpawnItem(ItemIndex, SpawnTrace)
		local sent_ball = scripted_ents.GetStored("sent_ball")
		if not sent_ball then return NULL end

		local SpawnFunction = scripted_ents.GetMember("sent_ball", "SpawnFunction")
		if not SpawnFunction then return NULL end

		return SpawnFunction(sent_ball, self:GetOwner(), SpawnTrace, "sent_ball")
	end

	function SWEP:RegisterSpawnedItem(Item, SpawnTrace)
		local Owner = self:GetOwner()

		undo.Create("SENT")
		undo.SetPlayer(Owner)
		undo.AddEntity(Item)
		undo.SetCustomUndoText("Undone " .. scripted_ents.GetMember("sent_ball", "PrintName"))
		undo.Finish("Scripted Entity (sent_ball)")

		Item:SetCreator(Owner)
		Owner:AddCleanup("sents", Item)
	end

	function SWEP:PostItemSpawned(Item, SpawnTrace)
		local PhysicsObject = Item:GetPhysicsObject()

		if IsValid(PhysicsObject) then
			local Forward = SpawnTrace.Normal
			Forward:Mul(GetConVar("sv_maxvelocity"):GetInt())

			PhysicsObject:SetVelocity(Forward)
		end
	end
end
