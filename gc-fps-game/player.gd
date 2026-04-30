extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var mouse_sensitivity: float = 0.002

@onready var camera = $Camera3D
@onready var accuracy_label = $"../UI/HUD/AccuracyLabel"
@onready var misses_label = $"../UI/HUD/MissesLabel"
@onready var fps_label = $"../UI/HUD/FPSLabel"
@onready var reset_targets_btn = $"../ControlPanel/ResetTargetsButton"
@onready var reset_accuracy_btn = $"../ControlPanel/ResetAccuracyButton"
@onready var raycaster = $CustomRaycaster

var total_shots: int = 0
var total_hits: int = 0

# for raycast demo (vars)
var show_raycast_laser: bool = false
var raycast_line: MeshInstance3D

func _ready() -> void:
	# Lock the mouse to the center of the screen
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	# Handle Mouselook
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		# Prevent the camera from flipping upside down
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Transform the input direction to be relative to where the player is currently facing
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Godot's built-in physics movement execution
	move_and_slide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		fire_weapon()
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func fire_weapon() -> void:
	total_shots += 1
	
	var origin = camera.global_position
	var direction = -camera.global_transform.basis.z 
	
	# Check reset targets button (no shot cost)
	if reset_targets_btn:
		var to_btn = reset_targets_btn.global_position - origin
		if direction.angle_to(to_btn) < 0.2:
			reset_targets_btn.activate()
			return

	# Check reset accuracy button (no shot cost)
	if reset_accuracy_btn:
		var to_btn = reset_accuracy_btn.global_position - origin
		if direction.angle_to(to_btn) < 0.2:
			reset_accuracy_btn.activate()
			return
	
	var closest_distance = INF
	var hit_target = null
	
	var targets = get_tree().get_nodes_in_group("Targets")
	
	for target in targets:
		var sphere_center = target.global_position
		
		# Assuming visual target is a standard Godot Sphere (default radius 0.5)
		# We multiply 0.5 by the target's X scale so it matches perfectly even if you shrink/grow the target!
		var exact_visual_radius = 0.5 * target.scale.x 
		
		# Feed the perfectly matched radius to our C++ math
		var hit_dist = raycaster.check_sphere_hit(origin, direction, sphere_center, exact_visual_radius)
			
		if hit_dist > 0.0 and hit_dist < closest_distance:
			closest_distance = hit_dist
			hit_target = target
			
	# Calculate where the raycast bullet should end visually
	var end_point = origin + (direction * 100.0) # Shoot way out to 100m if we miss
	
	if hit_target != null:
		total_hits += 1
		print("Hit! Target: ", hit_target.name)
		hit_target.queue_free() 
	else:
		print("Miss.")
		
	update_accuracy_ui()
	
	# Draw the laser starting from the Gun mesh
	var gun_node = $Camera3D/Gun
	
	draw_laser(origin, end_point)

func update_accuracy_ui() -> void:
	var misses = total_shots - total_hits
	var accuracy = 0.0
	if total_shots > 0:
		accuracy = (float(total_hits) / float(total_shots)) * 100.0

	accuracy_label.text = "Accuracy: %.1f%%" % accuracy
	misses_label.text = "Misses: %d" % misses
	
# Raycast Drawing Function 
func draw_laser(start_pos: Vector3, end_pos: Vector3) -> void:
	# If the toggle is off, hide the line and don't draw a new one
	if not show_raycast_laser:
		if raycast_line and is_instance_valid(raycast_line) and raycast_line.visible:
			raycast_line.visible = false
		return
		
	# Create the line visualizer if it doesn't exist yet
	if not raycast_line or not is_instance_valid(raycast_line):
		raycast_line = MeshInstance3D.new()
		var mesh = ImmediateMesh.new()
		raycast_line.mesh = mesh
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0, 0) # Red laser color
		mat.emission_enabled = true
		mat.emission = Color(1, 0, 0)
		mat.emission_energy = 5.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		raycast_line.material_override = mat
		
		# Add it to the main scene tree so it stays behind when we look around
		get_tree().root.add_child(raycast_line)
		
	raycast_line.visible = true
	var mesh = raycast_line.mesh as ImmediateMesh
	mesh.clear_surfaces() # This makes the old line disappear immediately!
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(start_pos)
	mesh.surface_add_vertex(end_pos)
	mesh.surface_end()
