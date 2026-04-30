extends Control

# This allows us to link the player in the inspector to update their sensitivity
@export var player: CharacterBody3D

@onready var main_panel = $MainPanel
@onready var settings_panel = $SettingsPanel
@onready var sensitivity_slider = $SettingsPanel/TabContainer/PlayerOptions/SensitivitySlider
@onready var raycast_demo_checkbox = $SettingsPanel/TabContainer/PlayerOptions/RaycastDemoCheckBox
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

const SAVE_PATH: String = "user://settings.cfg"# for saving settings

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
	raycast_demo_checkbox.toggled.connect(_on_raycast_demo_toggled)
	window_mode_dropdown.item_selected.connect(_on_window_mode_selected)
	resolution_dropdown.item_selected.connect(_on_resolution_selected)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	
	# Initialize Crosshair Settings
	crosshair_color = crosshair_color_picker.color
	crosshair_size = crosshair_size_slider.value
	
	# This will ensure Dot is selected and applied by default in the crosshair tab
	if crosshair_type_dropdown.selected == -1:
		crosshair_type_dropdown.select(0)#0 is dot duh lol
	crosshair_type = crosshair_type_dropdown.selected
	
	crosshair_size_slider.value_changed.connect(_on_crosshair_size_changed)
	crosshair_color_picker.color_changed.connect(_on_crosshair_color_changed)
	crosshair_type_dropdown.item_selected.connect(_on_crosshair_type_selected)
	
	# Set up dynamic drawing and disable the old static color rect
	if crosshair_rect:
		crosshair_rect.hide()
	crosshair_container.draw.connect(_draw_crosshair)
	crosshair_container.item_rect_changed.connect(func(): crosshair_container.queue_redraw()) # Redraw on window resize
	
	crosshair_container.queue_redraw()
	
	# Launch Defaults 
	# Force Fullscreen on Launch and disable resolution dropdown
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	window_mode_dropdown.select(1)
	resolution_dropdown.disabled = true
	
	# Load all settings from file (or apply launch defaults if none exist)
	load_settings()
	
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
		save_settings() # Save upon exiting the menu via Escape key
		get_tree().paused = false
		hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		crosshair_container.queue_redraw() # Snap crosshair back to center
	else:
		# Pause
		get_tree().paused = true
		show()
		main_panel.show()
		settings_panel.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		crosshair_container.queue_redraw() # Shift crosshair to the right for the crosshair viewer

# --- Save/Load System ---

func save_settings() -> void:
	var config = ConfigFile.new()
	
	# Video Settings
	config.set_value("Video", "window_mode", window_mode_dropdown.selected)
	config.set_value("Video", "resolution", resolution_dropdown.selected)
	config.set_value("Video", "ui_scale", ui_scale_slider.value)
	
	# Player Settings
	if player:
		config.set_value("Player", "sensitivity", player.mouse_sensitivity)
		if "show_raycast_laser" in player:
			config.set_value("Player", "show_raycast_laser", player.show_raycast_laser)
			
	# Crosshair Settings
	config.set_value("Crosshair", "size", crosshair_size)
	config.set_value("Crosshair", "color", crosshair_color)
	config.set_value("Crosshair", "type", crosshair_type)
	
	# Save to local app data folder
	config.save(SAVE_PATH)

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err != OK:
		# No save file found. Apply launch defaults and generate a fresh save file
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		window_mode_dropdown.select(1)
		resolution_dropdown.disabled = true
		
		# Ensure crosshair has a default Type
		if crosshair_type_dropdown.selected == -1:
			crosshair_type_dropdown.select(0)
		crosshair_type = crosshair_type_dropdown.selected
		
		save_settings()
		return
		
	# Load Video Settings
	var w_mode = config.get_value("Video", "window_mode", 1)
	window_mode_dropdown.select(w_mode)
	_on_window_mode_selected(w_mode) # Triggers the logic for resizing
	
	var res = config.get_value("Video", "resolution", 2)
	resolution_dropdown.select(res)
	if w_mode == 0:
		_on_resolution_selected(res)
		
	var ui_scale = config.get_value("Video", "ui_scale", 1.0)
	ui_scale_slider.value = ui_scale
	_on_ui_scale_changed(ui_scale) # Force update labels
	
	# Load Player Settings
	if player:
		var sens = config.get_value("Player", "sensitivity", 0.002)
		player.mouse_sensitivity = sens
		sensitivity_slider.value = sens
		
		if "show_raycast_laser" in player:
			var show_laser = config.get_value("Player", "show_raycast_laser", false)
			player.show_raycast_laser = show_laser
			raycast_demo_checkbox.button_pressed = show_laser
			
	# Load Crosshair Settings
	crosshair_size = config.get_value("Crosshair", "size", 1.0)
	crosshair_size_slider.value = crosshair_size
	
	crosshair_color = config.get_value("Crosshair", "color", Color.WHITE)
	crosshair_color_picker.color = crosshair_color
	
	crosshair_type = config.get_value("Crosshair", "type", 0)
	crosshair_type_dropdown.select(crosshair_type)
	
	crosshair_container.queue_redraw()
	
# --- Main Menu Buttons ---

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_settings_pressed() -> void:
	main_panel.hide()
	settings_panel.show()
	# Sync UI to the player's current settings when opening the menu
	if player:
		sensitivity_slider.value = player.mouse_sensitivity
		if "show_raycast_laser" in player:
			raycast_demo_checkbox.button_pressed = player.show_raycast_laser
			
func _on_exit_pressed() -> void:
	save_settings() # Save as game closes
	get_tree().quit()

# --- Settings Menu ---

func _on_back_pressed() -> void:
	save_settings() # Save upon returning to the main menu
	settings_panel.hide()
	main_panel.show()

func _on_sensitivity_changed(value: float) -> void:
	if player:
		player.mouse_sensitivity = value

func _on_raycast_demo_toggled(toggled_on: bool) -> void:
	if player and "show_raycast_laser" in player:
		player.show_raycast_laser = toggled_on
		
func _on_window_mode_selected(index: int) -> void:
	if index == 0: # Windowed
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		resolution_dropdown.disabled = false
		
		# Immediately apply the chosen windowed resolution
		var current_res_index = resolution_dropdown.selected
		if current_res_index != -1:
			_on_resolution_selected(current_res_index)
			
	elif index == 1: # Fullscreen
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		resolution_dropdown.disabled = true

func _on_resolution_selected(index: int) -> void:
	# Only change resolution if we are not in fullscreen mode
	if window_mode_dropdown.selected == 0:
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
	# redraw crosshair so its offset gap scales dynamically too
	crosshair_container.queue_redraw()
	
# --- Crosshair Drawing & Updates ---
	
func _on_crosshair_size_changed(value: float) -> void:
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
	
	# Shift crosshair to the right when the pause menu is open to act as a viewer
	if get_tree().paused and visible:
		var current_scale = ui_scale_slider.value if ui_scale_slider else 1.0
		# Shift by half the width of the pause menu plus a 120-pixel gap
		center.x += (BASE_MIN_SIZE.x / 2.0 + 120) * current_scale
		
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
