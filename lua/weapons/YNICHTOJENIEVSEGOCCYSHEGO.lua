SWEP.PrintName = "BOG SMERTI - UNICHTOTITEL REALNOSTI"
SWEP.Author = "VANYA - RAZRUSHITEL"
SWEP.Category = "Vaniny pushki"
SWEP.Instructions = "LKM = Smert vsemu | PKM = Sozdat ad | V KONSOLI: kill_everything"

if CLIENT then
	SWEP.IconOverride = "cool_randomizer/png/starlight.png"
	SWEP.WepSelectIcon = surface.GetTextureID("cool_randomizer/vtf/gaga")
end

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/v_smg_p90.mdl"
SWEP.WorldModel = "models/weapons/w_combine_sniper.mdl"
SWEP.Spawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "Pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
    if CLIENT then
		self.Owner:PrintMessage(HUD_PRINTTALK, "TY VZYAL BOZHESTVENNOE ORUZHIE. MIR OBRECHYON.")
	end
end

function SWEP:Reload() return false end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime())
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:EmitSound("Weapon_RPG.Single")
    
    if SERVER then
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent ~= self.Owner then
                if ent:IsPlayer() or ent:IsNPC() then
                    ent:Kill()
                elseif ent:GetClass() == "prop_physics" then
                    ent:Remove()
                end
            end
        end
    end
    
    self.Owner:PrintMessage(HUD_PRINTTALK, "TY UBIL VSYO ZHIVOE NA KARTE")
end

function SWEP:SecondaryAttack()
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:EmitSound("ambient/explosions/explode_5.wav")
    
    if SERVER then
        for i = 1, 100 do
            local exp = ents.Create("env_explosion")
            if IsValid(exp) then
                local offset = Vector(
                    math.random(-5000, 5000),
                    math.random(-5000, 5000),
                    math.random(-500, 1000)
                )
                exp:SetPos(self.Owner:GetPos() + offset)
                exp:SetOwner(self.Owner)
                exp:Spawn()
                exp:SetKeyValue("iMagnitude", "1000")
                exp:Fire("Explode", "", 0)
            end
        end
        
        for i = 1, 1000 do
            local zombie = ents.Create("npc_zombie")
            if IsValid(zombie) then
                local offset = Vector(
                    math.random(-8000, 8000),
                    math.random(-8000, 8000),
                    0
                )
                zombie:SetPos(self.Owner:GetPos() + offset)
                zombie:Spawn()
            end
        end
        
        self.Owner:PrintMessage(HUD_PRINTTALK, "TY VYZVAL TYSYaChU ZOMBI I SOTNYU VZRYVOV")
    end
end

function TotalApocalypse(ply)
    if not IsValid(ply) then return end
    if not SERVER then return end
    
    ply:PrintMessage(HUD_PRINTTALK, "NACINAETSYa KONEC SVETA... PROShchAY, REALNOST")
    ply:EmitSound("npc/strider/strider_roar1.wav")
    
    for i = 1, 500 do
        local exp = ents.Create("env_explosion")
        if IsValid(exp) then
            exp:SetPos(Vector(
                math.random(-15000, 15000),
                math.random(-15000, 15000),
                math.random(-1000, 2000)
            ))
            exp:Spawn()
            exp:SetKeyValue("iMagnitude", "1500")
            exp:Fire("Explode", "", 0.1)
        end
    end
    
    timer.Simple(0.5, function()
        for i = 1, 2000 do
            local zombie = ents.Create("npc_zombie")
            if IsValid(zombie) then
                zombie:SetPos(Vector(
                    math.random(-12000, 12000),
                    math.random(-12000, 12000),
                    0
                ))
                zombie:Spawn()
            end
        end
    end)
    
    timer.Simple(1, function()
        for i = 1, 1000 do
            local barrel = ents.Create("prop_physics")
            if IsValid(barrel) then
                barrel:SetModel("models/props_c17/oildrum001_explosive.mdl")
                barrel:SetPos(Vector(
                    math.random(-10000, 10000),
                    math.random(-10000, 10000),
                    math.random(200, 800)
                ))
                barrel:Spawn()
                local phys = barrel:GetPhysicsObject()
                if IsValid(phys) then
                    phys:SetVelocity(Vector(math.random(-300, 300), math.random(-300, 300), math.random(100, 500)))
                end
            end
        end
    end)
    
    timer.Simple(1.5, function()
        for i = 1, 200 do
            local fire = ents.Create("entity_flame")
            if IsValid(fire) then
                fire:SetPos(Vector(
                    math.random(-8000, 8000),
                    math.random(-8000, 8000),
                    math.random(0, 100)
                ))
                fire:Spawn()
            end
        end
    end)
    
    timer.Simple(2, function()
        for _, target in ipairs(player.GetAll()) do
            if IsValid(target) then
                target:SetPos(target:GetPos() + Vector(0, 0, 2000))
                target:SetGravity(0.1)
                target:PrintMessage(HUD_PRINTTALK, "TEBYa VOZNOSIT V NEBESA... PROShchAY")
                timer.Simple(3, function()
                    if IsValid(target) then
                        target:SetGravity(1)
                        target:PrintMessage(HUD_PRINTTALK, "ZEMLYa VSTRECHAET TEBYa SMERTYu")
                        target:Kill()
                    end
                end)
            end
        end
    end)
    
    timer.Simple(4, function()
        for i = 1, 50 do
            local exp = ents.Create("env_explosion")
            if IsValid(exp) then
                exp:SetPos(ply:GetPos() + Vector(math.random(-3000, 3000), math.random(-3000, 3000), math.random(-200, 500)))
                exp:Spawn()
                exp:SetKeyValue("iMagnitude", "2000")
                exp:Fire("Explode", "", 0)
            end
        end
        ply:PrintMessage(HUD_PRINTTALK, "ARMAGEDDON ZAVERShYON. MIR UNICHTOTZhEN. PEREGRUZI KARTU")
    end)
end

concommand.Add("kill_everything", function(ply)
    if IsValid(ply) then
        TotalApocalypse(ply)
    end
end)