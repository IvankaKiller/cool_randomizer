AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "НЕЧТО"
ENT.Author = "ВАНЯ"
ENT.Category = "Entities"
ENT.Spawnable = true
ENT.AdminSpawnable = true

if CLIENT then
	ENT.IconOverride = "cool_randomizer/png/bog.png"
end

-- Модели для Нечто
local ThingModels = {
    "models/player/charple.mdl",
    "models/player/zombie_classic.mdl",
    "models/player/zombie_fast.mdl",
    "models/player/poison_zombie.mdl",
    "models/player/gman_high.mdl",
    "models/player/corpse1.mdl",
    "models/player/combine_super_soldier.mdl"
}

-- Страшные цвета
local ThingColors = {
    {20, 20, 20}, {60, 0, 0}, {0, 0, 40}, {30, 0, 30}, {10, 10, 10}
}

-- ОГРОМНЫЙ массив с типами поведения
local ThingPersonalities = {
    {
        name = "ИСКАЖИТЕЛЬ",
        phrases = {"РЕАЛЬНОСТЬ РУШИТСЯ...", "ЭТО НЕ ПО-НАСТОЯЩЕМУ...", "ПРОСНИСЬ...", "МИР ТРЕЩИТ ПО ШВАМ..."},
        actions = {"distort", "blur", "tunnel", "hallucinate", "shake", "glitch_heavy", "color_bleed", "mirror_world", "pixelate", "chromatic"}
    },
    {
        name = "ТЕНЬ",
        phrases = {"ТВОЯ ТЕНЬ ОЖИЛА...", "СЗАДИ КТО-ТО ЕСТЬ...", "ОГЛЯНИСЬ МЕДЛЕННО...", "ОН РЯДОМ..."},
        actions = {"shadow", "darkness", "flicker", "footsteps", "cold", "shadow_hand", "dark_aura", "light_flicker", "shadow_clone", "dark_fog"}
    },
    {
        name = "ШЁПОТ",
        phrases = {"ТИШЕ... ОН МОЖЕТ УСЛЫШАТЬ...", "НЕ КРИЧИ...", "ТЫ УЖЕ НИКОГДА НЕ БУДЕШЬ ПРЕЖНИМ..."},
        actions = {"whisper", "heartbeat", "child_laugh", "static", "echo", "demon_voice", "radio_voice", "backwards_speech", "inverted_speech", "whisper_army"}
    },
    {
        name = "ПАРАНОЙЯ",
        phrases = {"ЗА ТОБОЙ СЛЕДЯТ...", "ТЕБЯ ХОТЯТ ОБМАНУТЬ...", "НЕ ВЕРЬ СВОИМ ГЛАЗАМ...", "ОНИ ПОВСЮДУ..."},
        actions = {"fake_chat", "screen_glitch", "invert", "slow", "pull", "fake_damage", "fake_death", "fake_explosion", "fake_health", "fake_weapon"}
    },
    {
        name = "УЖАС",
        phrases = {"ТЫ УЖЕ МЁРТВ...", "СМОТРИ ПОД НОГИ...", "ОНИ ИДУТ...", "БЕГИ, ПОКА МОЖЕШЬ..."},
        actions = {"blood_screen", "ghost_pass", "scream", "fear", "blackout", "fall", "choke", "vertigo", "drown", "burn"}
    },
    {
        name = "КОШМАР",
        phrases = {"ЭТО НЕ СОН...", "ПРОСНИСЬ... НЕ МОЖЕШЬ?", "ТЫ В ЛОВУШКЕ...", "ВЫХОДА НЕТ..."},
        actions = {"spawn_chairs", "spawn_boxes", "spawn_barrels", "spawn_ragdolls", "spawn_mannequins", "spawn_ghosts", "spawn_eyes", "spawn_hands", "spawn_crosses", "spawn_blood"}
    },
    {
        name = "ХАОС",
        phrases = {"ВСЁ РАЗРУШАЕТСЯ...", "ПРЕДСКАЗУЕМОСТЬ УМЕРЛА...", "ЗАКОНЫ НЕ РАБОТАЮТ...", "СВОБОДА!"},
        actions = {"random_teleport", "random_gravity", "random_fov", "random_speed", "random_color", "random_sound", "random_shake", "random_flash", "explode_props", "throw_objects"}
    },
    {
        name = "ПУСТОТА",
        phrases = {"ЗДЕСЬ НИЧЕГО НЕТ...", "ПУСТОТА ГЛЯДИТ НА ТЕБЯ...", "ТЫ ОДИН...", "ЗВУКИ ИСЧЕЗАЮТ..."},
        actions = {"remove_sounds", "remove_light", "remove_props", "silence", "void_walk", "no_gravity", "invisible_walls", "fake_void", "zero_vision"}
    }
}

