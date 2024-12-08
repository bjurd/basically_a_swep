SWEP.Base = "weapon_bas_base"

if SERVER then
	function SWEP:OwnerCanSpawnItem()
		-- For override
		return true
	end

	function SWEP:RunItemSpawnTrace(BulletData, BulletIndex)
		if not BulletData then
			BulletData = self:GenerateBullet(nil, BulletIndex)
		end

		local StartPos = BulletData.Src
		local EndPos = BulletData.Dir

		EndPos:Mul(self:GetOwner():BoundingRadius() * 3)

		EndPos.y = EndPos.y + math.Rand(-BulletData.Spread.x, BulletData.Spread.x)
		EndPos.z = EndPos.z + math.Rand(-BulletData.Spread.y, BulletData.Spread.y)

		EndPos:Add(StartPos)

		return self:RunTrace(StartPos, EndPos)
	end

	function SWEP:SpawnItem(ItemIndex, SpawnTrace)
		-- For override
	end

	function SWEP:RegisterSpawnedItem(Item, SpawnTrace)
		-- For override
	end

	function SWEP:PostItemSpawned(Item, SpawnTrace)
		-- For override
	end

	function SWEP:TrySpawnItems()
		local BulletData = {}

		for BulletIndex = 1, self:GetCurrentFireTable().BulletCount do
			if not self:OwnerCanSpawnItem() then continue end

			self:GenerateBullet(BulletData, BulletIndex)

			local SpawnTrace = self:RunItemSpawnTrace(BulletData, BulletIndex)
			local Item = self:SpawnItem(BulletIndex, SpawnTrace)

			if IsValid(Item) then
				self:RegisterSpawnedItem(Item, SpawnTrace)
				self:PostItemSpawned(Item, SpawnTrace)
			end
		end
	end
end

function SWEP:OnPrimaryAttack()
	if SERVER and self:CallOnOwner("IsPlayer") then
		self:TrySpawnItems()
	end

	self:TakePrimaryAmmo(1)
	self:ApplyNextFireTime()

	self:ApplyViewPunch()
	self:ApplyAimPunch()

	return true
end
