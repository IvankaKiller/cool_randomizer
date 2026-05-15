--[[
    =============================================
    NPC: КВАНТОВЫЙ СТРАННИК (Quantum Strider)
    ИСПРАВЛЕННАЯ РАБОЧАЯ ВЕРСИЯ
    Автор: Департамент Квантовых Аномалий
    =============================================
    Особенности:
    - Телепортация каждые 3-5 секунд
    - Создаёт квантовые копии себя (вортигонты)
    - Стреляет квантовыми снарядами (банки/бутылки)
    - При смерти создаёт мощный взрыв
    - Имеет 3 фазы боя
    - Квантовый щит (отражает урон обратно)
    - Издаёт шизофренические звуки
    =============================================
]]--

AddCSLuaFile()

ENT.Type = "ai"
ENT.Base = "base_ai"
ENT.PrintName = "Квантовый Странник"
ENT.Author = "Quantum Anomalies Inc."
ENT.Category = "Half-Life 2"
ENT.Spawnable = true
ENT.AdminSpawnable = true

if CLIENT then
	ENT.IconOverride = "cool_randomizer/png/quantstrannik.png"
end

-- Используем ТОЛЬКО существующие модели
ENT.Model = "models/player/combine_super_soldier.mdl"
ENT.ProjectileModel = "models/props_junk/garbage_glassbottle001a.mdl" -- Существующая модель
ENT.CloneNPC = "npc_vortigaunt" -- Существующий NPC вместо хедкраба

-- Звуки (все существуют в игре)
local TeleportSounds = {
    "ambient/energy/zap1.wav",
    "ambient/energy/zap2.wav",
    "ambient/energy/zap3.wav"
}

local AttackSounds = {
    "vo/npc/male01/hacks01.wav",
    "vo/npc/male01/hacks02.wav",
    "npc/roller/mine/rmine_taunt.wav"
}

local DeathSounds = {
    "ambient/explosions/explode_8.wav",
    "ambient/explosions/explode_9.wav"
}

function ENT:Initialize()
    -- Базовая инициализация
    self:SetModel(self.Model)
    self:SetHealth(1000)
    self:SetMaxHealth(1000)
    
    -- Физика
    self:SetSolid(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_STEP)
    self:SetCollisionGroup(COLLISION_GROUP_NPC)
    
    -- Кастомные параметры
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:CapabilitiesAdd(CAP_MOVE_GROUND)
    self:CapabilitiesAdd(CAP_MOVE_JUMP)
    self:CapabilitiesAdd(CAP_MOVE_CLIMB)
    self:SetNPCState(NPC_STATE_ALERT)
    
    -- Инициализация переменных
    self.Phase = 1
    self.ShieldActive = false
    self.ShieldHealth = 200
    self.CloneCount = 0
    self.MaxClones = 3
    self.GlowColor = Color(100, 200, 255)
    self.Speed = 150
    self.NextTeleport = CurTime() + 3
    self.NextClone = CurTime() + 8
    self.NextQuote = CurTime() + 5
    self.NextPhase = CurTime() + 15
    self.NextAttack = CurTime() + 2
    
    -- Шизо-цитаты
    self.SchizoQuotes = {
        "КВАНТОВАЯ ЗАПУТАННОСТЬ НАРУШЕНА!",
        "ВРЕМЯ - ЭТО ИЛЛЮЗИЯ!",
        "Я ВИЖУ ВСЕ ВРЕМЕННЫЕ ЛИНИИ!",
        "ЭНТРОПИЯ РАСТЁТ!",
        "ШРЁДИНГЕР ОДОБРЯЕТ!",
        "КВАНТОВЫЙ СКАЧОК!",
        "ГРАВИТАЦИЯ - ВСЕГО ЛИШЬ РЕКОМЕНДАЦИЯ!",
        "Я ЗНАЮ РЕЦЕПТ ТЁМНОЙ МАТЕРИИ!"
    }
    self.CurrentQuote = 1
    
    -- Визуальные эффекты
    self:SetColor(self.GlowColor)
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    
    -- Запускаем таймеры
    timer.Simple(0.5, function()
        if IsValid(self) then
            self:StartBehaviorTimers()
        end
    end)
end

