extends Node

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		pass

func calculate_actions_per_minute(Actions_Per_Minute:float) -> float:
	return 60.0 / Actions_Per_Minute

func calculate_actions_per_second(Actions_Per_Second:float) -> float:
	return 1.0 / Actions_Per_Second
