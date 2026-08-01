local Particles = require("particles")

local Abilities = {}

local function distance(a, b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end

function Abilities.chain_lightning(State, Enemies)
	local p = State.player

	local damage = 6
	local jumps = 6
	local range = 70

	local hit = {}

	local current = {
		x = p.x,
		y = p.y,
	}

	for i = 1, jumps do
		local target = nil
		local closest = range
		for _, e in ipairs(Enemies.list) do
			if not hit[e] then
				local d = distance(current, e)

				if d < closest then
					closest = d
					target = e
				end
			end
		end

		if not target then
			break
		end

		-- lightning visual
		State.spawn_bolt(current.x, current.y, target.x, target.y, 14, 0.7)

		Particles.burst(target.x, target.y, 12, 60, 0.4, gfx.COLOR_BLUE, 1)

		Enemies.hit(target, damage, nil, State)

		hit[target] = true

		current = target
	end
end

return Abilities
