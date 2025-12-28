-- the file def_ellipse.lua

init_elements()
function def_ellipse(pa, pb, ratio)
 local axe = line:new(pa, pb)
 local o = axe.mid
 local a = 0.5 * axe.length
 local b = a * ratio
 -- local e = math.sqrt(a^2 - b^2)/a
 -- the previous line is useless, it can be deleted
 local pc = (pa - o):orthogonal(b): at (o)
 return o, pc
end