extends Node

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		pass

func calculate_actions_per_minute(actions_per_minute:float) -> float:
	return 60.0 / actions_per_minute

func calculate_actions_per_second(actions_per_second:float) -> float:
	return 1.0 / actions_per_second
