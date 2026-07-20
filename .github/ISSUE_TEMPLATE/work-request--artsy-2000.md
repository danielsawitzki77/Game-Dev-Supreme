---
name: 'Work request: Artsy_2000'
about: Do a change affecting Artsy_2000 (raytracer, physics, pixel rendering, freecam)
title: 'Work request for Artsy_2000: '
labels: ''
assignees: danielsawitzki77

---

We need a change or fix or improvement to be made in Artsy_2000. This is the software raytracer project with falling physics objects and artistic pixel output modes (quad, circle, primitive_sprite). Changes land in the `danielsawitzki77/Artsy_2000` repo.

**Components that may be affected:**
- `raytracer/` — Ray casting, Phong lighting, shape intersections (sphere, box, cylinder, cone, capsule), chunk-based partial rendering
- `physics/` — Rigid body dynamics, gravity, collision detection, impulse response, object spawning, FIFO pool
- `pixel_writer/` — Pixel output modes (quad, circle, primitive_sprite), sprite pool, SDL surface writing
- `math_lib/` — Vec3, Mat4, Ray, Color, shared math utilities
- `src/main.cpp` — Application entry point (SDL window, main loop, config loading)
- `config.json` — Runtime configuration (window size, internal resolution, render mode, physics params)

**Key subsystems:**
- **Chunk Renderer** — Random screen region selection, partial frame update (intentional tearing aesthetic)
- **Phong Shader** — Ambient, diffuse, specular, reflective lighting with configurable bounce depth (0–3)
- **Skybox Generator** — Plasma fractal procedural sky, pre-rendered at startup
- **Floor Plane** — Infinite checkered reflective XZ surface
- **Freecam** — WASD movement + Q/E roll, no mouse look
- **Spawner** — Continuous object rain near camera position
- **Object Pool** — FIFO eviction at max_objects cap

**Verification:**
- If changes affect rendering: describe expected visual output or attach a screenshot showing the raytraced scene.
- If changes affect physics: describe expected object behavior (falling, bouncing, stacking).
- If changes affect config: provide example JSON values for the new/modified parameters.

Here comes the actual ask of what needs to be done/fixed/extended:
