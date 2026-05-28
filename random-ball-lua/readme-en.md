# Random Ball Packing Example

This example uses LuaLaTeX to compute ball positions at compile time, then emits TikZ drawing commands for the final image. The core implementation is inside the `luacode*` block in `mwe.tex`; the two `tikzpicture` environments at the end call the same Lua functions with different containers and styles.

## How to Build

Compile the file with LuaLaTeX, because the implementation depends on `luacode`, `\directlua`, and Lua's standard math library.

```powershell
lualatex mwe.tex
```

With `latexmk`:

```powershell
latexmk -lualatex mwe.tex
```

## High-Level Structure

All Lua functions are stored in the global `physics` table:

- `physics.trapezoid_walls(...)`: converts four corner points into container wall segments.
- `physics.prepare_walls(raw_walls)`: precomputes direction vectors, lengths, normals, and line constants for every wall.
- `physics.draw_walls(walls, style)`: emits TikZ `\draw` commands for the walls.
- `physics.draw_packed_balls(num_balls, r, raw_walls, options)`: the main function; it handles random drops, candidate generation, collision checks, stable-position selection, and drawing.

TikZ does not perform the placement logic. Lua first computes each circle center, then prints commands like:

```tex
\draw[<ball_style>] (<x>,<y>) circle (<r>);
\fill[<highlight_style>] (<x>,<y>) circle (<small-r>);
```

## Container and Wall Representation

`trapezoid_walls(left_top, left_bottom, right_bottom, right_top)` receives four points in `{x, y}` form. It returns three wall segments:

1. Left wall: `left_top -> left_bottom`
2. Bottom wall: `left_bottom -> right_bottom`
3. Right wall: `right_bottom -> right_top`

The top side is intentionally open, so balls can be placed as if they were dropped into the container from above.

Each raw wall has the form `{x1, y1, x2, y2}`. `prepare_walls` expands it into a table with cached geometric data:

- `dx`, `dy`: wall direction vector.
- `len`: wall length.
- `nx`, `ny`: wall normal, computed as `(-dy / len, dx / len)`.
- `c`: line constant satisfying `nx * x + ny * y = c`.

All later checks, including containment and wall contact, use these precomputed values.

## Circle and Collision Model

Every ball has radius `r`. Two ball centers must be at least `2 * r` apart:

```lua
local contact_dist = 2 * r
```

For a wall, a valid ball center must remain at least `r` away from the wall. The feasible half-plane is:

```lua
wall.nx * x + wall.ny * y >= wall.c + r
```

If this condition fails for any wall, `inside_container(x, y)` returns `false`.

Ball-ball overlap detection is handled by `overlaps_any(x, y)`. It checks the squared distance from the proposed center to every already placed ball. If the squared distance is less than `(2r)^2`, the new ball would overlap an existing one. The code uses `eps = 1e-7` as a numerical tolerance so that exact contacts are not rejected because of floating-point noise.

## Random Drops and Candidate Points

The algorithm is not a continuous-time physics simulation. Instead, it constructs geometric candidate positions that correspond to stable contact configurations.

For each new ball, the code first chooses a random horizontal starting coordinate within the container's horizontal bounds:

```lua
local x_start = x_left + math.random() * (x_right - x_left)
```

It then gathers candidate centers. Every candidate must:

- lie inside the container,
- avoid overlap with all already placed balls,
- come from a stable contact relationship.

Finally, `choose_candidate` selects the candidate with the smallest `y`; if two candidates have almost the same height, it chooses the one closest to `x_start`. In the example coordinate system, the bottom of the container has smaller `y` values, so this approximates a ball falling to the lowest reachable stable position.

## Candidate Types

### 1. Wall Drop Candidate: `floor-wall`

`add_wall_drop_candidate(candidates, wall, x_start)` computes a center located above a supporting wall at a fixed `x_start`.

The function only accepts walls with `wall.ny > 0.9`, which means the wall normal points mostly upward. Such walls behave like floors or shallow supporting slopes. The center must satisfy:

```lua
wall.nx * x_start + wall.ny * y = wall.c + r
```

Solving for `y` gives:

```lua
y = (wall.c + r - wall.nx * x_start) / wall.ny
```

The point is accepted only if its projection falls on the finite wall segment.

### 2. Two-Wall Candidate: `two-walls`

`add_wall_wall_candidate(candidates, a, b)` computes the center of a ball touching two walls at the same time.

Both walls are offset inward by the ball radius. The center must satisfy:

```lua
a.nx * x + a.ny * y = a.c + r
b.nx * x + b.ny * y = b.c + r
```

This is a 2x2 linear system. The determinant

```lua
det = a.nx * b.ny - a.ny * b.nx
```

is used to reject parallel lines. For non-parallel lines, the code solves the intersection directly, then checks that the point projects onto both wall segments and passes the common containment and overlap filters.

This candidate type mainly covers container corners, such as the intersection between a bottom wall and a side wall.

### 3. Wall-Ball Candidate: `wall-ball`

`add_wall_ball_candidate(candidates, wall, ball)` computes centers for a new ball that touches one wall and one existing ball.

The signed distance from the existing ball center to the offset center line is:

```lua
signed_dist = wall.nx * ball.x + wall.ny * ball.y - (wall.c + r)
```

The new center must also be exactly `2r` from the existing ball center. Geometrically, this is the intersection between a line and a circle centered at the existing ball with radius `2r`. The code projects the existing center onto the offset line, then moves in both tangent directions along the wall to produce up to two intersection points.

To simulate upward stacking, it only accepts points whose `y` coordinate is higher than the supporting ball:

```lua
if y1 > ball.y + eps then ...
```

### 4. Two-Ball Candidate: `two-balls`

`add_two_ball_candidates(candidates, a, b)` computes centers for a new ball touching two existing balls.

The new center must be at distance `2r` from both existing centers, so it lies at the intersection of two equal-radius circles. The implementation:

1. computes the distance `d` between the two existing centers,
2. rejects cases where the centers are too close or farther apart than `4r`,
3. computes the midpoint,
4. computes the perpendicular offset height `h`,
5. generates the two possible intersection points along the perpendicular direction.

Again, only points above both supporting balls are accepted.

## Candidate Filtering

All generated points go through `add_candidate`:

```lua
if inside_container(x, y) and not overlaps_any(x, y) then
    table.insert(candidates, {x = x, y = y, kind = kind})
end
```

This keeps candidate generation focused on geometry while applying containment and collision rules consistently in one place.

## Position Selection

`choose_candidate(candidates, x_start)` selects a point using this priority:

1. prefer the smaller `y` value,
2. if heights are nearly equal, prefer the point closer to the random starting `x_start`.

This is an approximation of a ball dropped from above and settling at the lowest stable contact position. Randomness only affects the starting horizontal coordinate; the final center is still determined by walls and previously placed balls.

If no legal candidate exists, the function reports a LuaTeX error:

```lua
tex.error("no stable position found for ball " .. i)
```

This usually means the requested number of balls, ball radius, or container shape no longer leaves enough valid space.

## Drawing Flow

Each ball is drawn immediately after it is placed:

```lua
tex.print(string.format("\\draw[%s] (%.3f,%.3f) circle (%.3f);", ...))
```

Unless `draw_highlight` is explicitly set to `false`, a small highlight is drawn in the upper-left area of the ball:

```lua
best_x - 0.35 * r
best_y + 0.35 * r
0.22 * r
```

After all balls are drawn, `physics.draw_walls(walls, wall_style)` draws the container walls. This makes the wall strokes appear above the ball edges, which helps the balls look contained.

## Options

`draw_packed_balls(num_balls, r, raw_walls, options)` supports:

- `num_balls`: number of balls to place.
- `r`: ball radius in TikZ coordinate units.
- `raw_walls`: array of wall segments, usually created with `trapezoid_walls`.
- `options.seed`: random seed. The same seed gives reproducible output.
- `options.ball_style`: TikZ style for the balls.
- `options.wall_style`: TikZ style for the walls.
- `options.highlight_style`: TikZ style for highlights.
- `options.draw_highlight`: whether to draw highlights; defaults to `true`.

For simple calls, `options` can also be a raw seed. Non-table values are converted to `{seed = options}`.

## Example Call

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

This creates an open trapezoid container, places 20 balls with radius `0.14`, and uses a fixed random seed so the result is reproducible.

## Limitations

- This is not a full physics engine. It has no velocity, gravity integration, friction, or elastic collision response.
- The algorithm approximates stable packing through geometric contact points, which is suitable for static illustrations.
- Containers are represented as line segments; the helper function currently creates a three-sided open trapezoid.
- Wall normals must point toward the container interior, otherwise `inside_container` will test the wrong side.
- If the ball count is too high, the radius is too large, or the container is too narrow, the code may fail with a TeX error because no stable legal point can be found.

