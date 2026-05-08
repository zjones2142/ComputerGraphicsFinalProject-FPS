# Computer Graphics Final Project — FPS Target Range

> **School project** — Demonstrates a custom raycaster implemented directly in C++ with OpenGL-style math, integrated into a first-person shooter built in Godot 4 via GDExtension and godot-cpp.

---

## Overview

This project is a first-person target-shooting range built in **Godot 4**. The main focus of the project is the implementation of a **custom raycasting system** in **C++** rather than relying on Godot’s built-in physics raycasts.

Our goal was to show how a graphics concept from class could be applied in an interactive game setting. Instead of using the engine’s default collision or raycast tools, we implemented the **ray–sphere intersection algorithm** ourselves and connected it to the Godot project using **GDExtension** and **godot-cpp**. This allowed us to combine game-engine development with lower-level graphics and math programming.

When the player fires, the game takes the camera position and forward shooting direction from GDScript and passes them into the C++ raycaster. The native code then calculates whether the ray intersects a target sphere and returns the hit distance. If a hit is detected, the target is removed. This is the core feature of the project and the main technical accomplishment.

Although the game is presented as an FPS target range, the most important part of the assignment is the raycasting implementation itself. The FPS setup exists mainly as a way to demonstrate that the custom raycaster works in a real-time interactive 3D environment.

---

## What the Project Demonstrates

This project demonstrates several computer graphics and programming concepts:

- **Raycasting using analytic geometry**
- **Ray–sphere intersection in C++**
- **Real-time interaction in a 3D environment**
- **Connecting native C++ code to Godot through GDExtension**
- **Use of vector math such as dot products, distances, and direction normalization**
- **Applying graphics/math concepts inside an interactive first-person project**

Rather than focusing on advanced combat mechanics or level design, this project focuses on showing that we can build and use our own ray-based hit detection system from scratch.

---

## Features

- **Custom C++ raycaster** — analytic ray–sphere intersection written with OpenGL-style vector math (`godot-cpp` types such as `Vector3`, dot product, length, and normalization)
- **GDExtension integration** — the raycaster is compiled as a native shared library and loaded by Godot as a custom node
- **FPS movement** — player movement with WASD and mouse-look
- **Target range gameplay** — spherical targets can be shot and removed when hit
- **Accuracy tracking** — includes hit/miss feedback and player accuracy statistics
- **Pause/settings menu** — includes game controls and interface options
- **Interactive reset controls** — allows the player to reset targets and continue testing the raycaster

---

## How the Raycaster Works

The `CustomRaycaster` node exposes a method used by the game when the player shoots:

```gdscript
var hit_dist = raycaster.check_sphere_hit(origin, direction, sphere_center, radius)
```

The raycasting logic is implemented analytically in C++. The process works as follows:

1. The game gets the ray **origin** from the player camera position.
2. The game gets the ray **direction** from where the player is aiming.
3. For each spherical target, the C++ code computes whether the ray intersects the sphere.
4. This is done using the **ray–sphere intersection formula**, not engine physics.
5. If the ray hits the sphere, the function returns the hit distance.
6. If there is no hit, the function returns `-1.0`.

More specifically, the algorithm:

- Computes the vector from the ray origin to the sphere center
- Projects that vector onto the ray direction
- Computes the perpendicular distance from the ray to the center of the sphere
- Compares that distance to the sphere radius
- If the ray intersects the sphere, solves for the nearest valid hit point

This is the same kind of math used in graphics programming, raytracing, and custom rendering systems. That is why the raycaster is the centerpiece of the project.

---

## Why Raycasting Was the Main Focus

The main purpose of this assignment was not just to make an FPS game, but to show a meaningful graphics technique implemented manually.

We chose raycasting because it directly connects to concepts from computer graphics:
- mathematical representation of rays
- object intersection testing
- geometric reasoning in 3D space
- real-time computation during gameplay

By building our own raycaster in C++, we showed how graphics math can be used to replace a built-in engine feature with a custom implementation. This made the project more technical and more aligned with the goals of a computer graphics final project.

---

## Project Structure

```text
.
├── SConstruct                  # Build script — compiles the C++ extension via godot-cpp
├── godot-cpp/                  # godot-cpp submodule (Godot's official C++ binding library)
├── src/
│   ├── CustomRaycaster.h       # GDExtension node declaration
│   ├── CustomRaycaster.cpp     # Ray–sphere intersection implementation
│   ├── register_types.h/.cpp   # Registers CustomRaycaster with Godot
└── gc-fps-game/                # Godot 4 project
    ├── project.godot
    ├── node_3d.tscn            # Main scene
    ├── player.gd               # Player logic and shooting code
    ├── pause_menu.gd
    ├── reset_targets_button.gd
    ├── reset_accuracy_button.gd
    └── bin/                    # Compiled native library output
```

---

## How to Compile and Run

### Prerequisites

| Tool | Version |
|------|---------|
| Python | 3.6+ |
| SCons | 4.x |
| C++ compiler | MSVC (Windows) or GCC/Clang (Linux/macOS) |
| Godot | 4.6 |

### Build Steps

```bash
# 1. Clone the repository with submodules
git clone --recurse-submodules https://github.com/zjones2142/ComputerGraphicsFinalProject-FPS.git
cd ComputerGraphicsFinalProject-FPS

# 2. Build the C++ GDExtension library
scons
```

After building:

1. Open **Godot 4**
2. Import the project located in `gc-fps-game/project.godot`
3. Run the main scene

The compiled native library is placed in `gc-fps-game/bin/`.

If the extension builds correctly, the Godot project will be able to call the custom C++ raycaster during gameplay.

---

## Controls

| Input | Action |
|-------|--------|
| W / A / S / D | Move |
| Mouse | Look around |
| Left Mouse Button | Shoot |
| Space | Jump |
| Escape | Open pause menu |

---

## Interactive Features

The main interactive features of the project are centered on testing the custom raycaster in real time:

- The player can move around the 3D scene in first person
- The player can aim using mouse-look
- Clicking shoots a ray from the player’s view direction
- The custom C++ code checks whether that ray hits a spherical target
- Targets disappear when hit
- Accuracy and miss statistics update during play
- Reset buttons allow repeated testing of the raycasting system

These features make the project interactive while also serving as a demonstration platform for the custom raycasting implementation.

---

## Technologies Used

- **Godot 4.6** — game engine and 3D scene framework
- **GDExtension** — interface for connecting native C++ code to Godot
- **godot-cpp** — official C++ bindings for Godot extensions
- **SCons** — build tool for the native extension
- **GDScript** — gameplay and UI scripting
- **C++** — custom raycasting implementation

---

## Conclusion

In summary, this project is a first-person target range built to demonstrate a **custom raycasting system**. The FPS format provides an interactive way to test and show the results, but the real emphasis of the project is the C++ implementation of ray–sphere intersection and its integration into Godot.

This project shows how computer graphics concepts can move beyond theory and be applied directly in a working real-time application. By replacing built-in engine raycasts with our own implementation, we created a project that is both interactive and technically focused on graphics programming.
