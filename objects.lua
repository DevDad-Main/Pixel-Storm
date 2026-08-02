SpawnMarker = Object:extend()
SpawnMarker:implement(GameObject)
function SpawnMarker:init(args)
  self:init_game_object(args)
  self.color = red[0]
  self.r = random:float(0, 2*math.pi)
  self.spring:pull(random:float(0.4, 0.6), 200, 10)
  self.t:after(1.125, function() self.dead = true end)
  self.m = 1
  self.n = 0
  pop3:play{pitch = 1, volume = 0.15}
  self.t:every({0.195, 0.24}, function()
    self.hidden = not self.hidden
    self.m = self.m*random:float(0.84, 0.87)
  end, nil, nil, 'blink')
end


function SpawnMarker:update(dt)
  self:update_game_object(dt)
  self.t:set_every_multiplier('blink', self.m)
end


function SpawnMarker:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
    graphics.push(self.x, self.y, self.r + math.pi/4)
      graphics.rectangle(self.x, self.y, 24, 6, 4, 4, self.color)
    graphics.pop()
    graphics.push(self.x, self.y, self.r + 3*math.pi/4)
      graphics.rectangle(self.x, self.y, 24, 6, 4, 4, self.color)
    graphics.pop()
  graphics.pop()
end




LightningLine = Object:extend()
LightningLine:implement(GameObject)
function LightningLine:init(args)
  self:init_game_object(args)
  self.lines = {}
  table.insert(self.lines, {x1 = self.src.x, y1 = self.src.y, x2 = self.dst.x, y2 = self.dst.y})
  self.w = 3
  self.generations = args.generations or 3
  self.max_offset = args.max_offset or 8
  self:generate()
  self.t:tween(self.duration or 0.1, self, {w = 1}, math.linear, function() self.dead = true end)
  self.color = args.color or blue[0]
  HitCircle{group = main.current.effects, x = self.src.x, y = self.src.y, rs = 6, color = fg[0], duration = self.duration or 0.1}
  for i = 1, 2 do HitParticle{group = main.current.effects, x = self.src.x, y = self.src.y, color = self.color} end
  HitCircle{group = main.current.effects, x = self.dst.x, y = self.dst.y, rs = 6, color = fg[0], duration = self.duration or 0.1}
  HitParticle{group = main.current.effects, x = self.dst.x, y = self.dst.y, color = self.color}
end


function LightningLine:update(dt)
  self:update_game_object(dt)
end


function LightningLine:draw()
  graphics.polyline(self.color, self.w, unpack(self.points))
end


function LightningLine:generate()
  local offset_amount = self.max_offset
  local lines = self.lines

  for j = 1, self.generations do
    for i = #self.lines, 1, -1 do
      local x1, y1 = self.lines[i].x1, self.lines[i].y1
      local x2, y2 = self.lines[i].x2, self.lines[i].y2
      table.remove(self.lines, i)

      local x, y = (x1+x2)/2, (y1+y2)/2
      local p = Vector(x2-x1, y2-y1):normalize():perpendicular()
      x = x + p.x*random:float(-offset_amount, offset_amount)
      y = y + p.y*random:float(-offset_amount, offset_amount)
      table.insert(self.lines, {x1 = x1, y1 = y1, x2 = x, y2 = y})
      table.insert(self.lines, {x1 = x, y1 = y, x2 = x2, y2 = y2})
    end
    offset_amount = offset_amount/2
  end

  self.points = {}
  while #self.lines > 0 do
    local min_d, min_i = 1000000, 0
    for i, line in ipairs(self.lines) do
      local d = math.distance(self.src.x, self.src.y, line.x1, line.y1)
      if d < min_d then
        min_d = d
        min_i = i
      end
    end
    local line = table.remove(self.lines, min_i)
    if line then
      table.insert(self.points, line.x1)
      table.insert(self.points, line.y1)
    end
  end
end




WallKnife = Object:extend()
WallKnife:implement(GameObject)
WallKnife:implement(Physics)
function WallKnife:init(args)
  self:init_game_object(args)
  self:set_as_rectangle(10, 4, 'dynamic', 'projectile')
  self.hfx:add('hit', 1)
  self.hfx:use('hit', 0.25)
  self.t:tween({0.8, 1.6}, self, {v = 0}, math.linear, function()
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
  end)

  self.vr = self.r
  self.dvr = random:table{random:float(-8*math.pi, -4*math.pi), random:float(4*math.pi, 8*math.pi)}
end


function WallKnife:update(dt)
  self:update_game_object(dt)

  self:set_angle(self.r)
  self:move_along_angle(self.v, self.r)
  self.vr = self.vr + self.dvr*dt
end


function WallKnife:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, self.vr, self.hfx.hit.x, self.hfx.hit.x)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end




WallArrow = Object:extend()
WallArrow:implement(GameObject)
function WallArrow:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, 10, 4)
  self.hfx:add('hit', 1)
  self.hfx:use('hit', 0.25)
  self.t:after({0.8, 2}, function()
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
  end)
end


function WallArrow:update(dt)
  self:update_game_object(dt)
end


function WallArrow:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end




Unit = Object:extend()
function Unit:init_unit()
  self.level = self.level or 1
  self.hfx:add('hit', 1)
  self.hfx:add('shoot', 1)
  self.hp_bar = HPBar{group = main.current.effects, parent = self}
  self.effect_bar = EffectBar{group = main.current.effects, parent = self}
end


function Unit:update_unit(dt)
  if self.hp_bar then self.hp_bar:update(dt) end
  if self.effect_bar then self.effect_bar:update(dt) end
end


function Unit:bounce(nx, ny)
  local vx, vy = self:get_velocity()
  if nx == 0 then
    self:set_velocity(vx, -vy)
    self.r = 2*math.pi - self.r
  end
  if ny == 0 then
    self:set_velocity(-vx, vy)
    self.r = math.pi - self.r
  end
  return self.r
end


function Unit:show_hp(n)
  self.hp_bar.hidden = false
  self.hp_bar.color = red[0]
  self.t:after(n or 2, function() self.hp_bar.hidden = true end, 'hp_bar')
end


function Unit:show_heal(n)
  self.effect_bar.hidden = false
  self.effect_bar.color = green[0]
  self.t:after(n or 4, function() self.effect_bar.hidden = true end, 'effect_bar')
end


function Unit:show_infused(n)
  self.effect_bar.hidden = false
  self.effect_bar.color = blue[0]
  self.t:after(n or 4, function() self.effect_bar.hidden = true end, 'effect_bar')
end


function Unit:calculate_damage(dmg)
  if self.def >= 0 then dmg = dmg*(100/(100+self.def))
  else dmg = dmg*(2 - 100/(100+self.def)) end
  return dmg
end


