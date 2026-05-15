--[[
    =============================================
    ИНСТРУМЕНТ "ЗАМЕНА" (THE SWAPPER) 
    Максимально упоротая версия
    Автор: Твой Поставщик Хаоса
    =============================================
    Как работает:
    ЛКМ (на объект) - Запомнить модель
    ПКМ (на объект) - Заменить модель на запомненную
    R (на объект) - Поменять два объекта местами
    E (держать) - Случайный режим "WTF"
    =============================================
]]--

SWEP.PrintName = "ЗАМЕНА"
SWEP.Author = "Chaos Goblins Inc."
SWEP.Purpose = "Меняем реальность, вызываем эпилепсию."
SWEP.Instructions = "ЛКМ - Запомнить | ПКМ - Заменить | R - Поменять местами | E - ЛОТЕРЕЯ ХАОСА"

if CLIENT then
	SWEP.IconOverride = "cool_randomizer/png/zamena.png"
	SWEP.WepSelectIcon = surface.GetTextureID("cool_randomizer/vtf/zamena")
end

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.ViewModelFOV = 70
SWEP.UseHands = true

-- Переменные
local StoredModel = nil
local StoredSkin = 0
local StoredColor = nil
local StoredMaterial = nil
local LastSwapSound = 0
local ChaosMode = false

-- Звуки из мемов (замени на свои пути или убери)
local MemeSounds = {
    "vo/npc/male01/hacks01.wav",
    "vo/npc/male01/hacks02.wav",
    "vo/npc/Barney/ba_yougotit.wav",
    "vo/npc/male01/question27.wav",
    "npc/roller/mine/rmine_blip3.wav",
    "ambient/creatures/chicken_death_02.wav",
    "buttons/button17.wav",
    "ambient/machines/thumper_hit.wav",
    "vehicles/v8/vehicle_stop1.wav",
    "physics/cardboard/cardboard_box_impact_bullet3.wav"
}

-- Цитаты шизофазии для худа
local SchizoMessages = {
    "МОДЕЛЬ ЗАХВАЧЕНА В ЦИФРОВОЙ ПЛЕН",
    "СУЩНОСТЬ СКОПИРОВАНА В БУФЕР ДУШИ",
    "РЕАЛЬНОСТЬ ИДЁТ ПО ПИЗДЕ... ПОДОЖДИТЕ",
    "ОБЪЕКТ ДЕНАТУРИРОВАН И ОЖИДАЕТ УЧАСТИ",
    "КВАНТОВАЯ НЕОПРЕДЕЛЁННОСТЬ НАРУШЕНА",
    "ПАМЯТЬ МИРА ПЕРЕПИСАНА. СОХРАНИТЕСЬ.",
    "АХАХАХАХА... ОЙ, ТО ЕСТЬ ГОТОВО.",
    "ТРАНСМОГРИФИКАЦИЯ УСПЕШНА. ВЫ БОГ.",
    "ЕСЛИ ЧТО-ТО ПОШЛО НЕ ТАК - ЭТО ФИЧА.",
    "СОСИСКИ."
}

-- Эффекты частиц
local function DoCrazyEffects(pos)
    local effectdata = EffectData()
    effectdata:SetOrigin(pos)
    effectdata:SetScale(1.5)
    util.Effect("Explosion", effectdata) -- Маленький взрыв
    
    effectdata:SetScale(2)
    util.Effect("MuzzleFlash", effectdata) -- Вспышка
    
    effectdata:SetScale(0.5)
    util.Effect("TeslaHitBoxes", effectdata) -- Молнии
    
    effectdata:SetMagnitude(2)
    effectdata:SetScale(1)
    util.Effect("cball_explode", effectdata) -- Шаровая молния (цветная хрень)
    
    -- Спавним кучу искр
    local emitter = ParticleEmitter(pos)
    if emitter then
        for i = 1, 30 do
            local particle = emitter:Add("sprites/glow04_noz", pos)
            if particle then
                particle:SetVelocity(VectorRand() * 300)
                particle:SetDieTime(math.Rand(0.5, 2))
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(math.Rand(5, 20))
                particle:SetEndSize(0)
                particle:SetColor(math.random(100, 255), math.random(100, 255), math.random(100, 255))
                particle:SetAirResistance(50)
                particle:SetGravity(Vector(0, 0, 100))
            end
        end
        emitter:Finish()
    end
