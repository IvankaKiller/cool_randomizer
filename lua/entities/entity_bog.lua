AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "БОГ - ВСЕВЫШНИЙ"
ENT.Author = "ВАНЯ"
ENT.Category = "Entities"
ENT.Spawnable = true
ENT.AdminSpawnable = true

-- Возможные модели для Бога
local GodModels = {
    "models/player/combine_super_soldier.mdl",
    "models/player/charple.mdl",
    "models/player/gman_high.mdl",
    "models/player/alyx.mdl",
    "models/player/breen.mdl",
    "models/player/eli.mdl",
    "models/player/mossman.mdl",
    "models/player/odessa.mdl",
    "models/player/kleiner.mdl",
    "models/player/zombie_classic.mdl",
    "models/player/zombie_fast.mdl",
    "models/player/poison_zombie.mdl"
}

-- Возможные цвета
local GodColors = {
    {255, 50, 50},   -- Красный (гнев)
    {50, 255, 50},   -- Зелёный (милость)
    {50, 50, 255},   -- Синий (мудрость)
    {255, 255, 50},  -- Жёлтый (предупреждение)
    {255, 50, 255},  -- Пурпурный (таинство)
    {50, 255, 255},  -- Бирюзовый (спокойствие)
    {255, 100, 100}, -- Розовый (любовь)
    {100, 100, 100}, -- Серый (безразличие)
    {200, 100, 0},   -- Оранжевый (страсть)
    {150, 0, 255}    -- Фиолетовый (власть)
}

-- Возможные характеры
local GodPersonalities = {
    {
        name = "ГНЕВНЫЙ",
        moodStart = "Гневный",
        colorIndex = 1,
        phrases = {
            "ТРЕПЕЩИТЕ, СМЕРТНЫЕ!",
            "Я РАЗДАВЛЮ ВАС, КАК НАСЕКОМЫХ!",
            "ВАШИ ГРЕХИ БЕСЧИСЛЕННЫ!",
            "Я НИКОГО НЕ ПОЩАЖУ!",
            "МОЙ ГНЕВ ОБРУШИТСЯ НА ВАС!"
        },
        actions = {"punish", "explode", "zombie", "lightning"}
    },
    {
        name = "МИЛОСЕРДНЫЙ",
        moodStart = "Счастливый",
        colorIndex = 2,
        phrases = {
            "Я ЛЮБЛЮ ВАС, ДЕТИ МОИ.",
            "ПРОСИТЕ - И ПОЛУЧИТЕ.",
            "МИР И ДОБРО ПУСТЬ СОПУТСТВУЮТ ВАМ.",
            "Я ПРОЩАЮ ВАШИ ГРЕХИ.",
            "ВЕРУЙТЕ В МЕНЯ."
        },
        actions = {"heal", "help", "bless", "protect"}
    },
    {
        name = "ХАОТИЧНЫЙ",
        moodStart = "Нейтральный",
        colorIndex = 4,
        phrases = {
            "ХАОС - ЭТО ЗАКОН!",
            "Я НЕ ПРЕДСКАЗУЕМ!",
            "КИНЬТЕ КУБИК СВОЕЙ СУДЬБЫ!",
            "ВСЁ МОЖЕТ ИЗМЕНИТЬСЯ В ЛЮБУЮ СЕКУНДУ!",
            "ПОРЯДОК - ЭТО ИЛЛЮЗИЯ!"
        },
        actions = {"random", "swap", "teleport", "confuse"}
    },
    {
        name = "МУДРЫЙ",
        moodStart = "Нейтральный",
        colorIndex = 3,
        phrases = {
            "Я ВИЖУ ВАШИ СУДЬБЫ...",
            "ЗНАНИЯ - ЭТО СИЛА.",
            "ВРЕМЯ - РЕКА. НЕЛЬЗЯ ВОЙТИ В НЕЁ ДВАЖДЫ.",
            "СМОТРИТЕ В БУДУЩЕЕ С НАДЕЖДОЙ.",
            "МОЛЧАНИЕ - ЗОЛОТО."
        },
        actions = {"answer", "reveal", "teach"}
    },
    {
        name = "ИГРИВЫЙ",
        moodStart = "Счастливый",
        colorIndex = 6,
        phrases = {
            "ДАВАЙТЕ ПОИГРАЕМ!",
            "УГАДАЙ, ЧТО СЕЙЧАС БУДЕТ?",
            "ХА-ХА, ЛОВИШЬСЯ!",
            "А ТЕПЕРЬ ПРЯТКИ!",
            "НЕ СКУЧАЙТЕ БЕЗ МЕНЯ!"
        },
        actions = {"game", "prank", "dance", "transform"}
    },
    {
        name = "ТАИНСТВЕННЫЙ",
        moodStart = "Нейтральный",
        colorIndex = 10,
        phrases = {
            "ТЫ НЕ ЗНАЕШЬ МОЕГО ИСТИННОГО ЛИЦА...",
            "ЗА ВУАЛЬЮ СКРЫВАЕТСЯ ИСТИНА.",
            "МОЯ ПРИРОДА НЕПОСТИЖИМА.",
            "СМОТРИ В ГЛУБЬ СЕБЯ...",
            "ТЫ - ЛИШЬ ПЕШКА В БОЛЬШОЙ ИГРЕ."
        },
        actions = {"mystery", "illusion", "fog"}
    },
    {
        name = "КАРАЮЩИЙ",
        moodStart = "Гневный",
        colorIndex = 1,
        phrases = {
            "ВЫ ПЕРЕШЛИ ЧЕРТУ!",
            "НИКТО НЕ УЙДЁТ ОТ ВОЗМЕЗДИЯ!",
            "СУДНЫЙ ДЕНЬ НАСТАЛ!",
            "ПЛАМЯ ОЧИСТИТ ВАС!",
            "ГРЕХИ ДОЛЖНЫ БЫТЬ НАКАЗАНЫ!"
        },
        actions = {"damage", "strike", "fire", "quake"}
    },
    {
        name = "ЗАБАВНЫЙ",
        moodStart = "Счастливый",
        colorIndex = 4,
        phrases = {
            "ХИ-ХИ-ХИ! ВЕСЕЛО, ПРАВДА?",
            "СМОТРИТЕ, ЧТО Я УМЕЮ!",
            "А ТАК МОЖЕТЕ?",
            "ДАВАЙТЕ СМЕЯТЬСЯ ВМЕСТЕ!",
            "ЖИЗНЬ - ЭТО ПРАЗДНИК!"
        },
        actions = {"fun", "confetti", "dance", "colors"}
    }
}