function Unit:calculate_stats(first_run)
  if self:is(Player) then
    self.base_hp = 100*math.pow(2, self.level-1)
    self.base_dmg = 10*math.pow(2, self.level-1)
    self.base_mvspd = 75
  elseif self:is(Seeker) then
    if current_new_game_plus == 0 then
      if self.boss then
        local x = self.level
        local y = {0, 0, 3, 0, 0, 6, 0, 0, 9, 0, 0, 12, 0, 0, 18, 0, 0, 40, 0, 0, 32, 0, 0, 64, 90}
        local y2 = {0, 0, 24, 0, 0, 28, 0, 0, 32, 0, 0, 36, 0, 0, 44, 0, 0, 64, 0, 0, 48, 0, 0, 80, 100}
        local k = 1.07
        for i = 26, 50 do y[i] = y2[i-25] end
        for i = 51, 5000 do
          local n = i % 25
          if n == 0 then
            n = 25
            k = k + 0.07
          end
          y[i] = y2[n]*k
        end
        self.base_hp = 100 + (current_new_game_plus*5) + (90 + current_new_game_plus*10)*y[x]
        self.base_dmg = (12 + current_new_game_plus*2) + (2 + current_new_game_plus)*y[x]
        self.base_mvspd = math.min(35 + 1.5*y[x], 35 + 1.5*y[150])
        if x % 25 == 0 then
          self.base_dmg = (12 + current_new_game_plus*2) + (1.25 + current_new_game_plus)*y[x]
          self.base_mvspd = math.min(35 + 1.1*y[x], 35 + 1.1*y[150])
        end
      else
        local x = self.level
        local y = {0, 1, 3, 3, 4, 6, 5, 6, 9, 7, 8, 12, 10, 11, 15, 12, 13, 18, 16, 17, 21, 17, 20, 24, 25}
        local k = 1.07
        for i = 26, 5000 do
          local n = i % 25
          if n == 0 then
            n = 25
            k = k + 0.07
          end
          y[i] = y[i-10]*k
        end
        self.base_hp = 25 + 16.5*y[x]
        self.base_dmg = 4.5 + 2.5*y[x]
        self.base_mvspd = math.min(70 + 3*y[x], 70 + 3*y[150])
      end
    else
      if self.boss then
        local x = self.level
        local y = {0, 0, 3, 0, 0, 6, 0, 0, 9, 0, 0, 12, 0, 0, 18, 0, 0, 40, 0, 0, 32, 0, 0, 64, 90}
        local y2 = {0, 0, 24, 0, 0, 28, 0, 0, 32, 0, 0, 36, 0, 0, 44, 0, 0, 64, 0, 0, 48, 0, 0, 80, 100}
        local k = 1.07
        for i = 26, 50 do y[i] = y2[i-25] end
        for i = 51, 5000 do
          local n = i % 25
          if n == 0 then
            n = 25
            k = k + 0.07
          end
          y[i] = y2[n]*k
        end
        self.base_hp = 100 + (current_new_game_plus*5) + (90 + current_new_game_plus*10)*y[x]
        self.base_dmg = (12 + current_new_game_plus*2) + (2 + current_new_game_plus)*y[x]
        self.base_mvspd = math.min(35 + 1.5*y[x], 35 + 1.5*y[150])
        if x % 25 == 0 then
          self.base_dmg = (12 + current_new_game_plus*2) + (1.75 + 0.5*current_new_game_plus)*y[x]
          self.base_mvspd = math.min(35 + 1.2*y[x], 35 + 1.2*y[150])
        end
      else
        local x = self.level
        local y = {0, 1, 3, 3, 4, 6, 5, 6, 9, 7, 8, 12, 10, 11, 15, 12, 13, 18, 16, 17, 21, 17, 20, 24, 25}
        local k = 1.07
        for i = 26, 5000 do
          local n = i % 25
          if n == 0 then
            n = 25
            k = k + 0.07
          end
          y[i] = y[i-10]*k
        end
        self.base_hp = 22 + (current_new_game_plus*3) + (15 + current_new_game_plus*2.7)*y[x]
        self.base_dmg = (4 + current_new_game_plus*1.15) + (2 + current_new_game_plus*0.83)*y[x]
        self.base_mvspd = math.min(70 + 3*y[x], 70 + 3*y[150])
      end
    end
  elseif self:is(Saboteur) then
    self.base_hp = 100*math.pow(2, self.level-1)
    self.base_dmg = 10*math.pow(2, self.level-1)
    self.base_mvspd = 75
  elseif self:is(Automaton) then
    self.base_hp = 100*math.pow(2, self.level-1)
    self.base_dmg = 10*math.pow(2, self.level-1)
    self.base_mvspd = 15
  elseif self:is(EnemyCritter) or self:is(Critter) then
    local x = self.level
    local y = {0, 1, 3, 3, 4, 6, 5, 6, 9, 7, 8, 12, 10, 11, 15, 12, 13, 18, 16, 17, 21, 17, 20, 24, 25}
    local k = 1.2
    for i = 26, 5000 do
      local n = i % 25
      if n == 0 then
        n = 25
        k = k + 0.2
      end
      y[i] = y[n]*k
    end
    self.base_hp = 25 + 30*(y[x] or 1)
    self.base_dmg = 10 + 3*(y[x] or 1)
    self.base_mvspd = 60 + 3*(y[x] or 1)
  elseif self:is(Overlord) then
    self.base_hp = 50*math.pow(2, self.level-1)
    self.base_dmg = 10*math.pow(2, self.level-1)
    self.base_mvspd = 40
  end
  self.base_aspd_m = 1
  self.base_area_dmg_m = 1
  self.base_area_size_m = 1
  self.base_def = 25
  self.class_hp_a = 0
  self.class_dmg_a = 0
  self.class_def_a = 0
  self.class_mvspd_a = 0
  self.class_hp_m = 1
  self.class_dmg_m = 1
  self.class_aspd_m = 1
  self.class_area_dmg_m = 1
  self.class_area_size_m = 1
  self.class_def_m = 1
  self.class_mvspd_m = 1
  if first_run then
    self.buff_hp_a = 0
    self.buff_dmg_a = 0
    self.buff_def_a = 0
    self.buff_mvspd_a = 0
    self.buff_hp_m = 1
    self.buff_dmg_m = 1
    self.buff_aspd_m = 1
    self.buff_area_dmg_m = 1
    self.buff_area_size_m = 1
    self.buff_def_m = 1
    self.buff_mvspd_m = 1
  end

  for _, class in ipairs(self.classes) do self.class_hp_m = self.class_hp_m*class_stat_multipliers[class].hp end
  self.max_hp = (self.base_hp + self.class_hp_a + self.buff_hp_a)*self.class_hp_m*self.buff_hp_m
  if first_run then self.hp = self.max_hp end

  for _, class in ipairs(self.classes) do self.class_dmg_m = self.class_dmg_m*class_stat_multipliers[class].dmg end
  self.dmg = (self.base_dmg + self.class_dmg_a + self.buff_dmg_a)*self.class_dmg_m*self.buff_dmg_m

  for _, class in ipairs(self.classes) do self.class_aspd_m = self.class_aspd_m*class_stat_multipliers[class].aspd end
  self.aspd_m = 1/(self.base_aspd_m*self.class_aspd_m*self.buff_aspd_m)

  for _, class in ipairs(self.classes) do self.class_area_dmg_m = self.class_area_dmg_m*class_stat_multipliers[class].area_dmg end
  self.area_dmg_m = self.base_area_dmg_m*self.class_area_dmg_m*self.buff_area_dmg_m

  for _, class in ipairs(self.classes) do self.class_area_size_m = self.class_area_size_m*class_stat_multipliers[class].area_size end
  self.area_size_m = self.base_area_size_m*self.class_area_size_m*self.buff_area_size_m

  for _, class in ipairs(self.classes) do self.class_def_m = self.class_def_m*class_stat_multipliers[class].def end
  self.def = (self.base_def + self.class_def_a + self.buff_def_a)*self.class_def_m*self.buff_def_m

  for _, class in ipairs(self.classes) do self.class_mvspd_m = self.class_mvspd_m*class_stat_multipliers[class].mvspd end
  self.max_v = (self.base_mvspd + self.class_mvspd_a + self.buff_mvspd_a)*self.class_mvspd_m*self.buff_mvspd_m
  self.v = (self.base_mvspd + self.class_mvspd_a + self.buff_mvspd_a)*self.class_mvspd_m*self.buff_mvspd_m
