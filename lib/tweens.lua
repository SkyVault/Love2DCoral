return function(sys, tools)
  local tween = {
    _VERSION     = 'tween 2.1.1',
    _DESCRIPTION = 'tweening for lua',
    _URL         = 'https://github.com/kikito/tween.lua',
    _LICENSE     = [[
      MIT LICENSE

      Copyright (c) 2014 Enrique García Cota, Yuichi Tateno, Emmanuel Oga

      Permission is hereby granted, free of charge, to any person obtaining a
      copy of this software and associated documentation files (the
      "Software"), to deal in the Software without restriction, including
      without limitation the rights to use, copy, modify, merge, publish,
      distribute, sublicense, and/or sell copies of the Software, and to
      permit persons to whom the Software is furnished to do so, subject to
      the following conditions:

      The above copyright notice and this permission notice shall be included
      in all copies or substantial portions of the Software.

      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
      OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
      MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
      IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
      CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
      TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
      SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ]]
  }

  -- easing

  -- Adapted from https://github.com/EmmanuelOga/easing. See LICENSE.txt for credits.
  -- For all easing functions:
  -- t = time == how much time has to pass for the tweening to complete
  -- b = begin == starting property value
  -- c = change == ending - beginning
  -- d = duration == running time. How much time has passed *right now*

  local pow, sin, cos, pi, sqrt, abs, asin = math.pow, math.sin, math.cos, math.pi, math.sqrt, math.abs, math.asin

  -- linear
  local function linear(t, b, c, d) return c * t / d + b end

  -- quad
  local function in_quad(t, b, c, d) return c * pow(t / d, 2) + b end
  local function out_quad(t, b, c, d)
    t = t / d
    return -c * t * (t - 2) + b
  end
  local function in_out_quad(t, b, c, d)
    t = t / d * 2
    if t < 1 then return c / 2 * pow(t, 2) + b end
    return -c / 2 * ((t - 1) * (t - 3) - 1) + b
  end
  local function out_in_quad(t, b, c, d)
    if t < d / 2 then return out_quad(t * 2, b, c / 2, d) end
    return in_quad((t * 2) - d, b + c / 2, c / 2, d)
  end

  -- cubic
  local function in_cubic (t, b, c, d) return c * pow(t / d, 3) + b end
  local function out_cubic(t, b, c, d) return c * (pow(t / d - 1, 3) + 1) + b end
  local function in_out_cubic(t, b, c, d)
    t = t / d * 2
    if t < 1 then return c / 2 * t * t * t + b end
    t = t - 2
    return c / 2 * (t * t * t + 2) + b
  end
  local function out_in_cubic(t, b, c, d)
    if t < d / 2 then return out_cubic(t * 2, b, c / 2, d) end
    return in_cubic((t * 2) - d, b + c / 2, c / 2, d)
  end

  -- quart
  local function in_quart(t, b, c, d) return c * pow(t / d, 4) + b end
  local function out_quart(t, b, c, d) return -c * (pow(t / d - 1, 4) - 1) + b end
  local function in_out_quart(t, b, c, d)
    t = t / d * 2
    if t < 1 then return c / 2 * pow(t, 4) + b end
    return -c / 2 * (pow(t - 2, 4) - 2) + b
  end
  local function out_in_quart(t, b, c, d)
    if t < d / 2 then return out_quart(t * 2, b, c / 2, d) end
    return in_quart((t * 2) - d, b + c / 2, c / 2, d)
  end

  -- quint
  local function in_quint(t, b, c, d) return c * pow(t / d, 5) + b end
  local function out_quint(t, b, c, d) return c * (pow(t / d - 1, 5) + 1) + b end
  local function in_out_quint(t, b, c, d)
    t = t / d * 2
    if t < 1 then return c / 2 * pow(t, 5) + b end
    return c / 2 * (pow(t - 2, 5) + 2) + b
  end
  local function out_in_quint(t, b, c, d)
    if t < d / 2 then return out_quint(t * 2, b, c / 2, d) end
    return in_quint((t * 2) - d, b + c / 2, c / 2, d)
  end

  -- sine
  local function in_sine(t, b, c, d) return -c * cos(t / d * (pi / 2)) + c + b end
  local function out_sine(t, b, c, d) return c * sin(t / d * (pi / 2)) + b end
  local function in_out_sine(t, b, c, d) return -c / 2 * (cos(pi * t / d) - 1) + b end
  local function out_in_sine(t, b, c, d)
    if t < d / 2 then return out_sine(t * 2, b, c / 2, d) end
    return in_sine((t * 2) -d, b + c / 2, c / 2, d)
  end

  -- expo
  local function in_expo(t, b, c, d)
    if t == 0 then return b end
    return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
  end
  local function out_expo(t, b, c, d)
    if t == d then return b + c end
    return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
  end
  local function in_out_expo(t, b, c, d)
    if t == 0 then return b end
    if t == d then return b + c end
    t = t / d * 2
    if t < 1 then return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005 end
    return c / 2 * 1.0005 * (-pow(2, -10 * (t - 1)) + 2) + b
  end
  local function out_in_expo(t, b, c, d)
    if t < d / 2 then return out_expo(t * 2, b, c / 2, d) end
    return in_expo((t * 2) - d, b + c / 2, c / 2, d)
  end

  -- circ
  local function in_circ(t, b, c, d) return(-c * (sqrt(1 - pow(t / d, 2)) - 1) + b) end
  local function out_circ(t, b, c, d)  return(c * sqrt(1 - pow(t / d - 1, 2)) + b) end
  local function in_out_circ(t, b, c, d)
    t = t / d * 2
    if t < 1 then return -c / 2 * (sqrt(1 - t * t) - 1) + b end
    t = t - 2
    return c / 2 * (sqrt(1 - t * t) + 1) + b
  end
  local function out_in_circ(t, b, c, d)
    if t < d / 2 then return out_circ(t * 2, b, c / 2, d) end
    return in_circ((t * 2) - d, b + c / 2, c / 2, d)
  end

  -- elastic
  local function calculate_pas(p,a,c,d)
    p, a = p or d * 0.3, a or 0
    if a < abs(c) then return p, c, p / 4 end -- p, a, s
    return p, a, p / (2 * pi) * asin(c/a) -- p,a,s
  end
  local function in_elastic(t, b, c, d, a, p)
    local s
    if t == 0 then return b end
    t = t / d
    if t == 1  then return b + c end
    p,a,s = calculate_pas(p,a,c,d)
    t = t - 1
    return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
  end
  local function out_elastic(t, b, c, d, a, p)
    local s
    if t == 0 then return b end
    t = t / d
    if t == 1 then return b + c end
    p,a,s = calculate_pas(p,a,c,d)
    return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
  end
  local function in_out_elastic(t, b, c, d, a, p)
    local s
    if t == 0 then return b end
    t = t / d * 2
    if t == 2 then return b + c end
    p,a,s = calculate_pas(p,a,c,d)
    t = t - 1
    if t < 0 then return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b end
    return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
  end
  local function out_in_elastic(t, b, c, d, a, p)
    if t < d / 2 then return out_elastic(t * 2, b, c / 2, d, a, p) end
    return in_elastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
  end

  -- back
  local function in_back(t, b, c, d, s)
    s = s or 1.70158
    t = t / d
    return c * t * t * ((s + 1) * t - s) + b
  end
  local function out_back(t, b, c, d, s)
    s = s or 1.70158
    t = t / d - 1
    return c * (t * t * ((s + 1) * t + s) + 1) + b
  end
  local function in_out_back(t, b, c, d, s)
    s = (s or 1.70158) * 1.525
    t = t / d * 2
    if t < 1 then return c / 2 * (t * t * ((s + 1) * t - s)) + b end
    t = t - 2
    return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
  end
  local function out_in_back(t, b, c, d, s)
    if t < d / 2 then return out_back(t * 2, b, c / 2, d, s) end
    return in_back((t * 2) - d, b + c / 2, c / 2, d, s)
  end

  -- bounce
  local function out_bounce(t, b, c, d)
    t = t / d
    if t < 1 / 2.75 then return c * (7.5625 * t * t) + b end
    if t < 2 / 2.75 then
      t = t - (1.5 / 2.75)
      return c * (7.5625 * t * t + 0.75) + b
    elseif t < 2.5 / 2.75 then
      t = t - (2.25 / 2.75)
      return c * (7.5625 * t * t + 0.9375) + b
    end
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
  end
  local function in_bounce(t, b, c, d) return c - out_bounce(d - t, 0, c, d) + b end
  local function in_out_bounce(t, b, c, d)
    if t < d / 2 then return in_bounce(t * 2, 0, c, d) * 0.5 + b end
    return out_bounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
  end
  local function out_in_bounce(t, b, c, d)
    if t < d / 2 then return out_bounce(t * 2, b, c / 2, d) end
    return in_bounce((t * 2) - d, b + c / 2, c / 2, d)
  end

  tween.easing = {
    linear    = linear,
    in_quad   = in_quad,    out_quad    = out_quad,    in_out_quad    = in_out_quad,    out_in_quad    = out_in_quad,
    in_cubic  = in_cubic,   out_cubic   = out_cubic,   in_out_cubic   = in_out_cubic,   out_in_cubic   = out_in_cubic,
    in_quart  = in_quart,   out_quart   = out_quart,   in_out_quart   = in_out_quart,   out_in_quart   = out_in_quart,
    in_quint  = in_quint,   out_quint   = out_quint,   in_out_quint   = in_out_quint,   out_in_quint   = out_in_quint,
    in_sine   = in_sine,    out_sine    = out_sine,    in_out_sine    = in_out_sine,    out_in_sine    = out_in_sine,
    in_expo   = in_expo,    out_expo    = out_expo,    in_out_expo    = in_out_expo,    out_in_expo    = out_in_expo,
    in_circ   = in_circ,    out_circ    = out_circ,    in_out_circ    = in_out_circ,    out_in_circ    = out_in_circ,
    in_elastic= in_elastic, out_elastic = out_elastic, in_out_elastic = in_out_elastic, out_in_elastic = out_in_elastic,
    in_back   = in_back,    out_back    = out_back,    in_out_back    = in_out_back,    out_in_back    = out_in_back,
    in_bounce = in_bounce,  out_bounce  = out_bounce,  in_out_bounce  = in_out_bounce,  out_in_bounce  = out_in_bounce
  }



  -- private stuff

  local function copyTables(destination, keysTable, valuesTable)
    valuesTable = valuesTable or keysTable
    local mt = getmetatable(keysTable)
    if mt and getmetatable(destination) == nil then
      setmetatable(destination, mt)
    end
    for k,v in pairs(keysTable) do
      if type(v) == 'table' then
        destination[k] = copyTables({}, v, valuesTable[k])
      else
        destination[k] = valuesTable[k]
      end
    end
    return destination
  end

  local function checkSubjectAndTargetRecursively(subject, target, path)
    path = path or {}
    local targetType, newPath
    for k,targetValue in pairs(target) do
      targetType, newPath = type(targetValue), copyTables({}, path)
      table.insert(newPath, tostring(k))
      if targetType == 'number' then
        assert(type(subject[k]) == 'number', "Parameter '" .. table.concat(newPath,'/') .. "' is missing from subject or isn't a number")
      elseif targetType == 'table' then
        checkSubjectAndTargetRecursively(subject[k], targetValue, newPath)
      else
        assert(targetType == 'number', "Parameter '" .. table.concat(newPath,'/') .. "' must be a number or table of numbers")
      end
    end
  end

  local function checkNewParams(duration, subject, target, easing)
    assert(type(duration) == 'number' and duration > 0, "duration must be a positive number. Was " .. tostring(duration))
    local tsubject = type(subject)
    assert(tsubject == 'table' or tsubject == 'userdata', "subject must be a table or userdata. Was " .. tostring(subject))
    assert(type(target)== 'table', "target must be a table. Was " .. tostring(target))
    assert(type(easing)=='function', "easing must be a function. Was " .. tostring(easing))
    checkSubjectAndTargetRecursively(subject, target)
  end

  local function getEasingFunction(easing)
    easing = easing or "linear"
    if type(easing) == 'string' then
      local name = easing
      easing = tween.easing[name]
      if type(easing) ~= 'function' then
        error("The easing function name '" .. name .. "' is invalid")
      end
    end
    return easing
  end

  local function performEasingOnSubject(subject, target, initial, clock, duration, easing)
    local t,b,c,d
    for k,v in pairs(target) do
      if type(v) == 'table' then
        performEasingOnSubject(subject[k], v, initial[k], clock, duration, easing)
      else
        t,b,c,d = clock, initial[k], v - initial[k], duration
        subject[k] = easing(t,b,c,d)
      end
    end
  end

  -- Tween methods

  local Tween = {}
  local Tween_mt = {__index = Tween}

  function Tween:set(clock)
    assert(type(clock) == 'number', "clock must be a positive number or 0")

    self.initial = self.initial or copyTables({}, self.target, self.subject)
    self.clock = clock

    if self.clock <= 0 then

      self.clock = 0
      copyTables(self.subject, self.initial)

    elseif self.clock >= self.duration then -- the tween has expired

      self.clock = self.duration
      copyTables(self.subject, self.target)

    else

      performEasingOnSubject(self.subject, self.target, self.initial, self.clock, self.duration, self.easing)

    end

    return self.clock >= self.duration
  end

  function Tween:reset()
    return self:set(0)
  end

  local tweens = {}

  function Tween:update(dt)
    assert(type(dt) == 'number', "dt must be a number")
    return self:set(self.clock + dt)
  end

  function Tween:start()
    table.insert(tweens, self)
    return self
  end

  -- Public interface

  function tween.new(duration, subject, target, easing)
    easing = getEasingFunction(easing)
    checkNewParams(duration, subject, target, easing)
    local twn = setmetatable(tools.builder {
      duration  = duration,
      subject   = subject,
      target    = target,
      easing    = easing,
      clock     = 0,
      on_complete = function() end,
    }, Tween_mt)
    return twn
  end

  function tween.newstart(duration, subject, target, easing)
    easing = getEasingFunction(easing)
    checkNewParams(duration, subject, target, easing)
    return setmetatable({
      duration  = duration,
      subject   = subject,
      target    = target,
      easing    = easing,
      clock     = 0,
      on_complete = function() end,
    }, Tween_mt):start()
  end

  local function update(dt)
     for i = 1, #tweens do
       if tweens[i] then
         if tweens[i]:update(dt) then
           tweens[i].on_complete()
           table.remove(tweens, i)
         end
       end
     end
  end

  sys.on_update(update)

  return tween
end
