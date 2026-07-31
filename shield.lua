local Shield = {}

function Shield.new(max_hp, regen_delay, regen_rate, radius)
	return {
		hp = max_hp,
		max_hp = max_hp,

		regen_delay = regen_delay or 3,
		regen_rate = regen_rate or 20,

		regen_timer = 0,
		active = true,
		radius = radius or 15,
	}
end

function Shield.hit(shield, damage)
	if not shield.active or shield.hp <= 0 then
		return false
	end

	shield.hp = shield.hp - damage
	shield.regen_timer = shield.regen_delay

	if shield.hp <= 0 then
		shield.hp = 0
		shield.active = false
	end

	return true
end

function Shield.update(shield, dt)
	if shield.hp < shield.max_hp then
		if shield.regen_timer > 0 then
			shield.regen_timer = shield.regen_timer - dt
			return
		end

		shield.hp = shield.hp + shield.regen_rate * dt

		if shield.hp > shield.max_hp then
			shield.hp = shield.max_hp
		end
	end

	if shield.hp > 0 then
		shield.active = true
	else
		shield.active = false
	end
end

function Shield.percent(shield)
	return shield.hp / shield.max_hp
end

return Shield
