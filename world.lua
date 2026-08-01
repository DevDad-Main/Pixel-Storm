local Camera = require("camera")

local World = {}

World.planets = {}

local SPOTS = {
	{ 260, 180, 55, "earth" },
	{ 1660, 920, 75, "gas" },
	{ 1500, 170, 40, "moon" },
	{ 320, 940, 48, "saturn" },
	{ 1050, 230, 30, "moon" },
	{ 820, 820, 42, "earth" },
}

function World.generate()
	local list = {}
	for _, s in ipairs(SPOTS) do
		local pl = {
			x = s[1],
			y = s[2],
			r = s[3],
			type = s[4],
			rot = math.random() * math.pi * 2,
			land = {},
			craters = {},
		}
		if pl.type == "earth" then
			local n = 4 + math.random(0, 3)
			for _ = 1, n do
				local a = math.random() * math.pi * 2
				local d = math.random() * s[3] * 0.55
				table.insert(pl.land, {
					math.cos(a) * d,
					math.sin(a) * d,
					s[3] * (0.12 + math.random() * 0.18),
				})
			end
		elseif pl.type == "moon" then
			local n = 2 + math.random(0, 2)
			for _ = 1, n do
				local a = math.random() * math.pi * 2
				local d = math.random() * s[3] * 0.5
				table.insert(pl.craters, {
					math.cos(a) * d,
					math.sin(a) * d,
					util.round(s[3] * (0.1 + math.random() * 0.14)),
				})
			end
		end
		table.insert(list, pl)
	end
	World.planets = list
	return list
end

-- Push-out collision: returns x, y moved out of every planet.
function World.resolve(x, y, r)
	for _ = 1, 2 do
		for _, pl in ipairs(World.planets) do
			local dx = x - pl.x
			local dy = y - pl.y
			local rr = pl.r + r
			local d2 = dx * dx + dy * dy
			if d2 < rr * rr and d2 > 0.0001 then
				local d = math.sqrt(d2)
				x = x + dx / d * (rr - d)
				y = y + dy / d * (rr - d)
			elseif d2 <= 0.0001 then
				x = x + rr
			end
		end
	end
	return x, y
end

-- True if a point overlaps any planet (for bullets).
function World.hits(x, y, r)
	for _, pl in ipairs(World.planets) do
		local dx = x - pl.x
		local dy = y - pl.y
		local rr = pl.r + (r or 0)
		if dx * dx + dy * dy < rr * rr then
			return true
		end
	end
	return false
end

-- Draws one horizontal row of a circle centred at (cx, cy).
local function row(cx, cy, r, dy, color, alpha)
	if math.abs(dy) >= r then
		return
	end
	local hw = math.sqrt(r * r - dy * dy)
	gfx.rect_fill(util.round(cx - hw), util.round(cy + dy), util.round(hw * 2), 1, color, alpha)
end

-- Fills a horizontal band between two y offsets (still clipped to the circle).
local function band(cx, cy, r, dy1, dy2, color, alpha)
	for dy = math.max(-r, dy1), math.min(r, dy2) do
		row(cx, cy, r, dy, color, alpha)
	end
end

-- Darkens the top/bottom rims so a circle reads as a sphere.
local function sphere_shade(cx, cy, r)
	for dy = -r, r do
		local edge = 1 - math.abs(dy) / r
		row(cx, cy, r, dy, gfx.COLOR_BLACK, edge * edge * 0.4)
	end
end

-- Draws one half of a tilted ring (the near half when front=true).
local function draw_ring(cx, cy, r, rot, thick, color, alpha, front)
	local tilt = 0.35
	local c, s = math.cos(rot), math.sin(rot)
	local steps = 64
	local prev_x, prev_y = nil, nil
	for i = 0, steps do
		local a = (i / steps) * math.pi * 2
		local lx = math.cos(a) * r
		local ly = math.sin(a) * r * tilt
		local show = (front and ly > 0) or (not front and ly <= 0)
		if not show then
			prev_x, prev_y = nil, nil
		else
			local wx = lx * c - ly * s
			local wy = lx * s + ly * c
			local sx = cx + wx
			local sy = cy + wy
			if prev_x then
				gfx.line_ex(util.round(prev_x), util.round(prev_y), util.round(sx), util.round(sy), thick, color, alpha)
			end
			prev_x, prev_y = sx, sy
		end
	end
end

