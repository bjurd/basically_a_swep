local developer = GetConVar("developer")

function DevMsg(...)
	if developer:GetBool() then
		Msg(...)
	end
end
