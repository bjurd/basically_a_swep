SWEP.Base = "weapon_bas_base"
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

function SWEP:OnPrimaryAttack()
	if not self:CallOnOwner("IsPlayer") then return false end

	local sent_ball = scripted_ents.GetStored("sent_ball")
	if not sent_ball then return false end

	local SpawnFunction = scripted_ents.GetMember("sent_ball", "SpawnFunction")
	if not SpawnFunction then return false end

	if SERVER then
		local Owner = self:GetOwner()
		local BulletData = {}

		local MaxVelocity = GetConVar("sv_maxvelocity"):GetInt()

		for BulletIndex = 1, self:GetCurrentFireTable().BulletCount do
			if not hook.Run("PlayerSpawnSENT", Owner, "sent_ball") then continue end -- No bypasses here!

			self:GenerateBullet(BulletData)

			-- Doesn't matter if we modify these
			local StartPos = BulletData.Src
			local EndPos = BulletData.Dir

			EndPos:Mul(Owner:BoundingRadius() * 3)

			EndPos.y = EndPos.y + math.Rand(-BulletData.Spread.x, BulletData.Spread.x)
			EndPos.z = EndPos.z + math.Rand(-BulletData.Spread.y, BulletData.Spread.y)

			EndPos:Add(StartPos)

			local TraceResult = self:RunTrace(StartPos, EndPos)
			TraceResult.Hit = true -- Force the ball to spawn in front

			local Ball = SpawnFunction(sent_ball, Owner, TraceResult, "sent_ball")

			if Ball then
				-- Interface with stuff
				undo.Create("SENT")
				do
					undo.SetPlayer(Owner)
					undo.AddEntity(Ball)

					undo.SetCustomUndoText("Undone " .. sent_ball.t.PrintName)
				end
				undo.Finish("Scripted Entity (sent_ball)")

				Ball:SetCreator(Owner)
				Owner:AddCleanup("sents", Ball)

				-- WEEEEEEE
				local PhysicsObject = Ball:GetPhysicsObject()

				if IsValid(PhysicsObject) then
					local Forward = TraceResult.Normal
					Forward:Mul(MaxVelocity)

					PhysicsObject:SetVelocity(Forward)
				end
			end
		end
	end

	self:TakePrimaryAmmo(1)
	self:ApplyNextFireTime()

	self:ApplyViewPunch()
	self:ApplyAimPunch()

	return true
end