-- Запуск поведенческих таймеров
function ENT:StartBehaviorTimers()
    if not IsValid(self) then return end
    
    local idx = self:EntIndex()
    
    -- Таймер телепортации
    timer.Create("QuantumTeleport_" .. idx, 4, 0, function()
        if not IsValid(self) then timer.Remove("QuantumTeleport_" .. idx) return end
        self:QuantumTeleport()
    end)
    
    -- Таймер создания копий
    timer.Create("QuantumClone_" .. idx, 10, 0, function()
        if not IsValid(self) then timer.Remove("QuantumClone_" .. idx) return end
        if self.CloneCount < self.MaxClones then
            self:CreateQuantumClone()
        end
    end)
    
    -- Таймер шизофрении
    timer.Create("QuantumSchizo_" .. idx, 7, 0, function()
        if not IsValid(self) then timer.Remove("QuantumSchizo_" .. idx) return end
        self:SchizoQuote()
    end)
    
    -- Таймер смены фазы
    timer.Create("QuantumPhase_" .. idx, 20, 0, function()
        if not IsValid(self) then timer.Remove("QuantumPhase_" .. idx) return end
        self:ChangePhase()
    end)
end

-- ============ КВАНТОВАЯ ТЕЛЕПОРТАЦИЯ ============
function ENT:QuantumTeleport()
    if not IsValid(self) then return end
    
    local oldPos = self:GetPos()
    
    -- Эффект перед телепортацией
    self:TeleportEffect(oldPos)
    
    -- Находим случайную позицию
    local newPos = self:FindTeleportPosition()
    
    if newPos then
        -- Телепортация
        self:SetPos(newPos)
        
        -- Эффект после телепортации
        self:TeleportEffect(newPos)
        
        -- Звук
        self:EmitSound(TeleportSounds[math.random(#TeleportSounds)], 90, math.random(90, 110))
    end
end

-- Поиск позиции для телепортации
function ENT:FindTeleportPosition()
    for i = 1, 15 do
        local randomPos = self:GetPos() + Vector(
            math.Rand(-400, 400),
            math.Rand(-400, 400),
            math.Rand(-50, 150)
        )
        
        local tr = util.TraceHull({
            start = randomPos,
            endpos = randomPos,
            mins = Vector(-16, -16, 0),
            maxs = Vector(16, 16, 72),
            filter = self
        })
        
        if not tr.Hit then
            return randomPos
        end
    end
    return nil
end

-- Эффект телепортации
function ENT:TeleportEffect(pos)
    if not IsValid(self) then return end
    
    -- Взрывной эффект
    local effectdata = EffectData()
    effectdata:SetOrigin(pos)
    effectdata:SetScale(2)
    util.Effect("cball_explode", effectdata)
    
    -- Молнии
    effectdata:SetScale(1)
    util.Effect("TeslaHitBoxes", effectdata)
    
    -- Отбрасываем всё вокруг (только на сервере)
    if SERVER then
        for _, ent in ipairs(ents.FindInSphere(pos, 200)) do
            if IsValid(ent) and ent:GetPhysicsObject():IsValid() and ent ~= self then
                local dir = (ent:GetPos() - pos):GetNormalized()
                ent:GetPhysicsObject():ApplyForceCenter(dir * 2000 + Vector(0, 0, 500))
            end
        end
    end
end

-- ============ КВАНТОВАЯ АТАКА ============
function ENT:QuantumAttack(target)
    if not IsValid(self) or not IsValid(target) then return end
    
    self:EmitSound(AttackSounds[math.random(#AttackSounds)], 85, math.random(95, 105))
    
    if SERVER then
        local projectile = ents.Create("prop_physics")
        if not IsValid(projectile) then return end
        
        projectile:SetModel(self.ProjectileModel)
        projectile:SetPos(self:GetPos() + Vector(0, 0, 60))
        projectile:Spawn()
        projectile:SetColor(Color(255, 100, 100, 200))
        projectile:SetRenderMode(RENDERMODE_TRANSALPHA)
        
        -- Таймер самоуничтожения
        local projectileEnt = projectile
        timer.Simple(3, function()
            if IsValid(projectileEnt) then
                local effectdata = EffectData()
                effectdata:SetOrigin(projectileEnt:GetPos())
                effectdata:SetScale(1.5)
                util.Effect("Explosion", effectdata)
                
                util.BlastDamage(self, self, projectileEnt:GetPos(), 150, 20)
                projectileEnt:Remove()
            end
        end)
        
        -- Запускаем в цель
        local dir = (target:GetPos() - projectile:GetPos()):GetNormalized()
        local phys = projectile:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(dir * 800)
        end
    end
end

-- Поиск врагов
function ENT:FindEnemies(radius)
    local enemies = {}
    for _, ent in ipairs(ents.FindInSphere(self:GetPos(), radius or 500)) do
        if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC()) and ent ~= self and ent:Health() > 0 then
            table.insert(enemies, ent)
        end
    end
    return enemies
end

-- ============ КВАНТОВЫЕ КОПИИ ============
function ENT:CreateQuantumClone()
    if not IsValid(self) then return end
    if self.CloneCount >= self.MaxClones then return end
    
    if SERVER then
        local clonePos = self:GetPos() + Vector(math.random(-200, 200), math.random(-200, 200), 0)
        
        -- Проверяем что позиция не в стене
        local tr = util.TraceHull({
            start = clonePos,
            endpos = clonePos,
            mins = Vector(-16, -16, 0),
            maxs = Vector(16, 16, 72),
            filter = self
        })
        
        if tr.Hit then return end -- Не спавним в стене
        
        local clone = ents.Create(self.CloneNPC)
        if not IsValid(clone) then return end
        
        clone:SetPos(clonePos)
        clone:Spawn()
        clone:SetHealth(100)
        clone:SetColor(self.GlowColor or Color(100, 200, 255))
        clone:SetRenderMode(RENDERMODE_TRANSALPHA)
        
        self.CloneCount = self.CloneCount + 1
        
        -- Эффект появления
        local effectdata = EffectData()
        effectdata:SetOrigin(clonePos)
        effectdata:SetScale(1.5)
        util.Effect("cball_explode", effectdata)
        
        -- Копия живёт ограниченное время
        timer.Simple(15, function()
            if IsValid(clone) then
                local pos = clone:GetPos()
                local effectdata2 = EffectData()
                effectdata2:SetOrigin(pos)
                effectdata2:SetScale(2)
                util.Effect("cball_explode", effectdata2)
                
                clone:Remove()
                if IsValid(self) then
                    self.CloneCount = math.max(0, self.CloneCount - 1)
                end
            end
        end)
    end
    
    self:EmitSound("ambient/energy/zap1.wav", 80, 120)
end

-- ============ ШИЗОФРЕНИЧЕСКИЕ ФРАЗЫ ============
function ENT:SchizoQuote()
    if not IsValid(self) then return end
    
    local quote = self.SchizoQuotes[self.CurrentQuote] or "КВАНТОВАЯ НЕОПРЕДЕЛЁННОСТЬ!"
    self.CurrentQuote = (self.CurrentQuote % #self.SchizoQuotes) + 1
    
    -- Выводим в чат (всем)
    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("🌌 [КВАНТОВЫЙ СТРАННИК]: " .. quote)
        end
    end
    
    self:EmitSound("vo/npc/male01/question27.wav", 70, 100)
end

-- ============ СМЕНА ФАЗЫ ============
function ENT:ChangePhase()
    if not IsValid(self) then return end
    
    self.Phase = (self.Phase % 3) + 1
    
    if self.Phase == 1 then
        self.GlowColor = Color(100, 200, 255)
        self.MaxClones = 3
    elseif self.Phase == 2 then
        self.GlowColor = Color(255, 200, 50)
        self.MaxClones = 5
    else
        self.GlowColor = Color(255, 50, 50)
        self.MaxClones = 7
        self:ActivateShield()
    end
    
    self:SetColor(self.GlowColor)
    
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetScale(3)
    util.Effect("cball_explode", effectdata)
    
    self:EmitSound("ambient/machines/thumper_hit.wav", 100, 50)
end

-- ============ КВАНТОВЫЙ ЩИТ ============
function ENT:ActivateShield()
    if not IsValid(self) or self.ShieldActive then return end
    self.ShieldActive = true
    self.ShieldHealth = 200
    
    self:EmitSound("ambient/energy/zap2.wav", 90, 150)
end

-- ============ ОБРАБОТКА УРОНА ============
function ENT:OnTakeDamage(dmginfo)
    if not IsValid(self) then return 0 end
    
    local damage = dmginfo:GetDamage()
    local attacker = dmginfo:GetAttacker()
    
    -- Квантовый щит отражает урон
    if self.ShieldActive and self.ShieldHealth > 0 then
        self.ShieldHealth = self.ShieldHealth - damage
        
        -- Отражаем часть урона обратно
        if IsValid(attacker) and attacker:IsPlayer() then
            local reflectDamage = DamageInfo()
            reflectDamage:SetDamage(damage * 0.5)
            reflectDamage:SetAttacker(self)
            reflectDamage:SetInflictor(self)
            reflectDamage:SetDamageType(DMG_SHOCK)
            attacker:TakeDamageInfo(reflectDamage)
        end
        
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        effectdata:SetScale(1)
        util.Effect("TeslaHitBoxes", effectdata)
        
        if self.ShieldHealth <= 0 then
            self.ShieldActive = false
            self:EmitSound("ambient/energy/zap3.wav", 100, 200)
        end
        
        return 0
    end
    
    -- В фазе 3 получаем меньше урона
    if self.Phase == 3 then
        damage = damage * 0.7
    end
    
    -- Телепортируемся при получении урона (10% шанс)
    if math.random() < 0.1 then
        self:QuantumTeleport()
    end
    
    -- При низком здоровье переходим в фазу 3
    if self:Health() < 300 and self.Phase < 3 then
        self.Phase = 3
        self.GlowColor = Color(255, 50, 50)
        self:SetColor(self.GlowColor)
        self:ActivateShield()
        self:ChangePhase()
    end
    
    return damage
end

-- ============ СМЕРТЬ ============
function ENT:OnKilled(dmginfo)
    if not IsValid(self) then return end
    
    local deathPos = self:GetPos()
    local entIndex = self:EntIndex()
    
    -- Эпичный взрыв
    local effectdata = EffectData()
    effectdata:SetOrigin(deathPos)
    effectdata:SetScale(5)
    util.Effect("Explosion", effectdata)
    
    effectdata:SetScale(3)
    util.Effect("cball_explode", effectdata)
    
    -- Молнии во все стороны
    for i = 1, 10 do
        effectdata:SetOrigin(deathPos + VectorRand() * 100)
        effectdata:SetScale(2)
        util.Effect("TeslaHitBoxes", effectdata)
    end
    
    -- Урон вокруг при смерти
    if SERVER then
        util.BlastDamage(self, self, deathPos, 300, 75)
        
        -- Отбрасываем всё вокруг
        for _, ent in ipairs(ents.FindInSphere(deathPos, 300)) do
            if IsValid(ent) and ent:GetPhysicsObject():IsValid() then
                local dir = (ent:GetPos() - deathPos):GetNormalized()
                ent:GetPhysicsObject():ApplyForceCenter(dir * 5000 + Vector(0, 0, 2000))
            end
        end
    end
    
    -- Последняя фраза
    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint("💀 [КВАНТОВЫЙ СТРАННИК]: КВАНТОВАЯ СМЕРТЬ - ЭТО ТОЛЬКО НАЧАЛО!")
    end
    
    -- Звук смерти
    self:EmitSound(DeathSounds[math.random(#DeathSounds)], 100, 50)
    
    -- Очистка таймеров
    timer.Remove("QuantumTeleport_" .. entIndex)
    timer.Remove("QuantumClone_" .. entIndex)
    timer.Remove("QuantumSchizo_" .. entIndex)
    timer.Remove("QuantumPhase_" .. entIndex)
end

-- ============ AI ПОВЕДЕНИЕ ============
function ENT:SelectScheduleHandleEnemy()
    if not IsValid(self) then return end
    
    if CurTime() < self.NextAttack then return end
    self.NextAttack = CurTime() + 2
    
    local enemies = self:FindEnemies(600)
    if #enemies > 0 then
        local target = enemies[1]
        self:SetTarget(target)
        self:QuantumAttack(target)
    end
end

-- ============ ОТРИСОВКА HUD ПРИ НАВЕДЕНИИ (только клиент) ============
if CLIENT then
    function ENT:Draw()
        self:DrawModel()
        
        if IsValid(LocalPlayer()) then
            local tr = LocalPlayer():GetEyeTrace()
            if tr.Entity == self then
                local screenPos = self:GetPos():ToScreen()
                
                local phase = self.Phase or 1
                local glowColor = self.GlowColor or Color(100, 200, 255)
                local shieldActive = self.ShieldActive or false
                local shieldHealth = self.ShieldHealth or 0
                
                draw.SimpleText("🌌 Квантовый Странник", "DermaLarge", 
                    screenPos.x, screenPos.y - 40, 
                    Color(100, 200, 255), TEXT_ALIGN_CENTER)
                
                draw.SimpleText("HP: " .. self:Health() .. "/" .. self:GetMaxHealth(), 
                    "DermaDefault", screenPos.x, screenPos.y - 20, 
                    Color(255, 255, 255), TEXT_ALIGN_CENTER)
                
                draw.SimpleText("Фаза: " .. phase .. "/3", 
                    "DermaDefault", screenPos.x, screenPos.y - 5, 
                    glowColor, TEXT_ALIGN_CENTER)
                
                if shieldActive then
                    draw.SimpleText("🛡 ЩИТ: " .. shieldHealth, 
                        "DermaDefault", screenPos.x, screenPos.y + 10, 
                        Color(255, 255, 0), TEXT_ALIGN_CENTER)
                end
            end
        end
    end
end