end




EffectBar = Object:extend()
EffectBar:implement(GameObject)
EffectBar:implement(Parent)
function EffectBar:init(args)
  self:init_game_object(args)
  self.hidden = true
  self.color = fg[0]
end


function EffectBar:update(dt)
  self:update_game_object(dt)
  self:follow_parent_exclusively()
end


function EffectBar:draw()
  if self.hidden then return end
  --[[
  local p = self.parent
  graphics.push(p.x, p.y, p.r, p.hfx.hit.x, p.hfx.hit.x)
    graphics.rectangle(p.x, p.y, 3, 3, 1, 1, self.color)
  graphics.pop()
  ]]--
end




HPBar = Object:extend()
HPBar:implement(GameObject)
HPBar:implement(Parent)
function HPBar:init(args)
  self:init_game_object(args)
  self.hidden = true
end


function HPBar:update(dt)
  self:update_game_object(dt)
  self:follow_parent_exclusively()
end


function HPBar:draw()
  if self.hidden then return end
  local p = self.parent
  graphics.push(p.x, p.y, 0, p.hfx.hit.x, p.hfx.hit.x)
    graphics.line(p.x - 0.5*p.shape.w, p.y - p.shape.h, p.x + 0.5*p.shape.w, p.y - p.shape.h, bg[-3], 2)
    local n = math.remap(p.hp, 0, p.max_hp, 0, 1)
    graphics.line(p.x - 0.5*p.shape.w, p.y - p.shape.h, p.x - 0.5*p.shape.w + n*p.shape.w, p.y - p.shape.h,
    p.hfx.hit.f and fg[0] or ((p:is(Player) and green[0]) or (table.any(main.current.enemies, function(v) return p:is(v) end) and red[0])), 2)
  graphics.pop()
end
Projectile = Object:extend()
Projectile:implement(GameObject)
Projectile:implement(Physics)
function Projectile:init(args)
  self:init_game_object(args)
  if not self.group.world then self.dead = true; return end
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self.hfx:add('hit', 1)
  self:set_as_rectangle(10, 4, 'dynamic', 'projectile')
  self.pierce = args.pierce or 0
  self.chain = args.chain or 0
  self.ricochet = args.ricochet or 0
  self.chain_enemies_hit = {}
  self.infused_enemies_hit = {}

  if self.character == 'sage' then
    elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
    self.compression_dmg = self.dmg
    self.dmg = 0
    self.pull_sensor = Circle(self.x, self.y, 64*self.parent.area_size_m)
    self.rs = 0
    self.t:tween(0.05, self, {rs = self.shape.w/2.5}, math.cubic_in_out, function() self.spring:pull(0.15) end)
    self.t:after(4, function()
      self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function()
        self:die()
        if self.level == 3 then
          _G[random:table{'saboteur_hit1', 'saboteur_hit2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.2}
          magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.075}
          local enemies = self:get_objects_in_shape(self.pull_sensor, main.current.enemies)
          for _, enemy in ipairs(enemies) do
            enemy:hit(3*self.compression_dmg)
          end
        end
      end)
    end)

    self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.08)
    self.t:every(0.08, function()
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color}
    end)
    self.vr = 0
    self.dvr = random:float(-math.pi/4, math.pi/4)

  elseif self.character == 'spellblade' then
    if self.level == 3 then
      self.v = 1.5*self.v
      self.pierce = 1000
      self.orbit_r = 0
      self.orbit_vr = 12*math.pi
      self.t:tween(6.25, self, {orbit_vr = 4*math.pi}, math.expo_out, function()
        self.t:tween(12.25, self, {orbit_vr = 0}, math.linear)
      end)
    else
      self.pierce = 1000
      self.orbit_r = 0
      self.orbit_vr = 8*math.pi
      self.t:tween(6.25, self, {orbit_vr = math.pi}, math.expo_out, function()
        self.t:tween(12.25, self, {orbit_vr = 0}, math.linear)
      end)
    end

  elseif self.character == 'psyker' then
    self.pierce = 10000
    self.orbit_distance = random:float(56, 64)
    self.orbit_speed = random:float(2, 4)*((self.parent.orbitism == 1 and 1.25) or (self.parent.orbitism == 2 and 1.50) or (self.parent.orbitism == 3 and 1.75) or 1)*(1/self.parent.aspd_m)
    self.orbit_offset = random:float(0, 2*math.pi)
    self.dmg = self.dmg*((self.parent.psychosink == 1 and 1.4) or (self.parent.psychosink == 2 and 1.8) or (self.parent.psychosink == 3 and 2.2) or 1)

  elseif self.character == 'lich' then
    self.spring:pull(0.15)
    self.t:every(0.08, function()
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color}
    end)

  elseif self.character == 'arcanist' then
    self.dmg = 0.2*self.dmg
    self.t:every(0.08, function() HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color, r = self.r + math.pi + random:float(-math.pi/6, math.pi/6), v = random:float(10, 25), parent = self} end)
    self.t:every(self.parent.level == 3 and 0.54 or 0.8, function()
      local enemies = table.head(self:get_objects_in_shape(Circle(self.x, self.y, 128), main.current.enemies), self.level == 3 and 2 or 1)
      for _, enemy in ipairs(enemies) do
        arcane2:play{pitch = random:float(0.7, 1.3), volume = 0.15}
        self.hfx:use('hit', 0.5)
        local r = self:angle_to_object(enemy)
        local t = {group = main.current.main, x = self.x + 8*math.cos(r), y = self.y + 8*math.sin(r), v = 250, r = r, color = self.parent.color, dmg = self.parent.dmg, pierce = 2, character = 'arcanist_projectile',
        parent = self.parent, level = self.parent.level}
        local check_circle = Circle(t.x, t.y, 2)
        local objects = main.current.main:get_objects_in_shape(check_circle, {Player, Seeker, EnemyCritter, Critter, Sentry, Volcano, Saboteur, Bomb, Pet, Turret, Automaton})
        if #objects == 0 then Projectile(table.merge(t, mods or {})) end
      end
    end)

  elseif self.character == 'witch' and self.level == 3 then
    self.chain = 1

  elseif self.character == 'miner' then
    self.homing = true
    if self.level == 3 then
      self.pierce = 2
    end
  end

  if self.parent.divine_machine_arrow and table.any(self.parent.classes, function(v) return v == 'ranger' end) then
    if random:bool((self.parent.divine_machine_arrow == 1 and 10) or (self.parent.divine_machine_arrow == 2 and 20) or (self.parent.divine_machine_arrow == 3 and 30)) then
      self.homing = true
      self.pierce = self.parent.divine_machine_arrow or 0
    end
  end

  if self.homing then
    self.homing = false
    self.t:after(0.1, function()
      self.homing = true
      self.closest_sensor = Circle(self.x, self.y, 64)
    end)
  end

  self.distance_travelled = 0
  self.distance_dmg_m = 1

  if self.parent.blunt_arrow and table.any(self.parent.classes, function(v) return v == 'ranger' end) then
    if random:bool((self.parent.blunt_arrow == 1 and 10) or (self.parent.blunt_arrow == 2 and 20) or (self.parent.blunt_arrow == 3 and 30)) then
      self.knockback = 10
    end
  end

  if self.parent.flying_daggers and table.any(self.parent.classes, function(v) return v == 'rogue' end) then
    self.chain = self.chain + ((self.parent.flying_daggers == 1 and 2) or (self.parent.flying_daggers == 2 and 3) or (self.parent.flying_daggers == 3 and 4))
  end
