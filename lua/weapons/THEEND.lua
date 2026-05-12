SWEP.PrintName = "THE END - FINAL WEAPON"
SWEP.Author = "VANYA"
SWEP.Category = "ABSOLUTE"
SWEP.Instructions = "LMB = KILL | RMB = STOP | CONSOLE: the_end"

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
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
    print("THE END WEAPON ACTIVE")
end

function SWEP:Reload() return false end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime())
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:EmitSound("npc/strider/strider_roar1.wav", 100, 20)
    
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
    
    self.Owner:PrintMessage(HUD_PRINTTALK, "YOU DESTROYED EVERYTHING")
end

function SWEP:SecondaryAttack()
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:EmitSound("ambient/levels/citadel/strange_talk1.wav")
    
    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply ~= self.Owner then
                ply:Freeze(true)
            end
        end
        
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and (ent:IsNPC() or ent:GetClass() == "prop_physics") then
                ent:Freeze(true)
            end
        end
    end
    
    self.Owner:PrintMessage(HUD_PRINTTALK, "TIME STOPPED - YOU ARE THE GOD")
    
    timer.Simple(5, function()
        if not IsValid(self) or not IsValid(self.Owner) then return end
        if SERVER then
            for _, ply in ipairs(player.GetAll()) do
                if IsValid(ply) then
                    ply:Freeze(false)
                end
            end
            for _, ent in ipairs(ents.GetAll()) do
                if IsValid(ent) and (ent:IsNPC() or ent:GetClass() == "prop_physics") then
                    ent:Freeze(false)
                end
            end
        end
        self.Owner:PrintMessage(HUD_PRINTTALK, "TIME CONTINUES...")
    end)
end

function AbsoluteEnd(ply)
    if not IsValid(ply) then return end
    if not SERVER then return end
    
    ply:PrintMessage(HUD_PRINTTALK, "=====================================")
    ply:PrintMessage(HUD_PRINTTALK, "THIS IS THE END. NOTHING WILL REMAIN.")
    ply:PrintMessage(HUD_PRINTTALK, "=====================================")
    ply:EmitSound("npc/strider/strider_roar1.wav", 100, 10)
    
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then
            p:Freeze(true)
            p:SetFOV(10, 0.1)
            p:SetGravity(0)
            p:PrintMessage(HUD_PRINTTALK, "YOU ARE NOTHING NOW")
        end
    end
    
    timer.Simple(1, function()
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent ~= ply then
                if ent:IsPlayer() then
                    ent:Kill()
                else
                    ent:Remove()
                end
            end
        end
        ply:PrintMessage(HUD_PRINTTALK, "EVERYTHING DISAPPEARED. ONLY VOID REMAINS.")
    end)
    
    timer.Simple(3, function()
        ply:PrintMessage(HUD_PRINTTALK, "DARKNESS CONSUMES YOU...")
    end)
    
    timer.Simple(4, function()
        if IsValid(ply) then
            ply:Kill()
        end
        print("=====================================")
        print("THE END. GAME OVER.")
        print("=====================================")
    end)
    
    timer.Simple(8, function()
        RunConsoleCommand("changelevel", "gm_construct")
    end)
end

concommand.Add("the_end", function(ply)
    if IsValid(ply) and ply:IsAdmin() then
        AbsoluteEnd(ply)
    elseif IsValid(ply) then
        ply:PrintMessage(HUD_PRINTTALK, "YOU ARE NOT THE GOD. NEED ADMIN.")
    end
end)

function SWEP:OnRemove()
    print("NOTHING MATTERS ANYMORE...")
end