extends Node

var is_host : bool = false

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"): 
		queue_free()
