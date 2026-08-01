local Particles = require("particles")
local Camera = require("camera")
local World = require("world")

local Bullets = {}
Bullets.list = {}

function Bullets.spawn(x, y, angle, speed, hostile, color, dmg, size, life, pierce, hit)
	table.insert(Bullets.list, {
		x = x,
		y = y,
		px = x,
		py = y,
		vx = math.cos(angle) * speed,
		vy = math.sin(angle) * speed,
		hostile = hostile,
		color = color,
		dmg = dmg,
		size = size or 1,
		life = life or 1.0,
		trail_t = 0,
		pierce = pierce or 0,
		hit = {},
	})
end

function Bullets.update(dt)
	local list = Bullets.list
	for i = #list, 1, -1 do
		local b = list[i]
		b.px = b.x
		b.py = b.y
		b.life = b.life - dt
		b.x = b.x + b.vx * dt
		b.y = b.y + b.vy * dt
		b.trail_t = b.trail_t - dt
		if b.trail_t <= 0 then
			b.trail_t = 0.02
			Particles.emit({ x = b.x, y = b.y, count = 1, speed = 4, life = 0.25, color = b.color, size = 1, shrink = false })
		end
		if World.hits(b.x, b.y, b.size) then
			Particles.burst(b.x, b.y, 5, 40, 0.25, gfx.COLOR_ORANGE, 1)
			table.remove(list, i)
		elseif b.life <= 0 or not Camera.visible(b.x, b.y, 80) then
			table.remove(list, i)
		end
	end
end

function Bullets.draw()
	for _, b in ipairs(Bullets.list) do
		local x, y = Camera.world_to_screen(b.x, b.y)
		x = util.round(x)
		y = util.round(y)
		if b.size > 1 then
			local s = util.round(Camera.scale(b.size))
			gfx.rect_fill(x - s, y - s, s * 2, s * 2, b.color)
		else
			gfx.px(x, y, b.color)
			gfx.px(x, y, gfx.COLOR_WHITE)
		end
	end
end

return Bullets
