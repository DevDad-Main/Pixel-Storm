local Bullets = require("bullets")
local Particles = require("particles")
local Player = require("player")
local Shield = require("shield")
local Camera = require("camera")
local World = require("world")
local Pickups = require("pickups")

local Enemies = {}
Enemies.list = {}

-- Movement hooks: given (e, dt, State, sp) return a velocity (vx, vy).
-- A type without `move` homes in on the player.
local function chaser_move(e, dt, State, sp)
	local p = State.player
	local dx, dy = p.x - e.x, p.y - e.y
	local dist = math.max(math.sqrt(dx * dx + dy * dy), 0.001)
	return dx / dist * sp, dy / dist * sp
end

local function fast_move(e, dt, State, sp)
	local p = State.player
	local dx, dy = p.x - e.x, p.y - e.y
	local dist = math.max(math.sqrt(dx * dx + dy * dy), 0.001)
	local nx, ny = dx / dist, dy / dist
	local w = math.sin(e.phase * 3) * 1.2
	return nx * sp - ny * w, ny * sp + nx * w
end

local function shooter_move(e, dt, State, sp)
	local p = State.player
	local dx, dy = p.x - e.x, p.y - e.y
	local dist = math.max(math.sqrt(dx * dx + dy * dy), 0.001)
	local nx, ny = dx / dist, dy / dist
	local target = 72
	local mv = util.clamp((dist - target) / target, -1, 1) * sp
	local vx = nx * mv * 1.4 - ny * math.sin(e.phase) * 14
	local vy = ny * mv * 1.4 + nx * math.sin(e.phase) * 14
	e.fire_t = e.fire_t - dt
	if e.fire_t <= 0 and dist < 195 then
		e.fire_t = 2.2
		State.enemy_shoot(e)
	end
	return vx, vy
end

local function draw_chaser(e, x, y)
	gfx.circ_fill(x, y, util.round(Camera.scale(2)), e.color)
	gfx.px(x, y, gfx.COLOR_DARK_PURPLE)
end

local function draw_fast(e, x, y)
	gfx.rect_fill(x - 1, y - 1, 3, 3, e.color)
	gfx.px(x, y, gfx.COLOR_ORANGE)
end

local function draw_shooter(e, x, y)
	gfx.circ_fill(x, y, util.round(Camera.scale(3)), e.color)
	local eye = util.round(Camera.scale(1.5))
	gfx.px(x + util.round(math.cos(e.eye) * eye), y + util.round(math.sin(e.eye) * eye), gfx.COLOR_WHITE)
end

local function draw_tank(e, x, y)
	gfx.circ_fill(x, y, util.round(Camera.scale(5)), e.color)
	gfx.circ(x, y, util.round(Camera.scale(5)), gfx.COLOR_DARK_BLUE)
	gfx.px(x - 2, y - 1, gfx.COLOR_RED)
	gfx.px(x + 2, y - 1, gfx.COLOR_RED)
end

local function draw_boss(e, x, y)
	gfx.circ_fill(x, y, util.round(Camera.scale(12)), e.color)
	gfx.circ(x, y, util.round(Camera.scale(8)), gfx.COLOR_DARK_BLUE)
	gfx.rect_fill(x - 1, y - 1, 3, 3, gfx.COLOR_DARK_PURPLE)
	gfx.px(x - 3, y - 2, gfx.COLOR_WHITE)
	gfx.px(x + 3, y - 2, gfx.COLOR_WHITE)
	gfx.px(x - 3, y + 2, gfx.COLOR_WHITE)
	gfx.px(x + 3, y + 2, gfx.COLOR_WHITE)
end

