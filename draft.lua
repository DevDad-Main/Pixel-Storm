local Bullets = require("bullets")
local Cards = require("cards")
local HUD = require("hud")

local Draft = {}

-- Ease-out-back: overshoots past 1 and then settles on 1.
local function ease_out_back(t)
	local c1 = 1.70158
	local c3 = c1 + 1
	local u = t - 1
	return 1 + c3 * u * u * u + c1 * u * u
end

function Draft.start(State)
	State.draft = {
		cards = Cards.roll(3, State.build),
		hover = 1,
		t0 = usagi.elapsed,
	}
	State.scene = "draft"
	-- small heal so the transition feels rewarding
	State.player.hp = math.min(State.player.max_hp, State.player.hp + 15)
	-- clear stray frozen bullets for a clean frame.
	Bullets.list = {}
end

-- Returns the chosen card, or nil while still browsing.
function Draft.update(State)
	local d = State.draft
	local n = #d.cards
	if input.key_pressed(input.KEY_1) then
		d.hover = 1
	elseif input.key_pressed(input.KEY_2) then
		d.hover = 2
	elseif input.key_pressed(input.KEY_3) then
		d.hover = 3
	end
	if input.key_pressed(input.KEY_LEFT) then
		d.hover = util.wrap(d.hover - 1, 1, n + 1)
	end
	if input.key_pressed(input.KEY_RIGHT) then
		d.hover = util.wrap(d.hover + 1, 1, n + 1)
	end
	if input.key_pressed(input.KEY_ENTER) or input.key_pressed(input.KEY_SPACE) or input.pressed(input.BTN1) then
		return d.cards[d.hover]
	end
	return nil
end

function Draft.draw(State)
	local d = State.draft
	gfx.rect_fill(0, 0, usagi.GAME_W, usagi.GAME_H, gfx.COLOR_BLACK, 0.6)

	local w, gap = 120, 12
	local total = #d.cards * w + (#d.cards - 1) * gap
	local x0 = usagi.GAME_W / 2 - total / 2 + w / 2
	local base_y = usagi.GAME_H / 2

	for i, card in ipairs(d.cards) do
		local t = util.clamp((usagi.elapsed - d.t0 - (i - 1) * 0.08) / 0.4, 0, 1)
		local y = base_y + (1 - ease_out_back(t)) * 40
		y = y + math.sin(usagi.elapsed * 2 + i * 1.3) * 2 * t
		if i == d.hover then
			y = y - 5
		end
		Cards.draw_card(card, x0 + (i - 1) * (w + gap), y, i == d.hover, i)
	end

	HUD.centered("CHOOSE AN UPGRADE", 36, gfx.COLOR_YELLOW)
	HUD.centered("WAVE " .. (State.wave + 1) .. " APPROACHING", 68, gfx.COLOR_WHITE)
	HUD.centered("Left/Right or 1-3 to select - Space/Click to take", usagi.GAME_H - 44, gfx.COLOR_LIGHT_GRAY)
end

return Draft
