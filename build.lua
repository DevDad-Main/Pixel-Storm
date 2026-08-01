local Build = {}

function Build.new()
	return {
		weapons = { "blaster" },
		weapon_index = 1,
		weapon_levels = { blaster = 1 },
		stats = {
			damage = 1, -- damage multiplier
			fire_rate = 1, -- attack speed multiplier
			bullet_speed = 1,
			move_speed = 1,
			max_hp = 0, -- bonus max HP
			bullet_count = 0, -- extra bullets per shot
			pierce = 0, -- extra enemy pierce
			ult_gain = 1, -- ult charge rate
		},
		drones = {},
	}
end

function Build.has_weapon(build, id)
	for _, wid in ipairs(build.weapons) do
		if wid == id then
			return true
		end
	end
	return false
end

function Build.maxed(build, id)
	return (build.weapon_levels[id] or 0) >= 5
end

function Build.level_weapon(build, id)
	local level = build.weapon_levels[id] or 0
	build.weapon_levels[id] = math.min(5, level + 1)
	if level == 0 then
		table.insert(build.weapons, id)
	end
	return build.weapon_levels[id]
end

return Build
