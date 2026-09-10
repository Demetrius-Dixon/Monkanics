extends Node

const RELAY_SERVER_NA_IPV4 : String = LOCALHOST_IPV4
const RELAY_SERVER_PORT : int = 5378
const LOCALHOST_IPV4 : String = "127.0.0.1"

var is_mouse_visible : bool = true

@onready var spawned_object_container : Node = $SpawnedObjects



func _process(_delta: float) -> void:
	
	pass
	
	#if Input.is_action_just_pressed("ui_cancel"):
		#
		#toggle_mouse()

func quit_monkanics() -> void:
	get_tree().root.\
	propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
	get_tree().quit()

func show_mouse() -> void:
	
	if is_mouse_visible == false:
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		is_mouse_visible = true
		
	else:
		return

func hide_mouse() -> void:
	
	if is_mouse_visible == true:
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		is_mouse_visible = false
		
	else:
		return

func toggle_mouse() -> void:
	
	if is_mouse_visible == false:
		show_mouse()
	elif is_mouse_visible == true:
		hide_mouse()
	else:
		return

func calculate_operations_per_minute(operations_per_minute:float) -> float:
	return 60.0 / operations_per_minute

func calculate_operations_per_second(operations_per_second:float) -> float:
	return 1.0 / operations_per_second
