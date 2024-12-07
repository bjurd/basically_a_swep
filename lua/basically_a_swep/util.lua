AddCSLuaFile()

BAS.Util = BAS.Util or {}
local BAS_Util = BAS.Util

BAS_Util.TraceOutput = {}
BAS_Util.TraceData = { output = BAS_Util.TraceOutput }

-- These can't be in SWEP because they have to exist before the baseclass does
function BAS_Util.GenerateAmmoTable()
	return table.Copy(BAS.Config.DefaultAmmoTable)
end

function BAS_Util.SetupAmmoTable(Data)
	return table.Merge(BAS_Util.GenerateAmmoTable(), Data)
end

function BAS_Util.ResetTrace()
	BAS_Util.TraceData.start = nil
	BAS_Util.TraceData.endpos = nil
	BAS_Util.TraceData.filter = nil
	BAS_Util.TraceData.mask = MASK_SOLID
	BAS_Util.TraceData.collisiongroup = COLLISION_GROUP_NONE
	BAS_Util.TraceData.ignoreworld = false
	BAS_Util.TraceData.output = BAS_Util.TraceOutput
	BAS_Util.TraceData.whitelist = false

	if CLIENT then
		BAS_Util.TraceData.hitclientonly = false
	end

	return BAS_Util.TraceData
end

function BAS_Util.RunTrace()
	util.TraceLine(BAS_Util.TraceData)

	return BAS_Util.TraceOutput
end

function BAS_Util.GetTimeSeed() -- :fire:
	return SysTime() + CurTime() + UnPredictedCurTime() + os.time()
end

function BAS_Util.NormalizeAngle(Angle)
	Angle.pitch = math.Clamp(math.NormalizeAngle(Angle.pitch), -89, 89)
	Angle.yaw = math.NormalizeAngle(Angle.yaw)
	Angle.roll = math.NormalizeAngle(Angle.roll)
end

function BAS_Util.EitherCoinFlip(A, B)
	return BAS.minstd:RandomFloat() >= 0.5 and A or B
end
