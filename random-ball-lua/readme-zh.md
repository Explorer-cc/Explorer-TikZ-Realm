# 随机小球堆叠示例

这个示例使用 LuaLaTeX 在编译时计算小球的位置，再把结果输出为 TikZ 绘图命令。核心代码位于 `mwe.tex` 的 `luacode*` 环境中，文档末尾的两个 `tikzpicture` 分别调用同一套 Lua 函数，生成两个不同容器中的随机堆叠效果。

## 运行方式

需要使用 LuaLaTeX 编译，因为代码依赖 `luacode`、`\directlua` 以及 Lua 的标准数学函数。

```powershell
lualatex mwe.tex
```

如果使用 `latexmk`：

```powershell
latexmk -lualatex mwe.tex
```

## 总体结构

代码把所有函数放在全局表 `physics` 中：

- `physics.trapezoid_walls(...)`：把四个顶点转换成容器墙体线段。
- `physics.prepare_walls(raw_walls)`：为每条墙计算方向、长度、法向量和直线常数。
- `physics.draw_walls(walls, style)`：把墙体输出成 TikZ 的 `\draw` 命令。
- `physics.draw_packed_balls(num_balls, r, raw_walls, options)`：主函数，负责随机投放、候选位置计算、碰撞检测和绘制小球。

TikZ 本身不参与物理计算。Lua 先决定每个圆心坐标，再通过 `tex.print` 输出类似下面的命令：

```tex
\draw[<ball_style>] (<x>,<y>) circle (<r>);
\fill[<highlight_style>] (<x>,<y>) circle (<small-r>);
```

## 容器和墙体表示

`trapezoid_walls(left_top, left_bottom, right_bottom, right_top)` 接收四个点，每个点都是 `{x, y}` 形式。函数返回三条墙：

1. 左墙：`left_top -> left_bottom`
2. 底墙：`left_bottom -> right_bottom`
3. 右墙：`right_bottom -> right_top`

顶部是开放的，所以不会生成顶墙。这样小球可以从上方“落入”容器。

原始墙体格式是 `{x1, y1, x2, y2}`。`prepare_walls` 会把它扩展成包含几何缓存的表：

- `dx`, `dy`：墙体方向向量。
- `len`：墙体长度。
- `nx`, `ny`：墙体法向量，计算式为 `(-dy / len, dx / len)`。
- `c`：直线常数，满足 `nx * x + ny * y = c`。

后续所有“圆是否在容器内”“圆是否接触墙体”等判断，都使用这些预计算值，避免反复推导。

## 圆和碰撞模型

每个小球半径为 `r`。圆心之间至少要相隔 `2 * r`，代码中记为：

```lua
local contact_dist = 2 * r
```

墙体约束的含义是：圆心必须与墙保持至少 `r` 的距离。对于一条墙，圆心的可行区域由下面的不等式描述：

```lua
wall.nx * x + wall.ny * y >= wall.c + r
```

如果任何一条墙不满足这个条件，`inside_container(x, y)` 就返回 `false`。

圆与圆的重叠检测由 `overlaps_any(x, y)` 完成。它遍历已经放置的小球，如果两个圆心距离的平方小于 `(2r)^2`，就认为发生重叠。代码使用 `eps = 1e-7` 作为数值容差，避免浮点误差导致临界接触被误判。

## 随机投放和候选点思想

主函数不是做连续时间物理模拟，而是用几何构造直接寻找“稳定接触点”。

对每一个新球，算法先在容器横向范围内随机选择一个起始横坐标：

```lua
local x_start = x_left + math.random() * (x_right - x_left)
```

然后收集一批候选圆心。每个候选点必须同时满足：

- 在容器内部。
- 不与已有小球重叠。
- 来自某一种稳定接触关系。

最后 `choose_candidate` 选择 `y` 最小的候选点；如果高度相同，则选择离 `x_start` 更近的点。由于示例坐标系中容器底部的 `y` 更小，这相当于让球落到当前可达的最低稳定位置。

## 候选点类型

### 1. 墙面下落候选：`floor-wall`

`add_wall_drop_candidate(candidates, wall, x_start)` 计算一条近似水平的承托墙上、指定 `x_start` 处的圆心位置。

代码只接受 `wall.ny > 0.9` 的墙，这意味着这条墙的法向量基本向上，适合作为底面或斜率较小的承托面。圆心满足：

```lua
wall.nx * x_start + wall.ny * y = wall.c + r
```

整理后得到：

```lua
y = (wall.c + r - wall.nx * x_start) / wall.ny
```

如果投影点落在墙段范围内，就加入候选列表。

### 2. 双墙候选：`two-walls`

`add_wall_wall_candidate(candidates, a, b)` 计算一个圆同时接触两条墙时的圆心。

对两条墙分别向容器内部偏移 `r`，圆心必须同时满足：

```lua
a.nx * x + a.ny * y = a.c + r
b.nx * x + b.ny * y = b.c + r
```

这是一个二元一次方程组。代码用行列式 `det = a.nx * b.ny - a.ny * b.nx` 判断两条偏移线是否平行；不平行时直接求交点。随后再检查该点是否投影到两条墙段之内，以及是否在容器中、是否与已有球重叠。

