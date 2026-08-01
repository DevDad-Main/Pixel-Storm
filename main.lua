local Bullets = require("bullets")
local Enemies = require("enemies")
local Particles = require("particles")
local Pickups = require("pickups")
local Player = require("player")
local HUD = require("hud")
local Shield = require("shield")
local Abilities = require("abilities")
local Camera = require("camera")
local World = require("world")
local Build = require("build")
local Weapons = require("weapons")
local Drone = require("drone")
local Draft = require("draft")

function _config()
	---@type Usagi.Config
	return {
		name = "Pixel Storm",
		game_id = "dev.dad.pixelstorm",
		pixel_perfect = true,
		game_width = 960,
		game_height = 540,
	}
end

local function make_bolt(x0, y0, x1, y1, jag)
	local pts = { { x = x0, y = y0 } }
	local dx, dy = x1 - x0, y1 - y0
	local dist = math.max(math.sqrt(dx * dx + dy * dy), 1)
	local nx, ny = -dy / dist, dx / dist
	local segs = 8
	for i = 1, segs - 1 do
		local t = i / segs
		pts[#pts + 1] = {
			x = x0 + dx * t + nx * (math.random() - 0.5) * 2 * jag,
			y = y0 + dy * t + ny * (math.random() - 0.5) * 2 * jag,
		}
	end
	pts[#pts + 1] = { x = x1, y = y1 }
	return pts
end

local function add_text(x, y, text, color, life, world)
	table.insert(State.texts, { x = x, y = y, text = text, color = color, life = life, max_life = life, world = world })
end

local function start_game()
	State.scene = "playing"
	State.build = Build.new()
	State.draft = nil
	State.player = Player.new()
	State.score = 0
	State.wave = 0
	State.kills = 0
	State.texts = {}
	State.spawn_left = 0
	State.spawn_t = 0
	State.break_t = 1.2
	State.death_t = 0
	State.ult = 0
	State.bolts = {}
	Enemies.list = {}
	Bullets.list = {}
	Pickups.list = {}
	Particles.list = {}
	State.camera.x = State.player.x
	State.camera.y = State.player.y
end

local function wave_budget(w)
	return 4 + w * 2
end

local function wave_kinds(w)
	local kinds = { "chaser", "chaser" }
	if w >= 2 then
		kinds[#kinds + 1] = "fast"
	end
	if w >= 3 then
		kinds[#kinds + 1] = "shooter"
	end
	if w >= 4 then
		kinds[#kinds + 1] = "fast"
	end
	if w >= 5 then
		kinds[#kinds + 1] = "shooter"
	end
	if w >= 6 then
		kinds[#kinds + 1] = "tank"
	end
	return kinds
end

local function next_wave()
	local S = State
	S.wave = S.wave + 1
	S.spawn_left = wave_budget(S.wave)
	S.spawn_t = 0.4
	add_text(usagi.GAME_W / 2, 60, "WAVE " .. S.wave, gfx.COLOR_YELLOW, 1.5)
end

local function update_playing(dt)
	local S = State
	local p = S.player

	if S.break_t > 0 then
		S.break_t = S.break_t - dt
		if S.break_t <= 0 then
			next_wave()
		end
	end

	if not p.alive then
		S.death_t = S.death_t + dt
		if S.death_t > 1.2 then
			S.scene = "gameover"
			if S.score > (S.saved.high or 0) then
				S.saved.high = S.score
				usagi.save(S.saved)
			end
		end
		return
	end

	Player.update(p, dt, S)
	Camera.update(S, dt)

	if (input.key_pressed(input.KEY_E) or input.pressed(input.BTN3)) and State.ult >= State.ult_max then
		State.ult_strike()
	end

	if input.key_pressed(input.KEY_F) then
		Pickups.spawn(p.x - 15, p.y - 15, "energy")
	end

	-- Weapon switching: keys 1-3 and the scroll wheel.
	if input.key_pressed(input.KEY_1) then
		Weapons.select(S.build, 1)
	elseif input.key_pressed(input.KEY_2) then
		Weapons.select(S.build, 2)
	elseif input.key_pressed(input.KEY_3) then
		Weapons.select(S.build, 3)
	end
	local scroll = input.mouse_scroll()
	if scroll > 0 then
		Weapons.cycle(S.build, 1)
	elseif scroll < 0 then
		Weapons.cycle(S.build, -1)
	end

	for i = #Bullets.list, 1, -1 do
		local b = Bullets.list[i]

		if b.hostile then
			-- Shield collision
			if p.shield and p.shield.active then
				local rsum = b.size + p.shield.radius

				if (b.x - p.x) ^ 2 + (b.y - p.y) ^ 2 < rsum * rsum then
					if Shield.hit(p.shield, b.dmg) then
						-- NOTE: More like a barrier
						Particles.burst(p.x + (b.x - p.x), p.y + (b.y - p.y), 10, 60, 0.3, gfx.COLOR_BLUE, 1)

						-- optional: make shield impact flash
						effect.screen_shake(0.05, 1)

						table.remove(Bullets.list, i)
					end

					goto continue
				end
			end

			-- Player collision
			local rsum = b.size + p.r

			if (b.x - p.x) ^ 2 + (b.y - p.y) ^ 2 < rsum * rsum then
				Player.hit(p, b.dmg, S)
				Particles.burst(b.x, b.y, 6, 30, 0.3, gfx.COLOR_RED, 1)
				table.remove(Bullets.list, i)
			end
		end

		::continue::
	end

	for i = #Bullets.list, 1, -1 do
		local b = Bullets.list[i]
		if not b.hostile then
			local hit = false
			for j = #Enemies.list, 1, -1 do
				local e = Enemies.list[j]
				if not b.hit[e] then
					local rsum = b.size + e.r
					if (b.x - e.x) ^ 2 + (b.y - e.y) ^ 2 < rsum * rsum then
						Enemies.hit(e, b.dmg, b, S)
						b.hit[e] = true
						if b.pierce > 0 then
							b.pierce = b.pierce - 1
						else
							hit = true
							break
						end
					end
				end
			end
			if hit then
				table.remove(Bullets.list, i)
			end
		end
	end

	Bullets.update(dt)
	Enemies.update(dt, S)
	Pickups.update(dt, S)
	Drone.update(S.build, dt, S)

	if S.spawn_left > 0 and S.break_t <= 0 then
		S.spawn_t = S.spawn_t - dt
		if S.spawn_t <= 0 then
			S.spawn_t = math.max(0.25, 1.1 - S.wave * 0.06)
			local kinds = wave_kinds(S.wave)
			Enemies.spawn(kinds[math.random(#kinds)])
			S.spawn_left = S.spawn_left - 1
		end
	end

	if S.spawn_left == 0 and #Enemies.list == 0 and S.break_t <= 0 then
		Draft.start(S)
	end
end

function _init()
	-- Live reload preserves globals across saved edits but resets locals.
	-- Stash mutable game state in a capitalized global like `State` so it
	-- survives reloads; F5 calls _init again to reset.
	math.randomseed(os.time())
	State = {
		scene = "menu",
		player = nil,
		score = 0,
		wave = 0,
		kills = 0,
		texts = {},
		spawn_left = 0,
		spawn_t = 0,
		break_t = 0,
		death_t = 0,
		ult = 0,
		ult_max = 100,
		bolts = {},
		saved = usagi.load() or {},
		stars = {},
		camera = {
			x = 0,
			y = 0,
			zoom = 1.0,
		},
		planets = World.generate(),
		build = Build.new(),
	}
	for i = 1, 40 do
		-- State.stars[i] = {
		-- 	x = math.random(0, usagi.GAME_W),
		-- 	y = math.random(0, usagi.GAME_H),
		-- d = 0.3 + math.random() * 0.7,
		-- }
		State.stars[i] = {
			x = math.random(0, usagi.GAME_W),
			y = math.random(0, usagi.GAME_H),
			speed = 0.5 + math.random(),
			size = math.random(),
		}
	end

	State.enemy_shoot = function(e)
		local p = State.player
		local ang = math.atan(p.y - e.y, p.x - e.x)
		Particles.burst(e.x + math.cos(ang) * 4, e.y + math.sin(ang) * 4, 4, 20, 0.2, gfx.COLOR_BLUE, 1)
		Bullets.spawn(e.x, e.y, ang, 105, true, gfx.COLOR_RED, 15, 2, 3.0)
	end

	State.spawn_bolt = function(x0, y0, x1, y1, jag, life)
		table.insert(State.bolts, {
			pts = make_bolt(x0, y0, x1, y1, jag or 8),
			life = life or 0.35,
			max_life = life or 0.35,
		})
	end

	State.ult_strike = function()
		State.ult = 0

		effect.flash(0.4, gfx.COLOR_WHITE)
		effect.screen_shake(0.4, 6)
		effect.hitstop(0.08)

		Abilities.chain_lightning(State, Enemies)
	end

	State.enemy_killed = function(e)
		State.score = State.score + e.score
		State.kills = State.kills + 1
		add_text(e.x, e.y - 6, "+" .. e.score, gfx.COLOR_WHITE, 0.8, true)
		if e.kind == "tank" then
			Pickups.spawn(e.x, e.y, "heart")
		end
		if math.random() < 0.10 then
			Pickups.spawn(e.x, e.y, "energy")
		end
		if math.random() < 0.05 then
			Pickups.spawn(e.x, e.y, "heart")
		end
	end

	State.player_died = function() end

	input.set_mouse_visible(false)
end

function _update(dt)
	local S = State
	for _, s in ipairs(S.stars) do
		s.x = s.x - s.speed * 5 * dt

		if s.x < 0 then
			s.x = usagi.GAME_W
			s.y = math.random(0, usagi.GAME_H)
		end
	end

	for i = #S.bolts, 1, -1 do
		S.bolts[i].life = S.bolts[i].life - dt
		if S.bolts[i].life <= 0 then
			table.remove(S.bolts, i)
		end
	end

	if S.scene == "playing" then
		update_playing(dt)
	elseif S.scene == "draft" then
		local card = Draft.update(S)
		if card then
			card.apply(S.build, S)
			S.draft = nil
			S.scene = "playing"
			next_wave()
		end
	elseif S.scene == "menu" or S.scene == "gameover" then
		if input.pressed(input.BTN1) then
			start_game()
		end
	end

	Particles.update(dt)
	for i = #S.texts, 1, -1 do
		local t = S.texts[i]
		t.life = t.life - dt
		t.y = t.y - 12 * dt
		if t.life <= 0 then
			table.remove(S.texts, i)
		end
	end
end

local function draw_background()
	-- NOTE: Drawn Grid logic, remove for now
	-- for x = 0, usagi.GAME_W, 16 do
	-- 	gfx.line(x, 0, x, usagi.GAME_H, gfx.COLOR_DARK_BLUE, 0.2)
	-- end
	-- for y = 0, usagi.GAME_H, 16 do
	-- 	gfx.line(0, y, usagi.GAME_W, y, gfx.COLOR_DARK_BLUE, 0.2)
	-- end
	for _, s in ipairs(State.stars) do
		gfx.px(
			util.round(s.x),
			util.round(s.y),
			s.size > 0.5 and gfx.COLOR_WHITE or gfx.COLOR_LIGHT_GRAY,
			0.3 + s.speed * 0.2
		)
		-- gfx.px(util.round(s.x), util.round(s.y), gfx.COLOR_LIGHT_GRAY, 0.2 + s.d * 0.5)
	end
end

local function draw_bolts()
	for _, b in ipairs(State.bolts) do
		local a = util.clamp(b.life / b.max_life, 0, 1)

		local pts = b.pts

		for i = 2, #pts do
			local sx1, sy1 = Camera.world_to_screen(pts[i - 1].x, pts[i - 1].y)
			local sx2, sy2 = Camera.world_to_screen(pts[i].x, pts[i].y)
			local x1 = util.round(sx1)
			local y1 = util.round(sy1)
			local x2 = util.round(sx2)
			local y2 = util.round(sy2)

			-- glow fades quickly
			gfx.line(x1, y1, x2, y2, gfx.COLOR_BLUE, a * 0.35)

			-- body
			gfx.line(x1, y1, x2, y2, gfx.COLOR_YELLOW, a * 0.7)

			-- core stays bright longer
			local core = math.min(1, a * 1.5)

			gfx.line(x1, y1, x2, y2, gfx.COLOR_WHITE, core)
		end
	end
end

-- local function draw_bolts()
-- 	for _, b in ipairs(State.bolts) do
-- 		local a = util.clamp(b.life / b.max_life, 0.4, 1)

-- 		local pts = b.pts

-- 		for i = 2, #pts do
-- 			if math.random() < 0.8 then
-- 				gfx.line(
-- 					util.round(pts[i - 1].x),
-- 					util.round(pts[i - 1].y),
-- 					util.round(pts[i].x),
-- 					util.round(pts[i].y),
-- 					gfx.COLOR_WHITE,
-- 					a
-- 				)
-- 				gfx.line(
-- 					util.round(pts[i - 1].x),
-- 					util.round(pts[i - 1].y),
-- 					util.round(pts[i].x),
-- 					util.round(pts[i].y),
-- 					gfx.COLOR_WHITE,
-- 					a
-- 				)
-- 			end
-- 		end
-- 	end
-- end

local function draw_crosshair()
	local mx, my = input.mouse()
	local x = util.round(mx)
	local y = util.round(my)
	local p = State.player
	if p.alive then
		local px, py = Camera.world_to_screen(p.x, p.y)
		gfx.line(util.round(px), util.round(py), x, y, gfx.COLOR_WHITE, 0.15)
	end
	gfx.px(x, y, gfx.COLOR_WHITE)
	gfx.px(x + 1, y, gfx.COLOR_WHITE)
	gfx.px(x - 1, y, gfx.COLOR_WHITE)
	gfx.px(x, y + 1, gfx.COLOR_WHITE)
	gfx.px(x, y - 1, gfx.COLOR_WHITE)
end

local function draw_menu()
	local S = State
	HUD.centered("PIXEL STORM", 36, gfx.COLOR_GREEN)
	HUD.centered("a twin-stick pixel arena", 50, gfx.COLOR_LIGHT_GRAY)
	gfx.text("WASD / arrows   move", 10, 96, gfx.COLOR_DARK_GRAY)
	gfx.text("mouse   aim", 10, 106, gfx.COLOR_DARK_GRAY)
	gfx.text("hold click   fire", 10, 116, gfx.COLOR_DARK_GRAY)
	gfx.text("E    Lightning Storm", 10, 126, gfx.COLOR_DARK_GRAY)
	local btn = input.mapping_for(input.BTN1) or "Z"
	local prompt = "Press " .. btn .. " to start"
	local blink = util.flash(usagi.elapsed, 2) and gfx.COLOR_WHITE or gfx.COLOR_DARK_GRAY
	HUD.centered(prompt, 140, blink)
	if S.saved.high and S.saved.high > 0 then
		gfx.text("HIGH SCORE: " .. S.saved.high, 4, 3, gfx.COLOR_YELLOW)
	end
end

local function draw_gameover()
	local S = State
	HUD.centered("GAME OVER", 40, gfx.COLOR_RED)
	HUD.centered("SCORE: " .. S.score, 58, gfx.COLOR_WHITE)
	if S.score >= (S.saved.high or 0) and S.score > 0 then
		HUD.centered("NEW HIGH SCORE!", 72, gfx.COLOR_YELLOW)
	else
		HUD.centered("HIGH SCORE: " .. (S.saved.high or 0), 72, gfx.COLOR_YELLOW)
	end
	HUD.centered("WAVES SURVIVED: " .. S.wave, 86, gfx.COLOR_LIGHT_GRAY)
	HUD.centered("KILLS: " .. S.kills, 98, gfx.COLOR_LIGHT_GRAY)
	local btn = input.mapping_for(input.BTN1) or "Z"
	local prompt = "Press " .. btn .. " to restart"
	local blink = util.flash(usagi.elapsed, 2) and gfx.COLOR_WHITE or gfx.COLOR_DARK_GRAY
	HUD.centered(prompt, 122, blink)
end

function _draw(dt)
	gfx.clear(gfx.COLOR_BLACK)
	draw_background()
	if State.scene == "menu" then
		draw_menu()
	elseif State.scene == "playing" then
		World.draw(State)
		Pickups.draw()
		Enemies.draw()
		Player.draw(State.player)
		Bullets.draw()

		HUD.draw_texts(State)
		HUD.draw_hud(State, #Enemies.list)
		HUD.draw_ult_bar(State)
		HUD.draw_wave_banner(State)

		draw_bolts()

		draw_crosshair()
	elseif State.scene == "draft" then
		World.draw(State)
		Pickups.draw()
		Enemies.draw()
		Player.draw(State.player)
		Bullets.draw()
		Drone.draw(State.build)
		HUD.draw_texts(State)
		Draft.draw(State)
	elseif State.scene == "gameover" then
		World.draw(State)
		Pickups.draw()
		Enemies.draw()
		Bullets.draw()

		HUD.draw_texts(State)

		draw_gameover()
	end
	Particles.draw()
	-- draw_bolts()
end
