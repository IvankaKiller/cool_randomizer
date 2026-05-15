SWEP.PrintName = "ARMAGEDDON - UNICHTOTITEL MIROV"
SWEP.Author = "VANYA - BOG RAZRUSHENIYA"
SWEP.Category = "Vaniny pushki"
SWEP.Instructions = "LKM: Obichnyy vanshot | PKM: Mini-vzryv | V KONSOLI: armageddon_begin"

SWEP.UseHands = true
SWEP.ViewModel = "models/props_junk/bicycle01a.mdl"
SWEP.WorldModel = "models/props_junk/meathook001a.mdl"
SWEP.Spawnable = true

if CLIENT then
	SWEP.IconOverride = "cool_randomizer/png/mmmm_blury_face.png"
	SWEP.WepSelectIcon = surface.GetTextureID("cool_randomizer/vtf/arma")
end

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "Pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

local MAX_EFFECTS = 150

function SWEP:Initialize()
    self.NextArmageddon = 0
    print("ORUZHIE 'ARMAGEDDON' AKTIVIROVANO. Vvedi v konsol 'armageddon_begin' dlya starta Sudnogo Dnya.")
end

function SWEP:Reload() return false end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime())
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:EmitSound("Weapon_RPG.Single")

    local bullet = {
        Num = 1, Damage = 999999, Dir = self.Owner:GetAimVector(),
        Src = self.Owner:GetShootPos(), Spread = Vector(0,0,0),
        Tracer = 1, Force = 5000
    }
    self.Owner:FireBullets(bullet)
    self.Owner:ViewPunch(Angle(-5,0,0))
end

function SWEP:SecondaryAttack()
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:EmitSound("Weapon_RPG.Single")
    self.Owner:ViewPunch(Angle(-10, math.random(-5,5), 0))

    if SERVER then
        for i=1, 5 do
            local exp = ents.Create("env_explosion")
            if IsValid(exp) then
                local off = Vector(math.random(-512,512), math.random(-512,512), math.random(0,200))
                exp:SetPos(self.Owner:GetPos() + off)
                exp:SetOwner(self.Owner)
                exp:Spawn()
                exp:SetKeyValue("iMagnitude", "300")
                exp:Fire("Explode", "", 0)
            end
        end
    end
end

function Armageddon_Begin(ply)
    if not IsValid(ply) then return end
    if not SERVER then return end
    
    print(ply:Name() .. " NACHAL ARMAGEDDON! SERVER UMIRAET...")
    ply:PrintMessage(HUD_PRINTTALK, "TY RAZBUDIL DREVNEGo BOGa. MIR OBRECHYON.")
    ply:EmitSound("npc/strider/strider_roar1.wav")

    for i = 1, MAX_EFFECTS do
        timer.Simple(i * 0.03, function()
            if not IsValid(ply) then return end
            
            local exp_ground = ents.Create("env_explosion")
            if IsValid(exp_ground) then
                local off = Vector(math.random(-3000,3000), math.random(-3000,3000), math.random(-50,100))
                exp_ground:SetPos(ply:GetPos() + off)
                exp_ground:SetOwner(ply)
                exp_ground:Spawn()
                exp_ground:SetKeyValue("iMagnitude", "450")
                exp_ground:Fire("Explode", "", 0.05)
            end

            if i % 5 == 0 then
                local fire = ents.Create("entity_flame")
                if IsValid(fire) then
                    local off = Vector(math.random(-2000,2000), math.random(-2000,2000), 0)
                    fire:SetPos(ply:GetPos() + off)
                    fire:Spawn()
                    fire:SetKeyValue("health", "3")
                    timer.Simple(3, function() if IsValid(fire) then fire:Remove() end end)
                end
            end

            if i % 7 == 0 then
                local lightning = ents.Create("env_beam")
                if IsValid(lightning) then
                    local start_pos = ply:GetPos() + Vector(math.random(-1500,1500), math.random(-1500,1500), 800)
                    local end_pos = start_pos - Vector(0,0, 700)
                    lightning:SetPos(start_pos)
                    lightning:SetEndPos(end_pos)
                    lightning:SetKeyValue("texture", "sprites/laserbeam.vmt")
                    lightning:Spawn()
                    lightning:Fire("TurnOn", "", 0)
                    timer.Simple(0.5, function() if IsValid(lightning) then lightning:Remove() end end)
                end
            end

            if i % 10 == 0 then
                for z=1, 5 do
                    local zombie = ents.Create("npc_zombie")
                    if IsValid(zombie) then
                        local off = Vector(math.random(-1200,1200), math.random(-1200,1200), 50)
                        zombie:SetPos(ply:GetPos() + off)
                        zombie:Spawn()
                        zombie:SetHealth(25)
                    end
                end
            end

            if i % 15 == 0 then
                for p=1, 20 do
                    local barrel = ents.Create("prop_physics")
                    if IsValid(barrel) then
                        barrel:SetModel("models/props_c17/oildrum001_explosive.mdl")
                        local off = Vector(math.random(-1000,1000), math.random(-1000,1000), math.random(300, 800))
                        barrel:SetPos(ply:GetPos() + off)
                        barrel:Spawn()
                        local phys = barrel:GetPhysicsObject()
                        if IsValid(phys) then
                            phys:SetVelocity(Vector(math.random(-500,500), math.random(-500,500), math.random(400, 800)))
                        end
                    end
                end
            end
        end)
    end

    timer.Simple(1, function()
        for _, p in ipairs(player.GetAll()) do
            p:SetFOV(10, 0.5)
            p:EmitSound("ambient/explosions/explode_1.wav")
            p:PrintMessage(HUD_PRINTTALK, "TEBYa OSLIPILO...")
        end
    end)

    timer.Simple(0.5, function() print("SERVER PREduPREZhDAET: FPS UPAL DO 0...") end)
    timer.Simple(1.5, function() print("SERVER KRIChIT: HVATIT, VANYa!") end)
    timer.Simple(3, function() print("ARMAGEDDON ZAVERShYON. MIR RAZRUShEN.") end)
end

concommand.Add("armageddon_begin", function(ply)
    if IsValid(ply) and ply:IsAdmin() then
        Armageddon_Begin(ply)
    elseif IsValid(ply) then
        ply:PrintMessage(HUD_PRINTTALK, "Ty ne Bog. Nuzhny prava admina.")
    end
end)