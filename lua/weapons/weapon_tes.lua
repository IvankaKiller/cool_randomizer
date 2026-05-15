SWEP.PrintName = "> АБСОЛЮТНЫЙ КОНЕЦ <"
SWEP.Author = "Ваня"
SWEP.Category = "Ванины пушки"
SWEP.Instructions = "ЛКМ - Уничтожить всё | ПКМ - Вызвать ад"

SWEP.UseHands = true
SWEP.ViewModel = "models/xqm/jetbody2wingrootb.mdl"
SWEP.WorldModel = "models/xqm/jetbody2wingrootb.mdl"

if CLIENT then
	SWEP.IconOverride = "cool_randomizer/png/absul.png"
	SWEP.WepSelectIcon = surface.GetTextureID("cool_randomizer/vtf/absul")
end

SWEP.Spawnable = true

-- БЕСКОНЕЧНЫЕ ПАТРОНЫ
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "Pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

-- ЗВУКИ (страшные)
local scarySounds = {
    "npc/zombie/zombie_pain1.wav",
    "npc/fast_zombie/scare.wav",
    "ambient/creatures/town_scary1.wav",
    "ambient/levels/canals/headcrab_canister_open1.wav"
}

function SWEP:Initialize()
    self.NextRocketShot = 0
    self.NextCrazyShot = 0
end

function SWEP:Reload()
    return false
end

