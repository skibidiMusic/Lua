for _, v in getgc(true) do
	if typeof(v) == "table" and rawget(v, "Bullets") and rawget(v, "FireModes") and rawget(v, "LimbDamage") and rawget(v, "AmmoInGun") then
		print(v)
		v.AmmoInGun = 500
		v.Ammo = 500
		v.RainbowMode = true
		v.ShootRate = 5000
		v.ExplosiveAmmo = true
		v.ExplosionRadius = 500
	end
end