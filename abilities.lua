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
	-- First hop must reach anything on screen; follow-up hops bridge gaps
	-- between nearby enemies so the chain keeps bouncing.
	local first_range = 520
	local chain_range = 300

	local hit = {}

	local current = {
		x = p.x,
		y = p.y,
	}

	for i = 1, jumps do
		local target = nil
		local closest = i == 1 and first_range or chain_range
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
