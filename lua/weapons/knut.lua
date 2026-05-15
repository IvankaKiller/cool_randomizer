--[[
    =============================================
    ГРАВИТАЦИОННЫЙ КНУТ «СКАЙХУК» (Skyhook)
    УЛЬТРА-ВЕРСИЯ С КАСТОМНЫМ РЕНДЕРОМ
    Автор: Лорд Гравитации
    Исправленная версия
    =============================================
    ЛКМ — Гравитационный бросок (притянуть и швырнуть)
    ПКМ — Гравитационная привязка (связать два объекта)
    R — Сменить режим гравитации (Толчок / Притяжение / Вихрь)
    E — Гравитационный рывок (телепорт к объекту / объекта к себе)
    =============================================
]]--

SWEP.PrintName = "Скайхук"
SWEP.Author = "Gravity Lords"
SWEP.Purpose = "Искривляем пространство-время как пластилин."
SWEP.Instructions = "ЛКМ — Бросок | ПКМ — Привязка | R — Режим | E — Рывок"

if CLIENT then
    SWEP.IconOverride = "cool_randomizer/png/grav.png"
    SWEP.WepSelectIcon = surface.GetTextureID("cool_randomizer/vtf/tool")
end

SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Category = "Гравитационные Искажения"

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

SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"
SWEP.ViewModelFOV = 70
SWEP.UseHands = true

-- ============ КАСТОМНЫЙ РЕНДЕР МОДЕЛИ ============
local function DrawGravityWhip(ply, vm)
    if not IsValid(ply) or not IsValid(vm) then return end
    local muzzlePos = vm:GetPos() + vm:GetForward() * 30 + vm:GetUp() * 5

    render.SetMaterial(Material("sprites/physbeam"))
    render.DrawBeam(
        muzzlePos,
        muzzlePos + vm:GetForward() * 50 + Vector(math.sin(CurTime() * 10) * 10, math.cos(CurTime() * 10) * 10, 0),
        8, 0, 1,
        Color(100, 100, 255, 200)
    )

    for i = 1, 3 do
        local angle = CurTime() * 5 + i * 120
        local offset = Vector(math.sin(angle) * 15, math.cos(angle) * 15, 0)
        render.DrawBeam(
            muzzlePos, muzzlePos + offset + vm:GetForward() * 20,
            3, 0, 1,
            Color(150, 150, 255, 150 + math.sin(CurTime() * 8 + i) * 50)
        )
    end
end

local function DrawWorldModelEffects(weapon)
    if not IsValid(weapon) then return end
    local pos = weapon:GetPos()

    render.SetMaterial(Material("sprites/glow04_noz"))
    render.DrawSprite(pos, 40, 40, Color(100, 100, 255, 150 + math.sin(CurTime() * 5) * 50))

    local emitter = ParticleEmitter(pos)
    if emitter then
        for i = 1, 5 do
            local particle = emitter:Add("sprites/glow04_noz", pos + VectorRand() * 20)
            if particle then
                particle:SetVelocity(VectorRand() * 50)
                particle:SetDieTime(1)
                particle:SetStartAlpha(100)
                particle:SetEndAlpha(0)
                particle:SetStartSize(5)
                particle:SetEndSize(15)
                particle:SetColor(100, 100, 255)
                particle:SetGravity(Vector(0, 0, 20))
            end
        end
        emitter:Finish()
    end
end

