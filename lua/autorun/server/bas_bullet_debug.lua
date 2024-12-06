if not GetConVar("developer"):GetBool() then return end

local BulletCache = {}

util.AddNetworkString("bas_bullet_debug")

hook.Add("PostEntityFireBullets", "bas_bullet_debug", function(Entity, Data)
	if not Entity.GetActiveWeapon then return end

	if not IsValid(Entity:GetActiveWeapon()) then return end
	if not weapons.IsBasedOn(Entity:GetActiveWeapon():GetClass(), "weapon_bas_base") then return end

	if not Data.Trace.Hit then return end -- Should never happen

	table.insert(BulletCache, { Data.Trace.StartPos, Data.Trace.HitPos })
end)

hook.Add("Tick", "bas_bullet_debug", function()
	if #BulletCache < 1 then return end

	-- Network in bulk every tick instead of every bullet
	local JSON = util.TableToJSON(BulletCache)
	local Encoded = util.Base64Encode(JSON)
	local Compressed = util.Compress(Encoded)
	local Length = string.len(Compressed)

	net.Start("bas_bullet_debug")
		net.WriteUInt(Length, 15)
		net.WriteData(Compressed, Length)
	net.Broadcast()

	-- Better empty
	for BulletIndex = #BulletCache, 1, -1 do
		table.remove(BulletCache, BulletIndex)
	end
end)
