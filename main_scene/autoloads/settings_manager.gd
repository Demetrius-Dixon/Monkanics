extends Node

var mouse_sensitivity : float = 0.003

func _ready() -> void:
	
	if OS.has_feature(FeatureManager.DEDICATED_SERVER): 
		queue_free()