-- ============ ГРАВИТАЦИОННЫЕ ЭФФЕКТЫ (исправлено - только на сервере) ============
local function SpacetimeDistortion(pos, scale)
    -- Визуальные эффекты работают везде
    local effectdata = EffectData()
    effectdata:SetOrigin(pos)
    effectdata:SetScale(scale)
    util.Effect("cball_explode", effectdata)

    local emitter = ParticleEmitter(pos)
    if emitter then
        for i = 1, 30 do
            local angle = math.rad(i * 12)
            local radius = 50 * (i / 30)
            local pPos = pos + Vector(math.cos(angle) * radius, math.sin(angle) * radius, 0)
            local particle = emitter:Add("sprites/glow04_noz", pPos)
            if particle then
                particle:SetVelocity(Vector(0, 0, 50))
                particle:SetDieTime(1)
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(10)
                particle:SetEndSize(0)
                particle:SetColor(100, 100, 255)
            end
        end
        emitter:Finish()
    end

    -- Свет создаётся только на сервере
    if SERVER then
        local light = ents.Create("light_dynamic")
        if IsValid(light) then
            light:SetPos(pos)
            light:SetKeyValue("brightness", "5")
            light:SetKeyValue("distance", "200")
            light:SetKeyValue("_light", "100 100 255 200")
            light:Spawn()
            light:Activate()
            timer.Simple(0.5, function() if IsValid(light) then light:Remove() end end)
        end
    end
end

local function GravityWave(pos)
    local effectdata = EffectData()
    effectdata:SetOrigin(pos)
    effectdata:SetMagnitude(10)
    effectdata:SetScale(5)
    util.Effect("Explosion", effectdata)

    if SERVER then
        for _, ent in ipairs(ents.FindInSphere(pos, 300)) do
            if IsValid(ent) and ent:GetPhysicsObject():IsValid() then
                local dir = (ent:GetPos() - pos):GetNormalized()
                ent:GetPhysicsObject():ApplyForceCenter(dir * 5000 + Vector(0, 0, 2000))
            end
        end
    end
end

local function CreateBlackHole(pos, ply, wep)
    if wep.BlackHoleActive then return end
    wep.BlackHoleActive = true

    if SERVER then
        local blackHole = ents.Create("prop_physics")
        if not IsValid(blackHole) then wep.BlackHoleActive = false return end

        blackHole:SetModel("models/props_combine/portalball001.mdl")
        blackHole:SetPos(pos)
        blackHole:Spawn()
        blackHole:SetColor(Color(0, 0, 0))
        blackHole:SetMaterial("models/props_combine/portalball001_sheet")
        blackHole:SetRenderMode(RENDERMODE_TRANSALPHA)

        local bhIndex = wep:EntIndex()
        timer.Create("BlackHolePull_" .. bhIndex, 0.1, 50, function()
            if not IsValid(blackHole) then
                timer.Remove("BlackHolePull_" .. bhIndex)
                return
            end

            for _, ent in ipairs(ents.FindInSphere(blackHole:GetPos(), 500)) do
                if IsValid(ent) and ent:GetPhysicsObject():IsValid() and ent ~= blackHole then
                    local dir = (blackHole:GetPos() - ent:GetPos()):GetNormalized()
                    ent:GetPhysicsObject():ApplyForceCenter(dir * 3000)

                    if ent:GetPos():Distance(blackHole:GetPos()) < 50 and (ent:IsPlayer() or ent:IsNPC()) then
                        local dmginfo = DamageInfo()
                        dmginfo:SetDamage(50)
                        dmginfo:SetAttacker(ply)
                        dmginfo:SetInflictor(blackHole)
                        dmginfo:SetDamageType(DMG_CRUSH)
                        ent:TakeDamageInfo(dmginfo)
                    end
                end
            end
            SpacetimeDistortion(blackHole:GetPos(), 2)
        end)

        timer.Simple(5, function()
            wep.BlackHoleActive = false
            if IsValid(blackHole) then
                util.BlastDamage(blackHole, ply, blackHole:GetPos(), 300, 50)
                blackHole:Remove()
            end
        end)
    end
end

-- ============ ИНИЦИАЛИЗАЦИЯ ============
function SWEP:Initialize()
    self:SetHoldType("pistol")

    self.GravityMode = 1
    self.LinkedEnts = {}
    self.RopeConstraints = {}
    self.GravityKills = 0
    self.AntiGravityActive = false
    self.BlackHoleActive = false
end