end


function Projectile:update(dt)
  self:update_game_object(dt)

  if self.character == 'psyker' then
    if self.parent.dead then self.dead = true; self.parent = nil; return end
    self:set_position(self.parent.x + self.orbit_distance*math.cos(self.orbit_speed*main.current.t.time + self.orbit_offset),
      self.parent.y + self.orbit_distance*math.sin(self.orbit_speed*main.current.t.time + self.orbit_offset))
    local dx, dy = self.x - (self.previous_x or 0), self.y - (self.previous_y or 0)
    self.r = Vector(dx, dy):angle()
    self:set_angle(self.r)
    self.previous_x, self.previous_y = self.x, self.y
    return
  end

  if self.character == 'spellblade' then
    self.orbit_r = self.orbit_r + self.orbit_vr*dt
  end

  if self.homing then
    self.closest_sensor:move_to(self.x, self.y)
    local target = self:get_closest_object_in_shape(self.closest_sensor, main.current.enemies)
    if target then
      self:rotate_towards_object(target, 0.1)
      self.r = self:get_angle()
      self:move_along_angle(self.v, self.r + (self.orbit_r or 0))
    else
      self:set_angle(self.r)
      self:move_along_angle(self.v, self.r + (self.orbit_r or 0))
    end
  else
    self:set_angle(self.r)
    self:move_along_angle(self.v, self.r + (self.orbit_r or 0))
  end

  if self.character == 'sage' then
    self.pull_sensor:move_to(self.x, self.y)
    local enemies = self:get_objects_in_shape(self.pull_sensor, main.current.enemies)
    for _, enemy in ipairs(enemies) do
      enemy:apply_steering_force(math.remap(self:distance_to_object(enemy), 0, 100, 250, 50), enemy:angle_to_object(self))
    end
    self.vr = self.vr + self.dvr*dt
  end

  --[[
  if self.parent.point_blank or self.parent.longshot then
    self.distance_travelled = self.distance_travelled + math.length(self:get_velocity())
    if self.parent.point_blank and self.parent.longshot then
      self.distance_dmg_m = 1
    elseif self.parent.point_blank then
      self.distance_dmg_m = math.remap(self.distance_travelled, 0, 15000, 2, 0.75)
    elseif self.parent.longshot then
      self.distance_dmg_m = math.remap(self.distance_travelled, 0, 15000, 0.75, 2)
    end
  end
  ]]--
end


function Projectile:draw()
  if self.character == 'sage' then
    if self.hidden then return end

    graphics.push(self.x, self.y, self.r + self.vr, self.spring.x, self.spring.x)
      graphics.circle(self.x, self.y, self.rs + random:float(-1, 1), self.color)
      graphics.circle(self.x, self.y, self.pull_sensor.rs, self.color_transparent)
      local lw = math.remap(self.pull_sensor.rs, 32, 256, 2, 4)
      for i = 1, 4 do graphics.arc('open', self.x, self.y, self.pull_sensor.rs, (i-1)*math.pi/2 + math.pi/4 - math.pi/8, (i-1)*math.pi/2 + math.pi/4 + math.pi/8, self.color, lw) end
    graphics.pop()

  elseif self.character == 'lich' then
    graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
      graphics.circle(self.x, self.y, 3 + random:float(-1, 1), self.color)
    graphics.pop()

  elseif self.character == 'arcanist' then
    graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
      graphics.circle(self.x, self.y, 4, self.hfx.hit.f and fg[0] or self.color)
    graphics.pop()

  elseif self.character == 'psyker' then
    graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
      graphics.circle(self.x, self.y, 2.5, self.hfx.hit.f and fg[0] or self.color)
    graphics.pop()

  else
    graphics.push(self.x, self.y, self.r + (self.orbit_r or 0))
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.color)
    graphics.pop()
  end
end


