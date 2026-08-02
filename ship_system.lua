-- Ship System for StarWeaver Modular Action Roguelite
-- Replaces the snake follower system with modular ship components

ShipSystem = Object:extend()

function ShipSystem:init(ship)
    self.ship = ship
    self.modules = {}  -- Equipped modules (weapons, engines, cores, etc.)
    self.slots = {
        weapon = {},   -- Weapon slots
        engine = {},   -- Engine/speed modules
        core = {},     -- Power/core modules
        utility = {},  -- Utility modules (shields, drones, etc.)
        ammo = {}      -- Ammunition types
    }

    -- Base ship stats
    self.base_stats = {
        hp = 100,
        dmg = 10,
        aspd = 1.0,
        area_dmg = 1.0,
        area_size = 1.0,
        defense = 0,
        move_speed = 100
    }

    -- Modifiers from modules (multiplicative except defense which is additive)
    self.modifiers = {
        hp = 1.0,
        dmg = 1.0,
        aspd = 1.0,
        area_dmg = 1.0,
        area_size = 1.0,
        defense = 0,
        move_speed = 1.0
    }

    -- Active abilities from modules
    self.abilities = {}

    -- Elemental ammo system
    self.ammo_types = {
        physical = { damage_mult = 1.0, effects = {} },
        fire = { damage_mult = 1.2, effects = { burn = true } },
        ice = { damage_mult = 0.9, effects = { slow = true } },
        lightning = { damage_mult = 1.1, effects = { chain = true } },
        plasma = { damage_mult = 1.3, effects = { pierce = true } }
    }

    self.current_ammo = "physical"
end

-- Add a module to the ship
function ShipSystem:add_module(module)
    -- Determine slot type based on module type
    local slot_type = module.type or "utility"

    -- Add to modules list
    table.insert(self.modules, module)

    -- Add to appropriate slot
    if self.slots[slot_type] then
        table.insert(self.slots[slot_type], module)
    end

    -- Set ship reference
    module.ship = self.ship

    -- Apply module effects
    module:on_equip()

    -- Recalculate stats
    self:recalculate_stats()

    return true
end

-- Remove a module from the ship
function ShipSystem:remove_module(module)
    -- Find and remove from modules list
    for i, mod in ipairs(self.modules) do
        if mod == module then
            table.remove(self.modules, i)

            -- Remove from slot
            local slot_type = module.type or "utility"
            if self.slots[slot_type] then
                for j, slot_module in ipairs(self.slots[slot_type]) do
                    if slot_module == module then
                        table.remove(self.slots[slot_type], j)
                        break
                    end
                end
            end

            -- Unequip module
            module:on_unequip()
            module.ship = nil

            -- Recalculate stats
            self:recalculate_stats()

            return true
        end
    end
    return false
end

-- Set ammo type
function ShipSystem:set_ammo_type(ammo_type)
    if self.ammo_types[ammo_type] then
        self.current_ammo = ammo_type
        return true
    end
    return false
end

-- Use an ability if available and ready
function ShipSystem:use_ability(ability_name)
    local ability = self.abilities[ability_name]
    if ability and ability.ready and (ability.cooldown <= 0 or not ability.cooldown) then
        ability.ready = false
        if ability.cooldown then
            ability.cooldown = ability.max_cooldown or ability.cooldown
        end
        return true
    end
    return false
end

-- Update ability cooldowns
function ShipSystem:update_abilities(dt)
    for name, ability in pairs(self.abilities) do
        if not ability.ready and ability.cooldown and ability.cooldown > 0 then
            ability.cooldown = ability.cooldown - dt
            if ability.cooldown <= 0 then
                ability.ready = true
            end
        end
    end
end

-- Calculate final stat value
function ShipSystem:calculate_stat(stat_name, base_value)
    local modifier = self.modifiers[stat_name] or 1.0
    if stat_name == "defense" then
        return base_value + modifier  -- Defense is additive
    else
        return base_value * modifier  -- Others are multiplicative
    end
end

-- Recalculate all stats based on equipped modules
function ShipSystem:recalculate_stats()
    -- Reset modifiers to base values
    for k in pairs(self.modifiers) do
        self.modifiers[k] = (k == "defense" and 0) or 1.0
    end

    -- Clear abilities
    self.abilities = {}

    -- Apply module modifiers and abilities
    for _, module in ipairs(self.modules) do
        -- Apply stat modifiers
        if module.modifiers then
            for stat, value in pairs(module.modifiers) do
                if self.modifiers[stat] ~= nil then
                    if stat == "defense" then
                        self.modifiers[stat] = self.modifiers[stat] + value
                    else
                        self.modifiers[stat] = self.modifiers[stat] * value
                    end
                end
            end
        end

        -- Add abilities
        if module.ability then
            self.abilities[module.ability.name] = {
                ready = true,
                cooldown = 0,
                max_cooldown = module.ability.cooldown or 5.0
            }
        end

        -- Set ammo type if provided
        if module.ammo_type then
            self.current_ammo = module.ammo_type
        end
    end

    -- Apply ammo modifiers
    local ammo = self.ammo_types[self.current_ammo]
    if ammo then
        self.modifiers.dmg = self.modifiers.dmg * ammo.damage_mult
        -- Elemental effects would be applied during damage calculation
    end
end

-- Get final stat value
function ShipSystem:get_stat(stat_name)
    local base = self.base_stats[stat_name] or 0
    return self:calculate_stat(stat_name, base)
end

return ShipSystem