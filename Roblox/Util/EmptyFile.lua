for _, v in getgc(true) do
	if typeof(v) == "table" and rawget(v, "Bullets") and rawget(v, "FireModes") and rawget(v, "LimbDamage") and rawget(v, "AmmoInGun") then
		print(v)
		v.AmmoInGun = 500
		v.Ammo = 500
	end
end