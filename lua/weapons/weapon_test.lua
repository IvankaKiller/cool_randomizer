-- ОФОРМЛЕНИЕ
SWEP.PrintName = "Ручной Противопехотный Гранатомет"
SWEP.Author = "Ваня"
SWEP.Category = "Ванины пушки"
SWEP.Purpose = "Выпускает мощный снаряд, который взрывается при ударе."
SWEP.Instructions = "ЛКМ - Обычные пули | ПКМ - Выстрелить снарядом"
SWEP.WepSelectIcon = WOOWZ.GENERATE_ICON("icons/weapon_test.png")

-- МОДЕЛИ И РУКИ
SWEP.UseHands = true
SWEP.ViewModel = "models/props_c17/doll01.mdl"   -- Вид из рук
SWEP.WorldModel = "models/props_c17/doll01.mdl" -- Вид на земле/у других
SWEP.ViewModelFOV = 65

-- ВИДИМОСТЬ В МЕНЮ (Q)
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

------------------------------------------------------------------
-- НАСТРОЙКИ СТРЕЛЬБЫ (ЛКМ - ПУЛИ)
------------------------------------------------------------------
SWEP.Primary.ClipSize = -1          -- Бесконечная обойма
SWEP.Primary.DefaultClip = -1       -- Бесконечные патроны
SWEP.Primary.Automatic = true       -- Автоматический огонь (зажал и стреляет)
SWEP.Primary.Ammo = "Pistol"        -- Тип патронов (любой, раз уж бесконечные)
SWEP.Primary.Damage = 999999        -- Огromный урон
SWEP.Primary.Recoil = 0             -- Нет отдачи

------------------------------------------------------------------
-- НАСТРОЙКИ РПГ (ПКМ)
------------------------------------------------------------------
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true    -- Одиночный выстрел (лучше для РПГ)
SWEP.Secondary.Ammo = "none"

-- СКОРОСТЬ ПЕРЕЗАРЯДКИ РПГ (ЗАДЕРЖКА МЕЖДУ ВЫСТРЕЛАМИ В СЕКУНДАХ)
local ROCKET_COOLDOWN = 0.01

-- ПЕРЕМЕННАЯ ДЛЯ ЗАДЕРЖКИ
function SWEP:Initialize()
    self.NextRocketShot = 0
    self:SetWeaponHoldType("rpg")
end

-- ПУСТАЯ ПЕРЕЗАРЯДКА (Т.К. ПАТРОНОВ НЕТ)
function SWEP:Reload()
    return false
end

------------------------------------------------------------------
-- ЛКМ: ОГРОМНЫЙ УРОН, НЕТ РАЗБРОСА
------------------------------------------------------------------
function SWEP:PrimaryAttack()

    -- Эффекты выстрела
    self:SetNextPrimaryFire(CurTime())          -- Задержка 0
    --self.Owner:EmitSound("Weapon_Pistol.Single")
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

    -- Отдача камеры (дергается)
    --self.Owner:ViewPunch(Angle(-3, 0, 0))

    -- ВЫСТРЕЛ ПУЛЕЙ
    local bullet = {}
    bullet.Num = 1
    bullet.Src = self.Owner:GetShootPos()
    bullet.Dir = self.Owner:GetAimVector()
    bullet.Spread = Vector(0, 0, 0)        -- Абсолютно точный!
    bullet.Tracer = 1
    bullet.Force = 10000
    bullet.Damage = 999999

    self.Owner:FireBullets(bullet)
end

------------------------------------------------------------------
-- ПКМ: СОЗДАЕТ И ЗАПУСКАЕТ СНАРЯД РПГ
------------------------------------------------------------------
function SWEP:SecondaryAttack()

    -- Проверка задержки (кулдаун)
    if self.NextRocketShot and CurTime() < self.NextRocketShot then return end
    self.NextRocketShot = CurTime() + ROCKET_COOLDOWN

    -- Анимация и звук выстрела
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    --self.Owner:EmitSound("Weapon_RPG.Single")   -- Звук выстрела РПГ
    --self.Owner:ViewPunch(Angle(-10, 0, 0))      -- Сильная отдача

    if (SERVER) then
        self:CreateRocketProjectile()
    end
end

