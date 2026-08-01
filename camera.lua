local Camera = {}

function Camera.update(State)
	local cam = State.camera
	local p = State.player

	if not p then
		return
	end

	cam.x = p.x
	cam.y = p.y
end

function Camera.world_to_screen(x, y)
	local cam = State.camera

	return (x - cam.x) * cam.zoom + usagi.GAME_W / 2, (y - cam.y) * cam.zoom + usagi.GAME_H / 2
end

function Camera.screen_to_world(x, y)
	local cam = State.camera

	return (x - usagi.GAME_W / 2) / cam.zoom + cam.x, (y - usagi.GAME_H / 2) / cam.zoom + cam.y
end

-- TODO: update all references to use
-- as an example:
-- local sx, sy = Camera.world_to_screen(p.x, p.y)
-- gfx.circ_fill(sx, sy, p.r * State.camera.zoom, ...)
return Camera