-- Adding a new enemy is one row here. `move`/`draw`/`on_kill` are
-- optional; omit them for a plain homing blob with the default draw.
local TYPES = {
	chaser = { hp = 1, speed = 63, r = 2.5, color = gfx.COLOR_PINK, score = 10, damage = 10, draw = draw_chaser },
	fast = {
		hp = 1,
		speed = 120,
		r = 1.5,
		color = gfx.COLOR_YELLOW,
		score = 20,
		damage = 20,
		move = fast_move,
		draw = draw_fast,
	},
	shooter = {
		hp = 2,
		speed = 42,
		r = 3,
		color = gfx.COLOR_BLUE,
		score = 25,
		damage = 25,
		move = shooter_move,
		draw = draw_shooter,
	},
	tank = {
		hp = 8,
		speed = 24,
		r = 5,
		color = gfx.COLOR_DARK_PURPLE,
		score = 50,
		damage = 30,
		move = chaser_move,
		draw = draw_tank,
		on_kill = function(e, State)
			Enemies.spawn("chaser")
			Enemies.spawn("chaser")
		end,
	},
	boss = {
		hp = 40,
		speed = 30,
		r = 13,
		color = gfx.COLOR_RED,
		score = 200,
		damage = 40,
		draw = draw_boss,
		move = function(e, dt, State, sp)
			local vx, vy = chaser_move(e, dt, State, sp * 0.6)
			e.fire_t = e.fire_t - dt
			if e.fire_t <= 0 then
				e.fire_t = 2.2
				State.enemy_shoot(e)
			end
			return vx, vy
		end,
		on_kill = function(e, State)
			effect.screen_shake(0.4, 8)
			effect.hitstop(0.1)
			Particles.burst(e.x, e.y, 40, 120, 0.9, e.color, 2)
			Pickups.spawn(e.x - 10, e.y, "heart")
			Pickups.spawn(e.x + 10, e.y, "energy")
		end,
	},
	bigboss = {
		hp = 220,
		speed = 18,
		r = 16,
		color = gfx.COLOR_DARK_PURPLE,
		score = 800,
		damage = 60,
		move = function(e, dt, State, sp)
			local p = State.player
			local vx, vy = chaser_move(e, dt, State, sp * 0.4)

			-- ability timers (init these in the entry or lazily like this)
			e.spin_t = (e.spin_t or 2) - dt
			if e.spin_t <= 0 then
				e.spin_t = 3
				-- ring of bullets: N shots around the boss
				local n = 12
				for i = 1, n do
					local a = math.pi * 2 * (i - 1) / n
					Bullets.spawn(e.x, e.y, a, 120, true, gfx.COLOR_RED, 10, 2, 4.0)
				end
				effect.screen_shake(0.3, 6)
			end

			e.fire_t = (e.fire_t or 1) - dt
			if e.fire_t <= 0 and math.abs(p.x - e.x) < 400 then
				e.fire_t = 1.6
				State.enemy_shoot(e)
			end
			return vx, vy
		end,
		draw = function(e, x, y)
			-- body
			gfx.circ_fill(x, y, util.round(Camera.scale(15)), e.color)
			gfx.circ(x, y, util.round(Camera.scale(15)), gfx.COLOR_DARK_BLUE)
			-- Limbs sweep as the phase cycles
			local a = e.phase * 1.5
			for i = 0, 3 do
				local la = a + i * math.pi / 2
				local lx = util.round(x + math.cos(la) * Camera.scale(16))
				local ly = util.round(y + math.sin(la) * Camera.scale(16))
				gfx.rect_fill(lx - 1, ly - 1, 3, 3, gfx.COLOR_WHITE)
			end
			gfx.px(x, y, gfx.COLOR_DARK_PURPLE)
		end,
		on_kill = function(e, State)
			effect.screen_shake(0.6, 10)
			effect.hitstop(0.2)
			Particles.burst(e.x, e.y, 60, 160, 1.2, e.color, 3)
			Pickups.spawn(e.x, e.y, "heart")
			Pickups.spawn(e.x - 15, e.y, "heart")
			Pickups.spawn(e.x + 15, e.y, "energy")
		end,
	},
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
	-- Enemies scale with the wave so the player can't out-grow them.
	local w = math.max(1, State.wave or 1)
	local hp_scale = 1 + (w - 1) * 0.15
	local dmg_scale = 1 + (w - 1) * 0.08
	local speed_scale = 1 + math.min(0.4, (w - 1) * 0.02)
	table.insert(Enemies.list, {
		kind = kind,
		x = x,
		y = y,
		r = t.r,
		hp = t.hp * hp_scale,
		max_hp = t.hp * hp_scale,
		speed = t.speed * speed_scale,
		color = t.color,
		score = t.score,
		phase = math.random() * math.pi * 2,
		fire_t = math.random() * 1.5 + 0.5,
		trail_t = 0,
		kx = 0,
		ky = 0,
		knock = 0,
		eye = 0,
		damage = t.damage * dmg_scale,
	})
end

function Enemies.update(dt, State)
	local p = State.player
	for i = #Enemies.list, 1, -1 do
		local e = Enemies.list[i]
		local t = TYPES[e.kind]

		if e.knock > 0 then
			e.knock = e.knock - dt * 6
			if e.knock < 0 then
				e.knock = 0
			end
			e.x = e.x + e.kx * dt
			e.y = e.y + e.ky * dt
		end

		e.phase = e.phase + dt
		e.eye = math.atan(p.y - e.y, p.x - e.x)
		local sp = e.speed * (0.9 + 0.2 * math.sin(e.phase * 2))
		local move = t.move or chaser_move
		local vx, vy = move(e, dt, State, sp)

		e.x = e.x + vx * dt
		e.y = e.y + vy * dt

		-- Planets are solid; enemies slide around them.
		e.x, e.y = World.resolve(e.x, e.y, e.r)

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
	local t = TYPES[e.kind]
	if e.kind == "tank" or e.kind == "boss" then
		effect.screen_shake(e.kind == "boss" and 0.4 or 0.25, e.kind == "boss" and 8 or 4)
		effect.hitstop(e.kind == "boss" and 0.1 or 0.05)
		Particles.burst(e.x, e.y, 24, 90, 0.8, e.color, 2)
	end
	if t and t.on_kill then
		t.on_kill(e, State)
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
			local t = TYPES[e.kind]
			local draw = (t and t.draw) or draw_chaser
			draw(e, x, y)
			if e.max_hp > 1 and e.hp < e.max_hp then
				local w = util.round(Camera.scale(e.r * 2))
				gfx.rect(x - w / 2 - 1, y - e.r - 5, w + 2, 2, gfx.COLOR_DARK_GRAY)
				gfx.rect_fill(x - w / 2, y - e.r - 4, util.round(w * e.hp / e.max_hp), 1, gfx.COLOR_RED)
			end
		end
	end
end

return Enemies
