local Bullets = require("bullets")
local Particles = require("particles")
local Player = require("player")
local Shield = require("shield")
local Camera = require("camera")

local Enemies = {}
Enemies.list = {}

local TYPES = {
	chaser = { hp = 1, speed = 42, r = 2.5, color = gfx.COLOR_PINK, score = 10, damage = 10 },
	fast = { hp = 1, speed = 80, r = 1.5, color = gfx.COLOR_YELLOW, score = 20, damage = 20 },
	shooter = { hp = 2, speed = 28, r = 3, color = gfx.COLOR_BLUE, score = 25, damage = 25 },
	tank = { hp = 8, speed = 16, r = 5, color = gfx.COLOR_DARK_PURPLE, score = 50, damage = 30 },
}

-- Spawn just outside the camera's view so enemies walk into the screen.
local function spawn_pos()
	local vx, vy, vw, vh = Camera.view()
	local m = 16
	local edge = math.random(1, 4)
	if edge == 1 then
		return util.round(vx) - m, util.round(vy) + math.random(0, util.round(vh))
	end
	if edge == 2 then
		return util.round(vx + vw) + m, util.round(vy) + math.random(0, util.round(vh))
	end
	if edge == 3 then
		return util.round(vx) + math.random(0, util.round(vw)), util.round(vy) - m
	end
	return util.round(vx) + math.random(0, util.round(vw)), util.round(vy + vh) + m
end

function Enemies.spawn(kind)
	local t = TYPES[kind]
	local x, y = spawn_pos()
	table.insert(Enemies.list, {
		kind = kind,
		x = x,
		y = y,
		r = t.r,
		hp = t.hp,
		max_hp = t.hp,
		speed = t.speed,
		color = t.color,
		score = t.score,
		phase = math.random() * math.pi * 2,
		fire_t = math.random() * 1.5 + 0.5,
		trail_t = 0,
		kx = 0,
		ky = 0,
		knock = 0,
		eye = 0,
		damage = t.damage,
	})
end

function Enemies.update(dt, State)
	local p = State.player
	for i = #Enemies.list, 1, -1 do
		local e = Enemies.list[i]

		if e.knock > 0 then
			e.knock = e.knock - dt * 6
			if e.knock < 0 then
				e.knock = 0
			end
			e.x = e.x + e.kx * dt
			e.y = e.y + e.ky * dt
		end

		local dx = p.x - e.x
		local dy = p.y - e.y
		local dist = math.max(math.sqrt(dx * dx + dy * dy), 0.001)
		local nx, ny = dx / dist, dy / dist
		e.phase = e.phase + dt
		e.eye = math.atan(dy, dx)

		local sp = e.speed * (0.9 + 0.2 * math.sin(e.phase * 2))
		local vx, vy = nx * sp, ny * sp

		if e.kind == "fast" then
			local w = math.sin(e.phase * 3) * 1.2
			vx = vx - ny * w
			vy = vy + nx * w
		elseif e.kind == "shooter" then
			local target = 48
			local mv = util.clamp((dist - target) / target, -1, 1) * sp
			vx = nx * mv * 1.4 - ny * math.sin(e.phase) * 14
			vy = ny * mv * 1.4 + nx * math.sin(e.phase) * 14
			e.fire_t = e.fire_t - dt
			if e.fire_t <= 0 and dist < 130 then
				e.fire_t = 2.2
				State.enemy_shoot(e)
			end
		end

		e.x = e.x + vx * dt
		e.y = e.y + vy * dt

		e.trail_t = e.trail_t - dt
		if e.trail_t <= 0 then
			e.trail_t = 0.06
			Particles.emit({ x = e.x, y = e.y, count = 1, speed = 2, life = 0.3, color = e.color, size = 1 })
		end

		if p.alive then
			if p.shield and p.shield.active then
				local rsum = e.r + p.shield.radius

				if (e.x - p.x) ^ 2 + (e.y - p.y) ^ 2 < rsum * rsum then
					if Shield.hit(p.shield, e.damage) then
						Particles.burst(e.x, e.y, 12, 70, 0.4, e.color, 1)

						Enemies.kill(e, State)
					end
				end
			elseif p.invuln_t <= 0 then
				local rsum = e.r + p.r

				if (e.x - p.x) ^ 2 + (e.y - p.y) ^ 2 < rsum * rsum then
					Player.hit(p, e.damage, State)
				end
			end
		end
	end
end

function Enemies.hit(e, dmg, bullet, State)
	e.hp = e.hp - dmg
	local ang = bullet and math.atan(e.y - bullet.y, e.x - bullet.x)
		or math.atan(e.y - State.player.y, e.x - State.player.x)
	Particles.spray(e.x, e.y, ang, 0.7, 3, 45, 0.3, gfx.COLOR_WHITE, 1)
	if e.hp <= 0 then
		Enemies.kill(e, State)
	end
end

function Enemies.kill(e, State)
	for i = #Enemies.list, 1, -1 do
		if Enemies.list[i] == e then
			table.remove(Enemies.list, i)
		end
	end
	Particles.burst(e.x, e.y, 16, 70, 0.6, e.color, 1)
	Particles.burst(e.x, e.y, 8, 40, 0.4, gfx.COLOR_WHITE, 1)
	if e.kind == "tank" then
		effect.screen_shake(0.25, 4)
		effect.hitstop(0.05)
		Particles.burst(e.x, e.y, 24, 90, 0.8, e.color, 2)
		Enemies.spawn("chaser")
		Enemies.spawn("chaser")
	else
		effect.screen_shake(0.12, 2)
	end
	State.enemy_killed(e)
end

function Enemies.draw()
	for _, e in ipairs(Enemies.list) do
		if Camera.visible(e.x, e.y, 24) then
			local x, y = Camera.world_to_screen(e.x, e.y)
			x = util.round(x)
			y = util.round(y)
			if e.kind == "chaser" then
				gfx.circ_fill(x, y, util.round(Camera.scale(2)), e.color)
				gfx.px(x, y, gfx.COLOR_DARK_PURPLE)
			elseif e.kind == "fast" then
				gfx.rect_fill(x - 1, y - 1, 3, 3, e.color)
				gfx.px(x, y, gfx.COLOR_ORANGE)
			elseif e.kind == "shooter" then
				gfx.circ_fill(x, y, util.round(Camera.scale(3)), e.color)
				local eye = util.round(Camera.scale(1.5))
				gfx.px(x + util.round(math.cos(e.eye) * eye), y + util.round(math.sin(e.eye) * eye), gfx.COLOR_WHITE)
			else
				gfx.circ_fill(x, y, util.round(Camera.scale(5)), e.color)
				gfx.circ(x, y, util.round(Camera.scale(5)), gfx.COLOR_DARK_BLUE)
				gfx.px(x - 2, y - 1, gfx.COLOR_RED)
				gfx.px(x + 2, y - 1, gfx.COLOR_RED)
			end
			if e.max_hp > 1 and e.hp < e.max_hp then
				local w = util.round(Camera.scale(e.r * 2))
				gfx.rect(x - w / 2 - 1, y - e.r - 5, w + 2, 2, gfx.COLOR_DARK_GRAY)
				gfx.rect_fill(x - w / 2, y - e.r - 4, util.round(w * e.hp / e.max_hp), 1, gfx.COLOR_RED)
			end
		end
	end
end

return Enemies