-- ============ ОСНОВНЫЕ АТАКИ ============
function SWEP:PrimaryAttack()
    local ply = self:GetOwner()
    if not IsFirstTimePredicted() then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    local hitPos = tr.HitPos
    local wep = self

    if IsValid(ent) and not ent:IsWorld() and not ent:IsPlayer() then
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            local pullDir = (ply:GetPos() + Vector(0, 0, 50) - ent:GetPos()):GetNormalized()
            phys:ApplyForceCenter(pullDir * 5000)

            timer.Simple(0.3, function()
                if IsValid(ent) and IsValid(phys) then
                    local throwDir = ply:GetAimVector()

                    if wep.GravityMode == 1 then -- Толчок
                        phys:SetVelocity(throwDir * 2000)
                    elseif wep.GravityMode == 2 then -- Притяжение
                        phys:SetVelocity(throwDir * 500)
                    elseif wep.GravityMode == 3 then -- Вихрь
                        phys:SetVelocity(throwDir * 1000)
                        phys:AddAngleVelocity(Vector(math.random(-500, 500), math.random(-500, 500), math.random(-500, 500)))
                    end

                    SpacetimeDistortion(ent:GetPos(), 1)
                    GravityWave(ent:GetPos())

                    -- Урон объекту при броске
                    if SERVER then
                        util.BlastDamage(wep, ply, ent:GetPos(), 100, 20)
                    end

                    if wep.GravityMode == 3 then
                        timer.Simple(2, function()
                            if IsValid(ent) then
                                wep.GravityKills = wep.GravityKills + 1
                                if wep.GravityKills >= 5 then
                                    wep.GravityKills = 0
                                    CreateBlackHole(ent:GetPos(), ply, wep)
                                end
                            end
                        end)
                    end
                end
            end)
        end
    else
        -- Урон по миру
        if SERVER then
            util.BlastDamage(wep, ply, hitPos, 80, 15)
        end
        SpacetimeDistortion(hitPos, 1)
    end

    self:SetNextPrimaryFire(CurTime() + 0.5)
end

function SWEP:SecondaryAttack()
    local ply = self:GetOwner()
    if not IsFirstTimePredicted() then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    local wep = self

    if IsValid(ent) and not ent:IsWorld() and not ent:IsPlayer() then
        if #wep.LinkedEnts == 0 then
            table.insert(wep.LinkedEnts, ent)
            ply:EmitSound("buttons/button19.wav")
            if CLIENT then
                chat.AddText(Color(100, 100, 255), "[СКАЙХУК] ", Color(255, 255, 255), "Первый объект выбран. Нажми ПКМ на втором объекте.")
            end
        else
            local ent1 = wep.LinkedEnts[1]
            local ent2 = ent

            if IsValid(ent1) and ent1 ~= ent2 then
                if SERVER then
                    constraint.Rope(ent1, ent2, 0, 0,
                        Vector(0, 0, 0), Vector(0, 0, 0),
                        100, 0, 0, 0,
                        "cable/cable.vmt", false)
                end

                SpacetimeDistortion((ent1:GetPos() + ent2:GetPos()) / 2, 2)
                ply:EmitSound("ambient/energy/zap1.wav")

                if #wep.LinkedEnts >= 2 then
                    if CLIENT then
                        chat.AddText(Color(100, 100, 255), "[СКАЙХУК] ", Color(255, 0, 0), "ГРАВИТАЦИОННЫЙ ТРЕУГОЛЬНИК СМЕРТИ!")
                    end
                    timer.Simple(1, function()
                        if IsValid(ent1) and IsValid(ent2) and IsValid(wep.LinkedEnts[2]) then
                            local center = (ent1:GetPos() + ent2:GetPos() + wep.LinkedEnts[2]:GetPos()) / 3
                            if SERVER then
                                util.BlastDamage(wep, ply, center, 200, 30)
                            end
                        end
                    end)
                end
                table.insert(wep.LinkedEnts, ent2)
            end

            if #wep.LinkedEnts >= 3 then
                wep.LinkedEnts = {}
            end
        end
    end

    self:SetNextSecondaryFire(CurTime() + 0.3)
