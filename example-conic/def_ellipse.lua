-- the file def_ellipse.lua

init_elements()
function def_ellipse(o, p, ratio)
 local a = line(o, p).length
 local b = a * ratio
 local pc = (p - o):orthogonal(b): at (o)
 local pa = o:symmetry(p)
 return o, pa, pc
end