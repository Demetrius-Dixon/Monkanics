extends Node

var Is_Mouse_Visible : bool = true

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		pass

func show_mouse() -> void:
	
	if Is_Mouse_Visible == false:
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Is_Mouse_Visible = true
		
	else:
		return

func hide_mouse() -> void:
	
	if Is_Mouse_Visible == true:
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		Is_Mouse_Visible = false
		
	else:
		return

func toggle_mouse() -> void:
	
	if Is_Mouse_Visible == false:
		show_mouse()
	elif Is_Mouse_Visible == true:
		hide_mouse()
	else:
		return
