ENT.Type = "anim"

ENT.AdminOnly = true

ENT.TravelDistance = 500 -- How far to travel before turning around
ENT.TravelDistanceSqr = ENT.TravelDistance * ENT.TravelDistance

ENT.TravelLifetime = 3 -- How long to travel before removal

ENT.WallHitSound = "weapons/knife/knife_hitwall1.wav"
ENT.EntityHitSounds = {
	"weapons/knife/knife_hit1.wav",
	"weapons/knife/knife_hit2.wav",
	"weapons/knife/knife_hit3.wav",
	"weapons/knife/knife_hit4.wav"
}

AccessorFunc(ENT, "m_flTickInterval", "TickInterval", FORCE_NUMBER)
AccessorFunc(ENT, "m_vecThrowOrigin", "ThrowOrigin", FORCE_VECTOR)

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "HitSomething")
end

function ENT:Initialize()
	self:SetTickInterval(engine.TickInterval())
	self:SetThrowOrigin(self:GetPos())

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self:SetMoveType(MOVETYPE_FLY)
	self:SetSolid(SOLID_BBOX)

	-- Why doesn't this exist by default :c
	hook.Add("Tick", self, self.Tick)

	self:CallOnRemove("ReturnKniferang", self.ReturnKniferang)
end

function ENT:TurnAround()
	local Forward = self:GetAngles()
	Forward:RotateAroundAxis(Forward:Up(), 180)

	self:SetAngles(Forward)
end

function ENT:CheckCreationTime()
	if CLIENT then return false end

	-- If the distance checks fuck up then fallback to time
	if CurTime() - self:GetCreationTime() >= self.TravelLifetime then
		self:Remove()
		return true
	end

	return false
end

function ENT:TraceMove()
	local StartPos = self:GetPos()
	local EndPos = Vector(StartPos)

	local Forward = self:GetForward()
	Forward:Mul(1000 * self:GetTickInterval())
	EndPos:Add(Forward)

	local TraceData = BAS.Util.ResetTrace()

	TraceData.start = StartPos
	TraceData.endpos = EndPos

	if self:GetHitSomething() then
		-- Come back no matter what
		TraceData.mask = 0
	else
		TraceData.filter = self
	end

	return BAS.Util.RunTrace()
end

function ENT:OnHitEntity(TraceResult)
	self:SetHitSomething(true)
	self:TurnAround()

	if SERVER then
		local HitEntity = TraceResult.Entity

		if IsValid(HitEntity) then
			local ThrowerWeapon = self:GetNW2Entity("m_ThrowerWeapon")
			local Thrower = IsValid(ThrowerWeapon) and ThrowerWeapon:GetOwner() or NULL

			local DamageInfo = DamageInfo()
			do
				DamageInfo:SetDamage(80)
				DamageInfo:SetAttacker(Thrower)
				DamageInfo:SetInflictor(self)
				DamageInfo:SetDamageType(DMG_SLASH)
				DamageInfo:SetDamageForce(self:GetForward() * -10000)
			end
			HitEntity:TakeDamageInfo(DamageInfo)

			if HitEntity:IsPlayer() or HitEntity:IsNPC() then
				local HitSound = self.EntityHitSounds[math.random(1, #self.EntityHitSounds)]

				self:EmitSound(HitSound)
			else
				self:EmitSound(self.WallHitSound)
			end
		elseif TraceResult.HitWorld then -- Silly that world isn't a valid entity
			self:EmitSound(self.WallHitSound) -- Sometimes this doesn't work because ??????????? I think the sound plays inside the wall
		end
	end
end

function ENT:ReturnKniferang()
	local ThrowerWeapon = self:GetNW2Entity("m_ThrowerWeapon")

	if IsValid(ThrowerWeapon) then
		ThrowerWeapon:SetThrownKniferang(NULL)
	end
end

function ENT:Tick()
	if self:CheckCreationTime() then return end

	local TraceResult = self:TraceMove()
	local TravelDistance =  self:GetPos():DistToSqr(self:GetThrowOrigin())

	-- See if we should turn
	if self:GetHitSomething() then
		-- TODO: This is a bit jank
		if TravelDistance <= 100 or TravelDistance >= self.TravelDistanceSqr then
			if SERVER then
				-- This is like this because the entity removes
				-- before the client finishes animating it all the way back
				SafeRemoveEntityDelayed(self, 0.25)
			end
		end
	else
		if TravelDistance >= self.TravelDistanceSqr then
			TraceResult.Hit = true -- Force a turn around after going far
		end

		if TraceResult.Hit then
			-- Zip back some to prevent getting removed by the distance check above early
			local ThrowOrigin = Vector(self:GetThrowOrigin())
			local ThrowForward = Vector(self:GetForward())

			ThrowForward:Mul(math.sqrt(self.TravelDistanceSqr) * 0.5)
			ThrowOrigin:Add(ThrowForward)

			TraceResult.HitPos:Set(ThrowOrigin)

			-- Bonk
			self:OnHitEntity(TraceResult)
		end
	end

	self:SetPos(TraceResult.HitPos)
end
