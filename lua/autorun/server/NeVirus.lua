math.randomseed(os.time())

local scarySounds = {
    "npc/zombie/zombie_pain1.wav",
    "npc/zombie/zombie_pain2.wav", 
    "npc/zombie/zombie_pain3.wav",
    "npc/fast_zombie/scare.wav",
    "npc/headcrab/headcrab_alert1.wav",
    "ambient/creatures/town_scary1.wav",
    "ambient/creatures/town_scary2.wav",
    "ambient/creatures/town_scary3.wav",
    "ambient/levels/canals/headcrab_canister_open1.wav",
    "ambient/alarms/citadel_alert_loop2.wav"
}

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
			local randomSound = scarySounds[math.random(1, #scarySounds)]
			p:EmitSound(randomSound)
		end},
		{name = "ORDA ZOMBIES", func = function(p)
			local pos = p:GetPos()
			local zombies = {"npc_zombie", "npc_fastzombie", "npc_poisonzombie", "npc_headcrab", "npc_fastheadcrab"}
			local zcount = math.random(4, 16)
			for i = 1, zcount do
				local zombieType = zombies[math.random(1, #zombies)]
				local zombies = ents.Create(zombieType)
				if IsValid(zombie) then
					local angle = (i / zcount) math.pi * 2
					local dist = math.random(200,500)
					local x = math.cos(angle) * math.random(150,300)
					local y = math.sin(angle) * math.random(150,300)
					zombie:SetPos(pos + Vector(x,y,0))
					zombie:spawn()
					
				end
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