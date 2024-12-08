SWEP.Base = "weapon_bas_base"
SWEP.PrintName = "Tide Minion"

SWEP.Category = "Basically Some SWEPs"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 1

SWEP.ViewModel = ""
SWEP.WorldModel = Model("models/player/kleiner.mdl")

SWEP.Primary = BAS.Util.SetupAmmoTable({
	ViewPunch = Vector(6, 5),

	BulletCount = 1,
	FireInterval = 1,

	UsesAmmo = false,
	Enabled = true
})

AccessorFunc(SWEP, "m_MinionModel", "MinionModel")
AccessorFunc(SWEP, "m_TidesModel", "TidesModel")

function SWEP:OnInitialized()
	self:SetHoldType("melee")
end

if SERVER then
	function SWEP:ThrowTides()
		if not self:CallOnOwner("IsPlayer") then return end

		local Owner = self:GetOwner()
		local BulletData = {}

		local MaxVelocity = GetConVar("sv_maxvelocity"):GetInt()

		for BulletIndex = 1, self:GetCurrentFireTable().BulletCount do
			if not hook.Run("PlayerSpawnProp", Owner, "models/props/de_tides/gate_large.mdl") then continue end

			self:GenerateBullet(BulletData)

			local StartPos = BulletData.Src
			local EndPos = BulletData.Dir

			EndPos:Mul(Owner:BoundingRadius() * 3)

			EndPos.y = EndPos.y + math.Rand(-BulletData.Spread.x, BulletData.Spread.x)
			EndPos.z = EndPos.z + math.Rand(-BulletData.Spread.y, BulletData.Spread.y)

			EndPos:Add(StartPos)

			local TraceResult = self:RunTrace(StartPos, EndPos)

			local Tides = ents.Create("prop_physics")
			if not IsValid(Tides) then continue end

			Tides:SetModel("models/props/de_tides/gate_large.mdl")
			Tides:SetPos(TraceResult.HitPos)
			Tides:SetAngles(TraceResult.Normal:Angle())
			Tides:Spawn()

			undo.Create("Prop")
			do
				undo.SetPlayer(Owner)
				undo.AddEntity(Tides)
			end
			undo.Finish("Prop (models/props/de_tides/gate_large.mdl)")

			Tides:SetCreator(Owner)
			Owner:AddCleanup("props", Tides)

			local PhysicsObject = Tides:GetPhysicsObject()

			if IsValid(PhysicsObject) then
				local Forward = TraceResult.Normal
				Forward:Mul(MaxVelocity)

				PhysicsObject:SetVelocity(Forward)
			end
		end
	end
end

function SWEP:OnPrimaryAttack()
	if SERVER then
		self:ThrowTides()
	end

	self:TakePrimaryAmmo(1)
	self:ApplyNextFireTime()

	self:ApplyViewPunch()
	self:ApplyAimPunch()

	return true
end

if CLIENT then
	function SWEP:CalculateRenderSetup(SetupEntity)
		SetupEntity = SetupEntity or self:GetOwner()

		local RenderOrigin = self:GetPos()
		local RenderAngles = self:GetAngles()

		if IsValid(SetupEntity) then
			local RightHand = SetupEntity:LookupAttachment("anim_attachment_RH")

			if RightHand <= 0 then
				-- No fallback attachments right now
				return RenderOrigin, RenderAngles
			end

			local AngPos = SetupEntity:GetAttachment(RightHand)

			RenderOrigin = AngPos.Pos
			RenderAngles = AngPos.Ang
		end

		return RenderOrigin, RenderAngles
	end

	function SWEP:CalculateMinionCenter()
		local MinionModel = self:GetMinionModel()

		local Mins, Maxs = MinionModel:GetModelBounds()
		Mins:Mul(MinionModel:GetModelScale())
		Maxs:Mul(MinionModel:GetModelScale())

		Mins:Add(Maxs) -- Not reusing so fuck 'em
		Mins:Mul(0.5)

		return Mins
	end

	function SWEP:CreateModels()
		local MinionModel = self:GetMinionModel()

		if not IsValid(MinionModel) then
			MinionModel = ClientsideModel(Model("models/player/kleiner.mdl"), RENDERGROUP_OPAQUE)

			if IsValid(MinionModel) then
				self:SetMinionModel(MinionModel)

				MinionModel:SetNoDraw(true)
				MinionModel:SetModelScale(0.25)
				MinionModel:SetSequence("ACT_HL2MP_IDLE_MELEE")

				MinionModel.m_vecCenter = self:CalculateMinionCenter()
			else
				return error("Failed to create minion model!")
			end
		end

		local TidesModel = self:GetTidesModel()

		if not IsValid(TidesModel) then
			TidesModel = ClientsideModel(Model("models/props/de_tides/gate_large.mdl"), RENDERGROUP_OPAQUE)

			if IsValid(TidesModel) then
				self:SetTidesModel(TidesModel)

				TidesModel:SetNoDraw(true)
				TidesModel:SetModelScale(0.05)
			else
				return error("Failed to create tides model!")
			end
		end

		return MinionModel, TidesModel
	end

	function SWEP:DrawWorldModel(Flags)
		if bit.band(Flags, STUDIO_RENDER) ~= STUDIO_RENDER then return end

		local MinionModel, TidesModel = self:CreateModels()

		-- Make the little fella
		local RenderOrigin, RenderAngles = self:CalculateRenderSetup(self:GetOwner())
		RenderAngles:RotateAroundAxis(RenderAngles:Up(), 90) -- Make him look forward

		local Center = Vector(MinionModel.m_vecCenter)
		Center:Rotate(RenderAngles)
		RenderOrigin:Sub(Center)

		MinionModel:SetPos(RenderOrigin)
		MinionModel:SetAngles(RenderAngles)
		MinionModel:DrawModel()

		-- Make his weapon
		RenderOrigin, RenderAngles = self:CalculateRenderSetup(MinionModel)
		RenderAngles:RotateAroundAxis(RenderAngles:Up(), 90)
		RenderAngles:RotateAroundAxis(RenderAngles:Forward(), 90)

		TidesModel:SetPos(RenderOrigin)
		TidesModel:SetAngles(RenderAngles)
		TidesModel:DrawModel()
	end
end
