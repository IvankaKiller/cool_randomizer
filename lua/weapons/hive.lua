--[[
    =============================================
    ПЧЕЛИНАЯ ПУШКА (H.I.V.E. Launcher)
    УЛЬТРА-УПОРОТАЯ ВЕРСИЯ С СЕКРЕТАМИ
    Автор: Королева Улья и Теневой Рой
    =============================================
    ЛКМ — Выстрелить роем (пчелиный шар)
    ПКМ — Прицельный выстрел жалом
    R — Режим «Пчелиное молочко» (лечащий спрей)
    E (зажать) — Разъярённый улей (БЕРСЕРК)
    
    🍯 ПАСХАЛКИ И СЕКРЕТЫ:
    - Выстрел в улей на карте = ДРУЖЕСТВЕННЫЙ РОЙ
    - Попадание в мёд = ВЗРЫВ СЛАДОСТИ
    - 3 выстрела в небо = ПЧЕЛИНЫЙ ДОЖДЬ
    - Убить курицу = АРМИЯ ПЧЕЛ-УБИЙЦ
    - Выстрел под водой = ПЧЕЛЫ-УТОПЛЕННИКИ
    - Спелл "БДЖЖЖ" в чат = РЕЖИМ БОГА ПЧЕЛ
    =============================================
]]--

SWEP.PrintName = "H.I.V.E. Launcher"
SWEP.Author = "Queen Bee Industries"
SWEP.Purpose = "Жужжим, жалим, вызываем анафилактический шок."
SWEP.Instructions = "ЛКМ — Рой | ПКМ — Жало | R — Молочко | E — БЕРСЕРК"

if CLIENT then
    SWEP.IconOverride = "cool_randomizer/png/hive.png"
    SWEP.WepSelectIcon = surface.GetTextureID("cool_randomizer/vtf/hive")
end

SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Category = "Пчелиное Царство" -- Уникальная категория!

SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "SMG1_Grenade"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 7
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 2
SWEP.SlotPos = 3
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = false

SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"
SWEP.ViewModelFOV = 65
SWEP.UseHands = true

-- ============ ПЕРЕМЕННЫЕ И СЕКРЕТЫ ============
local BerserkMode = false
local BerserkTarget = nil
local BerserkNextTick = 0
local BeesSpawned = {}
local SkyShots = 0 -- Счётчик выстрелов в небо
local ChickenKills = 0 -- Счётчик убитых кур
local GodMode = false -- Режим бога пчёл
local LastChatTime = 0

-- Секретные звуки (редкие)
local SecretSounds = {
    "npc/roller/mine/rmine_taunt.wav",      -- Редкий звук
    "vo/npc/male01/hacks01.wav",             -- Хакерский взлом
    "vo/npc/Barney/ba_yougotit.wav",         -- Барни одобряет
    "ambient/creatures/chicken_death_02.wav", -- Куриная смерть
    "npc/roller/mine/rmine_chirp_taunt.wav"  -- Чирп-дразнилка
}

-- ============ УНИКАЛЬНЫЕ ЭФФЕКТЫ ============

-- Эффект "Медовый взрыв"
local function HoneyExplosion(pos)
    local effectdata = EffectData()
    effectdata:SetOrigin(pos)
    effectdata:SetScale(3)
    util.Effect("cball_explode", effectdata)
    
    -- Золотые капли мёда
    local emitter = ParticleEmitter(pos)
    if emitter then
        for i = 1, 50 do
            local particle = emitter:Add("sprites/glow04_noz", pos)
            if particle then
                particle:SetVelocity(VectorRand() * 400)
                particle:SetDieTime(math.Rand(1, 3))
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(math.Rand(5, 15))
                particle:SetEndSize(20)
                particle:SetColor(255, 200, 0) -- Медовый цвет
                particle:SetAirResistance(20)
                particle:SetGravity(Vector(0, 0, -200))
            end
        end
        
        -- Пчелиные соты
        for i = 1, 20 do
            local particle = emitter:Add("effects/yellowflare", pos)
            if particle then
                particle:SetVelocity(VectorRand() * 300)
                particle:SetDieTime(math.Rand(0.5, 2))
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(3)
                particle:SetEndSize(10)
                particle:SetColor(255, 150, 0)
            end
        end
        emitter:Finish()
    end
