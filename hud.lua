local Camera = require("camera")
local Weapons = require("weapons")

local HUD = {}

-- UI font multiplier. Monogram is a bitmap font: keep it an integer.
HUD.SCALE = 2
local SC = HUD.SCALE
local LH = SC * 16 -- scaled line height

local function text(t, x, y, color, alpha)
	gfx.text_ex(t, util.round(x), util.round(y), SC, 0, color, alpha or 1)
end

HUD.text = text

-- #region Local Methods
local function draw_health_bar(p)
	local bw = 110
	gfx.rect(4, 40, bw + 4, 9, gfx.COLOR_DARK_GRAY)
	local hp_frac = p.hp / p.max_hp
	local hc = gfx.COLOR_GREEN
	if hp_frac <= 0.5 then
		hc = gfx.COLOR_YELLOW
	end
	if hp_frac <= 0.25 then
		hc = gfx.COLOR_RED
	end
	gfx.rect_fill(5, 41, util.round(bw * hp_frac), 7, hc)
end

local function draw_shield_bar(p)
	local bw = 100
	gfx.rect(4, 51, bw + 4, 9, gfx.COLOR_DARK_GRAY)
	local hp_frac = p.shield.hp / p.shield.max_hp
	local hc = gfx.COLOR_YELLOW
	if hp_frac <= 0.5 then
		hc = gfx.COLOR_YELLOW
	end
	if hp_frac <= 0.25 then
		hc = gfx.COLOR_RED
	end
	gfx.rect_fill(5, 52, util.round(bw * hp_frac), 7, hc)
end

local function draw_wave_text()
	local wave_t = "WAVE: " .. State.wave
	local ww = usagi.measure_text(wave_t) * SC
	text(wave_t, usagi.GAME_W - 4 - ww, 4, gfx.COLOR_YELLOW)
end

local function draw_enemies_text(enemy_count)
	local left_t = "ENEMIES: " .. (State.spawn_left + enemy_count)
	local lw = usagi.measure_text(left_t) * SC
	text(left_t, usagi.GAME_W - 4 - lw, 36, gfx.COLOR_DARK_GRAY)
end
-- #endregion

function HUD.draw_hud(State, enemy_count)
	local p = State.player
	local w = usagi.measure_text("SCORE: ") * SC
	text("SCORE: ", 4, 4, gfx.COLOR_DARK_GRAY)
	text(tostring(State.score), 4 + w, 4, gfx.COLOR_WHITE)
	draw_wave_text()
	draw_enemies_text(enemy_count)
	draw_health_bar(p)
	draw_shield_bar(p)
end

function HUD.draw_weapon(State)
	local build = State.build
	local n = #build.weapons
	if n == 0 then
		return
	end
	local idx = build.weapon_index
	local x, y = 4, 70
	if n > 1 then
		local prev = idx - 1
		if prev < 1 then
			prev = n
		end
		text(Weapons.DEF[build.weapons[prev]].name, x, y + LH * 0.3, gfx.COLOR_DARK_GRAY)
	end
	local def = Weapons.DEF[build.weapons[idx]]
	local level = build.weapon_levels[build.weapons[idx]] or 1
	gfx.rect_fill(x, y + LH + 7, 12, 12, def.color)
	text(def.name .. " Lv" .. level, x + 16, y + LH, gfx.COLOR_WHITE)
	if n > 1 then
		local nextw = idx + 1
		if nextw > n then
			nextw = 1
		end
		text(Weapons.DEF[build.weapons[nextw]].name, x, y + LH * 1.6, gfx.COLOR_DARK_GRAY)
	end
end

function HUD.draw_ult_bar(State)
	local S = State
	local x, y, w, h = 4, usagi.GAME_H - 40, 140, 8
	local full = S.ult >= S.ult_max
	local ty = usagi.GAME_H - LH - 40
	text("ULT", 4, ty, full and gfx.COLOR_BLUE or gfx.COLOR_DARK_GRAY)
	if full then
		local blink = util.flash(usagi.elapsed, 4) and gfx.COLOR_WHITE or gfx.COLOR_BLUE
		text("READY [E]", 48, ty, blink)
	end
	gfx.rect(x, y, w, h, full and gfx.COLOR_BLUE or gfx.COLOR_DARK_GRAY)
	gfx.rect_fill(x + 1, y + 1, util.round((w - 2) * S.ult / S.ult_max), h - 2, gfx.COLOR_BLUE)
end

function HUD.draw_wave_banner(State)
	local S = State
	if S.break_t <= 0 then
		return
	end
	local box_w = 160
	local bx = usagi.GAME_W / 2 - box_w / 2
	gfx.rect_fill(bx, 44, box_w, 64, gfx.COLOR_DARK_BLUE, 0)
	HUD.centered("WAVE " .. (S.wave + 1), 48, gfx.COLOR_WHITE)
	HUD.centered("GET READY", 80, gfx.COLOR_YELLOW)
end

function HUD.draw_texts(State)
	for _, t in ipairs(State.texts) do
		local a = util.clamp(t.life / t.max_life, 0, 1)
		local x, y = t.x, t.y
		if t.world then
			x, y = Camera.world_to_screen(t.x, t.y)
		end
		local w, h = usagi.measure_text(t.text)
		text(t.text, util.round(x - w * SC / 2), util.round(y - h * SC / 2), t.color, a)
	end
end

function HUD.centered(t, y, color, alpha)
	local w = usagi.measure_text(t) * SC
	text(t, util.round((usagi.GAME_W - w) / 2), y, color, alpha)
end

return HUD
