#!/usr/bin/env python
import os

# 1. Ask godot-cpp for its fully configured compiler environment!
env = SConscript("godot-cpp/SConstruct")

# 2. Point it to our custom code
env.Append(CPPPATH=["src/"])
sources = Glob("src/*.cpp")

# 3. Put the final DLL in our game folder
lib_dir = 'gc-fps-game/bin/'
if not os.path.exists(lib_dir):
    os.makedirs(lib_dir)

# 4. Compile using Godot's official naming suffixes (adds architecture to the name)
library = env.SharedLibrary(
    target=lib_dir + 'custom_raycaster{}{}'.format(env["suffix"], env["SHLIBSUFFIX"]), 
    source=sources
)

Default(library)