AddCSLuaFile()

BAS.Util = BAS.Util or {}
local BAS_Util = BAS.Util

-- These can't be in SWEP because they have to exist before the baseclass does
function BAS_Util.GenerateAmmoTable()
	return table.Copy(BAS.Config.DefaultAmmoTable)
end

function BAS_Util.SetupAmmoTable(Data)
	return table.Merge(BAS_Util.GenerateAmmoTable(), Data)
end
