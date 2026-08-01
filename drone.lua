local Bullets = require("bullets")
local Enemies = require("enemies")

local Drone = {}

local MAX_DRONES = 3

function Drone.add(build, State)
	if #build.drones >= MAX_DRONES then
		build.drone_level = (build.drone_level or 1) + 1
	else
		table.insert(build.drones, {
			angle = math.random() * math.pi * 2,
			orbit = 28,
			speed = 1.6,
			fire_t = 1,
			fire_rate = 0.45,
		})
	end
end

function Drone.update(build, dt, State)
	local p = State.player
	local level = build.drone_level or 1
	for _, d in ipairs(build.drones) do
		d.angle = d.angle + d.speed * dt
		d.x = p.x + math.cos(d.angle) * d.orbit
		d.y = p.y + math.sin(d.angle) * d.orbit
		d.fire_t = d.fire_t - dt
		if d.fire_t <= 0 then
			d.fire_t = d.fire_rate
			local target = nil
			local best = math.huge
			for _, e in ipairs(Enemies.list) do
				local dx, dy = e.x - d.x, e.y - d.y
				local d2 = dx * dx + dy * dy
				if d2 < best then
					best = d2
					target = e
				end
			end
			if target then
				local ang = math.atan(target.y - d.y, target.x - d.x)
				local dmg = 0.6 * build.stats.damage * level
				Bullets.spawn(d.x, d.y, ang, 300, false, gfx.COLOR_INDIGO, dmg, 1, 0.9)
			end
		end
	end
end

function Drone.draw(build)
	local Camera = require("camera")
	for _, d in ipairs(build.drones) do
		local x, y = Camera.world_to_screen(d.x, d.y)
		x = util.round(x)
		y = util.round(y)
		-- Drone body
		gfx.px(x + 1, y, gfx.COLOR_INDIGO)
		gfx.px(x - 1, y, gfx.COLOR_INDIGO)
		gfx.px(x, y + 1, gfx.COLOR_INDIGO)
		gfx.px(x, y - 1, gfx.COLOR_INDIGO)
		gfx.px(x, y, gfx.COLOR_WHITE)
	end
end

return Drone
