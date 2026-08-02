-- Example Modules for StarWeaver Ship System

-- Weapon Modules
LaserCannon = Module:extend()

function LaserCannon:init()
    self.super.init(self)
    self.name = "Laser Cannon"
    self.description = "Rapid-fire energy weapon"
    self.type = "weapon"
    self.modifiers = {
        dmg = 1.5,
        aspd = 1.2
    }
    self.ability = {
        name = "Piercing Shot",
        cooldown = 3.0,
        description = "Fire a shot that pierces through enemies"
    }
end

function LaserCannon:on_equip()
    -- Grant piercing shot ability
    if self.ship and self.ship.ship_system then
        self.ship.ship_system.abilities.piercing_shot = {
            ready = true,
            cooldown = 0,
            max_cooldown = 3.0
        }
    end
end

function LaserCannon:on_unequip()
    -- Remove piercing shot ability
    if self.ship and self.ship.ship_system then
        self.ship.ship_system.abilities.piercing_shot = nil
    end
end

MissileLauncher = Module:extend()

function MissileLauncher:init()
    self.super.init(self)
    self.name = "Missile Launcher"
    self.description = "Explosive missiles with area damage"
    self.type = "weapon"
    self.modifiers = {
        dmg = 2.0,
        area_dmg = 1.5,
        aspd = 0.6
    }
    self.ammo_type = "physical"  -- Can be changed to elemental
end

PlasmaRifle = Module:extend()

function PlasmaRifle:init()
    self.super.init(self)
    self.name = "Plasma Rifle"
    self.description = "High-tech plasma weapon"
    self.type = "weapon"
    self.modifiers = {
        dmg = 1.8,
        aspd = 1.0
    }
    self.ammo_type = "plasma"
end

-- Engine Modules
IonThruster = Module:extend()

function IonThruster:init()
    self.super.init(self)
    self.name = "Ion Thruster"
    self.description = "Efficient propulsion system"
    self.type = "engine"
    self.modifiers = {
        move_speed = 1.3
    }
end

FusionDrive = Module:extend()

function FusionDrive:init()
    self.super.init(self)
    self.name = "Fusion Drive"
    self.description = "High-speed propulsion with acceleration burst"
    self.type = "engine"
    self.modifiers = {
        move_speed = 1.5
    }
    self.ability = {
        name = "Speed Burst",
        cooldown = 5.0,
        description = "Temporary speed boost"
    }
end

-- Core Modules
QuantumCore = Module:extend()

function QuantumCore:init()
    self.super.init(self)
    self.name = "Quantum Core"
    self.description = "Advanced power core"
    self.type = "core"
    self.modifiers = {
        dmg = 1.2,
        aspd = 1.1,
        area_dmg = 1.1
    }
    self.ability = {
        name = "Overcharge",
        cooldown = 8.0,
        description = "Temporarily boost all weapon damage"
    }
end

ReactorCore = Module:extend()

function ReactorCore:init()
    self.super.init(self)
    self.name = "Reactor Core"
    self.description = "Stable power generation"
    self.type = "core"
    self.modifiers = {
        hp = 1.3,
        defense = 5
    }
end

-- Utility Modules
ShieldGenerator = Module:extend()

function ShieldGenerator:init()
    self.super.init(self)
    self.name = "Shield Generator"
    self.description = "Energy shield protection"
    self.type = "utility"
    self.modifiers = {
        hp = 1.5,
        defense = 10
    }
    self.ability = {
        name = "Shield Throw",
        cooldown = 6.0,
        description = "Throw your shield as a projectile"
    }
end

DroneBay = Module:extend()

function DroneBay:init()
    self.super.init(self)
    self.name = "Drone Bay"
    self.description = "Launches combat drones"
    self.type = "utility"
    self.modifiers = {
        dmg = 0.8  -- Drones provide additional damage
    }
    self.ability = {
        name = "Drone Command",
        cooldown = 4.0,
        description = "Deploy combat drones"
    }
end

-- Ammo Modules (modify ammo type)
FireAmmo = Module:extend()

function FireAmmo:init()
    self.super.init(self)
    self.name = "Fire Ammo"
    self.description = "Incendiary ammunition"
    self.type = "ammo"
    self.ammo_type = "fire"
end

IceAmmo = Module:extend()

function IceAmmo:init()
    self.super.init(self)
    self.name = "Ice Ammo"
    self.description = "Cryogenic ammunition"
    self.type = "ammo"
    self.ammo_type = "ice"
end

LightningAmmo = Module:extend()

function LightningAmmo:init()
    self.super.init(self)
    self.name = "Lightning Ammo"
    self.description = "Electrically charged ammunition"
    self.type = "ammo"
    self.ammo_type = "lightning"
end

-- Export modules
return {
    LaserCannon = LaserCannon,
    MissileLauncher = MissileLauncher,
    PlasmaRifle = PlasmaRifle,
    IonThruster = IonThruster,
    FusionDrive = FusionDrive,
    QuantumCore = QuantumCore,
    ReactorCore = ReactorCore,
    ShieldGenerator = ShieldGenerator,
    DroneBay = DroneBay,
    FireAmmo = FireAmmo,
    IceAmmo = IceAmmo,
    LightningAmmo = LightningAmmo
}