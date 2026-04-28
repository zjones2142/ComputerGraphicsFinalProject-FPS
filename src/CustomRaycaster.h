#ifndef CUSTOM_RAYCASTER_H
#define CUSTOM_RAYCASTER_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class CustomRaycaster : public Node {
    GDCLASS(CustomRaycaster, Node)

protected:
    static void _bind_methods();

public:
    CustomRaycaster();
    ~CustomRaycaster();

    // Returns the distance to the hit, or -1.0 if it missed.
    float check_sphere_hit(Vector3 ray_origin, Vector3 ray_dir, Vector3 sphere_center, float sphere_radius);
};

} // namespace godot

#endif // CUSTOM_RAYCASTER_H