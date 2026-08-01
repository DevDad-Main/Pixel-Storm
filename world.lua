local Camera = require("camera")

local World = {}

local PALETTE = {
	gfx.COLOR_DARK_PURPLE,
	gfx.COLOR_INDIGO,
	gfx.COLOR_DARK_BLUE,
	gfx.COLOR_BROWN,
	gfx.COLOR_DARK_GREEN,
	gfx.COLOR_DARK_GRAY,
}

-- Fixed spots inside the 1920x1080 world (avoid the player spawn at center).
local SPOTS = {
	{ 260, 180, 55 },
	{ 1660, 920, 75 },
	{ 1500, 170, 40 },
	{ 320, 940, 48 },
	{ 1050, 230, 30 },
	{ 820, 820, 42 },
}

function World.generate()
	local list = {}
	for _, s in ipairs(SPOTS) do
		table.insert(list, {
			x = s[1],
			y = s[2],
			r = s[3],
			color = PALETTE[math.random(#PALETTE)],
			ring = math.random() < 0.5,
		})
	end
	return list
end

function World.draw(State)
	-- World boundary line, so you can feel the map edge.
	local x1, y1 = Camera.world_to_screen(0, 0)
	local x2, y2 = Camera.world_to_screen(Camera.world_w, Camera.world_h)
	gfx.rect(util.round(x1), util.round(y1), util.round(x2 - x1), util.round(y2 - y1), gfx.COLOR_DARK_BLUE, 0.5)

	for _, pl in ipairs(State.planets) do
		if Camera.visible(pl.x, pl.y, pl.r) then
			local x, y = Camera.world_to_screen(pl.x, pl.y)
			x = util.round(x)
			y = util.round(y)
			local r = util.round(Camera.scale(pl.r))
			gfx.circ_fill(x, y, r, pl.color)
			gfx.circ(x, y, r, gfx.COLOR_BLACK, 0.4)
			gfx.px(x - util.round(r * 0.4), y - util.round(r * 0.4), gfx.COLOR_WHITE, 0.6)
			if pl.ring then
				gfx.circ_ex(x, y, util.round(r * 1.5), 1, gfx.COLOR_LIGHT_GRAY, 0.4)
				gfx.circ_ex(x, y, util.round(r * 1.8), 1, gfx.COLOR_LIGHT_GRAY, 0.2)
			end
		end
	end
end

return World