function Projectile:die(x, y, r, n)
  if self.dead then return end
  x = x or self.x
  y = y or self.y
  n = n or random:int(3, 4)
  for i = 1, n do HitParticle{group = main.current.effects, x = x, y = y, r = random:float(0, 2*math.pi), color = self.color} end
  HitCircle{group = main.current.effects, x = x, y = y}:scale_down()
  self.dead = true

  if self.character == 'wizard' then
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*24, color = self.color, dmg = self.parent.area_dmg_m*self.dmg, character = self.character, level = self.level, parent = self,
      void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
  elseif self.character == 'blade' then
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*64, color = self.color, dmg = self.parent.area_dmg_m*self.dmg, character = self.character, level = self.level, parent = self,
      void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
  elseif self.character == 'cannoneer' then
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*96, color = self.color, dmg = 2*self.parent.area_dmg_m*self.dmg, character = self.character, level = self.level, parent = self,
      void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
    if self.level == 3 then
      self.parent.t:every(0.3, function()
        _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        Area{group = main.current.effects, x = self.x + random:float(-32, 32), y = self.y + random:float(-32, 32), r = self.r + random:float(0, 2*math.pi), w = self.parent.area_size_m*48, color = self.color, 
          dmg = 0.5*self.parent.area_dmg_m*self.dmg, character = self.character, level = self.level, parent = self, void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
      end, 7)
    end
  end
end


function Projectile:on_collision_enter(other, contact)
  local x, y = contact:getPositions()
  local nx, ny = contact:getNormal()
  local r = 0
  if nx == 0 and ny == -1 then r = -math.pi/2
  elseif nx == 0 and ny == 1 then r = math.pi/2
  elseif nx == -1 and ny == 0 then r = math.pi
  else r = 0 end

  if other:is(Wall) then
    if self.character == 'archer' or self.character == 'hunter' or self.character == 'barrage' or self.character == 'barrager' or self.character == 'sentry' then
      if self.ricochet <= 0 then
        self:die(x, y, r, 0)
        WallArrow{group = main.current.main, x = x, y = y, r = self.r, color = self.color}
      else
        local r = Unit.bounce(self, nx, ny)
        self.r = r
        self.ricochet = self.ricochet - 1
      end
      _G[random:table{'arrow_hit_wall1', 'arrow_hit_wall2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.2}
    elseif self.character == 'scout' or self.character == 'outlaw' or self.character == 'blade' or self.character == 'spellblade' or self.character == 'jester' or self.character == 'beastmaster' or self.character == 'witch' or
           self.character == 'thief' then
      self:die(x, y, r, 0)
      knife_hit_wall1:play{pitch = random:float(0.9, 1.1), volume = 0.2}
      local r = Unit.bounce(self, nx, ny)
      self.parent.t:after(0.01, function()
        WallKnife{group = main.current.main, x = x, y = y, r = r, v = self.v*0.1, color = self.color}
      end)
      if self.character == 'spellblade' then
        magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.075}
      end
    elseif self.character == 'artificer_death' then
      if self.ricochet <= 0 then
        self:die(x, y, r, random:int(2, 3))
        magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.075}
      else
        local r = Unit.bounce(self, nx, ny)
        self.r = r
        self.ricochet = self.ricochet - 1
      end
    elseif self.character == 'wizard' or self.character == 'lich' or self.character == 'arcanist' or self.character == 'arcanist_projectile' or self.character == 'witch' then
      self:die(x, y, r, random:int(2, 3))
      magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.075}
    elseif self.character == 'cannoneer' then
      self:die(x, y, r, random:int(2, 3))
      cannon_hit_wall1:play{pitch = random:float(0.95, 1.05), volume = 0.1}
    elseif self.character == 'engineer' or self.character == 'dual_gunner' or self.character == 'miner' then
      self:die(x, y, r, random:int(2, 3))
      _G[random:table{'turret_hit_wall1', 'turret_hit_wall2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.2}
    elseif self.character == 'psyker' then
    else
      self:die(x, y, r, random:int(2, 3))
      proj_hit_wall1:play{pitch = random:float(0.9, 1.1), volume = 0.2}
    end
  end
end


function Projectile:on_trigger_enter(other, contact)
  if self.character == 'sage' then return end

  if table.any(main.current.enemies, function(v) return other:is(v) end) then
    if self.pierce <= 0 and self.chain <= 0 then
      self:die(self.x, self.y, nil, random:int(2, 3))
    else
      if self.pierce > 0 then
        self.pierce = self.pierce - 1
      end
      if self.chain > 0 then
        self.chain = self.chain - 1
        table.insert(self.chain_enemies_hit, other)
        local object = self:get_random_object_in_shape(Circle(self.x, self.y, 48), main.current.enemies, self.chain_enemies_hit)
        if object then
          self.r = self:angle_to_object(object)
          if self.character == 'lich' then
            self.v = self.v*1.1
            if self.level == 3 then
              object:slow(0.2, 2)
            end
          else
            self.v = self.v*1.25
          end
          if self.level == 3 and self.character == 'scout' then
            self.dmg = self.dmg*1.25
          end
          if self.parent.ultimatum then
            self.dmg = self.dmg*((self.parent.ultimatum == 1 and 1.1) or (self.parent.ultimatum == 2 and 1.2) or (self.parent.ultimatum == 3 and 1.3))
          end
        end
      end
      HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = fg[0], duration = 0.1}
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color}
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = other.color}
    end

    if self.character == 'archer' or self.character == 'scout' or self.character == 'outlaw' or self.character == 'blade' or self.character == 'hunter' or self.character == 'spellblade' or self.character == 'engineer' or
    self.character == 'jester' or self.character == 'assassin' or self.character == 'barrager' or self.character == 'beastmaster' or self.character == 'witch' or self.character == 'miner' or self.character == 'thief' or 
    self.character == 'psyker' or self.character == 'sentry' then
      hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
      if self.character == 'spellblade' or self.character == 'psyker' then
        magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.15}
      end
    elseif self.character == 'wizard' or self.character == 'lich' or self.character == 'arcanist' then
      magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.15}
    elseif self.character == 'arcanist_projectile' then
      magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.075}
    else
      hit3:play{pitch = random:float(0.95, 1.05), volume = 0.35}
    end

    other:hit(self.dmg*(self.distance_dmg_m or 1), self)

    if self.character == 'wizard' and self.level == 3 then
      Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*32, color = self.color, dmg = self.parent.area_dmg_m*self.dmg, character = self.character, parent = self,
        void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
    end

    if self.character == 'hunter' and random:bool(40) then
      trigger:after(0.01, function()
        if self.level == 3 then
          local r = self.parent:angle_to_object(other)
          SpawnEffect{group = main.current.effects, x = self.parent.x, y = self.parent.y, color = green[0], action = function(x, y)
            Pet{group = main.current.main, x = x, y = y, r = r, v = 150, parent = self.parent, conjurer_buff_m = self.conjurer_buff_m or 1}
            Pet{group = main.current.main, x = x + 12*math.cos(r + math.pi/2), y = y + 12*math.sin(r + math.pi/2), r = r, v = 150, parent = self.parent, conjurer_buff_m = self.conjurer_buff_m or 1}
            Pet{group = main.current.main, x = x + 12*math.cos(r - math.pi/2), y = y + 12*math.sin(r - math.pi/2), r = r, v = 150, parent = self.parent, conjurer_buff_m = self.conjurer_buff_m or 1}
          end}
        else
          SpawnEffect{group = main.current.effects, x = self.parent.x, y = self.parent.y, color = orange[0], action = function(x, y)
            Pet{group = main.current.main, x = x, y = y, r = self.parent:angle_to_object(other), v = 150, parent = self.parent, conjurer_buff_m = self.conjurer_buff_m or 1}
          end}
        end
      end)
    end

    if self.character == 'assassin' then
      other:apply_dot((self.crit and 4*self.dmg or self.dmg/2)*(self.dot_dmg_m or 1)*(main.current.chronomancer_dot or 1), 3)
    end

    if self.parent and self.parent.chain_infused then
      local units = self.parent:get_all_units()
      local stormweaver_level = 0
      for _, unit in ipairs(units) do
        if unit.character == 'stormweaver' then
          stormweaver_level = unit.level
          break
        end
      end
      local src = other
      for i = 1, 2 + (stormweaver_level == 3 and 2 or 0) do
        _G[random:table{'spark1', 'spark2', 'spark3'}]:play{pitch = random:float(0.9, 1.1), volume = 0.3}
        table.insert(self.infused_enemies_hit, src)
        local dst = src:get_random_object_in_shape(Circle(src.x, src.y, (stormweaver_level == 3 and 128 or 64)), main.current.enemies, self.infused_enemies_hit)
        if dst then
          dst:hit(0.2*self.dmg*(self.distance_dmg_m or 1))
          LightningLine{group = main.current.effects, src = src, dst = dst}
          src = dst 
        end
      end
    end

    if self.parent and self.parent.lightning_strike then
      if random:bool((self.parent.lightning_strike == 1 and 5) or (self.parent.lightning_strike == 2 and 10) or (self.parent.lightning_strike == 3 and 15)) then
        local src = other
        for j = 1, 3 do
          main.current.t:after((j-1)*0.1, function()
            if not self.parent then return end
            _G[random:table{'spark1', 'spark2', 'spark3'}]:play{pitch = random:float(0.9, 1.1), volume = 0.3}
            for i = 1, 3 do
              table.insert(self.infused_enemies_hit, src)
              local dst = src:get_random_object_in_shape(Circle(src.x, src.y, 64), main.current.enemies, self.infused_enemies_hit)
              if dst then
                dst:hit(0.33*((self.parent.lightning_strike == 1 and 0.6) or (self.parent.lightning_strike == 2 and 0.8) or (self.parent.lightning_strike == 3 and 1))*self.dmg*(self.distance_dmg_m or 1))
                LightningLine{group = main.current.effects, src = src, dst = dst}
                src = dst 
              end
            end
          end)
        end
      end
    end

    if self.crit then
      camera:shake(5, 0.25)
      rogue_crit1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      rogue_crit2:play{pitch = random:float(0.95, 1.05), volume = 0.15}
      for i = 1, 3 do HitParticle{group = main.current.effects, x = other.x, y = other.y, color = self.color, v = random:float(100, 400)} end
      for i = 1, 3 do HitParticle{group = main.current.effects, x = other.x, y = other.y, color = other.color, v = random:float(100, 400)} end
      HitCircle{group = main.current.effects, x = other.x, y = other.y, rs = 12, color = fg[0], duration = 0.3}:scale_down():change_color(0.5, self.color)
    end

    if self.knockback then
      other:push(self.knockback*(self.knockback_m or 1), self.r)
    end

    if self.parent and self.parent.explosive_arrow and table.any(self.parent.classes, function(v) return v == 'ranger' end) then
      if random:bool((self.parent.explosive_arrow == 1 and 10) or (self.parent.explosive_arrow == 2 and 20) or (self.parent.explosive_arrow == 3 and 30)) then
        _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        Area{group = main.current.effects, x = self.x, y = self.y, r = self.r + random:float(0, 2*math.pi), w = self.parent.area_size_m*32, color = self.color, 
          dmg = ((self.parent.explosive_arrow == 1 and 0.1) or (self.parent.explosive_arrow == 2 and 0.2) or (self.parent.explosive_arrow == 3 and 0.3))*self.parent.area_dmg_m*self.dmg, character = self.character,
          level = self.level, parent = self, void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
      end
    end

    if self.parent and self.parent.void_rift and table.any(self.parent.classes, function(v) return v == 'mage' or v == 'nuker' or v == 'voider' end) then
      if random:bool(20) then
        DotArea{group = main.current.effects, x = self.x, y = self.y, rs = self.parent.area_size_m*24, color = self.color, dmg = self.parent.area_dmg_m*self.dmg*(self.parent.dot_dmg_m or 1), void_rift = true, duration = 1}
      end
    end
  end
end




Area = Object:extend()
Area:implement(GameObject)
function Area:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, 1.5*self.w, 1.5*self.w, self.r)
  local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
  for _, enemy in ipairs(enemies) do
    local resonance_dmg = 0
    local resonance_m = (self.parent.resonance == 1 and 0.03) or (self.parent.resonance == 2 and 0.05) or (self.parent.resonance == 3 and 0.07) or 0
    if self.character == 'elementor' then
      if self.parent.resonance then resonance_dmg = 2*self.dmg*resonance_m*#enemies end
      enemy:hit(2*self.dmg + resonance_dmg, self)
      if self.level == 3 then
        enemy:slow(0.4, 6)
      end
    elseif self.character == 'swordsman' then
      if self.parent.resonance then resonance_dmg = (self.dmg + self.dmg*0.15*#enemies)*resonance_m*#enemies end
      enemy:hit(self.dmg + self.dmg*0.15*#enemies + resonance_dmg, self)
    elseif self.character == 'blade' and self.level == 3 then
      if self.parent.resonance then resonance_dmg = (self.dmg + self.dmg*0.33*#enemies)*resonance_m*#enemies end
      enemy:hit(self.dmg + self.dmg*0.33*#enemies + resonance_dmg, self)
    elseif self.character == 'highlander' then
      if self.parent.resonance then resonance_dmg = 6*self.dmg*resonance_m*#enemies end
      enemy:hit(6*self.dmg + resonance_dmg, self)
    elseif self.character == 'launcher' then
      if self.parent.resonance then resonance_dmg = (self.level == 3 and 6*self.dmg*0.05*#enemies or 2*self.dmg*0.05*#enemies) end
      enemy:curse('launcher', 4*(self.hex_duration_m or 1), (self.level == 3 and 6*self.dmg or 2*self.dmg) + resonance_dmg, self.parent)
    elseif self.character == 'freezing_field' then
      enemy:slow(0.5, 2)
    else
      if self.parent.resonance then resonance_dmg = self.dmg*resonance_m*#enemies end
      enemy:hit(self.dmg + resonance_dmg, self)
    end
    HitCircle{group = main.current.effects, x = enemy.x, y = enemy.y, rs = 6, color = fg[0], duration = 0.1}
    for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = self.color} end
    for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = enemy.color} end
    if self.character == 'wizard' or self.character == 'magician' or self.character == 'elementor' or self.character == 'psychic' then
      magic_hit1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    elseif self.character == 'swordsman' or self.character == 'barbarian' or self.character == 'juggernaut' or self.character == 'highlander' then
      hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
    elseif self.character == 'blade' then
      blade_hit1:play{pitch = random:float(0.9, 1.1), volume = 0.35}
      hit2:play{pitch = random:float(0.95, 1.05), volume = 0.2}
    elseif self.character == 'saboteur' or self.character == 'pyromancer' or self.character == 'bomber' then
      if self.character == 'pyromancer' then pyro2:play{pitch = random:float(0.95, 1.05), volume = 0.4} end
      _G[random:table{'saboteur_hit1', 'saboteur_hit2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.2}
    elseif self.character == 'cannoneer' then
      _G[random:table{'saboteur_hit1', 'saboteur_hit2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.075}
    end

    if self.stun then
      enemy:slow(0.1, self.stun)
      enemy.barbarian_stunned = true
      enemy.t:after(self.stun, function() enemy.barbarian_stunned = false end)
    end

    if self.juggernaut_push then
      local r = self.parent:angle_to_object(enemy)
      enemy:push(random:float(75, 100)*(self.knockback_m or 1), r)
      enemy.juggernaut_push = 3*self.dmg
    end
  end

  if self.parent:is(Projectile) then
    local p = self.parent.parent
    if p.void_rift and table.any(p.classes, function(v) return v == 'mage' or v == 'nuker' or v == 'voider' end) then
      if random:bool(20) then
        DotArea{group = main.current.effects, x = self.x, y = self.y, rs = p.area_size_m*24, color = self.color, dmg = p.area_dmg_m*self.dmg*(p.dot_dmg_m or 1),
          void_rift = true, duration = 1, parent = p}
      end
    end
    if p.echo_barrage and not self.echo_barrage_area then
      if random:bool((p.echo_barrage == 1 and 10) or (p.echo_barrage == 2 and 20) or (p.echo_barrage == 3 and 30)) then
        p.t:every(0.3, function()
          _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          Area{group = main.current.effects, x = self.x + random:float(-32, 32), y = self.y + random:float(-32, 32), r = self.r + random:float(0, 2*math.pi), w = p.area_size_m*48, color = p.color, 
            dmg = 0.5*p.area_dmg_m*self.dmg, character = self.character, level = p.level, parent = p, echo_barrage_area = true}
        end, p.echo_barrage)
      end
    end
  else
    if self.parent.void_rift and table.any(self.parent.classes, function(v) return v == 'mage' or v == 'nuker' or v == 'voider' end) then
      if random:bool(20) then
        DotArea{group = main.current.effects, x = self.x, y = self.y, rs = self.parent.area_size_m*24, color = self.color, dmg = self.parent.area_dmg_m*self.dmg*(self.parent.dot_dmg_m or 1),
          void_rift = true, duration = 1, parent = self.parent}
      end
    end
    if self.parent.echo_barrage and not self.echo_barrage_area then
      if random:bool((self.parent.echo_barrage == 1 and 10) or (self.parent.echo_barrage == 2 and 20) or (self.parent.echo_barrage == 3 and 30)) then
        self.parent.t:every(0.3, function()
          _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          Area{group = main.current.effects, x = self.x + random:float(-32, 32), y = self.y + random:float(-32, 32), r = self.r + random:float(0, 2*math.pi), w = self.parent.area_size_m*48, color = self.parent.color, 
            dmg = 0.5*self.parent.area_dmg_m*(self.dmg or self.parent.dmg), character = self.character, level = self.parent.level, parent = self.parent, echo_barrage_area = true}
        end, self.parent.echo_barrage)
      end
    end
  end

  self.color = fg[0]
  self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.08)
  self.w = 0
  self.hidden = false
  self.t:tween(0.05, self, {w = args.w}, math.cubic_in_out, function() self.spring:pull(0.15) end)
  self.t:after(0.2, function()
    self.color = args.color
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
  end)
end


function Area:update(dt)
  self:update_game_object(dt)
end


function Area:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
  local w = self.w/2
  local w10 = self.w/10
  local x1, y1 = self.x - w, self.y - w
  local x2, y2 = self.x + w, self.y + w
  local lw = math.remap(w, 32, 256, 2, 4)
  graphics.polyline(self.color, lw, x1, y1 + w10, x1, y1, x1 + w10, y1)
  graphics.polyline(self.color, lw, x2 - w10, y1, x2, y1, x2, y1 + w10)
  graphics.polyline(self.color, lw, x2 - w10, y2, x2, y2, x2, y2 - w10)
  graphics.polyline(self.color, lw, x1, y2 - w10, x1, y2, x1 + w10, y2)
  graphics.rectangle((x1+x2)/2, (y1+y2)/2, x2-x1, y2-y1, nil, nil, self.color_transparent)
  graphics.pop()
end




DotArea = Object:extend()
DotArea:implement(GameObject)
DotArea:implement(Physics)
function DotArea:init(args)
  self:init_game_object(args)
  self.shape = Circle(self.x, self.y, self.rs)
  self.closest_sensor = Circle(self.x, self.y, 128)

  if self.character == 'plague_doctor' or self.character == 'pyromancer' or self.character == 'witch' or self.character == 'burning_field' then
    self.t:every(0.2, function()
      local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
      if #enemies > 0 then self.spring:pull(0.05, 200, 10) end
      for _, enemy in ipairs(enemies) do
        hit2:play{pitch = random:float(0.8, 1.2), volume = 0.2}
        if self.character == 'pyromancer' then
          pyro1:play{pitch = random:float(1.5, 1.8), volume = 0.1}
          if self.level == 3 then
            enemy.pyrod = self
          end
        end
        enemy:hit((self.dot_dmg_m or 1)*self.dmg/5, self, true)
        HitCircle{group = main.current.effects, x = enemy.x, y = enemy.y, rs = 6, color = fg[0], duration = 0.1}
        for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = self.color} end
        for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = enemy.color} end
      end
    end, nil, nil, 'dot')

  elseif self.character == 'cryomancer' then
    self.t:every(1, function()
      local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
      if #enemies > 0 then
        self.spring:pull(0.15, 200, 10)
        frost1:play{pitch = random:float(0.8, 1.2), volume = 0.4}
      end
      for _, enemy in ipairs(enemies) do
        if self.level == 3 then
          enemy:slow(0.4, 4)
        end
        enemy:hit((self.dot_dmg_m or 1)*2*self.dmg, self, true)
        HitCircle{group = main.current.effects, x = enemy.x, y = enemy.y, rs = 6, color = fg[0], duration = 0.1}
        for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = self.color} end
        for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = enemy.color} end
      end
    end, nil, nil, 'dot')

  --[[
  elseif self.character == 'bane' then
    if self.level == 3 then
      self.t:every(0.5, function()
        local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
        if #enemies > 0 then
          self.spring:pull(0.05, 200, 10)
          buff1:play{pitch = random:float(0.8, 1.2), volume = 0.1}
        end
        for _, enemy in ipairs(enemies) do
          enemy:curse('bane', 0.5*(self.hex_duration_m or 1), self.level == 3, self)
          if self.level == 3 then
            enemy:slow(0.5, 0.5)
            enemy:hit((self.dot_dmg_m or 1)*self.dmg/2)
            HitCircle{group = main.current.effects, x = enemy.x, y = enemy.y, rs = 6, color = fg[0], duration = 0.1}
            for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = self.color} end
            for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = enemy.color} end
          end
        end
      end, nil, nil, 'dot')
    end
    ]]--

  elseif self.void_rift then
    self.t:every(0.2, function()
      local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
      if #enemies > 0 then self.spring:pull(0.05, 200, 10) end
      for _, enemy in ipairs(enemies) do
        hit2:play{pitch = random:float(0.8, 1.2), volume = 0.2}
        enemy:hit((self.dot_dmg_m or 1)*self.dmg/5, self, true)
        HitCircle{group = main.current.effects, x = enemy.x, y = enemy.y, rs = 6, color = fg[0], duration = 0.1}
        for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = self.color} end
        for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = enemy.color} end
      end
    end, nil, nil, 'dot')
  end

  if self.character == 'witch' then
    self.v = random:float(40, 80)
    self.r = random:table{math.pi/4, 3*math.pi/4, -math.pi/4, -3*math.pi/4}
    if self.level == 3 then
      self.t:every(1, function()
        local enemies = main.current.main:get_objects_in_shape(self.closest_sensor, main.current.enemies)
        if enemies and #enemies > 0 then
          local r = self:angle_to_object(enemies[1])
          HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6}
          local t = {group = main.current.main, x = self.x, y = self.y, v = 250, r = r, color = self.parent.color, dmg = self.parent.dmg, character = 'witch', parent = self.parent, level = self.parent.level}
          Projectile(table.merge(t, mods or {}))
          _G[random:table{'scout1', 'scout2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.35}
          wizard1:play{pitch = random:float(0.95, 1.05), volume = 0.15}
        end
      end)
    end
  end

  self.color = fg[0]
  self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.08)
  self.rs = 0
  self.hidden = false
  self.t:tween(0.05, self, {rs = args.rs}, math.cubic_in_out, function() self.spring:pull(0.15) end)
  self.t:after(0.2, function() self.color = args.color end)
  if self.duration and self.duration > 0.5 then
    self.t:after(self.duration - 0.35, function()
      self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
    end)
  end

  self.vr = 0
  self.dvr = random:float(-math.pi/4, math.pi/4)

  if self.void_rift then
    self.dvr = random:table{random:float(-4*math.pi, -2*math.pi), random:float(2*math.pi, 4*math.pi)}
  end
