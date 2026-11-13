extends Node

func _ready() -> void:
	prune_main_scene()

func prune_main_scene() -> void:
	
	if OS.has_feature("dedicated_server"):
		
		pass
		
		
	
	if not OS.has_feature("dedicated_server"):
		
		pass
	
	else:
		pass
	
	queue_free()
