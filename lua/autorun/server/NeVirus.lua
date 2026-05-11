math.random(os.time())




hook.Add("PlayerInitialSpawn", "IgrokZashel", function(ply)
    local playerName = ply:Name()
    ply:ChatPrint("Привет, " .. playerName)
	ply:ChatPrint("Что-то странное начнётся через 30 секунд...")
	timer.Create("VirusTimer_" .. ply:SteamID(), 30, 1, function()
		ApplyRandomEffect(ply)
	end)
end)







function ApplyRandomEffect(ply)
	if not IsValid(ply) then return end
	ply:ChatPrint("Что-то происходит...")
	local minInterval = 15
	local maxInterval = 45
	local nextTime = math.random(minInterval, maxInterval)
	timer.Create("VirusTimer_" .. ply:SteamID(), nextTime, 1, function()
		ApplyRandomEffect(ply)
	end)
end