if SERVER then
    -- Регистрируем сетевые сообщения
    local networkMessages = {
        "ThingDistort", "ThingBlur", "ThingTunnel", "ThingInvert", "ThingDarkness",
        "ThingFlicker", "ThingHeartbeat", "ThingStatic", "ThingGlitch", "ThingCold",
        "ThingShake", "ThingPull", "ThingBloodScreen", "ThingBlackout", "ThingVertigo",
        "ThingColorBleed", "ThingMirrorWorld", "ThingShadowHand", "ThingDarkAura",
        "ThingLightFlicker", "ThingDemonVoice", "ThingRadioVoice", "ThingBackwardsSpeech",
        "ThingFakeDamage", "ThingFakeDeath", "ThingGhostPass", "ThingScream", "ThingFear",
        "ThingPixelate", "ThingChromatic", "ThingShadowClone", "ThingDarkFog", "ThingInvertedSpeech",
        "ThingWhisperArmy", "ThingFakeHealth", "ThingFakeWeapon", "ThingDrown", "ThingBurn",
        "ThingRandomFlash", "ThingRemoveSounds", "ThingRemoveLight", "ThingSilence", "ThingVoidWalk",
        "ThingNoGravity", "ThingFakeVoid", "ThingZeroVision", "ThingThrowObjects"
    }
    
    for _, msg in ipairs(networkMessages) do
        util.AddNetworkString(msg)
    end
    
    -- Здоровье сущности
    function ENT:InitializeHealth()
        self.health = 100
        self.maxHealth = 100
        self:SetNWInt("ThingHealth", self.health)
        self:SetNWInt("ThingMaxHealth", self.maxHealth)
    end
    
    -- Получение урона
    function ENT:TakeDamage(amount, attacker)
        if not IsValid(self) then return end
        self.health = self.health - amount
        self:SetNWInt("ThingHealth", self.health)
        
        -- Эффект при получении урона
        if IsValid(attacker) then
            attacker:PrintMessage(HUD_PRINTTALK, "НЕЧТО ВЗВИЗГНУЛО ОТ БОЛИ!")
            net.Start("ThingScream")
            net.Send(attacker)
        end
        
        -- Смерть
        if self.health <= 0 then
            self:Die()
        end
    end
    
    -- Смерть сущности
    function ENT:Die()
        for _, p in ipairs(player.GetAll()) do
            p:PrintMessage(HUD_PRINTTALK, "=====================================")
            p:PrintMessage(HUD_PRINTTALK, "НЕЧТО ИЗДАЛО ПРЕДСМЕРТНЫЙ КРИК И ИСЧЕЗЛО!")
            p:PrintMessage(HUD_PRINTTALK, "ТЫ УБИЛ ЕГО... НО ОНО ВЕРНЁТСЯ...")
            p:PrintMessage(HUD_PRINTTALK, "=====================================")
            net.Start("ThingScream")
            net.Send(p)
            net.Start("ThingBlackout")
            net.Send(p)
        end
        self:Remove()
    end
    
    -- Функция для спавна объектов
    function ENT:SpawnObject(ply, model, offset, color)
        local obj = ents.Create("prop_physics")
        if IsValid(obj) then
            obj:SetModel(model)
            obj:SetPos(ply:GetPos() + offset)
            obj:Spawn()
            if color then
                obj:SetColor(color)
            end
            timer.Simple(5, function() if IsValid(obj) then obj:Remove() end end)
            return obj
        end
        return nil
    end
    
    -- Активное движение (летает вокруг игрока)
    function ENT:ActiveMovement()
        if not IsValid(self.target) then return end
        
        local moveType = math.random(1, 5)
        local pos = self:GetPos()
        local targetPos = self.target:GetPos()
        
        if moveType == 1 then
            -- Кружение вокруг игрока
            local angle = CurTime() * 2
            local radius = 150
            local newPos = targetPos + Vector(math.cos(angle) * radius, math.sin(angle) * radius, math.sin(angle * 2) * 50)
            self:SetPos(newPos)
        elseif moveType == 2 then
            -- Рывок к игроку
            local dir = (targetPos - pos):GetNormalized()
            local newPos = pos + dir * 20
            self:SetPos(newPos)
        elseif moveType == 3 then
            -- Внезапное исчезновение и появление за спиной
            if math.random(1, 100) < 10 then
                local behindPos = targetPos - self.target:GetAimVector() * 100
                self:SetPos(behindPos)
                self.target:PrintMessage(HUD_PRINTTALK, "НЕЧТО ПЕРЕМЕСТИЛОСЬ ЗА ТВОЮ СПИНУ!")
                self:DoScare(self.target)
            end
        elseif moveType == 4 then
            -- Парение в воздухе
            local newPos = pos + Vector(0, 0, math.sin(CurTime() * 5) * 20)
            self:SetPos(newPos)
        elseif moveType == 5 then
            -- Следование за игроком (медленно)
            local behindPos = targetPos - self.target:GetAimVector() * 120
            self:SetPos(behindPos)
        end
        
        -- Визуальный эффект движения (след)
        local trail = EffectData()
        trail:SetOrigin(pos)
        util.Effect("ManhackSparks", trail)
    end
    
    -- Функция для рандомного эффекта
    function ENT:DoScare(ply)
        if not IsValid(ply) then return end
        
        local personality = self:GetPersonality()
        local action = personality.actions[math.random(1, #personality.actions)]
        
        -- ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
        if action == "distort" then net.Start("ThingDistort") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "Мир вокруг искажается...")
        elseif action == "blur" then net.Start("ThingBlur") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "Твоё зрение затуманилось...")
        elseif action == "tunnel" then net.Start("ThingTunnel") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "Ты видишь только то, что впереди...")
        elseif action == "invert" then net.Start("ThingInvert") net.Send(ply)
        elseif action == "darkness" then net.Start("ThingDarkness") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "Вокруг темнеет...")
        elseif action == "flicker" then net.Start("ThingFlicker") net.Send(ply)
        elseif action == "screen_glitch" then net.Start("ThingGlitch") net.Send(ply)
        elseif action == "glitch_heavy" then 
            net.Start("ThingGlitch") net.Send(ply)
            timer.Simple(0.5, function() net.Start("ThingGlitch") net.Send(ply) end)
            timer.Simple(1, function() net.Start("ThingGlitch") net.Send(ply) end)
            ply:PrintMessage(HUD_PRINTTALK, "ЭКРАН СХОДИТ С УМА!!!")
        elseif action == "color_bleed" then net.Start("ThingColorBleed") net.Send(ply)
        elseif action == "mirror_world" then net.Start("ThingMirrorWorld") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "Мир перевернулся...")
        elseif action == "blood_screen" then net.Start("ThingBloodScreen") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "Твои руки в крови?!")
        elseif action == "blackout" then net.Start("ThingBlackout") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "ТЕМНОТА ПОГЛОЩАЕТ ТЕБЯ!")
        elseif action == "vertigo" then net.Start("ThingVertigo") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "У тебя кружится голова...")
        elseif action == "pixelate" then net.Start("ThingPixelate") net.Send(ply)
        elseif action == "chromatic" then net.Start("ThingChromatic") net.Send(ply)
        elseif action == "zero_vision" then net.Start("ThingZeroVision") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "ТЫ ОСЛЕП!")
        
        -- АУДИО ЭФФЕКТЫ
        elseif action == "whisper" then
            local phrase = personality.phrases[math.random(1, #personality.phrases)]
            ply:PrintMessage(HUD_PRINTTALK, "ШЁПОТ: " .. phrase)
            ply:EmitSound("npc/overwatch/radiovoice/silence.wav", 30, 80)
        elseif action == "heartbeat" then net.Start("ThingHeartbeat") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "Твоё сердце бешено колотится...")
        elseif action == "child_laugh" then
            local laughs = {"ambient/children/child_distant_laugh1.wav", "ambient/children/child_distant_laugh2.wav", "ambient/children/child_distant_laugh3.wav"}
            ply:EmitSound(laughs[math.random(1, #laughs)], 70, math.random(90, 110))
            ply:PrintMessage(HUD_PRINTTALK, "Ты слышишь детский смех... ОТВСЮДУ!")
        elseif action == "footsteps" then
            for i = 1, 3 do
                timer.Simple(i * 0.3, function() if IsValid(ply) then ply:EmitSound("player/footsteps/concrete" .. math.random(1,4) .. ".wav", 60, 80) end end)
            end
            ply:PrintMessage(HUD_PRINTTALK, "Кто-то идёт за тобой... ОН БЛИЗКО!")
        elseif action == "static" then net.Start("ThingStatic") net.Send(ply)
        elseif action == "echo" then ply:EmitSound("ambient/voices/citizen_beaten" .. math.random(1,5) .. ".wav", 50, 70)
        elseif action == "demon_voice" then ply:EmitSound("npc/fast_zombie/fz_scream1.wav", 80, 40) ply:PrintMessage(HUD_PRINTTALK, "ДЕМОНИЧЕСКИЙ ГОЛОС: ТЫ МОЙ...")
        elseif action == "radio_voice" then ply:EmitSound("npc/overwatch/radiovoice/attention.wav", 70, math.random(50,80)) ply:PrintMessage(HUD_PRINTTALK, "Из радио слышится странное сообщение...")
        elseif action == "backwards_speech" then ply:EmitSound("ambient/levels/citadel/strange_talk1.wav", 60, 100) ply:PrintMessage(HUD_PRINTTALK, "Ты слышишь речь ЗАДОМ НАПЕРЁД...")
        elseif action == "scream" then
            local screams = {"npc/zombie/zombie_pain1.wav", "npc/zombie/zombie_pain2.wav", "npc/fast_zombie/fz_scream1.wav"}
            ply:EmitSound(screams[math.random(1, #screams)], 100, math.random(80,120))
            ply:PrintMessage(HUD_PRINTTALK, "КРИК РАЗДАЛСЯ В ТВОЕЙ ГОЛОВЕ!")
        elseif action == "inverted_speech" then net.Start("ThingInvertedSpeech") net.Send(ply)
        elseif action == "whisper_army" then net.Start("ThingWhisperArmy") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "ТЫСЯЧИ ГОЛОСОВ ШЕПЧУТ ОДНОВРЕМЕННО!")
        elseif action == "silence" then net.Start("ThingSilence") net.Send(ply)
        elseif action == "remove_sounds" then net.Start("ThingRemoveSounds") net.Send(ply)
        
        -- ФИЗИЧЕСКИЕ ЭФФЕКТЫ
        elseif action == "shake" then net.Start("ThingShake") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "Земля дрожит под ногами!")
        elseif action == "slow" then
            local oldWalk, oldRun = ply:GetWalkSpeed(), ply:GetRunSpeed()
            ply:SetWalkSpeed(30) ply:SetRunSpeed(60)
            timer.Simple(6, function() if IsValid(ply) then ply:SetWalkSpeed(oldWalk) ply:SetRunSpeed(oldRun) end end)
            ply:PrintMessage(HUD_PRINTTALK, "Тебя что-то замедляет... Ты еле двигаешься!")
        elseif action == "pull" then net.Start("ThingPull") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "Что-то тянет тебя назад!")
        elseif action == "cold" then net.Start("ThingCold") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "Резко похолодало...")
        elseif action == "fall" then
            local pos = ply:GetPos()
            ply:SetPos(pos + Vector(0,0,300))
            timer.Simple(0.1, function() if IsValid(ply) then ply:SetPos(pos) ply:ViewPunch(Angle(10,0,0)) end end)
            ply:PrintMessage(HUD_PRINTTALK, "Ты чувствуешь, что падаешь!")
        elseif action == "choke" then net.Start("ThingHeartbeat") net.Send(ply) ply:PrintMessage(HUD_PRINTTALK, "Ты задыхаешься!")
        elseif action == "drown" then net.Start("ThingDrown") net.Send(ply)
        elseif action == "burn" then net.Start("ThingBurn") net.Send(ply)
        elseif action == "random_gravity" then
            local grav = math.random(20, 200) / 100
            ply:SetGravity(grav)
            timer.Simple(5, function() if IsValid(ply) then ply:SetGravity(1) end end)
        elseif action == "random_fov" then
            ply:SetFOV(math.random(20, 120), 0.3)
            timer.Simple(5, function() if IsValid(ply) then ply:SetFOV(90, 0.5) end end)
        elseif action == "no_gravity" then net.Start("ThingNoGravity") net.Send(ply)
        elseif action == "void_walk" then net.Start("ThingVoidWalk") net.Send(ply)
        
        -- ПСИХОЛОГИЧЕСКИЕ ЭФФЕКТЫ
        elseif action == "hallucinate" then
            for i = 1, 5 do
                local dummy = ents.Create("prop_physics")
                if IsValid(dummy) then
                    dummy:SetModel("models/player/charple.mdl")
                    dummy:SetPos(ply:GetPos() + Vector(math.random(-500,500), math.random(-500,500), 0))
                    dummy:Spawn()
                    dummy:SetColor(Color(50,50,50,100))
                    timer.Simple(4, function() if IsValid(dummy) then dummy:Remove() end end)
                end
            end
        elseif action == "shadow" then
            local dlight = DynamicLight(self:EntIndex())
            if dlight then dlight.Pos = ply:GetPos() dlight.r = 20 dlight.g = 20 dlight.b = 20 dlight.Brightness = 8 dlight.Decay = 200 dlight.Size = 800 dlight.DieTime = CurTime()+0.5 end
        elseif action == "shadow_hand" then net.Start("ThingShadowHand") net.Send(ply)
        elseif action == "dark_aura" then net.Start("ThingDarkAura") net.Send(ply)
        elseif action == "shadow_clone" then net.Start("ThingShadowClone") net.Send(ply)
        elseif action == "dark_fog" then net.Start("ThingDarkFog") net.Send(ply)
        elseif action == "fake_chat" then
            local fakeMessages = {"??? : Не оборачивайся...", "??? : Я вижу тебя", "??? : Ты следующий", "??? : Беги"}
            ply:PrintMessage(HUD_PRINTTALK, fakeMessages[math.random(1,#fakeMessages)])
        elseif action == "fake_damage" then net.Start("ThingFakeDamage") net.Send(ply)
        elseif action == "fake_death" then net.Start("ThingFakeDeath") net.Send(ply)
        elseif action == "fake_health" then net.Start("ThingFakeHealth") net.Send(ply)
        elseif action == "fake_weapon" then net.Start("ThingFakeWeapon") net.Send(ply)
        elseif action == "fear" then net.Start("ThingFear") net.Send(ply)
        elseif action == "light_flicker" then net.Start("ThingLightFlicker") net.Send(ply)
        elseif action == "random_flash" then net.Start("ThingRandomFlash") net.Send(ply)
        elseif action == "remove_light" then net.Start("ThingRemoveLight") net.Send(ply)
        elseif action == "invisible_walls" then net.Start("ThingInvisibleWalls") net.Send(ply)
        elseif action == "fake_void" then net.Start("ThingFakeVoid") net.Send(ply)
        
        -- СПАВН ОБЪЕКТОВ
        elseif action == "spawn_chairs" then
            for i = 1, 8 do self:SpawnObject(ply, "models/props_c17/chair02a.mdl", Vector(math.random(-300,300), math.random(-300,300), 0)) end
        elseif action == "spawn_boxes" then
            for i = 1, 12 do self:SpawnObject(ply, "models/props_crates/static_crate_40.mdl", Vector(math.random(-400,400), math.random(-400,400), 0)) end
        elseif action == "spawn_barrels" then
            for i = 1, 8 do self:SpawnObject(ply, "models/props_junk/barrel01.mdl", Vector(math.random(-300,300), math.random(-300,300), 0)) end
        elseif action == "spawn_ragdolls" then
            local ragdolls = {"models/player/charple.mdl", "models/player/zombie_classic.mdl", "models/player/corpse1.mdl"}
            for i = 1, 6 do self:SpawnObject(ply, ragdolls[math.random(1,#ragdolls)], Vector(math.random(-400,400), math.random(-400,400), 0), Color(100,0,0,255)) end
        elseif action == "spawn_mannequins" then
            for i = 1, 5 do self:SpawnObject(ply, "models/player/charple.mdl", Vector(math.random(-300,300), math.random(-300,300), 0), Color(80,80,80,255)) end
        elseif action == "spawn_ghosts" then
            for i = 1, 4 do
                local ghost = self:SpawnObject(ply, "models/player/charple.mdl", Vector(math.random(-400,400), math.random(-400,400), 0), Color(200,200,200,100))
                if ghost then ghost:SetMaterial("models/shiny") ghost:SetColor(Color(200,200,200,50)) end
            end
        elseif action == "spawn_eyes" then
            for i = 1, 10 do
                local eye = self:SpawnObject(ply, "models/hunter/blocks/cube1x1x1.mdl", Vector(math.random(-500,500), math.random(-500,500), math.random(50,200)))
                if eye then eye:SetColor(Color(255,0,0,255)) eye:SetModelScale(0.2) end
            end
        elseif action == "spawn_hands" then
            for i = 1, 8 do self:SpawnObject(ply, "models/hunter/blocks/cube1x1x1.mdl", Vector(math.random(-400,400), math.random(-400,400), math.random(0,100)), Color(150,75,0,255)) end
        elseif action == "spawn_crosses" then
            for i = 1, 6 do self:SpawnObject(ply, "models/props_c17/gravestone001a.mdl", Vector(math.random(-400,400), math.random(-400,400), 0)) end
        elseif action == "spawn_blood" then
            for i = 1, 15 do
                local blood = ents.Create("prop_physics")
                if IsValid(blood) then
                    blood:SetModel("models/hunter/blocks/cube1x1x1.mdl")
                    blood:SetPos(ply:GetPos() + Vector(math.random(-300,300), math.random(-300,300), 0))
                    blood:Spawn()
                    blood:SetColor(Color(255,0,0,255))
                    blood:SetModelScale(0.1)
                    timer.Simple(5, function() if IsValid(blood) then blood:Remove() end end)
                end
            end
        elseif action == "explode_props" then
            for _, obj in ipairs(ents.FindInSphere(ply:GetPos(), 500)) do
                if obj:GetClass() == "prop_physics" then obj:Remove() end
            end
        elseif action == "throw_objects" then net.Start("ThingThrowObjects") net.Send(ply)
        elseif action == "random_teleport" then
            ply:SetPos(Vector(math.random(-3000,3000), math.random(-3000,3000), math.random(0,500)))
        elseif action == "random_color" then
            ply:SetColor(Color(math.random(0,255), math.random(0,255), math.random(0,255), 255))
            timer.Simple(5, function() if IsValid(ply) then ply:SetColor(Color(255,255,255,255)) end end)
        elseif action == "ghost_pass" then net.Start("ThingGhostPass") net.Send(ply)
        end
    end
    
    -- Инициализация
    function ENT:Initialize()
        local personalityIndex = math.random(1, #ThingPersonalities)
        local personality = ThingPersonalities[personalityIndex]
        local color = ThingColors[math.random(1, #ThingColors)]
        self:SetModel(ThingModels[math.random(1, #ThingModels)])
        self:SetColor(Color(color[1], color[2], color[3], 200))
        self:SetMaterial("models/shiny")
        self:SetNWString("ThingName", personality.name)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_BBOX)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(true) phys:SetMass(50) end
        
        self:InitializeHealth()
        self.nextAction = CurTime()
        self.nextWhisper = CurTime()
        self.nextMove = CurTime()
        self.personalityIndex = personalityIndex
        self.target = nil
        
        -- Выбор цели (ближайший игрок)
        local players = player.GetAll()
        if #players > 0 then
            self.target = players[1]
            for _, p in ipairs(players) do
                if self:GetPos():Distance(p:GetPos()) < self:GetPos():Distance(self.target:GetPos()) then
                    self.target = p
                end
            end
        end
        
        for _, p in ipairs(player.GetAll()) do
            p:PrintMessage(HUD_PRINTTALK, "=====================================")
            p:PrintMessage(HUD_PRINTTALK, "Ты чувствуешь чьё-то присутствие...")
            p:PrintMessage(HUD_PRINTTALK, "НЕЧТО " .. personality.name .. " явилось в этот мир")
            p:PrintMessage(HUD_PRINTTALK, personality.phrases[1])
            p:PrintMessage(HUD_PRINTTALK, "=====================================")
        end
    end
    
    function ENT:GetPersonality() return ThingPersonalities[self.personalityIndex] end
    
    function ENT:Think()
        if not IsValid(self.target) then
            local players = player.GetAll()
            if #players > 0 then
                self.target = players[1]
            else
                self:NextThink(CurTime() + 1)
                return true
            end
        end
        
        -- Активное движение (каждый тик)
        self:ActiveMovement()
        
        -- Случайные действия
        if CurTime() > self.nextAction then
            self:DoScare(self.target)
            self.nextAction = CurTime() + math.random(5, 12)
        end
        
        if CurTime() > self.nextWhisper then
            local personality = self:GetPersonality()
            self.target:PrintMessage(HUD_PRINTTALK, "НЕЧТО " .. personality.name .. ": " .. personality.phrases[math.random(1, #personality.phrases)])
            self.nextWhisper = CurTime() + math.random(15, 30)
        end
        
        self:NextThink(CurTime() + 0.1)
        return true
    end
    
    function ENT:OnRemove()
        for _, p in ipairs(player.GetAll()) do
            p:PrintMessage(HUD_PRINTTALK, "Присутствие исчезло... но оно вернётся...")
        end
    end
    
    function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
    
    -- Получение урона от оружия
    hook.Add("EntityTakeDamage", "NechtoDamage", function(target, dmginfo)
        if IsValid(target) and target:GetClass() == "nechto" then
            local attacker = dmginfo:GetAttacker()
            target:TakeDamage(dmginfo:GetDamage(), attacker)
            dmginfo:SetDamage(0)
            return true
        end
    end)
end

-- ==================================================
-- КЛИЕНТСКИЕ ЭФФЕКТЫ
-- ==================================================
if CLIENT then
    local blurIntensity = 0
    local tunnelIntensity = 0
    local shakeIntensity = 0
    local heartbeatTime = 0
    local staticIntensity = 0
    local invertIntensity = 0
    local coldIntensity = 0
    local bloodIntensity = 0
    local blackoutIntensity = 0
    local vertigoIntensity = 0
    local pixelateIntensity = 0
    
    hook.Add("RenderScreenspaceEffects", "ThingEffects", function()
        if blurIntensity > 0 then DrawMotionBlur(0.5, blurIntensity, 0.05) blurIntensity = blurIntensity - 0.02 end
        if shakeIntensity > 0 then
            local x = math.sin(CurTime() * 60) * 4 * shakeIntensity
            local y = math.cos(CurTime() * 57) * 4 * shakeIntensity
            render.OverrideView({ origin = EyePos() + Vector(x, y, 0) })
            shakeIntensity = shakeIntensity - 0.02
        end
        if heartbeatTime > 0 then
            if math.sin(CurTime() * 25) > 0.7 then DrawMotionBlur(1, 0.4, 0.05) end
            heartbeatTime = heartbeatTime - 0.015
        end
        if staticIntensity > 0 then
            for i = 1, 150 do
                surface.SetDrawColor(255, 255, 255, math.random(0, 80) * staticIntensity)
                surface.DrawRect(math.random(0, ScrW()), math.random(0, ScrH()), math.random(1, 4), math.random(1, 4))
            end
            staticIntensity = staticIntensity - 0.02
        end
        if invertIntensity > 0 then
            DrawColorModify({["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0, ["$pp_colour_brightness"] = 0, ["$pp_colour_contrast"] = 1.5, ["$pp_colour_colour"] = 0.5})
            invertIntensity = invertIntensity - 0.025
        end
        if coldIntensity > 0 then
            DrawColorModify({["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 80, ["$pp_colour_brightness"] = -30, ["$pp_colour_contrast"] = 0.8, ["$pp_colour_colour"] = 0.6})
            coldIntensity = coldIntensity - 0.025
        end
        if bloodIntensity > 0 then
            DrawColorModify({["$pp_colour_addr"] = 100, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0, ["$pp_colour_brightness"] = -10, ["$pp_colour_contrast"] = 1.2, ["$pp_colour_colour"] = 0.8})
            bloodIntensity = bloodIntensity - 0.02
        end
        if blackoutIntensity > 0 then
            surface.SetDrawColor(0, 0, 0, 255 * blackoutIntensity)
            surface.DrawRect(0, 0, ScrW(), ScrH())
            blackoutIntensity = blackoutIntensity - 0.03
        end
        if vertigoIntensity > 0 then
            local x = math.sin(CurTime() * 20) * 20 * vertigoIntensity
            local y = math.cos(CurTime() * 20) * 20 * vertigoIntensity
            render.OverrideView({ origin = EyePos() + Vector(x, y, 0), angles = EyeAngles() + Angle(x, y, 0) })
            vertigoIntensity = vertigoIntensity - 0.02
        end
        if pixelateIntensity > 0 then
            pixelateIntensity = pixelateIntensity - 0.02
        end
    end)
    
    -- Приёмники
    net.Receive("ThingDistort", function() tunnelIntensity = 0.6 blurIntensity = 0.4 end)
    net.Receive("ThingBlur", function() blurIntensity = 0.5 end)
    net.Receive("ThingTunnel", function() tunnelIntensity = 0.7 end)
    net.Receive("ThingInvert", function() invertIntensity = 0.7 end)
    net.Receive("ThingDarkness", function() blurIntensity = 0.3 tunnelIntensity = 0.3 blackoutIntensity = 0.4 end)
    net.Receive("ThingFlicker", function() staticIntensity = 0.4 end)
    net.Receive("ThingHeartbeat", function() heartbeatTime = 0.7 end)
    net.Receive("ThingStatic", function() staticIntensity = 0.5 end)
    net.Receive("ThingGlitch", function() invertIntensity = 0.4 staticIntensity = 0.5 end)
    net.Receive("ThingCold", function() coldIntensity = 0.6 end)
    net.Receive("ThingShake", function() shakeIntensity = 0.4 end)
    net.Receive("ThingPull", function() shakeIntensity = 0.3 blurIntensity = 0.3 end)
    net.Receive("ThingBloodScreen", function() bloodIntensity = 0.6 end)
    net.Receive("ThingBlackout", function() blackoutIntensity = 0.7 end)
    net.Receive("ThingVertigo", function() vertigoIntensity = 0.5 end)
    net.Receive("ThingScream", function() shakeIntensity = 0.3 blurIntensity = 0.2 end)
    net.Receive("ThingFear", function() heartbeatTime = 0.5 shakeIntensity = 0.3 end)
    net.Receive("ThingPixelate", function() pixelateIntensity = 0.5 end)
    net.Receive("ThingRandomFlash", function() blackoutIntensity = 0.2 timer.Simple(0.1, function() blackoutIntensity = 0 end) end)
    
    -- Полоска здоровья
    hook.Add("HUDPaint", "NechtoHealthBar", function()
        local ent = LocalPlayer():GetEyeTrace().Entity
        if IsValid(ent) and ent:GetClass() == "nechto" then
            local health = ent:GetNWInt("ThingHealth", 100)
            local maxHealth = ent:GetNWInt("ThingMaxHealth", 100)
            local healthPercent = health / maxHealth
            
            local pos = ent:GetPos() + Vector(0, 0, 100)
            local pos2D = pos:ToScreen()
            
            if pos2D.visible then
                draw.RoundedBox(4, pos2D.x - 50, pos2D.y - 40, 100, 10, Color(0, 0, 0, 200))
                draw.RoundedBox(4, pos2D.x - 50, pos2D.y - 40, 100 * healthPercent, 10, Color(200, 0, 0, 255))
                draw.SimpleText("НЕЧТО - " .. ent:GetNWString("ThingName", "???"), "Default", pos2D.x, pos2D.y - 55, Color(255, 255, 255, 255), 1, 1)
            end
        end
    end)
    
    -- Отрисовка
    function ENT:Draw()
        self:DrawModel()
        local pos = self:GetPos() + Vector(0, 0, 80)
        cam.Start3D2D(pos, Angle(0, 0, 0), 0.15)
            draw.SimpleText("?", "Default", 0, -20, Color(150,150,150,200), 1, 1)
            draw.SimpleText(self:GetNWString("ThingName", "???"), "Default", 0, 5, Color(100,100,100,180), 1, 1)
        cam.End3D2D()
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.Pos = self:GetPos()
            dlight.r = 50 dlight.g = 0 dlight.b = 20
            dlight.Brightness = 3 dlight.Decay = 400 dlight.Size = 500
            dlight.DieTime = CurTime() + 0.1
        end
    end
end

-- ==================================================
-- КОНТЕКСТНОЕ МЕНЮ (ПРАВАЯ КНОПКА + C)
-- ==================================================
local function OpenNechtoMenu()
    local ent = LocalPlayer():GetEyeTrace().Entity
    if not IsValid(ent) or ent:GetClass() != "nechto" then return end
    
    local menu = DermaMenu()
    menu:SetTitle("НЕЧТО - Взаимодействие")
    
    -- Основные действия
    menu:AddOption("🔍 Осмотреть", function()
        net.Start("NechtoInspect")
        net.SendToServer()
    end)
    
    menu:AddOption("💬 Попытаться поговорить", function()
        net.Start("NechtoTalk")
        net.SendToServer()
    end)
    
    menu:AddSpacer()
    
    -- Опасные действия
    local dangerMenu = menu:AddSubMenu("⚠️ ОПАСНЫЕ ДЕЙСТВИЯ ⚠️")
    dangerMenu:AddOption("😨 Отогнать (рискованно)", function()
        net.Start("NechtoShake")
        net.SendToServer()
    end)
    dangerMenu:AddOption("🫣 Прикоснуться (ОЧЕНЬ ОПАСНО!)", function()
        net.Start("NechtoTouch")
        net.SendToServer()
    end)
    dangerMenu:AddOption("📢 Позвать (привлечь внимание)", function()
        net.Start("NechtoCall")
        net.SendToServer()
    end)
    
    menu:AddSpacer()
    
    -- Атака
    local attackMenu = menu:AddSubMenu("⚔️ АТАКОВАТЬ ⚔️")
    attackMenu:AddOption("🔫 Выстрелить в НЕЧТО", function()
        net.Start("NechtoShoot")
        net.SendToServer()
    end)
    attackMenu:AddOption("🗡️ Ударить НЕЧТО", function()
        net.Start("NechtoMelee")
        net.SendToServer()
    end)
    
    menu:AddSpacer()
    
    -- Призыв
    menu:AddOption("🙏 Попросить уйти", function()
        net.Start("NechtoLeave")
        net.SendToServer()
    end)
    
    menu:AddOption("📞 Призвать снова (если ушло)", function()
        net.Start("NechtoRecall")
        net.SendToServer()
    end)
    
    menu:Open()
end

-- Хук на C+ПКМ
hook.Add("PlayerBindPress", "NechtoContextMenu", function(ply, bind, pressed)
    if bind == "+attack2" and input.IsKeyDown(KEY_C) then
        OpenNechtoMenu()
        return true
    end
end)

-- Альтернативный способ: просто ПКМ по энтити
hook.Add("ContextMenuOpen", "NechtoSimpleMenu", function()
    OpenNechtoMenu()
end)

-- Сетевые сообщения для контекстного меню
if SERVER then
    util.AddNetworkString("NechtoInspect")
    util.AddNetworkString("NechtoTalk")
    util.AddNetworkString("NechtoShake")
    util.AddNetworkString("NechtoTouch")
    util.AddNetworkString("NechtoCall")
    util.AddNetworkString("NechtoLeave")
    util.AddNetworkString("NechtoRecall")
    util.AddNetworkString("NechtoShoot")
    util.AddNetworkString("NechtoMelee")
    
    net.Receive("NechtoInspect", function(len, ply)
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 300)) do
            if ent:GetClass() == "nechto" then
                ply:PrintMessage(HUD_PRINTTALK, "Ты чувствуешь, как тьма смотрит в ответ...")
                net.Start("ThingDistort") net.Send(ply)
            end
        end
    end)
    
    net.Receive("NechtoTalk", function(len, ply)
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 300)) do
            if ent:GetClass() == "nechto" then
                local personality = ent:GetPersonality()
                ply:PrintMessage(HUD_PRINTTALK, "НЕЧТО " .. personality.name .. ": " .. personality.phrases[math.random(1, #personality.phrases)])
                if math.random(1, 100) < 30 then ent:DoScare(ply) end
            end
        end
    end)
    
    net.Receive("NechtoShake", function(len, ply)
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 300)) do
            if ent:GetClass() == "nechto" then
                local personality = ent:GetPersonality()
                if math.random(1, 100) < 50 then
                    ply:PrintMessage(HUD_PRINTTALK, "НЕЧТО " .. personality.name .. " ИСЧЕЗАЕТ... НО ПОЯВЛЯЕТСЯ ЗА ТВОЕЙ СПИНОЙ!")
                    ent:SetPos(ply:GetPos() - ply:GetAimVector() * 100)
                    ent:DoScare(ply)
                else
                    ply:PrintMessage(HUD_PRINTTALK, "НЕЧТО " .. personality.name .. " ЗЛИТСЯ ЕЩЁ СИЛЬНЕЕ!")
                    ent:DoScare(ply)
                    ent:DoScare(ply)
                end
            end
        end
    end)
    
    net.Receive("NechtoTouch", function(len, ply)
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 300)) do
            if ent:GetClass() == "nechto" then
                ply:PrintMessage(HUD_PRINTTALK, "ТЫ КОСНУЛСЯ НЕЧТО... Твоя рука прошла сквозь него!")
                ply:SetHealth(ply:Health() - 15)
                net.Start("ThingBloodScreen") net.Send(ply)
                net.Start("ThingShake") net.Send(ply)
                ent:DoScare(ply)
                ent:DoScare(ply)
            end
        end
    end)
    
    net.Receive("NechtoCall", function(len, ply)
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 300)) do
            if ent:GetClass() == "nechto" then
                ply:PrintMessage(HUD_PRINTTALK, "НЕЧТО ПРИБЛИЖАЕТСЯ!")
                ent:SetPos(ply:GetPos() - ply:GetAimVector() * 50)
                ent:DoScare(ply)
            end
        end
    end)
    
    net.Receive("NechtoLeave", function(len, ply)
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 300)) do
            if ent:GetClass() == "nechto" then
                if math.random(1, 100) < 20 then
                    ply:PrintMessage(HUD_PRINTTALK, "НЕЧТО ИСЧЕЗАЕТ... НО ОБЕЩАЕТ ВЕРНУТЬСЯ...")
                    ent:Remove()
                else
                    ply:PrintMessage(HUD_PRINTTALK, "НЕЧТО ИГНОРИРУЕТ ТВОЮ ПРОСЬБУ!")
                    ent:DoScare(ply)
                end
            end
        end
    end)
    
    net.Receive("NechtoRecall", function(len, ply)
        local exists = false
        for _, ent in ipairs(ents.FindByClass("nechto")) do
            if IsValid(ent) then exists = true break end
        end
        if not exists then
            local ent = ents.Create("nechto")
            if IsValid(ent) then
                ent:SetPos(ply:GetPos() + Vector(0, 0, 100))
                ent:Spawn()
                ply:PrintMessage(HUD_PRINTTALK, "ТЫ ПРИЗВАЛ НЕЧТО ОБРАТНО... ОНО ЗЛО!")
            end
        else
            ply:PrintMessage(HUD_PRINTTALK, "НЕЧТО УЖЕ ЗДЕСЬ... ОНО РЯДОМ...")
        end
    end)
    
    net.Receive("NechtoShoot", function(len, ply)
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 500)) do
            if ent:GetClass() == "nechto" then
                local damage = math.random(15, 30)
                ent:TakeDamage(damage, ply)
                ply:PrintMessage(HUD_PRINTTALK, "Ты выстрелил в НЕЧТО! Урон: " .. damage)
            end
        end
    end)
    
    net.Receive("NechtoMelee", function(len, ply)
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 150)) do
            if ent:GetClass() == "nechto" then
                local damage = math.random(10, 20)
                ent:TakeDamage(damage, ply)
                ply:PrintMessage(HUD_PRINTTALK, "Ты ударил НЕЧТО! Урон: " .. damage)
            end
        end
    end)
end

-- Подсказка при наведении
hook.Add("PreDrawHalos", "NechtoHalo", function()
    local tr = LocalPlayer():GetEyeTrace()
    if IsValid(tr.Entity) and tr.Entity:GetClass() == "nechto" then
        halo.Add({tr.Entity}, Color(100, 0, 50, 150), 5, 5, 2, true, true)
        local pos = tr.Entity:GetPos() + Vector(0, 0, 120)
        cam.Start3D2D(pos, Angle(0, LocalPlayer():GetAngles().y - 90, 0), 0.2)
            draw.SimpleText("Нажми C + ПКМ для меню", "Default", 0, 0, Color(255, 200, 100, 255), 1, 1)
            draw.SimpleText("У НЕЧТО " .. tr.Entity:GetNWInt("ThingHealth", 100) .. "/" .. tr.Entity:GetNWInt("ThingMaxHealth", 100) .. " HP", "Default", 0, 20, Color(255, 100, 100, 255), 1, 1)
        cam.End3D2D()
    end
end)