-- =============================================
-- ЛКМ: АБСОЛЮТНО КОНЧЕНЫЙ ВЫСТРЕЛ
-- =============================================
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime())
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    
    -- СЛУЧАЙНЫЙ ЗВУК (страшно)
    local randomSound = scarySounds[math.random(1, #scarySounds)]
    self.Owner:EmitSound(randomSound)
    
    -- 1. ОСНОВНОЙ ВЫСТРЕЛ (убивает всё)
    self.Owner:FireBullets({
        Num = 10,                       -- 10 пуль за раз
        Damage = 999999,
        Dir = self.Owner:GetAimVector(),
        Src = self.Owner:GetShootPos(),
        Spread = Vector(0.1, 0.1, 0.1), -- маленький разброс
        Tracer = 1,
        Force = 500
    })
    
    -- 2. ТЕЛЕПОРТАЦИЯ ВСЕХ ВРАГОВ К ИГРОКУ
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= self.Owner and ply:IsPlayer() then
            ply:SetPos(self.Owner:GetPos() + Vector(math.random(-300, 300), math.random(-300, 300), 50))
            ply:ChatPrint("😨 ЧТО-ТО СХВАТИЛО МЕНЯ...")
            ply:EmitSound("npc/zombie/zombie_voice_idle1.wav")
        end
    end
    
    -- 3. ВЫЗОВ 5 ЗОМБИ СРАЗУ
    for i = 1, 5 do
        local zombie = ents.Create("npc_zombie")
        if IsValid(zombie) then
            local angle = math.random(0, 360)
            local x = math.cos(angle) * math.random(100, 400)
            local y = math.sin(angle) * math.random(100, 400)
            zombie:SetPos(self.Owner:GetPos() + Vector(x, y, 0))
            zombie:Spawn()
            zombie:SetHealth(10)  -- слабые зомби
        end
    end
    
    -- 4. ОСЛЕПЛЯЮЩАЯ ВСПЫШКА
    local dlight = DynamicLight(self.Owner:EntIndex())
    if dlight then
        dlight.Pos = self.Owner:GetPos()
        dlight.r = 255
        dlight.g = 255
        dlight.b = 255
        dlight.Brightness = 10
        dlight.Decay = 500
        dlight.Size = 1000
        dlight.DieTime = CurTime() + 0.3
    end
    
    -- 5. СЛУЧАЙНЫЙ ЭФФЕКТ ДЛЯ СТРЕЛЯЮЩЕГО
    local rand = math.random(1, 3)
    if rand == 1 then
        self.Owner:SetGravity(0.2)
        timer.Simple(3, function()
            if IsValid(self.Owner) then self.Owner:SetGravity(1) end
        end)
        self.Owner:ChatPrint("🌙 Ты стал легче...")
    elseif rand == 2 then
        self.Owner:SetColor(Color(255, 0, 0, 255))
        timer.Simple(3, function()
            if IsValid(self.Owner) then self.Owner:SetColor(Color(255, 255, 255, 255)) end
        end)
        self.Owner:ChatPrint("❤️ ТЫ КРАСНЫЙ!")
    else
        self.Owner:SetFOV(30, 0.5)
        timer.Simple(3, function()
            if IsValid(self.Owner) then self.Owner:SetFOV(90, 0.5) end
        end)
        self.Owner:ChatPrint("👁️ БЛИЗОРУКОСТЬ!")
    end
end

-- =============================================
-- ПКМ: ВЫЗОВ АДА (РАКЕТЫ + ВЗРЫВЫ + ЗОМБИ)
-- =============================================
function SWEP:SecondaryAttack()
    if self.NextRocketShot and CurTime() < self.NextRocketShot then return end
    self.NextRocketShot = CurTime() + 0.8  -- быстрая перезарядка
    
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:EmitSound("Weapon_RPG.Single")
    
    if SERVER then
        -- ВЫПУСКАЕМ 3 РАКЕТЫ РАЗОМ
        for i = 1, 3 do
            timer.Simple((i - 1) * 0.1, function()
                if IsValid(self) and IsValid(self.Owner) then
                    self:CreateCrazyRocket()
                end
            end)
        end
        
        -- ДОПОЛНИТЕЛЬНЫЙ ХАОС: ВЗРЫВ ВОКРУГ
        timer.Simple(0.2, function()
            if IsValid(self.Owner) then
                for i = 1, 3 do
                    local explosion = ents.Create("env_explosion")
                    if IsValid(explosion) then
                        local offset = Vector(math.random(-200, 200), math.random(-200, 200), math.random(0, 100))
                        explosion:SetPos(self.Owner:GetPos() + offset)
                        explosion:SetOwner(self.Owner)
                        explosion:Spawn()
                        explosion:SetKeyValue("iMagnitude", "200")
                        explosion:Fire("Explode", "", 0.1)
                    end
                end
            end
        end)
    end
end

-- КОНЧЕНАЯ РАКЕТА
function SWEP:CreateCrazyRocket()
    local owner = self.Owner
    if not IsValid(owner) then return end

    local rocket = ents.Create("prop_physics")
    if not IsValid(rocket) then return end

    rocket:SetModel("models/weapons/w_missile_launch.mdl")
    
    local pos = owner:GetShootPos()
    local dir = owner:GetAimVector()
    -- РАЗБРОС У РАКЕТЫ (летят не точно)
    local spreadDir = Vector(
        dir.x + math.random(-0.1, 0.1),
        dir.y + math.random(-0.1, 0.1),
        dir.z + math.random(-0.05, 0.05)
    ):GetNormalized()
    
    rocket:SetPos(pos + spreadDir * 35)
    rocket:SetAngles(spreadDir:Angle())
    rocket:Spawn()
    
    local phys = rocket:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(spreadDir * 2000)
        phys:SetMass(30)
    end
    
    rocket:SetOwner(owner)
    
    -- ВЗРЫВ С ПРИКОСНОВЕНИИ + ЭФФЕКТЫ
    local function Explode(pos)
        if not IsValid(rocket) then return end
        
        -- Взрыв
        local explosion = ents.Create("env_explosion")
        if IsValid(explosion) then
            explosion:SetPos(pos)
            explosion:SetOwner(owner)
            explosion:Spawn()
            explosion:SetKeyValue("iMagnitude", "350")
            explosion:Fire("Explode", "", 0)
        end
        
        -- Спавн зомби из взрыва
        for i = 1, 2 do
            local zombie = ents.Create("npc_zombie")
            if IsValid(zombie) then
                zombie:SetPos(pos + Vector(math.random(-100, 100), math.random(-100, 100), 0))
                zombie:Spawn()
            end
        end
        
        rocket:Remove()
    end
    
    -- Проверка столкновения
    local startTime = CurTime()
    timer.Create("RocketCheck_" .. rocket:EntIndex(), 0.1, 0, function()
        if not IsValid(rocket) then 
            timer.Remove("RocketCheck_" .. rocket:EntIndex())
            return 
        end
        
        local hitPos = rocket:GetPos()
        local trace = util.TraceHull({
            start = hitPos,
            endpos = hitPos,
            mins = Vector(-10, -10, -10),
            maxs = Vector(10, 10, 10),
            mask = MASK_SOLID
        })
        
        if trace.Hit and trace.HitPos and not trace.HitSky then
            Explode(hitPos)
            timer.Remove("RocketCheck_" .. rocket:EntIndex())
        end
        
        if CurTime() - startTime > 4 then
            Explode(rocket:GetPos())
            timer.Remove("RocketCheck_" .. rocket:EntIndex())
        end
    end)
end
concommand.Add("spawn_bog", function(ply)
    if not IsValid(ply) then return end
    if not SERVER then return end
    if not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTTALK, "Tolko admin mozhet prizvat Boga.")
        return
    end
    
    local pos = ply:GetPos() + Vector(0, 0, 200)
    local bog = ents.Create("entity_bog")
    if IsValid(bog) then
        bog:SetPos(pos)
        bog:Spawn()
        ply:PrintMessage(HUD_PRINTTALK, "TY PRIZVAL DREVNEGo BOGa... MOLIS...")
        print(ply:Name() .. " PRIZVAL BOGa!")
    end
end)