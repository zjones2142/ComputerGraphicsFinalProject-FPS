extends Control

# This allows us to link the player in the inspector to update their sensitivity
@export var player: CharacterBody3D

@onready var main_panel = $MainPanel
@onready var settings_panel = $SettingsPanel
@onready var sensitivity_slider = $SettingsPanel/TabContainer/PlayerOptions/SensitivitySlider
@onready var window_mode_dropdown = $SettingsPanel/TabContainer/Video/WindowModeDropdown
@onready var resolution_dropdown = $SettingsPanel/TabContainer/Video/ResolutionDropdown
@onready var ui_scale_slider: SpinBox = $SettingsPanel/TabContainer/Video/UIScaleSlider
@onready var tab_container = $SettingsPanel/TabContainer  # for tab button font scaling
@onready var all_ui_nodes: Array = []
@onready var all_spinboxes: Array = []

# Crosshair Nodes
@onready var crosshair_size_slider: SpinBox = $SettingsPanel/TabContainer/Crosshair/CrosshairSizeSlider
@onready var crosshair_color_picker: ColorPickerButton = $SettingsPanel/TabContainer/Crosshair/CrosshairColorPicker
@onready var crosshair_type_dropdown: OptionButton = $SettingsPanel/TabContainer/Crosshair/CrosshairTypeDropdown
@onready var crosshair_container: Control = $"../../CrosshairLayer/CrosshairContainer"
@onready var crosshair_rect: ColorRect = $"../../CrosshairLayer/CrosshairContainer/ColorRect"

const BASE_FONT_SIZE: int = 20
const BASE_MIN_SIZE: Vector2 = Vector2(450, 300)

var resolutions = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

# Crosshair State Variables
var crosshair_color: Color = Color.WHITE
var crosshair_type: int = 0
var crosshair_size: float = 1.0

func _ready() -> void:
	# Hide the menu when the game starts
	hide()
	settings_panel.hide()
	
	# Collect HUD labels to resize
	var ui = get_parent()
	
	# HUD labels
	all_ui_nodes = [
		ui.get_node("HUD/AccuracyLabel"),
		ui.get_node("HUD/MissesLabel"),
		ui.get_node("HUD/FPSLabel"),
	]
	
	# Pause menu buttons and labels — collect every Label and Button recursively
	_collect_text_nodes(self, all_ui_nodes)
	
	# Populate the Video Dropdown
	window_mode_dropdown.add_item("Windowed")
	window_mode_dropdown.add_item("Fullscreen")
	
	resolution_dropdown.add_item("1280 x 720")
	resolution_dropdown.add_item("1600 x 900")
	resolution_dropdown.add_item("1920 x 1080")
	resolution_dropdown.add_item("2560 x 1440")
	resolution_dropdown.add_item("3840 x 2160")
	
	# Wire up all button signals via code so you don't have to do it in the editor
	$MainPanel/ResumeButton.pressed.connect(_on_resume_pressed)
	$MainPanel/SettingsButton.pressed.connect(_on_settings_pressed)
	$MainPanel/ExitButton.pressed.connect(_on_exit_pressed)
	$SettingsPanel/BackButton.pressed.connect(_on_back_pressed)
	
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	window_mode_dropdown.item_selected.connect(_on_window_mode_selected)
	resolution_dropdown.item_selected.connect(_on_resolution_selected)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	crosshair_size_slider.value_changed.connect(_on_crosshair_size_changed)
	
	# Initialize Crosshair Settings
	crosshair_color = crosshair_color_picker.color
	crosshair_size = crosshair_size_slider.value
	
	crosshair_size_slider.value_changed.connect(_on_crosshair_size_changed)
	crosshair_color_picker.color_changed.connect(_on_crosshair_color_changed)
	crosshair_type_dropdown.item_selected.connect(_on_crosshair_type_selected)
	
	# Set up dynamic drawing and disable the old static color rect
	crosshair_rect.hide()
	crosshair_container.draw.connect(_draw_crosshair)
	crosshair_container.item_rect_changed.connect(func(): crosshair_container.queue_redraw()) # Redraw on window resize

