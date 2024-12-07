AddCSLuaFile()
AddCSLuaFile("minstd/minstd.lua")

BAS = BAS or {}

include("util.lua")

BAS.Config = include("config.lua")

BAS.minstd = include("minstd/minstd.lua")
BAS.minstd:SetSeed(BAS.Util.GetTimeSeed()) -- :fire:
