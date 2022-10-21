local function hex(c)
    -- strip leading "#" or "0x" if necessary
    if c:sub(1, 1) == "#" then
      c = c:sub(2)
    elseif c:sub(1, 2) == "0x" then
      c = c:sub(3)
    end

    local color = {}
    local color_width = (#c < 6) and 1 or 2
    local max_val = 16 ^ color_width - 1

    for i = 1, #c, color_width do
        color[#color + 1] = tonumber(c:sub(i, i + color_width - 1), 16) / max_val
    end

    return color
end

Black = hex "0x000000FF"
DarkBlue = hex "0x1D2B53FF"
Maroon = hex "0x7E2553FF"
DarkGreen = hex "0x008751FF"
Brown = hex "0xAB5236FF"
DarkGray = hex "0x5F574FFF"
LightGray = hex "0xC2C3C7FF"
White = hex "0xFFF1E8FF"
Red = hex "0xFF004DFF"
Orange = hex "0xFFA300FF"
Yellow = hex "0xFFEC27FF"
Green = hex "0x00E436FF"
Blue = hex "0x29ADFFFF"
Gray = hex "0x83769CFF"
Pink = hex "0xFF77A8FF"
Tan = hex "0xFFCCAAFF"

local function mix_color(a, b, strength)
  local s = strength or 0.5
  return {
    a[1] * (1 - s) + b[1] * s,
    a[2] * (1 - s) + b[2] * s,
    a[3] * (1 - s) + b[3] * s,
    a[4] * (1 - s) + b[4] * s,
  }
end

local colors = {
  Black, DarkBlue, Maroon, DarkGreen,
  Brown, DarkGray, LightGray, White,
  Red, Orange, Yellow, Green, Blue,
  Gray, Pink, Tan,
}

local bright_colors = {
  Maroon, Brown, White, Red, Orange, Yellow, Green, Blue, Gray, Pink, Tan,
}

local bright_index = 1

local function next_bright_color()
  local c = bright_colors[math.random(1, #bright_colors)]
  return c
end

return {
  mix_color = mix_color,
  next_bright_color = next_bright_color,
  hex = hex,

  black = Black,
  dark_blue = DarkBlue,
  maroon = Maroon,
  dark_green = DarkGreen,
  brown = Brown,
  dark_gray = DarkGray,
  light_gray = LightGray,
  white = White,
  red = Red,
  orange = Orange,
  yellow = Yellow,
  green = Green,
  blue = Blue,
  gray = Gray,
  pink = Pink,
  tan = Tan,

  colors = colors,
}