end


function DotArea:update(dt)
  self:update_game_object(dt)
  self.t:set_every_multiplier('dot', (main.current.chronomancer_dot or 1))
  self.vr = self.vr + self.dvr*dt

  if self.parent then
    if (self.character == 'plague_doctor' and self.level == 3 and not self.plague_doctor_unmovable) or self.character == 'cryomancer' or self.character == 'pyromancer' then
      self.x, self.y = self.parent.x, self.parent.y
      self.shape:move_to(self.x, self.y)
    end
  end

  if self.character == 'witch' then
    self.x, self.y = self.x + self.v*math.cos(self.r)*dt, self.y + self.v*math.sin(self.r)*dt
    if self.x >= main.current.x2 - self.shape.rs/2 or self.x <= main.current.x1 + self.shape.rs/2 then
      self.r = math.pi - self.r
    end
    if self.y >= main.current.y2 - self.shape.rs/2 or self.y <= main.current.y1 + self.shape.rs/2 then
      self.r = 2*math.pi - self.r
    end
    self.shape:move_to(self.x, self.y)
  end
end


function DotArea:draw()
  if self.hidden then return end

  graphics.push(self.x, self.y, self.r + self.vr, self.spring.x, self.spring.x)
    -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
    graphics.circle(self.x, self.y, self.shape.rs, self.color_transparent)
    local lw = math.remap(self.shape.rs, 32, 256, 2, 4)
    for i = 1, 4 do graphics.arc('open', self.x, self.y, self.shape.rs, (i-1)*math.pi/2 + math.pi/4 - math.pi/8, (i-1)*math.pi/2 + math.pi/4 + math.pi/8, self.color, lw) end
  graphics.pop()