这类候选主要用于容器角落，例如底墙和侧墙形成的角。

### 3. 墙-球候选：`wall-ball`

`add_wall_ball_candidate(candidates, wall, ball)` 计算一个新球同时接触一条墙和一个已有小球时的圆心。

已有球圆心到“圆心可行偏移线”的有符号距离为：

```lua
signed_dist = wall.nx * ball.x + wall.ny * ball.y - (wall.c + r)
```

新球圆心还必须距离已有球 `2r`。因此问题变成：一条直线与一个半径为 `2r`、圆心为已有球圆心的圆相交。代码先把已有球投影到偏移线上，得到 `base_x, base_y`，再沿墙体切向量 `tx, ty` 向两边移动距离 `h`，得到两个可能交点。

为了模拟“向上堆叠”，代码只接受 `y` 比被接触球更高的点：

```lua
if y1 > ball.y + eps then ...
```

### 4. 双球候选：`two-balls`

`add_two_ball_candidates(candidates, a, b)` 计算一个新球同时接触两个已有小球时的圆心。

新球圆心必须同时距离两个已有圆心 `2r`，所以它位于两个等半径圆的交点上。实现步骤是：

1. 计算两个已有圆心的距离 `d`。
2. 如果 `d` 太小或大于 `4r`，两圆没有有效交点。
3. 计算中点 `m`。
4. 计算垂直方向上的偏移高度 `h`。
5. 沿两球连线的垂线生成两个交点。

同样，代码只接受比两个支撑球都更高的交点，以避免生成下方或不稳定位置。

## 候选过滤

所有候选点最终都会经过 `add_candidate`：

```lua
if inside_container(x, y) and not overlaps_any(x, y) then
    table.insert(candidates, {x = x, y = y, kind = kind})
end
```

因此，各个候选生成函数只负责“几何上可能在哪里接触”，统一的合法性检查则集中在一个入口中。这让主逻辑更清晰，也避免不同候选类型之间出现不一致的碰撞规则。

## 位置选择策略

`choose_candidate(candidates, x_start)` 按以下优先级选点：

1. `y` 更小者优先。
2. 如果 `y` 几乎相同，选择离随机起始横坐标 `x_start` 更近者。

这个策略不是完整的刚体动力学，但能生成接近“从上方落下后停在最低接触位置”的效果。随机性只影响每个球的起始横坐标，最终位置仍由墙和已有小球的几何约束决定。

如果没有找到任何合法候选点，代码会调用：

```lua
tex.error("no stable position found for ball " .. i)
```

这会让 LuaLaTeX 报错，提示当前容器、半径或球数设置已经无法继续稳定放置。

## 绘制流程

每放置一个小球，代码立即输出一个圆：

```lua
tex.print(string.format("\\draw[%s] (%.3f,%.3f) circle (%.3f);", ...))
```

如果 `draw_highlight` 没有被显式设为 `false`，还会在左上方绘制一个小高光：

```lua
best_x - 0.35 * r
best_y + 0.35 * r
0.22 * r
```

所有小球绘制完成后，再调用 `physics.draw_walls(walls, wall_style)` 绘制墙体。这样墙线会覆盖在球的边缘之上，视觉上更像小球被容器包住。

## 可配置项

`draw_packed_balls(num_balls, r, raw_walls, options)` 支持以下参数：

- `num_balls`：小球数量。
- `r`：小球半径，单位与 TikZ 坐标一致。
- `raw_walls`：墙体数组，通常由 `trapezoid_walls` 生成。
- `options.seed`：随机种子。相同种子会生成可复现结果。
- `options.ball_style`：TikZ 圆形样式。
- `options.wall_style`：TikZ 墙体线段样式。
- `options.highlight_style`：TikZ 高光样式。
- `options.draw_highlight`：是否绘制高光，默认为 `true`。

为了兼容简单调用，`options` 也可以直接传一个 seed；代码会把非表类型转换为 `{seed = options}`。

## 示例调用

```tex
\directlua{
    physics.draw_packed_balls(20, 0.14,
        physics.trapezoid_walls({-1.3, 0}, {-0.8, -3}, {0.8, -3}, {1.3, 0}),
        {
            seed = 12345,
            ball_style = "line width=0.5pt, draw=orange!60!black, fill=orange!80!yellow",
            wall_style = "ultra thick, draw=black, line cap=rect",
            highlight_style = "fill=white, opacity=0.55",
        })
}
```

这个调用创建一个上宽下窄的开放梯形容器，放入 20 个半径为 `0.14` 的小球，并使用固定随机种子保证每次编译结果一致。

## 实现限制

- 这不是精确物理引擎，没有速度、重力积分、摩擦或弹性碰撞。
- 算法通过几何接触点近似“稳定堆叠”，适合静态插图。
- 容器目前由线段墙组成，示例工具函数只生成三边开放梯形。
- 墙体法向量方向必须指向容器内部，否则 `inside_container` 的判断会反向。
- 球数过多、半径过大或容器过窄时，可能找不到合法稳定点并触发 TeX 错误。

