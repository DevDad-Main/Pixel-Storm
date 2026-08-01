local Bullets = require("bullets")
local Particles = require("particles")

local Weapons = {}

Weapons.DEF = {
	blaster = {
		name = "Blaster",
		desc = "Reliable all-rounder",
		color = gfx.COLOR_YELLOW,
		damage = 1,
		fire_rate = 0.13,
		bullet_speed = 330,
		count = 1,
		spread = 0,
		pierce = 0,
	},
	spread = {
		name = "Spread Shot",
		desc = "3 pellets, wide arc",
		color = gfx.COLOR_ORANGE,
		damage = 0.7,
		fire_rate = 0.22,
		bullet_speed = 300,
		count = 3,
		spread = 0.22,
		pierce = 0,
	},
	smg = {
		name = "SMG",
		desc = "Very fast, weak dmg",
		color = gfx.COLOR_GREEN,
		damage = 0.5,
		fire_rate = 0.055,
		bullet_speed = 360,
		count = 1,
		spread = 0.06,
		pierce = 0,
	},
	railgun = {
		name = "Railgun",
		desc = "Slow, huge, pierces",
		color = gfx.COLOR_PINK,
		damage = 3.2,
		fire_rate = 0.55,
		bullet_speed = 520,
		count = 1,
		spread = 0,
		pierce = 4,
	},
}

-- Live stats of the equipped weapon (def x level x build multipliers)
function Weapons.resolve(build)
	local id = build.weapons[build.weapon_index]
	local def = Weapons.DEF[id]
	local level = build.weapon_levels[id] or 1
	local lvl_dmg_multip = 1 + (level - 1) * 0.25 -- + 25% damage per weapon level
	return {
		id = id,
		name = def.name,
		color = def.color,
		damage = def.damage * build.stats.damage * lvl_dmg_multip,
		fire_rate = def.fire_rate / build.stats.fire_rate,
		bullet_speed = def.bullet_speed * build.stats.bullet_speed,
		count = def.count + build.stats.bullet_count,
		spread = def.spread,
		pierce = def.pierce + build.stats.pierce,
	}
end

function Weapons.fire(player, build, State, w)
	w = w or Weapons.resolve(build)
	local base = player.aim
	for i = 1, w.count do
		local offset = (i - 1) / math.max(1, w.count - 1) - 0.5
		local ang = base + offset * w.spread * 2 + (math.random() - 0.5) * 0.02
		local bx = player.x + math.cos(ang) * 8
		local by = player.y + math.sin(ang) * 8
		Bullets.spawn(bx, by, ang, w.bullet_speed, false, w.color, w.damage, 1, 2.8, w.pierce)
		Particles.spray(bx, by, ang, 0.4, 2, 50, 0.12, gfx.COLOR_ORANGE, 1)
	end
end

function Weapons.cycle(build, dir)
	local n = #build.weapons
	if n <= 1 then
		return
	end
	build.weapon_index = build.weapon_index + dir
	if build.weapon_index < 1 then
		build.weapon_index = n
	elseif build.weapon_index > n then
		build.weapon_index = 1
	end
end

function Weapons.select(build, slot)
	if slot <= #build.weapons then
		build.weapon_index = slot
	end
end

return Weapons