end

-- Звуковой хаос
local function DoCrazySounds(ply, pos)
    if not IsFirstTimePredicted() then return end
    if CurTime() - LastSwapSound < 0.1 then return end -- Лимит чтобы не взорвать уши
    LastSwapSound = CurTime()
    
    -- Случайный звук из списка
    local snd = MemeSounds[math.random(#MemeSounds)]
    ply:EmitSound(snd, 75, math.random(90, 150), 1, CHAN_AUTO)
    
    -- Дополнительный БАСС на всю карту
    local bassSounds = {
        "ambient/machines/thumper_hit.wav",
        "vehicles/tank_readyfire1.wav",
        "ambient/explosions/explode_9.wav"
    }
    local bass = bassSounds[math.random(#bassSounds)]
    timer.Simple(0.2, function() 
        if IsValid(ply) then 
            ply:EmitSound(bass, 100, 50, 1, CHAN_STATIC) 
        end 
    end)
end

-- Уведомления в хайд с шизофренией
local function DoSchizoHUD(ply, msg)
    -- Стандартные уведомления
    if SERVER then
        net.Start("Swapper_SchizoHUD")
            net.WriteString(msg or SchizoMessages[math.random(#SchizoMessages)])
        net.Send(ply)
    end
end

if SERVER then
    util.AddNetworkString("Swapper_SchizoHUD")
end

if CLIENT then
    net.Receive("Swapper_SchizoHUD", function()
        local msg = net.ReadString()
        chat.AddText(Color(255, 100, 100), "[ЗАМЕНА] ", Color(255, 255, 100), msg)
        
        -- Дополнительный визуальный мусор в центре экрана
        surface.PlaySound("buttons/button17.wav")
        
        local function DrawSchizoText()
            draw.SimpleText(msg, "DermaLarge", ScrW()/2 + math.random(-10, 10), ScrH()/4 + math.random(-10, 10), 
                Color(math.random(200,255), math.random(100,255), math.random(0,100), 200), 
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        hook.Add("HUDPaint", "Swapper_SchizoDraw", DrawSchizoText)
        timer.Simple(2, function() hook.Remove("HUDPaint", "Swapper_SchizoDraw") end)
    end)
end

-- Тряска экрана
local function DoScreenShake(ply)
    if CLIENT and IsFirstTimePredicted() then
        util.ScreenShake(ply:GetPos(), 15, 5, 1, 200)
    end
end

-- Функция замены модели (основная магия)
local function ApplyModelSwap(ent, ply)
    if not IsValid(ent) then return end
    if ent:IsPlayer() then 
        DoSchizoHUD(ply, "НЕЛЬЗЯ ЗАМЕНИТЬ СМЕРТНОГО. ЭТО НЕЭТИЧНО (но мы пытались)")
        return 
    end
    
    -- Сохраняем физику
    local phys = ent:GetPhysicsObject()
    local mass = 0
    local material = "default"
    if IsValid(phys) then
        mass = phys:GetMass()
        material = phys:GetMaterial()
    end
    
    -- Меняем модель и скин
    ent:SetModel(StoredModel)
    ent:SetSkin(StoredSkin)
    
    -- Меняем цвет если был
    if StoredColor then
        ent:SetColor(StoredColor)
        ent:SetRenderMode(RENDERMODE_TRANSALPHA)
    end
    
    -- Меняем материал если был
    if StoredMaterial then
        ent:SetMaterial(StoredMaterial)
    end
    
    -- Восстанавливаем физику
    timer.Simple(0.01, function()
        if IsValid(ent) then
            local newPhys = ent:GetPhysicsObject()
            if IsValid(newPhys) then
                -- Если можно менять массу (на некоторых серверах заблокировано)
                pcall(function()
                    newPhys:SetMass(mass)
                    newPhys:SetMaterial(material)
                end)
                newPhys:Wake()
            end
        end
    end)
    
    -- ЭФФЕКТЫ
    DoCrazyEffects(ent:GetPos())
    DoCrazySounds(ply, ent:GetPos())
    DoScreenShake(ply)
    DoSchizoHUD(ply, "ОБЪЕКТ ПЕРЕПИСАН. СЛАВА ХАОСУ.")
    
    -- Случайный дополнительный эффект (1 из 5)
    local rand = math.random(1, 5)
    if rand == 1 then
        -- Объект подпрыгивает
        if IsValid(phys) then phys:ApplyForceCenter(Vector(0, 0, 5000)) end
    elseif rand == 2 then
        -- Игрок получает урон током (для хардкора)
        ply:TakeDamage(5, ply, ply)
        ply:EmitSound("ambient/energy/electric_loop_1.wav")
    elseif rand == 3 then
        -- Все вокруг поджигаются на секунду
        local fire = ents.Create("env_fire")
        fire:SetPos(ent:GetPos())
        fire:Spawn()
        fire:Activate()
        timer.Simple(0.5, function() if IsValid(fire) then fire:Remove() end end)
    elseif rand == 4 then
        -- Гравитация рядом ломается на секунду
        local phys_ent = ents.Create("point_gravity")
        phys_ent:SetPos(ent:GetPos())
        phys_ent:Spawn()
        phys_ent:Activate()
        phys_ent:SetKeyValue("gravity", "-100")
        timer.Simple(1, function() if IsValid(phys_ent) then phys_ent:Remove() end end)
    elseif rand == 5 then
        -- Спавним случайный проп на секунду для смеха
        local jokeProps = {
            "models/props_junk/watermelon01.mdl",
            "models/props_c17/oildrum001.mdl",
            "models/props_junk/garbage_takeoutcarton001a.mdl",
            "models/props_junk/trashdumpster01a.mdl"
        }
        local joke = ents.Create("prop_physics")
        joke:SetModel(jokeProps[math.random(#jokeProps)])
        joke:SetPos(ent:GetPos() + Vector(0, 0, 50))
        joke:Spawn()
        joke:SetCollisionGroup(COLLISION_GROUP_WORLD)
        timer.Simple(2, function() if IsValid(joke) then joke:Remove() end end)
    end
    
    -- Иногда спавним надпись
    if math.random(1, 3) == 1 then
        local textEnt = ents.Create("point_worldtext")
        textEnt:SetPos(ent:GetPos() + Vector(0, 0, 70))
        textEnt:SetText("ЗАМЕНЁН!")
        textEnt:SetColor(Color(255, 0, 0))
        textEnt:SetScale(0.5)
        textEnt:Spawn()
        timer.Simple(2, function() if IsValid(textEnt) then textEnt:Remove() end end)
    end
end

function SWEP:PrimaryAttack()
    local ply = self:GetOwner()
    if not IsFirstTimePredicted() then return end
    
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    
    if not IsValid(ent) or ent:IsWorld() then
        DoSchizoHUD(ply, "НЕ ВИЖУ ЦЕЛИ. ТЫЧЬ В ПРЕДМЕТ, А НЕ В ВОЗДУХ, ГЕНИЙ.")
        ply:EmitSound("buttons/combine_button_locked.wav")
        return
    end
    
    -- Запоминаем модель
    StoredModel = ent:GetModel()
    StoredSkin = ent:GetSkin()
    StoredColor = ent:GetColor()
    StoredMaterial = ent:GetMaterial()
    
    DoCrazyEffects(ent:GetPos())
    DoCrazySounds(ply, ent:GetPos())
    DoSchizoHUD(ply, "ЗАХВАЧЕНО: " .. StoredModel)
    
    self:SetNextPrimaryFire(CurTime() + 0.2)
end

function SWEP:SecondaryAttack()
    local ply = self:GetOwner()
    if not IsFirstTimePredicted() then return end
    
    if not StoredModel then
        DoSchizoHUD(ply, "БУФЕР ПУСТ. СНАЧАЛА ЗАХВАТИ МОДЕЛЬ (ЛКМ).")
        ply:EmitSound("buttons/button19.wav")
        return
    end
    
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    
    if not IsValid(ent) or ent:IsWorld() then
        DoSchizoHUD(ply, "КУДА ТЫЧЕШЬ? ТАМ НИЧЕГО НЕТ.")
        return
    end
    
    -- ЗАМЕНА
    ApplyModelSwap(ent, ply)
    
    self:SetNextSecondaryFire(CurTime() + 0.3)
end

function SWEP:Reload()
    local ply = self:GetOwner()
    if not IsFirstTimePredicted() then return end
    
    local tr = ply:GetEyeTrace()
    local ent1 = tr.Entity
    
    if not IsValid(ent1) or ent1:IsWorld() then
        DoSchizoHUD(ply, "ВЫБЕРИ ПЕРВЫЙ ОБЪЕКТ ДЛЯ ОБМЕНА.")
        return
    end
    
    -- Сохраняем первый объект и ждём второго
    local savedEnt = ent1
    DoSchizoHUD(ply, "ПЕРВЫЙ ОБЪЕКТ ВЫБРАН. ТЫКНИ ВО ВТОРОЙ.")
    
    -- Ждём следующий клик R
    self.NextReloadTarget = savedEnt
end

-- Переменные для режима WTF (добавь в начало файла рядом с другими локалками)
local WTF_Active = false
local WTF_Target = nil
local WTF_NextTick = 0
local WTF_ModelsCache = nil -- Кеш моделей чтобы не грузить каждый раз

-- Функция загрузки всех моделей (кешируем для производительности)
local function LoadModelsCache()
    if WTF_ModelsCache then return WTF_ModelsCache end
    WTF_ModelsCache = {}
    local _, dirs = file.Find("models/*", "GAME")
    for _, dir in ipairs(dirs) do
        local files, _ = file.Find("models/" .. dir .. "/*.mdl", "GAME")
        for _, f in ipairs(files) do
            table.insert(WTF_ModelsCache, "models/" .. dir .. "/" .. f)
        end
    end
    return WTF_ModelsCache
end

-- Отслеживание зажатия E через хук Think (добавь в SWEP:Think)
function SWEP:Think()
    -- ... существующий код для R остаётся ...
    -- Обработка второго нажатия R
    if self.NextReloadTarget then
        local ply = self:GetOwner()
        if ply:KeyDown(IN_RELOAD) and IsFirstTimePredicted() then
            local tr = ply:GetEyeTrace()
            local ent2 = tr.Entity
            
            if IsValid(ent2) and not ent2:IsWorld() and ent2 ~= self.NextReloadTarget then
                local ent1 = self.NextReloadTarget
                
                -- Меняем модели местами
                local model1 = ent1:GetModel()
                local skin1 = ent1:GetSkin()
                local color1 = ent1:GetColor()
                local mat1 = ent1:GetMaterial()
                
                local model2 = ent2:GetModel()
                local skin2 = ent2:GetSkin()
                local color2 = ent2:GetColor()
                local mat2 = ent2:GetMaterial()
                
                ent1:SetModel(model2)
                ent1:SetSkin(skin2)
                ent1:SetColor(color2)
                ent1:SetMaterial(mat2)
                
                ent2:SetModel(model1)
                ent2:SetSkin(skin1)
                ent2:SetColor(color1)
                ent2:SetMaterial(mat1)
                
                DoCrazyEffects(ent1:GetPos())
                DoCrazyEffects(ent2:GetPos())
                DoCrazySounds(ply, (ent1:GetPos() + ent2:GetPos()) / 2)
                DoScreenShake(ply)
                DoSchizoHUD(ply, "ОБЪЕКТЫ ПОМЕНЯЛИСЬ МЕСТАМИ. МАТРИЦА СЛОМАНА.")
                
                self.NextReloadTarget = nil
            else
                DoSchizoHUD(ply, "ОТМЕНА ОБМЕНА. СЛАБАК.")
                self.NextReloadTarget = nil
            end
        end
    end
    
    -- ===== НОВОЕ: Обработка зажатия E (WTF MODE) =====
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    
    if ply:KeyDown(IN_USE) then
        local tr = ply:GetEyeTrace()
        local ent = tr.Entity
        
        -- Проверяем что игрок смотрит на валидный объект
        if IsValid(ent) and not ent:IsWorld() and not ent:IsPlayer() then
            -- Если это новый объект или режим только активируется
            if not WTF_Active or WTF_Target ~= ent then
                WTF_Active = true
                WTF_Target = ent
                WTF_NextTick = CurTime() + 0.1 -- Небольшая задержка перед первым срабатыванием
                DoSchizoHUD(ply, "РЕЖИМ WTF АКТИВИРОВАН! ДЕРЖИ E ДЛЯ ХАОСА!")
                ply:EmitSound("ambient/machines/thumper_startup1.wav")
            end
            
            -- Бешеная замена каждые N секунд
            if WTF_Active and CurTime() >= WTF_NextTick and IsFirstTimePredicted() then
                local models = LoadModelsCache()
                if models and #models > 0 then
                    local randomModel = models[math.random(#models)]
                    StoredModel = randomModel
                    StoredSkin = math.random(0, 10)
                    StoredColor = Color(math.random(50, 255), math.random(50, 255), math.random(50, 255), 255)
                    StoredMaterial = nil
                    
                    ApplyModelSwap(WTF_Target, ply)
                    
                    -- Уменьшаем интервал со временем (всё быстрее и быстрее)
                    local speed = math.max(0.05, 0.5 - (CurTime() - WTF_NextTick) * 0.1)
                    WTF_NextTick = CurTime() + speed
                    
                    DoSchizoHUD(ply, "WTF: " .. randomModel .. " [СКОРОСТЬ: " .. string.format("%.2f", speed) .. "c]")
                end
            end
        else
            -- Если смотрит в пустоту — пауза в режиме WTF но не сброс
            if WTF_Active then
                DoSchizoHUD(ply, "ПОТЕРЯНА ЦЕЛЬ. НАВЕДИ НА ОБЪЕКТ!")
            end
        end
    else
        -- Клавиша E отпущена — сбрасываем WTF
        if WTF_Active then
            WTF_Active = false
            WTF_Target = nil
            WTF_NextTick = 0
            DoSchizoHUD(ply, "РЕЖИМ WTF ОСТАНОВЛЕН. ХАОС ПРЕКРАЩЁН.")
            ply:EmitSound("ambient/machines/thumper_shutdown1.wav")
            
            -- Финальный БОЛЬШОЙ БУМ
            if IsValid(ply) then
                DoScreenShake(ply)
                DoCrazyEffects(ply:GetPos())
            end
        end
    end
    -- ===== КОНЕЦ WTF =====
end

-- Очистка при холстере
function SWEP:Holster()
    self.NextReloadTarget = nil
    WTF_Active = false
    WTF_Target = nil
    WTF_NextTick = 0
    return true
end

-- Очистка при удалении оружия
function SWEP:OnRemove()
    WTF_Active = false
    WTF_Target = nil
    WTF_NextTick = 0
end

-- Рисуем инфу о сохранённой модели на экране
function SWEP:DrawHUD()
    if StoredModel then
        local x, y = ScrW() / 2, ScrH() - 100
        draw.SimpleText("ЗАХВАЧЕНО: " .. StoredModel, "DermaDefault", x, y, Color(255, 255, 0, 255), TEXT_ALIGN_CENTER)
        draw.SimpleText("СКИН: " .. StoredSkin, "DermaDefault", x, y + 20, Color(255, 200, 0, 255), TEXT_ALIGN_CENTER)
    else
        local x, y = ScrW() / 2, ScrH() - 100
        draw.SimpleText("БУФЕР ПУСТ. ЖМИ ЛКМ НА ОБЪЕКТЕ.", "DermaDefault", x, y, Color(255, 0, 0, 255), TEXT_ALIGN_CENTER)
    end
end