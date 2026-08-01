local Build = require("build")
local Drone = require("drone")

local Cards = {}

-- Each card = data + apply(build, State). Weapon cards carry `weapon`.
Cards.POOL = {
	{
		id = "damage",
		name = "Damage Up",
		desc = "+15% damage",
		type = "stat",
		rarity = "common",
		color = gfx.COLOR_RED,
		maxed = function(build)
			return build.stats.damage >= 2
		end,
		apply = function(build)
			build.stats.damage = math.min(2, build.stats.damage + 0.15)
		end,
	},
	{
		id = "fire_rate",
		name = "Rapid Fire",
		desc = "+10% fire rate",
		type = "stat",
		rarity = "common",
		color = gfx.COLOR_YELLOW,
		maxed = function(build)
			return build.stats.fire_rate >= 2
		end,
		apply = function(build)
			build.stats.fire_rate = math.min(2, build.stats.fire_rate + 0.1)
		end,
	},
	{
		id = "bullet_speed",
		name = "Velocity",
		desc = "+18% bullet speed",
		type = "stat",
		rarity = "common",
		color = gfx.COLOR_LIGHT_GRAY,
		maxed = function(build)
			return build.stats.bullet_speed >= 2
		end,
		apply = function(build)
			build.stats.bullet_speed = math.min(2, build.stats.bullet_speed + 0.18)
		end,
	},
	{
		id = "move_speed",
		name = "Adrenaline",
		desc = "+12% move speed",
		type = "stat",
		rarity = "common",
		color = gfx.COLOR_GREEN,
		maxed = function(build)
			return build.stats.move_speed >= 2
		end,
		apply = function(build)
			build.stats.move_speed = math.min(2, build.stats.move_speed + 0.12)
		end,
	},
	{
		id = "max_hp",
		name = "Vitality",
		desc = "+15 max HP, heal",
		type = "stat",
		rarity = "common",
		color = gfx.COLOR_RED,
		maxed = function(build)
			return build.stats.max_hp >= 75
		end,
		apply = function(build, State)
			build.stats.max_hp = math.min(75, build.stats.max_hp + 15)
			State.player.max_hp = math.min(State.player.base_max_hp + 75, State.player.max_hp + 15)
			State.player.hp = math.min(State.player.max_hp, State.player.hp + 15)
		end,
	},
	{
		id = "multi",
		name = "Twin Shot",
		desc = "+1 bullet per shot",
		type = "stat",
		rarity = "rare",
		color = gfx.COLOR_ORANGE,
		maxed = function(build)
			return build.stats.bullet_count >= 3
		end,
		apply = function(build)
			build.stats.bullet_count = math.min(3, build.stats.bullet_count + 1)
		end,
	},
	{
		id = "pierce",
		name = "Piercing Rounds",
		desc = "+1 pierce",
		type = "stat",
		rarity = "rare",
		color = gfx.COLOR_PINK,
		maxed = function(build)
			return build.stats.pierce >= 3
		end,
		apply = function(build)
			build.stats.pierce = math.min(3, build.stats.pierce + 1)
		end,
	},
	{
		id = "ult_gain",
		name = "Focus",
		desc = "+20% ult charge",
		type = "stat",
		rarity = "rare",
		color = gfx.COLOR_BLUE,
		maxed = function(build)
			return build.stats.ult_gain >= 2
		end,
		apply = function(build)
			build.stats.ult_gain = math.min(2, build.stats.ult_gain + 0.2)
		end,
	},

	{
		id = "w_spread",
		name = "Spread Shot",
		desc = "Unlock a wide 3-pellet blaster",
		weapon = "spread",
		type = "weapon",
		rarity = "rare",
		color = gfx.COLOR_ORANGE,
		apply = function(build, State)
			Build.level_weapon(build, "spread")
			build.weapon_index = #build.weapons
		end,
	},
	{
		id = "w_smg",
		name = "SMG",
		desc = "Unlock a very fast, weak SMG",
		weapon = "smg",
		type = "weapon",
		rarity = "rare",
		color = gfx.COLOR_GREEN,
		apply = function(build, State)
			Build.level_weapon(build, "smg")
			build.weapon_index = #build.weapons
		end,
	},
	{
		id = "w_railgun",
		name = "Railgun",
		desc = "Unlock a slow, huge, piercing shot",
		weapon = "railgun",
		type = "weapon",
		rarity = "epic",
		color = gfx.COLOR_PINK,
		apply = function(build, State)
			Build.level_weapon(build, "railgun")
			build.weapon_index = #build.weapons
		end,
	},

	{
		id = "drone",
		name = "Combat Drone",
		desc = "Adds an orbiting auto-turret",
		type = "drone",
		rarity = "epic",
		color = gfx.COLOR_INDIGO,
		apply = function(build, State)
			Drone.add(build, State)
		end,
	},
}

local RARITY_WEIGHT = { common = 60, rare = 30, epic = 10 }

-- Drop cards that can't be taken (owned weapons, maxed-out stats).
function Cards.available(build)
	local out = {}
	for _, card in ipairs(Cards.POOL) do
		local skip = (card.weapon and Build.has_weapon(build, card.weapon)) or (card.maxed and card.maxed(build))
		if not skip then
			table.insert(out, card)
		end
	end
	return out
end

function Cards.roll(amount, build)
	local pool = Cards.available(build)
	local picks = {}
	for _ = 1, amount do
		if #pool == 0 then
			break
		end

		local total = 0
		for _, c in ipairs(pool) do
			total = total + RARITY_WEIGHT[c.rarity]
		end

		local r = math.random() * total
		local idx = 1
		for i, c in ipairs(pool) do
			r = r - RARITY_WEIGHT[c.rarity]
			if r <= 0 then
				idx = i
				break
			end
		end
		table.insert(picks, pool[idx])
		table.remove(pool, idx)
	end
	return picks
end

-- Wraps a description into at most two lines at the given char width.
local function wrap(text, max)
	if #text <= max then
		return { text }
	end
	local cut = max
	for i = max, 1, -1 do
		if text:sub(i, i) == " " then
			cut = i
			break
		end
	end
	return { text:sub(1, cut - 1), text:sub(cut + 1) }
end

function Cards.draw_card(card, x, y, selected, index)
	local w, h = 120, 132
	if selected then
		w, h = 132, 144
	end
	local bx = util.round(x - w / 2)
	local by = util.round(y - h / 2)
	gfx.rect_fill(bx, by, w, h, selected and gfx.COLOR_DARK_GRAY or gfx.COLOR_DARK_BLUE, 0.92)
	local border = selected and (util.flash(usagi.elapsed, 4) and gfx.COLOR_WHITE or card.color) or card.color
	gfx.rect_ex(bx, by, w, h, selected and 2 or 1, border)
	if selected then
		gfx.rect_ex(bx - 2, by - 2, w + 4, h + 4, 1, card.color, 0.35)
	end
	gfx.rect_fill(bx + 4, by + 4, w - 8, 18, card.color, 0.4)
	gfx.text(card.name, bx + 6, by + 7, gfx.COLOR_WHITE)
	gfx.text(card.type:upper(), bx + 6, by + 28, card.color)
	local lines = wrap(card.desc, 20)
	for i, line in ipairs(lines) do
		gfx.text(line, bx + 6, by + 44 + (i - 1) * 9, gfx.COLOR_LIGHT_GRAY)
	end
	gfx.text("[" .. index .. "]", bx + 6, by + h - 12, gfx.COLOR_DARK_GRAY)
end

return Cards
