local Particles = require "particles"
local Camera = require "camera"

local Pickups = {}
Pickups.list = {}

function Pickups.spawn(x, y,kind)
  table.insert(Pickups.list, {x = x, y = y, kind = kind or "heart", bob = math.random() * math.pi * 2})
end

function Pickups.update(dt, State)
  local p = State.player
  for i = #Pickups.list, 1, -1 do
    local pk = Pickups.list[i]
    local dx = p.x - pk.x
    local dy = p.y - pk.y
    local d2 = dx * dx + dy * dy
    if d2 < 900 then
      local d = math.sqrt(d2)
      if d < 0.001 then d = 0.001 end
      local pull = 120 * dt
      pk.x = pk.x + dx / d * pull
      pk.y = pk.y + dy / d * pull
      if d2 < 64 then
        if pk.kind == "energy" then
          if State.ult >= State.ult_max then
            State.score = State.score + 50
          else
            State.ult = math.min(State.ult_max, State.ult + 25)
          end
          Particles.burst(pk.x, pk.y, 10, 50, 0.5, gfx.COLOR_BLUE, 1)
          Particles.burst(pk.x, pk.y, 4, 30, 0.3, gfx.COLOR_WHITE, 1)
        else
          p.hp = math.min(p.max_hp, p.hp + 25)
          Particles.burst(pk.x, pk.y, 8, 40, 0.4, gfx.COLOR_RED, 1)
          Particles.burst(pk.x, pk.y, 4, 30, 0.3, gfx.COLOR_WHITE, 1)
        end
        table.remove(Pickups.list, i)
      end
    end
  end
end

function Pickups.draw()
  for _, pk in ipairs(Pickups.list) do
    if Camera.visible(pk.x, pk.y, 8) then
      local x, y = Camera.world_to_screen(pk.x, pk.y)
      x = util.round(x)
      y = util.round(y) + util.round(math.sin(pk.bob) * 1)
      if pk.kind == "energy" then
        gfx.px(x, y, gfx.COLOR_BLUE)
        gfx.px(x + 1, y, gfx.COLOR_BLUE)
        gfx.px(x - 1, y, gfx.COLOR_BLUE)
        gfx.px(x, y + 1, gfx.COLOR_BLUE)
        gfx.px(x, y - 1, gfx.COLOR_BLUE)
        gfx.px(x, y, gfx.COLOR_WHITE)
      else
        gfx.px(x, y, gfx.COLOR_RED)
        gfx.px(x + 1, y, gfx.COLOR_RED)
        gfx.px(x, y + 1, gfx.COLOR_RED)
        gfx.px(x - 1, y + 1, gfx.COLOR_RED)
        gfx.px(x, y + 2, gfx.COLOR_RED)
      end
    end
  end
end

return Pickups
