DEFINE_BASECLASS("weapon_bas_shooter_base")

SWEP.Base = "weapon_bas_shooter_base"
SWEP.PrintName = "Tide Minion"

SWEP.Category = "Basically Some SWEPs"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 1

SWEP.ViewModel = Model("models/player/kleiner.mdl") -- These are only set because if they're left blank the hooks aren't called
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
	function SWEP:OwnerCanSpawnItem()
		return hook.Run("PlayerSpawnProp", self:GetOwner(), "models/props/de_tides/gate_large.mdl")
	end

	function SWEP:SpawnItem(ItemIndex, SpawnTrace)
		local Tides = ents.Create("prop_physics")
		if not IsValid(Tides) then return NULL end

		Tides:SetModel("models/props/de_tides/gate_large.mdl")
		Tides:SetPos(SpawnTrace.HitPos)
		Tides:SetAngles(SpawnTrace.Normal:Angle())
		Tides:Spawn()

		return Tides
	end

	function SWEP:RegisterSpawnedItem(Item, SpawnTrace)
		local Owner = self:GetOwner()

		undo.Create("Prop")
		undo.SetPlayer(Owner)
		undo.AddEntity(Item)
		undo.Finish("Prop (" .. Item:GetModel() .. ")")

		Item:SetCreator(Owner)
		Owner:AddCleanup("props", Item)
		Item:SetPhysicsAttacker(Owner)

		hook.Run("PlayerSpawnedProp", Owner, Item:GetModel(), Item)
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

if CLIENT then
	AccessorFunc(SWEP, "m_flThrowStartTime", "ThrowStartTime", FORCE_NUMBER)
	AccessorFunc(SWEP, "m_flThrowDuration", "ThrowDuration", FORCE_NUMBER)

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

		MinionModel:InvalidateBoneCache()
		TidesModel:InvalidateBoneCache()

		return MinionModel, TidesModel
	end

	function SWEP:AnimateModel(MinionModel)
		local ThrowStartTime = self:GetThrowStartTime() or 0
		local ThrowDuration = self:GetThrowDuration() or 0

		if ThrowStartTime > 0 then
			local CurrentTime = CurTime()

			if CurrentTime >= ThrowStartTime + ThrowDuration then
				self:SetThrowStartTime(-1) -- Signal reset
			else
				-- Automatic frame advance please :c
				local Cycle = (CurrentTime - ThrowStartTime) / ThrowDuration
				Cycle = math.Clamp(Cycle, 0, 1)

				MinionModel:SetSequence("seq_throw")
				MinionModel:SetCycle(Cycle)
			end
		elseif ThrowStartTime == -1 then
			MinionModel:SetSequence("ACT_HL2MP_IDLE_MELEE")
			MinionModel:SetCycle(0)

			self:SetThrowStartTime(0)
		end
	end

	function SWEP:DrawWorldModel(Flags)
		if bit.band(Flags, STUDIO_RENDER) ~= STUDIO_RENDER then return end

		local MinionModel, TidesModel = self:CreateModels()
		self:AnimateModel(MinionModel)

		-- Make the little fella
		local RenderOrigin, RenderAngles = self:CalculateRenderSetup(self:GetOwner())
		RenderAngles:RotateAroundAxis(RenderAngles:Up(), 90) -- Make him look forward

		local Center = Vector(MinionModel.m_vecCenter)
		Center:Rotate(RenderAngles)
		RenderOrigin:Sub(Center)

		MinionModel:SetRenderOrigin(RenderOrigin)
		MinionModel:SetRenderAngles(RenderAngles)
		MinionModel:DrawModel()

		-- Make his weapon
		RenderOrigin, RenderAngles = self:CalculateRenderSetup(MinionModel)
		RenderAngles:RotateAroundAxis(RenderAngles:Up(), 90)
		RenderAngles:RotateAroundAxis(RenderAngles:Forward(), 90)

		TidesModel:SetRenderOrigin(RenderOrigin)
		TidesModel:SetRenderAngles(RenderAngles)
		TidesModel:DrawModel()
	end

	-- Absolute mess that for some reason shakes with screen shake
	function SWEP:CalculateViewModelPosition(MinionModel, ViewSetup)
		local ViewAngles = self:GetOwner():EyeAngles() -- May look off but prevents the freakout on screen shake
		local ViewDown = ViewAngles:Up()

		local AngleThatGoesIntoForwardToMoveHimRight = Angle(ViewAngles)
		AngleThatGoesIntoForwardToMoveHimRight:RotateAroundAxis(ViewDown, -20) -- Move him to the right

		ViewDown:Mul(20) -- More down

		local Forward = AngleThatGoesIntoForwardToMoveHimRight:Forward()
		Forward:Mul(45)

		local RenderOrigin = Vector(ViewSetup.origin)
		local Center = Vector(MinionModel.m_vecCenter)

		RenderOrigin:Sub(ViewDown) -- Move him down
		RenderOrigin:Add(Forward)

		local RenderAngles = Angle(ViewAngles)
		RenderAngles:RotateAroundAxis(ViewDown, 180)
		RenderAngles:RotateAroundAxis(ViewDown, -1)

		return RenderOrigin, RenderAngles
	end

	function SWEP:PreDrawViewModel()
		local ViewSetup = render.GetViewSetup() -- Put this shit in viewmodel space

		local MinionModel, TidesModel = self:CreateModels()
		self:AnimateModel(MinionModel)

		cam.Start3D(ViewSetup.origin, ViewSetup.angles, ViewSetup.fovviewmodel, ViewSetup.x, ViewSetup.y, ViewSetup.width, ViewSetup.height, ViewSetup.znear, ViewSetup.zfar)
		do
			cam.IgnoreZ(true)
			do
				local RenderOrigin, RenderAngles = self:CalculateViewModelPosition(MinionModel, ViewSetup)

				MinionModel:SetRenderOrigin(RenderOrigin)
				MinionModel:SetRenderAngles(RenderAngles)
				MinionModel:DrawModel()

				RenderOrigin, RenderAngles = self:CalculateRenderSetup(MinionModel)
				RenderAngles:RotateAroundAxis(RenderAngles:Up(), 90)
				RenderAngles:RotateAroundAxis(RenderAngles:Forward(), 90)

				TidesModel:SetRenderOrigin(RenderOrigin)
				TidesModel:SetRenderAngles(RenderAngles)
				TidesModel:DrawModel()
			end
			cam.IgnoreZ(false)
		end
		cam.End3D()

		return true -- Prevent the big Kleiner showing up
	end

	function SWEP:OnPrimaryAttack()
		local Result = BaseClass.OnPrimaryAttack(self)

		if Result ~= false then
			local MinionModel = self:CreateModels()
			local ThrowSequence, ThrowDuration = MinionModel:LookupSequence("seq_throw")

			if ThrowSequence >= 0 then
				self:SetThrowStartTime(CurTime())
				self:SetThrowDuration(ThrowDuration)
			end
		end

		return Result
	end
end
