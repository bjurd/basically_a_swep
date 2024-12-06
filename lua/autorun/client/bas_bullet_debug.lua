if util.NetworkStringToID("bas_bullet_debug") <= 0 then return end

local color_red = Color(255, 0, 0, 255) -- Client bullets
local color_blue = Color(0, 0, 255, 255) -- Server bullets

local BulletDebug = CreateClientConVar("bas_bullet_debug", 0, true, false, "Whether or not to show bullet debug", 0, 1)
local BulletLifetime = CreateClientConVar("bas_bullet_lifetime", 5, true, false, "How long should bullet debug visuals last, in seconds", 0, 60)

local BulletMins = Vector(-2, -2, -2)
local BulletMaxs = Vector(2, 2, 2)

local BulletBoxMaterial = CreateMaterial("BulletBoxMaterial", "UnlitGeneric", { -- The default color material doesn't support alpha
	["$basetexture"] = "color/white",
	["$model"] = 1,
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1,
	["$alpha"] = 0.5
})

local Bullets = {}

local function ReceiveServerBullets()
	local Length = net.ReadUInt(15)
	local Data = net.ReadData(Length)

	local Decompressed = util.Decompress(Data)
	local Decoded = util.Base64Decode(Decompressed)
	local ReceivedBullets = util.JSONToTable(Decoded)

	for BulletIndex = 1, #ReceivedBullets do
		ReceivedBullets[BulletIndex][3] = color_blue -- Mark them as server
		ReceivedBullets[BulletIndex][4] = CurTime() -- Give them life!

		table.insert(Bullets, ReceivedBullets[BulletIndex])
	end
end

local function RenderBullets(Depth, Skybox, Skybox3D)
	if #Bullets < 1 then return end
	if Depth or Skybox or Skybox3D then return end

	local CurrentTime = CurTime()
	local BulletLifetime = BulletLifetime:GetFloat()

	render.SetMaterial(BulletBoxMaterial)

	for BulletIndex = #Bullets, 1, -1 do
		local Bullet = Bullets[BulletIndex]

		render.DrawLine(Bullet[1], Bullet[2], Bullet[3], false)
		render.DrawBox(Bullet[2], angle_zero, BulletMins, BulletMaxs, Bullet[3])

		-- Kill old
		if CurrentTime - Bullet[4] >= BulletLifetime then
			table.remove(Bullets, BulletIndex)
			continue
		end
	end
end

local function AddClientsideBullet(Entity, Data)
	if not IsFirstTimePredicted() then return end
	if not Entity.GetActiveWeapon then return end

	if not IsValid(Entity:GetActiveWeapon()) then return end
	if not weapons.IsBasedOn(Entity:GetActiveWeapon():GetClass(), "weapon_bas_base") then return end

	if not Data.Trace.Hit then return end -- Should never happen

	table.insert(Bullets, { Data.Trace.StartPos, Data.Trace.HitPos, color_red, CurTime() })
end

cvars.AddChangeCallback("bas_bullet_debug", function(_, _, ShouldDebug)
	ShouldDebug = tobool(ShouldDebug)

	if ShouldDebug then
		net.Receive("bas_bullet_debug", ReceiveServerBullets)

		hook.Add("PostDrawTranslucentRenderables", "bas_bullet_debug", RenderBullets)
		hook.Add("PostEntityFireBullets", "bas_bullet_debug", AddClientsideBullet)
	else
		net.Receive("bas_bullet_debug", nil)

		hook.Remove("PostDrawTranslucentRenderables", "bas_bullet_debug")
		hook.Remove("PostEntityFireBullets", "bas_bullet_debug")
	end
end, "DisableHooks")

-- Force the callback to run to properly enable/disable
BulletDebug:SetBool(not BulletDebug:GetBool())
BulletDebug:SetBool(not BulletDebug:GetBool())
