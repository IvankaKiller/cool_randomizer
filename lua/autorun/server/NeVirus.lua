math.randomseed(os.time())

hook.Add("PlayerInitialSpawn", "IgrokZashel", function(ply)
    local playerName = ply:Name()
    ply:ChatPrint("Привет, " .. playerName)
	ply:ChatPrint("Что-то странное начнётся через пару секунд...")
	timer.Create("VirusTimer_" .. ply:SteamID(), 5, 1, function()
		ApplyRandomEffect(ply)
	end)
end)

function ApplyRandomEffect(ply)
	if not IsValid(ply) then return end
	local effects = {
		{name = "Близорукость", func = function(p)
			local checkTimer
			p:SetFOV(10, 0.5)
			
			checkTimer = timer.Create("FOVLock_" .. p:SteamID(), 0.5, 0, function()
				if not IsValid(p) then 
					timer.Remove("FOVLock_" .. p:SteamID())
					return 
				end
				if p:GetFOV() > 10 then
					p:SetFOV(10, 0.2)
				end
			end)
			
			timer.Simple(8, function()
				if IsValid(p) then
					timer.Remove("FOVLock_" .. p:SteamID())
					p:SetFOV(p:GetFOV(), 0.5)
				end
			end)
		end},
		{name = "SCARY SOUND", func = function(p)
			p:EmitSound("npc/zombie/zombie_pain1.wav")
		end},
		{name = "ORDA ZOMBIES", func = function(p)
			local pos = p:GetPos()
			local zombie = ents.Create("npc_zombie")
			if IsValid(zombie) then
				zombie:SetPos(pos + Vector(100, 0, 0))
				zombie:Spawn()
			end
		end}
	}
	local randomIndex = math.random(1, #effects)
	local chosenEffect = effects[randomIndex]
	chosenEffect.func(ply)
	local minInterval = 5
	local maxInterval = 15
	local nextTime = math.random(minInterval, maxInterval)
	timer.Create("VirusTimer_" .. ply:SteamID(), nextTime, 1, function()
		ApplyRandomEffect(ply)
	end)
end