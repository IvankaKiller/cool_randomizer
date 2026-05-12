SWEP.PrintName = "THE END - FINAL WEAPON"
SWEP.Author = "VANYA"
SWEP.Category = "ABSOLUTE"
SWEP.Instructions = "LMB = KILL EVERYONE | RMB = STOP TIME | CONSOLE: the_end"

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
    print("=====================================")
    print("THE END WEAPON ACTIVE - USE WITH CARE")
    print("=====================================")
end

function SWEP:Reload() return false end

-- ==================================================
-- LMB: KILL EVERYTHING (ТОЛЬКО НА СЕРВЕРЕ)
-- ==================================================
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime())
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:EmitSound("npc/strider/strider_roar1.wav", 100, 20)
    
    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply ~= self.Owner then
                ply:Kill()
            end
        end
        
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() then
                ent:Remove()
            end
        end
        
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:GetClass() == "prop_physics" then
                ent:Remove()
            end
        end
    end
    
    self.Owner:PrintMessage(HUD_PRINTTALK, "YOU DESTROYED EVERYTHING")
end

-- ==================================================
-- RMB: FREEZE EVERYTHING
-- ==================================================
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

-- ==================================================
-- THE END - ABSOLUTE APOCALYPSE (ТОЛЬКО НА СЕРВЕРЕ)
-- ==================================================
function AbsoluteEnd(ply)
    if not IsValid(ply) then return end
    if not SERVER then return end  -- ВАЖНО: только на сервере!
    
    ply:PrintMessage(HUD_PRINTTALK, "=====================================")
    ply:PrintMessage(HUD_PRINTTALK, "THIS IS THE END. NOTHING WILL REMAIN.")
    ply:PrintMessage(HUD_PRINTTALK, "=====================================")
    ply:EmitSound("npc/strider/strider_roar1.wav", 100, 10)
    
    -- STAGE 1: FREEZE EVERYONE FOREVER
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then
            p:Freeze(true)
            p:SetFOV(10, 0.1)
            p:SetGravity(0)
            p:PrintMessage(HUD_PRINTTALK, "YOU ARE NOTHING NOW")
        end
    end
    
    -- STAGE 2: DESTROY EVERY ENTITY
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
    
    -- STAGE 3: TOTAL DARKNESS
    timer.Simple(2, function()
        for i = 1, 20 do
            local dlight = DynamicLight(i)
            if dlight then
                dlight.Pos = ply:GetPos()
                dlight.r = 0
                dlight.g = 0
                dlight.b = 0
                dlight.Brightness = 100
                dlight.Size = 50000
                dlight.DieTime = CurTime() + 60
            end
        end
        ply:PrintMessage(HUD_PRINTTALK, "EVEN THE LIGHT IS DEAD")
    end)
    
    -- STAGE 4: KILL YOURSELF
    timer.Simple(4, function()
        if IsValid(ply) then
            ply:Kill()
        end
        print("=====================================")
        print("THE END. GAME OVER.")
        print("=====================================")
    end)
    
    -- STAGE 5: RESTART MAP
    timer.Simple(8, function()
        RunConsoleCommand("changelevel", "gm_construct")
    end)
end

-- CONSOLE COMMAND
concommand.Add("the_end", function(ply)
    if not IsValid(ply) then return end
    if not SERVER then return end
    if ply:IsAdmin() then
        AbsoluteEnd(ply)
    else
        ply:PrintMessage(HUD_PRINTTALK, "YOU ARE NOT THE GOD. NEED ADMIN.")
    end
end)

function SWEP:OnRemove()
    print("NOTHING MATTERS ANYMORE...")
end