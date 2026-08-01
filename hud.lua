local Camera = require("camera")

local HUD = {}
-- #region Local Methods
local function draw_health_bar(p)
	local bw = 60
	gfx.rect(4, 17, bw + 2, 5, gfx.COLOR_DARK_GRAY)
	local hp_frac = p.hp / p.max_hp
	local hc = gfx.COLOR_GREEN
	if hp_frac <= 0.5 then
		hc = gfx.COLOR_YELLOW
	end
	if hp_frac <= 0.25 then
		hc = gfx.COLOR_RED
	end
	gfx.rect_fill(5, 18, util.round(bw * hp_frac), 3, hc)
end

local function draw_shield_bar(p)
	local bw = 55
	gfx.rect(4, 21, bw + 2, 5, gfx.COLOR_DARK_GRAY)
	local hp_frac = p.shield.hp / p.shield.max_hp
	local hc = gfx.COLOR_YELLOW
	if hp_frac <= 0.5 then
		hc = gfx.COLOR_YELLOW
	end
	if hp_frac <= 0.25 then
		hc = gfx.COLOR_RED
	end
	gfx.rect_fill(5, 22, util.round(bw * hp_frac), 3, hc)
end

local function draw_wave_text()
	local wave_t = "WAVE: " .. State.wave
	local ww = usagi.measure_text(wave_t)
	gfx.text(wave_t, usagi.GAME_W - 4 - ww, 3, gfx.COLOR_YELLOW)
end

local function draw_enemies_text(enemy_count)
	local left_t = "ENEMIES: " .. (State.spawn_left + enemy_count)
	local lw = usagi.measure_text(left_t)
	gfx.text(left_t, usagi.GAME_W - 4 - lw, 15, gfx.COLOR_DARK_GRAY)
end
-- #endregion

function HUD.draw_hud(State, enemy_count)
	local p = State.player
	-- NOTE: Potentially inline option, but all text is the same colour
	-- gfx.text("SCORE: " .. tostring(State.score), 4, 3, gfx.COLOR_DARK_GRAY)
	gfx.text("SCORE: ", 4, 3, gfx.COLOR_DARK_GRAY)
	gfx.text(tostring(State.score), 45, 3, gfx.COLOR_WHITE)

	draw_wave_text()
	draw_enemies_text(enemy_count)
	draw_health_bar(p)
	draw_shield_bar(p)
end

function HUD.draw_ult_bar(State)
	local S = State
	local x, y, w, h = 4, usagi.GAME_H - 8, 70, 5
	local full = S.ult >= S.ult_max
	gfx.text("ULT", 4, usagi.GAME_H - 20, full and gfx.COLOR_BLUE or gfx.COLOR_DARK_GRAY)
	if full then
		local blink = util.flash(usagi.elapsed, 4) and gfx.COLOR_WHITE or gfx.COLOR_BLUE
		gfx.text("READY [E]", 30, usagi.GAME_H - 20, blink)
	end
	gfx.rect(x, y, w, h, full and gfx.COLOR_BLUE or gfx.COLOR_DARK_GRAY)
	gfx.rect_fill(x + 1, y + 1, util.round((w - 2) * S.ult / S.ult_max), h - 2, gfx.COLOR_BLUE)
end

function HUD.draw_wave_banner(State)
	local S = State
	if S.break_t <= 0 then
		return
	end
	local box_w = 74
	local bx = usagi.GAME_W / 2 - box_w / 2
	local no_bg_alpha = 0
	gfx.rect_fill(bx, 54, box_w, 26, gfx.COLOR_DARK_BLUE, no_bg_alpha)
	HUD.centered("WAVE " .. (S.wave + 1), 58, gfx.COLOR_WHITE)
	HUD.centered("GET READY", 68, gfx.COLOR_YELLOW)
end

function HUD.draw_texts(State)
	for _, t in ipairs(State.texts) do
		local a = util.clamp(t.life / t.max_life, 0, 1)
		local w, h = usagi.measure_text(t.text)
		local x, y = t.x, t.y
		if t.world then
			x, y = Camera.world_to_screen(t.x, t.y)
		end
		gfx.text(t.text, util.round(x - w / 2), util.round(y - h / 2), t.color, a)
	end
end

function HUD.centered(text, y, color, alpha)
	local w, h = usagi.measure_text(text)
	gfx.text(text, util.round((usagi.GAME_W - w) / 2), y, color, alpha)
end

return HUD