end

-- Эффект "Пчелиный дождь"
local function BeeRain(ply)
    if SERVER then
        for i = 1, 30 do
            timer.Simple(i * 0.1, function()
                if IsValid(ply) then
                    local pos = ply:GetPos() + Vector(math.random(-500, 500), math.random(-500, 500), 1000)
                    local bee = ents.Create("prop_physics")
                    bee:SetModel("models/props_junk/watermelon01_chunk02c.mdl")
                    bee:SetPos(pos)
                    bee:Spawn()
                    bee:SetColor(Color(255, 215, 0))
                    bee:SetMaterial("models/shiny")
                    
                    local phys = bee:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:SetMass(5)
                        phys:SetVelocity(Vector(0, 0, -500))
                    end
                    
                    timer.Simple(5, function()
                        if IsValid(bee) then bee:Remove() end
                    end)
                end
            end)
        end
    end
end

-- Эффект "Армия пчел-убийц"
local function KillerBeeArmy(pos, ply)
    if SERVER then
        for i = 1, 50 do
            timer.Simple(i * 0.05, function()
                if IsValid(ply) then
                    local bee = ents.Create("prop_physics")
                    bee:SetModel("models/props_junk/watermelon01_chunk02b.mdl")
                    bee:SetPos(pos + VectorRand() * 200)
                    bee:Spawn()
                    bee:SetColor(Color(255, 0, 0)) -- КРАСНЫЕ ПЧЕЛЫ-УБИЙЦЫ
                    bee:SetMaterial("models/shiny")
                    bee:SetRenderMode(RENDERMODE_TRANSALPHA)
                    bee:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
                    
                    local phys = bee:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:SetMass(0.5)
                        phys:SetVelocity(VectorRand() * 1000)
                        phys:AddAngleVelocity(VectorRand() * 500)
                    end
                    
                    -- Агрессивное поведение
                    timer.Create("KillerBee_" .. bee:EntIndex(), 0.1, 30, function()
                        if IsValid(bee) then
                            local targets = ents.FindInSphere(bee:GetPos(), 300)
                            for _, target in ipairs(targets) do
                                if (target:IsPlayer() or target:IsNPC()) and target ~= ply then
                                    local beePhys = bee:GetPhysicsObject()
                                    if IsValid(beePhys) then
                                        local dir = (target:GetPos() - bee:GetPos()):GetNormalized()
                                        beePhys:SetVelocity(dir * 800)
                                    end
                                    
                                    if bee:GetPos():Distance(target:GetPos()) < 50 then
                                        local dmginfo = DamageInfo()
                                        dmginfo:SetDamage(15)
                                        dmginfo:SetAttacker(ply)
                                        dmginfo:SetInflictor(bee)
                                        dmginfo:SetDamageType(DMG_BULLET)
                                        target:TakeDamageInfo(dmginfo)
                                        bee:Remove()
                                    end
                                end
                            end
                        else
                            timer.Remove("KillerBee_" .. bee:EntIndex())
                        end
                    end)
                    
                    timer.Simple(10, function()
                        if IsValid(bee) then 
                            bee:Remove()
                            timer.Remove("KillerBee_" .. bee:EntIndex())
                        end
                    end)
                end
            end)
        end
    end
end

-- Эффект "Пчелы-утопленники"
local function DrownedBees(pos, ply)
    if SERVER then
        for i = 1, 20 do
            local bee = ents.Create("prop_physics")
            bee:SetModel("models/props_junk/watermelon01_chunk02c.mdl")
            bee:SetPos(pos + VectorRand() * 100)
            bee:Spawn()
            bee:SetColor(Color(0, 100, 255)) -- СИНИЕ ПЧЕЛЫ
            bee:SetMaterial("models/props_combine/portalball001_sheet")
            bee:SetRenderMode(RENDERMODE_TRANSALPHA)
            
            local phys = bee:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetMass(0.1)
                phys:SetVelocity(VectorRand() * 200)
                phys:SetBuoyancyRatio(0.1) -- Тонут
            end
            
            timer.Simple(3, function()
                if IsValid(bee) then bee:Remove() end
            end)
        end
    end
