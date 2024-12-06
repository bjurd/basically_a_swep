function SWEP:SetupAmmo(Key, Data)
	local AmmoData = self[Key]

	if not istable(AmmoData) then
		self[Key] = {}
		AmmoData = self[Key]
	end

	for DataKey, DataValue in next, Data do
		AmmoData[DataKey] = DataValue
	end
end
