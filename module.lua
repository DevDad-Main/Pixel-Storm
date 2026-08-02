-- Base Module class for ShipSystem
Module = Object:extend()

function Module:init()
    self.ship = nil
    self.name = "Undefined Module"
    self.description = "No description"
    self.modifiers = {}  -- Stat modifiers this module provides
    self.ability = nil   -- Special ability this module grants
    self.ammo_type = nil -- Ammo type this module provides
    self.type = "utility" -- Default type
end

function Module:on_equip()
    -- Called when module is equipped
    if self.on_equip_callback then
        self:on_equip_callback()
    end
end

function Module:on_unequip()
    -- Called when module is unequipped
    if self.on_unequip_callback then
        self:on_unequip_callback()
    end
end

return Module