end

-- ============ ПАСХАЛКИ И СЕКРЕТЫ ============

-- Проверка на улей (модели ульев на картах)
local function IsHiveEntity(ent)
    if not IsValid(ent) then return false end
    local model = ent:GetModel():lower()
    return model:find("hive") or model:find("bee") or model:find("hornet") or model:find("nest")
end

-- Проверка на мёд/сладости
local function IsHoneyEntity(ent)
    if not IsValid(ent) then return false end
    local model = ent:GetModel():lower()
    return model:find("melon") or model:find("watermelon") or model:find("food") or model:find("soda")
end

-- Чат-команды для пасхалок
hook.Add("PlayerSay", "BeeGun_Secrets", function(ply, text)
    if text:lower():find("бджжж") or text:lower():find("bzzz") then
        if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_hive_launcher" then
            GodMode = true
            ply:SetHealth(9999)
            ply:SetRunSpeed(1000)
            ply:EmitSound("vo/npc/Barney/ba_yougotit.wav")
            
            chat.AddText(Color(255, 215, 0), "[ПЧЕЛИНЫЙ БОГ] ", Color(255, 255, 0), ply:Nick() .. " ПРОИЗНЁС ЗАКЛИНАНИЕ! РЕЖИМ БОГА АКТИВИРОВАН!")
            
            timer.Simple(10, function()
                if IsValid(ply) then
                    GodMode = false
                    ply:SetHealth(100)
                    ply:SetRunSpeed(500)
                    chat.AddText(Color(255, 215, 0), "[ПЧЕЛИНЫЙ БОГ] ", Color(255, 0, 0), "БОЖЕСТВЕННАЯ СИЛА ИССЯКЛА...")
                end
            end)
        end
    end
end)

-- ============ СТАНДАРТНЫЕ ФУНКЦИИ ============

function SWEP:Initialize()
    self:SetHoldType("shotgun")
end

