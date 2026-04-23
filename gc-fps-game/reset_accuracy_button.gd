extends MeshInstance3D

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
	label_3d.text = "RESET\nACCURACY"

func activate() -> void:
	set_surface_override_material(0, red_mat)
	label_3d.text = "RESETTING..."

	var player = get_tree().root.find_child("Player", true, false)
	if player:
		player.total_shots = 0
		player.total_hits = 0
		player.update_accuracy_ui()

	await get_tree().create_timer(0.5).timeout
	set_surface_override_material(0, green_mat)
	label_3d.text = "RESET\nACCURACY"
