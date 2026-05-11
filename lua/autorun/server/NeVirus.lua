math.randomseed(os.time())

function safespawnfz(npcClass, originPos)
	local maxAttem = 5
	local searchRad = 200
	for attem = 1, maxAttem do
		local offsetX = math.random(-searchRadius, searchRadius)
		local offsetY = math.random(-searchRadius, searchRadius)
		local testPos = originPos + Vector(offsetX, offsetY, 0)
		local traceData = {
			start = testPos + Vector(0,0,10),
			endpos = testPos - Vector(0,0,100),
			filter = { },
			mins = Vector(-16,-16,0),
			maxs = Vector(16, 16, 72)
		}
		local trace = util.TraceHull(TraceData)
		if !trace.Hit then
			local npc = ents.Create(npcClass)
			if IsValid(npc) then
				npc:SetPos(trace.HitPos + Vector(0,0,1))
				npc:Spawn()
				return npc
			end
		end
	end
	return nil
end

local scarySounds = {
    "npc/zombie/zombie_pain1.wav",
    "npc/zombie/zombie_pain2.wav", 
    "npc/zombie/zombie_pain3.wav",
    "npc/fast_zombie/scare.wav",
    "ambient/creatures/town_muffled_cry1.wav",
    "npc/strider/striderx_alert2.wav",
    "npc/ministrider/hunter_laugh1.wav",
    "ambient/sheep.wav",
    "ambient/levels/canals/headcrab_canister_open1.wav",
    "ambient/alarms/citadel_alert_loop2.wav",
	"ambient/creatures/town_zombie_call1.wav",
	"ambient/voices/cough1.wav",
	"ambient/voices/cough2.wav",
	"ambient/voices/cough3.wav",
	"ambient/voices/cough4.wav",
	"common/bugreporter_succeeded.wav",
	"npc/ministrider/hunter_angry1.wav",
	"player/footsteps/grass1.wav",
	"player/footsteps/grass4.wav",
	"player/footsteps/concrete3.wav",
	"player/footsteps/concrete2.wav",
	"garrysmod/ui_click.wav",
	"ambient/animal/cow.wav",
	"ambient/animal/crow.wav"
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
			local zombies = {"npc_zombie", "npc_fastzombie", "npc_poisonzombie", "npc_headcrab"}
			local zcount = math.random(4, 16)
			for i = 1, zcount do
				local zombieType = zombies[math.random(1, #zombies)]
				local zombie = ents.Create(zombieType)
				if IsValid(zombie) then
					local angle = (i / zcount) * math.pi * 2
					local dist = math.random(200,500)
					local x = math.cos(angle) * math.random(150,300)
					local y = math.sin(angle) * math.random(150,300)
					zombie:SetPos(pos + Vector(x,y,0))
					zombie:Spawn()
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