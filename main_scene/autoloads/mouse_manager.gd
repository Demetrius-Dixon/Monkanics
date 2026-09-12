extends Node

var is_mouse_visible : bool = true

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