-- Глобальные переменные для отслеживания
local LastPlayerSay = {}

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "PowerLevel")
    self:NetworkVar("Bool", 0, "IsAngry")
    self:NetworkVar("String", 0, "GodMood")
    self:NetworkVar("String", 0, "PersonalityType")
    self:NetworkVar("Int", 1, "PersonalityIndex")
end

function ENT:Initialize()
    if SERVER then
        -- ВЫБИРАЕМ УНИКАЛЬНЫЙ ХАРАКТЕР
        local personalityIndex = math.random(1, #GodPersonalities)
        local personality = GodPersonalities[personalityIndex]
        
        -- ВЫБИРАЕМ УНИКАЛЬНЫЙ ЦВЕТ
        local colorIndex = personality.colorIndex
        local color = GodColors[colorIndex]
        
        -- ВЫБИРАЕМ УНИКАЛЬНУЮ МОДЕЛЬ
        local modelIndex = math.random(1, #GodModels)
        local model = GodModels[modelIndex]
        
        -- Применяем характеристики
        self:SetModel(model)
        self:SetColor(Color(color[1], color[2], color[3], 255))
        self:SetMaterial("models/shiny")
        self:SetPowerLevel(math.random(50, 200))
        self:SetIsAngry(personality.moodStart == "Гневный")
        self:SetGodMood(personality.moodStart)
        self:SetPersonalityType(personality.name)
        self:SetPersonalityIndex(personalityIndex)
        
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_BBOX)
        
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
        end
        
        self:SetPos(self:GetPos() + Vector(0, 0, 200))
        
        self.nextSound = CurTime()
        self.nextAction = CurTime()
        self.nextThought = CurTime()
        
        -- УНИКАЛЬНОЕ ПРИВЕТСТВИЕ
        local welcomePhrase = personality.phrases[math.random(1, #personality.phrases)]
        self:EmitSound("npc/strider/strider_speak1.wav", 80, 40)
        
        for _, p in ipairs(player.GetAll()) do
            p:PrintMessage(HUD_PRINTTALK, "=====================================")
            p:PrintMessage(HUD_PRINTTALK, "ЯВИЛСЯ БОГ ХАРАКТЕРА: " .. personality.name)
            p:PrintMessage(HUD_PRINTTALK, welcomePhrase)
            p:PrintMessage(HUD_PRINTTALK, "=====================================")
        end
        
        -- Обработчик чата
        hook.Add("PlayerSay", "GodListener_" .. self:EntIndex(), function(ply, text)
            if not IsValid(self) then return end
            self:OnPlayerSay(ply, text)
        end)
    end
end

-- Получить текущий характер
function ENT:GetPersonality()
    return GodPersonalities[self:GetPersonalityIndex()]
end

-- Реакция на сообщения игроков
function ENT:OnPlayerSay(ply, text)
    if not IsValid(ply) then return end
    
    local lowerText = string.lower(text)
    local personality = self:GetPersonality()
    
    -- Защита от спама
    if LastPlayerSay[ply] and CurTime() - LastPlayerSay[ply] < 5 then
        ply:PrintMessage(HUD_PRINTTALK, "БОГ УСТАЛ СЛУШАТЬ ТЕБЯ... ПОДОЖДИ НЕМНОГО.")
        return
    end
    LastPlayerSay[ply] = CurTime()
    
    -- Реакция в зависимости от характера
    if string.find(lowerText, "бог") or string.find(lowerText, "bog") then
        local response = personality.phrases[math.random(1, #personality.phrases)]
        ply:PrintMessage(HUD_PRINTTALK, "БОГ " .. personality.name .. " ОТВЕЧАЕТ: " .. response)
        self:EmitSound("npc/strider/strider_speak1.wav", 70, 50)
        
        -- Действие в зависимости от характера
        self:DoPersonalityAction(ply, personality)
    end
end

-- Действие в зависимости от характера
function ENT:DoPersonalityAction(ply, personality)
    local action = personality.actions[math.random(1, #personality.actions)]
    
    if action == "punish" then
        self:PunishPlayer(ply)
    elseif action == "heal" then
        self:HealPlayer(ply)
    elseif action == "help" then
        self:HelpPlayer(ply)
    elseif action == "explode" then
        self:ExplodeAround(ply)
    elseif action == "zombie" then
        self:SpawnZombie(ply)
    elseif action == "lightning" then
        self:LightningStrike(ply)
    elseif action == "damage" then
        self:DamagePlayer(ply)
    elseif action == "strike" then
        self:StrikePlayer(ply)
    elseif action == "fire" then
        self:FireRain(ply)
    elseif action == "quake" then
        self:EarthQuake(ply)
    elseif action == "random" then
        self:RandomEffect(ply)
    elseif action == "swap" then
        self:SwapPlayers()
    elseif action == "teleport" then
        self:TeleportPlayer(ply)
    elseif action == "confuse" then
        self:ConfusePlayer(ply)
    elseif action == "bless" then
        self:BlessPlayer(ply)
    elseif action == "protect" then
        self:ProtectPlayer(ply)
    elseif action == "game" then
        self:StartGame(ply)
    elseif action == "prank" then
        self:PrankPlayer(ply)
    elseif action == "dance" then
        self:MakeDance(ply)
    elseif action == "transform" then
        self:TransformPlayer(ply)
    elseif action == "fun" then
        self:FunEffect(ply)
    elseif action == "confetti" then
        self:ConfettiEffect(ply)
    elseif action == "colors" then
        self:RainbowColors(ply)
    elseif action == "answer" then
        self:AnswerQuestion(ply, "")
    elseif action == "reveal" then
        self:RevealSecret(ply)
    elseif action == "teach" then
        self:TeachLesson(ply)
    elseif action == "mystery" then
        self:MysteryEffect(ply)
    elseif action == "illusion" then
        self:IllusionEffect(ply)
    elseif action == "fog" then
        self:FogEffect(ply)
    end
end

-- ==================================================
-- ДЕЙСТВИЯ БОГА
-- ==================================================

function ENT:HealPlayer(ply)
    ply:SetHealth(ply:Health() + 50)
    ply:SetArmor(100)
    ply:PrintMessage(HUD_PRINTTALK, "БОГ ИСЦЕЛИЛ ТЕБЯ!")
end

function ENT:HelpPlayer(ply)
    ply:SetHealth(100)
    ply:SetArmor(100)
    ply:SetGravity(0.6)
    ply:PrintMessage(HUD_PRINTTALK, "БОГ ПОМОГ ТЕБЕ! ТЫ СТАЛ ЛЕГЧЕ!")
    timer.Simple(10, function() if IsValid(ply) then ply:SetGravity(1) end end)
end

function ENT:PunishPlayer(ply)
    ply:SetHealth(ply:Health() - 50)
    ply:PrintMessage(HUD_PRINTTALK, "БОГ НАКАЗАЛ ТЕБЯ!")
    ply:EmitSound("npc/fast_zombie/scare.wav")
end

function ENT:DamagePlayer(ply)
    ply:SetHealth(ply:Health() - 30)
    ply:PrintMessage(HUD_PRINTTALK, "БОГ ПРИЧИНИЛ ТЕБЕ БОЛЬ!")
end

function ENT:StrikePlayer(ply)
    ply:SetPos(ply:GetPos() + Vector(0, 0, 500))
    ply:SetHealth(ply:Health() - 20)
    ply:PrintMessage(HUD_PRINTTALK, "НЕБЕСНЫЙ ГНЕВ ОБРУШИЛСЯ НА ТЕБЯ!")
end

function ENT:ExplodeAround(ply)
    for i = 1, 3 do
        local exp = ents.Create("env_explosion")
        if IsValid(exp) then
            exp:SetPos(ply:GetPos() + Vector(math.random(-300, 300), math.random(-300, 300), 0))
            exp:Spawn()
            exp:SetKeyValue("iMagnitude", "100")
            exp:Fire("Explode", "", 0.1)
        end
    end
    ply:PrintMessage(HUD_PRINTTALK, "ВОКРУГ ТЕБЯ ВЗРЫВАЕТСЯ ЗЕМЛЯ!")
end

function ENT:SpawnZombie(ply)
    local zombie = ents.Create("npc_fastzombie")
    if IsValid(zombie) then
        zombie:SetPos(ply:GetPos() + Vector(math.random(-200, 200), math.random(-200, 200), 0))
        zombie:Spawn()
        ply:PrintMessage(HUD_PRINTTALK, "БОГ ПРИЗВАЛ К ТЕБЕ ЧУДОВИЩЕ!")
    end
end

function ENT:LightningStrike(ply)
    local lightning = ents.Create("env_beam")
    if IsValid(lightning) then
        lightning:SetPos(ply:GetPos() + Vector(0, 0, 500))
        lightning:SetEndPos(ply:GetPos())
        lightning:SetKeyValue("texture", "sprites/laserbeam.vmt")
        lightning:Spawn()
        lightning:Fire("TurnOn", "", 0)
        timer.Simple(0.5, function() if IsValid(lightning) then lightning:Remove() end end)
    end
    ply:PrintMessage(HUD_PRINTTALK, "МОЛНИЯ УДАРИЛА РЯДОМ С ТОБОЙ!")
end

function ENT:FireRain(ply)
    for i = 1, 10 do
        local fire = ents.Create("entity_flame")
        if IsValid(fire) then
            fire:SetPos(ply:GetPos() + Vector(math.random(-500, 500), math.random(-500, 500), math.random(200, 400)))
            fire:Spawn()
            timer.Simple(3, function() if IsValid(fire) then fire:Remove() end end)
        end
    end
    ply:PrintMessage(HUD_PRINTTALK, "ОГНЕННЫЙ ДОЖДЬ ОБРУШИЛСЯ НА ЗЕМЛЮ!")
end

function ENT:EarthQuake(ply)
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then
            p:ViewPunch(Angle(math.random(-10, 10), math.random(-10, 10), 0))
        end
    end
    ply:PrintMessage(HUD_PRINTTALK, "ЗЕМЛЯ ДРОЖИТ ПОД НОГАМИ!")
end

function ENT:RandomEffect(ply)
    local effects = {"teleport", "confuse", "gravity", "fov"}
    local effect = effects[math.random(1, #effects)]
    
    if effect == "teleport" then
        ply:SetPos(ply:GetPos() + Vector(math.random(-500, 500), math.random(-500, 500), math.random(0, 200)))
        ply:PrintMessage(HUD_PRINTTALK, "ХАОС ТЕЛЕПОРТИРОВАЛ ТЕБЯ!")
    elseif effect == "confuse" then
        ply:SetFOV(20, 0.2)
        timer.Simple(5, function() if IsValid(ply) then ply:SetFOV(90, 0.5) end end)
        ply:PrintMessage(HUD_PRINTTALK, "ТВОЁ ЗРЕНИЕ ИСКАЗИЛОСЬ!")
    elseif effect == "gravity" then
        ply:SetGravity(0.3)
        timer.Simple(5, function() if IsValid(ply) then ply:SetGravity(1) end end)
        ply:PrintMessage(HUD_PRINTTALK, "ГРАВИТАЦИЯ ИЗМЕНИЛАСЬ!")
    elseif effect == "fov" then
        ply:SetFOV(70, 0.3)
        timer.Simple(5, function() if IsValid(ply) then ply:SetFOV(90, 0.5) end end)
    end
end

function ENT:SwapPlayers()
    local players = {}
    for _, p in ipairs(player.GetAll()) do
        table.insert(players, p)
    end
    
    if #players >= 2 then
        for i = 1, #players, 2 do
            if i+1 <= #players then
                local pos1 = players[i]:GetPos()
                players[i]:SetPos(players[i+1]:GetPos())
                players[i+1]:SetPos(pos1)
            end
        end
        for _, p in ipairs(players) do
            p:PrintMessage(HUD_PRINTTALK, "БОГ ПОМЕНЯЛ ВАС МЕСТАМИ!")
        end
    end
end

function ENT:TeleportPlayer(ply)
    local players = player.GetAll()
    if #players > 1 then
        local target = players[math.random(1, #players)]
        if IsValid(target) and target ~= ply then
            local pos = target:GetPos()
            ply:SetPos(pos + Vector(0, 0, 100))
            ply:PrintMessage(HUD_PRINTTALK, "БОГ ТЕЛЕПОРТИРОВАЛ ТЕБЯ К ДРУГОМУ ИГРОКУ!")
        end
    end
end

function ENT:ConfusePlayer(ply)
    ply:SetColor(Color(255, 255, 0, 255))
    ply:SetGravity(0.5)
    ply:SetFOV(40, 0.3)
    timer.Simple(6, function()
        if IsValid(ply) then
            ply:SetColor(Color(255, 255, 255, 255))
            ply:SetGravity(1)
            ply:SetFOV(90, 0.5)
        end
    end)
    ply:PrintMessage(HUD_PRINTTALK, "ХАОС ОКУТАЛ ТЕБЯ! ТЫ ЗАПУТАЛСЯ!")
end

function ENT:BlessPlayer(ply)
    ply:SetHealth(100)
    ply:SetArmor(100)
    ply:SetColor(Color(255, 215, 0, 255))
    ply:PrintMessage(HUD_PRINTTALK, "БОГ БЛАГОСЛОВИЛ ТЕБЯ! ТЫ СВЕТИШЬСЯ!")
    timer.Simple(10, function()
        if IsValid(ply) then ply:SetColor(Color(255, 255, 255, 255)) end
    end)
end

function ENT:ProtectPlayer(ply)
    ply:SetArmor(200)
    ply:PrintMessage(HUD_PRINTTALK, "БОГ ЗАЩИТИЛ ТЕБЯ! ТЕПЕРЬ У ТЕБЯ МНОГО БРОНИ!")
end

function ENT:StartGame(ply)
    ply:PrintMessage(HUD_PRINTTALK, "ИГРА: ПРЯТКИ! БОГ БУДЕТ ИСКАТЬ ТЕБЯ 30 СЕКУНД!")
    local startPos = ply:GetPos()
    timer.Simple(30, function()
        if IsValid(ply) then
            local dist = ply:GetPos():Distance(startPos)
            if dist < 500 then
                ply:PrintMessage(HUD_PRINTTALK, "БОГ НАШЁЛ ТЕБЯ! ТЫ ПРОИГРАЛ!")
                ply:SetHealth(ply:Health() - 30)
            else
                ply:PrintMessage(HUD_PRINTTALK, "БОГ НЕ НАШЁЛ ТЕБЯ! ТЫ ПОБЕДИЛ!")
                ply:SetHealth(100)
            end
        end
    end)
end

function ENT:PrankPlayer(ply)
    ply:SetModel("models/player/zombie_classic.mdl")
    ply:PrintMessage(HUD_PRINTTALK, "ХА-ХА! БОГ ПРЕВРАТИЛ ТЕБЯ В ЗОМБИ НА 10 СЕКУНД!")
    timer.Simple(10, function()
        if IsValid(ply) then
            ply:SetModel("models/player/charple.mdl")
            ply:PrintMessage(HUD_PRINTTALK, "ТЫ СНОВА ЧЕЛОВЕК!")
        end
    end)
end

function ENT:MakeDance(ply)
    ply:PrintMessage(HUD_PRINTTALK, "БОГ ЗАСТАВЛЯЕТ ТЕБЯ ТАНЦЕВАТЬ!")
    ply:SetPlaybackRate(2)
    timer.Simple(5, function() if IsValid(ply) then ply:SetPlaybackRate(1) end end)
end

function ENT:TransformPlayer(ply)
    local models = {
        "models/player/charple.mdl",
        "models/player/alyx.mdl",
        "models/player/breen.mdl"
    }
    local newModel = models[math.random(1, #models)]
    ply:SetModel(newModel)
    ply:PrintMessage(HUD_PRINTTALK, "БОГ ИЗМЕНИЛ ТВОЙ ОБЛИК!")
end

function ENT:FunEffect(ply)
    ply:SetColor(Color(math.random(0, 255), math.random(0, 255), math.random(0, 255), 255))
    ply:PrintMessage(HUD_PRINTTALK, "ТЫ СТАЛ РАДУЖНЫМ!")
    timer.Simple(5, function()
        if IsValid(ply) then ply:SetColor(Color(255, 255, 255, 255)) end
    end)
end

function ENT:ConfettiEffect(ply)
    for i = 1, 20 do
        local effect = EffectData()
        effect:SetOrigin(ply:GetPos() + Vector(math.random(-200, 200), math.random(-200, 200), math.random(0, 100)))
        util.Effect("HelicopterMegaBomb", effect)
    end
    ply:PrintMessage(HUD_PRINTTALK, "КОНФЕТТИ!")
end

function ENT:RainbowColors(ply)
    ply:PrintMessage(HUD_PRINTTALK, "ВСЕ ВОКРУГ СТАЛО РАДУЖНЫМ!")
    for _, p in ipairs(player.GetAll()) do
        p:SetColor(Color(math.random(0, 255), math.random(0, 255), math.random(0, 255), 255))
        timer.Simple(5, function() if IsValid(p) then p:SetColor(Color(255, 255, 255, 255)) end end)
    end
end

function ENT:AnswerQuestion(ply, text)
    local answers = {
        "БОГ ЗНАЕТ, НО НЕ СКАЖЕТ.",
        "ТЫ ЕЩЁ НЕ ГОТОВ К ЭТИМ ЗНАНИЯМ.",
        "МОЛИСЬ, И, БЫТЬ МОЖЕТ, ТЫ УЗНАЕШЬ.",
        "НЕ ТВОЕГО УМА ЭТО ДЕЛО.",
        "ПОСЛЕ СМЕРТИ ТЫ УЗНАЕШЬ."
    }
    local answer = answers[math.random(1, #answers)]
    ply:PrintMessage(HUD_PRINTTALK, "МУДРЫЙ БОГ ОТВЕЧАЕТ: " .. answer)
end

function ENT:RevealSecret(ply)
    ply:PrintMessage(HUD_PRINTTALK, "ТЫ УЗНАЛ ТАЙНУ: ЗАВТРА БУДЕТ ХОРОШАЯ ПОГОДА!")
end

function ENT:TeachLesson(ply)
    ply:PrintMessage(HUD_PRINTTALK, "УРОК ЖИЗНИ: НЕ НАДО БЫТЬ ЗЛЫМ!")
end

function ENT:MysteryEffect(ply)
    ply:SetColor(Color(0, 0, 0, 255))
    ply:PrintMessage(HUD_PRINTTALK, "ТЫ ИСЧЕЗАЕШЬ ВО ТЬМЕ...")
    timer.Simple(3, function()
        if IsValid(ply) then
            ply:SetColor(Color(255, 255, 255, 255))
            ply:PrintMessage(HUD_PRINTTALK, "ТЫ ВЕРНУЛСЯ В РЕАЛЬНОСТЬ...")
        end
    end)
end

function ENT:IllusionEffect(ply)
    for i = 1, 5 do
        local dummy = ents.Create("prop_physics")
        if IsValid(dummy) then
            dummy:SetModel("models/player/charple.mdl")
            dummy:SetPos(ply:GetPos() + Vector(math.random(-300, 300), math.random(-300, 300), 0))
            dummy:Spawn()
            timer.Simple(5, function() if IsValid(dummy) then dummy:Remove() end end)
        end
    end
    ply:PrintMessage(HUD_PRINTTALK, "ИЛЛЮЗИИ НАПОЛНЯЮТ МИР!")
end

function ENT:FogEffect(ply)
    for _, p in ipairs(player.GetAll()) do
        p:SetFOV(30, 0.5)
        timer.Simple(5, function()
            if IsValid(p) then p:SetFOV(90, 0.5) end
        end)
    end
    ply:PrintMessage(HUD_PRINTTALK, "ТУМАН СГУЩАЕТСЯ...")
end

-- Периодические мысли Бога
function ENT:Think()
    if SERVER then
        if CurTime() > self.nextThought then
            local personality = self:GetPersonality()
            local phrase = personality.phrases[math.random(1, #personality.phrases)]
            
            for _, p in ipairs(player.GetAll()) do
                p:PrintMessage(HUD_PRINTTALK, "БОГ " .. personality.name .. ": " .. phrase)
            end
            
            self.nextThought = CurTime() + math.random(30, 60)
        end
        
        if CurTime() > self.nextSound then
            self:EmitSound("npc/strider/strider_speak1.wav", 70, math.random(40, 60))
            self.nextSound = CurTime() + math.random(20, 40)
        end
    end
    
    self:NextThink(CurTime() + 0.5)
    return true
end

function ENT:OnRemove()
    if SERVER then
        hook.Remove("PlayerSay", "GodListener_" .. self:EntIndex())
        self:EmitSound("npc/strider/strider_pain2.wav", 100, 20)
        
        for _, p in ipairs(player.GetAll()) do
            p:PrintMessage(HUD_PRINTTALK, "БОГ " .. self:GetPersonalityType() .. " ПОКИНУЛ ЭТОТ МИР... НО ПРИДЁТ ДРУГОЙ.")
        end
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

if not CLIENT then return end

-- КЛИЕНТСКАЯ ОТРИСОВКА
function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos() + Vector(0, 0, 180)
    local ang = Angle(0, CurTime() * 30, 0)
    
    cam.Start3D2D(pos, ang, 0.2)
        draw.SimpleText("Б О Г", "Trebuchet24", 0, -30, Color(255, 215, 0, 255), 1, 1)
        draw.SimpleText(self:GetPersonalityType(), "Trebuchet18", 0, 0, Color(200, 200, 200, 255), 1, 1)
    cam.End3D2D()
    
    -- Свечение
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.Pos = self:GetPos()
        local color = self:GetColor()
        dlight.r = color.r
        dlight.g = color.g
        dlight.b = color.b
        dlight.Brightness = 3
        dlight.Decay = 400
        dlight.Size = 600
        dlight.DieTime = CurTime() + 0.2
    end
end