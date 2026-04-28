#include "CustomRaycaster.h"
#include <godot_cpp/core/class_db.hpp>
#include <cmath>

using namespace godot;

void CustomRaycaster::_bind_methods() {
    ClassDB::bind_method(D_METHOD("check_sphere_hit", "ray_origin", "ray_dir", "sphere_center", "sphere_radius"), &CustomRaycaster::check_sphere_hit);
}

CustomRaycaster::CustomRaycaster() {}
CustomRaycaster::~CustomRaycaster() {}

float CustomRaycaster::check_sphere_hit(Vector3 ray_origin, Vector3 ray_dir, Vector3 sphere_center, float sphere_radius) {
    Vector3 d = ray_dir.normalized();
    Vector3 L = sphere_center - ray_origin;
    
    float tca = L.dot(d);
    
    if (tca < 0) {
        return -1.0f; 
    }
    
    float d2 = L.length_squared() - (tca * tca);
    float radius2 = sphere_radius * sphere_radius;
    
    if (d2 > radius2) {
        return -1.0f; 
    }
    
    // Changed Math::sqrt to std::sqrt
    float thc = std::sqrt(radius2 - d2);
    float hit_distance = tca - thc; 
    
    return hit_distance; 
}