------------------------------------------------------------------
-- ФУНКЦИЯ, СОЗДАЮЩАЯ СНАРЯД
------------------------------------------------------------------
function SWEP:CreateRocketProjectile()
    local function Explode(pos)
        if not IsValid(rocket) then return end
        
        local explosion = ents.Create("env_explosion")
        if IsValid(explosion) then
            explosion:SetPos(pos)
            explosion:SetOwner(owner)
            explosion:Spawn()
            explosion:SetKeyValue("iMagnitude", "400")
            explosion:Fire("Explode", "", 0)
        end
        rocket:Remove()
    end

    local owner = self.Owner
    if (!IsValid(owner)) then return end

    -- 1. СОЗДАЕМ ФИЗИЧЕСКИЙ ОБЪЕКТ (СНАРЯД)
    local rocket = ents.Create("prop_physics")
    if (!IsValid(rocket)) then return end

    -- СТАВИМ МОДЕЛЬ РАКЕТЫ (самая популярная модель снаряда в GMod)
    rocket:SetModel("models/weapons/w_missile_launch.mdl")

    -- ПОЗИЦИЯ ВЫСТРЕЛА (перед стволом, чтобы не застревало в игроке)
    local startPos = owner:GetShootPos()
    local shootDir = owner:GetAimVector()
    rocket:SetPos(startPos + shootDir * 35)

    rocket:SetAngles(shootDir:Angle())
    rocket:Spawn()

    -- 2. ТОЛКАЕМ ЕГО, ЧТОБЫ ОН ЛЕТЕЛ
    local phys = rocket:GetPhysicsObject()
    if (IsValid(phys)) then
        phys:SetVelocity(shootDir * 30000)        -- Скорость полета (3000 - оч. быстро)
        phys:SetMass(25000)                         -- Масса (чтобы не тормозил от ветра)
        -- Вращение для красоты
        phys:AddAngleVelocity(Vector(1000, math.random(-500, 500), math.random(-500, 500)))
    end

    rocket:SetOwner(owner)

    -- 3. ДЕЛАЕМ ТАЙМЕР ДЛЯ ВЗРЫВА (ЧЕРЕЗ 2.5 СЕКУНДЫ)
    timer.Simple(1, function()
        if (IsValid(rocket)) then
            self:ExplodeRocket(rocket, rocket:GetPos())
        end
    end)

    -- 4. ОТСЛЕЖИВАЕМ СТОЛКНОВЕНИЕ (ВЗРЫВ ПРИ ПОПАДАНИИ)
    local lastSpeed = 3000
    local stuckTimer = 0

    rocket:SetThink(function()
        if (!IsValid(rocket)) then return end

        local phys = rocket:GetPhysicsObject()
        if (IsValid(phys)) then
            local curSpeed = phys:GetVelocity():Length()

            -- Если скорость резко упала (меньше 100) - значит во что-то врезался
            if (curSpeed < 100 and lastSpeed > 500) then
                self:ExplodeRocket(rocket, rocket:GetPos())
                return
            end

            -- Если скорость маленькая больше секунды (застрял в стене) - взрываем
            if (curSpeed < 50) then
                stuckTimer = stuckTimer + 0.1
                if (stuckTimer > 1.0) then
                    self:ExplodeRocket(rocket, rocket:GetPos())
                    return
                end
            else
                stuckTimer = 0
            end
            lastSpeed = curSpeed
        end

        rocket:NextThink(CurTime() + 0.05)
        return true
    end, "RocketThink")

    rocket:NextThink(CurTime() + 0.05)
end

------------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ВЗРЫВА
------------------------------------------------------------------
function SWEP:ExplodeRocket(entity, pos)

    if (!IsValid(entity)) then return end

    -- Взрывная сущность
    local explosion = ents.Create("env_explosion")
    if (IsValid(explosion)) then
        explosion:SetPos(pos)
        explosion:SetOwner(self.Owner)
        explosion:Spawn()
        explosion:SetKeyValue("iMagnitude", "400")  -- Сила взрыва (400 - очень мощно)
        explosion:Fire("Explode", "", 0)            -- Запускаем взрыв
    end

    -- Удаляем снаряд
    if (IsValid(entity)) then
        entity:Remove()
    end
end