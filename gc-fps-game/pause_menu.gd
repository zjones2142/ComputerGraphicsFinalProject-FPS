extends Control

# This allows us to link the player in the inspector to update their sensitivity
@export var player: CharacterBody3D

@onready var main_panel = $MainPanel
@onready var settings_panel = $SettingsPanel
@onready var sensitivity_slider = $SettingsPanel/TabContainer/PlayerOptions/SensitivitySlider
@onready var window_mode_dropdown = $SettingsPanel/TabContainer/Video/WindowModeDropdown

func _ready() -> void:
	# Hide the menu when the game starts
	hide()
	settings_panel.hide()
	
	# Populate the Video Dropdown
	window_mode_dropdown.add_item("Windowed")
	window_mode_dropdown.add_item("Fullscreen")
	
	# Wire up all button signals via code so you don't have to do it in the editor
	$MainPanel/ResumeButton.pressed.connect(_on_resume_pressed)
	$MainPanel/SettingsButton.pressed.connect(_on_settings_pressed)
	$MainPanel/ExitButton.pressed.connect(_on_exit_pressed)
	$SettingsPanel/BackButton.pressed.connect(_on_back_pressed)
	
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	window_mode_dropdown.item_selected.connect(_on_window_mode_selected)

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