end

-- ============ THINK (Е) ============
function SWEP:Think()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    if ply:KeyDown(IN_USE) then
        local tr = ply:GetEyeTrace()
        local ent = tr.Entity

        if IsValid(ent) and not ent:IsWorld() then
            if ent:IsPlayer() then
                if SERVER and IsFirstTimePredicted() then
                    local targetPos = ent:GetPos() + ent:GetForward() * -100
                    ply:SetPos(targetPos)
                end
                if CLIENT then
                    SpacetimeDistortion(ply:GetPos(), 2)
                end
            else
                local phys = ent:GetPhysicsObject()
                if IsValid(phys) and IsFirstTimePredicted() then
                    phys:SetVelocity((ply:GetPos() + Vector(0, 0, 50) - ent:GetPos()) * 10)
                end
                if CLIENT then
                    SpacetimeDistortion(ent:GetPos(), 0.5)
                end
            end
        end
    end
end

-- ============ РЕНДЕР ============
function SWEP:PreDrawViewModel(vm, weapon, ply)
    render.SetBlend(0.8)
    render.SetColorModulation(0.5, 0.5, 1)
end

function SWEP:PostDrawViewModel(vm, weapon, ply)
    render.SetBlend(1)
    render.SetColorModulation(1, 1, 1)
    DrawGravityWhip(ply, vm)
end

function SWEP:DrawWorldModel(flags)
    self:DrawModel()
    if not IsValid(self:GetOwner()) then
        DrawWorldModelEffects(self)
    end
end

hook.Add("PostDrawOpaqueRenderables", "Skyhook_WorldEffects", function()
    for _, ent in ipairs(ents.FindByClass("weapon_skyhook_gravity")) do
        if IsValid(ent) and not IsValid(ent:GetOwner()) then
            DrawWorldModelEffects(ent)
        end
    end
end)

-- ============ ПЕРЕКЛЮЧЕНИЕ РЕЖИМОВ (исправлено через хук) ============
hook.Add("KeyPress", "Skyhook_ModeSwitch", function(ply, key)
    if key == IN_RELOAD then
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_skyhook_gravity" then
            if not IsFirstTimePredicted() then return end

            wep.GravityMode = wep.GravityMode % 3 + 1

            local modeNames = {"ТОЛЧОК", "ПРИТЯЖЕНИЕ", "ВИХРЬ"}
            local modeColors = {
                Color(255, 100, 100),
                Color(100, 100, 255),
                Color(255, 100, 255)
            }

            if CLIENT then
                chat.AddText(modeColors[wep.GravityMode], "[СКАЙХУК] ", Color(255, 255, 255), "Режим: " .. modeNames[wep.GravityMode] .. " [" .. wep.GravityMode .. "/3]")
            end

            ply:EmitSound("buttons/button14.wav")
            SpacetimeDistortion(ply:GetPos(), 1)
        end
    end
end)

-- ============ ПАСХАЛКИ ============
hook.Add("PlayerSay", "Skyhook_Secrets", function(ply, text)
    if text:lower():find("гравицапа") or text:lower():find("gravitsapa") then
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_skyhook_gravity" then
            wep.AntiGravityActive = not wep.AntiGravityActive

            if wep.AntiGravityActive then
                if SERVER then
                    for _, ent in ipairs(ents.GetAll()) do
                        if IsValid(ent) and ent:GetPhysicsObject():IsValid() then
                            ent:GetPhysicsObject():EnableGravity(false)
                        end
                    end
                end
                chat.AddText(Color(100, 100, 255), "[ГРАВИЦАПА] ", Color(255, 255, 0), "АНТИГРАВИТАЦИЯ АКТИВИРОВАНА! ВСЁ ЛЕТАЕТ!")
                timer.Simple(10, function()
                    if SERVER then
                        for _, ent in ipairs(ents.GetAll()) do
                            if IsValid(ent) and ent:GetPhysicsObject():IsValid() then
                                ent:GetPhysicsObject():EnableGravity(true)
                            end
                        end
                    end
                    wep.AntiGravityActive = false
                    chat.AddText(Color(100, 100, 255), "[ГРАВИЦАПА] ", Color(255, 0, 0), "Гравитация восстановлена.")
                end)
            end
        end
    end
end)

