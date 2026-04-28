# Computer Graphics Final Project — FPS Target Range

> **School project** — Demonstrates a custom raycaster implemented directly in C++ with OpenGL-style math, integrated into a first-person shooter built in Godot 4 via GDExtension and godot-cpp.

---

## Overview

This project is a first-person target-shooting range built in **Godot 4**. The core academic goal is to bypass Godot's built-in physics raycasting and instead implement the ray–sphere intersection algorithm from scratch in **C++**, exposing it to the engine through the **GDExtension** / **godot-cpp** native extension system. The C++ code mirrors the kind of geometry calculations typically written directly against OpenGL in a software renderer.

When the player fires, GDScript collects the camera's world position and forward direction, passes them to the C++ node, and the native code determines the exact hit distance using analytic geometry — no physics engine involved.

---

## Features

- **Custom C++ raycaster** — analytic ray–sphere intersection written with OpenGL-style vector math (`godot-cpp` types: `Vector3`, dot product, length, etc.)
- **GDExtension integration** — the raycaster is compiled as a native shared library (`.dll` / `.so`) and loaded by Godot as a first-class node (`CustomRaycaster`)
- **FPS movement** — WASD + mouse-look with clamped pitch, gravity, and jump
- **9 spherical targets** — placed in a shooting range; targets are removed on hit
- **Accuracy HUD** — live accuracy percentage, miss counter, and FPS counter
- **Pause menu** — resume, video/display settings (resolution, window mode, UI scale), player sensitivity slider, crosshair size, and exit
- **In-world control panel** — 3-D buttons to reset targets and reset the accuracy tracker without leaving the game

---

## Project Structure

```
.
├── SConstruct                  # Build script — compiles the C++ extension via godot-cpp
├── godot-cpp/                  # godot-cpp submodule (Godot's official C++ binding library)
├── src/
│   ├── CustomRaycaster.h       # GDExtension node declaration
│   ├── CustomRaycaster.cpp     # Ray–sphere intersection implementation
│   ├── register_types.h/.cpp   # Extension entry point — registers CustomRaycaster with Godot
└── gc-fps-game/                # Godot 4 project
    ├── project.godot
    ├── node_3d.tscn            # Main scene (range, player, targets, UI)
    ├── player.gd               # Player controller + weapon logic (calls the C++ node)
    ├── pause_menu.gd
    ├── reset_targets_button.gd
    ├── reset_accuracy_button.gd
    └── bin/                    # Compiled native library lands here
```

---

## How the Raycaster Works

The `CustomRaycaster` node exposes a single method:

```gdscript
var hit_dist = raycaster.check_sphere_hit(origin, direction, sphere_center, radius)
```

Internally, the C++ implementation performs an analytic ray–sphere test:

1. Compute the vector **L** from the ray origin to the sphere center.
2. Project **L** onto the normalised ray direction to get `tca` (closest approach along the ray).
3. Use the Pythagorean theorem to find `d²` (squared perpendicular distance from the ray to the sphere center).
4. If `d² > r²` the ray misses; otherwise solve for the near intersection distance `t = tca - √(r² - d²)`.
5. Return the hit distance, or `-1.0` on a miss.

This is the same intersection test used in classic software raytracers and in OpenGL-based custom rendering pipelines.

---

## Building the Extension

**Prerequisites**

| Tool | Version |
|------|---------|
| Python | 3.6+ |
| SCons | 4.x |
| C++ compiler | MSVC (Windows) or GCC/Clang (Linux/macOS) |
| Godot | 4.6 |

**Steps**

```bash
# 1. Clone with submodules
git clone --recurse-submodules <repo-url>
cd ComputerGraphicsFinalProject-FPS

# 2. Build the native library
scons

# 3. Open the Godot project
#    Launch Godot 4, import gc-fps-game/project.godot, then run the scene.
```

The compiled library is automatically placed in `gc-fps-game/bin/` with Godot's standard naming convention (`custom_raycaster.<platform>.<arch>.dll` / `.so`).

---

## Controls

| Input | Action |
|-------|--------|
| W / A / S / D | Move |
| Mouse | Look |
| Left Mouse Button | Shoot |
| Space | Jump |
| Escape | Pause menu |

---

## Technologies

- **Godot 4.6** — game engine and scene management
- **GDExtension** — Godot's native extension API
- **godot-cpp** — official C++ bindings for GDExtension
- **SCons** — build system used by godot-cpp
- **GDScript** — player controller, UI, game logic
- **C++** — custom raycaster (ray–sphere intersection)
