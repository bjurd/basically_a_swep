SWEP.PrintName = "Basically A SWEP"
SWEP.Category = "Basically Some SWEPs"

SWEP.Author = "Very Bad Developer"

SWEP.Contact = "t.me/very_bad_developer"
SWEP.Purpose = "Basically a weapon that shoots and is scripted\n" -- Newlines for spacing in the instruction box
SWEP.Instructions = "Primary attack (left click) to attack\nSecondary attack (right click) to secondarily attack\n"

include("shared.lua")

function SWEP:CalcViewModelView() -- Fix FOV issues
	self.ViewModelFOV = GetConVar("viewmodel_fov"):GetInt()
end