# Recursively collect Labels, Buttons, OptionButtons, and SpinBoxes
func _collect_text_nodes(node: Node, result: Array) -> void:
	for child in node.get_children():
		if child is Label or child is Button or child is OptionButton:
			result.append(child)
		elif child is SpinBox:
			all_spinboxes.append(child)
		_collect_text_nodes(child, result)
		
func _input(event: InputEvent) -> void:
	# 'ui_cancel' is mapped to Escape by default
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var is_paused = get_tree().paused
	
	if is_paused:
		# Unpause
		get_tree().paused = false
		hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		# Pause
		get_tree().paused = true
		show()
		main_panel.show()
		settings_panel.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --- Main Menu Buttons ---

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_settings_pressed() -> void:
	main_panel.hide()
	settings_panel.show()
	# Sync the slider to the player's current sensitivity when opening the menu
	if player:
		sensitivity_slider.value = player.mouse_sensitivity

func _on_exit_pressed() -> void:
	get_tree().quit()

# --- Settings Menu ---

func _on_back_pressed() -> void:
	settings_panel.hide()
	main_panel.show()

func _on_sensitivity_changed(value: float) -> void:
	if player:
		player.mouse_sensitivity = value

func _on_window_mode_selected(index: int) -> void:
	if index == 0: # Windowed
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif index == 1: # Fullscreen
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _on_resolution_selected(index: int) -> void:
	var res = resolutions[index]
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(res)
	# Center the window on screen after resize
	var screen_size = DisplayServer.screen_get_size()
	DisplayServer.window_set_position((screen_size - res) / 2)

func _on_ui_scale_changed(value: float) -> void:
	var new_size = int(BASE_FONT_SIZE * value)

	# Scale labels, buttons, dropdowns
	for node in all_ui_nodes:
		if node:
			node.add_theme_font_size_override("font_size", new_size)

	# Scale tab buttons
	tab_container.add_theme_font_size_override("font_size", new_size)

	# Scale each SpinBox — both the box itself and its internal LineEdit
	for spinbox in all_spinboxes:
		if spinbox:
			spinbox.add_theme_font_size_override("font_size", new_size)
			var line_edit = spinbox.get_line_edit()
			if line_edit:
				line_edit.add_theme_font_size_override("font_size", new_size)

	# Scale and re-center the pause menu window
	custom_minimum_size = BASE_MIN_SIZE * value
	size = BASE_MIN_SIZE * value
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
# --- Crosshair Drawing & Updates ---
	
func _on_crosshair_size_changed(value: float) -> void:
	if crosshair_rect:
		var half = 2.0 * value
		crosshair_rect.offset_left = -half
		crosshair_rect.offset_top = -half
		crosshair_rect.offset_right = half
		crosshair_rect.offset_bottom = half
	crosshair_size = value
	crosshair_container.queue_redraw()

func _on_crosshair_color_changed(color: Color) -> void:
	crosshair_color = color
	crosshair_container.queue_redraw()

func _on_crosshair_type_selected(index: int) -> void:
	crosshair_type = index
	crosshair_container.queue_redraw()

func _draw_crosshair() -> void:
	var center = crosshair_container.size / 2.0
	var base_size = 4.0 * crosshair_size
	
	if crosshair_type == 0: # Dot
		var rect = Rect2(center - Vector2(base_size/2, base_size/2), Vector2(base_size, base_size))
		crosshair_container.draw_rect(rect, crosshair_color)
		
	elif crosshair_type == 1: # Cross
		var length = base_size * 4.0
		var thickness = base_size * 0.75
		# Horizontal line
		var h_rect = Rect2(center - Vector2(length/2, thickness/2), Vector2(length, thickness))
		crosshair_container.draw_rect(h_rect, crosshair_color)
		# Vertical line
		var v_rect = Rect2(center - Vector2(thickness/2, length/2), Vector2(thickness, length))
		crosshair_container.draw_rect(v_rect, crosshair_color)
		
	elif crosshair_type == 2: # Circle
		var radius = base_size * 2.0
		var thickness = base_size * 0.75
		crosshair_container.draw_arc(center, radius, 0, TAU, 32, crosshair_color, thickness, true)
