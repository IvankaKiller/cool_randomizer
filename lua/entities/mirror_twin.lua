AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Зеркальный Двойник"
ENT.Author = "ВАНЯ"
ENT.Category = "Entities"
ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "CopyStage")
    self:NetworkVar("Int", 1, "CorruptionLevel")
end

if SERVER then
    util.AddNetworkString("MirrorWhisper")
    util.AddNetworkString("MirrorGlitch")
    util.AddNetworkString("MirrorInvert")
    util.AddNetworkString("MirrorCopy")
    util.AddNetworkString("MirrorScream")
    util.AddNetworkString("MirrorShake")
    util.AddNetworkString("MirrorBlood")
    util.AddNetworkString("MirrorBlackout")
    util.AddNetworkString("MirrorHeartbeat")
    util.AddNetworkString("MirrorStatic")
    util.AddNetworkString("MirrorFOV")
    util.AddNetworkString("MirrorGravity")
    util.AddNetworkString("MirrorSlow")
    util.AddNetworkString("MirrorTeleport")
    util.AddNetworkString("MirrorFakeChat")
    util.AddNetworkString("MirrorFakeDamage")
    util.AddNetworkString("MirrorFakeDeath")
    util.AddNetworkString("MirrorWeaponSteal")
    util.AddNetworkString("MirrorVoiceChanger")
    util.AddNetworkString("MirrorHallucination")
    util.AddNetworkString("MirrorClone")
end

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/player/charple.mdl")
        self:SetMaterial("models/shiny")
        self:SetColor(Color(150, 150, 150, 200))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_BBOX)
        
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(true)
            phys:SetMass(50)
        end
        
        self.target = nil
        self.lastSeen = CurTime()
        self.nextMove = CurTime()
        self.nextWhisper = CurTime()
        self.nextEffect = CurTime()
        self.nextCopy = CurTime()
        self.copyStage = 1
        self.corruption = 0
        self:SetCopyStage(1)
        self:SetCorruptionLevel(0)
        
        -- Запоминаем оружие игрока
        self.playerWeapons = {}
        
        -- Выбор цели
        local players = player.GetAll()
        if #players > 0 then
            self.target = players[1]
            self:SetModel(self.target:GetModel())
            local col = self.target:GetColor()
            self:SetColor(Color(255 - col.r, 255 - col.g, 255 - col.b, 200))
        end
    end
end

-- Запись оружия игрока
function ENT:RecordPlayerWeapons()
    if not IsValid(self.target) then return end
    self.playerWeapons = {}
    for _, wep in ipairs(self.target:GetWeapons()) do
        table.insert(self.playerWeapons, wep:GetClass())
    end
end

-- Движение (только когда не смотрят)
function ENT:MoveWhenNotLooking()
    if not IsValid(self.target) then return end
    
    local toEntity = (self:GetPos() - self.target:GetPos()):GetNormalized()
    local lookDir = self.target:GetAimVector()
    local dot = lookDir:Dot(toEntity)
    
    if dot > 0.5 then
        self.lastSeen = CurTime()
        self:SetColor(Color(255, 100, 100, 200))
        self.nextMove = CurTime() + 0.5
    else
        local corruption = self:GetCorruptionLevel()
        local speed = math.max(1, 3 - corruption / 30)
        self:SetColor(Color(150 - corruption, 150 - corruption, 150 - corruption, 200))
        
        if CurTime() > self.nextMove then
            local dist = 300 + corruption * 10
            local newPos = self.target:GetPos() + Vector(
                math.random(-dist, dist),
                math.random(-dist, dist),
                math.sin(CurTime() * 5) * 50
            )
            self:SetPos(newPos)
            self.nextMove = CurTime() + math.random(1, 3) / speed
            
            if corruption > 30 then
                self:EmitSound("npc/fast_zombie/fz_scream1.wav", 50, 100)
            else
                self:EmitSound("player/footsteps/concrete" .. math.random(1,4) .. ".wav", 60, 80)
            end
        end
    end
    
    if CurTime() - self.lastSeen > 3 then
        self:ScareTarget()
        self.lastSeen = CurTime()
    end
end