function SWEP:PrimaryAttack()
    local ply = self:GetOwner()
    if not IsFirstTimePredicted() then return end
    if self:Clip1() <= 0 then
        ply:EmitSound("buttons/combine_button_locked.wav")
        return
    end
    
    self:TakePrimaryAmmo(1)
    local tr = ply:GetEyeTrace()
    local hitPos = tr.HitPos
    local target = tr.Entity
    
    -- ПАСХАЛКА 1: Выстрел в улей
    if IsValid(target) and IsHiveEntity(target) then
        if SERVER then
            chat.AddText(Color(255, 215, 0), "[🐝] ", Color(255, 255, 0), "УЛЕЙ ПРОБУЖДЁН! ДРУЖЕСТВЕННЫЙ РОЙ ВЫРВАЛСЯ НА СВОБОДУ!")
            
            -- Спавним дружественных пчёл
            for i = 1, 40 do
                local friendlyBee = ents.Create("npc_headcrab") -- Замена на пчелу
                friendlyBee:SetPos(target:GetPos() + VectorRand() * 200)
                friendlyBee:Spawn()
                friendlyBee:SetColor(Color(255, 215, 0))
                friendlyBee:AddEntityRelationship(ply, D_LI, 99)
                
                timer.Simple(15, function()
                    if IsValid(friendlyBee) then friendlyBee:Remove() end
                end)
            end
        end
        
        HoneyExplosion(target:GetPos())
        ply:EmitSound("vo/npc/male01/hacks01.wav")
        return
    end
    
    -- ПАСХАЛКА 2: Попадание в мёд/арбуз
    if IsValid(target) and IsHoneyEntity(target) then
        HoneyExplosion(hitPos)
        ply:EmitSound("ambient/explosions/explode_9.wav")
        
        if SERVER then
            util.BlastDamage(self, ply, hitPos, 200, 30)
            target:Remove()
        end
        return
    end
    
    -- ПАСХАЛКА 3: Выстрелы в небо
    if tr.HitSky then
        SkyShots = SkyShots + 1
        
        if SkyShots >= 3 then
            SkyShots = 0
            BeeRain(ply)
            chat.AddText(Color(255, 215, 0), "[🐝] ", Color(255, 255, 0), "ПЧЕЛИНЫЙ ДОЖДЬ НАЧИНАЕТСЯ!")
            ply:EmitSound("ambient/machines/thumper_startup1.wav")
        end
        return
    else
        SkyShots = 0
    end
    
    -- Обычная атака
    if IsValid(target) and not target:IsWorld() then
        -- ПАСХАЛКА 4: Убийство курицы
        if target:GetClass() == "npc_headcrab" then -- Замена на курицу если есть
            ChickenKills = ChickenKills + 1
            if ChickenKills >= 3 then
                ChickenKills = 0
                KillerBeeArmy(hitPos, ply)
                chat.AddText(Color(255, 215, 0), "[🐝] ", Color(255, 0, 0), "АРМИЯ ПЧЕЛ-УБИЙЦ ВЫЗВАНА!")
            end
        end
        
        -- ПАСХАЛКА 5: Подводная атака
        if ply:WaterLevel() > 2 then
            DrownedBees(hitPos, ply)
            chat.AddText(Color(255, 215, 0), "[🐝] ", Color(0, 100, 255), "ПЧЕЛЫ-УТОПЛЕННИКИ АТАКУЮТ!")
        end
        
        -- Спавн обычных пчёл
        if SERVER then
            for i = 1, 20 do
                local bee = ents.Create("prop_physics")
                bee:SetModel("models/props_junk/watermelon01_chunk02c.mdl")
                bee:SetPos(hitPos + VectorRand() * 100)
                bee:Spawn()
                bee:SetColor(Color(255, 215, 0))
                bee:SetMaterial("models/shiny")
                bee:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
                
                local phys = bee:GetPhysicsObject()
                if IsValid(phys) then
                    phys:SetMass(0.5)
                    phys:SetVelocity(VectorRand() * 500)
                end
                
                timer.Simple(3, function()
                    if IsValid(bee) then bee:Remove() end
                end)
            end
        end
    end
    
    -- Эффекты
    local effectdata = EffectData()
    effectdata:SetOrigin(hitPos)
    effectdata:SetScale(1.5)
    util.Effect("cball_explode", effectdata)
    
    ply:EmitSound("buttons/button17.wav", 80, math.random(90, 110))
    
    self:SetNextPrimaryFire(CurTime() + 0.5)
end

function SWEP:SecondaryAttack()
    local ply = self:GetOwner()
    if not IsFirstTimePredicted() then return end
    
    local tr = ply:GetEyeTrace()
    local target = tr.Entity
    
    if IsValid(target) and not target:IsWorld() then
        local dmginfo = DamageInfo()
        dmginfo:SetDamage(GodMode and 100 or 25) -- Урон х100 в режиме бога
        dmginfo:SetAttacker(ply)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamageType(DMG_BULLET)
        target:TakeDamageInfo(dmginfo)
        
        -- Замедление
        if target:IsPlayer() then
            target:SetWalkSpeed(100)
            target:SetRunSpeed(200)
            timer.Simple(3, function()
                if IsValid(target) then
                    target:SetWalkSpeed(200)
                    target:SetRunSpeed(500)
                end
            end)
        end
        
        HoneyExplosion(tr.HitPos)
        ply:EmitSound("ambient/machines/thumper_hit.wav")
    end
    
    self:SetNextSecondaryFire(CurTime() + 1)
end

function SWEP:Reload()
    local ply = self:GetOwner()
    if not IsFirstTimePredicted() then return end
    
    -- Лечение
    ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + 30))
    
    -- Лечим союзников
    for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 200)) do
        if ent:IsPlayer() and ent ~= ply then
            ent:SetHealth(math.min(ent:GetMaxHealth(), ent:Health() + 15))
        end
    end
    
    -- Восстанавливаем патроны
    self:SetClip1(self.Primary.ClipSize)
    
    -- Эффект лечения
    local effectdata = EffectData()
    effectdata:SetOrigin(ply:GetPos())
    effectdata:SetScale(2)
    util.Effect("cball_explode", effectdata)
    
    ply:EmitSound("items/smallmedkit1.wav")
    
    self:SetNextPrimaryFire(CurTime() + 2)
