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

function mix_color(a, b, strength)
    local s = strength or 0.5
    return {
        a[1] * (1 - s) + b[1] * s,
        a[2] * (1 - s) + b[2] * s,
        a[3] * (1 - s) + b[3] * s,
        a[4] * (1 - s) + b[4] * s,
    }
end