-- Копирование оружия
function ENT:CopyWeapon()
    if not IsValid(self.target) then return end
    
    local weapons = self.target:GetWeapons()
    if #weapons > 0 then
        local wep = weapons[math.random(1, #weapons)]
        local wepClass = wep:GetClass()
        
        -- Создаём копию оружия у двойника
        local fakeWep = ents.Create(wepClass)
        if IsValid(fakeWep) then
            fakeWep:SetPos(self:GetPos())
            fakeWep:Spawn()
            timer.Simple(5, function() if IsValid(fakeWep) then fakeWep:Remove() end end)
        end
        
        self.target:PrintMessage(HUD_PRINTTALK, "Двойник скопировал твоё оружие: " .. wep:GetPrintName())
        net.Start("MirrorCopy")
        net.Send(self.target)
    end
end

-- Галлюцинации
function ENT:CreateHallucination()
    if not IsValid(self.target) then return end
    
    for i = 1, math.random(3, 7) do
        local dummy = ents.Create("prop_physics")
        if IsValid(dummy) then
            dummy:SetModel(self.target:GetModel())
            dummy:SetPos(self.target:GetPos() + Vector(
                math.random(-600, 600),
                math.random(-600, 600),
                math.sin(CurTime() * 10) * 100
            ))
            dummy:Spawn()
            dummy:SetColor(Color(100, 100, 100, 50 + math.random(0, 100)))
            dummy:SetMaterial("models/shiny")
            timer.Simple(4, function() if IsValid(dummy) then dummy:Remove() end end)
        end
    end
    
    self.target:PrintMessage(HUD_PRINTTALK, "Ты видишь множество СЕБЯ... они смотрят на тебя...")
    net.Start("MirrorHallucination")
    net.Send(self.target)
end

-- Клонирование двойника
function ENT:CreateClone()
    if not IsValid(self.target) then return end
    
    local clone = ents.Create("mirror_twin")
    if IsValid(clone) then
        clone:SetPos(self:GetPos() + Vector(math.random(-200, 200), math.random(-200, 200), 0))
        clone:Spawn()
        clone.target = self.target
        clone:SetModel(self.target:GetModel())
        clone:SetColor(Color(150, 150, 150, 150))
        self.target:PrintMessage(HUD_PRINTTALK, "ДВОЙНИК РАЗДВОИЛСЯ! ТЕПЕРЬ ИХ ДВОЕ!")
    end
end

-- Кража голоса
function ENT:StealVoice()
    if not IsValid(self.target) then return end
    
    local messages = {
        "Помогите!",
        "Кто здесь?",
        "Я здесь!",
        "Не подходи!",
        "Оно рядом..."
    }
    
    local msg = messages[math.random(1, #messages)]
    self.target:PrintMessage(HUD_PRINTTALK, "Твой голос: " .. msg)
    
    for _, p in ipairs(player.GetAll()) do
        if p != self.target then
            p:PrintMessage(HUD_PRINTTALK, self.target:Name() .. ": " .. msg)
        end
    end
    
    net.Start("MirrorVoiceChanger")
    net.Send(self.target)
end

-- Эффекты страха (расширенные)
function ENT:ScareTarget()
    if not IsValid(self.target) then return end
    
    local corruption = self:GetCorruptionLevel()
    corruption = corruption + 1
    self:SetCorruptionLevel(corruption)
    
    local effects = {
        -- Визуальные эффекты
        function()
            net.Start("MirrorGlitch")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "Твой двойник моргнул... но ты не моргал...")
        end,
        function()
            net.Start("MirrorInvert")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "Мир перевернулся...")
        end,
        function()
            net.Start("MirrorFOV")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "Твоё зрение искажается...")
        end,
        function()
            net.Start("MirrorBlackout")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "ТЕМНОТА ПОГЛОЩАЕТ ТЕБЯ!")
        end,
        function()
            net.Start("MirrorStatic")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "Помехи на экране... но это не телевизор...")
        end,
        function()
            net.Start("MirrorBlood")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "Ты чувствуешь кровь на руках... но раны нет...")
        end,
        
        -- Аудио эффекты
        function()
            self.target:EmitSound("npc/fast_zombie/fz_scream1.wav", 70, 60)
            self.target:PrintMessage(HUD_PRINTTALK, "ТВОЙ ДВОЙНИК ИЗДАЁТ КРИК!")
        end,
        function()
            net.Start("MirrorWhisper")
            net.Send(self.target)
            local whispers = {
                "Ты мне нравишься... давай поменяемся?",
                "Твоё тело... такое тёплое...",
                "Скоро ты станешь мной... а я тобой...",
                "Никто не заметит замену...",
                "Твои друзья не увидят разницы..."
            }
            self.target:PrintMessage(HUD_PRINTTALK, "Шёпот: '" .. whispers[math.random(1, #whispers)] .. "'")
        end,
        function()
            net.Start("MirrorHeartbeat")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "Твоё сердце колотится как бешеное...")
        end,
        
        -- Физические эффекты
        function()
            net.Start("MirrorShake")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "Земля дрожит под ногами!")
        end,
        function()
            net.Start("MirrorGravity")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "Гравитация изменилась!")
        end,
        function()
            net.Start("MirrorSlow")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "Ты еле двигаешься...")
        end,
        function()
            net.Start("MirrorTeleport")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "ТЕЛЕПОРТАЦИЯ! ГДЕ Я?")
        end,
        
        -- Психологические эффекты
        function()
            net.Start("MirrorFakeChat")
            net.Send(self.target)
        end,
        function()
            net.Start("MirrorFakeDamage")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "Ты получил урон... ИЛИ ПОКАЗАЛОСЬ?")
        end,
        function()
            net.Start("MirrorFakeDeath")
            net.Send(self.target)
            self.target:PrintMessage(HUD_PRINTTALK, "ТВОЁ СЕРДЦЕ ОСТАНОВИЛОСЬ...")
        end,
        function()
            local newHealth = self.target:Health() - 5
            if newHealth <= 0 then
                self.target:Kill()
            else
                self.target:SetHealth(newHealth)
            end
            self.target:PrintMessage(HUD_PRINTTALK, "Двойник высасывает твою жизнь... -5 HP")
        end,
        
        -- Специальные эффекты (при высоком уровне коррупции)
        function()
            if corruption > 20 then
                self:CopyWeapon()
            end
        end,
        function()
            if corruption > 30 then
                self:CreateHallucination()
            end
        end,
        function()
            if corruption > 40 then
                self:StealVoice()
            end
        end,
        function()
            if corruption > 50 then
                self:CreateClone()
            end
        end,
        function()
            if corruption > 60 then
                net.Start("MirrorWeaponSteal")
                net.Send(self.target)
                local wep = self.target:GetActiveWeapon()
                if IsValid(wep) then
                    self.target:StripWeapon(wep:GetClass())
                    self.target:PrintMessage(HUD_PRINTTALK, "Двойник ЗАБРАЛ ТВОЁ ОРУЖИЕ!")
                end
            end
        end
    }
    
    local effect = effects[math.random(1, #effects)]
    effect()
    
    -- Финальная стадия - игрок проигрывает
    if corruption >= 100 then
        self.target:PrintMessage(HUD_PRINTTALK, "=====================================")
        self.target:PrintMessage(HUD_PRINTTALK, "ДВОЙНИК ЗАНЯЛ ТВОЁ МЕСТО!")
        self.target:PrintMessage(HUD_PRINTTALK, "Ты исчезаешь... прощай...")
        self.target:Kill()
        self:Remove()
    end
end

-- Копирование игрока
function ENT:CopyPlayer()
    if not IsValid(self.target) then return end
    
    self.copyStage = self.copyStage + 1
    self:SetCopyStage(self.copyStage)
    
    if self.copyStage == 2 then
        self.target:PrintMessage(HUD_PRINTTALK, "=====================================")
        self.target:PrintMessage(HUD_PRINTTALK, "Твой двойник начинает КОПИРОВАТЬ ТЕБЯ...")
        self.target:PrintMessage(HUD_PRINTTALK, "Ты замечаешь странные совпадения...")
        self:RecordPlayerWeapons()
    elseif self.copyStage == 3 then
        self.target:PrintMessage(HUD_PRINTTALK, "Твой двойник повторяет ТВОИ ДВИЖЕНИЯ!")
        self:SetPos(self.target:GetPos() + Vector(0, 100, 0))
        net.Start("MirrorCopy")
        net.Send(self.target)
    elseif self.copyStage == 4 then
        self.target:PrintMessage(HUD_PRINTTALK, "Двойник говорит ТВОИМИ СЛОВАМИ!")
        local lastMsg = self.target:GetNWString("LastMessage", "...")
        self.target:PrintMessage(HUD_PRINTTALK, "ДВОЙНИК: " .. lastMsg)
    elseif self.copyStage == 5 then
        self.target:PrintMessage(HUD_PRINTTALK, "Двойник знает ТВОИ МЫСЛИ!")
    elseif self.copyStage == 6 then
        self.target:PrintMessage(HUD_PRINTTALK, "Ты уже не помнишь, кто из вас настоящий...")
        net.Start("MirrorInvert")
        net.Send(self.target)
    elseif self.copyStage == 7 then
        self.target:PrintMessage(HUD_PRINTTALK, "=====================================")
        self.target:PrintMessage(HUD_PRINTTALK, "ДВОЙНИК ПОЧТИ ЗАКОНЧИЛ КОПИРОВАНИЕ!")
        self.target:PrintMessage(HUD_PRINTTALK, "Осталось совсем немного...")
    elseif self.copyStage == 8 then
        self.target:PrintMessage(HUD_PRINTTALK, "Двойник ЗАБЫЛ ТВОЙ СТРАХ!")
    elseif self.copyStage == 9 then
        self.target:PrintMessage(HUD_PRINTTALK, "Ты становишься ПУСТОТОЙ...")
        net.Start("MirrorBlackout")
        net.Send(self.target)
    elseif self.copyStage == 10 then
        self.target:PrintMessage(HUD_PRINTTALK, "=====================================")
        self.target:PrintMessage(HUD_PRINTTALK, "КОПИРОВАНИЕ ЗАВЕРШЕНО!")
        self.target:PrintMessage(HUD_PRINTTALK, "Ты теперь - ДВОЙНИК. А он - ЭТО ТЫ.")
        self.target:Kill()
        self:Remove()
    end
end

-- Запись сообщений игрока
hook.Add("PlayerSay", "MirrorRecord", function(ply, text)
    ply:SetNWString("LastMessage", text)
end)

function ENT:Think()
    if SERVER then
        if not IsValid(self.target) then
            local players = player.GetAll()
            if #players > 0 then
                self.target = players[1]
                self:SetModel(self.target:GetModel())
            else
                self:NextThink(CurTime() + 1)
                return true
            end
        end
        
        self:MoveWhenNotLooking()
        
        if CurTime() > self.nextWhisper then
            self:ScareTarget()
            self.nextWhisper = CurTime() + math.random(10, 20)
        end
        
        if CurTime() > self.nextEffect then
            self:CopyPlayer()
            self.nextEffect = CurTime() + math.random(45, 90)
        end
    end
    
    self:NextThink(CurTime() + 0.1)
    return true
end

function ENT:OnTakeDamage(dmginfo)
    if SERVER then
        local attacker = dmginfo:GetAttacker()
        if IsValid(attacker) and attacker:IsPlayer() then
            local corruption = self:GetCorruptionLevel()
            local damage = dmginfo:GetDamage()
            
            if corruption > 50 then
                attacker:PrintMessage(HUD_PRINTTALK, "Ты ударил двойника... но ТЕБЕ БОЛЬНО!")
                local newHealth = attacker:Health() - damage * 2
                if newHealth <= 0 then
                    attacker:Kill()
                else
                    attacker:SetHealth(newHealth)
                end
            else
                attacker:PrintMessage(HUD_PRINTTALK, "Ты ударил двойника... но он даже не пошевелился!")
                self:ScareTarget()
            end
        end
        dmginfo:SetDamage(0)
    end
    return true
end

function ENT:OnRemove()
    if SERVER and IsValid(self.target) then
        local corruption = self:GetCorruptionLevel()
        self.target:PrintMessage(HUD_PRINTTALK, "=====================================")
        if corruption >= 100 then
            self.target:PrintMessage(HUD_PRINTTALK, "Двойник ЗАНЯЛ ТВОЁ МЕСТО. Прощай...")
        else
            self.target:PrintMessage(HUD_PRINTTALK, "Двойник исчез... но ты чувствуешь, что он ВЕРНЁТСЯ...")
            self.target:PrintMessage(HUD_PRINTTALK, "Твоя коррупция: " .. corruption .. "%")
            local newHealth = self.target:Health() - corruption / 2
            if newHealth <= 0 then
                self.target:Kill()
            else
                self.target:SetHealth(newHealth)
            end
        end
        self.target:PrintMessage(HUD_PRINTTALK, "=====================================")
    end
end

scripted_ents.Register(ENT, "mirror_twin")

-- Консольные команды
concommand.Add("spawn_mirror_twin", function(ply)
    if SERVER then
        local twin = ents.Create("mirror_twin")
        if IsValid(twin) then
            twin:SetPos(ply:GetPos() + Vector(100, 100, 0))
            twin:Spawn()
            ply:PrintMessage(HUD_PRINTTALK, "=====================================")
            ply:PrintMessage(HUD_PRINTTALK, "Ты видишь СВОЁ ОТРАЖЕНИЕ... но оно ДВИГАЕТСЯ...")
            ply:PrintMessage(HUD_PRINTTALK, "=====================================")
        end
    end
end)

concommand.Add("remove_mirror_twin", function(ply)
    if SERVER then
        for _, ent in ipairs(ents.FindByClass("mirror_twin")) do
            ent:Remove()
        end
        ply:PrintMessage(HUD_PRINTTALK, "Двойник исчез... на этот раз...")
    end
end)

concommand.Add("mirror_corruption", function(ply)
    if SERVER then
        for _, ent in ipairs(ents.FindByClass("mirror_twin")) do
            if IsValid(ent) then
                ply:PrintMessage(HUD_PRINTTALK, "Текущий уровень коррупции: " .. ent:GetCorruptionLevel() .. "%")
                ply:PrintMessage(HUD_PRINTTALK, "Стадия копирования: " .. ent:GetCopyStage() .. "/10")
            end
        end
    end
end)

-- Клиентские эффекты
-- Клиентские эффекты
if CLIENT then
    local glitchIntensity = 0
    local heartbeatTime = 0
    local shakeIntensity = 0
    local blackoutIntensity = 0
    local bloodIntensity = 0
    local oldFOV = 90
    
    -- Функция для получения FOV
    local function GetPlayerFOV()
        return LocalPlayer():GetFOV()
    end
    
    hook.Add("RenderScreenspaceEffects", "MirrorEffects", function()
        if glitchIntensity > 0 then
            for i = 1, 100 do
                surface.SetDrawColor(255, 255, 255, math.random(0, 100) * glitchIntensity)
                surface.DrawRect(math.random(0, ScrW()), math.random(0, ScrH()), math.random(1, 5), math.random(1, 5))
            end
            glitchIntensity = glitchIntensity - 0.02
        end
        
        if shakeIntensity > 0 then
            local x = math.sin(CurTime() * 60) * 4 * shakeIntensity
            local y = math.cos(CurTime() * 57) * 4 * shakeIntensity
            local view = {}
            view.origin = EyePos() + Vector(x, y, 0)
            view.angles = EyeAngles()
            view.fov = GetPlayerFOV()
            view.drawviewer = true
            render.RenderView(view)
            shakeIntensity = shakeIntensity - 0.02
        end
        
        if heartbeatTime > 0 then
            if math.sin(CurTime() * 25) > 0.7 then
                DrawMotionBlur(1, 0.4, 0.05)
            end
            heartbeatTime = heartbeatTime - 0.015
        end
        
        if blackoutIntensity > 0 then
            surface.SetDrawColor(0, 0, 0, 255 * blackoutIntensity)
            surface.DrawRect(0, 0, ScrW(), ScrH())
            blackoutIntensity = blackoutIntensity - 0.03
        end
        
        if bloodIntensity > 0 then
            DrawColorModify({
                ["$pp_colour_addr"] = 100,
                ["$pp_colour_addg"] = 0,
                ["$pp_colour_addb"] = 0,
                ["$pp_colour_brightness"] = -10,
                ["$pp_colour_contrast"] = 1.2,
                ["$pp_colour_colour"] = 0.8
            })
            bloodIntensity = bloodIntensity - 0.02
        end
    end)
    
    net.Receive("MirrorGlitch", function() glitchIntensity = 0.5 end)
    net.Receive("MirrorInvert", function() glitchIntensity = 0.3 end)
    net.Receive("MirrorShake", function() shakeIntensity = 0.4 end)
    net.Receive("MirrorHeartbeat", function() heartbeatTime = 0.7 end)
    net.Receive("MirrorBlackout", function() blackoutIntensity = 0.7 end)
    net.Receive("MirrorBlood", function() bloodIntensity = 0.6 end)
    net.Receive("MirrorStatic", function() glitchIntensity = 0.5 end)
    
    net.Receive("MirrorFOV", function()
        oldFOV = LocalPlayer():GetFOV()
        LocalPlayer():SetFOV(30, 0.3)
        timer.Simple(3, function()
            if IsValid(LocalPlayer()) then
                LocalPlayer():SetFOV(oldFOV, 0.5)
            end
        end)
    end)
    
    net.Receive("MirrorGravity", function()
        LocalPlayer():SetGravity(0.3)
        timer.Simple(5, function()
            if IsValid(LocalPlayer()) then
                LocalPlayer():SetGravity(1)
            end
        end)
    end)
    
    net.Receive("MirrorSlow", function()
        local oldWalk = LocalPlayer():GetWalkSpeed()
        local oldRun = LocalPlayer():GetRunSpeed()
        LocalPlayer():SetWalkSpeed(50)
        LocalPlayer():SetRunSpeed(100)
        timer.Simple(5, function()
            if IsValid(LocalPlayer()) then
                LocalPlayer():SetWalkSpeed(oldWalk)
                LocalPlayer():SetRunSpeed(oldRun)
            end
        end)
    end)
    
    net.Receive("MirrorTeleport", function()
        local pos = LocalPlayer():GetPos()
        LocalPlayer():SetPos(pos + Vector(0, 0, 500))
        timer.Simple(0.1, function()
            if IsValid(LocalPlayer()) then
                LocalPlayer():SetPos(pos)
            end
        end)
    end)
    
    net.Receive("MirrorFakeChat", function()
        local fakeMessages = {
            "??? : Ты скоро станешь мной...",
            "??? : Я уже внутри тебя...",
            "??? : Твоё сознание ускользает...",
            "??? : Никто не заметит подмены..."
        }
        chat.AddText(Color(200, 0, 0), fakeMessages[math.random(1, #fakeMessages)])
    end)
    
    net.Receive("MirrorFakeDamage", function()
        surface.PlaySound("player/damage1.wav")
        bloodIntensity = 0.3
    end)
    
    net.Receive("MirrorFakeDeath", function()
        blackoutIntensity = 0.8
        surface.PlaySound("player/drown.wav")
        timer.Simple(2, function() blackoutIntensity = 0 end)
    end)
    
    net.Receive("MirrorWeaponSteal", function()
        LocalPlayer():PrintMessage(HUD_PRINTTALK, "Твоё оружие ИСЧЕЗЛО из рук!")
    end)
    
    net.Receive("MirrorVoiceChanger", function()
        LocalPlayer():PrintMessage(HUD_PRINTTALK, "Твой голос звучит ЧУЖО!")
    end)
    
    net.Receive("MirrorHallucination", function()
        glitchIntensity = 0.4
        shakeIntensity = 0.2
    end)
    
    net.Receive("MirrorClone", function()
        glitchIntensity = 0.6
        shakeIntensity = 0.3
    end)
    
    net.Receive("MirrorCopy", function()
        glitchIntensity = 0.5
    end)
    
    net.Receive("MirrorWhisper", function()
        glitchIntensity = 0.2
        surface.PlaySound("npc/overwatch/radiovoice/silence.wav")
    end)
    
    net.Receive("MirrorScream", function()
        shakeIntensity = 0.3
        surface.PlaySound("npc/fast_zombie/fz_scream1.wav")
    end)
    
    function ENT:Draw()
        self:DrawModel()
        
        local pos = self:GetPos() + Vector(0, 0, 80)
        local copyStage = self:GetCopyStage() or 1
        local corruption = self:GetCorruptionLevel() or 0
        
        cam.Start3D2D(pos, Angle(0, CurTime() * 50, 0), 0.2)
            if copyStage <= 2 then
                draw.SimpleText("ТЕНЬ", "Default", 0, -30, Color(150,150,150,200), 1, 1)
            elseif copyStage <= 4 then
                draw.SimpleText("КОПИЯ", "Default", 0, -30, Color(200,100,100,200), 1, 1)
            elseif copyStage <= 6 then
                draw.SimpleText("ОТРАЖЕНИЕ", "Default", 0, -30, Color(255,50,50,200), 1, 1)
            elseif copyStage <= 8 then
                draw.SimpleText("ЗАМЕНА", "Default", 0, -30, Color(255,0,0,200), 1, 1)
            else
                draw.SimpleText("ТЫ?", "Default", 0, -30, Color(255,0,0,255), 1, 1)
            end
            
            draw.SimpleText("Стадия " .. copyStage .. "/10", "Default", 0, -5, Color(200,200,200,180), 1, 1)
            
            local color
            if corruption < 30 then
                color = Color(0, 255, 0, 180)
            elseif corruption < 60 then
                color = Color(255, 255, 0, 180)
            elseif corruption < 90 then
                color = Color(255, 100, 0, 180)
            else
                color = Color(255, 0, 0, 180)
            end
            draw.SimpleText("Коррупция: " .. corruption .. "%", "Default", 0, 20, color, 1, 1)
        cam.End3D2D()
        
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.Pos = self:GetPos()
            dlight.r = 100 + corruption
            dlight.g = 100 - corruption
            dlight.b = 150 - corruption
            dlight.Brightness = 2
            dlight.Decay = 300
            dlight.Size = 400
            dlight.DieTime = CurTime() + 0.1
        end
    end
end