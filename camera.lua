local Camera = {}

-- The playable world is larger than the screen. The camera follows the
-- player, and every draw/aim/spawn call converts between world and screen
-- space through here. Screen space = the 640x360 render target.
Camera.world_w = 1920
Camera.world_h = 1080

function Camera.update(State, dt)
	local cam = State.camera
	local p = State.player

	if not p then
		return
	end

	-- Frame-rate independent smooth follow. t goes 0 -> 1 fast at first,
	-- then eases: cam moves most of the remaining distance each frame.
	local t = 1 - math.pow(0.001, dt)
	cam.x = util.lerp(cam.x, p.x, t)
	cam.y = util.lerp(cam.y, p.y, t)

	-- Clamp so the view never shows outside the world. If the world is
	-- smaller than the screen on an axis, center that axis instead.
	local half_w = usagi.GAME_W / 2 / cam.zoom
	local half_h = usagi.GAME_H / 2 / cam.zoom

	if Camera.world_w > half_w * 2 then
		cam.x = util.clamp(cam.x, half_w, Camera.world_w - half_w)
	else
		cam.x = Camera.world_w / 2
	end

	if Camera.world_h > half_h * 2 then
		cam.y = util.clamp(cam.y, half_h, Camera.world_h - half_h)
	else
		cam.y = Camera.world_h / 2
	end
end

-- World position -> screen position. cam.x/cam.y is the world point at the
-- center of the screen.
function Camera.world_to_screen(x, y)
	local cam = State.camera
	return (x - cam.x) * cam.zoom + usagi.GAME_W / 2, (y - cam.y) * cam.zoom + usagi.GAME_H / 2
end

-- Screen position (e.g. raw mouse coords) -> world position.
function Camera.screen_to_world(x, y)
	local cam = State.camera
	return (x - usagi.GAME_W / 2) / cam.zoom + cam.x, (y - usagi.GAME_H / 2) / cam.zoom + cam.y
end

-- Scale a world-space length/radius into screen-space pixels.
function Camera.scale(r)
	return r * State.camera.zoom
end

-- Is a world point on screen (with an optional margin in world px)?
function Camera.visible(x, y, margin)
	local cam = State.camera
	local half_w = usagi.GAME_W / 2 / cam.zoom + (margin or 0)
	local half_h = usagi.GAME_H / 2 / cam.zoom + (margin or 0)
	return math.abs(x - cam.x) <= half_w and math.abs(y - cam.y) <= half_h
end

-- Returns the world-space rectangle currently visible:
-- x, y (top-left), w, h
function Camera.view()
	local cam = State.camera
	local half_w = usagi.GAME_W / 2 / cam.zoom
	local half_h = usagi.GAME_H / 2 / cam.zoom
	return cam.x - half_w, cam.y - half_h, half_w * 2, half_h * 2
end

return Camera