local function draw_earth(pl, x, y, r)
	gfx.circ_fill(x, y, r, gfx.COLOR_BLUE)
	for _, lm in ipairs(pl.land) do
		gfx.circ_fill(x + util.round(lm[1]), y + util.round(lm[2]), util.round(lm[3]), gfx.COLOR_DARK_GREEN)
		gfx.circ_fill(x + util.round(lm[1]), y + util.round(lm[2]), util.round(lm[3] * 0.6), gfx.COLOR_GREEN)
	end
	band(x, y, r, -r, -util.round(r * 0.62), gfx.COLOR_WHITE, 0.95)
	band(x, y, r, util.round(r * 0.62), r, gfx.COLOR_WHITE, 0.95)
	sphere_shade(x, y, r)
	gfx.circ_ex(x, y, r, 1, gfx.COLOR_INDIGO, 0.6)
end

local function draw_moon(pl, x, y, r)
	gfx.circ_fill(x, y, r, gfx.COLOR_DARK_GRAY)
	for _, cr in ipairs(pl.craters) do
		gfx.circ_fill(x + cr[1], y + cr[2], cr[3], gfx.COLOR_BROWN, 0.55)
		gfx.circ(x + cr[1], y + cr[2], cr[3], gfx.COLOR_BLACK, 0.5)
		gfx.px(x + cr[1] - cr[3], y + cr[2] - cr[3], gfx.COLOR_WHITE, 0.5)
	end
	sphere_shade(x, y, r)
end

local function draw_saturn(x, y, r)
	gfx.circ_fill(x, y, r, gfx.COLOR_PEACH)
	band(x, y, r, -r, -util.round(r * 0.55), gfx.COLOR_BROWN, 0.4)
	band(x, y, r, -util.round(r * 0.35), -util.round(r * 0.2), gfx.COLOR_ORANGE, 0.35)
	band(x, y, r, util.round(r * 0.1), util.round(r * 0.3), gfx.COLOR_ORANGE, 0.3)
	band(x, y, r, util.round(r * 0.45), util.round(r * 0.7), gfx.COLOR_BROWN, 0.4)
	sphere_shade(x, y, r)
end

local function draw_gas(x, y, r)
	gfx.circ_fill(x, y, r, gfx.COLOR_ORANGE)
	band(x, y, r, -r, -util.round(r * 0.7), gfx.COLOR_PEACH, 0.5)
	band(x, y, r, -util.round(r * 0.45), -util.round(r * 0.3), gfx.COLOR_BROWN, 0.5)
	band(x, y, r, -util.round(r * 0.05), util.round(r * 0.1), gfx.COLOR_PEACH, 0.45)
	band(x, y, r, util.round(r * 0.25), util.round(r * 0.45), gfx.COLOR_BROWN, 0.45)
	band(x, y, r, util.round(r * 0.55), util.round(r * 0.75), gfx.COLOR_DARK_GRAY, 0.4)
	gfx.circ_fill(x + util.round(r * 0.35), y + util.round(r * 0.35), util.round(r * 0.12), gfx.COLOR_RED, 0.6)
	sphere_shade(x, y, r)
end

function World.draw(State)
	local x1, y1 = Camera.world_to_screen(0, 0)
	local x2, y2 = Camera.world_to_screen(Camera.world_w, Camera.world_h)
	gfx.rect(util.round(x1), util.round(y1), util.round(x2 - x1), util.round(y2 - y1), gfx.COLOR_DARK_BLUE, 0.5)

	for _, pl in ipairs(State.planets) do
		if Camera.visible(pl.x, pl.y, pl.r) then
			local x, y = Camera.world_to_screen(pl.x, pl.y)
			x = util.round(x)
			y = util.round(y)
			local r = util.round(Camera.scale(pl.r))

			if pl.type == "saturn" then
				draw_ring(x, y, util.round(r * 1.5), pl.rot, math.max(1, util.round(r * 0.1)), gfx.COLOR_PEACH, 0.9, false)
				draw_ring(x, y, util.round(r * 1.16), pl.rot, math.max(1, util.round(r * 0.08)), gfx.COLOR_PEACH, 0.8, false)
			end

			if pl.type == "earth" then
				draw_earth(pl, x, y, r)
			elseif pl.type == "moon" then
				draw_moon(pl, x, y, r)
			elseif pl.type == "saturn" then
				draw_saturn(x, y, r)
			else
				draw_gas(x, y, r)
			end

			if pl.type == "saturn" then
				draw_ring(x, y, util.round(r * 1.5), pl.rot, math.max(1, util.round(r * 0.1)), gfx.COLOR_PEACH, 0.9, true)
				draw_ring(x, y, util.round(r * 1.16), pl.rot, math.max(1, util.round(r * 0.08)), gfx.COLOR_PEACH, 0.8, true)
			end
		end
	end
end

return World