hook.Add("PostDrawOpaqueRenderables", "Skyhook_MoonShot", function()
    if not IsValid(LocalPlayer()) then return end
    local wep = LocalPlayer():GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_skyhook_gravity" then return end

    if LocalPlayer():KeyDown(IN_ATTACK) then
        local tr = LocalPlayer():GetEyeTrace()
        if tr.HitSky then
            SpacetimeDistortion(tr.HitPos, 3)
            if CLIENT then
                chat.AddText(Color(100, 100, 255), "[ЛУННЫЙ КОЛОДЕЦ] ", Color(255, 255, 255), "Гравитационная аномалия в небе!")
            end
        end
    end
end)

-- ============ HUD ============
function SWEP:DrawHUD()
    local x, y = ScrW() / 2, ScrH() - 150
    local modeNames = {"ТОЛЧОК", "ПРИТЯЖЕНИЕ", "ВИХРЬ"}
    local modeColors = {Color(255, 100, 100), Color(100, 100, 255), Color(255, 100, 255)}

    self.GravityMode = self.GravityMode or 1

    draw.SimpleText("🌌 СКАЙХУК v1.0", "DermaLarge", x, y - 60,
        Color(100, 100, 255, 200 + math.sin(CurTime() * 2) * 50), TEXT_ALIGN_CENTER)
    draw.SimpleText("Режим: " .. modeNames[self.GravityMode], "DermaDefault", x, y - 30,
        modeColors[self.GravityMode], TEXT_ALIGN_CENTER)
    draw.SimpleText("Связей: " .. #(self.LinkedEnts or {}) .. "/3", "DermaDefault", x, y - 10,
        Color(100, 100, 255), TEXT_ALIGN_CENTER)

    if (self.GravityKills or 0) > 0 then
        draw.SimpleText("Гравитационных убийств: " .. self.GravityKills .. "/5", "DermaDefault", x, y + 20,
            Color(255, 100, 100), TEXT_ALIGN_CENTER)
    end
    if self.AntiGravityActive then
        draw.SimpleText("⚡ АНТИГРАВИТАЦИЯ АКТИВНА! ⚡", "DermaLarge", x, y + 50,
            Color(255, 255, 0, 255 + math.sin(CurTime() * 10) * 100), TEXT_ALIGN_CENTER)
    end
    if self.BlackHoleActive then
        draw.SimpleText("🌀 ЧЁРНАЯ ДЫРА АКТИВНА! 🌀", "DermaLarge", x, y + 80,
            Color(0, 0, 0, 255 + math.sin(CurTime() * 15) * 100), TEXT_ALIGN_CENTER)
    end
end

function SWEP:DoDrawCrosshair(x, y)
    self.GravityMode = self.GravityMode or 1
    local colors = {Color(255, 100, 100), Color(100, 100, 255), Color(255, 100, 255)}
    local col = colors[self.GravityMode]

    for i = 1, 3 do
        local radius = 10 + i * 10 + math.sin(CurTime() * 5 + i) * 5
        surface.SetDrawColor(col.r, col.g, col.b, 150 - i * 30)
        surface.DrawCircle(x, y, radius, col)
    end
    surface.SetDrawColor(col.r, col.g, col.b, 255)
    surface.DrawRect(x - 2, y - 2, 4, 4)
    return true
end

function SWEP:Holster()
    for _, constraint in ipairs(self.RopeConstraints or {}) do
        if IsValid(constraint) then constraint:Remove() end
    end
    self.RopeConstraints = {}
    self.LinkedEnts = {}
    return true
end

function SWEP:OnRemove()
    self:Holster()
end