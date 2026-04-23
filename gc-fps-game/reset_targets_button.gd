extends MeshInstance3D

const TARGET_POSITIONS: Array[Vector3] = [
	Vector3(-12, 2,   -43),
	Vector3(-4,  2,   -43),
	Vector3( 4,  2,   -43),
	Vector3( 12, 2,   -43),
	Vector3(-8,  5,   -43),
	Vector3( 0,  5,   -43),
	Vector3( 8,  5,   -43),
	Vector3(-4,  7.5, -43),
	Vector3( 4,  7.5, -43),
]

@onready var label_3d = $Label3D
var green_mat: StandardMaterial3D
var red_mat: StandardMaterial3D

func _ready() -> void:
	green_mat = StandardMaterial3D.new()
	green_mat.albedo_color = Color(0.1, 0.4, 0.1, 1)
	green_mat.emission_enabled = true
	green_mat.emission = Color(0.0, 0.7, 0.0, 1)
	green_mat.emission_energy_multiplier = 0.5

	red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color(0.4, 0.1, 0.1, 1)
	red_mat.emission_enabled = true
	red_mat.emission = Color(0.7, 0.0, 0.0, 1)
	red_mat.emission_energy_multiplier = 0.5

	set_surface_override_material(0, green_mat)
	label_3d.text = "RESET\nTARGETS"

func activate() -> void:
	set_surface_override_material(0, red_mat)
	label_3d.text = "RESETTING..."

	for target in get_tree().get_nodes_in_group("Targets"):
		target.queue_free()

	await get_tree().process_frame

	var mat = preload("res://Materials/target_material.tres")
	var sphere_mesh = SphereMesh.new()
	var targets_parent = get_tree().root.find_child("Targets", true, false)

	for i in TARGET_POSITIONS.size():
		var t = MeshInstance3D.new()
		t.name = "Target%d" % (i + 1)
		t.mesh = sphere_mesh
		t.set_surface_override_material(0, mat)
		t.global_position = TARGET_POSITIONS[i]
		t.add_to_group("Targets")
		targets_parent.add_child(t)

	await get_tree().create_timer(0.5).timeout
	set_surface_override_material(0, green_mat)
	label_3d.text = "RESET\nTARGETS"