end

-- ============ РЕЖИМ БЕРСЕРКА ============
function SWEP:Think()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    
    if ply:KeyDown(IN_USE) then
        local tr = ply:GetEyeTrace()
        local ent = tr.Entity
        
        if IsValid(ent) and not ent:IsWorld() then
            if not BerserkMode or BerserkTarget ~= ent then
                BerserkMode = true
                BerserkTarget = ent
                BerserkNextTick = CurTime() + 0.2
            end
            
            if BerserkMode and CurTime() >= BerserkNextTick then
                if IsValid(BerserkTarget) and (BerserkTarget:IsPlayer() or BerserkTarget:IsNPC()) then
                    local dmginfo = DamageInfo()
                    dmginfo:SetDamage(GodMode and 50 or 8) -- Урон х6 в режиме бога
                    dmginfo:SetAttacker(ply)
                    dmginfo:SetInflictor(self)
                    dmginfo:SetDamageType(DMG_BULLET)
                    BerserkTarget:TakeDamageInfo(dmginfo)
                    
                    HoneyExplosion(BerserkTarget:GetPos())
                end
                BerserkNextTick = CurTime() + 0.1
            end
        end
    else
        if BerserkMode then
            BerserkMode = false
            BerserkTarget = nil
            BerserkNextTick = 0
        end
    end
end

function SWEP:Holster()
    BerserkMode = false
    BerserkTarget = nil
    return true
end

function SWEP:OnRemove()
    BerserkMode = false
    BerserkTarget = nil
    for _, bee in ipairs(BeesSpawned) do
        if IsValid(bee) then bee:Remove() end
    end
    BeesSpawned = {}
end

-- ============ УНИКАЛЬНЫЙ HUD С СЕКРЕТАМИ ============
function SWEP:DrawHUD()
    local x, y = ScrW() / 2, ScrH() - 100
    
    -- Секретный HUD для режима бога
    if GodMode then
        draw.SimpleText("🐝 РЕЖИМ БОГА ПЧЕЛ АКТИВЕН! 🐝", "DermaLarge", x, y - 60, 
            Color(255, 215, 0, 255 + math.sin(CurTime() * 10) * 100), TEXT_ALIGN_CENTER)
    end
    
    if BerserkMode then
        draw.SimpleText("⚡ БЕРСЕРК УЛЬЯ ⚡", "DermaLarge", x, y - 40, 
            Color(255, 0, 0, 255 + math.sin(CurTime() * 15) * 100), TEXT_ALIGN_CENTER)
    end
    
    draw.SimpleText("ПЧЁЛ: " .. self:Clip1() .. "/" .. self.Primary.ClipSize, "DermaDefault", 
        x, y, Color(255, 215, 0), TEXT_ALIGN_CENTER)
    
    -- Секретный счетчик пасхалок
    if SkyShots > 0 then
        draw.SimpleText("Выстрелы в небо: " .. SkyShots .. "/3", "DermaDefault", 
            x, y + 20, Color(100, 200, 255), TEXT_ALIGN_CENTER)
    end
end

-- Уникальный прицел-соты
function SWEP:DoDrawCrosshair(x, y)
    if BerserkMode then
        -- Красные соты в берсерке
        surface.SetDrawColor(255, 0, 0, 255)
    elseif GodMode then
        -- Золотые соты в режиме бога
        surface.SetDrawColor(255, 215, 0, 255 + math.sin(CurTime() * 20) * 100)
    else
        surface.SetDrawColor(255, 215, 0, 200)
    end
    
    local size = 10
    for i = 0, 5 do
        local angle1 = math.rad(60 * i)
        local angle2 = math.rad(60 * (i + 1))
        surface.DrawLine(
            x + math.cos(angle1) * size,
            y + math.sin(angle1) * size,
            x + math.cos(angle2) * size,
            y + math.sin(angle2) * size
        )
    end
    
    return true
end