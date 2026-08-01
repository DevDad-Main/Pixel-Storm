local Particles = require("particles")
local Shield = require("shield")
local Camera = require("camera")
local World = require("world")

local Player = {}

function Player.new()
	return {
		x = Camera.world_w / 2,
		y = Camera.world_h / 2,
		r = 3,
		hp = 100,
		max_hp = 100,
		speed = 142,
		fire_t = 0,
		fire_rate = 0.13,
		invuln_t = 0,
		trail_t = 0,
		alive = true,
		aim = 0,
		shield = Shield.new(100, 3, 10, 25),
	}
end

function Player.update(p, dt, State)
	if not p.alive then
		return
	end
	p.fire_t = p.fire_t - dt
	p.invuln_t = p.invuln_t - dt
	p.trail_t = p.trail_t - dt

	-- NOTE: Shield update
	Shield.update(p.shield, dt)

	local dx = 0
	local dy = 0
	if input.held(input.LEFT) then
		dx = dx - 1
	end
	if input.held(input.RIGHT) then
		dx = dx + 1
	end
	if input.held(input.UP) then
		dy = dy - 1
	end
	if input.held(input.DOWN) then
		dy = dy + 1
	end
	local len = math.sqrt(dx * dx + dy * dy)
	if len > 0 then
		dx = dx / len
		dy = dy / len
	end
	p.x = p.x + dx * p.speed * dt
	p.y = p.y + dy * p.speed * dt

	-- Clamp to the WORLD bounds, not the screen.
	p.x = util.clamp(p.x, p.r + 1, Camera.world_w - p.r - 1)
	p.y = util.clamp(p.y, p.r + 1, Camera.world_h - p.r - 1)

	-- Planets are solid; slide along their surface.
	p.x, p.y = World.resolve(p.x, p.y, p.r)

	-- Mouse is in screen space; convert to world so aim matches the shot.
	local mx, my = input.mouse()
	mx, my = Camera.screen_to_world(mx, my)
	p.aim = math.atan(my - p.y, mx - p.x)

	if (dx ~= 0 or dy ~= 0) and p.trail_t <= 0 then
		p.trail_t = 0.04
		Particles.emit({
			x = p.x,
			y = p.y,
			count = 1,
			speed = 4,
			life = 0.35,
			color = gfx.COLOR_GREEN,
			size = 1,
			drag = 2,
		})
	end

	if input.mouse_held(input.MOUSE_LEFT) and p.fire_t <= 0 then
		p.fire_t = p.fire_rate
		State.shoot(p)
	end
end

function Player.hit(p, dmg, State)
	if p.invuln_t > 0 or not p.alive then
		return
	end

	p.hp = p.hp - dmg
	p.invuln_t = 0.8
	effect.flash(0.25, gfx.COLOR_RED)
	effect.screen_shake(0.2, 3)
	Particles.burst(p.x, p.y, 14, 60, 0.5, gfx.COLOR_RED, 1)
	if p.hp <= 0 then
		p.hp = 0
		p.alive = false
		effect.screen_shake(0.4, 6)
		effect.flash(0.35, gfx.COLOR_RED)
		Particles.burst(p.x, p.y, 40, 90, 0.9, gfx.COLOR_WHITE, 1)
		Particles.burst(p.x, p.y, 30, 70, 0.7, gfx.COLOR_GREEN, 1)
		Particles.emit({ x = p.x, y = p.y, count = 1, speed = 30, life = 0.5, color = gfx.COLOR_YELLOW, size = 6 })
		State.player_died()
	end
end

function Player.draw(p)
	if not p.alive then
		return
	end
	if p.invuln_t > 0 and util.flash(usagi.elapsed, 16) then
		return
	end
	local x, y = Camera.world_to_screen(p.x, p.y)
	x = util.round(x)
	y = util.round(y)
	local barrel = util.round(Camera.scale(6))
	local body = util.round(Camera.scale(3))
	local wing = util.round(Camera.scale(3))

	local bx = x + util.round(math.cos(p.aim) * barrel)
	local by = y + util.round(math.sin(p.aim) * barrel)
	gfx.line_ex(x, y, bx, by, 2, gfx.COLOR_LIGHT_GRAY)
	gfx.circ_fill(x, y, body, gfx.COLOR_GREEN)
	gfx.px(x, y, gfx.COLOR_WHITE)
	local wx = util.round(math.cos(p.aim + math.pi / 2) * wing)
	local wy = util.round(math.sin(p.aim + math.pi / 2) * wing)
	gfx.px(x + wx, y + wy, gfx.COLOR_DARK_GREEN)
	gfx.px(x - wx, y - wy, gfx.COLOR_DARK_GREEN)

	-- NOTE: draw shield
	if p.shield and p.shield.active then
		gfx.circ(x, y, util.round(Camera.scale(p.shield.radius)), gfx.COLOR_TRUE_WHITE)
	end
end

return Player
