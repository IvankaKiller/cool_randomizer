SWEP.PrintName = "GOLOS IZ BEZDNI"
SWEP.Author = "VANYA - HRANITEL TMINI"
SWEP.Category = "Vaniny pushki"
SWEP.Instructions = "LKM = Shepot tmi | PKM = Portal | V KONSOLI: world_end"

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/v_eq_smokegrenade.mdl"
SWEP.WorldModel = "models/weapons/w_eq_flashbang.mdl"
SWEP.Spawnable = true

if CLIENT then
	SWEP.IconOverride = "cool_randomizer/png/broin.png"
	SWEP.WepSelectIcon = surface.GetTextureID("cool_randomizer/vtf/broin")
end

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "Pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

local whisperSounds = {
    "ambient/voices/cough1.wav",
    "ambient/voices/cough2.wav",
    "ambient/voices/cough3.wav",
    "ambient/voices/cough4.wav",
    "ambient/creatures/town_scary1.wav",
    "ambient/creatures/town_scary3.wav",
    "npc/fast_zombie/scare.wav"
}

function SWEP:Initialize()
    print("TY USLISHAL GOLOS... ON ZOVET TEBYA...")
end

function SWEP:Reload() return false end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 1)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    
    local sound = whisperSounds[math.random(1, #whisperSounds)]
    self.Owner:EmitSound(sound, 70, math.random(80, 120))
    
    local rand = math.random(1, 5)
    
    if rand == 1 then
        self.Owner:SetFOV(20, 0.3)
        timer.Simple(2, function()
            if IsValid(self.Owner) then self.Owner:SetFOV(90, 0.5) end
        end)
        self.Owner:PrintMessage(HUD_PRINTTALK, "TY VIDISH TO, CHEGO NE DOLZHEN...")
        
    elseif rand == 2 then
        self.Owner:SetGravity(0.4)
        timer.Simple(3, function()
            if IsValid(self.Owner) then self.Owner:SetGravity(1) end
        end)
        self.Owner:PrintMessage(HUD_PRINTTALK, "ZEMLYA UHODIT IZ-POD NOG...")
        
    elseif rand == 3 then
        self.Owner:SetColor(Color(100, 100, 150, 255))
        timer.Simple(4, function()
            if IsValid(self.Owner) then self.Owner:SetColor(Color(255, 255, 255, 255)) end
        end)
        self.Owner:PrintMessage(HUD_PRINTTALK, "TVOYA KROV STINET...")
        
    elseif rand == 4 then
        for _, ply in ipairs(player.GetAll()) do
            if ply ~= self.Owner then
                ply:EmitSound("npc/zombie/zombie_voice_idle1.wav", 100, 50)
                ply:PrintMessage(HUD_PRINTTALK, "KTO-TO SHEPCHET TEBE V UHO...")
            end
        end
    else
        self.Owner:PrintMessage(HUD_PRINTTALK, "MIR STANOVITSYA TYOMNUM...")
    end
end

function SWEP:SecondaryAttack()
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:EmitSound("ambient/levels/citadel/strange_talk1.wav")
    
    if SERVER then
        for i = 1, 50 do
            timer.Simple(i * 0.05, function()
                if not IsValid(self.Owner) then return end
                
                local pos = self.Owner:GetPos() + Vector(
                    math.random(-800, 800),
                    math.random(-800, 800),
                    math.random(0, 200)
                )
                
                if i % 3 == 0 then
                    local zombie = ents.Create("npc_fastzombie")
                    if IsValid(zombie) then
                        zombie:SetPos(pos)
                        zombie:Spawn()
                        zombie:SetHealth(50)
                    end
                elseif i % 5 == 0 then
                    local headcrab = ents.Create("npc_headcrab")
                    if IsValid(headcrab) then
                        headcrab:SetPos(pos)
                        headcrab:Spawn()
                    end
                end
            end)
        end
        
        self.Owner:PrintMessage(HUD_PRINTTALK, "PORTAL OTKRYT... ONI IDUT...")
    end
end

function TheQuietApocalypse(ply)
    if not IsValid(ply) then return end
    
    ply:PrintMessage(HUD_PRINTTALK, "...ON PROSNULSYA...")
    ply:EmitSound("npc/strider/strider_roar1.wav", 100, 30)
    
    for i = 1, 10 do
        timer.Simple(i * 0.5, function()
            for _, p in ipairs(player.GetAll()) do
                if IsValid(p) then
                    p:SetFOV(math.random(10, 120), 0.1)
                    p:EmitSound("ambient/voices/cough" .. math.random(1,4) .. ".wav", 80, math.random(40, 80))
                end
            end
        end)
    end
    
    timer.Simple(3, function()
        for _, p in ipairs(player.GetAll()) do
            p:PrintMessage(HUD_PRINTTALK, "NEBO ISCHEZAET... OSTAYOTSYA TOLKO TMA...")
        end
    end)
    
    timer.Simple(5, function()
        local players = {}
        for _, p in ipairs(player.GetAll()) do
            table.insert(players, p)
        end
        
        for i = 1, #players do
            local p1 = players[i]
            local p2 = players[#players - i + 1]
            if IsValid(p1) and IsValid(p2) and p1 ~= p2 then
                local pos1 = p1:GetPos()
                p1:SetPos(p2:GetPos())
                p2:SetPos(pos1)
            end
        end
        
        for _, p in ipairs(player.GetAll()) do
            p:PrintMessage(HUD_PRINTTALK, "MIR PEREVERNULSYA... TY NE ZNAYESH, GDE TY...")
            p:EmitSound("ambient/creatures/town_scary1.wav")
        end
    end)
    
    timer.Simple(7, function()
        for i = 1, 300 do
            timer.Simple(i * 0.03, function()
                if IsValid(ply) then
                    local types = {"npc_zombie", "npc_fastzombie", "npc_poisonzombie", "npc_headcrab", "npc_fastheadcrab"}
                    local monster = ents.Create(types[math.random(1, #types)])
                    if IsValid(monster) then
                        monster:SetPos(Vector(
                            math.random(-8000, 8000),
                            math.random(-8000, 8000),
                            math.random(0, 100)
                        ))
                        monster:Spawn()
                        monster:SetColor(Color(50, 50, 50, 255))
                    end
                end
            end)
        end
        for _, p in ipairs(player.GetAll()) do
            p:PrintMessage(HUD_PRINTTALK, "ONI VYHODYAT IZ ZEMLI... ONI VEZDE...")
        end
    end)
    
    timer.Simple(10, function()
        for i = 1, 500 do
            timer.Simple(i * 0.01, function()
                if IsValid(ply) then
                    local blood = ents.Create("env_blood")
                    if IsValid(blood) then
                        blood:SetPos(Vector(
                            math.random(-10000, 10000),
                            math.random(-10000, 10000),
                            math.random(500, 1500)
                        ))
                        blood:Spawn()
                        blood:Fire("EmitBlood", "", 0)
                    end
                end
            end)
        end
        
        for _, p in ipairs(player.GetAll()) do
            p:PrintMessage(HUD_PRINTTALK, "NEBO PLACHET KROVYU... ONO SKORBIT...")
            p:SetColor(Color(150, 50, 50, 255))
        end
    end)
    
    timer.Simple(13, function()
        for i = 1, 50 do
            timer.Simple(i * 0.2, function()
                for _, p in ipairs(player.GetAll()) do
                    if IsValid(p) then
                        p:EmitSound(whisperSounds[math.random(1, #whisperSounds)], 50, math.random(30, 60))
                    end
                end
            end)
        end
        
        for _, p in ipairs(player.GetAll()) do
            p:PrintMessage(HUD_PRINTTALK, "GOLOSA SHEPCHUT TVOYO IMYA... ONI ZNAYUT TEBYA...")
            p:SetFOV(30, 0.5)
        end
    end)
    
    timer.Simple(16, function()
        for _, p in ipairs(player.GetAll()) do
            p:SetFOV(10, 0.2)
            p:PrintMessage(HUD_PRINTTALK, "SVET UMIRAYET... TEPER TY VECHNO VO TME...")
            p:PrintMessage(HUD_PRINTTALK, "END OF THE WORLD")
            p:Kill()
        end
    end)
end

concommand.Add("world_end", function(ply)
    if IsValid(ply) then
        TheQuietApocalypse(ply)
    end
end)