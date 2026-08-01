local Particles = {}
Particles.list = {}


function Particles.emit(o)
  for _ = 1, (o.count or 1) do
    local a
    if o.angle then
      a = o.angle + (math.random() - 0.5) * (o.spread or 0)
    else
      a = math.random() * math.pi * 2
    end
    local speed = o.speed * (0.4 + math.random() * 0.6)
    local life = o.life * (0.5 + math.random() * 0.9)
    table.insert(Particles.list, {
                   x = o.x,
                   y = o.y,
                   vx = math.cos(a) * speed,
                   vy = math.sin(a) * speed,
                   life = life,
                   max_life = life,
                   size = o.size or 1,
                   color = o.color,
                   gravity = o.gravity or 0,
                   drag = o.drag or 0,
                   shrink = o.shrink == nil and true or o.shrink,
    })
  end
end

function Particles.burst(x, y, count, speed, life, color, size)
  Particles.emit({x=x, y=y, count=count, speed=speed, life=life, color=color, size=size, drag=2.5})
end

function Particles.spray(x, y, angle, spread, count, speed, life, color, size)
  Particles.emit({x=x, y=y, angle=angle, spread=spread, count=count, speed=speed, life=life, color=color, size=size, drag=1.5})
end

function Particles.update(dt)
  local list = Particles.list
  for i = #list, 1, -1 do
    local p = list[i]
    p.life = p.life - dt
    if p.life <= 0 then
      table.remove(list, i)
    else
      p.x = p.x + p.vx * dt
      p.y = p.y + p.vy * dt
      p.vy = p.vy + p.gravity * dt
      if p.drag > 0 then
        local f = 1 - p.drag * dt
        p.vx = p.vx * f
        p.vy = p.vy * f
      end
    end
  end
end

function Particles.draw()
  local Camera = require "camera"
  local list = Particles.list
  for i = 1, #list do
    local p = list[i]
    if Camera.visible(p.x, p.y, 8) then
      local a = util.clamp(p.life / p.max_life, 0, 1)
      local s = p.size
      if p.shrink then s = util.clamp(p.size * a, 0, p.size) end
      s = s * State.camera.zoom
      local px, py = Camera.world_to_screen(p.x, p.y)
      px = util.round(px)
      py = util.round(py)
      if s <= 0.5 then
        gfx.px(px, py, p.color, a)
      else
        local half = util.round(s)
        gfx.rect_fill(px - half, py - half, half * 2, half * 2, p.color, a)
      end
    end
  end
end

return Particles
