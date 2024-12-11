ENT.PrintName = "Thrown Kniferang"

ENT.Author = "Very Bad Developer"

ENT.Contact = "t.me/very_bad_developer"
ENT.Purpose = "Thrown knife for weapon_bas_kniferang"
ENT.Instructions = "Get weapon_bas_kniferang to use"

ENT.RenderGroup = RENDERGROUP_OPAQUE

AccessorFunc(ENT, "m_nLastSpinFrame", "LastSpinFrame", FORCE_NUMBER) -- Fix being called mulitple times a frame causing faster rotations

include("shared.lua")

function ENT:Draw(Flags)
	if bit.band(Flags, STUDIO_RENDER) ~= STUDIO_RENDER then return end

	local FrameNumber = FrameNumber()

	if self:GetLastSpinFrame() ~= FrameNumber then
		local AngleDelta = 720 * FrameTime()

		local RenderAngles = self:GetRenderAngles() or self:GetAngles()
		RenderAngles.pitch = 90
		RenderAngles.yaw = math.NormalizeAngle(RenderAngles.yaw + AngleDelta)

		self:SetRenderAngles(RenderAngles)

		self:SetLastSpinFrame(FrameNumber)
	end

	self:DrawModel()
end

function ENT:DrawTranslucent()
	return
end