end


function DotArea:scale(v)
  self.shape = Circle(self.x, self.y, (v or 1)*self.rs)
end




ForceArea = Object:extend()
ForceArea:implement(GameObject)
ForceArea:implement(Physics)
function ForceArea:init(args)
  self:init_game_object(args)
  self.shape = Circle(self.x, self.y, self.rs)
  
  self.color = fg[0]
  self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.08)
  self.rs = 0
  self.hidden = false
  self.t:tween(0.05, self, {rs = args.rs}, math.cubic_in_out, function() self.spring:pull(0.15) end)
  self.t:after(0.2, function() self.color = args.color end)

  self.vr = 0
  self.dvr = random:table{random:float(-6*math.pi, -4*math.pi), random:float(4*math.pi, 6*math.pi)}

  if self.character == 'psykino' then
    elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
    self.t:tween(2, self, {dvr = 0}, math.linear)

    self.t:during(2, function()
      local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
      local t = self.t:get_during_elapsed_time('psykino')
      for _, enemy in ipairs(enemies) do
        enemy:apply_steering_force(600*(1-t), enemy:angle_to_point(self.x, self.y))
      end
    end, nil, 'psykino')
    self.t:after(2 - 0.35, function()
      self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
      if self.level == 3 then
        elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
        local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
        for _, enemy in ipairs(enemies) do
          enemy:hit(4*self.parent.dmg)
          enemy:push(50*(self.knockback_m or 1), self:angle_to_object(enemy))
        end
      end
    end)

  elseif self.character == 'gravity_field' then
    elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.4}
    self.t:tween(1, self, {dvr = 0}, math.linear)

    self.t:during(1, function()
      local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
      local t = self.t:get_during_elapsed_time('gravity_field')
      for _, enemy in ipairs(enemies) do
        enemy:apply_steering_force(400*(1-t), enemy:angle_to_point(self.x, self.y))
      end
    end, nil, 'gravity_field')
    self.t:after(1 - 0.35, function()
      self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
    end)
  end
end


function ForceArea:update(dt)
  self:update_game_object(dt)
  self.vr = self.vr + self.dvr*dt
end


function ForceArea:draw()
  if self.hidden then return end

  graphics.push(self.x, self.y, self.r + self.vr, self.spring.x, self.spring.x)
    graphics.circle(self.x, self.y, self.shape.rs, self.color_transparent)
    local lw = math.remap(self.shape.rs, 32, 256, 2, 4)
    for i = 1, 4 do graphics.arc('open', self.x, self.y, self.shape.rs, (i-1)*math.pi/2 + math.pi/4 - math.pi/8, (i-1)*math.pi/2 + math.pi/4 + math.pi/8, self.color, lw) end
  graphics.pop()
end



